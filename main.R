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

leafletTooltip <- function(pays, region, dpt, canton, insee, commune, prime)
    return(paste0(
        "Pays : <strong>", pays, "</strong>",
        `if`(is.null(region), "", paste0("<br>Région : <strong>", region, "</strong>")),
        `if`(is.null(dpt), "", paste0("<br>Département : <strong>", dpt, "</strong>")),
        `if`(is.null(canton), "", paste0("<br>Canton : <strong>", canton, "</strong>")),
        `if`(is.null(insee), "", paste0("<br>Insee : <strong>", insee, "</strong>")),
        `if`(is.null(commune), "", paste0("<br>Commune : <strong>", commune, "</strong>")),
        "<br><br>Primes : <strong>", format(round(prime), big.mark = " "), "€</strong>."
    ))

onRPGMJavascript <- function(message, data){
    if(message == 'mapState'){
        gui.setValue('this', 'lastBounds', paste0('North lat: ', round(data$view$northLat, 3), ' East lng: ', round(data$view$eastLng, 3), ' South lat: ', round(data$view$southLat, 3), ' West lng: ', round(data$view$westLng, 3), ' Zoom lvl: ', data$view$zoomLevel));
        total <- 0
        z <- getLvlPolygonToDisplay(data$view$zoomLevel)
        color <- getColorLvlPolygon(z)
        for(i in 1:length(shape[[z]]$geometry))
        {
            P <- list()
            l <- 1
            for(j in 1:length(shape[[z]]$geometry[[i]]))
            {
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
                rpgm.sendToJavascript('addGeoJSON', list(points=P, id=i, tooltip=leafletTooltip(shape[[z]]$COUNTRY[[i]], shape[[z]]$NAME_1[i], shape[[z]]$NAME_2[i], shape[[z]]$NAME_3[i], shape[[z]]$NAME_4[i], shape[[z]]$NAME_5[i], Primes[[z]][i]), color=Primes_couleurs[[z]][i]));
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