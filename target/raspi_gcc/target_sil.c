#include "target_sil.h"

static SilWriteHook writeHook = 0;

void SilSetWriteHook(const SilWriteHook hook)
{
  writeHook = hook;
}

Std_ReturnType SilCallWriteHook(int size, uintptr_t addr, const void* data)
{
  if ( writeHook ) {
    return (*writeHook)(size,addr,data);
  }
  return 0;
}

void foo(void)
{
  return;
}
