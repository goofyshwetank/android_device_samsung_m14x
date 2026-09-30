// Samsung's libsensorndkbridge exported ALooper_forCamera(); AOSP's does not.
struct ALooper;
extern "C" ALooper* ALooper_prepare(int opts);

extern "C" ALooper* ALooper_forCamera() {
    return ALooper_prepare(0);
}
