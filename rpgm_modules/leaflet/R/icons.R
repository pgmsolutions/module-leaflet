.leaflet$icons <- list()

Leaflet.createIcon <- function(iconId, options){
    .leaflet$icons[[iconId]] <<- options;
}