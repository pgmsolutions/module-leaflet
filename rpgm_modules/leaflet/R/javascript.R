rpgm.on('didReceiveMessage', function(message, data){
    if(message == 'leaflet/onDidEnterStep'){
        # Check if a map exists in this step and load it
        for(map in .leaflet$maps){
            if(map$step[[2L]] == data$stepId){
                rpgm.sendToJavascript('leaflet/initialize', list(mapId=mapId, layer=layerURL, height=height, options=options, layerOptions=layerOptions))
            }
        }
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