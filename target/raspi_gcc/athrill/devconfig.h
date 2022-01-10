#ifndef _DEVCONFIG_H_
#define _DEVCONFIG_H_
#include "std_types.h"
#include "std_errno.h"

extern Std_ReturnType cpuemu_load_devcfg(const char *path);
extern Std_ReturnType cpuemu_get_devcfg_value(const char* key, uint32 *value);
extern Std_ReturnType cpuemu_get_devcfg_value_hex(const char* key, uint32 *value);
extern Std_ReturnType cpuemu_get_devcfg_string(const char* key, char **value);

#endif /* _DEVCONFIG_H_ */
