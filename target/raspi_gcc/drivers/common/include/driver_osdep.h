#ifndef _DRIVER_OSDEP_H_
#define _DRIVER_OSDEP_H_

#include "driver_types.h"
#include "kernel.h"
#include "prc_config.h"

static inline void driver_os_lock(void)
{
	loc_cpu();
	return;
}
static inline void driver_os_unlock(void)
{
	unl_cpu();
	return;
}

static inline void driver_clear_intno(DrvUint32Type intno)
{
	x_clear_int(intno);
	return;
}
static inline void driver_os_sleep(DrvUint32Type msec)
{
	dly_tsk(msec);
	return;
}
#endif /* _DRIVER_OSDEP_H_ */
