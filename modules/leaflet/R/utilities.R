# Create a new LatLng object to use where [Leaflet LatLng object](https://leafletjs.com/reference.html#latlng) are used.
Leaflet.latLng <- function(lat, lng){
    return(list(lat=lat, lng=lng))
}

# Create a new LatLng object to use where [Leaflet LatLngBounds object](https://leafletjs.com/reference.html#latlngbounds) are used.
Leaflet.latLngBounds <- function(corner1, corner2){
    return(list(corner1=corner1, corner2=corner2));
}