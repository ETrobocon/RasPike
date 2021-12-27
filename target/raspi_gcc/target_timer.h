/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2000-2003 by Embedded and Real-Time Systems Laboratory
 *                              Toyohashi Univ. of Technology, JAPAN
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
 *  $Id: target_timer.h 458 2015-08-21 14:59:09Z ertl-hiro $
 */

/*
 *		タイマドライバ（Mac OS X用）
 */

#ifndef TOPPERS_TARGET_TIMER_H
#define TOPPERS_TARGET_TIMER_H

#include <sil.h>
#include "macosx.h"
#ifndef TOPPERS_MACRO_ONLY
#include <sys/time.h>
#endif /* TOPPERS_MACRO_ONLY */

/*
 *  タイマ割込みハンドラ登録のための定数
 */
#define INHNO_TIMER		SIGALRM				/* 割込みハンドラ番号 */
#define INTNO_TIMER		SIGALRM				/* 割込み番号 */
#define INTPRI_TIMER	(TMAX_INTPRI - 1)	/* 割込み優先度 */
#define INTATR_TIMER	TA_EDGE				/* 割込み属性 */

#ifndef TOPPERS_MACRO_ONLY

/*
 *  タイマの初期化処理
 */
extern void	target_timer_initialize(intptr_t exinf);

/*
 *  タイマの終了処理
 */
extern void	target_timer_terminate(intptr_t exinf);

/*
 *  高分解能タイマの現在のカウント値の読出し
 */
extern HRTCNT target_hrt_get_current(void);

/*
 *  高分解能タイマへの割込みタイミングの設定
 *
 *  高分解能タイマを，hrtcntで指定した値カウントアップしたら割込みを発
 *  生させるように設定する．
 */
extern void target_hrt_set_event(HRTCNT hrtcnt);

/*
 *  高分解能タイマ割込みの要求
 */
extern void target_hrt_raise_event(void);

/*
 *  割込みタイミングに指定する最大値
 */
#define HRTCNT_BOUND	4000000002U

/*
 *  オーバランタイマドライバ
 */
#ifdef TOPPERS_SUPPORT_OVRHDR

/*
 *  オーバランタイマの動作開始
 */
extern void target_ovrtimer_start(PRCTIM ovrtim);

/*
 *  オーバランタイマの停止
 */
extern PRCTIM target_ovrtimer_stop(void);

/*
 *  オーバランタイマの現在値の読出し
 */
extern PRCTIM target_ovrtimer_get_current(void);

#endif /* TOPPERS_SUPPORT_OVRHDR */

/*
 *  タイマ割込みハンドラ
 */
extern void	target_timer_handler(void);

#endif /* TOPPERS_MACRO_ONLY */
#endif /* TOPPERS_TARGET_TIMER_H */
