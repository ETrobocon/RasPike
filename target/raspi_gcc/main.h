#ifndef _MAIN_H_
#define _MAIN_H_

typedef int (*StartUpCb)(void);

/* コンフィグを読み込んだ後で呼ばれるコールバック関数変数。使用する場合はグローバルコンストラクタ(__attribute__((constructor)) )で設定を行う */

extern StartUpCb deviceStartupCb;

#endif
