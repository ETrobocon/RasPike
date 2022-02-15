#include "option.h"
#include "devconfig.h"
#include "target_kernel_impl.h"
#include "main.h"
#include <sys/time.h>
#include <sys/resource.h>

StartUpCb deviceStartupCb = 0;

/*
 *  メイン関数
 */
int
main(int argc, const char *argv[])
{
  	Std_ReturnType err;
	sigset_t			sigmask;
	stack_t				ss;
	struct sigaction	sigact;

	CmdOptionType *opt;
	
	opt = parse_args(argc, argv);
        if (opt == NULL) {
                return 1;
        }

	if (opt->devcfgpath != NULL) {
	  err = cpuemu_load_devcfg(opt->devcfgpath);
	  if (err != STD_E_OK) {
	    return -1;
	  }
	}

	if ( deviceStartupCb ) {
	  int ret = (*deviceStartupCb)();
	}

	sleep(1);

	
	setpriority(PRIO_PROCESS,0,-10);
	
	target_main();
}
