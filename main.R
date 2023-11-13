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


leafletTooltipGeo <- function(pays, region, dpt, canton, insee, commune)
    return(paste0(
        "Pays : <strong>", pays, "</strong>",
        `if`(is.null(region), "", paste0("<br>Région : <strong>", region, "</strong>")),
        `if`(is.null(dpt), "", paste0("<br>Département : <strong>", dpt, "</strong>")),
        `if`(is.null(canton), "", paste0("<br>Canton : <strong>", canton, "</strong>")),
        `if`(is.null(insee), "", paste0("<br>Insee : <strong>", insee, "</strong>")),
        `if`(is.null(commune), "", paste0("<br>Commune : <strong>", commune, "</strong>"))
    ))


leafletTooltipPrimes <- function(pays, region, dpt, canton, insee, commune, prime)
    return(paste0(
        leafletTooltipGeo(pays, region, dpt, canton, insee, commune),
        "<br><br>Primes : <strong>", format(round(prime), big.mark = " "), "€</strong>."
    ))

leafletTooltipVents <- function(pays, region, dpt, canton, insee, commune, vent)
    return(paste0(
        leafletTooltipGeo(pays, region, dpt, canton, insee, commune),
        "<br><br>Vents : <strong>", format(round(vent), big.mark = " "), "km/h</strong>."
    ))


plotlyTitle <- function(pays, region, dpt, canton, insee, commune)
    return(paste0(
        "<b>", pays, "</b>",
        `if`(is.null(region), "", paste0(", <b>", region, "</b>")),
        `if`(is.null(dpt), "", paste0(", <b>", dpt, "</b>")),
        `if`(is.null(canton), "", paste0(", <b>", canton, "</b>")),
        `if`(is.null(insee), "", paste0(", <b>", insee, "</b>")),
        `if`(is.null(commune), "", paste0(", <b>", commune, "</b>"))
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
                if(empreinte == "exposition")
                    rpgm.sendToJavascript('addGeoJSON', list(points=P, id=i, tooltip=leafletTooltipPrimes(shape[[z]]$COUNTRY[i], shape[[z]]$NAME_1[i], shape[[z]]$NAME_2[i], shape[[z]]$NAME_3[i], shape[[z]]$NAME_4[i], shape[[z]]$NAME_5[i], Primes[[z]][i]), color=Primes_couleurs[[z]][i]))
                else if(empreinte == "babet")
                    rpgm.sendToJavascript('addGeoJSON', list(points=P, id=i, tooltip=leafletTooltipVents(shape[[z]]$COUNTRY[i], shape[[z]]$NAME_1[i], shape[[z]]$NAME_2[i], shape[[z]]$NAME_3[i], shape[[z]]$NAME_4[i], shape[[z]]$NAME_5[i], Rafales[[z]][i]), color=Rafales_couleurs[[z]][i]))
                total <- total+1
            }
        }
        
        # Erase previous drawings and draw all polygons addded in queue
        gui.setValue('this', 'totalPolygons', paste0('Total multi-polygons drawed: ', total));
        rpgm.sendToJavascript('drawGeoJSON', list());
        rpgm.sendToJavascript('updateLegend', list(content="Légende"));
    }
    else if(message == 'mapClick'){
        print(paste0('User clicked on lat: ',data$coordinates$lat, 'and lng: ', data$coordinates$lng));
    }
    else if(message == 'zoneClick'){
        print(paste0('User clicked on zone id: ', data$id));
        z <- getLvlPolygonToDisplay(data$zoomLevel)
        selected_shape <- shape[[z]][data$id, ]
        assures <- donnees[t(sf::st_contains(selected_shape, donnees_points_sf, sparse = FALSE)), ]
        donnees_plotly <- table(assures$var_1)
        data_plotly = list(
            values= as.list(as.vector(donnees_plotly)),
            labels= as.list(names(donnees_plotly)),
            type= 'pie',
            marker = list(
                colors = c('#3498db', '#c0392b')
            )
        )
        layout = list(
            title = plotlyTitle(selected_shape$COUNTRY, selected_shape$NAME_1, selected_shape$NAME_2, selected_shape$NAME_3, selected_shape$NAME_4, selected_shape$NAME_5),
            height = 400,
            width = 500
        )
        gui.setValue('this', 'var_1', list(data = data_plotly, layout = layout))
        gui.show('this', 'var_1')
    }
}