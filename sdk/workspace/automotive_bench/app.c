// tag::tracer_def[]
#include "app.h"
#include <stdio.h>
#include <math.h>
#include "athrill_syscall.h"
#define CHECK(title, cond) \
	if ( (cond) ) { \
		syslog(LOG_NOTICE, #title ": suceeded \n"); \
	} else { \
		syslog(LOG_NOTICE, #title ": failed \n"); \
	}		
// end::tracer_def[]
// tag::main_task[]
void main_task(intptr_t unused) {
	athrill_reset_time();
	basic_math_main();
	athrill_show_time();
	printf("Finished\n");

}
// end::main_task[]
