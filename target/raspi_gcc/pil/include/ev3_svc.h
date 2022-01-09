#ifndef _EV3_SVC_H_
#define _EV3_SVC_H_

#include <kernel.h>
#include <itron.h>

typedef ER_UINT	(*EXTSVC)(intptr_t par1, intptr_t par2, intptr_t par3,
								intptr_t par4, intptr_t par5, ID cdmid);

typedef struct extended_service_call_initialization_block {
	EXTSVC		svcrtn;		/* 拡張サービスコールの先頭番地 */
	SIZE		stksz;		/* 拡張サービスコールで使用するスタックサイズ */
} SVCINIB;
#define SVC_TABLE_NUM	43
extern const SVCINIB _kernel_svcinib_table[SVC_TABLE_NUM];

extern ER_UINT extsvc_fetch_brick_info(intptr_t p_brickinfo, intptr_t par2, intptr_t par3, intptr_t par4, intptr_t par5, ID cdmid);
extern ER_UINT extsvc_button_set_on_clicked(intptr_t button, intptr_t handler, intptr_t exinf, intptr_t par4, intptr_t par5, ID cdmid);
extern ER_UINT extsvc_brick_misc_command(intptr_t misccmd, intptr_t exinf, intptr_t par3, intptr_t par4, intptr_t par5, ID cdmid);
extern ER_UINT extsvc_motor_command(intptr_t port, intptr_t mode, intptr_t par3, intptr_t par4, intptr_t par5, ID cdmid);

// For returning OK
extern ER_UINT extsvc_dummy_ok_func(intptr_t port, intptr_t mode, intptr_t par3, intptr_t par4, intptr_t par5, ID cdmid);
#define DUMMY_RETURN_OK_FUNC (EXTSVC)extsvc_dummy_ok_func

#endif /* _EV3_SVC_H_ */
