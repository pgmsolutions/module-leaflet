setDefaultView <- function(){
    rpgm.sendToJavascript('resetView', list()); # resetView doesn't not need data, so we use an empty list
}

doDisplayPolygon <- function(Z, view)
{
    Z_range <- list(lng = range(Z[, 1]), lat = range(Z[, 2]))
    return(Z_range$lat[1] < view$northLat && Z_range$lat[2] > view$southLat && Z_range$lng[1] < view$eastLng && Z_range$lng[2] > view$westLng)
}

formatPolygonForLeaflet <- function(Z)
    return(lapply(seq_len(nrow(Z)), function(k) list(Z[k, 1], Z[k, 2])))

onRPGMJavascript <- function(message, data){
    if(message == 'mapState'){
        gui.setValue('this', 'lastBounds', paste0('North lat: ', round(data$view$northLat, 3), ' East lng: ', round(data$view$eastLng, 3), ' South lat: ', round(data$view$southLat, 3), ' West lng: ', round(data$view$westLng, 3), ' Zoom lvl: ', data$view$zoomLevel));

        # Create a triangle polygon in the current view
        # Here you should fetch info from database and draw polygon according to results and the lat/long of the view
        # rpgm.sendToJavascript('resetDrawings', list()); # First erase previous polygons
        # rpgm.sendToJavascript('drawPolygon', list(color="blue", points=list(
        #     list(lat=data$view$northLat, lng=data$view$westLongitude), # NW
        #     list(lat=data$view$northLatitude, lng=data$view$eastLongitude), # NE
        #     list(lat=data$view$southLatitude, lng=data$view$eastLongitude), # SE
        #     list(lat=data$view$southLatitude, lng=data$view$westLongitude) # SW
        # )));

        # # lourd transfert en liste pour le format JS
        # z <- getLvlPolygonToDisplay(data$view$zoomLevel)
        # color <- getColorLvlPolygon(z)
        # for(i in 1:length(shape[[z]]$geometry))
        # {
        #     for(j in 1:length(shape[[z]]$geometry[[i]]))
        #     {
        #         Z <- shape[[z]]$geometry[[i]][[j]][[1]]
        #         if(nrow(Z) > 1 && doDisplayPolygon(Z, data$view))
        #         {
        #             P <- lapply(seq_len(nrow(Z)), function(k) list(lat = Z[k, 2], lng = Z[k, 1]))
        #             cat('Y')
        #             rpgm.sendToJavascript('addPolygonToQueue', list(color=color, points=P)); # Add polygon to queue
        #         }
        #     }
        # }
        # 
        # # Erase previous drawings and draw all polygons addded in queue
        # rpgm.sendToJavascript('drawQueue', list());

        # lourd transfert en liste pour le format JS
        total <- 0
        z <- getLvlPolygonToDisplay(data$view$zoomLevel)
        color <- getColorLvlPolygon(z)
        for(i in 1:length(shape[[z]]$geometry))
        {
#            donnees_points_sf <- sf::st_as_sf(donnees_points, coords = c('lng', 'lat'), crs = sf::st_crs(shape[[z]])) #ne sépare pas encore les polygones, donc teste tout, il faut gérer les sous polygones shape[[z]][i, ] après et tout envoyer / tester dedans. Et retravailler si besoin l'envoie des données / relier les polygones.
#            IS_IN_SHAPE <- sf::st_contains(shape[[1]], donnees_points_sf, sparse = FALSE) 
            P <- list()
            l <- 1
            for(j in 1:length(shape[[z]]$geometry[[i]]))
            {
                country <- shape[[z]]$COUNTRY[[i]]
                for(k in 1:length(shape[[z]]$geometry[[i]][[j]]))
                {
                    Z <- shape[[z]]$geometry[[i]][[j]][[k]]
                    if(nrow(Z) > 1 && doDisplayPolygon(Z, data$view))
                    {
                        P[[l]] <- formatPolygonForLeaflet(Z)
                        l <- l+1
                    }
                }
            }
            if(l > 1)
            {
                rpgm.sendToJavascript('addGeoJSON', list(points=P, id=i, tooltip=paste0("Primes : <strong>", format(round(Primes[[z]][i]), big.mark = " "), "€</strong>."), color=Primes_couleurs[[z]][i]));
                total <- total+1
            }
        }
        
        # Erase previous drawings and draw all polygons addded in queue
        gui.setValue('this', 'totalPolygons', paste0('Total multi-polygons drawed: ', total));
        rpgm.sendToJavascript('drawGeoJSON', list());
    }
    else if(message == 'mapClick'){
        print(paste0('User clicked on lat: ',data$coordinates$lat, 'and lng: ', data$coordinates$lng));
    }
    else if(message == 'zoneClick'){
        print(paste0('User clicked on zone id: ', data$id));
        rpgm.sendToJavascript('updateLegend', list(content="Bonjour"));
    }
}