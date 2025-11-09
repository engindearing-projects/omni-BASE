package com.engindearing.omnitak.maplibre

import android.content.Context
import com.snap.valdi.attributes.AttributesBinder
import com.snap.valdi.attributes.AttributesBindingContext
import com.snap.valdi.attributes.RegisterAttributesBinder
import com.snap.valdi.attributes.impl.animations.ValdiAnimator

/**
 * Attributes binder for MapLibreMapView
 *
 * This class binds TypeScript attributes to the MapLibreMapView,
 * allowing Valdi to configure the map view declaratively from TSX.
 *
 * @RegisterAttributesBinder annotation ensures Valdi runtime can find this binder
 */
@RegisterAttributesBinder
class MapLibreMapViewAttributesBinder(private val context: Context) : AttributesBinder<MapLibreMapView> {

    override val viewClass: Class<MapLibreMapView>
        get() = MapLibreMapView::class.java

    override fun bindAttributes(attributesBindingContext: AttributesBindingContext<MapLibreMapView>) {
        // Bind styleUrl attribute
        attributesBindingContext.bindStringAttribute(
            "styleUrl",
            invalidateLayoutOnChange = false,
            applyBlock = this::applyStyleUrl,
            resetBlock = this::resetStyleUrl
        )

        // Bind options attribute (JSON object)
        attributesBindingContext.bindStringAttribute(
            "options",
            invalidateLayoutOnChange = false,
            applyBlock = this::applyOptions,
            resetBlock = this::resetOptions
        )

        // Bind markers attribute (JSON array)
        attributesBindingContext.bindStringAttribute(
            "markers",
            invalidateLayoutOnChange = false,
            applyBlock = this::applyMarkers,
            resetBlock = this::resetMarkers
        )

        // Bind onCameraChange callback
        attributesBindingContext.bindStringAttribute(
            "onCameraChange",
            invalidateLayoutOnChange = false,
            applyBlock = this::applyOnCameraChange,
            resetBlock = this::resetOnCameraChange
        )

        // Bind onMapClick callback
        attributesBindingContext.bindStringAttribute(
            "onMapClick",
            invalidateLayoutOnChange = false,
            applyBlock = this::applyOnMapClick,
            resetBlock = this::resetOnMapClick
        )

        // Bind onMarkerTap callback
        attributesBindingContext.bindStringAttribute(
            "onMarkerTap",
            invalidateLayoutOnChange = false,
            applyBlock = this::applyOnMarkerTap,
            resetBlock = this::resetOnMarkerTap
        )
    }

    //region Attribute Apply Methods

    private fun applyStyleUrl(view: MapLibreMapView, value: String, animator: ValdiAnimator?) {
        view.setStyleUrl(value)
    }

    private fun resetStyleUrl(view: MapLibreMapView, animator: ValdiAnimator?) {
        // Reset to default style
        view.setStyleUrl("https://demotiles.maplibre.org/style.json")
    }

    private fun applyOptions(view: MapLibreMapView, value: String, animator: ValdiAnimator?) {
        view.setMapOptions(value)
    }

    private fun resetOptions(view: MapLibreMapView, animator: ValdiAnimator?) {
        // Reset to default options
        view.setMapOptions("{}")
    }

    private fun applyMarkers(view: MapLibreMapView, value: String, animator: ValdiAnimator?) {
        view.setMarkers(value)
    }

    private fun resetMarkers(view: MapLibreMapView, animator: ValdiAnimator?) {
        // Clear all markers
        view.setMarkers("[]")
    }

    private fun applyOnCameraChange(view: MapLibreMapView, value: String, animator: ValdiAnimator?) {
        view.setOnCameraChange(value)
    }

    private fun resetOnCameraChange(view: MapLibreMapView, animator: ValdiAnimator?) {
        // No-op: callback removed
    }

    private fun applyOnMapClick(view: MapLibreMapView, value: String, animator: ValdiAnimator?) {
        view.setOnMapClick(value)
    }

    private fun resetOnMapClick(view: MapLibreMapView, animator: ValdiAnimator?) {
        // No-op: callback removed
    }

    private fun applyOnMarkerTap(view: MapLibreMapView, value: String, animator: ValdiAnimator?) {
        view.setOnMarkerTap(value)
    }

    private fun resetOnMarkerTap(view: MapLibreMapView, animator: ValdiAnimator?) {
        // No-op: callback removed
    }

    //endregion
}
