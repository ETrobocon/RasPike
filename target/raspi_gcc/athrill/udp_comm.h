#ifndef _UDP_SERVER_H_
#define _UDP_SERVER_H_

#include "udp_common.h"

typedef struct {
	int 			srv_sock;
	UdpBufferType	read_data;

	uint32			client_port;
	int 			clt_sock;
	UdpBufferType	write_data;
} UdpCommType;

extern Std_ReturnType udp_comm_create(const UdpCommConfigType *config, UdpCommType *comm);
extern Std_ReturnType udp_comm_create_ipaddr(const UdpCommConfigType *config, UdpCommType *comm, const char* my_ipaddr);

extern Std_ReturnType udp_comm_read(UdpCommType *comm);
extern Std_ReturnType udp_comm_write(UdpCommType *comm);
extern Std_ReturnType udp_comm_remote_write(UdpCommType *comm, const char *remote_ipaddr);
extern void udp_server_delete(UdpCommType *comm);
extern Std_ReturnType udp_comm_read_with_timeout(UdpCommType *comm, struct timeval *timeout);

#endif /* _UDP_SERVER_H_ */
