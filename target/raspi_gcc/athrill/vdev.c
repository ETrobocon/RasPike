#include "vdev.h"

/* assume this area is cleared by C runtime */
unsigned char athrill_vdev_mem[VDEV_RX_DATA_SIZE+VDEV_TX_FLAG_SIZE+VDEV_TX_FLAG_SIZE];
