shape <- list()
n_shape <- 6L
script.setProgress(TRUE, 0L, "Importing shape files... 1/6")

shape$country <- sf::st_read("sf/gadm41_FRA_0.shp")
shape$country <- sf::st_simplify(shape$country, preserveTopology = TRUE, dTolerance = 30)
script.setProgress(TRUE, 8L, "Importing shape files... 2/6")

shape$region <- sf::st_read("sf/gadm41_FRA_1.shp")
shape$region <- sf::st_simplify(shape$region, preserveTopology = TRUE, dTolerance = 30)
script.setProgress(TRUE, 17L, "Importing shape files... 3/6")

shape$departement <- sf::st_read("sf/gadm41_FRA_2.shp")
script.setProgress(TRUE, 25L, "Importing shape files... 4/6")

shape[[4]] <- sf::st_read("sf/gadm41_FRA_3.shp")
script.setProgress(TRUE, 33L, "Importing shape files... 5/6")

shape[[5]] <- sf::st_read("sf/gadm41_FRA_4.shp")
script.setProgress(TRUE, 42L, "Importing shape files... 6/6")

shape[[6]] <- sf::st_read("sf/gadm41_FRA_5.shp")
script.setProgress(TRUE, 50L, "Importing shape files... 6/6")

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

#var_1 = appartement/maison
donnees <- data.table::fread("donnees/aportfolios.csv", sep =";", na.strings=c("",NA,"NULL"), select=c("lat", "lng", "prime_ttc", "var_1"))
IS_NULL <- is.na(donnees$lat) | is.na(donnees$lng)

donnees_null <- donnees[IS_NULL, ]
donnees <- donnees[!IS_NULL, ]

data.table::setDF(donnees)
data.table::setDF(donnees_null)

donnees_points <- donnees[c("lat", "lng")]
donnees_points_sf <- sf::st_as_sf(donnees_points, coords = c('lng', 'lat'), crs = sf::st_crs(shape[[1]]))

couleur_min <- '#f1c40f'
couleur_max <- '#c0392b'
couleur_median <- '#e67e22'
couleur_zero <- '#bdc3c7'

Primes <- Primes_couleurs <- list()
for(i in 1:length(shape))
{
    script.setProgress(TRUE, round(100*(n_shape+i-1)/(2*n_shape)), paste0("Importing premiums... ", i, "/", n_shape))
    Z <- as.data.frame(sf::st_within(donnees_points_sf, shape[[i]])) #dans le polygone ou non, tester si plus performant
    Primes[[i]] <- as.vector(tapply(donnees$prime_ttc[Z$row.id], factor(Z$col.id, levels = 1:length(shape[[i]]$geometry)), sum))
    Primes[[i]][is.na(Primes[[i]])] <- 0
    if(length(Primes[[i]]) > 1)
        Primes_couleurs[[i]] <- interpCol(Primes[[i]], couleur_min, couleur_max)
    else
        Primes_couleurs[[i]] <- couleur_median
    Primes_couleurs[[i]][Primes[[i]] == 0] <- couleur_zero
}
script.setProgress(TRUE, 100L, "Entering GUI...")

