package com.engindearing.omnitak.native

import android.util.Log
import kotlinx.coroutines.*
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.resume

/**
 * OmniTAKNativeBridge - Android/Kotlin Bridge to omnitak-mobile Rust Library
 *
 * This class provides the Kotlin interface to the native Rust library via JNI.
 * It handles:
 * - JNI native method declarations
 * - Callback management from C -> Kotlin -> TypeScript
 * - Thread safety for callbacks
 * - Certificate storage
 * - Async/coroutine integration
 */
class OmniTAKNativeBridge {

    companion object {
        private const val TAG = "OmniTAKNative"

        // Singleton instance for callback management
        @Volatile
        private var instance: OmniTAKNativeBridge? = null

        fun getInstance(): OmniTAKNativeBridge {
            return instance ?: synchronized(this) {
                instance ?: OmniTAKNativeBridge().also { instance = it }
            }
        }

        // Load native library
        init {
            try {
                System.loadLibrary("omnitak_mobile")
                Log.i(TAG, "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library", e)
                throw e
            }
        }
    }

    // MARK: - Native Method Declarations

    // Initialize the native library
    private external fun nativeInit(): Int

    // Shutdown the native library
    private external fun nativeShutdown()

    // Connect to TAK server
    private external fun nativeConnect(
        host: String,
        port: Int,
        protocol: Int,
        useTls: Boolean,
        certPem: String?,
        keyPem: String?,
        caPem: String?
    ): Long

    // Disconnect from server
    private external fun nativeDisconnect(connectionId: Long): Int

    // Send CoT message
    private external fun nativeSendCot(connectionId: Long, cotXml: String): Int

    // Register callback for receiving CoT messages
    private external fun nativeRegisterCallback(connectionId: Long): Int

    // Unregister callback
    private external fun nativeUnregisterCallback(connectionId: Long): Int

    // Get connection status
    private external fun nativeGetStatus(connectionId: Long): ConnectionStatusNative?

    // Get library version
    private external fun nativeVersion(): String

    // MARK: - Data Classes

    data class ServerConfig(
        val host: String,
        val port: Int,
        val protocol: String,
        val useTls: Boolean,
        val certificateId: String? = null,
        val reconnect: Boolean = false,
        val reconnectDelayMs: Int = 5000
    )

    data class ConnectionInfo(
        val id: Long,
        val status: String,
        val host: String,
        val port: Int,
        val protocol: String,
        val latencyMs: Int,
        val messagesReceived: Long,
        val messagesSent: Long,
        val lastError: String? = null
    )

    // Native status structure (matches C struct)
    private data class ConnectionStatusNative(
        val isConnected: Int,
        val messagesSent: Long,
        val messagesReceived: Long,
        val lastErrorCode: Int
    )

    private data class CertificateBundle(
        val certPem: String,
        val keyPem: String,
        val caPem: String?
    )

    // MARK: - Protocol Constants

    private object Protocol {
        const val TCP = 0
        const val UDP = 1
        const val TLS = 2
        const val WEBSOCKET = 3

        fun fromString(protocol: String): Int {
            return when (protocol.lowercase()) {
                "tcp" -> TCP
                "udp" -> UDP
                "tls" -> TLS
                "websocket" -> WEBSOCKET
                else -> throw IllegalArgumentException("Unknown protocol: $protocol")
            }
        }

        fun toString(protocol: Int): String {
            return when (protocol) {
                TCP -> "tcp"
                UDP -> "udp"
                TLS -> "tls"
                WEBSOCKET -> "websocket"
                else -> "unknown"
            }
        }
    }

    // MARK: - Instance State

    // Certificate storage
    private val certificates = ConcurrentHashMap<String, CertificateBundle>()

    // Callback storage: connection_id -> callback
    private val callbacks = ConcurrentHashMap<Long, (String) -> Unit>()

    // Connection metadata
    private val connections = ConcurrentHashMap<Long, ServerConfig>()

    // Initialization state
    @Volatile
    private var isInitialized = false
    private val initLock = Any()

    // Coroutine scope for async operations
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    init {
        ensureInitialized()
    }

    // MARK: - Initialization

    private fun ensureInitialized() {
        if (isInitialized) return

        synchronized(initLock) {
            if (!isInitialized) {
                val result = nativeInit()
                if (result == 0) {
                    isInitialized = true
                    Log.i(TAG, "Native library initialized successfully")
                } else {
                    Log.e(TAG, "Failed to initialize native library: $result")
                    throw RuntimeException("Failed to initialize OmniTAK native library")
                }
            }
        }
    }

    // MARK: - Public API

    fun getVersion(): String {
        return nativeVersion()
    }

    suspend fun connect(config: ServerConfig): Long? = withContext(Dispatchers.IO) {
        ensureInitialized()

        try {
            val protocolId = Protocol.fromString(config.protocol)

            // Get certificate bundle if specified
            val certBundle = config.certificateId?.let { certificates[it] }

            val connectionId = nativeConnect(
                host = config.host,
                port = config.port,
                protocol = protocolId,
                useTls = config.useTls,
                certPem = certBundle?.certPem,
                keyPem = certBundle?.keyPem,
                caPem = certBundle?.caPem
            )

            if (connectionId > 0) {
                connections[connectionId] = config
                Log.i(TAG, "Connected successfully: $connectionId")
                connectionId
            } else {
                Log.e(TAG, "Connection failed")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Connect exception", e)
            null
        }
    }

    suspend fun disconnect(connectionId: Long): Unit = withContext(Dispatchers.IO) {
        try {
            val result = nativeDisconnect(connectionId)

            // Clean up
            connections.remove(connectionId)
            callbacks.remove(connectionId)

            if (result == 0) {
                Log.i(TAG, "Disconnected: $connectionId")
            } else {
                Log.w(TAG, "Disconnect returned error: $result")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Disconnect exception", e)
        }
    }

    suspend fun sendCot(connectionId: Long, cotXml: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val result = nativeSendCot(connectionId, cotXml)
            val success = (result == 0)

            if (success) {
                Log.d(TAG, "CoT sent on connection $connectionId")
            } else {
                Log.e(TAG, "Failed to send CoT on connection $connectionId: $result")
            }

            success
        } catch (e: Exception) {
            Log.e(TAG, "SendCot exception", e)
            false
        }
    }

    fun registerCotCallback(connectionId: Long, callback: (String) -> Unit) {
        callbacks[connectionId] = callback

        // Register with native layer
        val result = nativeRegisterCallback(connectionId)

        if (result == 0) {
            Log.i(TAG, "Callback registered for connection $connectionId")
        } else {
            Log.e(TAG, "Failed to register callback for connection $connectionId: $result")
        }
    }

    suspend fun getConnectionStatus(connectionId: Long): ConnectionInfo? = withContext(Dispatchers.IO) {
        try {
            val nativeStatus = nativeGetStatus(connectionId)
            val config = connections[connectionId]

            if (nativeStatus != null && config != null) {
                ConnectionInfo(
                    id = connectionId,
                    status = if (nativeStatus.isConnected != 0) "connected" else "disconnected",
                    host = config.host,
                    port = config.port,
                    protocol = config.protocol,
                    latencyMs = 0, // Not provided by native layer yet
                    messagesReceived = nativeStatus.messagesReceived,
                    messagesSent = nativeStatus.messagesSent,
                    lastError = if (nativeStatus.lastErrorCode != 0) {
                        "Error code: ${nativeStatus.lastErrorCode}"
                    } else null
                )
            } else {
                Log.w(TAG, "Failed to get status for connection $connectionId")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "GetStatus exception", e)
            null
        }
    }

    suspend fun importCertificate(
        certPem: String,
        keyPem: String,
        caPem: String? = null
    ): String = withContext(Dispatchers.IO) {
        // Generate unique ID
        val certId = UUID.randomUUID().toString()

        val bundle = CertificateBundle(
            certPem = certPem,
            keyPem = keyPem,
            caPem = caPem
        )

        certificates[certId] = bundle

        Log.i(TAG, "Certificate imported: $certId")
        certId
    }

    // MARK: - Callback from JNI

    /**
     * Called from JNI when a CoT message is received
     * This method is called on a native thread, so we dispatch to Kotlin coroutines
     */
    @Suppress("unused")
    private fun onCotReceived(connectionId: Long, cotXml: String) {
        Log.d(TAG, "CoT received on connection $connectionId")

        // Get callback and invoke on main dispatcher
        val callback = callbacks[connectionId]
        if (callback != null) {
            scope.launch(Dispatchers.Main) {
                try {
                    callback(cotXml)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in CoT callback", e)
                }
            }
        } else {
            Log.w(TAG, "No callback registered for connection $connectionId")
        }
    }

    // MARK: - Cleanup

    fun shutdown() {
        scope.cancel()
        nativeShutdown()
        isInitialized = false
        callbacks.clear()
        connections.clear()
        certificates.clear()
        Log.i(TAG, "Shutdown complete")
    }
}

// MARK: - Valdi Integration Extensions

/**
 * Extension functions for Valdi polyglot integration
 */
object OmniTAKNativeModule {

    private val bridge = OmniTAKNativeBridge.getInstance()

    suspend fun connect(config: Map<String, Any?>): Long? {
        val serverConfig = parseServerConfig(config) ?: return null
        return bridge.connect(serverConfig)
    }

    suspend fun disconnect(connectionId: Long) {
        bridge.disconnect(connectionId)
    }

    suspend fun sendCot(connectionId: Long, cotXml: String): Boolean {
        return bridge.sendCot(connectionId, cotXml)
    }

    fun registerCotCallback(connectionId: Long, callback: (String) -> Unit) {
        bridge.registerCotCallback(connectionId, callback)
    }

    suspend fun getConnectionStatus(connectionId: Long): Map<String, Any?>? {
        val info = bridge.getConnectionStatus(connectionId) ?: return null

        return mapOf(
            "id" to info.id,
            "status" to info.status,
            "host" to info.host,
            "port" to info.port,
            "protocol" to info.protocol,
            "latencyMs" to info.latencyMs,
            "messagesReceived" to info.messagesReceived,
            "messagesSent" to info.messagesSent,
            "lastError" to info.lastError
        )
    }

    suspend fun importCertificate(
        certPem: String,
        keyPem: String,
        caPem: String? = null
    ): String {
        return bridge.importCertificate(certPem, keyPem, caPem)
    }

    private fun parseServerConfig(config: Map<String, Any?>): OmniTAKNativeBridge.ServerConfig? {
        try {
            val host = config["host"] as? String ?: return null
            val port = (config["port"] as? Number)?.toInt() ?: return null
            val protocol = config["protocol"] as? String ?: return null
            val useTls = config["useTls"] as? Boolean ?: false
            val certificateId = config["certificateId"] as? String
            val reconnect = config["reconnect"] as? Boolean ?: false
            val reconnectDelayMs = (config["reconnectDelayMs"] as? Number)?.toInt() ?: 5000

            return OmniTAKNativeBridge.ServerConfig(
                host = host,
                port = port,
                protocol = protocol,
                useTls = useTls,
                certificateId = certificateId,
                reconnect = reconnect,
                reconnectDelayMs = reconnectDelayMs
            )
        } catch (e: Exception) {
            Log.e("OmniTAKNative", "Failed to parse ServerConfig", e)
            return null
        }
    }
}
