// -----------------------------------------------------------------------------------------
// by rigaya
// -----------------------------------------------------------------------------------------
// The MIT License

#include <cstdint>
#include <climits>

#if !(defined(_WIN32) || defined(_WIN64))
enum : uint32_t {
    WAIT_OBJECT_0 = 0,
    WAIT_TIMEOUT = 258L,
    WAIT_ABANDONED_0 = 0x00000080L
};

typedef void* HANDLE;

static const uint32_t INFINITE = UINT_MAX;

void ResetEvent(HANDLE ev);
void SetEvent(HANDLE ev);
HANDLE CreateEvent(void *pDummy, int bManualReset, int bInitialState, void *pDummy2);
void CloseEvent(HANDLE ev);
uint32_t WaitForSingleObject(HANDLE ev, uint32_t millisec);
#endif //#if !(defined(_WIN32) || defined(_WIN64))
