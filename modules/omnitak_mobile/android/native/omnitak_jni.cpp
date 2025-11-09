/**
 * omnitak_jni.cpp - JNI Bridge for OmniTAK Mobile
 *
 * This file provides JNI bindings between Kotlin/Java and the Rust FFI.
 * It handles:
 * - String conversions between JNI and C
 * - Callback bridging from C -> JNI -> Kotlin
 * - Thread safety and JNI reference management
 * - Error handling and logging
 */

#include <jni.h>
#include <string>
#include <map>
#include <mutex>
#include <android/log.h>

// Import the C FFI header from Rust
extern "C" {
    #include "omnitak_mobile.h"
}

// Logging macros
#define LOG_TAG "OmniTAK-JNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// Global state for callback management
struct CallbackContext {
    JavaVM* jvm;
    jobject bridge_instance; // Global reference to OmniTAKNativeBridge instance
};

static std::map<uint64_t, CallbackContext> g_callbacks;
static std::mutex g_callbacks_mutex;
static JavaVM* g_jvm = nullptr;

// Helper: Convert JNI string to C++ string
static std::string jstring_to_string(JNIEnv* env, jstring jstr) {
    if (!jstr) return "";

    const char* chars = env->GetStringUTFChars(jstr, nullptr);
    std::string result(chars);
    env->ReleaseStringUTFChars(jstr, chars);
    return result;
}

// Helper: Convert C++ string to JNI string
static jstring string_to_jstring(JNIEnv* env, const char* str) {
    if (!str) return nullptr;
    return env->NewStringUTF(str);
}

// C callback function that bridges to Java/Kotlin
static void cot_callback_bridge(void* user_data, uint64_t connection_id, const char* cot_xml) {
    LOGD("CoT callback triggered for connection %llu", (unsigned long long)connection_id);

    // Get callback context
    CallbackContext context;
    {
        std::lock_guard<std::mutex> lock(g_callbacks_mutex);
        auto it = g_callbacks.find(connection_id);
        if (it == g_callbacks.end()) {
            LOGE("No callback context found for connection %llu", (unsigned long long)connection_id);
            return;
        }
        context = it->second;
    }

    // Attach to JVM (this might be called from a native thread)
    JNIEnv* env = nullptr;
    int getEnvStat = context.jvm->GetEnv((void**)&env, JNI_VERSION_1_6);
    bool needDetach = false;

    if (getEnvStat == JNI_EDETACHED) {
        LOGD("Attaching to JVM for callback");
        if (context.jvm->AttachCurrentThread(&env, nullptr) != 0) {
            LOGE("Failed to attach to JVM");
            return;
        }
        needDetach = true;
    } else if (getEnvStat != JNI_OK) {
        LOGE("Failed to get JNI environment");
        return;
    }

    // Get the OmniTAKNativeBridge class and onCotReceived method
    jclass bridgeClass = env->GetObjectClass(context.bridge_instance);
    jmethodID onCotReceivedMethod = env->GetMethodID(
        bridgeClass,
        "onCotReceived",
        "(JLjava/lang/String;)V"
    );

    if (!onCotReceivedMethod) {
        LOGE("Failed to find onCotReceived method");
        env->DeleteLocalRef(bridgeClass);
        if (needDetach) {
            context.jvm->DetachCurrentThread();
        }
        return;
    }

    // Convert C string to JNI string
    jstring jCotXml = string_to_jstring(env, cot_xml);

    // Call the Kotlin callback method
    env->CallVoidMethod(
        context.bridge_instance,
        onCotReceivedMethod,
        (jlong)connection_id,
        jCotXml
    );

    // Check for exceptions
    if (env->ExceptionCheck()) {
        LOGE("Exception occurred in onCotReceived");
        env->ExceptionDescribe();
        env->ExceptionClear();
    }

    // Cleanup
    env->DeleteLocalRef(jCotXml);
    env->DeleteLocalRef(bridgeClass);

    if (needDetach) {
        context.jvm->DetachCurrentThread();
    }
}

// JNI_OnLoad - Called when library is loaded
JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("JNI_OnLoad called");
    g_jvm = vm;
    return JNI_VERSION_1_6;
}

// Native method implementations

extern "C" JNIEXPORT jint JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeInit(
    JNIEnv* env,
    jobject thiz
) {
    LOGI("nativeInit called");
    int32_t result = omnitak_init();
    LOGI("omnitak_init returned %d", result);
    return (jint)result;
}

extern "C" JNIEXPORT void JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeShutdown(
    JNIEnv* env,
    jobject thiz
) {
    LOGI("nativeShutdown called");

    // Clean up all callbacks
    {
        std::lock_guard<std::mutex> lock(g_callbacks_mutex);
        for (auto& pair : g_callbacks) {
            env->DeleteGlobalRef(pair.second.bridge_instance);
        }
        g_callbacks.clear();
    }

    omnitak_shutdown();
    LOGI("Shutdown complete");
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeConnect(
    JNIEnv* env,
    jobject thiz,
    jstring host,
    jint port,
    jint protocol,
    jboolean useTls,
    jstring certPem,
    jstring keyPem,
    jstring caPem
) {
    LOGI("nativeConnect called");

    // Convert strings
    std::string hostStr = jstring_to_string(env, host);
    const char* certPemStr = certPem ? jstring_to_string(env, certPem).c_str() : nullptr;
    const char* keyPemStr = keyPem ? jstring_to_string(env, keyPem).c_str() : nullptr;
    const char* caPemStr = caPem ? jstring_to_string(env, caPem).c_str() : nullptr;

    LOGI("Connecting to %s:%d (protocol=%d, tls=%d)",
         hostStr.c_str(), (int)port, (int)protocol, (int)useTls);

    uint64_t connection_id = omnitak_connect(
        hostStr.c_str(),
        (uint16_t)port,
        (int32_t)protocol,
        useTls ? 1 : 0,
        certPemStr,
        keyPemStr,
        caPemStr
    );

    if (connection_id > 0) {
        LOGI("Connected successfully: %llu", (unsigned long long)connection_id);
    } else {
        LOGE("Connection failed");
    }

    return (jlong)connection_id;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeDisconnect(
    JNIEnv* env,
    jobject thiz,
    jlong connectionId
) {
    LOGI("nativeDisconnect called for connection %lld", (long long)connectionId);

    int32_t result = omnitak_disconnect((uint64_t)connectionId);

    // Clean up callback
    {
        std::lock_guard<std::mutex> lock(g_callbacks_mutex);
        auto it = g_callbacks.find((uint64_t)connectionId);
        if (it != g_callbacks.end()) {
            env->DeleteGlobalRef(it->second.bridge_instance);
            g_callbacks.erase(it);
            LOGI("Callback cleaned up for connection %lld", (long long)connectionId);
        }
    }

    return (jint)result;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeSendCot(
    JNIEnv* env,
    jobject thiz,
    jlong connectionId,
    jstring cotXml
) {
    std::string cotXmlStr = jstring_to_string(env, cotXml);

    LOGD("Sending CoT on connection %lld", (long long)connectionId);

    int32_t result = omnitak_send_cot((uint64_t)connectionId, cotXmlStr.c_str());

    if (result != 0) {
        LOGE("Failed to send CoT: %d", result);
    }

    return (jint)result;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeRegisterCallback(
    JNIEnv* env,
    jobject thiz,
    jlong connectionId
) {
    LOGI("nativeRegisterCallback called for connection %lld", (long long)connectionId);

    // Store callback context
    {
        std::lock_guard<std::mutex> lock(g_callbacks_mutex);

        // Create global reference to bridge instance
        jobject globalRef = env->NewGlobalRef(thiz);

        CallbackContext context;
        context.jvm = g_jvm;
        context.bridge_instance = globalRef;

        g_callbacks[(uint64_t)connectionId] = context;
    }

    // Register with C layer
    int32_t result = omnitak_register_callback(
        (uint64_t)connectionId,
        cot_callback_bridge,
        nullptr // user_data not needed, we use global map
    );

    if (result == 0) {
        LOGI("Callback registered successfully");
    } else {
        LOGE("Failed to register callback: %d", result);
    }

    return (jint)result;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeUnregisterCallback(
    JNIEnv* env,
    jobject thiz,
    jlong connectionId
) {
    LOGI("nativeUnregisterCallback called for connection %lld", (long long)connectionId);

    // Unregister from C layer
    int32_t result = omnitak_unregister_callback((uint64_t)connectionId);

    // Clean up callback context
    {
        std::lock_guard<std::mutex> lock(g_callbacks_mutex);
        auto it = g_callbacks.find((uint64_t)connectionId);
        if (it != g_callbacks.end()) {
            env->DeleteGlobalRef(it->second.bridge_instance);
            g_callbacks.erase(it);
        }
    }

    return (jint)result;
}

extern "C" JNIEXPORT jobject JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeGetStatus(
    JNIEnv* env,
    jobject thiz,
    jlong connectionId
) {
    LOGD("nativeGetStatus called for connection %lld", (long long)connectionId);

    ConnectionStatus status;
    int32_t result = omnitak_get_status((uint64_t)connectionId, &status);

    if (result != 0) {
        LOGE("Failed to get status: %d", result);
        return nullptr;
    }

    // Create ConnectionStatusNative object
    jclass statusClass = env->FindClass(
        "com/engindearing/omnitak/native/OmniTAKNativeBridge$ConnectionStatusNative"
    );

    if (!statusClass) {
        LOGE("Failed to find ConnectionStatusNative class");
        return nullptr;
    }

    jmethodID constructor = env->GetMethodID(statusClass, "<init>", "(IJJI)V");
    if (!constructor) {
        LOGE("Failed to find ConnectionStatusNative constructor");
        env->DeleteLocalRef(statusClass);
        return nullptr;
    }

    jobject statusObject = env->NewObject(
        statusClass,
        constructor,
        (jint)status.is_connected,
        (jlong)status.messages_sent,
        (jlong)status.messages_received,
        (jint)status.last_error_code
    );

    env->DeleteLocalRef(statusClass);

    return statusObject;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeVersion(
    JNIEnv* env,
    jobject thiz
) {
    const char* version = omnitak_version();
    LOGI("Library version: %s", version);
    return string_to_jstring(env, version);
}
