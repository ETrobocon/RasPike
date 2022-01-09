// tag::tracer_def[]
#include "app.h"
#include <stdio.h>
#include <math.h>
#define CHECK(title, cond) \
	if ( (cond) ) { \
		syslog(LOG_NOTICE, #title ": suceeded \n"); \
	} else { \
		syslog(LOG_NOTICE, #title ": failed \n"); \
	}		
// end::tracer_def[]
// tag::main_task[]
void main_task(intptr_t unused) {

	// Bluetooth仮想シリアルポートのファイルをオープンする
	FILE *bt = ev3_serial_open_file(EV3_SERIAL_BT);

	// 書式化した文字列をBluetooth仮想シリアルポートへ書き込む
	fprintf(bt, "Bluetooth SPP ID: %d\n", EV3_SERIAL_BT);

	// Bluetooth仮想シリアルポートから1文字を読み取る
	int c;
	while(1) {
		c = fgetc(bt);
		syslog(LOG_NOTICE,"Input was=%d\n",c);
		tslp_tsk(1000000);
	//	fprintf(bt, "Bluetooth SPP ID: %d\n", EV3_SERIAL_BT);
	}
}
// end::main_task[]
