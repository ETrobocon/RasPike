#ifndef _ATHRILL_SERIAL_H_
#define _ATHRILL_SERIAL_H_

#include "driver_types.h"
#include "athrill_serial_fifo.h"

extern int athrill_serial_init(DrvInt32Type channel, DrvUint32Type baud);
extern int athrill_serial_set_baud(DrvInt32Type channel, DrvUint32Type baud);
extern int athrill_serial_send(DrvInt32Type channel, const char* at_cmd);
extern int athrill_serial_send_data(DrvInt32Type channel, const char* datap, DrvInt32Type datalen);
extern int athrill_serial_readline(DrvInt32Type channel, char* bufferp, DrvInt32Type bufflen);
extern int athrill_serial_read_data(DrvInt32Type channel, char* bufferp, DrvInt32Type bufflen);
extern int athrill_serial_skip_newline(DrvInt32Type channel);

extern void serial_fifo0_intr_rx(void);
extern void serial_fifo0_intr_tx(void);
extern void serial_fifo1_intr_rx(void);
extern void serial_fifo1_intr_tx(void);

#define ATHRILL_SERIAL_FIFO_CH0_RX_INTNO	57
#define ATHRILL_SERIAL_FIFO_CH0_TX_INTNO	65
#define ATHRILL_SERIAL_FIFO_CH1_RX_INTNO	58
#define ATHRILL_SERIAL_FIFO_CH1_TX_INTNO	66

#endif /* _ATHRILL_SERIAL_H_ */
