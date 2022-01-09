#include "ev3_svc.h"


const SVCINIB _kernel_svcinib_table[SVC_TABLE_NUM] = {
	{ NULL, 0 },	// 0
	{ NULL, 0 },	// 1
	{ NULL, 0 },	// 2
	{ NULL, 0 },	// 3
	{ NULL, 0 },	// 4
	{ NULL, 0 },	// 5
	{ NULL, 0 },	// 6
	{ NULL, 0 },	// 7
	{ NULL, 0 },	// 8
	{ NULL, 0 },	// 9
	{ NULL, 0 },	// 10
	{ NULL, 0 },	// 11
	{ NULL, 0 },	// 12
	{ NULL, 0 },	// 13
	{ NULL, 0 },	// 14
	{ NULL, 0 },	// 15
	{ NULL, 0 },	// 16
	{ NULL, 0 },	// 17
	{ NULL, 0 },	// 18
	{ NULL, 0 },	// 19
	{ NULL, 0 },	// 20
	{ NULL, 0 },	// 21
	{ NULL, 0 },	// 22
	{ (EXTSVC)(extsvc_motor_command), 1024 },	// 23
	{ (EXTSVC)(extsvc_fetch_brick_info), 1024 },	//24
	{ (EXTSVC)(extsvc_button_set_on_clicked), 1024 },	//25
	{ (EXTSVC)(extsvc_brick_misc_command), 1024 },	//26
	{ NULL, 0 },	//27
	{ NULL, 0 },	//28
	{ NULL, 0 },	//29
	// 30-32 are for sound api
	{ DUMMY_RETURN_OK_FUNC, 1024 },	//30
	{ DUMMY_RETURN_OK_FUNC, 1024 },	//31
	{ DUMMY_RETURN_OK_FUNC, 1024 },	//32
	{ NULL, 0 },	//33
	{ NULL, 0 },	//34
	{ NULL, 0 },	//35
	{ NULL, 0 },	//36
	{ NULL, 0 },	//37
	{ NULL, 0 },	//38
	{ NULL, 0 },	//39
	{ NULL, 0 },	//40
	{ NULL, 0 },	//41
	{ NULL, 0 },	//42
};


ER_UINT extsvc_dummy_ok_func(intptr_t port, intptr_t mode, intptr_t par3, intptr_t par4, intptr_t par5, ID cdmid)
{
	return E_OK;
}