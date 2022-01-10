#ifndef _VDEV_IF_H_
#define _VDEV_IF_H_

#include "std_types.h"

typedef Std_ReturnType (*VdevIfComInit)(void);
typedef Std_ReturnType (*VdevIfComSend)(const unsigned char *buf, int len);
typedef Std_ReturnType (*VdevIfComRecv)(unsigned char *buf, int len);

typedef struct {
  VdevIfComInit init; // called by framework
  VdevIfComSend send;
  VdevIfComRecv receive;
} VdevIfComMethod;

typedef int (*VdevIfFunc)(const VdevIfComMethod *com);

typedef struct {
  VdevIfFunc init;

} VdevProtocolHandler;
  
#endif
