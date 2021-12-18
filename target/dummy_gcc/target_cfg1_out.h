/*
 *		cfg1_out.cのリンクに必要なスタブの定義
 *
 *  $Id: target_cfg1_out.h 286 2014-11-29 07:51:11Z ertl-hiro $
 */

#include <t_stddef.h>

int main()
{
	return(0);
}

/*
 *  offset.hを生成するための定義
 */
const uint8_t	MAGIC_1 = 0x12;
const uint16_t	MAGIC_2 = 0x1234;
const uint32_t	MAGIC_4 = 0x12345678;
