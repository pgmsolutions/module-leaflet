Leaflet.latLng <- function(lat, lng){
    return(list(lat=lat, lng=lng))
}

Leaflet.latLngBounds <- function(corner1, corner2){
    return(list(corner1=corner1, corner2=corner2));
}