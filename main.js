/**
 * This class manages the leaflet map.
 */
window.MapManager = new class {
    constructor(){
        /** Leaflet map pointer */
        this._map = null;
        this._mapInfo = null;

        /** All draw stuff */
        this._queuedDrawings = [];
        this._mapDrawing = [];

        this._queueGeoJSON = [];
        this._lastGeoJSON = null;

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
        RPGM.on('didReceiveJavascriptMessage', (message, data)=>{
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
            }
            else if(message === 'resetView'){
                this._map.setView([48.866667, 2.333333], 5);
            }
        });
        this.initializeMap(); // Try to initialize now for RPGM Server
    }

    /**
     * Initialize the map
     */
    initializeMap(){
        // Stop if the user is not in the correct GUI
        if(RPGM.getCurrentStepId() !== 'leaflet'){
            return;
        }

        // Stop if already initialized
        if(this._map !== null){
            return;
        }

        // Initialize map
        this._map = L.map('map');
        this._map.setView([48.866667, 2.333333], 5);
        const tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(this._map);

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
            this._legendDiv = L.DomUtil.create('div', 'info legend');
            this._legendDiv.innerHTML = 'Légende';
            return this._legendDiv;
        };
        this._legend.addTo(this._map);

        // Detect zoom change and drag
        this._map.on('zoomend', this.onMapViewChange);
        this._map.on('moveend', this.onMapViewChange);

        // First change
        this.onMapViewChange();

        // Use for debugging (to delete)
        this._map.on('click', (e)=>{
            RPGM.sendToLanguage('r', 'mapClick', {
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
        RPGM.sendToLanguage('r', 'mapState', {
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
    // 1. SIMPLE POLYGON SYSTEM
    // ---------------------------------------------------------
    /*
    addPolygon(points, color){
        const draw = L.polygon(points, {color});
        draw.addTo(this._map);
        this._mapDrawing.push(draw);
    }
    removeAllDrawings(){
        this._mapDrawing.forEach(d => d.remove());
    }
    */

    // ---------------------------------------------------------
    // 2. QUEUE SYSTEM
    // ---------------------------------------------------------
    /*
    clearQueue(){
        this._queuedDrawings = [];
    }
    addToQueue(points, color){
        this._queuedDrawings.push(L.polygon(points, {color}));
    }
    drawQueue(){
        this.removeAllDrawings();
        this._mapDrawing = this._queuedDrawings;
        this.clearQueue();
        this._mapDrawing.forEach(d => d.addTo(this._map));
    }
    */

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
        RPGM.sendToLanguage('r', 'zoneClick', {
            id: e.target.feature.properties.id,
            zoomLevel: this._map.getZoom(),
            tooltip: e.target.feature.properties.tooltip
        });
    }
    updateLegend(content){
        this._legendDiv.innerHTML = content;
    }
}
MapManager.initialize();