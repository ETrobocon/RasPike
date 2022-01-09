#ifndef _DRIVER_TYPES_H_
#define _DRIVER_TYPES_H_

typedef unsigned int DrvUint32Type;
typedef unsigned short DrvUint16Type;
typedef unsigned char DrvUint8Type;

typedef signed int DrvInt32Type;
typedef signed short DrvInt16Type;
typedef signed char DrvInt8Type;

#ifndef FALSE
#define FALSE	0U
#endif /* TRUE */

#ifndef TRUE
#define TRUE	( !(FALSE) )
#endif /* TRUE */

#endif /* _DRIVER_TYPES_H_ */
