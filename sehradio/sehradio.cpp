// rild only reports the modem's real radio capability (LTE_CA/NR) on slots where
// ISehRadioNetwork::setResponseFunctions was called; One UI's framework does that, AOSP never does.
// Register no-op callbacks on every slot as soon as rild is up, before telephony's first
// GET_RADIO_CAPABILITY, then stay alive so the callbacks remain valid.
#include <android/binder_ibinder.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>
#include <android/binder_stability.h>
#include <log/log.h>
#include <string.h>
#include <unistd.h>

#include <string>

#undef LOG_TAG
#define LOG_TAG "sehradio"

static const std::string kPkg = "vendor.samsung.hardware.radio.network.";

static binder_status_t onTransact(AIBinder*, transaction_code_t code, const AParcel*, AParcel* out) {
    if (code == FIRST_CALL_TRANSACTION + 16777214) {  // getInterfaceVersion
        AParcel_writeStatusHeader(out, nullptr);
        return AParcel_writeInt32(out, 1);
    }
    return STATUS_OK;
}
static void* onCreate(void* args) { return args; }
static void onDestroy(void*) {}

static AIBinder_Class* defineClass(const std::string& name) {
    return AIBinder_Class_define(strdup((kPkg + name).c_str()), onCreate, onDestroy, onTransact);
}

static AIBinder* newCallback(const char* name) {
    AIBinder* b = AIBinder_new(defineClass(name), nullptr);
    AIBinder_markVintfStability(b);
    return b;
}

// ponytail: if rild restarts, init restarts us too, but telephony may query the capability
// before we re-register; a phone process restart (or reboot) recovers it.
static void onRildDied(void*) {
    ALOGE("rild died, exiting");
    _exit(1);
}

int main() {
    ABinderProcess_setThreadPoolMaxThreadCount(1);
    ABinderProcess_startThreadPool();
    AIBinder_Class* svcClass = defineClass("ISehRadioNetwork");
    AIBinder_DeathRecipient* death = AIBinder_DeathRecipient_new(onRildDied);

    for (int slot = 1;; slot++) {
        std::string name = kPkg + "ISehRadioNetwork/slot" + std::to_string(slot);
        if (!AServiceManager_isDeclared(name.c_str())) break;
        AIBinder* svc = AServiceManager_waitForService(name.c_str());
        if (!svc || !AIBinder_associateClass(svc, svcClass)) {
            ALOGE("%s unavailable", name.c_str());
            return 1;
        }
        AIBinder_linkToDeath(svc, death, nullptr);

        AParcel* in = nullptr;
        AParcel* out = nullptr;
        AIBinder_prepareTransaction(svc, &in);
        AParcel_writeStrongBinder(in, newCallback("ISehRadioNetworkResponse"));
        AParcel_writeStrongBinder(in, newCallback("ISehRadioNetworkIndication"));
        binder_status_t st =
                AIBinder_transact(svc, FIRST_CALL_TRANSACTION + 20, &in, &out, FLAG_ONEWAY);
        if (out) AParcel_delete(out);
        ALOGI("%s setResponseFunctions -> %d", name.c_str(), st);
        if (st != STATUS_OK) return 1;
    }

    ABinderProcess_joinThreadPool();
    return 1;
}
