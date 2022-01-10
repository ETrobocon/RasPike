#ifndef _VDEV_PRIVATE_H_
#define _VDEV_PRIVATE_H_

#include "vdev.h"
#include "std_errno.h"
#include "udp_comm.h"

typedef struct {
	UdpCommConfigType config;

	uint32		cpu_freq;
	uint64 		vdev_sim_time[VDEV_SIM_INX_NUM]; /* usec */
	/*
	 * for UDP ONLY
	 */
	UdpCommType comm;
	char *remote_ipaddr;
	char *local_ipaddr;

} VdevControlType;
extern VdevControlType vdev_control;


#endif
