#pragma once
#include <stdint.h>
#include <stddef.h>

typedef void (*WhoDisStatusCallback)(const char *status, void *context);

int who_dis_check(void);
void *who_dis_start(const char *config_json, WhoDisStatusCallback callback, void *context);
void who_dis_stop(void *handle);
