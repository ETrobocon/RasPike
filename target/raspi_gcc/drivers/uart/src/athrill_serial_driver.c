#include "athrill_serial_driver.h"
#include <string.h>

/*
 * config
 */
#define SERIAL_WAIT_TIME	1000 /* msec */
#define SERIAL_RX_BUFFER_SIZE	128

typedef struct {
	DrvUint32Type count;
	DrvUint32Type roff;
	DrvUint32Type woff;
	DrvUint8Type data[SERIAL_RX_BUFFER_SIZE];
} AtSerialPeekDataStoreType;

static AtSerialPeekDataStoreType athrill_serial_peek_data_store[SERIAL_FIFO_MAX_CHANNEL_NUM];

static void athrill_serial_put_buffer(DrvInt32Type channel)
{
	DrvUint8Type c;
	while (TRUE) {
		if (athrill_serial_peek_data_store[channel].count >= SERIAL_RX_BUFFER_SIZE) {
			break;
		}
		int ret = serial_fifo_read(channel, &c);
		if (ret < 0) {
			break;
		}
		athrill_serial_peek_data_store[channel].data[athrill_serial_peek_data_store[channel].woff] = c;
		athrill_serial_peek_data_store[channel].count++;
		athrill_serial_peek_data_store[channel].woff++;
		if (athrill_serial_peek_data_store[channel].woff >= SERIAL_RX_BUFFER_SIZE) {
			athrill_serial_peek_data_store[channel].woff = 0;
		}
	}
	return;
}
static int athrill_serial_get_buffer(DrvInt32Type channel)
{
	int c;
	if (athrill_serial_peek_data_store[channel].count == 0) {
		return -1;
	}
	driver_os_lock();
	c = athrill_serial_peek_data_store[channel].data[athrill_serial_peek_data_store[channel].roff];
	athrill_serial_peek_data_store[channel].count--;
	athrill_serial_peek_data_store[channel].roff++;
	if (athrill_serial_peek_data_store[channel].roff >= SERIAL_RX_BUFFER_SIZE) {
		athrill_serial_peek_data_store[channel].roff = 0;
	}
	driver_os_unlock();
	return c;
}

static int athrill_serial_peek_buffer(DrvInt32Type channel)
{
	int c = -1;
	driver_os_lock();
	if (athrill_serial_peek_data_store[channel].count > 0) {
		c = athrill_serial_peek_data_store[channel].data[athrill_serial_peek_data_store[channel].roff];
	}
	driver_os_unlock();
	return c;
}

static int athrill_serial_peek(DrvInt32Type channel)
{
	driver_os_lock();
	athrill_serial_put_buffer(channel);
	driver_os_unlock();
	return athrill_serial_peek_buffer(channel);
}

static int athrill_serial_read(DrvInt32Type channel)
{
	driver_os_lock();
	athrill_serial_put_buffer(channel);
	driver_os_unlock();
	int c = athrill_serial_get_buffer(channel);
	if (c < 0) {
		return -1;
	}
	//syslog(LOG_NOTICE, "IN:%c", c);
	return c;
}

int athrill_serial_init(DrvInt32Type channel, DrvUint32Type baud)
{
	//nothing to do
	return 0;
}

int athrill_serial_set_baud(DrvInt32Type channel, DrvUint32Type baud)
{
	//nothing to do
	return 0;
}

int athrill_serial_send(DrvInt32Type channel, const char* at_cmd)
{
	int len = strlen(at_cmd);
	return athrill_serial_send_data(channel, at_cmd, (len + 1));
}

int athrill_serial_send_data(DrvInt32Type channel, const char* datap, DrvInt32Type datalen)
{
	int i;
	for (i = 0; i < datalen; i++) {
		//syslog(LOG_NOTICE, "OUT:%c", datap[i]);
		int ret = -1;
		do {
			ret = serial_fifo_write(channel, datap[i]);
			if (ret < 0) {
				serial_fifo_send(channel);
				driver_os_sleep(SERIAL_WAIT_TIME);
			}
		} while (ret < 0);
	}
	serial_fifo_send(channel);
	return i;
}

int athrill_serial_skip_newline(DrvInt32Type channel)
{
	int c;
	while (TRUE) {
		c = athrill_serial_peek(channel);
		if (c < 0) {
			driver_os_sleep(SERIAL_WAIT_TIME);
			continue;
		}
		if ((c == '\n') || (c == '\r')) {
			(void)athrill_serial_read(channel);
			continue;
		}
		else {
			break;
		}
	}
	return c;
}

int athrill_serial_readline(DrvInt32Type channel, char* bufferp, DrvInt32Type bufflen)
{
	int i = 0;
	int c;
	while (i < (bufflen - 1)) {
		c = athrill_serial_read(channel);
		if (c < 0) {
			driver_os_sleep(SERIAL_WAIT_TIME);
			continue;
		}
		bufferp[i] = (DrvUint8Type)c;
		if ((c == '\0') || (c == '\n') || (c == '\r')) {
			bufferp[i + 1] = '\0';
			break;
		}
		i++;
	}
	if (i == (bufflen -1)) {
		bufferp[bufflen - 1] = '\0';
	}
	return i;
}

int athrill_serial_read_data(DrvInt32Type channel, char* bufferp, DrvInt32Type bufflen)
{
	int i = 0;
	int c;
	while (i < bufflen){
		c = athrill_serial_read(channel);
		if (c < 0) {
			driver_os_sleep(SERIAL_WAIT_TIME);
			continue;
		}
		bufferp[i] = (DrvUint8Type)c;
		i++;
	}
	return i;
}

void athrill_serial_intr_rx(DrvInt32Type channel)
{
	driver_os_lock();
	athrill_serial_put_buffer(channel);
	driver_os_unlock();
	driver_clear_intno(SERIAL_FIFO_RX_INTNO(channel));
	return;
}

void athrill_serial_intr_tx(DrvInt32Type channel)
{
	driver_clear_intno(SERIAL_FIFO_TX_INTNO(channel));
	return;
}

void serial_fifo0_intr_rx(void)
{
	athrill_serial_intr_rx(0);
}

void serial_fifo0_intr_tx(void)
{
	athrill_serial_intr_tx(0);
}

void serial_fifo1_intr_rx(void)
{
	athrill_serial_intr_rx(1);
}

void serial_fifo1_intr_tx(void)
{
	athrill_serial_intr_tx(1);
}
