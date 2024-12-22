#ifndef _VDEV_H_
#define _VDEV_H_

#include "std_types.h"
#include <stdint.h>

extern unsigned char athrill_vdev_mem[];

//#define VDEV_BASE			0x090F0000
#define VDEV_BASE 		((uintptr_t)(athrill_vdev_mem))


#define VDEV_RX_DATA_BASE	VDEV_BASE
#define VDEV_RX_DATA_SIZE	0x1000

#define VDEV_RX_DATA_COMM_SIZE	1024U
#define VDEV_RX_DATA_HEAD_OFF	0U
#define VDEV_RX_DATA_HEAD_SIZE	32U
#define VDEV_RX_DATA_BODY_OFF	VDEV_RX_DATA_HEAD_SIZE
#define VDEV_RX_DATA_HEAD_HEADER	"ETRX"
#define VDEV_RX_DATA_HEAD_VERSION	1U
#define VDEV_RX_DATA_HEAD_EXT_OFF	512U
#define VDEV_RX_DATA_HEAD_EXT_SIZE	512U
typedef struct {
	uint8	header[4U];				/* 0 */
	uint32	version;				/* 4 */
	uint8	reserve[8U];			/* 8 */
	uint64	unity_simtime;			/* 16 */
	uint32	ext_off;				/* 24 */
	uint32	ext_size;				/* 28 */
} VdevRxDataHeadType;



#define VDEV_TX_DATA_BASE	(VDEV_BASE + VDEV_RX_DATA_SIZE)
#define VDEV_TX_DATA_SIZE	0x1000

#define VDEV_TX_DATA_COMM_SIZE	1024U
#define VDEV_TX_DATA_HEAD_OFF	0U
#define VDEV_TX_DATA_HEAD_SIZE	32U
#define VDEV_TX_DATA_BODY_OFF	VDEV_TX_DATA_HEAD_SIZE
#define VDEV_TX_DATA_BODY_SIZE	(VDEV_TX_DATA_COMM_SIZE - VDEV_TX_DATA_HEAD_SIZE)
#define VDEV_TX_DATA_HEAD_HEADER	"ETTX"
#define VDEV_TX_DATA_HEAD_VERSION	1U
#define VDEV_TX_DATA_HEAD_EXT_OFF	512U
#define VDEV_TX_DATA_HEAD_EXT_SIZE	512U
typedef struct {
	uint8	header[4U];				/* 0 */
	uint32	version;				/* 4 */
	uint64	micon_simtime;			/* 8 */
	uint64	unity_simtime;			/* 16 */
	uint32	ext_off;				/* 24 */
	uint32	ext_size;				/* 28 */
} VdevTxDataHeadType;




#define VDEV_TX_FLAG_BASE	(VDEV_TX_DATA_BASE + VDEV_TX_DATA_SIZE)
#define VDEV_TX_FLAG_SIZE	0x1000

#define VDEV_TX_SIM_TIME_BASE	0x008
#define VDEV_TX_SIM_TIME_SIZE	0x010

#define VDEV_RX_SIM_TIME_BASE	0x010
#define VDEV_RX_SIM_TIME_SIZE	0x008

#define VDEV_TX_SIM_TIME(inx)		( VDEV_TX_SIM_TIME_BASE + ( (inx) * 8U ) )
#define VDEV_RX_SIM_TIME(inx)		( VDEV_RX_SIM_TIME_BASE + ( (inx) * 8U ) )

#define VDEV_SIM_INX_NUM		2U
#define VDEV_SIM_INX_ME			0U
#define VDEV_SIM_INX_YOU		1U

/*
 * RX VDEV DATA ADDR
 */
#define VDEV_RX_DATA(index)	(VDEV_RX_DATA_BASE + ( ( 4 * (index) + 0 ) ))

/*
 * TX VDEV DATA ADDR
 */
#define VDEV_TX_DATA(index)	(VDEV_TX_DATA_BASE + ( ( 4 * (index) + 0 ) ))

/*
 * TX VDEV FLAG ADDR
 */
#define VDEV_TX_FLAG(index)	(VDEV_TX_FLAG_BASE + ( ( 1 * (index) + 0 ) ))


#endif /* _VDEV_H_ */
