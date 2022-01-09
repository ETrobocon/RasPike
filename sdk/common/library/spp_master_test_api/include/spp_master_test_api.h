#pragma once

extern bool_t spp_master_test_is_connected();
extern void   spp_master_test_connect_ev3(uint8_t addr[6], const char *pin);
extern FILE*  spp_master_test_open_file();
