var map, heatmap, pointarray;

var data
var time

var running = false;
var unlock = false;
var nextPoint = 0;
//  MAP STYLE
var styles = [
  {
    "featureType": "administrative",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },{
    "featureType": "poi",
    "stylers": [
      { "visibility": "off" }
    ]
  },{
    "featureType": "road",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },{
    "featureType": "water",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },{
    "featureType": "transit",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },{
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [
      { "visibility": "on" },
      { "saturation": 100 },
      { "hue": "#00a1ff" },
      { "gamma": 0.43 }
    ]
  },{
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      { "hue": "#ff0000" },
      { "saturation": -100 },
      { "lightness": 100 },
      { "visibility": "off" }
    ]
  },{
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      { "visibility": "on" }
    ]
  },{
  }
]

//  BUILD DATA ARRAY
var heatData = new Array();
for (var i = 0;i<600;i++)
  {
    heatData[i] = {"date": i,
                   "coords": [51.8+0.3*Math.random(),3.93+0.8*Math.random()],
                   "weight": Math.random()}
  };

// INITIALIZE MAP
function initialize() {

  window.heat_data = new google.maps.MVCArray();

  map = new google.maps.Map(document.getElementById('map-canvas'),{
    zoom: 11,
    center: new google.maps.LatLng(51.925, 4.3),
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    scrollwheel: false,
    streetViewControl: false,
    mapTypeControl: false,
    styles: styles
  });

  window.google_map = map;

  heatmap = new google.maps.visualization.HeatmapLayer({
    map: map,
    data: window.heat_data,
    radius: 30,
    maxIntensity: 10000
  });

  google.maps.event.addListener(map, 'tilesloaded', function() {
    unlock = true;
  });
}

// MAP FUNCTIONS
function toggleHeatmap() {
  heatmap.setMap(heatmap.getMap() ? null : map);
}

function changeRadius() {
  heatmap.setOptions({radius: heatmap.get('radius') ? null : 40});
}

function changeOpacity() {
  heatmap.setOptions({opacity: heatmap.get('opacity') ? null : 0.4});
}

// MAP ANIMATION SETTINGS
function startAnimation() {
  if (unlock && ! running) {
    running = true;
    mapAnimate();
  }
}

function stopAnimation() {
  running = false;
}

function resetAnimation() {
    console.log("reset");
}

// function mapAnimate() {
//   if (!running) {
//     return;
//   }
//   time =


function updateDataset(tmin,tmax) {

  window.heat_data.clear();
  $.event.trigger('timerange_change', [tmin, tmax]);

  // console.log(tmin,tmax);
  // if (! running) {
  //   return;
  // }
  // for(var i=tmin;i<tmax;i++)
  // while (heatData[nextPoint].date < time) {
  //   window.heat_data.push(new google.maps.LatLng(heatData[nextPoint].coords[0], heatData[nextPoint].coords[1]));
  //   nextPoint++;
  // }
}

$(function() {
  $( "#slider-range" ).slider({
    range: true,
    // min: Math.round(new Date().getTime() / 1) - (3600 * 24),
    min: 1342699200000,
    // max: Math.round(new Date().getTime() / 1)+(60*60*48) - (3600 * 24),
    max: 1379651003000,
    // values: [Math.round(new Date().getTime() / 1) - (3600 * 24), Math.round(new Date().getTime() / 1)+(60*60*2) - (3600*24)],
    values: [1342699200000, 1342699200000 + (3600*48*1000)],
    slide: function( event, ui ) {
      $( "#amount" ).val(ui.values[ 0 ] + " - " + ui.values[ 1 ]);
    },
    change: function( event, ui ) {
      console.log("change");
      updateDataset(ui.values[0],ui.values[1]);
    }
  });
  $( "#amount" ).val($( "#slider-range" ).slider( "values", 0 ) + " - " + $( "#slider-range" ).slider( "values", 1 ));
});
