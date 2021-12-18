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
 *  $Id: wait.c 470 2015-12-30 09:50:36Z ertl-hiro $
 */

/*
 *		待ち状態管理モジュール
 */

#include "kernel_impl.h"
#include "taskhook.h"
#include "wait.h"

/*
 *  待ち状態への遷移（タイムアウト指定）
 */
#ifdef TOPPERS_waimake

void
make_wait_tmout(WINFO *p_winfo, TMEVTB *p_tmevtb, TMO tmout)
{
	make_non_runnable(p_runtsk);
	p_runtsk->p_winfo = p_winfo;
	if (tmout == TMO_FEVR) {
		p_winfo->p_tmevtb = NULL;
	}
	else {
		assert(tmout <= TMAX_RELTIM);
		p_winfo->p_tmevtb = p_tmevtb;
		p_tmevtb->callback = (CBACK) wait_tmout;
		p_tmevtb->arg = (void *) p_runtsk;
		tmevtb_enqueue(p_tmevtb, (RELTIM) tmout);
	}
}

#endif /* TOPPERS_waimake */

/*
 *  オブジェクト待ちキューからの削除
 */
#ifdef TOPPERS_waiwobj

void
wait_dequeue_wobj(TCB *p_tcb)
{
	if (TSTAT_WAIT_WOBJ(p_tcb->tstat)) {
		queue_delete(&(p_tcb->task_queue));
		if (TSTAT_WAIT_SMBF(p_tcb->tstat)) {
			(*mbfhook_dequeue_wobj)(p_tcb);
		}
	}
}

#endif /* TOPPERS_waiwobj */

/*
 *  待ち解除
 */
#ifdef TOPPERS_waicmp

void
wait_complete(TCB *p_tcb)
{
	wait_dequeue_tmevtb(p_tcb);
	p_tcb->p_winfo->wercd = E_OK;
	make_non_wait(p_tcb);
}

#endif /* TOPPERS_waicmp */

/*
 *  タイムアウトに伴う待ち解除
 */
#ifdef TOPPERS_waitmo

void
wait_tmout(TCB *p_tcb)
{
	wait_dequeue_wobj(p_tcb);
	p_tcb->p_winfo->wercd = E_TMOUT;
	make_non_wait(p_tcb);
	if (p_runtsk != p_schedtsk) {
		request_dispatch();
	}

	/*
	 *  ここで優先度の高い割込みを受け付ける．
	 */
	unlock_cpu();
	delay_for_interrupt();
	lock_cpu();
}

#endif /* TOPPERS_waitmo */
#ifdef TOPPERS_waitmook

void
wait_tmout_ok(TCB *p_tcb)
{
	p_tcb->p_winfo->wercd = E_OK;
	make_non_wait(p_tcb);
	if (p_runtsk != p_schedtsk) {
		request_dispatch();
	}

	/*
	 *  ここで優先度の高い割込みを受け付ける．
	 */
	unlock_cpu();
	delay_for_interrupt();
	lock_cpu();
}

#endif /* TOPPERS_waitmook */

/*
 *  実行中のタスクの同期・通信オブジェクトの待ちキューへの挿入
 *
 *  実行中のタスクを，同期・通信オブジェクトの待ちキューへ挿入する．オ
 *  ブジェクトの属性に応じて，FIFO順またはタスク優先度順で挿入する．
 */
Inline void
wobj_queue_insert(WOBJCB *p_wobjcb)
{
	if ((p_wobjcb->p_wobjinib->wobjatr & TA_TPRI) != 0U) {
		queue_insert_tpri(&(p_wobjcb->wait_queue), p_runtsk);
	}
	else {
		queue_insert_prev(&(p_wobjcb->wait_queue), &(p_runtsk->task_queue));
	}
}

/*
 *  同期・通信オブジェクトに対する待ち状態への遷移
 */
#ifdef TOPPERS_wobjwai

void
wobj_make_wait(WOBJCB *p_wobjcb, WINFO_WOBJ *p_winfo_wobj)
{
	make_wait(&(p_winfo_wobj->winfo));
	wobj_queue_insert(p_wobjcb);
	p_winfo_wobj->p_wobjcb = p_wobjcb;
	LOG_TSKSTAT(p_runtsk);
}

#endif /* TOPPERS_wobjwai */
#ifdef TOPPERS_wobjwaitmo

void
wobj_make_wait_tmout(WOBJCB *p_wobjcb, WINFO_WOBJ *p_winfo_wobj,
								TMEVTB *p_tmevtb, TMO tmout)
{
	make_wait_tmout(&(p_winfo_wobj->winfo), p_tmevtb, tmout);
	wobj_queue_insert(p_wobjcb);
	p_winfo_wobj->p_wobjcb = p_wobjcb;
	LOG_TSKSTAT(p_runtsk);
}

#endif /* TOPPERS_wobjwaitmo */

/*
 *  待ちキューの初期化
 */
#ifdef TOPPERS_iniwque

void
init_wait_queue(QUEUE *p_wait_queue)
{
	TCB		*p_tcb;

	while (!queue_empty(p_wait_queue)) {
		p_tcb = (TCB *) queue_delete_next(p_wait_queue);
		wait_dequeue_tmevtb(p_tcb);
		p_tcb->p_winfo->wercd = E_DLT;
		make_non_wait(p_tcb);
	}
}

#endif /* TOPPERS_iniwque */
