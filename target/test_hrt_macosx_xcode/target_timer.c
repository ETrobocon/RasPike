/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2005-2015 by Embedded and Real-Time Systems Laboratory
 *              Graduate School of Information Science, Nagoya Univ., JAPAN
 * 
 *  上記著作権者は，以下の(1)〜(4)の条件を満たす場合に限り，本ソフトウェ
 *  ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
 *  変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
 *  (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
 *      権表示，この利用条件および下記の無保証規定が，そのままの形でソー
 *      スコード中に含まれていること．
 *  (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
 *      用できる形で再配布する場合には，再配布に伴うドキュメント（利用
 *      者マニュアルなど）に，上記の著作権表示，この利用条件および下記
 *      の無保証規定を掲載すること．
 *  (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
 *      用できない形で再配布する場合には，次のいずれかの条件を満たすこ
 *      と．
 *    (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
 *        作権表示，この利用条件および下記の無保証規定を掲載すること．
 *    (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
 *        報告すること．
 *  (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
 *      害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
 *      また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
 *      由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
 *      免責すること．
 * 
 *  本ソフトウェアは，無保証で提供されているものである．上記著作権者お
 *  よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
 *  に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
 *  アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
 *  の責任を負わない．
 * 
 *  $Id: target_timer.c 381 2015-07-31 02:19:30Z ertl-hiro $
 */

/*
 *		タイマドライバ（Mac OS X上でのシステム時刻管理機能テスト用）
 */

#include "kernel_impl.h"
#include "time_event.h"
#include "target_timer.h"
#include <sys/time.h>

/*
 *  タイマ割込みを発生させるまでの時間
 */
#define HRT_INTERVAL	1000U

/*
 *  タイマの初期化処理
 */
void
target_timer_initialize(intptr_t exinf)
{
}

/*
 *  タイマの終了処理
 */
void
target_timer_terminate(intptr_t exinf)
{
}

/*
 *  高分解能タイマ割込みの要求
 */
void
target_raise_hrt_int(uint_t timing)
{
	struct itimerval	val, oval;

	if (timing == 0) {
		/*
		 *  即座にタイマ割込みを発生させる．
		 */
		raise(SIGALRM);
	}
	else {
		/*
		 *  一定時間後に，タイマ割込みを発生させる．
		 */
		val.it_interval.tv_sec = 0;
		val.it_interval.tv_usec = 0;
		val.it_value.tv_sec = HRT_INTERVAL * timing / 1000000U;
		val.it_value.tv_usec = HRT_INTERVAL * timing % 1000000U;
		setitimer(ITIMER_REAL, &val, &oval);
	}
}

/*
 *  タイマ割込みハンドラ
 */
void
target_timer_handler(void)
{
	signal_time();					/* 高分解能タイマ割込みの処理 */
}
