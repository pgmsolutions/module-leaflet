.leaflet <- new.env(parent=emptyenv())
.leaflet$maps <- list()

source(rpgm.pgmFilePath('rpgm_modules/leaflet/R/events.R'))
source(rpgm.pgmFilePath('rpgm_modules/leaflet/R/javascript.R'))
source(rpgm.pgmFilePath('rpgm_modules/leaflet/R/utilities.R'))

#### CREATION ####
Leaflet.createMap <- function(mapId, step, widgetId, layer = layerURL, height = 512, options = list(), layerOptions = list()){
    gui.setValue(step, widgetId, paste0('<div id="leaflet-', mapId, '" style="height: ', height ,'px"></div>'))
    .leaflet$maps[[mapId]] <- list(
        id=mapId,
        step=step,
        layer=layer,
        height=height,
        options=options,
        layerOptions=layerOptions,
        events=list(
            didLoad=list(),
            didClickMap=list(),
            didChangeView=list()
        )
    )
    rpgm.sendToJavascript('leaflet/enterStep') # Should force a leaflet/enterStep client msg
}

#### VIEWS ####
Leaflet.setView <- function(mapId, center, zoom){
    rpgm.sendToJavascript('leaflet/map/view', list(mapId=mapId, center=center, zoom=zoom))
}
Leaflet.setZoom <- function(mapId, zoom){
    rpgm.sendToJavascript('leaflet/map/zoom', list(mapId=mapId, zoom=zoom))
}
Leaflet.fitBounds <- function(mapId, bounds){
    rpgm.sendToJavascript('leaflet/map/fit', list(mapId=mapId, bounds=bounds))
}

#### MARKERS & ICONS ####
Leaflet.createIcon <- function(iconId, options){
    rpgm.sendToJavascript('leaflet/icon/create', list(iconId=iconId, options=options))
}
Leaflet.marker <- function(iconId, latlng, popup, options = list()){
    return(list(
        iconId=iconId,
        pos=latlng,
        popup=popup,
        options=options
    ))
}
Leaflet.updateMarkers <- function(mapId, markers){
    rpgm.sendToJavascript('leaflet/markers/update', list(mapId=mapId, markers=markers))
}

#### LEGEND ####
Leaflet.updateLegend <- function(mapId, content){
    rpgm.sendToJavascript('leaflet/legend/update', list(mapId=mapId, content=content))
}

#### GEOJSON ####
Leaflet.addGeoJSON <- function(mapId, data){
    rpgm.sendToJavascript('leaflet/geojson/add', list(mapId=mapId, zoneId=data$id, points=data$points, tooltip=data$tooltip, color=data$color))
}
Leaflet.flushGeoJSON <- function(mapId){
    rpgm.sendToJavascript('leaflet/geojson/flush', list(mapId=mapId))
}

#### LOADING ####
Leaflet.showLoading <- function(mapId){
    rpgm.sendToJavascript('leaflet/loading/show', list(mapId=mapId))
}
Leaflet.hideLoading <- function(mapId){
    rpgm.sendToJavascript('leaflet/loading/hide', list(mapId=mapId))
}