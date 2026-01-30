/*
    Macros used to generate fortran compatible bindings for the C api.

    These macros generate customized wrapper functions based on the determined
    characteristics of the fortran compiler.

    @author Peter Smith
*/


#ifndef __FORTRAN_API_H__
#define __FORTRAN_API_H__

#include    <string.h>

/*
 * These definitions control how the fortran function name is generated. One of
 * FORTRAN_API_UPPERCASE, FORTRAN_API_LOWERCASE, or FORTRAN_API_NOCASE should be
 * defined prior to inclusion, otherwise it will will default to upper case.
 * Additionally, FORTRAN_API_PREFIX and FORTRAN_API_SUFFIX can be used to add
 * leading or trailing characters to the exported function names (e.g. underscores)
 */
#if !defined(FORTRAN_API_UPPERCASE) && !defined(FORTRAN_API_LOWERCASE) && !defined(FORTRAN_API_NOCASE)
#define FORTRAN_API_UPPERCASE 1
#endif

#ifndef FORTRAN_API_PREFIX
#define FORTRAN_API_PREFIX
#endif

#ifndef FORTRAN_API_SUFFIX
#define FORTRAN_API_SUFFIX 
#endif


/*
 * Set up the macro to select the appropriate case for naming the fortan functions.
 */
#if FORTRAN_API_UPPERCASE
#define FORTRAN_API_NAME_SELECT(a,b,c) b
#elif FORTRAN_API_LOWERCASE
#define FORTRAN_API_NAME_SELECT(a,b,c) c
#else
#define FORTRAN_API_NAME_SELECT(a,b,c) a
#endif


/*
 * Set up macros for mapping API 'types' to actual langauge types. These can be
 * prefined if necessary.
 */
#ifndef FORTRAN_API_TYPE_INT32
#define FORTRAN_API_TYPE_INT32      int
#endif

#ifndef FORTRAN_API_TYPE_INT
#define FORTRAN_API_TYPE_INT        int
#endif

#ifndef FORTRAN_API_TYPE_FLOAT64
#define FORTRAN_API_TYPE_FLOAT64    double
#endif



/************************************************************
    All configuration control is above this point. Below
    this are the code generation functions and macros.
************************************************************/

/*
 * Thunking function to map a fixed length fortran string to a c-style null
 * terminated string on input.
 */
static inline char* fortran_api_map_string_in(const char* i, unsigned FORTRAN_API_TYPE_INT maxlen) {
    unsigned FORTRAN_API_TYPE_INT len = strlen(i);
    char* o = malloc(maxlen + 1);

    len = (len < maxlen) ? len : maxlen;
    if (len == maxlen) while(len > 0 && i[len] == ' ') --len;
    memcpy(o, i, len);
    o[len] = 0;

    return o;
}

/*
 * Thunking function to map a c-style null terminated string to a fixed length fortran
 * string on output.
 */
static inline void fortran_api_map_string_out(char* o, const char* i, unsigned FORTRAN_API_TYPE_INT maxlen) {
    unsigned FORTRAN_API_TYPE_INT len = strlen(i);
    len = (len < maxlen) ? len : maxlen;
    memcpy(o, i, len);
    while(len < maxlen) o[len++] = ' ';
}


/* Nested macro expansion (needed to support MS Visual C which has a more basic preprocessor) */

#define FORTRAN_API_EXPAND(x) x

/* Join simple strings */

#define FORTRAN_API_COMBINE2(A,B) A##B
#define FORTRAN_API_COMBINE3(A,B,C) A##B##C


/*
 * Maros used to construct another macro name - for example,
 * combining a macro prefix with a number to identify a macro that takes
 * a specific number or arguments.
 */
#define FORTRAN_API_MAKENAME2(A,B) FORTRAN_API_COMBINE2(A,B)
#define FORTRAN_API_MAKENAME3(A,B,C) FORTRAN_API_COMBINE3(A,B,C)


/*
 * Macros used to expand arguments to their appropriate type in an argument list.
 */
#define FORTRAN_API_ARG_PVOID       void*
#define FORTRAN_API_ARG_STRING      const char*
#define FORTRAN_API_ARG_PSTRING     char*
#define FORTRAN_API_ARG_INT         const FORTRAN_API_TYPE_INT*
#define FORTRAN_API_ARG_PINT        FORTRAN_API_TYPE_INT*
#define FORTRAN_API_ARG_INT32       const FORTRAN_API_TYPE_INT32*
#define FORTRAN_API_ARG_PINT32      FORTRAN_API_TYPE_INT32*
#define FORTRAN_API_ARG_FLOAT64     const FORTRAN_API_TYPE_FLOAT64*
#define FORTRAN_API_ARG_PFLOAT64    FORTRAN_API_TYPE_FLOAT64*


/*
 * Macros used to map types (e.g. 'OUT STRING' => 'PSTRING'). This just provides
 * a convenience when declaring your API and makes it a bit clearer that it is an 
 * output value. 
 */
#define FORTRAN_API_TYPEMAP_OUT _,P,
#define FORTRAN_API_TYPEMAP_JOIN23(_1,_2,_3,...) _2##_3
#define FORTRAN_API_TYPEMAP_JOIN(...) FORTRAN_API_EXPAND(FORTRAN_API_TYPEMAP_JOIN23(__VA_ARGS__))

#define FORTRAN_API_TYPEMAP(type) FORTRAN_API_TYPEMAP_JOIN(FORTRAN_API_COMBINE2(FORTRAN_API_TYPEMAP_, type),,type)


/*
 * Macros used to generate argument lists. Primary arguments are prefixed with 'a', e.g.
 * a1, a2, a3, ...
 */
#define FORTRAN_API_ARG_GENERATE(type) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_ARG_,type))
#define FORTRAN_API_ARG(type,n) FORTRAN_API_ARG_GENERATE(FORTRAN_API_TYPEMAP(type)) a##n
//#define FORTRAN_API_ARG(type,n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_ARG_,type)) a##n
#define FORTRAN_API_ARGS1(t1) FORTRAN_API_ARG(t1,1)
#define FORTRAN_API_ARGS2(t1,t2) FORTRAN_API_ARGS1(t1), FORTRAN_API_ARG(t2,2)
#define FORTRAN_API_ARGS3(t1,t2,t3) FORTRAN_API_ARGS2(t1,t2), FORTRAN_API_ARG(t3,3)
#define FORTRAN_API_ARGS4(t1,t2,t3,t4) FORTRAN_API_ARGS3(t1,t2,t3), FORTRAN_API_ARG(t4,4)
#define FORTRAN_API_ARGS5(t1,t2,t3,t4,t5) FORTRAN_API_ARGS4(t1,t2,t3,t4), FORTRAN_API_ARG(t5,5)
#define FORTRAN_API_ARGS6(t1,t2,t3,t4,t5,t6) FORTRAN_API_ARGS5(t1,t2,t3,t4,t5), FORTRAN_API_ARG(t6,6)
#define FORTRAN_API_ARGS7(t1,t2,t3,t4,t5,t6,t7) FORTRAN_API_ARGS6(t1,t2,t3,t4,t5,t6), FORTRAN_API_ARG(t7,7)
#define FORTRAN_API_ARGS8(t1,t2,t3,t4,t5,t6,t7,t8) FORTRAN_API_ARGS7(t1,t2,t3,t4,t5,t6,t7), FORTRAN_API_ARG(t8,8)
#define FORTRAN_API_ARGS9(t1,t2,t3,t4,t5,t6,t7,t8,t9) FORTRAN_API_ARGS8(t1,t2,t3,t4,t5,t6,t7,t8), FORTRAN_API_ARG(t9,9)
#define FORTRAN_API_ARGS10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) FORTRAN_API_ARGS9(t1,t2,t3,t4,t5,t6,t7,t8,t9), FORTRAN_API_ARG(t10,10)
#define FORTRAN_API_ARGS11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11) FORTRAN_API_ARGS10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10), FORTRAN_API_ARG(t11,11)
#define FORTRAN_API_ARGS12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12) FORTRAN_API_ARGS11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11), FORTRAN_API_ARG(t12,12)
#define FORTRAN_API_ARGS13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13) FORTRAN_API_ARGS12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12), FORTRAN_API_ARG(t13,13)
#define FORTRAN_API_ARGS14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14) FORTRAN_API_ARGS13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13), FORTRAN_API_ARG(t14,14)
#define FORTRAN_API_ARGS15(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15) FORTRAN_API_ARGS14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14), FORTRAN_API_ARG(t15,15)


/*
 * Macros used to generate the specific additional arguments based on the current
 * argument type. Currently, only strings do this, and these ar prefixed with 'l'
 * within an index that matches the primary argument. e.g. two string arguements
 * in position 2 and 4 would create an additional two arguments l2, l4.
 */
#define FORTRAN_API_ARGX_PVOID(n)
#define FORTRAN_API_ARGX_STRING(n)      , unsigned FORTRAN_API_TYPE_INT l##n
#define FORTRAN_API_ARGX_PSTRING(n)     , unsigned FORTRAN_API_TYPE_INT l##n
#define FORTRAN_API_ARGX_INT(n)
#define FORTRAN_API_ARGX_PINT(n)
#define FORTRAN_API_ARGX_INT32(n)
#define FORTRAN_API_ARGX_PINT32(n)
#define FORTRAN_API_ARGX_FLOAT64(n)
#define FORTRAN_API_ARGX_PFLOAT64(n)

/*
 * Macros used to generate extra arguments for input strings (in standard fortran calling
 * convention, the length of a string is passed in as an additional argument to the function)
 */
#define FORTRAN_API_ARGX_GENERATE(type, n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_ARGX_,type)(n))
#define FORTRAN_API_ARGX(type,n) FORTRAN_API_ARGX_GENERATE(FORTRAN_API_TYPEMAP(type),n)
//#define FORTRAN_API_ARGX(type,n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_ARGX_,type)(n))
#define FORTRAN_API_ARGX1(t1) FORTRAN_API_ARGX(t1,1)
#define FORTRAN_API_ARGX2(t1,t2) FORTRAN_API_ARGX1(t1) FORTRAN_API_ARGX(t2,2)
#define FORTRAN_API_ARGX3(t1,t2,t3) FORTRAN_API_ARGX2(t1,t2) FORTRAN_API_ARGX(t3,3)
#define FORTRAN_API_ARGX4(t1,t2,t3,t4) FORTRAN_API_ARGX3(t1,t2,t3) FORTRAN_API_ARGX(t4,4)
#define FORTRAN_API_ARGX5(t1,t2,t3,t4,t5) FORTRAN_API_ARGX4(t1,t2,t3,t4) FORTRAN_API_ARGX(t5,5)
#define FORTRAN_API_ARGX6(t1,t2,t3,t4,t5,t6) FORTRAN_API_ARGX5(t1,t2,t3,t4,t5) FORTRAN_API_ARGX(t6,6)
#define FORTRAN_API_ARGX7(t1,t2,t3,t4,t5,t6,t7) FORTRAN_API_ARGX6(t1,t2,t3,t4,t5,t6) FORTRAN_API_ARGX(t7,7)
#define FORTRAN_API_ARGX8(t1,t2,t3,t4,t5,t6,t7,t8) FORTRAN_API_ARGX7(t1,t2,t3,t4,t5,t6,t7) FORTRAN_API_ARGX(t8,8)
#define FORTRAN_API_ARGX9(t1,t2,t3,t4,t5,t6,t7,t8,t9) FORTRAN_API_ARGX8(t1,t2,t3,t4,t5,t6,t7,t8) FORTRAN_API_ARGX(t9,9)
#define FORTRAN_API_ARGX10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) FORTRAN_API_ARGX9(t1,t2,t3,t4,t5,t6,t7,t8,t9) FORTRAN_API_ARGX(t10,10)
#define FORTRAN_API_ARGX11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11) FORTRAN_API_ARGX10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) FORTRAN_API_ARGX(t11,11)
#define FORTRAN_API_ARGX12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12) FORTRAN_API_ARGX11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11) FORTRAN_API_ARGX(t12,12)
#define FORTRAN_API_ARGX13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13) FORTRAN_API_ARGX12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12) FORTRAN_API_ARGX(t13,13)
#define FORTRAN_API_ARGX14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14) FORTRAN_API_ARGX13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13) FORTRAN_API_ARGX(t14,14)
#define FORTRAN_API_ARGX15(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15) FORTRAN_API_ARGX14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14) FORTRAN_API_ARGX(t15,15)



/*
 * Macros used to expand input arguments to their appropriate type in the internal API function call.
 * Everything in FORTRAN is passed by reference (pointer), so we need to dereference values such as
 * integers or floats, but not arrays.
 */
#define FORTRAN_API_PARAM_PVOID(n)      a##n
#define FORTRAN_API_PARAM_STRING(n)     _a##n
#define FORTRAN_API_PARAM_PSTRING(n)    _a##n
#define FORTRAN_API_PARAM_INT(n)        *a##n
#define FORTRAN_API_PARAM_PINT(n)       a##n
#define FORTRAN_API_PARAM_INT32(n)      *a##n
#define FORTRAN_API_PARAM_PINT32(n)     a##n
#define FORTRAN_API_PARAM_FLOAT64(n)    *a##n
#define FORTRAN_API_PARAM_PFLOAT64(n)   a##n


/*
 * Macros used to generate parameter lists for invoking the internal function
 */
#define FORTRAN_API_PARAM_GENERATE(type, n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_PARAM_,type)(n))
#define FORTRAN_API_PARAM(type,n) FORTRAN_API_PARAM_GENERATE(FORTRAN_API_TYPEMAP(type),n)
//#define FORTRAN_API_PARAM(type,n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_PARAM_,type)(n))
#define FORTRAN_API_PARAMS1(t1) FORTRAN_API_PARAM(t1,1)
#define FORTRAN_API_PARAMS2(t1,t2) FORTRAN_API_PARAMS1(t1), FORTRAN_API_PARAM(t2,2)
#define FORTRAN_API_PARAMS3(t1,t2,t3) FORTRAN_API_PARAMS2(t1,t2), FORTRAN_API_PARAM(t3,3)
#define FORTRAN_API_PARAMS4(t1,t2,t3,t4) FORTRAN_API_PARAMS3(t1,t2,t3), FORTRAN_API_PARAM(t4,4)
#define FORTRAN_API_PARAMS5(t1,t2,t3,t4,t5) FORTRAN_API_PARAMS4(t1,t2,t3,t4), FORTRAN_API_PARAM(t5,5)
#define FORTRAN_API_PARAMS6(t1,t2,t3,t4,t5,t6) FORTRAN_API_PARAMS5(t1,t2,t3,t4,t5), FORTRAN_API_PARAM(t6,6)
#define FORTRAN_API_PARAMS7(t1,t2,t3,t4,t5,t6,t7) FORTRAN_API_PARAMS6(t1,t2,t3,t4,t5,t6), FORTRAN_API_PARAM(t7,7)
#define FORTRAN_API_PARAMS8(t1,t2,t3,t4,t5,t6,t7,t8) FORTRAN_API_PARAMS7(t1,t2,t3,t4,t5,t6,t7), FORTRAN_API_PARAM(t8,8)
#define FORTRAN_API_PARAMS9(t1,t2,t3,t4,t5,t6,t7,t8,t9) FORTRAN_API_PARAMS8(t1,t2,t3,t4,t5,t6,t7,t8), FORTRAN_API_PARAM(t9,9)
#define FORTRAN_API_PARAMS10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) FORTRAN_API_PARAMS9(t1,t2,t3,t4,t5,t6,t7,t8,t9), FORTRAN_API_PARAM(t10,10)
#define FORTRAN_API_PARAMS11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11) FORTRAN_API_PARAMS10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10), FORTRAN_API_PARAM(t11,11)
#define FORTRAN_API_PARAMS12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12) FORTRAN_API_PARAMS11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11), FORTRAN_API_PARAM(t12,12)
#define FORTRAN_API_PARAMS13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13) FORTRAN_API_PARAMS12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12), FORTRAN_API_PARAM(t13,13)
#define FORTRAN_API_PARAMS14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14) FORTRAN_API_PARAMS13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13), FORTRAN_API_PARAM(t14,14)
#define FORTRAN_API_PARAMS15(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15) FORTRAN_API_PARAMS14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14), FORTRAN_API_PARAM(t15,15)



/*
 * Macros used to generate mapping code for input parameters (code that converts an input value
 * to something that can be passed through to the API function call). Generally, only strings need
 * mapping code since FORTRAN uses fixed length strings where the length is passed in as an
 * additional function argument. Note that string handling is currently NOT optimized, but the likely
 * overhead is small when compared to the processing that is likely being performed on the data.
 */
#define FORTRAN_API_MAP_IN_PVOID(n)
#define FORTRAN_API_MAP_IN_STRING(n)        char* _a##n = fortran_api_map_string_in(a##n, l##n);
#define FORTRAN_API_MAP_IN_PSTRING(n)       char* _a##n = fortran_api_map_string_in(a##n, l##n);
#define FORTRAN_API_MAP_IN_INT(n)
#define FORTRAN_API_MAP_IN_PINT(n)
#define FORTRAN_API_MAP_IN_INT32(n)
#define FORTRAN_API_MAP_IN_PINT32(n)
#define FORTRAN_API_MAP_IN_FLOAT64(n)
#define FORTRAN_API_MAP_IN_PFLOAT64(n)


/*
 * Macros used to generate extra argument lists
 */
#define FORTRAN_API_MAP_IN_GENERATE(type, n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_MAP_IN_,type)(n)) 
#define FORTRAN_API_MAP_IN(type,n) FORTRAN_API_MAP_IN_GENERATE(FORTRAN_API_TYPEMAP(type), n)
//#define FORTRAN_API_MAP_IN(type,n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_MAP_IN_,type)(n)) 
#define FORTRAN_API_MAP_IN1(t1) FORTRAN_API_MAP_IN(t1,1)
#define FORTRAN_API_MAP_IN2(t1,t2) FORTRAN_API_MAP_IN1(t1) FORTRAN_API_MAP_IN(t2,2)
#define FORTRAN_API_MAP_IN3(t1,t2,t3) FORTRAN_API_MAP_IN2(t1,t2) FORTRAN_API_MAP_IN(t3,3)
#define FORTRAN_API_MAP_IN4(t1,t2,t3,t4) FORTRAN_API_MAP_IN3(t1,t2,t3) FORTRAN_API_MAP_IN(t4,4)
#define FORTRAN_API_MAP_IN5(t1,t2,t3,t4,t5) FORTRAN_API_MAP_IN4(t1,t2,t3,t4) FORTRAN_API_MAP_IN(t5,5)
#define FORTRAN_API_MAP_IN6(t1,t2,t3,t4,t5,t6) FORTRAN_API_MAP_IN5(t1,t2,t3,t4,t5) FORTRAN_API_MAP_IN(t6,6)
#define FORTRAN_API_MAP_IN7(t1,t2,t3,t4,t5,t6,t7) FORTRAN_API_MAP_IN6(t1,t2,t3,t4,t5,t6) FORTRAN_API_MAP_IN(t7,7)
#define FORTRAN_API_MAP_IN8(t1,t2,t3,t4,t5,t6,t7,t8) FORTRAN_API_MAP_IN7(t1,t2,t3,t4,t5,t6,t7) FORTRAN_API_MAP_IN(t8,8)
#define FORTRAN_API_MAP_IN9(t1,t2,t3,t4,t5,t6,t7,t8,t9) FORTRAN_API_MAP_IN8(t1,t2,t3,t4,t5,t6,t7,t8) FORTRAN_API_MAP_IN(t9,9)
#define FORTRAN_API_MAP_IN10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) FORTRAN_API_MAP_IN9(t1,t2,t3,t4,t5,t6,t7,t8,t9) FORTRAN_API_MAP_IN(t10,10)
#define FORTRAN_API_MAP_IN11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11) FORTRAN_API_MAP_IN10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) FORTRAN_API_MAP_IN(t11,11)
#define FORTRAN_API_MAP_IN12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12) FORTRAN_API_MAP_IN11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11) FORTRAN_API_MAP_IN(t12,12)
#define FORTRAN_API_MAP_IN13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13) FORTRAN_API_MAP_IN12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12) FORTRAN_API_MAP_IN(t13,13)
#define FORTRAN_API_MAP_IN14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14) FORTRAN_API_MAP_IN13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13) FORTRAN_API_MAP_IN(t14,14)
#define FORTRAN_API_MAP_IN15(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15) FORTRAN_API_MAP_IN14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14) FORTRAN_API_MAP_IN(t15,15)



/*
 * Macros used to generate mapping code for output parameters. Generally, only strings need
 * mapping code since FORTRAN uses fixed length strings where the length is passed in as an
 * additional function argument. 
 */
#define FORTRAN_API_MAP_OUT_PVOID(n)
#define FORTRAN_API_MAP_OUT_STRING(n) free(_a##n);
#define FORTRAN_API_MAP_OUT_PSTRING(n)  fortran_api_map_string_out(a##n, _a##n, l##n); FORTRAN_API_MAP_OUT_STRING(n)
#define FORTRAN_API_MAP_OUT_INT(n)
#define FORTRAN_API_MAP_OUT_PINT(n)
#define FORTRAN_API_MAP_OUT_INT32(n)
#define FORTRAN_API_MAP_OUT_PINT32(n)
#define FORTRAN_API_MAP_OUT_FLOAT64(n)
#define FORTRAN_API_MAP_OUT_PFLOAT64(n)


/*
 * Macros used to generate extra argument lists
 */
#define FORTRAN_API_MAP_OUT_GENERATE(type, n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_MAP_OUT_,type)(n)) 
#define FORTRAN_API_MAP_OUT(type,n) FORTRAN_API_MAP_OUT_GENERATE(FORTRAN_API_TYPEMAP(type), n)
//#define FORTRAN_API_MAP_OUT(type,n) FORTRAN_API_EXPAND(FORTRAN_API_COMBINE2(FORTRAN_API_MAP_OUT_,type)(n)) 
#define FORTRAN_API_MAP_OUT1(t1) FORTRAN_API_MAP_OUT(t1,1)
#define FORTRAN_API_MAP_OUT2(t1,t2) FORTRAN_API_MAP_OUT1(t1) FORTRAN_API_MAP_OUT(t2,2)
#define FORTRAN_API_MAP_OUT3(t1,t2,t3) FORTRAN_API_MAP_OUT2(t1,t2) FORTRAN_API_MAP_OUT(t3,3)
#define FORTRAN_API_MAP_OUT4(t1,t2,t3,t4) FORTRAN_API_MAP_OUT3(t1,t2,t3) FORTRAN_API_MAP_OUT(t4,4)
#define FORTRAN_API_MAP_OUT5(t1,t2,t3,t4,t5) FORTRAN_API_MAP_OUT4(t1,t2,t3,t4) FORTRAN_API_MAP_OUT(t5,5)
#define FORTRAN_API_MAP_OUT6(t1,t2,t3,t4,t5,t6) FORTRAN_API_MAP_OUT5(t1,t2,t3,t4,t5) FORTRAN_API_MAP_OUT(t6,6)
#define FORTRAN_API_MAP_OUT7(t1,t2,t3,t4,t5,t6,t7) FORTRAN_API_MAP_OUT6(t1,t2,t3,t4,t5,t6) FORTRAN_API_MAP_OUT(t7,7)
#define FORTRAN_API_MAP_OUT8(t1,t2,t3,t4,t5,t6,t7,t8) FORTRAN_API_MAP_OUT7(t1,t2,t3,t4,t5,t6,t7) FORTRAN_API_MAP_OUT(t8,8)
#define FORTRAN_API_MAP_OUT9(t1,t2,t3,t4,t5,t6,t7,t8,t9) FORTRAN_API_MAP_OUT8(t1,t2,t3,t4,t5,t6,t7,t8) FORTRAN_API_MAP_OUT(t9,9)
#define FORTRAN_API_MAP_OUT10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) FORTRAN_API_MAP_OUT9(t1,t2,t3,t4,t5,t6,t7,t8,t9) FORTRAN_API_MAP_OUT(t10,10)
#define FORTRAN_API_MAP_OUT11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11) FORTRAN_API_MAP_OUT10(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10) FORTRAN_API_MAP_OUT(t11,11)
#define FORTRAN_API_MAP_OUT12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12) FORTRAN_API_MAP_OUT11(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11) FORTRAN_API_MAP_OUT(t12,12)
#define FORTRAN_API_MAP_OUT13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13) FORTRAN_API_MAP_OUT12(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12) FORTRAN_API_MAP_OUT(t13,13)
#define FORTRAN_API_MAP_OUT14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14) FORTRAN_API_MAP_OUT13(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13) FORTRAN_API_MAP_OUT(t14,14)
#define FORTRAN_API_MAP_OUT15(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15) FORTRAN_API_MAP_OUT14(t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14) FORTRAN_API_MAP_OUT(t15,15)


/*
 * Macros used to count the number of args/parameters in a list. This can handle lists 
 * of up to 15 values. This is the key to allowing a single API declaration macro that
 * can handle variable length argument lists.
 */
#define FORTRAN_API_COUNT_LIST(...) FORTRAN_API_EXPAND(FORTRAN_API_CHECK_LIST(__VA_ARGS__,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0))
#define FORTRAN_API_CHECK_LIST(_1,_2_,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_14,_15,N,...) N


/*
 * Macros used to automtically create the appropriate argument or parameter list
 * based on the number of arguments.
 */
#define FORTRAN_API_MACRO_NAME(name,...) FORTRAN_API_MAKENAME2(name,FORTRAN_API_COUNT_LIST(__VA_ARGS__)) 
#define FORTRAN_API_ARG_LIST(...) FORTRAN_API_EXPAND(FORTRAN_API_MACRO_NAME(FORTRAN_API_ARGS,__VA_ARGS__)(__VA_ARGS__)) FORTRAN_API_EXPAND(FORTRAN_API_MACRO_NAME(FORTRAN_API_ARGX,__VA_ARGS__)(__VA_ARGS__))
#define FORTRAN_API_PARAM_LIST(...) FORTRAN_API_EXPAND(FORTRAN_API_MACRO_NAME(FORTRAN_API_PARAMS,__VA_ARGS__)(__VA_ARGS__))


/*
 * Macros used to handle return values. There are two aspects to this. The first is to
 * capture a return value from the internal function call. The second is to return
 * the value to the caller. 'void' is the special case here, since it indicates no
 * return value. These macros use a special case to generate a list of different
 * lengths, depending upon whether the return type is VOID or not, allowing us to
 * pick the value we want from a known position.
 */
#define FORTRAN_API_CAPTURE_RETURN_VOID _,

#define FORTRAN_API_SELECT_2(_1,_2,...) _2
#define FORTRAN_API_SELECT_RETURN(...) FORTRAN_API_EXPAND(FORTRAN_API_SELECT_2(__VA_ARGS__))

#define FORTRAN_API_CAPTURE_RETURN(type) FORTRAN_API_SELECT_RETURN(FORTRAN_API_COMBINE2(FORTRAN_API_CAPTURE_RETURN_,type),FORTRAN_API_COMBINE2(FORTRAN_API_TYPE_,type) retval =)
#define FORTRAN_API_RETURN(type) FORTRAN_API_SELECT_RETURN(FORTRAN_API_COMBINE2(FORTRAN_API_CAPTURE_RETURN_,type), return retval;)



/*
 * Macro to generate a fortran based wrapper function. This is the macro used to declare API
 * functions and automatically generate the wrapper code. Arguments are as follows:
 *  rettype     The function return type (INT32, FLOAT64, VOID, etc)
 *  name        The function name exactly as defined in the C code
 *  uc          The upper case form of the function name (macros cannot do this case conversion)
 *  lc          The lower case form of the function name
 *  ...         Additional parameter arguments (INT32, FLOAT64, STRING, etc )
 */
#define FORTRAN_API_FN(rettype, name, uc, lc, ...)                                                      \
    FORTRAN_API_COMBINE2(FORTRAN_API_TYPE_,rettype)                                                     \
    FORTRAN_API_MAKENAME3(FORTRAN_API_PREFIX,FORTRAN_API_NAME_SELECT(name,uc,lc),FORTRAN_API_SUFFIX)    \
    (FORTRAN_API_ARG_LIST(__VA_ARGS__))                                                                 \
    {                                                                                                   \
        FORTRAN_API_EXPAND(FORTRAN_API_MACRO_NAME(FORTRAN_API_MAP_IN,__VA_ARGS__)(__VA_ARGS__))         \
        FORTRAN_API_CAPTURE_RETURN(rettype) name(FORTRAN_API_PARAM_LIST(__VA_ARGS__));                  \
        FORTRAN_API_EXPAND(FORTRAN_API_MACRO_NAME(FORTRAN_API_MAP_OUT,__VA_ARGS__)(__VA_ARGS__))        \
        FORTRAN_API_RETURN(rettype)                                                                     \
    }



#endif   // __FORTRAN_API_H__