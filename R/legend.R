# Update the content of the legend of the map with `content`.
Leaflet.updateLegend <- function(mapId, content){
    rpgm.sendToJavascript('leaflet/legend/update', list(mapId=mapId, content=content))
}