source(rpgm.pgmFilePath('modules/leaflet/main.R'))

# Initialize the map widget
Leaflet.createMap(
    'main',
    rpgm.step('main', 'leaflet'),
    'map',
    layer = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    height = 512,
    options = list(
        center=Leaflet.latLng(48, 2),
        zoom=5
    ),
    layerOptions = list(
        maxZoom=19,
        attribution='&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    )
)

# Create the default icon
file.copy(rpgm.pgmFilePath('modules/leaflet/resources/icon.png'), rpgm.outputFile("leaflet_icon.png"));
leafletIconPath <- if(rpgm.isServer()) rpgm.outputFileURL('leaflet_icon.png') else rpgm.outputFile('leaflet_icon.png')
Leaflet.createIcon('default', list(
    iconUrl = leafletIconPath,
    iconSize = c(48, 48),
    iconAnchor = c(24, 48),
    popupAnchor = c(0, -48)
));

# Start loading data when the map is ready
Leaflet.on('main', 'onDidLoad', function(){
    Leaflet.showLoading('main');
    loadDonnees("Primes", path[["Primes"]])
});