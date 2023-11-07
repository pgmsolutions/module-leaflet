shape <- list() 
script.setProgress(TRUE, 0L, "Importing shape files...")

shape$country <- sf::st_read("sf/gadm41_FRA_0.shp")
shape$country <- sf::st_simplify(shape$country, preserveTopology = TRUE, dTolerance = 30)
script.setProgress(TRUE, 16L, "Importing shape files...")

shape$region <- sf::st_read("sf/gadm41_FRA_1.shp")
shape$region <- sf::st_simplify(shape$region, preserveTopology = TRUE, dTolerance = 30)
script.setProgress(TRUE, 33L, "Importing shape files...")

shape$departement <- sf::st_read("sf/gadm41_FRA_2.shp")
script.setProgress(TRUE, 50L, "Importing shape files...")

shape[[4]] <- sf::st_read("sf/gadm41_FRA_3.shp")
script.setProgress(TRUE, 67L, "Importing shape files...")

shape[[5]] <- sf::st_read("sf/gadm41_FRA_4.shp")
script.setProgress(TRUE, 83L, "Importing shape files...")

shape[[6]] <- sf::st_read("sf/gadm41_FRA_5.shp")
script.setProgress(TRUE, 100L, "Importing shape files...")

getLvlPolygonToDisplay <- function(zoomLevel)
{
    if(zoomLevel <=6)
        return(1)
    if(zoomLevel <=7)
        return(2)
    if(zoomLevel <=8)
        return(3)
    if(zoomLevel <=9)
        return(4)
    if(zoomLevel <=10)
        return(5)
    return(6)
}

getColorLvlPolygon <- function(lvlPolygon)
{
    if(lvlPolygon == 1)
        return(rgb(52, 73, 94, maxColorValue=255))
    if(lvlPolygon == 2)
        return(rgb(52, 152, 219, maxColorValue=255))
    if(lvlPolygon == 3)
        return(rgb(41, 128, 185, maxColorValue=255))
    if(lvlPolygon == 4)
        return(rgb(211, 84, 0, maxColorValue=255))
    if(lvlPolygon == 5)
        return(rgb(231, 76, 60, maxColorValue=255))
    if(lvlPolygon == 6)
        return(rgb(192, 57, 43, maxColorValue=255))
}

X <- data.table::fread("aportfolios.csv", sep =";")