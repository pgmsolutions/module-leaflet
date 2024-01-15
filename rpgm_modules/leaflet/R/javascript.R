rpgm.on('didReceiveMessage', function(message, data){
    if(message == 'leaflet/onDidEnterStep'){
        # Check if a map exists in this step and load it
        for(map in .leaflet$maps){
            if(map$step[[2L]] == data$stepId){
                rpgm.sendToJavascript('leaflet/initialize', list(
                    mapId=map$id,
                    layer=map$layer,
                    height=map$height,
                    options=map$options,
                    layerOptions=map$layerOptions,
                    icons=.leaflet$icons
                ))
            }
        }
    }
    else if(message == 'leaflet/onDidLoad'){
        # No extra data
        .leaflet$emit(data$id, 'onDidLoad', list())
    }
    else if(message == 'leaflet/onDidClickMap'){
        # lat, lng
        .leaflet$emit(data$id, 'onDidClickMap', list(data=data))
    }
    else if(message == 'leaflet/onDidClickZone'){
        # zoneId, northLat, eastLng, southLat, westLng, zoomLevel
        .leaflet$emit(data$id, 'onDidClickZone', list(data=data))
    }
    else if(message == 'leaflet/onDidChangeView'){
        # northLat, eastLng, southLat, westLng, zoomLevel
        .leaflet$emit(data$id, 'onDidChangeView', list(data=data))
    }
})