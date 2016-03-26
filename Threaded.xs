#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <dlfcn.h>
#include <pthread.h>

#include <mysql.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "src/util.h"

#if HAVE_EV
# include "EVAPI.h"
# include "CoroAPI.h"
#endif

#define IN_DESTRUCT   PL_dirty
#define MAX_WORKERS   2
#define PIPE_READ_FD  0
#define PIPE_WRITE_FD 1

// _FUNC(<result type>, <result var>, <function>,
//          <param type>, <param name>,
//          ...
#define _FUNC_LIST                                                      \
    _FUNC(MYSQL *, mysql, mysql_real_connect,                           \
            MYSQL *,       mysql,                                       \
            const char *,  host,                                        \
            const char *,  user,                                        \
            const char *,  passwd,                                      \
            const char *,  db,                                          \
            unsigned int,  port,                                        \
            const char *,  unix_socket,                                 \
            unsigned long, clientflag)                                  \
    _FUNC(int, num, mysql_real_query,                                   \
            MYSQL *,       mysql,                                       \
            const char *,  q,                                           \
            unsigned long, length)                                      \
    _FUNC(int, num, mysql_query,                                        \
            MYSQL *,       mysql,                                       \
            const char *,  q)                                           \
    _FUNC(int, num, mysql_send_query,                                   \
            MYSQL *,       mysql,                                       \
            const char *,  q,                                           \
            unsigned long, length)                                      \
    _FUNC(MYSQL_RES *, res, mysql_store_result,                         \
            MYSQL *,       mysql)

typedef struct worker_s worker_t;
typedef void (*call_real_func_t)(worker_t *worker);

struct worker_s {
    int              tid;
    pthread_t        thread;
    pthread_mutex_t  hold;
    pthread_mutex_t  mutex;
    pthread_cond_t   cond;
    int              terminate;
    int              busy;
    int              pipe_fds[2];
#if HAVE_EV
    ev_io            pipe_w;
#endif
    call_real_func_t call_real_func;
    struct {
        MYSQL         *mysql;
        const char    *host;
        const char    *user;
        const char    *passwd;
        const char    *db;
        const char    *unix_socket;
        const char    *q;
        unsigned int   port;
        unsigned long  clientflag;
        unsigned long  length;
    } param;
    struct {
        MYSQL         *mysql;
        MYSQL_RES     *res;
        int            num;
    } res;
};

static int       initialized = 0;
static int       use_ev      = 0;
static worker_t  workers[MAX_WORKERS];
static pthread_t main_thread;

#if HAVE_EV
static void pipe_cb(EV_P_ ev_io *w, UNUSED int revents) {
    dbg0("pipe callback");
    ev_io_stop(EV_A, w);
    CORO_READY((SV *) w->data);
}
#endif

static void *worker_func(void *arg) {
    worker_t *worker = (worker_t *) arg;

    dbg1("worker %d is ready", worker->tid);

    dbg1("p: %lu", pthread_self());

    pthread_mutex_lock(&worker->mutex);
    while (!worker->terminate) {
        dbg0("cond wait");
        pthread_cond_wait(&worker->cond, &worker->mutex);
        dbg0("got signal");

        if (worker->terminate)
            break;

        dbg0("send request");
        worker->call_real_func(worker);

        dbg0("got response");
        if (write(worker->pipe_fds[PIPE_WRITE_FD], "1", 1) != 1) {
            dbg1("write error: %s", strerror(errno));
        }
    }
    pthread_mutex_unlock(&worker->mutex);

    return NULL;
}

static int start_workers(void) {
    int       i;
    worker_t *worker;

    memset(workers, 0, sizeof(workers));

    for (i = 0; i < MAX_WORKERS; ++i) {
        dbg1("create worker: %d", i);

        worker = &workers[i];
        worker->tid = i;

        if (pipe2(worker->pipe_fds, O_NONBLOCK) == -1) {
            die("can't create pipe due: %s", strerror(errno));
        }
        dbg2("pipe:%d, %d", worker->pipe_fds[0], worker->pipe_fds[1]);

#if HAVE_EV
        if (use_ev) {
            ev_io_init(&worker->pipe_w, pipe_cb, worker->pipe_fds[PIPE_READ_FD], EV_READ);
        }
#endif
        pthread_mutex_init(&worker->hold, NULL);
        pthread_mutex_init(&worker->mutex, NULL);
        pthread_cond_init(&worker->cond, NULL);

        if (pthread_create(&worker->thread, NULL, worker_func, worker) != 0) {
            die("can't to create worker due: %s\n", strerror(errno));
            return 1;
        }
    }

    return 0;
}

static void stop_workers(void) {
    int i;

    dbg0("stop workers");

    for (i = 0; i < MAX_WORKERS; i++) {
        workers[i].terminate = 1;
        pthread_mutex_lock(&workers[i].mutex);
        pthread_cond_broadcast(&workers[i].cond);
        pthread_mutex_unlock(&workers[i].mutex);
    }

    for (i = 0; i < MAX_WORKERS; i++) {
        if (pthread_join(workers[i].thread, NULL)) {
            die("Can't stop worker due: %s\n", strerror(errno));
        }
    }
}

static worker_t *hold_worker(void) {
    int i;

    for (i = 0; i < MAX_WORKERS; ++i) {
        if (pthread_mutex_trylock(&workers[i].hold) == 0) {
            pthread_mutex_lock(&workers[i].mutex);
            return &workers[i];
        }
    }

    return NULL;
}

static void unhold_worker(worker_t *worker) {
    pthread_mutex_unlock(&worker->hold);
}

static void wakeup_worker(worker_t *worker) {
    char c;

    pthread_cond_broadcast(&worker->cond);
    pthread_mutex_unlock(&worker->mutex);

#if HAVE_EV
    if (use_ev) {
        worker->pipe_w.data = (void *) sv_2mortal(SvREFCNT_inc(CORO_CURRENT));
        ev_io_start(EV_DEFAULT_UC, &worker->pipe_w);
        dbg0("schedule");
        CORO_SCHEDULE;
        dbg0("continue");
        ev_io_stop(EV_DEFAULT_UC, &worker->pipe_w);
    }
#endif

    dbg0("read from pipe");
    while (read(worker->pipe_fds[PIPE_READ_FD], &c, 1) == 1)
        ;
}

// refs of real functions
#define _FUNC(result_type, result, func, ...)                           \
    static result_type(*_ ## func)();
_FUNC_LIST

// set callers to original functions
#undef _FUNC
#define _FUNC(result_type, result, func, ...)                           \
static void call_ ## func(worker_t *worker) {                           \
    worker->res.result = _ ## func(_GET_PARAM(__VA_ARGS__));            \
}
_FUNC_LIST

// new functions
#undef _GET_PARAM2
#define _GET_PARAM2(t1, n1) n1
#undef _FUNC
#define _FUNC(result_type, result, func, ...)                           \
result_type STDCALL func(_DECL_PARAM(__VA_ARGS__)) {                    \
    dbg2("main: %lu cur: %lu",main_thread, pthread_self());             \
    if (!pthread_equal(main_thread, pthread_self())) {                  \
        dbg0("isn't main thread, call original function");              \
        return _ ## func(_GET_PARAM(__VA_ARGS__));                      \
    }                                                                   \
                                                                        \
    dbg0("prepare");                                                    \
                                                                        \
    worker_t *worker = hold_worker();                                   \
    if (worker== NULL) {                                                \
        dbg0("no free workers, call original function");                \
        return _ ## func(_GET_PARAM(__VA_ARGS__));                      \
    }                                                                   \
                                                                        \
    worker->call_real_func = call_ ## func;                             \
    _SET_PARAM(__VA_ARGS__);                                            \
                                                                        \
    wakeup_worker(worker);                                              \
    result_type tmp = worker->res.result;                               \
    unhold_worker(worker);                                              \
                                                                        \
    return tmp;                                                         \
}
_FUNC_LIST

// function overloadins
#undef _FUNC
#define _FUNC(result_type, result, func, ...)                           \
    if ((ref = dlsym(mysql_lib_handle, #func)) == NULL) {               \
        die("Can't find symbol: %s", #func);                            \
    }                                                                   \
    else {                                                              \
        *(result_type **) (&_ ## func) = ref;                           \
    }

static void init(char *my_lib_path, char *mysql_lib_path) {
    void *mysql_lib_handle, *ref;

    main_thread = pthread_self();

    mysql_lib_handle = dlopen(mysql_lib_path, RTLD_LAZY);
    if (mysql_lib_handle == NULL) {
        die("dlopen");
    }

    _FUNC_LIST

    dlopen(my_lib_path, RTLD_NOW | RTLD_GLOBAL);

    if (start_workers() != 0) {
        die("can't start workers");
    }
}

MODULE = Coro::Mysql::Threaded PACKAGE = Coro::Mysql::Threaded

PROTOTYPES: DISABLE

void
_begin(my_lib_path, mysql_lib_path)
        char *my_lib_path;
        char *mysql_lib_path;
    CODE:
        if (initialized) XSRETURN_UNDEF;

        dbg2("init: %s, %s\n", my_lib_path, mysql_lib_path);

    #if HAVE_EV
        I_EV_API("Coro::Mysql");
        I_CORO_API("Coro::Mysql");
        use_ev = 1;
    #endif

        init(my_lib_path, mysql_lib_path);

void
_end()
    CODE:
        dbg0("end");
        if (!initialized) XSRETURN_UNDEF;

        stop_workers();
