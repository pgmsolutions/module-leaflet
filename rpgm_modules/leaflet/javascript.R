rpgm.on('didReceiveMessage', function(message, data){
    if(message == 'leaflet/enterStep'){
        # Check if a map exists in this step and load it
        for(map in .leaflet$maps){
            if(map$step[[2L]] == data$stepId){
                rpgm.sendToJavascript('leaflet/initialize', list(mapId=mapId, layer=layerURL, height=height, options=options, layerOptions=layerOptions))
            }
        }
    }
})