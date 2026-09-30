// SPDX-License-Identifier: Apache-2.0
//
// Wrap Samsung libsec-ril-impl.so so the SMSC it reports is dialable and the
// SMSC it is sent is valid BCD. Based on LineageOS sm8550-common's shim.
// Also report the framework as ready, which Samsung's telephony framework (or
// Lineage's sehradiomanager) normally does; until then incoming SMS are dropped.

#define LOG_TAG "sec-ril-shim"

#include <dlfcn.h>
#include <sys/system_properties.h>
#include <unistd.h>

#include <cstddef>
#include <cstring>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_set>

#include <android/binder_ibinder.h>
#include <android/binder_manager.h>
#include <cutils/properties.h>
#include <log/log.h>
#include <telephony/ril.h>

#include "SmscAddress.h"

static constexpr char kRealPath[] = "/vendor/lib64/libsec-ril-impl.so";

using SamsungRequestFunc = void (*)(int, void*, size_t, RIL_Token, RIL_SOCKET_ID);

// Samsung extends RIL_RadioFunctions after onRequest; only touch the prefix.
struct SamsungRilFunctionsPrefix {
    int version;
    SamsungRequestFunc onRequest;
};
static_assert(offsetof(SamsungRilFunctionsPrefix, onRequest) == sizeof(void*));

using RilInit = const RIL_RadioFunctions* (*)(const RIL_Env*, int, char**);

// rild_exynos passes exactly the four standard callbacks.
static_assert(sizeof(RIL_Env) == 4 * sizeof(void*));
static RIL_Env gShimEnv;
static const RIL_Env* gRealEnv = nullptr;
static SamsungRequestFunc gRealOnRequest = nullptr;

static std::mutex gMutex;
static std::unordered_set<RIL_Token> gSmscRequests;

static void shimOnRequestComplete(RIL_Token token, RIL_Errno error, void* response,
                                  size_t responselen) {
    bool isSmsc;
    {
        std::lock_guard<std::mutex> lock(gMutex);
        isSmsc = gSmscRequests.erase(token) != 0;
    }
    if (isSmsc && error == RIL_E_SUCCESS) {
        // Samsung returns e.g. "919935051914",145; Telephony wants +919935051914.
        std::string address;
        if (response != nullptr && responselen > 0 && responselen <= 128) {
            const char* text = static_cast<const char*>(response);
            if (samsung::ril::normalizeSmscAddress({text, strnlen(text, responselen)},
                                                   &address)) {
                gRealEnv->OnRequestComplete(token, error, address.data(), address.size() + 1);
                return;
            }
        }
        ALOGW("sec-ril-shim: invalid SMSC response");
        gRealEnv->OnRequestComplete(token, RIL_E_INVALID_RESPONSE, nullptr, 0);
        return;
    }
    gRealEnv->OnRequestComplete(token, error, response, responselen);
}

static void shimOnRequest(int request, void* data, size_t datalen, RIL_Token token,
                          RIL_SOCKET_ID socketId) {
    if (request == RIL_REQUEST_GET_SMSC_ADDRESS) {
        std::lock_guard<std::mutex> lock(gMutex);
        gSmscRequests.insert(token);
    } else if ((request == RIL_REQUEST_SEND_SMS || request == RIL_REQUEST_SEND_SMS_EXPECT_MORE) &&
               data != nullptr && datalen == 2 * sizeof(char*)) {
        char** sms = static_cast<char**>(data);
        if (sms[0] != nullptr && sms[1] != nullptr) {
            std::string pdu;
            size_t length = strnlen(sms[0], 129);
            if (length > 128 || !samsung::ril::normalizeSmscPdu({sms[0], length}, &pdu)) {
                ALOGW("sec-ril-shim: invalid SMSC for request %d", request);
                gRealEnv->OnRequestComplete(token, RIL_E_INVALID_ARGUMENTS, nullptr, 0);
                return;
            }
            if (pdu != sms[0]) {
                char* fixed[] = {pdu.data(), sms[1]};
                gRealOnRequest(request, fixed, sizeof(fixed), token, socketId);
                return;
            }
        }
    }
    gRealOnRequest(request, data, datalen, token, socketId);
}

// Serialize one SehVendorConfiguration {String name; String value;} array element.
static bool writeConfig(AParcel* parcel, const char* name, const char* value) {
    if (AParcel_writeInt32(parcel, 1) != STATUS_OK) return false;  // non-null
    int32_t start = AParcel_getDataPosition(parcel);
    if (AParcel_writeInt32(parcel, 0) != STATUS_OK ||
        AParcel_writeString(parcel, name, strlen(name)) != STATUS_OK ||
        AParcel_writeString(parcel, value, strlen(value)) != STATUS_OK) {
        return false;
    }
    int32_t end = AParcel_getDataPosition(parcel);
    return AParcel_setDataPosition(parcel, start) == STATUS_OK &&
           AParcel_writeInt32(parcel, end - start) == STATUS_OK &&
           AParcel_setDataPosition(parcel, end) == STATUS_OK;
}

static void sendFrameworkReady() {
    // Set by init on sys.boot_completed, which vendor domains cannot read.
    while (__system_property_find("ro.vendor.radio.fw_ready") == nullptr) sleep(1);

    // ISehRadioNetwork.setVendorSpecificConfiguration(int, in SehVendorConfiguration[])
    constexpr transaction_code_t kSetVendorSpecificConfiguration = FIRST_CALL_TRANSACTION + 23;
    int slots = property_get_int32("ro.vendor.multisim.simslotcount", 1);
    for (int slot = 1; slot <= slots; slot++) {
        std::string name = "vendor.samsung.hardware.radio.network.ISehRadioNetwork/slot" +
                           std::to_string(slot);
        AIBinder* binder = AServiceManager_waitForService(name.c_str());
        if (binder == nullptr) {
            ALOGE("sec-ril-shim: %s not found", name.c_str());
            continue;
        }
        AParcel* in = nullptr;
        AParcel* out = nullptr;
        binder_status_t status = AIBinder_prepareTransaction(binder, &in);
        if (status == STATUS_OK) {
            bool ok = AParcel_writeInt32(in, 0x4242) == STATUS_OK &&
                      AParcel_writeInt32(in, 2) == STATUS_OK &&
                      writeConfig(in, "FW_READY", "1") && writeConfig(in, "CA_ENABLED", "1");
            status = ok ? AIBinder_transact(binder, kSetVendorSpecificConfiguration, &in, &out,
                                            FLAG_ONEWAY)
                        : STATUS_NO_MEMORY;
        }
        if (in != nullptr) AParcel_delete(in);
        if (out != nullptr) AParcel_delete(out);
        AIBinder_decStrong(binder);
        ALOGI("sec-ril-shim: FW_READY on slot%d: %d", slot, status);
    }
}

static RilInit getRealInit(const char* name) {
    static void* handle = dlopen(kRealPath, RTLD_NOW);
    if (handle == nullptr) {
        ALOGE("sec-ril-shim: dlopen %s failed: %s", kRealPath, dlerror());
        return nullptr;
    }
    auto init = reinterpret_cast<RilInit>(dlsym(handle, name));
    if (init == nullptr) ALOGE("sec-ril-shim: dlsym %s failed: %s", name, dlerror());
    return init;
}

extern "C" const RIL_RadioFunctions* RIL_Init(const RIL_Env* env, int argc, char** argv) {
    RilInit realInit = getRealInit("RIL_Init");
    if (realInit == nullptr || env == nullptr || env->OnRequestComplete == nullptr) {
        return nullptr;
    }
    gRealEnv = env;
    gShimEnv = *env;
    gShimEnv.OnRequestComplete = shimOnRequestComplete;

    const RIL_RadioFunctions* real = realInit(&gShimEnv, argc, argv);
    if (real == nullptr) return real;

    auto* prefix = reinterpret_cast<SamsungRilFunctionsPrefix*>(
            const_cast<RIL_RadioFunctions*>(real));
    if (prefix->onRequest != nullptr && prefix->onRequest != shimOnRequest) {
        gRealOnRequest = prefix->onRequest;
        prefix->onRequest = shimOnRequest;
    }
    if (gRealOnRequest == nullptr) {
        ALOGE("sec-ril-shim: real onRequest missing");
        return nullptr;
    }
    ALOGI("sec-ril-shim: installed SMSC shim");
    std::thread(sendFrameworkReady).detach();
    return real;
}

extern "C" const RIL_RadioFunctions* RIL_SAP_Init(const RIL_Env* env, int argc, char** argv) {
    RilInit realInit = getRealInit("RIL_SAP_Init");
    return realInit != nullptr ? realInit(env, argc, argv) : nullptr;
}
