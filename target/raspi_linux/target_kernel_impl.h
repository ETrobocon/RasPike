/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2006-2017 by Embedded and Real-Time Systems Laboratory
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
 *  $Id: target_kernel_impl.h 789 2017-04-01 07:28:08Z ertl-hiro $
 */

/*
 *		カーネルのターゲット依存部（Mac OS X用）
 *
 *  カーネルのターゲット依存部のヘッダファイル．kernel_impl.hのターゲッ
 *  ト依存部の位置付けとなる．
 */

#ifndef TOPPERS_TARGET_KERNEL_IMPL_H
#define TOPPERS_TARGET_KERNEL_IMPL_H

/*
 *  標準のインクルードファイル
 */
#ifndef TOPPERS_MACRO_ONLY
#include <sys/types.h>
#include <stdlib.h>
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>

#include <kernel.h>
#include <t_syslog.h>
#endif /* TOPPERS_MACRO_ONLY */

/*
 *  ターゲットシステムのOS依存の定義
 */
#include "macosx.h"

/*
 *  ターゲット定義のオブジェクト属性
 */
#define TARGET_INHATR	TA_NONKERNEL	/* カーネル管理外の割込み */

/*
 *  エラーチェック方法の指定
 */
#define CHECK_STKSZ_ALIGN	16	/* スタックサイズのアライン単位 */
#define CHECK_INTPTR_ALIGN	4	/* intptr_t型の変数のアライン単位 */
#define CHECK_INTPTR_NONNULL	/* intptr_t型の変数の非NULLチェック */
#define CHECK_FUNC_ALIGN	4	/* 関数のアライン単位 */
#define CHECK_FUNC_NONNULL		/* 関数の非NULLチェック */
#define CHECK_STACK_ALIGN	16	/* スタック領域のアライン単位 */
#define CHECK_STACK_NONNULL		/* スタック領域の非NULLチェック */
#define CHECK_MPF_ALIGN		4	/* 固定長メモリプール領域のアライン単位 */
#define CHECK_MPF_NONNULL		/* 固定長メモリプール領域の非NULLチェック */
#define CHECK_MB_ALIGN		4	/* 管理領域のアライン単位 */

/*
 *  トレースログに関する設定
 */
#ifdef TOPPERS_ENABLE_TRACE
#include "arch/tracelog/trace_log.h"
#endif /* TOPPERS_ENABLE_TRACE */

/*
 *  トレースログマクロのデフォルト定義
 */
#ifndef LOG_INH_ENTER
#define LOG_INH_ENTER(inhno)
#endif /* LOG_INH_ENTER */

#ifndef LOG_INH_LEAVE
#define LOG_INH_LEAVE(inhno)
#endif /* LOG_INH_LEAVE */

#ifndef LOG_EXC_ENTER
#define LOG_EXC_ENTER(excno)
#endif /* LOG_EXC_ENTER */

#ifndef LOG_EXC_LEAVE
#define LOG_EXC_LEAVE(excno)
#endif /* LOG_EXC_LEAVE */

/*
 *  アーキテクチャ（プロセッサ）依存の定義
 */
#if defined(__ppc__)

#define JMPBUF_PC				21			/* jmp_buf中でのPCの位置 */
#define JMPBUF_SP				0			/* jmp_buf中でのSPの位置 */
#define TASK_STACK_MERGIN		4U
#define DEFAULT_ISTKSZ			SIGSTKSZ	/* シグナルスタックのサイズ */

#elif defined(__i386__)

#define JMPBUF_PC				12			/* jmp_buf中でのPCの位置 */
#define JMPBUF_SP				9			/* jmp_buf中でのSPの位置 */
#define TASK_STACK_MERGIN		4U 
#define DEFAULT_ISTKSZ			SIGSTKSZ	/* シグナルスタックのサイズ */

#elif defined(__x86_64__)

#error architecture not supported
#define JMPBUF_PC				7			/* jmp_buf中でのPCの位置 */
#define JMPBUF_SP				2			/* jmp_buf中でのSPの位置 */
#define TASK_STACK_MERGIN		8U 
#define DEFAULT_ISTKSZ			SIGSTKSZ	/* シグナルスタックのサイズ */

#else
#error architecture not supported
#endif

/* 
 *  標準の割込み管理機能の初期化を行わないための定義
 */
#define OMIT_INITIALIZE_INTERRUPT

#ifndef TOPPERS_MACRO_ONLY

/*
 *  タスクコンテキストブロックの定義
 */
typedef struct task_context_block {
	jmp_buf		env;			/* コンテキスト情報 */
} TSKCTXB;

/*
 *  割込みハンドラ初期化ブロック
 *
 *  標準の割込みハンドラ初期化ブロックに，割込み優先度を追加したもの．
 */
typedef struct interrupt_handler_initialization_block {
	INHNO		inhno;			/* 割込みハンドラ番号 */
	ATR			inhatr;			/* 割込みハンドラ属性 */
	FP			int_entry;		/* 割込みハンドラの出入口処理の番地 */
	PRI			intpri;			/* 割込み優先度 */
} INHINIB;

/*
 *  割込みハンドラ番号の数（kernel_cfg.c）
 */
extern const uint_t	tnum_def_inhno;

/*
 *  割込みハンドラ初期化ブロックのエリア（kernel_cfg.c）
 */
extern const INHINIB	inhinib_table[];

/*
 *  シグナルセット操作マクロ
 */
#define sigequalset(set1, set2)		(*(set1) == *(set2))
#define sigassignset(set1, set2)	(*(set1) = *(set2))
#define sigjoinset(set1, set2)		(*(set1) |= *(set2))

/*
 *  割込み優先度マスクによるシグナルマスク（kernel_cfg.c）
 *
 *  割込み優先度マスクによってマスクされている割込みと，割込み属性が設
 *  定されていない割込みに対応するシグナルをマスクするためのシグナルマ
 *  スクを保持する配列．配列のインデックスは，割込み優先度マスクの符号
 *  を反転したもの．
 *
 *  sigmask_table[0]：割込み属性が設定されていない割込みに対応するシグ
 *                    ナルのみをマスクするシグナルマスク
 *  sigmask_table[-TMIN_INTPRI]：カーネル管理の割込みすべてと，割込み属
 *                    性が設定されていない割込みに対応するシグナルをマ
 *                    スクするシグナルマスク
 *  sigmask_table[6]：NMIとSIGUSR2を除くすべての割込みと，割込み属性が設
 *                    定されていない割込みに対応するシグナルをマスクする
 *                    シグナルマスク
 *  sigmask_table[7]：sigmask_table[6]と同じ値
 */
extern const sigset_t sigmask_table[8];

/*
 *  割込み要求禁止フラグ実現のための変数の初期値（kernel_cfg.c）
 */
extern const sigset_t sigmask_disint_init;

/*
 *  割込みロック／CPUロックへの移行でマスクするシグナルを保持する変数
 */
extern sigset_t	sigmask_intlock;	/* 割込みロックでマスクするシグナル */
extern sigset_t	sigmask_cpulock;	/* CPUロックでマスクするシグナル */

/*
 *  コンテキストの参照
 */
Inline bool_t
sense_context(void)
{
	stack_t	ss;

	sigaltstack(NULL, &ss);
	return((ss.ss_flags & SS_ONSTACK) != 0);
}

/*
 *  CPUロックフラグ実現のための変数
 */
extern volatile bool_t		lock_flag;		/* CPUロックフラグを表す変数 */
extern volatile sigset_t	saved_sigmask;	/* シグナルマスクを保存する変数 */

/*
 *  割込み優先度マスク実現のための変数
 */
extern volatile PRI			intpri_value;	/* 割込み優先度マスクを表す変数 */

/*
 *  割込み要求禁止フラグ実現のための変数
 */
extern volatile sigset_t	sigmask_disint;	/* 個別にマスクしているシグナル */

/*
 *  シグナルマスクの設定
 *
 *  現在の状態（コンテキスト，CPUロックフラグ，割込み優先度マスク，割込
 *  み禁止フラグ）を参照して，現在のシグナルマスクとsaved_sigmaskを適切
 *  な値に設定する．
 */
Inline void
set_sigmask(void)
{
	sigset_t	sigmask;

	sigassignset(&sigmask, &(sigmask_table[-intpri_value]));
	sigjoinset(&sigmask, &sigmask_disint);
	if (sense_context()) {
		sigaddset(&sigmask, SIGUSR2);
	}
	if (lock_flag) {
		sigassignset(&saved_sigmask, &sigmask);
		sigjoinset(&sigmask, &sigmask_cpulock);
	}
	sigprocmask(SIG_SETMASK, &sigmask, NULL);
}

/*
 *  CPUロック状態への移行
 */
Inline void
lock_cpu(void)
{
	assert(!lock_flag);
	sigprocmask(SIG_BLOCK, &sigmask_cpulock, (sigset_t *) &saved_sigmask);
	lock_flag = true;
}

/*
 *  CPUロック状態への移行（ディスパッチできる状態）
 */
#define lock_cpu_dsp()		lock_cpu()

/*
 *  CPUロック状態の解除
 */
Inline void
unlock_cpu(void)
{
	assert(lock_flag);
	lock_flag = false;
	sigprocmask(SIG_SETMASK, (sigset_t *) &saved_sigmask, NULL);
}

/*
 *  CPUロック状態の解除（ディスパッチできる状態）
 */
#define unlock_cpu_dsp()	unlock_cpu()

/*
 *  CPUロック状態の参照
 */
Inline bool_t
sense_lock(void)
{
	return(lock_flag);
}

/*
 *  割込みを受け付けるための遅延処理
 */
Inline void
delay_for_interrupt(void)
{
}

/*
 *  割込み優先度マスクの設定
 */
Inline void
t_set_ipm(PRI intpri)
{
	intpri_value = intpri;
	set_sigmask();
}

/*
 *  割込み優先度マスクの参照
 */
Inline PRI
t_get_ipm(void)
{
	return(intpri_value);
}

/*
 *  割込み番号の範囲の判定
 */
#define	VALID_INTNO(intno)	(1 <= (intno) && (intno) <= 30 \
								&& (intno) != SIGKILL && (intno) != SIGSTOP)

/*
 *  割込み属性の設定のチェック
 */
Inline bool_t
check_intno_cfg(INTNO intno)
{
	return(!sigismember(&(sigmask_table[0]), intno)
				&& sigismember(&(sigmask_table[7]), intno));
}

/*
 *  割込み要求禁止フラグのセット
 */
Inline void
disable_int(INTNO intno)
{
	sigaddset(&sigmask_disint, intno);
	set_sigmask();
}

/*
 *  割込み要求禁止フラグのクリア
 */
Inline void
enable_int(INTNO intno)
{
	sigdelset(&sigmask_disint, intno);
	set_sigmask();
}

/*
 *  割込みが要求できる状態か？
 */
Inline bool_t
check_intno_raise(INTNO intno)
{
	return(true);
}

/*
 *  割込みの要求
 */
Inline void
raise_int(INTNO intno)
{
	raise(intno);
}

/*
 *  割込み要求のチェック
 */
Inline bool_t
probe_int(INTNO intno)
{
	sigset_t	sigmask;

	sigpending(&sigmask);
	return(sigismember(&sigmask, intno));
}

/*
 *  最高優先順位タスクへのディスパッチ
 *
 *  dispatchは，タスクコンテキストから呼び出されたサービスコール処理か
 *  ら呼び出すべきもので，タスクコンテキスト・CPUロック状態・ディスパッ
 *  チ許可状態・（モデル上の）割込み優先度マスク全解除状態で呼び出さな
 *  ければならない．
 */
extern void	dispatch(void);

/*
 *  非タスクコンテキストからのディスパッチ要求
 */
#define request_dispatch()

/*
 *  ディスパッチャの動作開始
 *
 *  start_dispatchをreturnにマクロ定義することで，カーネルの初期化完了
 *  後にsta_kerからmainにリターンさせ，シグナルスタックから元のスタック
 *  に戻す．
 */
#define start_dispatch()	return

/*
 *  現在のコンテキストを捨ててディスパッチ
 *
 *  exit_and_dispatchは，ext_tskから呼び出すべきもので，タスクコンテキ
 *  スト・CPUロック状態・ディスパッチ許可状態・（モデル上の）割込み優先
 *  度マスク全解除状態で呼び出さなければならない．
 */
extern void	exit_and_dispatch(void);

/*
 *  割込みハンドラ出口処理
 */
extern void	ret_int(void);

/*
 *  CPU例外ハンドラ出口処理
 */
extern void	ret_exc(void);

/*
 *  カーネルの終了処理の呼出し
 *
 *  call_exit_kernelは，カーネルの終了時に呼び出すべきもので，非タスク
 *  コンテキストに切り換えて，カーネルの終了処理（exit_kernel）を呼び出
 *  す．
 */
extern void call_exit_kernel(void) NoReturn;

/*
 *  タスクコンテキストの初期化
 *
 *  タスクが休止状態から実行できる状態に移行する時に呼ばれる．この時点
 *  でスタック領域を使ってはならない．
 *
 *  activate_contextを，インライン関数ではなくマクロ定義としているのは，
 *  この時点ではTCBが定義されていないためである．
 */
extern void	start_r(void);

#define activate_context(p_tcb)											\
{																		\
	((intptr_t *) &((p_tcb)->tskctxb.env))[JMPBUF_PC]					\
											= (intptr_t) start_r;		\
	((intptr_t *) &((p_tcb)->tskctxb.env))[JMPBUF_SP]					\
						= (intptr_t)((char *)((p_tcb)->p_tinib->stk)	\
										+ (p_tcb)->p_tinib->stksz		\
										- TASK_STACK_MERGIN);			\
}

/*
 *  割込みハンドラ番号とCPU例外ハンドラ番号の範囲の判定
 */
#define VALID_INHNO(inhno)		VALID_INTNO((INTNO)(inhno))
#define VALID_EXCNO(excno)		VALID_INTNO((INTNO)(excno))

/*
 *  割込みハンドラの設定
 *
 *  ベクトル番号inhnoの割込みハンドラの出入口処理の番地をint_entryに，
 *  割込み優先度をintpriに設定する．
 */
Inline void
define_inh(INHNO inhno, FP int_entry, PRI intpri)
{
	struct sigaction	sigact;

	assert(VALID_INHNO(inhno));
	sigact.sa_sigaction =
				(void (*)(int, struct __siginfo *, void *))(int_entry);
	sigact.sa_flags = (SA_ONSTACK | SA_SIGINFO);
	sigassignset(&(sigact.sa_mask), &(sigmask_table[-intpri]));
	sigaddset(&(sigact.sa_mask), SIGUSR2);
	sigaction(inhno, &sigact, NULL);
}

/*
 *  CPU例外ハンドラの設定
 *
 *  ベクトル番号excnoのCPU例外ハンドラの出入口処理の番地をexc_entryに設
 *  定する．
 *
 *  SA_NODEFERにより，シグナルハンドラの起動時に，そのシグナルをマスク
 *  するのを抑止している．
 */
Inline void
define_exc(EXCNO excno, FP exc_entry)
{
	struct sigaction	sigact;

	assert(VALID_EXCNO(excno));
	sigact.sa_sigaction =
				(void (*)(int, struct __siginfo *, void *))(exc_entry);
	sigact.sa_flags = (SA_ONSTACK | SA_SIGINFO | SA_NODEFER);
	sigemptyset(&(sigact.sa_mask));
	sigaddset(&(sigact.sa_mask), SIGUSR2);
	sigaction(excno, &sigact, NULL);
}

/*
 *  オーバランハンドラ動作開始／停止のためのマクロ
 */
#ifdef TOPPERS_SUPPORT_OVRHDR

#define OVRTIMER_START() do {					\
			if (_kernel_p_runtsk != NULL) {		\
				_kernel_ovrtimer_start();		\
			}									\
		} while (0)

#define OVRTIMER_STOP()		_kernel_ovrtimer_stop()

#else /* TOPPERS_SUPPORT_OVRHDR */

#define OVRTIMER_START()	((void) 0)
#define OVRTIMER_STOP()		((void) 0)

#endif /* TOPPERS_SUPPORT_OVRHDR */

/*
 *  割込みハンドラの入口処理の生成マクロ
 */
#define INT_ENTRY(inhno, inthdr)	_kernel_##inthdr##_##inhno

#define INTHDR_ENTRY(inhno, inthdr, intpri)								\
void _kernel_##inthdr##_##inhno(int sig,								\
						struct __siginfo *p_info, void *p_ctx)			\
{																		\
	PRI		saved_intpri;												\
																		\
	lock_cpu();															\
	saved_intpri = _kernel_intpri_value;								\
	_kernel_intpri_value = intpri;										\
	if (((ucontext_t *) p_ctx)->uc_onstack == 0) {						\
		OVRTIMER_STOP();												\
	}																	\
	unlock_cpu();														\
																		\
	LOG_INH_ENTER(inhno);												\
	inthdr();					/* 割込みハンドラを呼び出す */			\
	LOG_INH_LEAVE(inhno);												\
																		\
	if (!sense_lock()) {												\
		lock_cpu();														\
	}																	\
	if (((ucontext_t *) p_ctx)->uc_onstack == 0) {						\
		if (_kernel_p_runtsk != _kernel_p_schedtsk) {					\
			raise(SIGUSR2);		/* ディスパッチャの起動を要求する */	\
		}																\
		else {															\
			OVRTIMER_START();											\
		}																\
	}																	\
	_kernel_intpri_value = saved_intpri;								\
	unlock_cpu();														\
}

/*
 *  CPU例外ハンドラの入口処理の生成マクロ
 */
#define EXC_ENTRY(excno, exchdr)	_kernel_##exchdr##_##excno

#define EXCHDR_ENTRY(excno, excno_num, exchdr)								\
void _kernel_##exchdr##_##excno(int sig,									\
						struct __siginfo *p_info, void *p_ctx)				\
{																			\
	if (exc_sense_nonkernel(p_ctx)) {										\
		bool_t	saved_lock_flag;											\
																			\
		/* カーネル管理外のCPU例外ハンドラの場合 */							\
		saved_lock_flag = _kernel_lock_flag;								\
		exchdr(p_ctx);				/* CPU例外ハンドラを呼び出す */			\
		_kernel_lock_flag = saved_lock_flag;								\
	}																		\
	else {																	\
		/* カーネル管理のCPU例外ハンドラの場合 */							\
		lock_cpu();															\
		if (((ucontext_t *) p_ctx)->uc_onstack == 0) {						\
			OVRTIMER_STOP();												\
		}																	\
		unlock_cpu();														\
																			\
		LOG_EXC_ENTER(excno);												\
		exchdr(p_ctx);				/* CPU例外ハンドラを呼び出す */			\
		LOG_EXC_LEAVE(excno);												\
																			\
		if (!sense_lock()) {												\
			lock_cpu();														\
		}																	\
		if (((ucontext_t *) p_ctx)->uc_onstack == 0) {						\
			if (_kernel_p_runtsk != _kernel_p_schedtsk) {					\
				raise(SIGUSR2);		/* ディスパッチャの起動を要求する */	\
			}																\
			else {															\
				OVRTIMER_START();											\
			}																\
		}																	\
		unlock_cpu();														\
	}																		\
}

/*
 *  CPU例外の発生した時のコンテキストの参照
 *
 *  CPU例外の発生した時のコンテキストが，タスクコンテキストの時にfalse，
 *  そうでない時にtrueを返す．
 */
Inline bool_t
exc_sense_context(void *p_excinf)
{
	return(((ucontext_t *) p_excinf)->uc_onstack != 0);
}

/*
 *  カーネル管理外のCPU例外の判別
 *
 *  カーネル管理外のCPU例外の時にtrue，そうでない時にfalseを返す．
 */
Inline bool_t
exc_sense_nonkernel(void *p_excinf)
{
	sigset_t	sigmask;

	sigassignset(&sigmask, &(((ucontext_t *) p_excinf)->uc_sigmask));
	return(sigismember(&sigmask, SIGUSR2));
}

/*
 *  CPU例外の発生した時のコンテキストと割込みのマスク状態の参照
 *
 *  CPU例外の発生した時のシステム状態が，カーネル内のクリティカルセクショ
 *  ンの実行中でなく，全割込みロック状態でなく，CPUロック状態でなく，カー
 *  ネル管理外の割込みハンドラ実行中でなく，カーネル管理外のCPU例外ハン
 *  ドラ実行中でなく，タスクコンテキストであり，割込み優先度マスクが全
 *  解除である時にtrue，そうでない時にfalseを返す．
 */
Inline bool_t
exc_sense_intmask(void *p_excinf)
{
	return(!exc_sense_context(p_excinf) && !exc_sense_nonkernel(p_excinf)
											&& intpri_value == TIPM_ENAALL);
}

/*
 *  ターゲットシステム依存の初期化
 */
extern void	target_initialize(void);

/*
 *  ターゲットシステムの終了
 *
 *  システムを終了する時に使う．
 */
extern void	target_exit(void) NoReturn;

#endif /* TOPPERS_MACRO_ONLY */

/*
 *  カーネルの割り付けるメモリ領域の管理
 *
 *  target_kernel_impl.cに，TLSF（オープンソースのメモリ管理ライブラリ）
 *  を用いたメモリ管理ルーチンを含めている．
 */
#define OMIT_KMM_ALLOCONLY

#endif /* TOPPERS_TARGET_KERNEL_IMPL_H */
