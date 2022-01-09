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

    FILE *fp = fopen("fstest.txt","w");
    CHECK( fopen , fp );

    const char p[] = "abcdefg";
    fwrite(p,sizeof(p),1,fp);
    fclose(fp);

    fp = fopen("fstest.txt","r");

    char buf[100];
    fread(buf,sizeof(buf),1,fp);
     syslog(LOG_NOTICE,buf);
    CHECK(read_write, !strcmp(p,buf));
    
    fclose(fp);

    memfile_t mf;

    ER err = ev3_memfile_load("fstest.txt",&mf);

    CHECK( memfile_load, ((err==E_OK)&&!memcmp(p,mf.buffer,mf.filesz)));

    err = ev3_memfile_free(&mf);
    CHECK( memfile_free, (err==E_OK));

    ER_ID id = ev3_sdcard_opendir("test");
    CHECK(sdcard_opendir,id>0);

    fileinfo_t file;
    while ( ev3_sdcard_readdir(id,&file) == E_OK ) {
	 syslog(LOG_NOTICE,"readdir name=%s is_dir=%d\n",file.name,file.is_dir);
	tslp_tsk(1000000);
    }

    CHECK(sdcard_close, ev3_sdcard_closedir(id)==0);


    while(1) {;}


}
// end::main_task[]
