# Queue a new GeoJSON shape for future rendering on the map. When all GeoJSON shapes are added, call `flushGeoJSON()` to draw all the GeoJSON shapes at once.
Leaflet.addGeoJSON <- function(mapId, data){
    rpgm.sendToJavascript('leaflet/geojson/add', list(mapId=mapId, zoneId=data$id, points=data$points, tooltip=data$tooltip, color=data$color))
}

# Remove all previous rendered geojson shapes and draw all the queued shapes with `addGeoJSON()`.
Leaflet.flushGeoJSON <- function(mapId){
    rpgm.sendToJavascript('leaflet/geojson/flush', list(mapId=mapId))
}