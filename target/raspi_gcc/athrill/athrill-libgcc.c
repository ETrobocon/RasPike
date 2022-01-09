#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

//#include "athrill_syscall.h"
#include "driver_interface_filesys.h"
#include "ev3api.h"

unsigned int athrill_device_func_call __attribute__ ((section(".athrill_device_section")));

#define _PARAMS(args) args

// Special FD Handling
// (to convert one fd to in or out for bluetooth )
// index is fd for out. if the value is 0, it means the fd is normal file


ER filesys_opendir(const char *path) {
		
  //	return athrill_ev3_opendir((sys_addr)path);
  // TODO: implement
  return 0;
}

ER filesys_readdir(ID dirid, fatfs_filinfo_t *p_fileinfo) 
{

  //	return athrill_ev3_readdir(dirid, p_fileinfo);
  // TODO: implemant
  return 0;
}

ER filesys_closedir(ID dirid) 
{

  // return athrill_ev3_closedir(dirid);
  // TODO: implement
  return 0;
}

ER filesys_serial_open(sys_serial_port_t port)
{
  #if 0
	int fd = 0; // Default is stdout
	sys_int32 sys_port;
	
	if ( port == SYS_EV3_SERIAL_UART ) {
		sys_port = SYS_SERIAL_UART;
	} else if ( port == SYS_EV3_SERIAL_BT ) {
		sys_port = SYS_SERIAL_BT;
	} else {
		return -1;
	}

	fd = athrill_ev3_serial_open(sys_port);

	return fd;
  #endif

	// TODO: implement
	return -1;
}


