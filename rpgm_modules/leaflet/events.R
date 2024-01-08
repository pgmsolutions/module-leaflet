.leaflet$emit <- function(mapId, event, data){
    for(map in .leaflet$maps){
        if(map$id == mapId){
            for(entry in map$events[[event]]){
                do.call(entry, data);
            }
        }
    }
}

Leaflet.addEventListener <- function(mapId, event, callback){
    for(map in .leaflet$maps){
        if(map$id == mapId){
            map$events[[event]] <- append(map$events[[event]], callback);
        }
    }
}

Leaflet.removeEventListener <- function(mapId, event, callback){
    for(map in .leaflet$maps){
        if(map$id == mapId){
            map$events[[event]] <<- map$events[[event]][map$events[[event]] != callback];
        }
    }
}