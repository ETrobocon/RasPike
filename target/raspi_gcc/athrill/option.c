#include "option/option.h"
#include "file.h"
#include <stdlib.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

static CmdOptionType cmd_option;

static int cmd_atoi(char *arg, uint64 *out)
{
	char *endptr;
	long long ret64;
	/*
	 * 10進数チェック
	 */
	errno = 0;
	ret64 = strtoll((const char*)arg, &endptr, 10);
	if ((errno == 0) && (*endptr == '\0')) {
		*out = ret64;
		return 0;
	}
	return -1;
}

static int cmd_atoi32(char *arg, uint32 *out)
{
	char *endptr;
	uint32 ret32;
	/*
	 * 10進数チェック
	 */
	errno = 0;
	ret32 = strtol((const char*)arg, &endptr, 10);
	if ((errno == 0) && (*endptr == '\0')) {
		*out = ret32;
		return 0;
	}
	return -1;
}

CmdOptionType *parse_args(int argc, const char* argv[])
{
	  int opt;


	  cmd_option.load_filepath = NULL;
	  cmd_option.is_binary_data = FALSE;
	  cmd_option.is_interaction = FALSE;
	  cmd_option.is_remote = FALSE;
	  cmd_option.timeout = 0;

	  while ((opt = getopt(argc, (char**)argv, "irbt:p:d:c:m:")) != -1) {
		  switch (opt) {
		  case 'i':
	    	cmd_option.is_interaction = TRUE;
	        break;
		  case 'r':
	    	cmd_option.is_remote = TRUE;
	        break;
	      case 'b':
		    cmd_option.is_binary_data = TRUE;
	        break;
	      case 't':
					if (cmd_atoi(optarg, &cmd_option.timeout) < 0) {
							printf("error! -t %s\n", optarg);
						return NULL;
					}
	        break;
	      case 'c':
					if (cmd_atoi32(optarg, &cmd_option.core_id_num) < 0) {
							printf("error! -c %s\n", optarg);
						return NULL;
					}
	        break;
	      case 'p':
	    	memcpy(cmd_option.buffer_fifopath, optarg, strlen(optarg));
	    	cmd_option.buffer_fifopath[strlen(optarg)] = '\0';
	        cmd_option.fifocfgpath = cmd_option.buffer_fifopath;
	        break;
	      case 'm':
	    	memcpy(cmd_option.buffer_memfile, optarg, strlen(optarg));
	    	cmd_option.buffer_memfile[strlen(optarg)] = '\0';
	        cmd_option.memfilepath = cmd_option.buffer_memfile;
	        break;
	      case 'd':
	    	memcpy(cmd_option.buffer_devcfgpath, optarg, strlen(optarg));
	    	cmd_option.buffer_devcfgpath[strlen(optarg)] = '\0';
	        cmd_option.devcfgpath = cmd_option.buffer_devcfgpath;
	        break;
	      default:
	        printf("parse_args:error! \'%c\' \'%c\'\n", opt, optopt);
	        return NULL;
	    }
	  }
#if 0
	  printf("i = %d\n", cmd_option.is_interaction);
	  printf("b = %d\n", cmd_option.is_binary_data);
	  printf("t = %llu\n", cmd_option.timeout);
	  printf("p = %s\n", (cmd_option.fifocfgpath != NULL) ? cmd_option.fifocfgpath : "NULL");
#endif
	  /*
	    In asp simulator, we do not need actual executable file 
	  */
#if 0	  
		if (optind >= argc) {
			printf("ERROR: not found <load file>\n");
			return NULL;
		}

	  memcpy(cmd_option.load_file.filepath.str, argv[optind], strlen(argv[optind]));
	  cmd_option.load_file.filepath.str[strlen(argv[optind])] = '\0';
	  cmd_option.load_file.filepath.len = strlen(argv[optind]);
	  cmd_option.load_filepath = (char *)cmd_option.load_file.filepath.str;

      if (file_load(&cmd_option.load_file) == FALSE) {
    	  return NULL;
      }
#endif

      
      if ((cmd_option.fifocfgpath != NULL) &&(file_exist(cmd_option.fifocfgpath) == FALSE)) {
    	  printf("ERROR: not found fifo(%s)\n", cmd_option.fifocfgpath);
    	  return NULL;
      }
      
      if ((cmd_option.devcfgpath != NULL) &&(file_exist(cmd_option.devcfgpath) == FALSE)) {
    	  printf("ERROR: not found devcfg(%s)\n", cmd_option.devcfgpath);
    	  return NULL;
      }
      if ((cmd_option.memfilepath != NULL) &&(file_exist(cmd_option.memfilepath) == FALSE)) {
    	  printf("ERROR: not found memory.txt(%s)\n", cmd_option.memfilepath);
    	  return NULL;
      }

	  return &cmd_option;
}
