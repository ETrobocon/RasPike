#include "devconfig.h"

/* 
 * Option取得の処理はathrillのcpuemu.cをベースにして必要なものを切り出したものです。
 * 
 * https://github.com/toppers/athrill
 */

#include "option.h"
#include <stdio.h>
#include <string.h>
#include "token.h"
#include "file.h"
#include "std_errno.h"

#define CPUEMU_DEVCFG_PARAM_MAXNUM	128
typedef struct {
	uint32			param_num;
	struct {
		TokenValueType	key;
		TokenValueType	value;
	} param[CPUEMU_DEVCFG_PARAM_MAXNUM];
} CpuEmuDevCfgType;

static CpuEmuDevCfgType cpuemu_devcfg;
static char dvcfg_buffer[4096];
static TokenContainerType devcfg_token_container;
static FileType devcfg_file;


Std_ReturnType cpuemu_load_devcfg(const char *path)
{
	Std_ReturnType err = STD_E_OK;
	uint32 len;
	bool ret;

	cpuemu_devcfg.param_num = 0;

	ret = token_string_set(&devcfg_file.filepath, path);
	if (ret == FALSE) {
		return STD_E_INVALID;
	}
	ret = file_ropen(&devcfg_file);
	if (ret == FALSE) {
		return STD_E_NOENT;
	}
	while (TRUE) {
		err = STD_E_INVALID;

		len = file_getline(&devcfg_file, dvcfg_buffer, 4096);
		if (len <= 0) {
			break;
		}
		err = token_split(&devcfg_token_container, (uint8*)dvcfg_buffer, len);
		if (err != STD_E_OK) {
			printf("ERROR: can not parse data on %s...\n", path);
			goto errdone;
		}
		if (devcfg_token_container.num != 2) {
			printf("ERROR: the token is invalid %s on %s...\n", dvcfg_buffer, path);
			goto errdone;
		}
		cpuemu_devcfg.param[cpuemu_devcfg.param_num].key = devcfg_token_container.array[0];
		cpuemu_devcfg.param[cpuemu_devcfg.param_num].value = devcfg_token_container.array[1];
		cpuemu_devcfg.param_num++;
		//printf("param=%s\n", devcfg_token_container.array[0].body.str.str);
		//printf("value=%s\n", devcfg_token_container.array[1].body.str.str);
	}

	file_close(&devcfg_file);
	return STD_E_OK;
errdone:
	file_close(&devcfg_file);
	return err;
}

static void cpuemu_env_parse_devcfg_string(TokenStringType* strp)
{
	static char env_name[TOKEN_STRING_MAX_SIZE];
	static char out_name[TOKEN_STRING_MAX_SIZE];
	char *start = strchr((const char*)strp->str, '{');
	char *end = strchr((const char*)strp->str, '}');
	if ((start == NULL) || (end == NULL)) {
		return;
	}
	int len = ((int)(end - start) - 1);
	if (len == 0) {
		return;
	}
	memset(env_name, 0, TOKEN_STRING_MAX_SIZE);
	memcpy(env_name, (start + 1), len);

	//printf("%s\n", env_name);
	char *ep = getenv(env_name);
	if (ep == NULL) {
		return;
	}
	//printf("ep = %s\n", ep);
	memset(out_name, 0, TOKEN_STRING_MAX_SIZE);
	len = snprintf(out_name, TOKEN_STRING_MAX_SIZE, "%s%s", ep, (end + 1));
	out_name[len] = '\0';
	len++;
	//printf("out_name=%s len=%d\n", out_name, len);
	memcpy(strp->str, out_name, len);
	strp->len = len;

	return;
}

Std_ReturnType cpuemu_get_devcfg_value(const char* key, uint32 *value)
{
	int i;
	TokenStringType token;

	token.len = strlen(key);
	memcpy(token.str, key, token.len);
	token.str[token.len] = '\0';

	for (i = 0; i < cpuemu_devcfg.param_num; i++) {
		if (cpuemu_devcfg.param[i].value.type != TOKEN_TYPE_VALUE_DEC) {
			continue;
		}
		if (token_strcmp(&cpuemu_devcfg.param[i].key.body.str, &token) == FALSE) {
			continue;
		}
		*value = cpuemu_devcfg.param[i].value.body.dec.value;
		return STD_E_OK;
	}
	return STD_E_NOENT;
}



Std_ReturnType cpuemu_get_devcfg_value_hex(const char* key, uint32 *value)
{
	int i;
	TokenStringType token;

	token.len = strlen(key);
	memcpy(token.str, key, token.len);
	token.str[token.len] = '\0';

	for (i = 0; i < cpuemu_devcfg.param_num; i++) {
		if (cpuemu_devcfg.param[i].value.type != TOKEN_TYPE_VALUE_HEX) {
			continue;
		}
		if (token_strcmp(&cpuemu_devcfg.param[i].key.body.str, &token) == FALSE) {
			continue;
		}
		*value = cpuemu_devcfg.param[i].value.body.hex.value;
		return STD_E_OK;
	}
	return STD_E_NOENT;
}

Std_ReturnType cpuemu_get_devcfg_string(const char* key, char **value)
{
	int i;
	TokenStringType token;

	token.len = strlen(key);
	memcpy(token.str, key, token.len);
	token.str[token.len] = '\0';

	for (i = 0; i < cpuemu_devcfg.param_num; i++) {
		if (cpuemu_devcfg.param[i].value.type != TOKEN_TYPE_STRING) {
			continue;
		}
		if (token_strcmp(&cpuemu_devcfg.param[i].key.body.str, &token) == FALSE) {
			continue;
		}
		cpuemu_env_parse_devcfg_string(&cpuemu_devcfg.param[i].value.body.str);
		*value = (char*)cpuemu_devcfg.param[i].value.body.str.str;
		printf("%s = %s\n", key, *value);
		return STD_E_OK;
	}
	return STD_E_NOENT;
}

