// Samsung's libsensorndkbridge gives the camera its own loopers instead of the shared one.
#include "ALooper.h"

extern "C" ALooper* ALooper_forCamera() {
    return new ALooper();
}

extern "C" int ALooper_pollOnce_camera(ALooper* looper, int timeoutMillis, int* outFd,
                                       int* outEvents, void** outData) {
    return looper->pollOnce(timeoutMillis, outFd, outEvents, outData);
}

extern "C" void ALooper_release_forCamera(ALooper* looper) {
    delete looper;
}
