/*
 *  EV3用ドライバ定義
 */

#ifndef TOPPERS_EV3_H
#define TOPPERS_EV3_H

#include <sil.h>


/**
 * Task priority
 */
#define TPRI_INIT_TASK       (TMIN_TPRI)
#define TPRI_USBMSC          (TMIN_TPRI + 1)
#define TPRI_BLUETOOTH_QOS   (TMIN_TPRI + 1)
#define TPRI_BLUETOOTH_HIGH  (TMIN_TPRI + 2)
#define TPRI_APP_TERM_TASK   (TMIN_TPRI + 3)
#define TPRI_EV3_LCD_TASK    (TMIN_TPRI + 3)
#define TPRI_EV3_MONITOR     (TMIN_TPRI + 4)
#define TPRI_PLATFORM_BUSY   (TMIN_TPRI + 5)
#define TPRI_APP_INIT_TASK   (TMIN_TPRI + 6)
#define TPRI_EV3_CYC         (TMIN_TPRI + 7)
#define TMIN_APP_TPRI        (TMIN_TPRI + 8)
#define TPRI_BLUETOOTH_LOW   (TMAX_TPRI)/*(TMIN_TPRI + 1)*/

/*
 *  タスクのスタックサイズ
 */
#ifndef STACK_SIZE
#define STACK_SIZE  4096
#endif

/**
 * Memory
 */
#define KERNEL_HEAP_SIZE (1024 * 1024) //!< Heap size for dynamic memory allocation in TDOM_KERNEL
#define APP_HEAP_SIZE    (1024 * 1024) //!< Heap size for dynamic memory allocation in TDOM_APP

/**
 * Bluetooth configuration
 */
#define BT_SND_BUF_SIZE        (2048)             //!< Size of send buffer
#define BT_HIGH_PRI_TIME_SLICE (1)                //!< Time slice for BT_TSK in high priority mode (mS)
#define BT_LOW_PRI_TIME_SLICE  (19)               //!< Time slice for BT_TSK in low priority mode (mS)
#define BT_USE_EDMA_MODE       (true)            //!< true: EDMA mode, false: interrupt mode

/**
 * Loadable application module configuration (Dynamic loading)
 */
#define TMAX_APP_TSK_NUM     (32)          //!< Maximum number of tasks in a loadable application module
#define TMAX_APP_SEM_NUM     (16)          //!< Maximum number of semaphores in a loadable application module
#define TMAX_APP_FLG_NUM     (16)          //!< Maximum number of event flags in a loadable application module
#define TMAX_APP_DTQ_NUM     (16)          //!< Maximum number of data queues in a loadable application module
#define TMAX_APP_PDQ_NUM     (16)          //!< Maximum number of priority data queues in a loadable application module
#define TMAX_APP_MTX_NUM     (16)          //!< Maximum number of mutexes in a loadable application module
#define TMAX_APP_TEXT_SIZE   (1024 * 1024) //!< Maximum size of the text section in a loadable application module
#define TMAX_APP_DATA_SIZE   (1024 * 1024) //!< Maximum size of the data section in a loadable application module
#define TMAX_APP_BINARY_SIZE (1024 * 1024) //!< Maximum size of a loadable application module's binary file

/**
 * LCD configuration
 */
#define LCD_FRAME_RATE (25)

/**
 * Miscellaneous configuration
 */
#define FORCE_SHUTDOWN_TIMEOUT (500)  //!< Timeout in milliseconds of force shutdown feature by pressing BACK+LEFT+RIGHT buttons
#define TMAX_EV3_CYC_NUM       (16)   //!< Maximum number of EV3_CRE_CYC in a user application

/**
 * Default SIO Port for syslog etc.
 */
#ifndef TOPPERS_MACRO_ONLY
extern int SIO_PORT_DEFAULT;
#endif

/**
 * Utility function for outputting SVC error
 */
#ifndef TOPPERS_MACRO_ONLY
extern void svc_perror(const char *file, int_t line, const char *expr, ER ercd);
#define SVC_PERROR(expr) svc_perror(__FILE__, __LINE__, #expr, (expr))
# if 0
#define SVC_PERROR(expr) do { \
	ER ercd = (expr); \
	if (ercd < 0) { \
		t_perror(LOG_ERROR, __FILE__, __LINE__, #expr, ercd); \
	} \
}while(0)
#endif
#endif

/**
 * PRU Soft UART Driver
 */
#define SUART1_INT 3
#define SUART2_INT 4
#ifndef TOPPERS_MACRO_ONLY
extern void pru_suart_isr(intptr_t portline);
#endif

#define TCNT_SYSLOG_BUFFER (1024)

#endif /* TOPPERS_EV3_H */
