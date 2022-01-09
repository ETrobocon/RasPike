// tag::tracer_def[]
#include "app.h"
#include <stdio.h>
#include <math.h>

#include "athrill_syscall.h"

void main_task(intptr_t unused) {
	sta_cyc(CYC_PRD_TSK_1);
	while(1){;}
}

void sub_task(intptr_t unused) {
	static int num = 0;
	if ( num == 0 ) {
		athrill_reset_time();
	}
	if ( (++num % 100) == 0 ) {
		printf( "EV3 Time = %d msec:",10*num);
		athrill_show_time();

	}
	ext_tsk();
}


// end::main_task[]
