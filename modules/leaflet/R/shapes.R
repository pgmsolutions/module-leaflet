# Queue a new circle in the shapes layer. When all shapes are added, call `flushShapes()` to draw all the shapes at once.
Leaflet.addCircle <- function(mapId, shapeId, point, tooltip="", options=list()){
    rpgm.sendToJavascript('leaflet/shapes/add/circle', list(mapId=mapId, shapeId=shapeId, point=point, tooltip=tooltip, options=options))
}

# Queue a new polygon in the shapes layer. When all shapes are added, call `flushShapes()` to draw all the shapes at once.
Leaflet.addPolygon <- function(mapId, shapeId, points, tooltip="", options=list()){
    rpgm.sendToJavascript('leaflet/shapes/add/polygon', list(mapId=mapId, shapeId=shapeId, points=points, tooltip=tooltip, options=options))
}

# Remove all previous rendered simple shapes and draw all the queued shapes with `addCircle()` and `addPolygon()`.
Leaflet.flushShapes <- function(mapId){
    rpgm.sendToJavascript('leaflet/shapes/flush', list(mapId=mapId))
}