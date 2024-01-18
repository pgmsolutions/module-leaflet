# Queue a new circle in the shapes layer
Leaflet.addCircle <- function(mapId, shapeId, point, tooltip, options){
    rpgm.sendToJavascript('leaflet/shapes/add/circle', list(mapId=mapId, shapeId=shapeId, point=point, tooltip=tooltip, options=options))
}

# Queue a new polygon in the shapes layer
Leaflet.addPolygon <- function(mapId, shapeId, points, tooltip, options){
    rpgm.sendToJavascript('leaflet/shapes/add/polygon', list(mapId=mapId, shapeId=shapeId, points=points, tooltip=tooltip, options=options))
}

# Remove all previously drawed shapes and draw all queued shapes
Leaflet.flushShapes <- function(mapId){
    rpgm.sendToJavascript('leaflet/shapes/flush', list(mapId=mapId))
}