#ifndef _VDEV_H_
#define _VDEV_H_

#define VDEV_BASE			0x090F0000

#define VDEV_RX_DATA_BASE	VDEV_BASE
#define VDEV_RX_DATA_SIZE	0x1000

#define VDEV_TX_DATA_BASE	(VDEV_BASE + VDEV_RX_DATA_SIZE)
#define VDEV_TX_DATA_SIZE	0x1000

#define VDEV_TX_FLAG_BASE	(VDEV_TX_DATA_BASE + VDEV_TX_DATA_SIZE)
#define VDEV_TX_FLAG_SIZE	0x1000

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
