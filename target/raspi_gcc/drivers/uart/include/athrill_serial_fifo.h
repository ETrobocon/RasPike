#ifndef _ATHRILL_SERIAL_FIFO_H_
#define _ATHRILL_SERIAL_FIFO_H_

#include "driver_osdep.h"

#define SERIAL_FIFO_CH_0	0
#define SERIAL_FIFO_CH_1	1
#define SERIAL_FIFO_CH_2	2
#define SERIAL_FIFO_CH_3	3
#define SERIAL_FIFO_CH_4	4
#define SERIAL_FIFO_CH_5	5
#define SERIAL_FIFO_CH_6	6
#define SERIAL_FIFO_CH_7	7
#define SERIAL_FIFO_MAX_CHANNEL_NUM					8U

#define SERIAL_FIFO_INTNO_RX_BASE	57
#define SERIAL_FIFO_INTNO_TX_BASE	(SERIAL_FIFO_INTNO_RX_BASE + SERIAL_FIFO_MAX_CHANNEL_NUM)
#define SERIAL_FIFO_RX_INTNO(ch)	(SERIAL_FIFO_INTNO_RX_BASE + (ch))
#define SERIAL_FIFO_TX_INTNO(ch)	(SERIAL_FIFO_INTNO_TX_BASE + (ch))

/*
 * Please configure SERIAL_FIFO_BASE_ADDR for your environment.
 */
#define SERIAL_FIFO_BASE_ADDR						(uintptr_t)0x03FF7000

#define SERIAL_FIFO_WRITE_STATUS_OFF				(SERIAL_FIFO_MAX_CHANNEL_NUM * 0U)
#define SERIAL_FIFO_WRITE_CMD_OFF					(SERIAL_FIFO_MAX_CHANNEL_NUM * 1U)
#define SERIAL_FIFO_WRITE_PTR_OFF					(SERIAL_FIFO_MAX_CHANNEL_NUM * 2U)
#define SERIAL_FIFO_READ_STATUS_OFF					(SERIAL_FIFO_MAX_CHANNEL_NUM * 3U)
#define SERIAL_FIFO_READ_CMD_OFF					(SERIAL_FIFO_MAX_CHANNEL_NUM * 4U)
#define SERIAL_FIFO_READ_PTR_OFF					(SERIAL_FIFO_MAX_CHANNEL_NUM * 5U)


/*
 * status:
 *  0x0: can write
 *  0x1: can not write(busy)
 */
#define SERIAL_FIFO_WRITE_STATUS_ADDR(base, ch)		((base) + SERIAL_FIFO_WRITE_STATUS_OFF + (ch))
/*
 * cmd:
 *  0x0: no cmd
 *  0x1: move one char data from fifo buffer
 */
#define SERIAL_FIFO_WRITE_CMD_ADDR(base, ch)		((base) + SERIAL_FIFO_WRITE_CMD_OFF + (ch))
#define SERIAL_FIFO_WRITE_PTR_ADDR(base, ch)		((base) + SERIAL_FIFO_WRITE_PTR_OFF    + (ch))

#define SERIAL_FIFO_WRITE_STATUS_CAN_DATA		0x0
#define SERIAL_FIFO_WRITE_STATUS_DATA_FULL		0x1

#define SERIAL_FIFO_WRITE_CMD_NONE				0x0
#define SERIAL_FIFO_WRITE_CMD_MOVE				0x1
#define SERIAL_FIFO_WRITE_CMD_TX				0x2


/*
 * status:
 *  0x0: can not read(no data)
 *  0x1: can read
 */
#define SERIAL_FIFO_READ_STATUS_ADDR(base, ch)		((base) + SERIAL_FIFO_READ_STATUS_OFF + (ch))
/*
 * cmd:
 *  0x0: no cmd
 *  0x1: move one char data from fifo buffer
 */
#define SERIAL_FIFO_READ_CMD_ADDR(base, ch)			((base) + SERIAL_FIFO_READ_CMD_OFF + (ch))
#define SERIAL_FIFO_READ_PTR_ADDR(base, ch)			((base) + SERIAL_FIFO_READ_PTR_OFF    + (ch))
#define SERIAL_FIFO_READ_STATUS_NO_DATA			0x0
#define SERIAL_FIFO_READ_STATUS_DATA_IN			0x1

#define SERIAL_FIFO_READ_CMD_NONE				0x0
#define SERIAL_FIFO_READ_CMD_MOVE				0x1

static inline int serial_fifo_write(DrvUint32Type ch, DrvUint8Type data)
{
	DrvUint8Type *cmd;
	DrvUint8Type *ptr;
	volatile DrvUint8Type *w_status = (DrvUint8Type *)SERIAL_FIFO_WRITE_STATUS_ADDR(SERIAL_FIFO_BASE_ADDR, ch);
	if (*w_status == SERIAL_FIFO_WRITE_STATUS_CAN_DATA) {
		ptr = (DrvUint8Type*)SERIAL_FIFO_WRITE_PTR_ADDR(SERIAL_FIFO_BASE_ADDR, ch);
		*ptr = data;
		cmd = (DrvUint8Type*)SERIAL_FIFO_WRITE_CMD_ADDR(SERIAL_FIFO_BASE_ADDR, ch);
		*cmd = SERIAL_FIFO_WRITE_CMD_MOVE;
		return 0;
	}
	else {
		return -1;
	}
}
static inline void serial_fifo_send(DrvUint32Type ch)
{
	DrvUint8Type *cmd;
	cmd = (DrvUint8Type*)SERIAL_FIFO_WRITE_CMD_ADDR(SERIAL_FIFO_BASE_ADDR, ch);
	*cmd = SERIAL_FIFO_WRITE_CMD_TX;
	return;
}

static inline int serial_fifo_read(DrvUint32Type ch, DrvUint8Type *data)
{
	DrvUint8Type *cmd;

	volatile DrvUint8Type *r_status = (DrvUint8Type *)SERIAL_FIFO_READ_STATUS_ADDR(SERIAL_FIFO_BASE_ADDR, ch);
	if (*r_status == SERIAL_FIFO_READ_STATUS_DATA_IN) {
		cmd = (DrvUint8Type*)SERIAL_FIFO_READ_CMD_ADDR(SERIAL_FIFO_BASE_ADDR, ch);
		*cmd = SERIAL_FIFO_READ_CMD_MOVE;
		*data = *(DrvUint8Type *)SERIAL_FIFO_READ_PTR_ADDR(SERIAL_FIFO_BASE_ADDR, ch);
		return 0;
	}
	else {
		return -1;
	}
}

#endif /* _ATHRILL_SERIAL_FIFO_H_ */
