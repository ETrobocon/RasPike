/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2000-2003 by Embedded and Real-Time Systems Laboratory
 *                              Toyohashi Univ. of Technology, JAPAN
 *  Copyright (C) 2005-2014 by Embedded and Real-Time Systems Laboratory
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
 *  $Id: eventflag.h 200 2014-09-05 19:18:00Z ertl-hiro $
 */

/*
 *		イベントフラグ機能
 */

#ifndef TOPPERS_EVENTFLAG_H
#define TOPPERS_EVENTFLAG_H

#include "kernel_impl.h"
#include <queue.h>
#include "wait.h"

/*
 *  イベントフラグ初期化ブロック
 *
 *  この構造体は，同期・通信オブジェクトの初期化ブロックの共通部分
 *  （WOBJINIB）を拡張（オブジェクト指向言語の継承に相当）したもので，
 *  最初のフィールドが共通になっている．
 */
typedef struct eventflag_initialization_block {
	ATR			flgatr;			/* イベントフラグ属性 */
	FLGPTN		iflgptn;		/* イベントフラグのビットパターンの初期値 */
} FLGINIB;

/*
 *  イベントフラグ管理ブロック
 *
 *  この構造体は，同期・通信オブジェクトの管理ブロックの共通部分（WOBJCB）
 *  を拡張（オブジェクト指向言語の継承に相当）したもので，最初の2つの
 *  フィールドが共通になっている．
 */
typedef struct eventflag_control_block {
	QUEUE		wait_queue;		/* イベントフラグ待ちキュー */
	const FLGINIB *p_flginib;	/* 初期化ブロックへのポインタ */
	FLGPTN		flgptn;			/* イベントフラグ現在パターン */
} FLGCB;

/*
 *  イベントフラグ待ち情報ブロックの定義
 *
 *  この構造体は，同期・通信オブジェクトの待ち情報ブロックの共通部分
 *  （WINFO_WOBJ）を拡張（オブジェクト指向言語の継承に相当）したもので，
 *  最初の2つのフィールドが共通になっている．
 *
 *  waiptnには，待ち状態の間は待ちパターンを，待ち解除された後は待ち解
 *  除時のパターンを入れる（1つのフィールドを2つの目的に兼用している）．
 */
typedef struct eventflag_waiting_information {
	WINFO		winfo;			/* 標準の待ち情報ブロック */
	FLGCB		*p_flgcb;		/* 待っているイベントフラグの管理ブロック */
	FLGPTN		waiptn;			/* 待ちパターン／待ち解除時のパターン */
	MODE		wfmode;			/* 待ちモード */
} WINFO_FLG;

/*
 *  使用していないイベントフラグ管理ブロックのリスト
 */
extern QUEUE	free_flgcb;

/*
 *  イベントフラグIDの最大値（kernel_cfg.c）
 */
extern const ID	tmax_flgid;
extern const ID	tmax_sflgid;

/*
 *  イベントフラグ初期化ブロックのエリア（kernel_cfg.c）
 */
extern const FLGINIB	flginib_table[];
extern FLGINIB			aflginib_table[];

/*
 *  イベントフラグ管理ブロックのエリア（kernel_cfg.c）
 */
extern FLGCB	flgcb_table[];

/*
 *  イベントフラグ管理ブロックからイベントフラグIDを取り出すためのマクロ
 */
#define	FLGID(p_flgcb)	((ID)(((p_flgcb) - flgcb_table) + TMIN_FLGID))

/*
 *  イベントフラグ機能の初期化
 */
extern void	initialize_eventflag(void);

/*
 *  イベントフラグ待ち解除条件のチェック
 */
extern bool_t	check_flg_cond(FLGCB *p_flgcb, FLGPTN waiptn,
								MODE wfmode, FLGPTN *p_flgptn);

#endif /* TOPPERS_EVENTFLAG_H */
