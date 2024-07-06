#include "app.h"
#include <stdio.h>
#include "LineTracer.h"

/* センサーポートの定義 */
static const pbio_port_id_t
  color_sensor_port    = PBIO_PORT_ID_C,
  left_motor_port      = PBIO_PORT_ID_E,
  right_motor_port     = PBIO_PORT_ID_B; 

/* メインタスク(起動時にのみ関数コールされる) */
void main_task(intptr_t unused) {

  /* LineTracerに構成を渡す */
  LineTracer_Configure(left_motor_port,right_motor_port,color_sensor_port);
  printf("Start Line Trace!!\n");
    
  /* ライントレースタスクの起動 */
  sta_cyc(LINE_TRACER_TASK_CYC);

  /* タスク終了 */
  ext_tsk();
}
