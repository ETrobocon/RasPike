/**
 * This sample program balances a two-wheeled Segway type robot such as Gyroboy in EV3 core set.
 *
 * References:
 * http://www.hitechnic.com/blog/gyro-sensor/htway/
 * http://www.cs.bgu.ac.il/~ami/teaching/Lejos-2013/classes/src/lejos/robotics/navigation/Segoway.java
 */

#include "ev3api.h"
#include "app.h"

#include <mruby.h>
#include <mruby/compile.h>
#include "mruby/irep.h"
#include "mruby/debug.h"
#include "mruby/opcode.h"
#include "mruby/value.h"
#include "mruby/string.h"
#include "mruby/array.h"
#include "mruby/proc.h"

//#define DEBUG

#ifdef DEBUG
#define _debug(x) (x)
#else
#define _debug(x)
#endif

#define ERR_CHECK(err)  \
do {    \
    if ((err) != 0) {   \
        syslog(LOG_NOTICE, "ERROR: %s %d err=%d", __FUNCTION__, __LINE__, (err));   \
    }   \
} while (0)

#include "main_task.h"
void main_task(intptr_t unused)
{
    syslog(LOG_NOTICE, "#### main_task start!");

	static mrb_state *mrb = NULL;
	mrb_value ret;
	mrb = mrb_open();
	struct RClass * ev3rt = mrb_class_get(mrb, "EV3RT");
    mrb_define_const(mrb, ev3rt, "MAIN_TASK", mrb_fixnum_value(MAIN_TASK));

    ret = mrb_load_irep (mrb, bcode);
    if(mrb->exc){
        syslog(LOG_NOTICE, "#### load_irep done");
        if(!mrb_undef_p(ret)){
            syslog(LOG_NOTICE, "#### EV3way-ET ERR");
		    mrb_value s = mrb_funcall(mrb, mrb_obj_value(mrb->exc), "inspect", 0);
		    if (mrb_string_p(s)) {
                char *p = RSTRING_PTR(s);
                syslog(LOG_NOTICE, "#### mruby err msg:%s", p);
		    } else {
            syslog(LOG_NOTICE, "#### error unknown!");
		    }
		}else{
            syslog(LOG_NOTICE, "#### mrb_undef_p(ret)");
        }
     }else{
         // 正常終了
        syslog(LOG_NOTICE, "#### mruby exit OK");
     }
    mrb_close(mrb);
//?    ext_tsk();
}
