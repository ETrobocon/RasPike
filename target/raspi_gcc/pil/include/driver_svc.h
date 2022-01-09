#ifndef _DRIVER_SVC_H_
#define _DRIVER_SVC_H_

#include "ev3_svc.h"

/*
 *  cal_svcサービスコールのインタフェース
 */
Inline ER_UINT
cal_svc(FN fncd, intptr_t par1, intptr_t par2,
							intptr_t par3, intptr_t par4, intptr_t par5)
{
	//TODO
	if (fncd >= SVC_TABLE_NUM) {
		return E_PAR;
	}
	const SVCINIB *fp = &_kernel_svcinib_table[fncd];
	if (fp == NULL) {
		return E_OBJ;
	}
	if (fp->svcrtn == NULL) {
		return E_OBJ;
	}
	return fp->svcrtn(par1, par2, par3, par4, par5, fncd);
}


#endif
