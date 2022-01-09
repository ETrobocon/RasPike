//#include "api_common.h"
#include "ev3api.h"
#include "platform_interface_layer.h"
#include "syssvc/serial.h"
#include <stdlib.h>
#include <string.h>

void spp_master_test_connect_ev3(const uint8_t addr[6], const char *pin) {
    spp_master_test_connect(addr, pin); // TODO: check return value
}

bool_t spp_master_test_is_connected() {
	T_SERIAL_RPOR rpor;
	ER ercd = serial_ref_por(SIO_PORT_SPP_MASTER_TEST, &rpor);
	return ercd == E_OK;
}

FILE* spp_master_test_open_file() {
	int fd = SIO_PORT_SPP_MASTER_TEST_FILENO;

    FILE *fp = fdopen(fd, "a+");
    if (fp != NULL)
    	setbuf(fp, NULL); /* IMPORTANT! */
    else assert(false); //API_ERROR("fdopen() failed, fd: %d.", fd);
    return fp;
}

