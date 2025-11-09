package com.engindearing.omnitak.maplibre

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.Keep
import com.mapbox.mapboxsdk.camera.CameraPosition
import com.mapbox.mapboxsdk.camera.CameraUpdateFactory
import com.mapbox.mapboxsdk.geometry.LatLng
import com.mapbox.mapboxsdk.maps.MapView
import com.mapbox.mapboxsdk.maps.MapboxMap
import com.mapbox.mapboxsdk.maps.OnMapReadyCallback
import com.mapbox.mapboxsdk.maps.Style
import com.mapbox.mapboxsdk.plugins.annotation.SymbolManager
import com.mapbox.mapboxsdk.plugins.annotation.SymbolOptions
import com.snap.valdi.views.ValdiView
import org.json.JSONArray
import org.json.JSONObject

/**
 * MapLibre GL Native integration for OmniTAK Mobile
 *
 * This view wraps MapLibre's MapView for use within Valdi framework.
 * It provides TAK-specific functionality including CoT marker display,
 * camera controls, and map interaction callbacks.
 *
 * @Keep annotation prevents ProGuard from stripping this class in release builds
 */
@Keep
class MapLibreMapView(context: Context) : ValdiView(context), OnMapReadyCallback {

    companion object {
        private const val TAG = "MapLibreMapView"
        private const val DEFAULT_ZOOM = 10.0
        private const val DEFAULT_LAT = 38.8977
        private const val DEFAULT_LON = -77.0365
        private const val DEFAULT_STYLE_URL = "https://demotiles.maplibre.org/style.json"
    }

    // MapLibre components
    private val mapView: MapView = MapView(context)
    private var mapboxMap: MapboxMap? = null
    private var symbolManager: SymbolManager? = null
    private var isMapReady = false

    // Main thread handler for safe UI updates
    private val mainHandler = Handler(Looper.getMainLooper())

    // Map options
    private var styleUrl: String = DEFAULT_STYLE_URL
    private var initialCenter: LatLng = LatLng(DEFAULT_LAT, DEFAULT_LON)
    private var initialZoom: Double = DEFAULT_ZOOM
    private var initialBearing: Double = 0.0
    private var initialTilt: Double = 0.0

    // Markers data (stored as JSON string)
    private var markersJson: String? = null

    // Callbacks (stored as JSON strings with function references)
    private var onCameraChangeCallback: String? = null
    private var onMapClickCallback: String? = null
    private var onMarkerTapCallback: String? = null

    init {
        // Add MapView as child
        addView(mapView)

        // Initialize map asynchronously
        mapView.getMapAsync(this)

        Log.d(TAG, "MapLibreMapView initialized")
    }

    //region Property Setters (called from AttributesBinder)

    /**
     * Set map style URL
     * @param url MapLibre style JSON URL
     */
    fun setStyleUrl(url: String) {
        if (styleUrl == url) return
        styleUrl = url

        if (isMapReady) {
            mapboxMap?.setStyle(Style.Builder().fromUri(styleUrl))
        }
        Log.d(TAG, "Style URL set to: $url")
    }

    /**
     * Set initial map center
     * @param options JSON object with lat, lon, zoom, bearing, tilt
     */
    fun setMapOptions(options: String) {
        try {
            val json = JSONObject(options)

            if (json.has("center")) {
                val center = json.getJSONObject("center")
                val lat = center.getDouble("lat")
                val lon = center.getDouble("lon")
                initialCenter = LatLng(lat, lon)
            }

            if (json.has("zoom")) {
                initialZoom = json.getDouble("zoom")
            }

            if (json.has("bearing")) {
                initialBearing = json.getDouble("bearing")
            }

            if (json.has("tilt")) {
                initialTilt = json.getDouble("tilt")
            }

            // Apply camera position if map is ready
            if (isMapReady) {
                applyCameraPosition()
            }

            Log.d(TAG, "Map options updated: center=$initialCenter, zoom=$initialZoom")
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing map options: ${e.message}", e)
        }
    }

    /**
     * Set markers on the map
     * @param markersJsonStr JSON array of marker objects
     */
    fun setMarkers(markersJsonStr: String) {
        markersJson = markersJsonStr

        if (isMapReady) {
            updateMarkers()
        }
    }

    /**
     * Set camera change callback
     * @param callbackId Callback identifier for Valdi bridge
     */
    fun setOnCameraChange(callbackId: String) {
        onCameraChangeCallback = callbackId
        Log.d(TAG, "Camera change callback registered")
    }

    /**
     * Set map click callback
     * @param callbackId Callback identifier for Valdi bridge
     */
    fun setOnMapClick(callbackId: String) {
        onMapClickCallback = callbackId
        Log.d(TAG, "Map click callback registered")
    }

    /**
     * Set marker tap callback
     * @param callbackId Callback identifier for Valdi bridge
     */
    fun setOnMarkerTap(callbackId: String) {
        onMarkerTapCallback = callbackId
        Log.d(TAG, "Marker tap callback registered")
    }

    //endregion

    //region MapboxMap.OnMapReadyCallback

    override fun onMapReady(map: MapboxMap) {
        Log.d(TAG, "Map ready!")
        mapboxMap = map
        isMapReady = true

        // Load style
        map.setStyle(Style.Builder().fromUri(styleUrl)) { style ->
            Log.d(TAG, "Style loaded: $styleUrl")

            // Initialize symbol manager for markers
            symbolManager = SymbolManager(mapView, map, style)

            // Apply initial camera position
            applyCameraPosition()

            // Apply markers if any
            if (markersJson != null) {
                updateMarkers()
            }

            // Setup event listeners
            setupEventListeners(map)
        }
    }

    //endregion

    //region Private Methods

    /**
     * Apply camera position to map
     */
    private fun applyCameraPosition() {
        val cameraPosition = CameraPosition.Builder()
            .target(initialCenter)
            .zoom(initialZoom)
            .bearing(initialBearing)
            .tilt(initialTilt)
            .build()

        mapboxMap?.let { map ->
            runOnUiThread {
                map.animateCamera(CameraUpdateFactory.newCameraPosition(cameraPosition), 500)
            }
        }
    }

    /**
     * Update markers on the map
     */
    private fun updateMarkers() {
        val manager = symbolManager ?: return
        val json = markersJson ?: return

        try {
            runOnUiThread {
                // Clear existing markers
                manager.deleteAll()

                // Parse and add new markers
                val markersArray = JSONArray(json)
                for (i in 0 until markersArray.length()) {
                    val marker = markersArray.getJSONObject(i)

                    val id = marker.optString("id", "marker_$i")
                    val lat = marker.getDouble("lat")
                    val lon = marker.getDouble("lon")
                    val title = marker.optString("title", "")
                    val iconName = marker.optString("icon", "marker-default")
                    val iconColor = marker.optString("color", "#FF0000")

                    // Create symbol
                    val symbolOptions = SymbolOptions()
                        .withLatLng(LatLng(lat, lon))
                        .withIconImage(iconName)
                        .withIconSize(1.0f)
                        .withTextField(title)
                        .withTextSize(12.0f)
                        .withTextOffset(arrayOf(0.0f, 1.5f))

                    manager.create(symbolOptions)
                }

                Log.d(TAG, "Updated ${markersArray.length()} markers")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating markers: ${e.message}", e)
        }
    }

    /**
     * Setup event listeners for map interactions
     */
    private fun setupEventListeners(map: MapboxMap) {
        // Camera change listener
        if (onCameraChangeCallback != null) {
            map.addOnCameraMoveListener {
                val position = map.cameraPosition
                val data = JSONObject().apply {
                    put("center", JSONObject().apply {
                        put("lat", position.target.latitude)
                        put("lon", position.target.longitude)
                    })
                    put("zoom", position.zoom)
                    put("bearing", position.bearing)
                    put("tilt", position.tilt)
                }

                // TODO: Invoke Valdi callback with data
                Log.d(TAG, "Camera changed: $data")
            }
        }

        // Map click listener
        if (onMapClickCallback != null) {
            map.addOnMapClickListener { point ->
                val data = JSONObject().apply {
                    put("lat", point.latitude)
                    put("lon", point.longitude)
                }

                // TODO: Invoke Valdi callback with data
                Log.d(TAG, "Map clicked: $data")
                true
            }
        }

        // Marker tap listener
        if (onMarkerTapCallback != null) {
            symbolManager?.addClickListener { symbol ->
                val data = JSONObject().apply {
                    put("lat", symbol.latLng.latitude)
                    put("lon", symbol.latLng.longitude)
                    put("id", symbol.id)
                }

                // TODO: Invoke Valdi callback with data
                Log.d(TAG, "Marker tapped: $data")
            }
        }
    }

    /**
     * Run code on UI thread
     */
    private fun runOnUiThread(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action()
        } else {
            mainHandler.post(action)
        }
    }

    //endregion

    //region Lifecycle Methods

    /**
     * Called when view is attached to window
     */
    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        mapView.onStart()
        Log.d(TAG, "onAttachedToWindow")
    }

    /**
     * Called when view is detached from window
     */
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        mapView.onStop()
        Log.d(TAG, "onDetachedFromWindow")
    }

    /**
     * Activity/Fragment lifecycle: onStart
     */
    fun onStart() {
        mapView.onStart()
        Log.d(TAG, "onStart")
    }

    /**
     * Activity/Fragment lifecycle: onResume
     */
    fun onResume() {
        mapView.onResume()
        Log.d(TAG, "onResume")
    }

    /**
     * Activity/Fragment lifecycle: onPause
     */
    fun onPause() {
        mapView.onPause()
        Log.d(TAG, "onPause")
    }

    /**
     * Activity/Fragment lifecycle: onStop
     */
    fun onStop() {
        mapView.onStop()
        Log.d(TAG, "onStop")
    }

    /**
     * Activity/Fragment lifecycle: onDestroy
     */
    fun onDestroy() {
        mapView.onDestroy()
        symbolManager?.onDestroy()
        symbolManager = null
        mapboxMap = null
        isMapReady = false
        Log.d(TAG, "onDestroy")
    }

    /**
     * Activity/Fragment lifecycle: onSaveInstanceState
     */
    fun onSaveInstanceState(outState: android.os.Bundle) {
        mapView.onSaveInstanceState(outState)
    }

    /**
     * Activity/Fragment lifecycle: onLowMemory
     */
    fun onLowMemory() {
        mapView.onLowMemory()
        Log.d(TAG, "onLowMemory")
    }

    //endregion

    //region Layout

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)

        // Ensure MapView fills parent
        mapView.measure(widthMeasureSpec, heightMeasureSpec)
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)

        // Layout MapView to fill entire view
        mapView.layout(0, 0, right - left, bottom - top)
    }

    //endregion
}
