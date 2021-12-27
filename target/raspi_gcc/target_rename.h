/* This file is generated from target_rename.def by genrename. */

#ifndef TOPPERS_TARGET_RENAME_H
#define TOPPERS_TARGET_RENAME_H

/*
 *  kernel_cfg.c
 */
#define sigmask_table				_kernel_sigmask_table
#define sigmask_disint_init			_kernel_sigmask_disint_init

/*
 *  target_kernel_impl.c
 */
#define sigmask_intlock				_kernel_sigmask_intlock
#define sigmask_cpulock				_kernel_sigmask_cpulock
#define lock_flag					_kernel_lock_flag
#define saved_sigmask				_kernel_saved_sigmask
#define intpri_value				_kernel_intpri_value
#define sigmask_disint				_kernel_sigmask_disint
#define dispatch					_kernel_dispatch
#define exit_and_dispatch			_kernel_exit_and_dispatch
#define call_exit_kernel			_kernel_call_exit_kernel
#define start_r						_kernel_start_r
#define target_initialize			_kernel_target_initialize
#define target_exit					_kernel_target_exit

/*
 *  target_timer.c
 */
#define target_timer_initialize		_kernel_target_timer_initialize
#define target_timer_terminate		_kernel_target_timer_terminate
#define target_hrt_get_current		_kernel_target_hrt_get_current
#define target_hrt_set_event		_kernel_target_hrt_set_event
#define target_hrt_raise_event		_kernel_target_hrt_raise_event
#define target_ovrtimer_start		_kernel_target_ovrtimer_start
#define target_ovrtimer_stop		_kernel_target_ovrtimer_stop
#define target_ovrtimer_get_current	_kernel_target_ovrtimer_get_current
#define target_timer_handler		_kernel_target_timer_handler

/*
 *  tTraceLog.c
 */
#define log_dsp_enter				_kernel_log_dsp_enter
#define log_dsp_leave				_kernel_log_dsp_leave
#define log_inh_enter				_kernel_log_inh_enter
#define log_inh_leave				_kernel_log_inh_leave
#define log_exc_enter				_kernel_log_exc_enter
#define log_exc_leave				_kernel_log_exc_leave


#endif /* TOPPERS_TARGET_RENAME_H */
