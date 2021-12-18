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
 *  $Id: tSIOPortMacOSXMain.c 526 2016-01-14 11:43:26Z ertl-hiro $
 */

/*
 *		SIOドライバ（Mac OS X用）
 */

#include "macosx.h"
#include <t_stddef.h>
#include <t_syslog.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include "tSIOPortMacOSXMain_tecsgen.h"
 
/*
 *  SIOポートのオープン
 */
void
eSIOPort_open(CELLIDX idx)
{
	CELLCB	*p_cellcb = GET_CELLCB(idx);
	int_t	fd;
	struct	termios term;

	if (ATTR_path != NULL) {
		fd = open(ATTR_path, O_RDWR, 0777);
		assert(fd >= 0);
		VAR_read_fd = fd;
		VAR_write_fd = fd;
	}
	else {
		fd = STDIN_FILENO;					/* 標準入出力を使う */
		VAR_read_fd = STDIN_FILENO;
		VAR_write_fd = STDOUT_FILENO;
	}
	fcntl(fd, F_SETOWN, getpid());
	fcntl(fd, F_SETFL, (O_NONBLOCK | O_ASYNC));

	tcgetattr(fd, &VAR_saved_term);
	term = VAR_saved_term;
	term.c_lflag &= ~(ECHO | ICANON);
	tcsetattr(fd, TCSAFLUSH, &term);

	VAR_rcv_flag = false;
	VAR_rcv_rdy = false;
	VAR_snd_flag = false;
	VAR_snd_rdy = false;
	VAR_openflag = true;
}

/*
 *  SIOポートのクローズ
 */
void
eSIOPort_close(CELLIDX idx)
{
	CELLCB	*p_cellcb = GET_CELLCB(idx);
	int_t	fd;

	fd = VAR_read_fd;
	tcsetattr(fd, TCSAFLUSH, &VAR_saved_term);
	fcntl(fd, F_SETFL, 0);

	if (ATTR_path != NULL) {
		close(VAR_read_fd);
	}
	VAR_openflag = false;
}

/*
 *  SIOポートへの文字送信
 */
bool_t
eSIOPort_putChar(CELLIDX idx, char c)
{
	CELLCB	*p_cellcb = GET_CELLCB(idx);
	int_t	n;

	if (!VAR_snd_flag) {
		if ((n = write(VAR_write_fd, &c, 1)) > 0) {
			return(true);
		}
		else {
			assert(n < 0 && errno == EAGAIN);
			VAR_snd_flag = true;
			VAR_snd_buf = c;
			return(true);
		}
	}
	else {
		return(false);
	}
}

/*
 *  SIOポートからの文字受信
 */
int_t
eSIOPort_getChar(CELLIDX idx)
{
	CELLCB	*p_cellcb = GET_CELLCB(idx);
	char	c;
	int_t	n;

	if (VAR_rcv_flag) {
		VAR_rcv_flag = false;
		return((int_t)(uint8_t)(VAR_rcv_buf));
	}
	else if ((n = read(VAR_read_fd, &c, 1)) > 0) {
		return((int_t)(uint8_t) c);
	}
	else {
		assert(n < 0 && errno == EAGAIN);
		return(-1);
	}
}

/*
 *  SIOポートからのコールバックの許可
 */
void
eSIOPort_enableCBR(CELLIDX idx, uint_t cbrtn)
{
	CELLCB	*p_cellcb = GET_CELLCB(idx);

	switch (cbrtn) {
	case SIOSendReady:
		VAR_snd_rdy = true;
		break;
	case SIOReceiveReady:
		VAR_rcv_rdy = true;
		break;
	}
}

/*
 *  SIOポートからのコールバックの禁止
 */
void
eSIOPort_disableCBR(CELLIDX idx, uint_t cbrtn)
{
	CELLCB	*p_cellcb = GET_CELLCB(idx);

	switch (cbrtn) {
	case SIOSendReady:
		VAR_snd_rdy = false;
		break;
	case SIOReceiveReady:
		VAR_rcv_rdy = false;
		break;
	}
}

/*
 *  SIOの割込みサービスルーチン
 */
void
eiISR_main(CELLIDX idx)
{
	CELLCB	*p_cellcb = GET_CELLCB(idx);
	int_t	n;

	if (VAR_snd_flag) {
		if ((n = write(VAR_write_fd, &(VAR_snd_buf), 1)) > 0) {
			VAR_snd_flag = false;
			if (VAR_snd_rdy && is_ciSIOCBR_joined()) { 
				ciSIOCBR_readySend();
			}
		}
	}
	if (!VAR_rcv_flag) {
		if ((n = read(VAR_read_fd, &(VAR_rcv_buf), 1)) > 0) {
			VAR_rcv_flag = true;
			if (VAR_rcv_rdy && is_ciSIOCBR_joined()) {
				ciSIOCBR_readyReceive();
			}
		}
	}
}

/*
 *  SIOドライバの終了処理
 */
void
eTerminate_main(CELLIDX idx)
{
	CELLCB	*p_cellcb = GET_CELLCB(idx);

	if (VAR_openflag) {
		eSIOPort_close(idx);
	}
}
