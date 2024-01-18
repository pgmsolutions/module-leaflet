.leaflet$emit <- function(mapId, event, data){
    for(map in .leaflet$maps){
        if(map$id == mapId){
            for(entry in map$events[[event]]){
                do.call(entry, data[names(data) != "id"]);
            }
        }
    }
}

# Add a new event listener. See the [Events](#events) section for more information.
Leaflet.on <- function(mapId, event, callback){
    for(map in .leaflet$maps){
        if(map$id == mapId){
            .leaflet$maps[[map$id]]$events[[event]] <- append(map$events[[event]], callback);
        }
    }
}

# Remove an existing event listener. See the [Events](#events) section for more information.
Leaflet.off <- function(mapId, event, callback){
    for(map in .leaflet$maps){
        if(map$id == mapId){
           .leaflet$maps[[map$id]]$events[[event]] <- map$events[[event]][map$events[[event]] != callback];
        }
    }
}