// -----------------------------------------------------------------------------------------
// by rigaya
// -----------------------------------------------------------------------------------------
// The MIT License
#include "event.h"
#if !(defined(_WIN32) || defined(_WIN64))
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <climits>
#include <chrono>
#include <algorithm>

class Event {
public:
    bool bManualReset;
    bool bReady;
    std::mutex mtx;
    std::condition_variable cv;

    Event() : bManualReset(false), bReady(false), mtx(), cv() {

    };
    Event(bool manualReset) : Event() {
        bManualReset = manualReset;
    };
};

void ResetEvent(HANDLE ev) {
    Event *event = (Event *)ev;
    {
        std::lock_guard<std::mutex> lock(event->mtx);
        if (event->bReady) {
            event->bReady = false;
        }
    }
}

void SetEvent(HANDLE ev) {
    Event *event = (Event *)ev;
    {
        std::lock_guard<std::mutex> lock(event->mtx);
        if (!event->bReady) {
            event->bReady = true;
            (event->bManualReset) ? event->cv.notify_all() : event->cv.notify_one();
        }
    }
}

HANDLE CreateEvent(void *pDummy, int bManualReset, int bInitialState, void *pDummy2) {
    Event *event = new Event(!!bManualReset);
    if (bInitialState) {
        SetEvent(event);
    }
    return event;
}

void CloseEvent(HANDLE ev) {
    if (ev != NULL) {
        Event *event = (Event *)ev;
       delete event;
    }
}

uint32_t WaitForSingleObject(HANDLE ev, uint32_t millisec) {
    Event *event = (Event *)ev;
    {
        std::unique_lock<std::mutex> uniq_lk(event->mtx);
        if (millisec == INFINITE) {
            event->cv.wait(uniq_lk, [&event]{ return event->bReady;});
            if (!event->bManualReset) {
                event->bReady = false;
            }
        } else {
            event->cv.wait_for(uniq_lk, std::chrono::milliseconds(millisec), [&event]{ return event->bReady;});
            if (!event->bReady) {
                return WAIT_TIMEOUT;
            }
            if (!event->bManualReset) {
                event->bReady = false;
            }
        }
    }
    return WAIT_OBJECT_0;
}

#endif //#if !(defined(_WIN32) || defined(_WIN64))