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


leafletTooltipDonnees <- function(pays, region, dpt, canton, insee, commune, donnee, nom_donnee, unite_donnee)
    return(paste0(
        leafletTooltipGeo(pays, region, dpt, canton, insee, commune),
        "<br><br>", nom_donnee, " : <strong>", format(round(donnee), big.mark = " "), unite_donnee, "</strong>."
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

plotly_graph <- function(data)
{
        z <- getLvlPolygonToDisplay(data$zoomLevel)
        selected_shape <- shape[[z]][data$id, ]
        assures <- donnees[t(sf::st_contains(selected_shape, donnees_points_sf, sparse = FALSE)), ]

        #layout commun
        layout = list(
            title = plotlyTitle(selected_shape$COUNTRY, selected_shape$NAME_1, selected_shape$NAME_2, selected_shape$NAME_3, selected_shape$NAME_4, selected_shape$NAME_5),
            height = 350,
            width = 450,
            font = list(
                color = '#ecf0f1'
            ),
            plot_bgcolor = '#2e3134',
            paper_bgcolor = '#2e3134'
        )

        #graphiques 
        for(var in paste0("var_", 1:3))
        {
            donnees_plotly <- table(assures[[var]])
            data_plotly = list(
                values= as.list(as.vector(donnees_plotly)),
                labels= as.list(names(donnees_plotly)),
                type= 'pie',
                marker = list(
                    colors = c('#3498db', '#c0392b')
                )
            )
            gui.setValue('this', var, list(data = data_plotly, layout = layout))
            gui.show('this', var)
        }
}

onRPGMJavascript <- function(message, data){
    if(message == 'mapState'){
        if(mapReady)
        {
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
                        rpgm.sendToJavascript('addGeoJSON', list(points=P, id=i, tooltip=leafletTooltipDonnees(shape[[z]]$COUNTRY[i], shape[[z]]$NAME_1[i], shape[[z]]$NAME_2[i], shape[[z]]$NAME_3[i], shape[[z]]$NAME_4[i], shape[[z]]$NAME_5[i], DonneesCarte[["Primes"]][[z]][i], "Primes", "€"), color=DonneesCarte_couleurs[["Primes"]][[z]][i]))
                    else if(empreinte == "ciaran")
                        rpgm.sendToJavascript('addGeoJSON', list(points=P, id=i, tooltip=leafletTooltipDonnees(shape[[z]]$COUNTRY[i], shape[[z]]$NAME_1[i], shape[[z]]$NAME_2[i], shape[[z]]$NAME_3[i], shape[[z]]$NAME_4[i], shape[[z]]$NAME_5[i], DonneesCarte[["Vents"]][[z]][i], "Vents", "km/h"), color=DonneesCarte_couleurs[["Vents"]][[z]][i]))
                    total <- total+1
                }
            }
            
            # Erase previous drawings and draw all polygons addded in queue
            gui.setValue('this', 'totalPolygons', paste0('Total multi-polygons drawed: ', total, '<br>North lat: ', round(data$view$northLat, 3), ', East lng: ', round(data$view$eastLng, 3), ', South lat: ', round(data$view$southLat, 3), ', West lng: ', round(data$view$westLng, 3), ', Zoom lvl: ', data$view$zoomLevel));
            rpgm.sendToJavascript('drawGeoJSON', list());
            rpgm.sendToJavascript('updateLegend', list(content=getLegend(list(
                list(color='#FED976', label='100000 +'),
                list(color='#FEB24C', label='Elephant - Carotte'),
                list(color='#FD8D3C', label='50 - 1337'),
                list(color='#FC4E2A', label='20 - 40'),
                list(color='#800026', label='10 - 20')
            ))));
        }
    }
    else if(message == 'mapClick'){
        print(paste0('User clicked on lat: ',data$coordinates$lat, 'and lng: ', data$coordinates$lng));
    }
    else if(message == 'zoneClick'){
        plotly_graph(data)
   }
}

getLegend <- function(info){
    result <- '';
    for(i in info){
        result <- paste0(result, '<i style="background:', i$color, '"></i> ', i$label, '<br>');
    }
    return(result);
}