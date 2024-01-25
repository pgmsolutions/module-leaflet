# Set the view of the map to a specific point and zoom.
Leaflet.setView <- function(mapId, center, zoom){
    rpgm.sendToJavascript('leaflet/map/view', list(mapId=mapId, center=center, zoom=zoom))
}

# Set the zoom level of the map.
Leaflet.setZoom <- function(mapId, zoom){
    rpgm.sendToJavascript('leaflet/map/zoom', list(mapId=mapId, zoom=zoom))
}

# Show a specific view on the map.
Leaflet.fitBounds <- function(mapId, bounds){
    rpgm.sendToJavascript('leaflet/map/fit', list(mapId=mapId, bounds=bounds))
}

# Force the map to send an `onDidChangeView` event. Useful to refresh the map view after loading data for example.
Leaflet.triggerViewEvent <- function(mapId){
    rpgm.sendToJavascript('leaflet/triggerView', list(mapId=mapId))
}