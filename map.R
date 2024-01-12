source(rpgm.pgmFilePath('rpgm_modules/leaflet/main.R'))

# Initialize the map widget
Leaflet.createMap(
    'main',
    rpgm.step('main', 'leaflet'),
    'map',
    layer = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    height = 512,
    options = list(
        center=Leaflet.Latlng(48, 2),
        zoom=5
    ),
    layerOptions = list(
        maxZoom=19,
        attribution='&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    )
)

# Create the default icon
file.copy(rpgm.pgmFilePath('rpgm_modules/leaflet/resources/icon.png'), rpgm.outputFile("leaflet_icon.png"));
Leaflet.createIcon('default_icon', list(
    iconUrl = rpgm.outputFileURL('leaflet_icon.png'),
    iconSize = c(48, 48),
    iconAnchor = c(24, 48),
    popupAnchor = c(0, -48)
));

# Start loading data when the map is ready
Leaflet.addEventListener('main', 'onDidLoad', function(){
    Leaflet.showLoading('main');
    loadDonnees("Primes", path[["Primes"]])
});