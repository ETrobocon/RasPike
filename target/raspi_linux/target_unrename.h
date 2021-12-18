/* This file is generated from target_rename.def by genrename. */

/* This file is included only when target_rename.h has been included. */
#ifdef TOPPERS_TARGET_RENAME_H
#undef TOPPERS_TARGET_RENAME_H

/*
 *  kernel_cfg.c
 */
#undef sigmask_table
#undef sigmask_disint_init

/*
 *  target_kernel_impl.c
 */
#undef sigmask_intlock
#undef sigmask_cpulock
#undef lock_flag
#undef saved_sigmask
#undef intpri_value
#undef sigmask_disint
#undef dispatch
#undef exit_and_dispatch
#undef call_exit_kernel
#undef start_r
#undef target_initialize
#undef target_exit

/*
 *  target_timer.c
 */
#undef target_timer_initialize
#undef target_timer_terminate
#undef target_hrt_get_current
#undef target_hrt_set_event
#undef target_hrt_raise_event
#undef target_ovrtimer_start
#undef target_ovrtimer_stop
#undef target_ovrtimer_get_current
#undef target_timer_handler

/*
 *  tTraceLog.c
 */
#undef log_dsp_enter
#undef log_dsp_leave
#undef log_inh_enter
#undef log_inh_leave
#undef log_exc_enter
#undef log_exc_leave


#endif /* TOPPERS_TARGET_RENAME_H */
