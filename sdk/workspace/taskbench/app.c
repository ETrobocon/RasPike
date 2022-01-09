// tag::tracer_def[]
#include "app.h"
#include <stdio.h>
#include <math.h>
#include <time.h>

struct timespec prev_time={0};

void main_task(intptr_t unused) {
	sta_cyc(CYC_PRD_TSK_1);
	while(1){;}
}

void sub_task(intptr_t unused) {
	static int num = 0;
	if ( num == 0 ) {
	  clock_gettime(CLOCK_MONOTONIC_COARSE,&prev_time);
	}
	if ( (++num % 100) == 0 ) {
	  struct timespec cur;
	  clock_gettime(CLOCK_MONOTONIC_COARSE,&cur);	  
	  int sec = cur.tv_sec - prev_time.tv_sec;
	  int nsec = 0;
	  if ( cur.tv_nsec >= prev_time.tv_nsec ) {
	    nsec = cur.tv_nsec - prev_time.tv_nsec;
	  } else {
	    nsec = 1000000 + cur.tv_nsec - prev_time.tv_nsec;
	    sec--;
	  }
	  printf( "EV3 Time =%d sec %d msec:%d\n",10*num,sec,nsec/1000000);
	  fflush(stdout);

	}
	ext_tsk();
}


// end::main_task[]
