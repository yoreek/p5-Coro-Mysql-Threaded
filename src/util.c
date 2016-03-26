#ifdef WITH_DEBUG

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <pthread.h>
#include "util.h"

static pthread_mutex_t dbg_mutex = PTHREAD_MUTEX_INITIALIZER;

void
_dbg(const char *func, int line, const char *msg, ...)
{
    va_list args;

    pthread_mutex_lock(&dbg_mutex);

    (void) fprintf(stderr, "(DEBUG) %s[%.0d]: ", func, line);

    va_start(args, msg);
    (void) vfprintf(stderr, msg, args);
    if (msg[strlen(msg) - 1] != '\n') {
        (void) fprintf(stderr, "\n");
    }
    va_end(args);

    pthread_mutex_unlock(&dbg_mutex);
}

#endif // WITH_DEBUG
