#include <stdio.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "udp_comm.h"
#include "errno.h"

#define UDP_COMM_BLOCKING		0
#define UDP_COMM_NONBLOCKING	1

Std_ReturnType udp_comm_create_ipaddr(const UdpCommConfigType *config, UdpCommType *comm, const char* my_ipaddr)
{
	int err;
	struct sockaddr_in addr;
	u_long val;

	err = socket(AF_INET, SOCK_DGRAM, 0);
	if (err < 0) {
		return STD_E_INVALID;
	}
	comm->srv_sock = err;

	addr.sin_family = AF_INET;
	addr.sin_port = htons(config->server_port);
	if (my_ipaddr == NULL) {
		addr.sin_addr.s_addr = INADDR_ANY;
	}
	else {
		addr.sin_addr.s_addr = inet_addr(my_ipaddr);
	}

	err = bind(comm->srv_sock, (struct sockaddr *)&addr, sizeof(addr));
	if (err < 0) {
		return STD_E_INVALID;
	}

	if (!(config->is_wait)) {
		val = UDP_COMM_NONBLOCKING;
	}
	else {
		val = UDP_COMM_BLOCKING;
	}
	ioctl(comm->srv_sock, FIONBIO, &val);

	comm->client_port = htons(config->client_port);

	return STD_E_OK;
}
Std_ReturnType udp_comm_create(const UdpCommConfigType *config, UdpCommType *comm)
{
	return udp_comm_create_ipaddr(config, comm, NULL);
}

Std_ReturnType udp_comm_read(UdpCommType *comm)
{
	int err;

	while(1) {
	  err = recv(comm->srv_sock, comm->read_data.buffer, sizeof(comm->read_data.buffer), 0);
	  if ( err >= 0 ) {
	    comm->read_data.len = err;
	    return STD_E_OK;
	  } else if (errno != EAGAIN && errno != EINTR ) {
	    return STD_E_INVALID;
	  } else {
	    // retry
	  }
	}
	// not reached
	return STD_E_OK;
}

Std_ReturnType udp_comm_read_with_timeout(UdpCommType *comm, struct timeval *timeout)
{
	int err;

	fd_set fdset;
	FD_ZERO(&fdset);
	FD_SET(comm->srv_sock,&fdset);

	err = select(comm->srv_sock+1, &fdset, 0, 0, timeout);

	if ( err == -1 ) {
		// error
		return STD_E_INVALID;
	} else if ( err ) {
		// read success
		return udp_comm_read(comm);
	} else {
		// timeout occured
		return STD_E_TIMEOUT;
	}

}

Std_ReturnType udp_comm_write(UdpCommType *comm)
{
	int err;

	struct sockaddr_in addr;

	err = socket(AF_INET, SOCK_DGRAM, 0);
	if (err < 0) {
		return STD_E_INVALID;
	}
	comm->clt_sock = err;

	addr.sin_family = AF_INET;
	addr.sin_port = comm->client_port;
	addr.sin_addr.s_addr = inet_addr("127.0.0.1");

	while (1) {
	  err = sendto(comm->clt_sock, comm->write_data.buffer, comm->write_data.len, 0,
		       (struct sockaddr *)&addr, sizeof(addr));
	  if ( err > 0 ) {
	    if ( err  != comm->write_data.len) {
	      return STD_E_INVALID;
	    }
	    break; // valid
	  } else  if ( err < 0 && ( errno != EAGAIN && errno != EINTR )) {
	    return STD_E_INVALID;
	  }
	  // err == 0 or EAGIN, EINTR call again
	}
	close(comm->clt_sock);
	comm->clt_sock = -1;

	return STD_E_OK;
}
Std_ReturnType udp_comm_remote_write(UdpCommType *comm, const char *remote_ipaddr)
{
	int err;

	struct sockaddr_in addr;

	err = socket(AF_INET, SOCK_DGRAM, 0);
	if (err < 0) {
		return STD_E_INVALID;
	}
	comm->clt_sock = err;

	addr.sin_family = AF_INET;
	addr.sin_port = comm->client_port;
	addr.sin_addr.s_addr = inet_addr(remote_ipaddr);

	while (1) {
	  err = sendto(comm->clt_sock, comm->write_data.buffer, comm->write_data.len, 0,
		       (struct sockaddr *)&addr, sizeof(addr));
	  if ( err > 0 ) {
	    if ( err  != comm->write_data.len) {
	      return STD_E_INVALID;
	    }
	    break; // valid
	  } else  if ( err < 0 && ( errno != EAGAIN && errno != EINTR )) {
	    return STD_E_INVALID;
	  }
	  // err == 0 or EAGIN, EINTR call again
	}

	close(comm->clt_sock);
	comm->clt_sock = -1;

	return STD_E_OK;
}

void udp_server_delete(UdpCommType *comm)
{
	close(comm->srv_sock);
	comm->srv_sock = -1;
	return;
}
