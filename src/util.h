#pragma once
#ifndef _UTIL_H_
#define _UTIL_H_

#ifdef __GNUC__
#  define UNUSED __attribute__((__unused__))
#else
#  define UNUSED
#endif

#define VA_NARGS(...) VA_NARGS_IMPL(__VA_ARGS__, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
#define VA_NARGS_IMPL(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, N, ...) N

#ifdef WITH_DEBUG

void _dbg(const char *func, int line, const char *msg, ...);

#define dbg0(msg)                                                       \
        _dbg(__FUNCTION__, __LINE__, msg)
#define dbg1(msg, arg1)                                                 \
        _dbg(__FUNCTION__, __LINE__, msg, arg1)
#define dbg2(msg, arg1, arg2)                                           \
        _dbg(__FUNCTION__, __LINE__, msg, arg1, arg2)
#define dbg3(msg, arg1, arg2, arg3)                                     \
        _dbg(__FUNCTION__, __LINE__, msg, arg1, arg2, arg3)
#define dbg4(msg, arg1, arg2, arg3, arg4)                               \
        _dbg(__FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4)
#define dbg5(msg, arg1, arg2, arg3, arg4, arg5)                         \
        _dbg(__FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5)
#define dbg6(msg, arg1, arg2, arg3, arg4, arg5, arg6)                   \
        _dbg(__FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6)
#define dbg7(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)             \
        _dbg(__FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#define dbg8(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)       \
        _dbg(__FUNCTION__, __LINE__, msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)

#else // WITH_DEBUG

#define dbg0(msg)
#define dbg1(msg, arg1)
#define dbg2(msg, arg1, arg2)
#define dbg3(msg, arg1, arg2, arg3)
#define dbg4(msg, arg1, arg2, arg3, arg4)
#define dbg5(msg, arg1, arg2, arg3, arg4, arg5)
#define dbg6(msg, arg1, arg2, arg3, arg4, arg5, arg6)
#define dbg7(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#define dbg8(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)

#endif // WITH_DEBUG

#define _DECL_PARAM2(t1, n1) t1 n1
#define _DECL_PARAM4(t1, n1, t2, n2) _DECL_PARAM2(t1, n1), _DECL_PARAM2(t2, n2)
#define _DECL_PARAM6(t1, n1, t2, n2, t3, n3)                            \
    _DECL_PARAM4(t1, n1, t2, n2),                                       \
    _DECL_PARAM2(t3, n3)
#define _DECL_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4)                    \
    _DECL_PARAM4(t1, n1, t2, n2),                                       \
    _DECL_PARAM4(t3, n3, t4, n4)
#define _DECL_PARAM10(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5)           \
    _DECL_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4),                       \
    _DECL_PARAM2(t5, n5)
#define _DECL_PARAM12(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6)   \
    _DECL_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4),                       \
    _DECL_PARAM4(t5, n5, t6, n6)
#define _DECL_PARAM14(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6, t7, n7)\
    _DECL_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4),                       \
    _DECL_PARAM6(t5, n5, t6, n6, t7, n7)
#define _DECL_PARAM16(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6, t7, n7, t8, n8)\
    _DECL_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4),                       \
    _DECL_PARAM8(t5, n5, t6, n6, t7, n7, t8, n8)
#define _DECL_PARAM_IMPL2(count, ...) _DECL_PARAM ## count (__VA_ARGS__)
#define _DECL_PARAM_IMPL(count, ...) _DECL_PARAM_IMPL2(count, __VA_ARGS__)
#define _DECL_PARAM(...) _DECL_PARAM_IMPL(VA_NARGS(__VA_ARGS__), __VA_ARGS__)

#define _GET_PARAM2(t1, n1) worker->param.n1
#define _GET_PARAM4(t1, n1, t2, n2) _GET_PARAM2(t1, n1), _GET_PARAM2(t2, n2)
#define _GET_PARAM6(t1, n1, t2, n2, t3, n3)                             \
    _GET_PARAM4(t1, n1, t2, n2),                                        \
    _GET_PARAM2(t3, n3)
#define _GET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4)                     \
    _GET_PARAM4(t1, n1, t2, n2),                                        \
    _GET_PARAM4(t3, n3, t4, n4)
#define _GET_PARAM10(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5)            \
    _GET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4),                        \
    _GET_PARAM2(t5, n5)
#define _GET_PARAM12(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6)    \
    _GET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4),                        \
    _GET_PARAM4(t5, n5, t6, n6)
#define _GET_PARAM14(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6, t7, n7)\
    _GET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4),                        \
    _GET_PARAM6(t5, n5, t6, n6, t7, n7)
#define _GET_PARAM16(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6, t7, n7, t8, n8)\
    _GET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4),                        \
    _GET_PARAM8(t5, n5, t6, n6, t7, n7, t8, n8)
#define _GET_PARAM_IMPL2(count, ...) _GET_PARAM ## count (__VA_ARGS__)
#define _GET_PARAM_IMPL(count, ...) _GET_PARAM_IMPL2(count, __VA_ARGS__)
#define _GET_PARAM(...) _GET_PARAM_IMPL(VA_NARGS(__VA_ARGS__), __VA_ARGS__)

#define _SET_PARAM2(t1, n1) worker->param.n1 = n1;
#define _SET_PARAM4(t1, n1, t2, n2)                                     \
    _SET_PARAM2(t1, n1)                                                 \
    _SET_PARAM2(t2, n2)
#define _SET_PARAM6(t1, n1, t2, n2, t3, n3)                             \
    _SET_PARAM4(t1, n1, t2, n2)                                         \
    _SET_PARAM2(t3, n3)
#define _SET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4)                     \
    _SET_PARAM4(t1, n1, t2, n2)                                         \
    _SET_PARAM4(t3, n3, t4, n4)
#define _SET_PARAM10(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5)            \
    _SET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4)                         \
    _SET_PARAM2(t5, n5)
#define _SET_PARAM12(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6)    \
    _SET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4)                         \
    _SET_PARAM4(t5, n5, t6, n6)
#define _SET_PARAM14(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6, t7, n7)\
    _SET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4)                         \
    _SET_PARAM6(t5, n5, t6, n6, t7, n7)
#define _SET_PARAM16(t1, n1, t2, n2, t3, n3, t4, n4, t5, n5, t6, n6, t7, n7, t8, n8)\
    _SET_PARAM8(t1, n1, t2, n2, t3, n3, t4, n4)                         \
    _SET_PARAM8(t5, n5, t6, n6, t7, n7, t8, n8)
#define _SET_PARAM_IMPL2(count, ...) _SET_PARAM ## count (__VA_ARGS__)
#define _SET_PARAM_IMPL(count, ...) _SET_PARAM_IMPL2(count, __VA_ARGS__)
#define _SET_PARAM(...) _SET_PARAM_IMPL(VA_NARGS(__VA_ARGS__), __VA_ARGS__)

#endif
