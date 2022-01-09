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

const int BODY_X_POSITION = 0;
const int BODY_Y_POSITION = 0;

float get_target_distance(float target_x_posision, float target_y_posision){
	float diff_x,diff_y;
	diff_x = target_x_posision - BODY_X_POSITION;
	diff_y = target_y_posision - BODY_Y_POSITION;
	return sqrt((diff_x * diff_x) + (diff_y * diff_y));
}

void main_task(intptr_t unused) {

    ev3_sensor_config(EV3_PORT_1,GYRO_SENSOR);
    ev3_motor_config(EV3_PORT_A,LARGE_MOTOR);
    ev3_motor_set_power(EV3_PORT_A,20);
    int i = 0;
    float steer;
    float error;
    float distance;
    int diff = -100.0;
    ev3_lcd_draw_string("TESTSTRING",0,0);

    while(1) {
	diff+=i;
	error = (100-i)*0.85;
	steer= ( 1.8*error+1.0*diff );
        syslog(LOG_NOTICE,"steer=%d",(int)steer);
        steer= ( 1.8f*error+1.0f*diff );
        syslog(LOG_NOTICE,"steer=%d",(int)steer);
	i++;
  	  if ( i % 5 == 0 ) {
	  	ev3_gyro_sensor_reset(EV3_PORT_1);
		  ev3_motor_reset_counts(EV3_PORT_A);
	    }

      syslog(LOG_NOTICE,"----------");
	distance = get_target_distance(steer,error); 
        syslog(LOG_NOTICE,"distance=%d",distance);
	tslp_tsk(500000);
   }
}


// end::main_task[]
