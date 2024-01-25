.leaflet$maps <- list()

# Create a new map widget. This function must be called before entering the GUI containing the map.
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
    rpgm.sendToJavascript('leaflet/enterStep')
}