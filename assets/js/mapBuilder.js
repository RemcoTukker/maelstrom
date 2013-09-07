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

  google.maps.event.addListener(window.google_map, 'zoom_changed', function() {
    changeRadius(40 * Math.pow(1.5,(window.google_map.getZoom() - 11) ));
  });

  heatmap = new google.maps.visualization.HeatmapLayer({
    map: map,
    data: window.heat_data,
    radius: 40
    // maxIntensity: 1000
  });

  google.maps.event.addListener(map, 'tilesloaded', function() {
    unlock = true;
  });
}

// MAP FUNCTIONS
function toggleHeatmap() {
  heatmap.setMap(heatmap.getMap() ? null : map);
}

function changeRadius(radius) {
  heatmap.setOptions({radius: radius});
}

function changeOpacity() {
  heatmap.setOptions({opacity: heatmap.get('opacity') ? null : 0.4});
}

// MAP ANIMATION SETTINGS
function startAnimation() {
  if (unlock && ! running) {
    running = true;
    animateMap();
  }
}

function stopAnimation() {
  running = false;
}

function resetAnimation() {
    console.log("reset");
    tmin = 1378011600000;
    tmax = 1378011600000 + (3600*5*1000);
    $('#slider-range').slider('values', [tmin, tmax]);
}

function nextHour() {
  if (! running) {
    return;
  }
  if (tmax > simTime) {
    running = false;
    return;
  }
  else {
    tmin = tmin + (60*60*1000);
    tmax = tmax + (60*60*1000);
    $( "#slider-range" ).slider({
      values: [tmin, tmax]
    })
    setTimeout(nextHour, 100);
  }
}

function animateMap() {
  console.log("starting animation");
  tmin = $( "#slider-range" ).slider( "values", 0 );
  tmax = $( "#slider-range" ).slider( "values", 1 );

  simTime = new Date().getTime() + (60*60*48*1000);

  nextHour();
}


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

function pad(num, size) {
    var s = num+"";
    while (s.length < size) s = "0" + s;
    return s;
}

function printDate(d) {
  var curr_date = pad(d.getDate(),2);
  var curr_month = pad(d.getMonth()+1,2);
  var curr_year = d.getFullYear();
  var curr_hour = pad(d.getHours(), 2);
  var curr_min  = pad(d.getMinutes(), 2);

  var datestring = "" + curr_date + "-" + curr_month + "-" + curr_year + " " + curr_hour + ":" + curr_min;
  return datestring
}

$(function() {
  $( "#slider-range" ).slider({
    range: true,
    // min: Math.round(new Date().getTime() / 1) - (3600 * 24),
    min: 1378011600000,
    // max: Math.round(new Date().getTime() / 1)+(60*60*48) - (3600 * 24),
    max: 1378566904000,
    // values: [Math.round(new Date().getTime() / 1) - (3600 * 24), Math.round(new Date().getTime() / 1)+(60*60*2) - (3600*24)],
    values: [1378011600000, 1378011600000 + (3600*20*1000)],
    slide: function( event, ui ) {
      $( "#amount" ).val(printDate(new Date(ui.values[0])) + "   -   " + printDate(new Date(ui.values[1])));
    },
    change: function (event, ui ) {
      updateDataset(ui.values[0],ui.values[1]);
      printDate(new Date(ui.values[0]));
      $( "#amount" ).val(printDate(new Date(ui.values[0])) + "   -   " + printDate(new Date(ui.values[1])));
    }
  });
  $( "#amount" ).val(printDate(new Date($( "#slider-range" ).slider( "values", 0 ))) + "  -  " + printDate(new Date($( "#slider-range" ).slider( "values", 1 ))));
});
