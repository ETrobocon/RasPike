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
 *  $Id: target_timer.c 458 2015-08-21 14:59:09Z ertl-hiro $
 */

/*
 *		タイマドライバ（Mac OS X用）
 *
 *  Mac OS X上で使用できるマイクロ秒精度のタイマが1つしかないため，1つ
 *  のインターバルタイマでシステム時刻を進めるための高分解能タイマを実
 *  現している．この方法は，時間のずれが生じるために推奨できないが，シ
 *  ミュレーション環境で時間のずれは大きい問題ではないため，この方法を
 *  採用している．
 *
 *  さらに，オーバランハンドラ機能のためのタイマ（オーバランタイマ）も，
 *  同じインターバルタイマを多重化して実現している．
 */

#include "kernel_impl.h"
#include "time_event.h"
#ifdef TOPPERS_SUPPORT_OVRHDR
#include "overrun.h"
#endif /* TOPPERS_SUPPORT_OVRHDR */
#include "target_timer.h"
#include <sys/time.h>

/*
 *  高分解能タイマの状態
 */
static HRTCNT	hrtcnt_current;		/* 高分解能タイマの現時点の値 */
static HRTCNT	hrtcnt_left;		/* 高分解能タイマ割込みの残りカウント */
static bool_t	hrtcnt_pending;		/* 高分解能タイマ割込みが要求中 */

/*
 *  オーバランタイマの状態
 */
#ifdef TOPPERS_SUPPORT_OVRHDR
static PRCTIM	ovrtimer_left;		/* オーバランタイマ割込みの残り時間 */
static bool_t	ovrtimer_pending;	/* オーバランタイマ割込みが要求中 */
#endif /* TOPPERS_SUPPORT_OVRHDR */

/*
 *  インターバルタイマの設定状態
 */
static ulong_t	itimer_value;		/* 最後にインターバルタイマに設定した値 */

/*
 *  インターバルタイマを停止させるための変数
 */
static const struct itimerval	itimerval_stop = {{ 0, 0 }, { 0, 0 }};

/*
 *  インターバルタイマの経過時間の算出
 */
Inline ulong_t
itimer_progress(struct itimerval *p_val)
{
	return(itimer_value - ((ulong_t)(p_val->it_value.tv_sec) * 1000000U
									+ (ulong_t)(p_val->it_value.tv_usec)));
}

/*
 *  インターバルタイマの一時停止処理
 */
static void
pause_itimer(void)
{
	ulong_t				progtim;
	struct itimerval	val;

	/*
	 *  インターバルタイマを停止し，経過した時間を求める．
	 */
	setitimer(ITIMER_REAL, &itimerval_stop, &val);
	progtim = itimer_progress(&val);

	/*
	 *  高分解能タイマの状態を更新する．
	 */
	hrtcnt_current += progtim;
	if (hrtcnt_left > 0U) {
		if (hrtcnt_left > progtim) {
			hrtcnt_left -= progtim;
		}
		else {
			hrtcnt_left = 0U;
			hrtcnt_pending = true;
			/*
			 *  ここでSIGALRMを要求しないと，タイマ割込み要求が抜けてし
			 *  まう場合がある（サンプルプログラムで，'o'を連打すると再
			 *  現する）．スプリアス割込みがかかるため，避けたいところ
			 *  だが，抜ける原因が不明であるため，修正できていない．
			 */
			raise(SIGALRM);
		}
	}

	/*
	 *  オーバランタイマの状態を更新する．
	 */
#ifdef TOPPERS_SUPPORT_OVRHDR
	if (ovrtimer_left > 0U) {
		if (ovrtimer_left > progtim) {
			ovrtimer_left -= progtim;
		}
		else {
			ovrtimer_left = 0U;
			ovrtimer_pending = true;
		}
	}
#endif /* TOPPERS_SUPPORT_OVRHDR */
}

/*
 *  インターバルタイマの動作開始処理
 */
static void
start_itimer(void)
{
	struct itimerval	val;

	/*
	 *  インターバルタイマに設定する時間を求める．
	 */
	itimer_value = (hrtcnt_left > 0U) ? hrtcnt_left : ULONG_MAX;
#ifdef TOPPERS_SUPPORT_OVRHDR
	if (ovrtimer_left > 0U && ovrtimer_left < itimer_value) {
		itimer_value = ovrtimer_left;
	}
#endif /* TOPPERS_SUPPORT_OVRHDR */

	/*
	 *  インターバルタイマの動作を開始する．
	 */
	val.it_interval.tv_sec = 0;
	val.it_interval.tv_usec = 0;
	val.it_value.tv_sec = itimer_value / 1000000U;
	val.it_value.tv_usec = itimer_value % 1000000U;
	setitimer(ITIMER_REAL, &val, NULL);
}

/*
 *  タイマの初期化処理
 */
void
target_timer_initialize(intptr_t exinf)
{
	hrtcnt_current = 0U;
	hrtcnt_left = 0U;
	hrtcnt_pending = false;
#ifdef TOPPERS_SUPPORT_OVRHDR
	ovrtimer_left = 0U;
	ovrtimer_pending = false;
#endif /* TOPPERS_SUPPORT_OVRHDR */
	start_itimer();
}

/*
 *  タイマの終了処理
 */
void
target_timer_terminate(intptr_t exinf)
{
	/*
	 *  インターバルタイマの動作を停止する．
	 */
	setitimer(ITIMER_REAL, &itimerval_stop, NULL);
}

/*
 *  高分解能タイマの現在のカウント値の読出し
 */
HRTCNT
target_hrt_get_current(void)
{
	struct itimerval	val;

	getitimer(ITIMER_REAL, &val);
	return(hrtcnt_current + itimer_progress(&val));
}

/*
 *  高分解能タイマへの割込みタイミングの設定
 */
void
target_hrt_set_event(HRTCNT hrtcnt)
{
	pause_itimer();
	hrtcnt_left = hrtcnt;
	start_itimer();
}

/*
 *  高分解能タイマ割込みの要求
 */
void
target_hrt_raise_event(void)
{
	hrtcnt_pending = true;
	raise(SIGALRM);
}

#ifdef TOPPERS_SUPPORT_OVRHDR

/*
 *  オーバランタイマの動作開始
 */
void
target_ovrtimer_start(PRCTIM ovrtim)
{
	assert(ovrtimer_left == 0U);
	if (ovrtim > 0U) {
		pause_itimer();
		ovrtimer_left = ovrtim;
		start_itimer();
	}
	else {
		ovrtimer_pending = true;
		raise(SIGALRM);
	}
}

/*
 *  オーバランタイマの停止
 */
PRCTIM
target_ovrtimer_stop(void)
{
	PRCTIM	lefttim;

	assert(ovrtimer_left > 0U);
	pause_itimer();
	lefttim = ovrtimer_left;
	ovrtimer_left = 0U;
	start_itimer();
	return(lefttim);
}

/*
 *  オーバランタイマの現在値の読出し
 */
PRCTIM
target_ovrtimer_get_current(void)
{
	struct itimerval	val;

	assert(ovrtimer_left > 0U);
	getitimer(ITIMER_REAL, &val);
	return(ovrtimer_left - itimer_progress(&val));
}

#endif /* TOPPERS_SUPPORT_OVRHDR */

/*
 *  タイマ割込みハンドラ
 */
void
target_timer_handler(void)
{
	lock_cpu();
	pause_itimer();

#ifdef TOPPERS_SUPPORT_OVRHDR
	/*
	 *  オーバランタイマにより割込みが発生した場合
	 */
	if (ovrtimer_pending) {
		ovrtimer_pending = false;
		start_itimer();
		unlock_cpu();

		call_ovrhdr();				/* オーバランハンドラの起動処理 */

		if (!sense_lock()) {
			lock_cpu();
		}
		pause_itimer();
	}
#endif /* TOPPERS_SUPPORT_OVRHDR */

	/*
	 *  高分解能タイマにより割込みが発生した場合
	 */
	if (hrtcnt_pending) {
		hrtcnt_pending = false;
		start_itimer();
		unlock_cpu();

		signal_time();			/* 高分解能タイマ割込みの処理 */
	}
	else {
		start_itimer();
		unlock_cpu();
	}
}
