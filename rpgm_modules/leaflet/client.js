function wait(ms){
    return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Manage all the maps in the app.
 */
class MapManager {
    constructor(){
        this._currentStepCache = null;
        this._maps = [];
        this._icons = [];
    }

    /**
     * Initialize the map manager by setting hook on the RPGM app.
     */
    initialize(){
        // Send R the current step
        RPGM.on('didEnterStep', (stepId)=>{
            this._currentStepCache = stepId;
            RPGM.sendMessage('r', 'leaflet/enterStep', {id: this._currentStepCache});
        });

        // When receiving a message
        RPGM.on('didReceiveMessage', (message, data)=>{
            if(message === 'leaflet/enterStep' && this._currentStepCache !== null){
                RPGM.sendMessage('r', 'leaflet/enterStep', {id: this._currentStepCache});
                return;
            }
            if(message === 'leaflet/icon/create'){
                this._icons[data.iconId] = L.icon(data.options);
                return;
            }
            if(message === 'leaflet/initialize'){
                const mapInstance = new LeafletMap({
                    id: data.mapId,
                    layerURL: data.layerURL,
                    height: data.height,
                    options: data.options,
                    layerOptions: data.layerOptions
                });
                return;
            }

            // All next messages requires a mapId
            const mapInstance = this.getMap(data.mapId);
            if(mapInstance === undefined){
                return;
            }

            // Packets
            if(message === 'leaflet/setViews'){
                mapInstance.setView(data.center, data.zoom);
            }
            else if(message === 'leaflet/setZoom'){
                mapInstance.setZoom(data.zoom);
            }
            else if(message === 'leaflet/fitBounds'){
                mapInstance.fitBounds(data.bounds);
            }
            else if(message === 'leaflet/updateMarkers'){
                mapInstance.updateMarkers(data.markers);
            }
            else if(message === 'leaflet/updateLegend'){
                mapInstance.updateLegend(data.content);
            }
            else if(message === 'leaflet/addGeoJSON'){
                mapInstance.addGeoJSON(data.zoneId, data.points, data.tooltip, data.color);
            }
            else if(message === 'leaflet/flushGeoJSON'){
                mapInstance.flushGeoJSON();
            }
        });
    }

    /**
     * Return a map by its id or undefined if not found.
     */
    getMap(mapId){
        return this._maps.find(m => m.id === mapId);
    }

    /**
     * Return an icon by its id or undefined if not found.
     */
    getIcon(iconId){
        return this._icons.find(m => m.id === iconId);
    }
}

/**
 * This class manages the leaflet map.
 */
class Map {
    constructor(options){
        /** All draw stuff */
        this._queueGeoJSON = [];
        this._lastGeoJSON = null;
        this._markers = [];

        /** Timer to not send too much changes to RPGM */
        this._debouncer = null;

        /** JS binding */
        this.sendChange = this.sendChange.bind(this);
        this.initializeMap = this.initializeMap.bind(this);
        this.onMapViewChange = this.onMapViewChange.bind(this);
        this.highlightFeature = this.highlightFeature.bind(this);
        this.resetHighlight = this.resetHighlight.bind(this);
        this.zoomToFeature = this.zoomToFeature.bind(this);

        // Create map
        this._map = L.map(`leaflet-${options.id}`, options.options);
        L.tileLayer(options.layerURL, options.layerOptions).addTo(this._map);

        // Info popup
        this._tooltip = L.control();
        this._tooltip.onAdd = function(map){
            this._div = L.DomUtil.create('div', 'info');
            this.update();
            return this._div;
        };
        this._tooltip.update = function(props){
            this._div.style.display = props ? 'block' : 'none';
            this._div.innerHTML = props ? props.tooltip : '';
        };
        this._tooltip.addTo(this._map);

        // Legend
        this._legend = L.control({position: 'bottomright'});
        this._legend.onAdd = (map)=>{
            this._legendDiv = L.DomUtil.create('div', 'info map-legend');
            this._legendDiv.innerHTML = 'Légende';
            return this._legendDiv;
        };
        this._legend.addTo(this._map);

        // Detect zoom change and drag
        this._map.on('zoomend', this.onMapViewChange);
        this._map.on('moveend', this.onMapViewChange);

        // Use for debugging (to delete)
        this._map.on('click', (e)=>{
            RPGM.sendMessage('r', 'leaflet/click', {
                lat: e.latlng.lat,
                lng: e.latlng.lng
            });
        });
    }

    /**
     * This function is called when the user changes the zoom or drag the map.
     * It debounces the call to R by setting a timer.
     */
    onMapViewChange(){
        if(this._debouncer !== null){
            clearTimeout(this._debouncer);
        }
        this._debouncer = setTimeout(this.sendChange, 200); // 200ms
    }

    /**
     * Actually send the map state to R.
     */
    sendChange(){
        RPGM.sendMessage('r', 'mapState', {
            view: {
                northLat: this._map.getBounds().getNorth(),
                eastLng: this._map.getBounds().getEast(),
                southLat: this._map.getBounds().getSouth(),
                westLng: this._map.getBounds().getWest(),
                zoomLevel: this._map.getZoom()
            }
        });
    }

    addGeoJSON(points, id, tooltip, color){
        this._queueGeoJSON.push({points, id, tooltip, color});
    }

    drawGeoJSON(geojson){
        if(this._lastGeoJSON){
            this._lastGeoJSON.remove();
        }
        
        const finalGeo = ({
            type: "FeatureCollection",
            features: this._queueGeoJSON.map(e => {
                let isMultiple = false;
                try {
                    isMultiple = Array.isArray(e.points[0][0]);
                }
                catch{
                    isMultiple = false;
                }
                
                const oo = {
                    type: "Feature",
                    properties: {
                        id: `${e.id}`,
                        color: e.color,
                        tooltip: e.tooltip
                    },
                    geometry: {
                        type: isMultiple ? "MultiPolygon" : "Polygon",
                        coordinates: isMultiple ? e.points.map(p => [p]) : [e.points]
                    }
                };
                return oo;
            })
        });
        this._queueGeoJSON = [];

        this._lastGeoJSON = L.geoJson(finalGeo, {
            style: (feature)=>{
                return {
                    fillColor: feature.properties.color,
                    opacity: 1,
                    color: 'white',
                    dashArray: 3,
                    fillOpacity: 0.6
                }
            },
            onEachFeature: (feature, layer)=>{
                layer.on({
                    mouseover: this.highlightFeature,
                    mouseout: this.resetHighlight,
                    click: this.zoomToFeature
                });
            }
        });
        this._lastGeoJSON.addTo(this._map);
    }
    highlightFeature(e){
        const layer = e.target;
        layer.setStyle({
            weight: 5,
            color: '#666',
            dashArray: '',
            fillOpacity: 0.7
        });
        layer.bringToFront();
        this._mapInfo.update(layer.feature.properties);
    }
    resetHighlight(e){
        this._lastGeoJSON.resetStyle(e.target);
        this._mapInfo.update();
    }
    zoomToFeature(e){
        RPGM.sendMessage('r', 'zoneClick', {
            id: e.target.feature.properties.id,
            zoomLevel: this._map.getZoom(),
            tooltip: e.target.feature.properties.tooltip
        });
    }
    updateLegend(content){
        this._legendDiv.innerHTML = content;
    }

    updateMarkers(markers){
        this._markers.map(m => m.remove());
        this._markers = [];
        markers.forEach(m => {
            const newMarker = L.marker([m.lat, m.lng], {icon: this._markerIcon});
            newMarker.bindPopup(m.label);
            newMarker.on('mouseover',function(ev){
                newMarker.openPopup();
            });
            newMarker.addTo(this._map);
            this._markers.push(newMarker);
        });
    }
}

/**
 * This class manages the leaflet map.
 */
window.MapManager = new class {
    constructor(){
        /** Leaflet map pointer */
        this._map = null;
        this._mapInfo = null;
        this._markerIcon = null;

        /** All draw stuff */
        this._queueGeoJSON = [];
        this._lastGeoJSON = null;
        this._markers = [];

        /** Timer to not send too much changes to RPGM */
        this._debouncer = null;

        /** JS binding */
        this.sendChange = this.sendChange.bind(this);
        this.initializeMap = this.initializeMap.bind(this);
        this.onMapViewChange = this.onMapViewChange.bind(this);
        this.highlightFeature = this.highlightFeature.bind(this);
        this.resetHighlight = this.resetHighlight.bind(this);
        this.zoomToFeature = this.zoomToFeature.bind(this);
    }

    /**
     * Initialize script
     */
    initialize(){
        RPGM.on('didEnterStep', this.initializeMap); // Function called when entered a new step
        RPGM.on('didReceiveMessage', (message, data)=>{
            if(message === 'addGeoJSON'){
                this.addGeoJSON(data.points, data.id, data.tooltip, data.color);
            }
            else if(message === 'drawGeoJSON'){
                this.drawGeoJSON();
            }
            else if(message === 'updateLegend'){
                this.updateLegend(data.content);
            }
            else if(message === 'updateMap'){
                this.sendChange();
                if (typeof data.empreinte !== 'undefined')
                {
                    RPGM.sendMessage('r', 'loadDonneesContinue', {
                        empreinte: data.empreinte,
                        lastShapeContinue: data.lastShapeContinue
                    });
                }
            }
            else if(message === 'updateMarkers'){
                this.updateMarkers(data.markers);
            }
            else if(message === 'resetView'){
                this._map.setView([48., 2.], 5);
            }
        });
    }

    /**
     * Initialize the map
     */
    async initializeMap(stepId){
        // Stop if the user is not in the correct GUI
        if(stepId !== 'leaflet'){
            return;
        }

        // Stop if already initialized
        if(this._map !== null){
            return;
        }

        // Initialize map
        await wait(10);
        this._map = L.map('map');
        this._map.setView([48., 2.], 5);
//      Lien pour les fonds de carte libres : https://leaflet-extras.github.io/leaflet-providers/preview/
//        const tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        const tiles = L.tileLayer('http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(this._map);

        // Icon
        this._markerIcon = L.icon({
            iconUrl:      RPGM.getOutputURL('icon.png'),
            iconSize:     [48, 48],
            iconAnchor:   [24, 48],
            popupAnchor:  [0, -48]
        });

        // Info popup
        this._mapInfo = L.control();
        this._mapInfo.onAdd = function(map){
            this._div = L.DomUtil.create('div', 'info'); // create a div with a class "info"
            this.update();
            return this._div;
        };
        this._mapInfo.update = function(props){
            this._div.innerHTML = props ? props.tooltip : 'Survoler une zone';
        };
        this._mapInfo.addTo(this._map);

        // Legend
        this._legend = L.control({position: 'bottomright'});
        this._legend.onAdd = (map)=>{
            this._legendDiv = L.DomUtil.create('div', 'info map-legend');
            this._legendDiv.innerHTML = 'Légende';
            return this._legendDiv;
        };
        this._legend.addTo(this._map);

        // Detect zoom change and drag
        this._map.on('zoomend', this.onMapViewChange);
        this._map.on('moveend', this.onMapViewChange);

        // First change
        //this.onMapViewChange();

        // Use for debugging (to delete)
        this._map.on('click', (e)=>{
            RPGM.sendMessage('r', 'mapClick', {
                coordinates: {
                    lat: e.latlng.lat,
                    lng: e.latlng.lng
                }
            });
        });
    }

    /**
     * This function is called when the user changes the zoom or drag the map.
     * It debounces the call to R by setting a timer.
     */
    onMapViewChange(){
        if(this._debouncer !== null){
            clearTimeout(this._debouncer);
        }
        this._debouncer = setTimeout(this.sendChange, 200); // 200ms
    }

    /**
     * Actually send the map state to R.
     */
    sendChange(){
        RPGM.sendMessage('r', 'mapState', {
            view: {
                northLat: this._map.getBounds().getNorth(),
                eastLng: this._map.getBounds().getEast(),
                southLat: this._map.getBounds().getSouth(),
                westLng: this._map.getBounds().getWest(),
                zoomLevel: this._map.getZoom()
            }
        });
    }

    // ---------------------------------------------------------
    // 3. GEOJSON SYSTEM
    // ---------------------------------------------------------
    addGeoJSON(points, id, tooltip, color){
        this._queueGeoJSON.push({points, id, tooltip, color});
    }
    drawGeoJSON(geojson){
        if(this._lastGeoJSON){
            this._lastGeoJSON.remove();
        }
        
        const finalGeo = ({
            type: "FeatureCollection",
            features: this._queueGeoJSON.map(e => {
                let isMultiple = false;
                try {
                    isMultiple = Array.isArray(e.points[0][0]);
                }
                catch{
                    isMultiple = false;
                }
                
                const oo = {
                    type: "Feature",
                    properties: {
                        id: `${e.id}`,
                        color: e.color,
                        tooltip: e.tooltip
                    },
                    geometry: {
                        type: isMultiple ? "MultiPolygon" : "Polygon",
                        coordinates: isMultiple ? e.points.map(p => [p]) : [e.points]
                    }
                };
                return oo;
            })
        });
        this._queueGeoJSON = [];

        this._lastGeoJSON = L.geoJson(finalGeo, {
            style: (feature)=>{
                return {
                    fillColor: feature.properties.color,
                    opacity: 1,
                    color: 'white',
                    dashArray: 3,
                    fillOpacity: 0.6
                }
            },
            onEachFeature: (feature, layer)=>{
                layer.on({
                    mouseover: this.highlightFeature,
                    mouseout: this.resetHighlight,
                    click: this.zoomToFeature
                });
            }
        });
        this._lastGeoJSON.addTo(this._map);
    }
    highlightFeature(e){
        const layer = e.target;
        layer.setStyle({
            weight: 5,
            color: '#666',
            dashArray: '',
            fillOpacity: 0.7
        });
        layer.bringToFront();
        this._mapInfo.update(layer.feature.properties);
    }
    resetHighlight(e){
        this._lastGeoJSON.resetStyle(e.target);
        this._mapInfo.update();
    }
    zoomToFeature(e){
        RPGM.sendMessage('r', 'zoneClick', {
            id: e.target.feature.properties.id,
            zoomLevel: this._map.getZoom(),
            tooltip: e.target.feature.properties.tooltip
        });
    }
    updateLegend(content){
        this._legendDiv.innerHTML = content;
    }

    updateMarkers(markers){
        this._markers.map(m => m.remove());
        this._markers = [];
        markers.forEach(m => {
            const newMarker = L.marker([m.lat, m.lng], {icon: this._markerIcon});
            newMarker.bindPopup(m.label);
            newMarker.on('mouseover',function(ev){
                newMarker.openPopup();
            });
            newMarker.addTo(this._map);
            this._markers.push(newMarker);
        });
    }
}
MapManager.initialize();