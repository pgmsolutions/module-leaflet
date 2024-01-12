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
                    layerOptions=map$layerOptions
                ))
            }
        }
    }
    else if(message == 'leaflet/onDidLoad'){
        cat(paste0("\n\nreceived onDidLoad from ", data$id, "...\n\n"))
        .leaflet$emit(data$id, 'onDidLoad', data)
    }
    else if(message == 'leaflet/onDidClickMap'){
        # data$lat, data#lng

    }
    else if(message == 'leaflet/onDidClickZone'){
        # data$zoneId

    }
    else if(message == 'leaflet/onDidChangeView'){
        # northLat, eastLng, southLat, westLng, zoomLevel
    }
})