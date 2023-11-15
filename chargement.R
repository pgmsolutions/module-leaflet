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
    if(zoomLevel <=5)
        return(1)
    if(zoomLevel <=6)
        return(2)
    if(zoomLevel <=7)
        return(3)
    if(zoomLevel <=8)
        return(4)
    if(zoomLevel <=9)
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
donnees <- data.table::fread("donnees/aportfolios.csv", sep =";", na.strings=c("",NA,"NULL"), select=c("lat", "lng", "prime_ttc", "var_1", "var_2", "var_3"), encoding = 'UTF-8')
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

DonneesCarte <- DonneesCarte_couleurs <- list() 
DonneesCarte[["Primes"]] <- DonneesCarte_couleurs[["Primes"]] <- list()
for(i in 1:length(shape))
{
    script.setProgress(TRUE, round(100*(n_shape+i-1)/(2*n_shape)), paste0("Importing premiums... ", i, "/", n_shape))
    Z <- as.data.frame(sf::st_within(donnees_points_sf, shape[[i]])) #dans le polygone ou non, tester si plus performant
    DonneesCarte[["Primes"]][[i]] <- as.vector(tapply(donnees$prime_ttc[Z$row.id], factor(Z$col.id, levels = 1:length(shape[[i]]$geometry)), sum))
    DonneesCarte[["Primes"]][[i]][is.na(DonneesCarte[["Primes"]][[i]])] <- 0
    if(length(DonneesCarte[["Primes"]][[i]]) > 1)
        DonneesCarte_couleurs[["Primes"]][[i]] <- interpCol(DonneesCarte[["Primes"]][[i]], couleur_min, couleur_max)
    else
        DonneesCarte_couleurs[["Primes"]][[i]] <- couleur_median
    DonneesCarte_couleurs[["Primes"]][[i]][DonneesCarte[["Primes"]][[i]] == 0] <- couleur_zero
}
script.setProgress(TRUE, 100L, "Entering GUI...")

loadDonneesVents <- function(path)
{
    gui.show(rpgm.step('main', 'leaflet'), 'progressbar_donnees')
    gui.setProperties("this", "progressbar_donnees", list(value = 100, progressdescription = "0%"))
    vents <- data.table::fread(path, sep =";", na.strings=c("",NA,"NULL"), select=c("Coordonnees", "Rafale sur les 10 dernieres minutes"))
    colnames(vents) <- c("coord", "rafales")
    vents <- vents[!is.na(vents$coord) & !is.na(vents$rafales)]
    vents[, c("lat", "lng")] <- data.table::tstrsplit(vents$coord, ", ")
    vents$coord <- NULL
    vents$rafales <- vents$rafales*3.6

    data.table::setDF(vents)

    vents_points <- vents[c("lat", "lng")]
    vents_points_sf <- sf::st_as_sf(vents_points, coords = c('lng', 'lat'), crs = sf::st_crs(shape[[1]]))

    DonneesCarte[["Vents"]] <<- DonneesCarte_couleurs[["Vents"]] <<- list()
    for(i in 1:length(shape))
    {
        Z <- as.data.frame(sf::st_within(vents_points_sf, shape[[i]])) #dans le polygone ou non, tester si plus performant
        DonneesCarte[["Vents"]][[i]] <<- as.vector(tapply(vents$rafales[Z$row.id], factor(Z$col.id, levels = 1:length(shape[[i]]$geometry)), max))
        DonneesCarte[["Vents"]][[i]][is.na(DonneesCarte[["Vents"]][[i]])] <<- 0
        if(length(DonneesCarte[["Vents"]][[i]]) > 1)
            DonneesCarte_couleurs[["Vents"]][[i]] <<- interpCol2(DonneesCarte[["Vents"]][[i]], c("#3498db", "#2980b9", "#1c2e30"), c(0, 0.5, 1))
        else
            DonneesCarte_couleurs[["Vents"]][[i]] <<- "#2980b9"
        DonneesCarte_couleurs[["Vents"]][[i]][DonneesCarte[["Vents"]][[i]] == 0] <<- couleur_zero
        k <- round(100*i/(n_shape))
        gui.setProperties("this", "progressbar_donnees", list(value = k, progressdescription = `if`(k < 25, paste0(k, "%"), paste0("Import... ", k, "%"))))
    }
}

loadDonnees <- function(nom, path)
{
    if(nom == "ciaran")
        if(is.null(DonneesCarte[["Vents"]]))
            loadDonneesVents(path)
}

empreinte <- "exposition"
gui.hide(rpgm.step('main', 'leaflet'), 'var_1')
gui.hide(rpgm.step('main', 'leaflet'), 'var_2')
gui.hide(rpgm.step('main', 'leaflet'), 'var_3')
gui.hide(rpgm.step('main', 'leaflet'), 'progressbar_donnees')
