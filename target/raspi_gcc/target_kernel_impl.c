/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2006-2016 by Embedded and Real-Time Systems Laboratory
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
 *  $Id: target_kernel_impl.c 515 2016-01-13 02:21:39Z ertl-hiro $
 */

/*
 *		カーネルのターゲット依存部（Mac OS X用）
 */

#include "kernel_impl.h"
#include "task.h"
#ifdef TOPPERS_SUPPORT_OVRHDR
#include "overrun.h"
#endif /* TOPPERS_SUPPORT_OVRHDR */

/*
 *  トレースログマクロのデフォルト定義
 */
#ifndef LOG_DSP_ENTER
#define LOG_DSP_ENTER(p_tcb)
#endif /* LOG_DSP_ENTER */

#ifndef LOG_DSP_LEAVE
#define LOG_DSP_LEAVE(p_tcb)
#endif /* LOG_DSP_LEAVE */

/*
 *  TMIN_INTPRIの範囲のチェック
 */
#if (TMIN_INTPRI > -1) || (-6 > TMIN_INTPRI)
#error TMIN_INTPRI out of range.
#endif /* (TMIN_INTPRI > -1) || (-6 > TMIN_INTPRI) */

/*
 *  割込みロック／CPUロックへの遷移でマスクするシグナルを保持する変数
 */
sigset_t	sigmask_intlock;	/* 割込みロックでマスクするシグナル */
sigset_t	sigmask_cpulock;	/* CPUロックでマスクするシグナル */

/*
 *  CPUロックフラグ実現のための変数
 */
volatile bool_t		lock_flag;		/* CPUロックフラグを表す変数 */
volatile sigset_t	saved_sigmask;	/* シグナルマスクを保存する変数 */

/*
 *  割込み優先度マスク実現のための変数
 */
volatile PRI		intpri_value;	/* 割込み優先度マスクを表す変数 */

/*
 *  割込み要求禁止フラグ実現のための変数
 */
volatile sigset_t	sigmask_disint;	/* 個別にマスクしているシグナル */

/*
 *  ディスパッチャ本体
 *
 *  LOG_DSP_LEAVEを，dispatcherに入れず，これを呼び出す関数の側に入れて
 *  いる理由は次の通り．LOG_DSP_LEAVEは，切換え後のタスクのスタックで呼
 *  び出さなければならないため，_longjmpを実行した後に呼び出す必要があ
 *  り，dispatcherを呼び出す関数の側に入れなければならない．
 */
static void
dispatcher(void)
{
	sigset_t	sigmask;

	p_runtsk = p_schedtsk;
	if (p_runtsk != NULL) {
		_longjmp(p_runtsk->tskctxb.env, 1);
		assert(0);
	}

	/*
	 *  アイドル処理
	 *
	 *  まず，CPUロック状態を解除する準備をする．sigmaskには，CPUロック
	 *  状態に遷移する前のシグナルマスクを取り出す．ループに入る前の
	 *  sigprocmaskは不要に思えるが，無いと正しく動作しない．
	 */
	lock_flag = false;
	sigassignset(&sigmask, &saved_sigmask);
	sigprocmask(SIG_SETMASK, &sigmask, NULL);
	while (true) {
		sigsuspend(&sigmask);			/* 割込み待ち */
	}
}

/*
 *  最高優先順位タスクへのディスパッチ
 */
void
dispatch(void)
{
#ifdef TOPPERS_SUPPORT_OVRHDR
	ovrtimer_stop();					/* オーバランタイマの停止 */
#endif /* TOPPERS_SUPPORT_OVRHDR */
	if (_setjmp(p_runtsk->tskctxb.env) == 0) {
		LOG_DSP_ENTER(p_runtsk);
		dispatcher();
		assert(0);
	}
	LOG_DSP_LEAVE(p_runtsk);
#ifdef TOPPERS_SUPPORT_OVRHDR
	ovrtimer_start();					/* オーバランタイマの動作開始 */
#endif /* TOPPERS_SUPPORT_OVRHDR */
}

/*
 *  最高優先順位タスクへのディスパッチ（シグナルハンドラ用）
 */
static void
dispatch_handler(int sig, siginfo_t *p_info, void *p_ctx)
{
	/*
	 *  シグナルハンドラの実行開始前のシグナルマスクをsaved_sigmaskに代
	 *  入し，CPUロック状態に遷移する．
	 */
	sigassignset(&saved_sigmask, &(((ucontext_t *) p_ctx)->uc_sigmask));
	lock_flag = true;

	if (p_runtsk != p_schedtsk) {
		if (p_runtsk != NULL) {
			if (_setjmp(p_runtsk->tskctxb.env) == 0) {
				LOG_DSP_ENTER(p_runtsk);
				dispatcher();
				assert(0);
			}
		}
		else {
			dispatcher();
			assert(0);
		}
		LOG_DSP_LEAVE(p_runtsk);
	}
#ifdef TOPPERS_SUPPORT_OVRHDR
	ovrtimer_start();					/* オーバランタイマの動作開始 */
#endif /* TOPPERS_SUPPORT_OVRHDR */

	/*
	 *  シグナルハンドラからのリターン後のシグナルマスクがsaved_sigmask
	 *  になるように設定し，CPUロック状態を解除する．
	 */
	lock_flag = false;
	sigassignset(&(((ucontext_t *) p_ctx)->uc_sigmask), &saved_sigmask);
}

/*
 *  現在のコンテキストを捨ててディスパッチ
 */
void
exit_and_dispatch(void)
{
	LOG_DSP_ENTER(p_runtsk);
	dispatcher();
	assert(0);
}

/*
 *  カーネルの終了処理の呼出し
 */
void
call_exit_kernel(void)
{
	sigset_t			sigmask;
	struct sigaction	sigact;

	/*
	 *  SIGUSR2のシグナルハンドラにexit_kernelを登録
	 */
	sigact.sa_handler = (void (*)(int)) exit_kernel;
	sigact.sa_flags = SA_ONSTACK;
	sigemptyset(&(sigact.sa_mask));
	sigaction(SIGUSR2, &sigact, NULL);

	/*
	 *  SIGUSR2のマスクを解除
	 */
	sigemptyset(&sigmask);
	sigaddset(&sigmask, SIGUSR2);
	sigprocmask(SIG_UNBLOCK, &sigmask, NULL);

	/*
	 *  exit_kernelの呼出し
	 */
	raise(SIGUSR2);
	assert(0);
	while (true);
}

/*
 *  タスク開始時処理
 */
void
start_r(void)
{
#ifdef TOPPERS_SUPPORT_OVRHDR
	ovrtimer_start();					/* オーバランタイマの動作開始 */
#endif /* TOPPERS_SUPPORT_OVRHDR */
	unlock_cpu();
	(*(p_runtsk->p_tinib->task))(p_runtsk->p_tinib->exinf);
	(void) ext_tsk();
	assert(0);
}

/*
 *  ターゲット依存の初期化
 */
void
target_initialize(void)
{
	struct sigaction	sigact;

	/*
	 *  割込みロックへの遷移でマスクするシグナルを保持する変数の初期化
	 */
	sigassignset(&sigmask_intlock, &(sigmask_table[6]));
	sigaddset(&sigmask_intlock, SIGUSR2);

	/*
	 *  CPUロックへの遷移でマスクするシグナルを保持する変数の初期化
	 */
	sigassignset(&sigmask_cpulock, &(sigmask_table[-TMIN_INTPRI]));
	sigaddset(&sigmask_cpulock, SIGUSR2);

	/*
	 *  CPUロックフラグ実現のための変数の初期化
	 *
	 *  saved_sigmaskは，カーネル起動時に呼び出すset_sigmaskで初期化さ
	 *  れる．
	 */
	lock_flag = true;

	/*
	 *  割込み優先度マスク実現のための変数の初期化
	 */
	intpri_value = TIPM_ENAALL;

	/*
	 *  割込み要求禁止フラグ実現のための変数の初期化
	 */
	sigassignset(&sigmask_disint, &sigmask_disint_init);

	/*
	 *  SIGUSR2のシグナルハンドラにディスパッチャを登録
	 */
	sigact.sa_sigaction = dispatch_handler;
	sigact.sa_flags = SA_SIGINFO;
	sigassignset(&(sigact.sa_mask), &sigmask_cpulock);
	sigaction(SIGUSR2, &sigact, NULL);
}

/*
 *  ターゲット依存の終了処理
 */
void
target_exit(void)
{
	/*
	 *  プロセスの終了処理
	 */
	exit(0);
}

/*
 *  割込み管理機能の初期化
 */
void
initialize_interrupt(void)
{
	uint_t			i;
	const INHINIB	*p_inhinib;

	for (i = 0; i < tnum_def_inhno; i++) {
		p_inhinib = &(inhinib_table[i]);
		define_inh(p_inhinib->inhno, p_inhinib->int_entry, p_inhinib->intpri);
	}
}

/*
 *  メイン関数
 */
int
main()
{
	sigset_t			sigmask;
	stack_t				ss;
	struct sigaction	sigact;

	/*
	 *  SIGUSR2以外のすべてのシグナルをマスク
	 */
	sigfillset(&sigmask);
	sigdelset(&sigmask, SIGUSR2);
	sigprocmask(SIG_BLOCK, &sigmask, NULL);

	/*
	 *  シグナルスタック（非タスクコンテキスト用のスタック）の設定
	 */
	ss.ss_sp = (char *)(istk);
	ss.ss_size = (int)(istksz);
	ss.ss_flags = 0;
	sigaltstack(&ss, NULL);

	/*
	 *  SIGUSR2のシグナルハンドラにsta_kerを登録
	 */
	sigact.sa_handler = (void (*)(int)) sta_ker;
	sigact.sa_flags = SA_ONSTACK;
	sigemptyset(&(sigact.sa_mask));
	sigaction(SIGUSR2, &sigact, NULL);

	/*
	 *  sta_kerの呼出し
	 */
	raise(SIGUSR2);

	/*
	 *  ディスパッチャの動作開始
	 *
	 *  target_initializeで，lock_flagをtrueに，intpri_valueを
	 *  TIPM_ENAALLに初期化しているため，set_sigmaskを呼び出してシグナ
	 *  ルマスクとsaved_sigmaskを設定することで，CPUロック状態・（モデ
	 *  ル上の）割込み優先度マスクがTIPM_ENAALLの状態になる．
	 *
	 *  また，initialize_taskでenadspをtrueに初期化しているため，ディ
	 *  スパッチ許可状態になっている．
	 */
	set_sigmask();
	dispatcher();
	assert(0);
	return(0);
}

/*
 *  カーネルの割り付けるメモリ領域の管理
 *
 *  TLSF（オープンソースのメモリ管理ライブラリ）を用いて実現．
 */
#ifdef TOPPERS_SUPPORT_DYNAMIC_CRE

#include "tlsf.h"

static bool_t	tlsf_initialized = false;

void
initialize_kmm(void)
{
	if (init_memory_pool(kmmsz, kmm) != -1) {
		tlsf_initialized = true;
	}
}

void *
kernel_malloc(size_t size)
{
	if (tlsf_initialized) {
		return(malloc_ex(size, kmm));
	}
	else {
		return(NULL);
	}
}

void
kernel_free(void *ptr)
{
	if (tlsf_initialized) {
		free_ex(ptr, kmm);
	}
}

#endif /* TOPPERS_SUPPORT_DYNAMIC_CRE */
