/*
 * ev3rt_config.c
 *
 *  Created on: Mar 31, 2015
 *      Author: liyixiao
 */

#include "ev3.h"
#include "minIni.h"
#include "btstack-interface.h"
#include "target_serial.h"

#define CFG_INI_FILE  ("/ev3rt/etc/rc.conf.ini")

const char   *ev3rt_bluetooth_local_name;
const char   *ev3rt_bluetooth_pin_code;
const int    *ev3rt_bluetooth_pan_disabled;
const char   *ev3rt_bluetooth_ip_address;
const bool_t *ev3rt_sensor_port_1_disabled;
const bool_t *ev3rt_usb_auto_terminate_app;
int           DEBUG_UART;
int           SIO_PORT_DEFAULT;

void ev3rt_load_configuration() {
	/**
	 * Create '/ev3rt/etc/'
	 */
	f_mkdir("/ev3rt");
	f_mkdir("/ev3rt/etc");

    char sio_default_port[5];
	ini_gets("Debug", "DefaultPort", NULL, sio_default_port, 5, CFG_INI_FILE);
    if (!strcasecmp("UART", sio_default_port)) {
        SIO_PORT_DEFAULT = SIO_PORT_UART;
    } else if (!strcasecmp("BT", sio_default_port)) {
        SIO_PORT_DEFAULT = SIO_PORT_BT;
    } else { // Use LCD by default
        SIO_PORT_DEFAULT = SIO_PORT_LCD;
	    ini_puts("Debug", "DefaultPort", "LCD", CFG_INI_FILE);
    }

	static char localname[100];
	ini_gets("Bluetooth", "LocalName", "Mindstorms EV3", localname, 100, CFG_INI_FILE);
	ini_puts("Bluetooth", "LocalName", localname, CFG_INI_FILE);
	ev3rt_bluetooth_local_name = localname;

	static char pincode[17];
	ini_gets("Bluetooth", "PinCode", "0000", pincode, 17, CFG_INI_FILE);
	ini_puts("Bluetooth", "PinCode", pincode, CFG_INI_FILE);
	ev3rt_bluetooth_pin_code = pincode;

	static int disable_pan;
#if !defined(BUILD_LOADER) // TODO: Bluetooth PAN is only supported by loader currently
    disable_pan = 1;
#else
	disable_pan = ini_getbool("Bluetooth", "DisablePAN", false, CFG_INI_FILE);
	ini_putl("Bluetooth", "DisablePAN", disable_pan, CFG_INI_FILE);
#endif
	ev3rt_bluetooth_pan_disabled = &disable_pan;

    // TODO: check valid IP address
	static char ip_address[16];
	ini_gets("Bluetooth", "IPAddress", "10.0.10.1", ip_address, 17, CFG_INI_FILE);
	ini_puts("Bluetooth", "IPAddress", ip_address, CFG_INI_FILE);
	ev3rt_bluetooth_ip_address = ip_address;

	static bool_t disable_port_1;
	disable_port_1 = ini_getbool("Sensors", "DisablePort1", false, CFG_INI_FILE);
	ini_putl("Sensors", "DisablePort1", disable_port_1, CFG_INI_FILE);
    if (SIO_PORT_DEFAULT == SIO_PORT_UART) disable_port_1 = true;
    DEBUG_UART = disable_port_1 ? 0 : 4;
	ev3rt_sensor_port_1_disabled = &disable_port_1;

	static bool_t auto_term_app;
	auto_term_app = ini_getbool("USB", "AutoTerminateApp", true, CFG_INI_FILE);
	ini_putl("USB", "AutoTerminateApp", auto_term_app, CFG_INI_FILE);
	ev3rt_usb_auto_terminate_app = &auto_term_app;
}

#if !defined(BUILD_LOADER)
void bnep_channel_receive_callback(uint8_t *packet, uint16_t size) {}
#endif

