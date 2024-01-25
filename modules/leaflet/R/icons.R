.leaflet$icons <- list()

# Create a new icon for future markers. Icon should be created before initializing the map.
Leaflet.createIcon <- function(iconId, options){
    .leaflet$icons[[iconId]] <<- options;
}

# Create a new marker to be used with `Leaflet.updateMarkers()`.
Leaflet.marker <- function(iconId, latlng, popup, options = list()){
    return(list(
        iconId=iconId,
        pos=latlng,
        popup=popup,
        options=options
    ))
}

# Remove all existing markers on the map and draw all the markers in the `markers` parameter.
Leaflet.updateMarkers <- function(mapId, markers){
    rpgm.sendToJavascript('leaflet/markers/update', list(mapId=mapId, markers=markers))
}