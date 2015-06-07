// Begin configurable section.

var google_api_key = "AIzaSyD0tmoXx3oJAPITndZR4f3I5GcnV-Jram4";
var pitch = 0; // In streetview, angle with respect to the horizon.

var logging_level = INFO;

var step;
var direction;

var map;
var marker;
var current_zoom = 15;

var current_lat;
var current_long;

var iconMarker;
var sizeForAllIcons = [25, 30];

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

    $.getJSON("latlonglookup.json", function(latlonglookup) {

      $.getJSON("http://www.civicdata.com/api/action/datastore_search?resource_id=46ec0807-31ff-497f-bfa0-f31c796cdee8", function(buildingdata_page1) {

          var all_buildings = buildingdata_page1['result']['records'];

          // Below code will show all unique building descriptions if uncommented
          //building_descriptions = _.map(all_buildings, function(building) { return building['Description'] } );
          //unique_building_descriptions = _.uniq(building_descriptions);
          //_.each(unique_building_descriptions, function(d) { console.log(d); } );

          $.each(all_buildings, function(index,item){
              var key = item['PermitNumber'];
              var latlong = latlonglookup[key];

              //fetch icon depending on description
	      // TODO
	      //              var status = getStatus(item['Description']);

	      var softStoryIcon = L.icon({
		  iconUrl: 'img/softStory.png',
		  iconRetinaUrl: 'img/softStory@2x.png',
		  iconSize: sizeForAllIcons,
	      });

	      var BuildingIcon = softStoryIcon;

              L.marker(latlong, {icon: BuildingIcon}).addTo(map).bindPopup(item['StreetAddress'] + '<br><br>');
            });
      });
    });


    
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

