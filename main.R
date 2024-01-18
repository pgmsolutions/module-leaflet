doDisplayPolygon <- function(Z, view)
{
    Z_range <- list(lng = range(Z[, 1]), lat = range(Z[, 2]))
    return(Z_range$lat[1] < view$northLat && Z_range$lat[2] > view$southLat && Z_range$lng[1] < view$eastLng && Z_range$lng[2] > view$westLng)
}

formatPolygonForLeaflet <- function(Z){
    return(lapply(seq_len(nrow(Z)), function(k) list(Z[k, 1], Z[k, 2])))
}

leafletTooltipGeo <- function(pays, region, dpt, canton, insee, commune){
    return(paste0(
        "Pays : <strong>", pays, "</strong>",
        `if`(is.null(region), "", paste0("<br>Région : <strong>", region, "</strong>")),
        `if`(is.null(dpt), "", paste0("<br>Département : <strong>", dpt, "</strong>")),
        `if`(is.null(canton), "", paste0("<br>Canton : <strong>", canton, "</strong>")),
        `if`(is.null(insee), "", paste0("<br>Insee : <strong>", insee, "</strong>")),
        `if`(is.null(commune), "", paste0("<br>Commune : <strong>", commune, "</strong>"))
    ));
}

leafletTooltipDonnees <- function(pays, region, dpt, canton, insee, commune, donnees){
    tooltip <- leafletTooltipGeo(pays, region, dpt, canton, insee, commune)
    for(i in 1:length(donnees)){
        tooltip <- paste0(tooltip, `if`(i == 1, "<br>", ""), "<br>", names(donnees)[i], " : <strong>", format(round(donnees[[i]]$value), big.mark = " "), donnees[[i]]$unit, "</strong>.")
    }
    return(tooltip)
}

plotlyTitle <- function(pays, region, dpt, canton, insee, commune, primes){
    return(paste0(
        "<b>", pays, "</b>",
        `if`(is.null(region), "", paste0(", <b>", region, "</b>")),
        `if`(is.null(dpt), "", paste0(", <b>", dpt, "</b>")),
        `if`(is.null(canton), "", paste0(", <b>", canton, "</b>")),
        `if`(is.null(insee), "", paste0(", <b>", insee, "</b>")),
        `if`(is.null(commune), "", paste0(", <b>", commune, "</b>")),
        `if`(is.null(primes), "", paste0("<br>Primes : <b>", format(round(primes), big.mark = " "), "€</b>"))
    ))
}

# Show the corresponding plotly graph of the clicked zone on the map 
showPlotlyGraph <- function(data){
    z <- getLvlPolygonToDisplay(data$zoomLevel)
    selected_shape <- shape[[z]][data$zoneId, ]
    assures <- Donnees[["Primes"]][t(sf::st_contains(selected_shape, donnees_points_sf, sparse = FALSE)), ]

    # Layout commun
    layout = list(
        title = plotlyTitle(selected_shape$COUNTRY, selected_shape$NAME_1, selected_shape$NAME_2, selected_shape$NAME_3, selected_shape$NAME_4, selected_shape$NAME_5, DonneesCartes[["Primes"]]$valeurs[[z]][as.integer(data$zoneId)]),
        font = list(
            color = '#ecf0f1'
        ),
        plot_bgcolor = '#2e3134',
        paper_bgcolor = '#2e3134'
    )

    # Graphics
    for(var in paste0("var_", 1:3)){
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

# Set the hook to the onDidClickZone function
Leaflet.on('main', 'onDidClickZone', showPlotlyGraph);

# Generate the HTML of the legend of the map.
getLegend <- function(info, unite)
{
    result <- paste0('Légende (', unite, ') <br>');
    for(i in info){
        result <- paste0(result, '<div class="map-legend-entry"><i style="background:', i$color, '"></i> ', i$label, '</div>')
    }
    return(result);
}

# Set the default view and zoom of the leaflet map
setDefaultView <- function(){
    Leaflet.setView('main', Leaflet.latLng(48, 2), 5);
    Leaflet.setZoom('main', 5);
}

# Called when the end-user changes the view of the leaflet map
onDidChangeView <- function(data){
    z <<- getLvlPolygonToDisplay(data$zoomLevel)
    if(mapReady[[empreinte]] >= z && (is.null(lastView) || lastView$empreinte != empreinte || lastView$zoomLevel != data$zoomLevel || (data$northLat > lastView$northLat || data$southLat < lastView$southLat || data$eastLng > lastView$eastLng || data$westLng < lastView$westLng)))
    {
        total <- 0

        lengthLat <- data$northLat - data$southLat
        lengthLng <- data$eastLng - data$westLng
        data[c('northLat', 'southLat', 'eastLng', 'westLng')] <- as.list(c(data$northLat, data$southLat, data$eastLng, data$westLng) + 0.4*c(lengthLat, - lengthLat, lengthLng, - lengthLng))

        lastView <<- data[c('northLat', 'southLat', 'eastLng', 'westLng', 'zoomLevel')]
        lastView$empreinte <<- empreinte

        for(i in 1:length(shape[[z]]$geometry))
        {
            P <- list()
            l <- 1
            for(j in 1:length(shape[[z]]$geometry[[i]]))
            {
                for(k in 1:length(shape[[z]]$geometry[[i]][[j]]))
                {
                    Z <- shape[[z]]$geometry[[i]][[j]][[k]]
                    if(nrow(Z) > 1 && doDisplayPolygon(Z, data))
                    {
                        P[[l]] <- formatPolygonForLeaflet(Z)
                        l <- l+1
                    }
                }
            }
            if(l > 1)
            {
                if(empreinte == "Primes")
                    Leaflet.addGeoJSON('main', list(points=P, id=i, tooltip=leafletTooltipDonnees(shape[[z]]$COUNTRY[i], shape[[z]]$NAME_1[i], shape[[z]]$NAME_2[i], shape[[z]]$NAME_3[i], shape[[z]]$NAME_4[i], shape[[z]]$NAME_5[i], list(Primes = list(value = DonneesCartes[[empreinte]]$valeurs[[z]][i], unit = DonneesCartes[[empreinte]]$unite))), color=DonneesCartes[[empreinte]]$couleurs[[z]][i]))
                else if(empreinte == "Ciaran")
                    Leaflet.addGeoJSON('main', list(points=P, id=i, tooltip=leafletTooltipDonnees(shape[[z]]$COUNTRY[i], shape[[z]]$NAME_1[i], shape[[z]]$NAME_2[i], shape[[z]]$NAME_3[i], shape[[z]]$NAME_4[i], shape[[z]]$NAME_5[i], list(Primes = list(value = DonneesCartes[["Primes"]]$valeurs[[z]][i], unit = "€"), Vents = list(value = DonneesCartes[[empreinte]]$valeurs[[z]][i], unit = DonneesCartes[[empreinte]]$unite))), color=DonneesCartes[[empreinte]]$couleurs[[z]][i]))
                total <- total+1
            }
        }
        
        # Erase previous drawings and draw all polygons added in queue
        Leaflet.flushGeoJSON('main')
        Leaflet.updateLegend('main', getLegend(lapply(seq_len(length(DonneesCartes[[empreinte]]$legendes[[z]]$couleurs)), function(k) list(color = DonneesCartes[[empreinte]]$legendes[[z]]$couleurs[k], label = DonneesCartes[[empreinte]]$legendes[[z]]$labels[k])), DonneesCartes[[empreinte]]$unite))
        
        # Markers
        if(empreinte == "Primes"){
            donnees_loc <- Donnees[[empreinte]][Donnees[[empreinte]]$lat < data$northLat & Donnees[[empreinte]]$lat > data$southLat & Donnees[[empreinte]]$lng < data$eastLng & Donnees[[empreinte]]$lng > data$westLng, ]
        }
        
        if(empreinte == "Primes" && nrow(donnees_loc) <= 500L){
            if(empreinte == "Primes"){
                D <- lapply(seq_len(nrow(donnees_loc)), function(k) Leaflet.marker('default', Leaflet.latLng(donnees_loc$lat[k], donnees_loc$lng[k]), paste0(empreinte, " : <strong>", donnees_loc$prime_ttc[k], DonneesCartes[[empreinte]]$unite, "</strong>.")))
            }
            else if(empreinte == "Ciaran"){
                D <- lapply(seq_len(nrow(donnees_loc)), function(k) Leaflet.marker('default', Leaflet.latLng(donnees_loc$lat[k], donnees_loc$lng[k]), paste0(empreinte, " : <strong>", donnees_loc$rafales[k], DonneesCartes[[empreinte]]$unite, "</strong>.")))
            }
            Leaflet.updateMarkers('main', D)
        }
        else {
            Leaflet.updateMarkers('main', list())
        }
    }
}

# Set the hook to the onDidChangeView function
Leaflet.on('main', 'onDidChangeView', onDidChangeView);