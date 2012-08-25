#ifndef TEST_NETWORK_H
#define TEST_NETWORK_H

#include <AM.h>
#include "UsaNetworkC.h"

enum{
AM_DUMMYUSANETWORKMSG = 0x05,
};

typedef nx_struct DummyUsaNetworkMsg {
    nx_uint32_t dummy1;
    nx_uint32_t dummy2;
  nx_uint16_t dummy3;
  nx_am_addr_t source;
  nx_uint16_t seqno;
  nx_am_addr_t parent;
  //nx_uint16_t metric;
  //nx_uint16_t data;
  //nx_uint16_t sendCount;
  //nx_uint16_t sendSuccessCount;
  nx_uint16_t voltage;
  nx_uint8_t hopToSource;
  nx_uint8_t passNodeId;
} DummyUsaNetworkMsg;

typedef nx_struct UsaNetworkMsg {
  nx_am_addr_t source;
  nx_uint16_t seqno;
  nx_am_addr_t parent;
  //nx_uint16_t metric;
  //nx_uint16_t data;
  //nx_uint16_t sendCount;
  //nx_uint16_t sendSuccessCount;
  nx_uint16_t voltage;
  nx_uint8_t hopToSource;
  nx_uint8_t passNodeId;
} UsaNetworkMsg;

#endif
