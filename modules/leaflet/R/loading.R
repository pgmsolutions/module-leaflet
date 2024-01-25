# Show the loading state of a map with a spinning animation over the map.
Leaflet.showLoading <- function(mapId){
    rpgm.sendToJavascript('leaflet/loading/show', list(mapId=mapId))
}

# Hide the loading state of a map.
Leaflet.hideLoading <- function(mapId){
    rpgm.sendToJavascript('leaflet/loading/hide', list(mapId=mapId))
}