﻿#ifndef _STD_TYPES_H_
#define _STD_TYPES_H_

typedef signed char sint8;
typedef signed short sint16;
typedef signed int sint32;
typedef signed long long sint64;

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;
typedef unsigned long long uint64;
typedef int	bool;
typedef int std_bool;
#define DEFINE_FLOAT_TYPEDEF
typedef float float32;
typedef double float64;

typedef uint32 Std_ReturnType;

typedef uint32 CoreIdType;


#ifndef NULL
#define NULL	((void*)0)
#endif

#ifndef TRUE
#define TRUE	(1U)
#endif

#ifndef FALSE
#define FALSE	(0U)
#endif

#ifndef UINT_C
#define UINT_C(val)		(val ## U)
#endif /* UINT_C */


#ifdef __i386__
#define CAST_UINT32_TO_ADDR(uint32_data) ( (void*)((uint32)(uint32_data)) )
#elif __x86_64__
#define CAST_UINT32_TO_ADDR(uint32_data) ( (void*)((uint64)(uint32_data)) )
#elif __arm64
#define CAST_UINT32_TO_ADDR(uint32_data) ( (void*)((uint64)(uint32_data)) )
#elif __arm__
#define CAST_UINT32_TO_ADDR(uint32_data) ( (void*)((uint32)(uint32_data)) )
#else
#error "unknown arch."
#endif

#endif /* _STD_TYPES_H_ */
