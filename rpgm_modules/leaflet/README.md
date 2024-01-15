
## Usage

```r

```

## Methods

In the following functions, `mapId` always refers to the unique id of a single map in the GUI, as defined in the `Leaflet.createMap` function with the `mapId` parameter.

### Leaflet.createMap

```r
Leaflet.createMap(mapId, step, widgetId, layer = layerURL, height = 512, options = list(), layerOptions = list())
```

- mapId is a unique name you give to the map
- step is the step where the map will be, created with `rpgm.step()`
- widgetId is the id of the label widget that will contain the map
- layerURL is the tile layer URL (see [TileLayer documentation](https://leafletjs.com/reference.html#tilelayer)), and layerOptions are the [TileLayer Options](https://leafletjs.com/reference.html#tilelayer-option).
- options is the map options as defined by the [Leaflet map options](https://leafletjs.com/reference.html#map-option)

### Leaflet.setView

```r
Leaflet.setView(mapId, center, zoom)
```

Set the view of the map to a specific point and zoom.

- `center` is a LatLng point created with `Leaflet.latLng()`;
- `zoom` is the wanted zoom level.

### Leaflet.setZoom

```r
Leaflet.setZoom(mapId, zoom)
```

Set the zoom level of the map.

### Leaflet.fitBounds

```r
Leaflet.fitBounds(mapId, bounds)
```

Show a specific view on the map.

- `bounds` is a LatLngBounds created with `Leaflet.latLngBounds()`

### Leaflet.createIcon

```r
Leaflet.createIcon(iconId, options)
```

Create a new icon for future markers. Icon should be created before initializing the map.

- `iconId` is a unique id;
- `options` is a list of [Leaflet icon options](https://leafletjs.com/reference.html#icon).

### Leaflet.marker

```r
Leaflet.marker(iconId, latlng, popup, options = list())
```

Create a new marker to be used with `Leaflet.updateMarkers()`.

- `iconId` is the id of an icon created with `Leaflet.createIcon()`;
- `latlng` is the position of the marker created with `Leaflet.latLng()`;
- `popup` is the HTML content of the popup when the user click on the marker;
- `options` is a list of [Leaflet marker options](https://leafletjs.com/reference.html#marker-option).

### Leaflet.updateMarkers

```r
Leaflet.updateMarkers(mapId, markers)
```

Remove all existing markers on the map and draw all the markers in the `markers` parameter.

- `mapId` is the id of the map;
- `markers` should be a list of markers created with `Leaflet.marker()`.

### Leaflet.updateLegend

```r
Leaflet.updateLegend(mapId, content)
```

Update the content of the legend of the map with `content`.

### Leaflet.addGeoJSON

```r
Leaflet.addGeoJSON(mapId, data)
```

Queue a new GeoJSON shape for future rendering on the map. When all shapes are added, call `flushGeoJSON()` to draw all the shapes at once.

- `mapId` is the id of the map;
- `data` is a list of:
    - `id`: a unique id for the shape/zone;
    - `points`: a list of points;
    - `tooltip`: the HTML content of the tooltip when the user put its mouse over the shape;
    - `color`: an HTML hex color, like `#ff0000`.

### Leaflet.flushGeoJSON

```r
Leaflet.flushGeoJSON(mapId)
```

Remove all previous rendered geojson shapes and draw all the queued shapes with `addGeoJSON()`.

### Leaflet.showLoading

```r
Leaflet.showLoading(mapId)
```

Show the loading state of a map with a spinning animation over the map.

### Leaflet.hideLoading

```r
Leaflet.hideLoading(mapId)
```

Hide the loading state of a map.

### Leaflet.latlng

```r
Leaflet.latlng(lat, lng)
```

Create a new LatLng object to use where [Leaflet LatLng object](https://leafletjs.com/reference.html#latlng) are used.

### Leaflet.latLngBounds

```r
Leaflet.latLngBounds(corner1, corner2)
```

Create a new LatLng object to use where [Leaflet LatLngBounds object](https://leafletjs.com/reference.html#latlngbounds) are used.

## Events

onDidLoad
onDidClickMap # lat, lng
onDidClickZone zoneId, northLat, eastLng, southLat, westLng, zoomLevel
onDidChangeView northLat, eastLng, southLat, westLng, zoomLevel