.leaflet <- new.env(parent=emptyenv())
.leaflet$maps <- list()

source(rpgm.pgmFilePath('rpgm_modules/leaflet/events.R'))
source(rpgm.pgmFilePath('rpgm_modules/leaflet/javascript.R'))
source(rpgm.pgmFilePath('rpgm_modules/leaflet/utilities.R'))

#### CREATION ####
Leaflet.create <- function(mapId, step, widgetId, layerURL, height = 512, options = list(), layerOptions = list()){
    gui.setValue(step, widget, paste0('<div id="leaflet-', mapId, '" style="height: ', height ,'px"></div>'))
    .leaflet$maps[[mapId]] <- list(
        id=mapId,
        step=step,
        layer=layerURL,
        height=height,
        options=options,
        layerOptions=layerOptions,
        events=list(
            didClickMap=list(),
            didChangeView=list()
        )
    )
    rpgm.sendToJavascript('leaflet/enterStep') # Should force a leaflet/enterStep client msg
}

#### VIEWS ####
Leaflet.setView <- function(mapId, center, zoom){
    rpgm.sendToJavascript('leaflet/setView', list(mapId=mapId, center=center, zoom=zoom))
}
Leaflet.setZoom <- function(mapId, zoom){
    rpgm.sendToJavascript('leaflet/setZoom', list(mapId=mapId, zoom=zoom))
}
Leaflet.fitBounds <- function(mapId, bounds){
    rpgm.sendToJavascript('leaflet/fitBounds', list(mapId=mapId, bounds=bounds))
}

#### MARKERS ####
Leaflet.createIcon <- function(iconId, options){
    rpgm.sendToJavascript('leaflet/icon/create', list(iconId=iconId, options=options))
}
Leaflet.marker <- function(latlng, popup, options = list()){
    return(list(
        pos=latlng,
        popup=popup,
        options=options
    ))
}
Leaflet.updateMarkers <- function(mapId, markers){
    rpgm.sendToJavascript('leaflet/updateMarkers', list(mapId=mapId, markers=markers))
}

#### LEGEND ####
Leaflet.updateLegend <- function(mapId, content){
    rpgm.sendToJavascript('leaflet/updateLegend', list(mapId=mapId, content=content))
}

#### GEOJSON ####
Leaflet.addGeoJSON <- function(mapId, zoneId, points, tooltip, color){
    rpgm.sendToJavascript('leaflet/addGeoJSON', list(mapId=mapId, zoneId=zoneId, points=points, tooltip=tooltip, color=color))
}
Leaflet.flushGeoJSON <- function(mapId){
    rpgm.sendToJavascript('leaflet/flushGeoJSON', list(mapId=mapId))
}