// Begin configurable section.

var google_api_key = "AIzaSyD0tmoXx3oJAPITndZR4f3I5GcnV-Jram4";
var pitch = 0; // In streetview, angle with respect to the horizon.
// How much to increment the score for a correct answer 
// or decrement for a "I don't know".
var score_increment = 10; 
var useProfilePicAsMarker = true;

// End Configurable section.

// every X milliseconds, decrement remaining time to answer this question on a tour.
var tour_question_decrement_interval = 5000;

var logging_level = INFO;

var step;
var direction;

var map;
var marker;
var current_zoom = 17;

var current_lat;
var current_long;

var iconMarker;

function start_tour() {
    current_lat = 37.7996525;
    current_long = -122.2765788;
    heading = 0;

    map = L.map('map').setView([current_lat, current_long], current_zoom);

    L.tileLayer('https://{s}.tiles.mapbox.com/v3/{id}/{z}/{x}/{y}.png', {
	maxZoom: 18,
	attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
	    '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
	    'Imagery © <a href="http://mapbox.com">Mapbox</a>',
	id: 'examples.map-i875mjb7'
    }).addTo(map);

    var profileIcon = L.icon({
	iconSize:     [16, 16], // size of the icon
	shadowSize:   [30, 30], // size of the shadow
	iconAnchor:   [7.5, 35], // point of the icon which will correspond to marker's location
	shadowAnchor: [4, 62],  // the same for the shadow
	popupAnchor:  [-18, -25] // point from which the popup should open relative to the iconAnchor
    });

    marker = L.marker([current_lat, current_long]).addTo(map).openPopup();

    var popup = L.popup();
    
    // initialize streetview
    $("#streetviewiframe").attr("src","https://www.google.com/maps/embed/v1/streetview?key="+google_api_key+"&location="+current_lat+","+current_long+"&heading="+heading+"&pitch="+pitch+"&fov=35");

    function onMapClick(e) {
	marker.setLatLng(e.latlng);
	current_lat = e.latlng.lat;
	current_long = e.latlng.lng;
	
	$("#streetviewiframe").attr("src","https://www.google.com/maps/embed/v1/streetview?key="+google_api_key+"&location="+current_lat+","+current_long+"&heading="+heading+"&pitch="+pitch+"&fov=35");

	
    }
    
    map.on('click', onMapClick);

    
    tour_loop();
}

function tour_loop() {
}

var answer_info = {};
var correct_answers = [];

function update_map(question,correct_answer,target_language,target_locale) {    
    L.circle([current_lat, 
	      current_long], 10, {
	color: 'lightblue',
	fillColor: 'green',
	fillOpacity: 0.5
    }).addTo(map).bindPopup(question + " &rarr; <i>" + correct_answer + "</i><br/>" + "<tt>["+current_lat+","+current_long+"]</tt>")
    step = step + direction;

    var path = tour_paths[target_language][target_locale];
    navigate_to(step,path,true);
}

function navigate_to(step,path,do_encouragement) {
    log(DEBUG,"NAVIGATE TO: " + path);
    heading = get_heading(path,step);

    current_lat = path[step][0];
    current_long = path[step][1];

    get_quadrant(path,step);

    // update the background OpensStreetMaps position:
    map.panTo(path[step]);
   
    // update the marker on the background OpenStreetMaps too:
    marker.setLatLng(path[step]);
    if (do_encouragement == true) {
	var encouragement = Math.floor(Math.random()*encouragements.length);
	marker.setPopupContent("<b>" + encouragements[encouragement] + 
			       "</b> " + step + "/" + path.length);
    }
    if (iconMarker != undefined) {
	iconMarker.setLatLng(path[step]);
    }

    // update Google streetview:
    $("#streetviewiframe").attr("src","https://www.google.com/maps/embed/v1/streetview?key="+google_api_key+"&location="+current_lat+","+current_long+"&heading="+heading+"&pitch="+pitch+"&fov=35");
}
