window.vesselUrl = '/haven_data/'

status = $('#status')
log = $('#log')

# Calculate the impact for the heatmap of a movement for a specific vessel
window.movementImpact = (vessel) ->
  factors =
    length: 1.5
    grossTonnage: 0.05

  vessel['length'] * factors['length'] + vessel['grossTonnage'] * factors['grossTonnage']

# Aggregate all information
window.getVesselPosisitions = () ->

  window.berthMovements = {}
  window.berths = {}
  window.positions = []

  $.getJSON vesselUrl + 'vesselpositions', (data, textStatus, jqXHR) ->

    for position in data

      pos = CoordinateConversion.rd2Wgs position.position['x'], position.position['y']

      window.positions.push pos

      $.getJSON vesselUrl + 'vesselvisits/' + position.vesselId, (data, textStatus, jqXHR) ->

        unless data[0]?
          return

        vesselId = data[0]['vessel']['id']
        movements = data[0]['movements']

        for movement in movements
          #TODO: tidy up this loop!
          if movement['berthVisitArrival']
            etaBerth = movement['berthVisitArrival']['etaBerth']
            etdBerth = movement['berthVisitArrival']['etdBerth']
            weight = window.movementImpact data[0]['vessel']

            berth = movement['berthVisitArrival']['berth']
            berth['movement'] = true
            berth['pos'] = CoordinateConversion.rd2Wgs berth['x'], berth['y']
            berth['latlong'] = new google.maps.LatLng berth.pos['latitude'], berth.pos['longitude']
            window.berths[berth['id']] ?= berth

            window.berthMovements[etaBerth] ?= []
            window.berthMovements[etaBerth].push
              eta: etaBerth,
              etd: etdBerth,
              weight: weight,
              type: 'arrival',
              shipName: data[0]['shipNameDuringVisit'],
              berth:
                id: berth['id'],
                x: berth['x'],
                y: berth['y'],

          if movement['berthVisitDeparture']

            etaBerth = movement['berthVisitDeparture']['etaBerth']
            etdBerth = movement['berthVisitDeparture']['etdBerth']
            weight = window.movementImpact data[0]['vessel']

            berth = movement['berthVisitDeparture']['berth']
            berth['movement'] = true
            berth['pos'] = CoordinateConversion.rd2Wgs berth['x'], berth['y']
            berth['latlong'] = new google.maps.LatLng berth.pos['latitude'], berth.pos['longitude']
            window.berths[berth['id']] ?= berth

            window.berthMovements[etdBerth] ?= []
            window.berthMovements[etdBerth].push
              eta: etaBerth,
              etd: etdBerth,
              weight: weight,
              type: 'departure',
              shipName: data[0]['shipNameDuringVisit'],
              berth:
                id: berth['id'],
                x: berth['x'],
                y: berth['y']

# Get all the movements within a specific time range
window.getMovements = (from, till) ->

  keys = Object.keys(window.berthMovements)
  events = []
  movementsInRange = for key, value of keys

    value = parseInt value

    if value >= from and value <= till
      for movement in window.berthMovements[value]

        movement['coordinate'] = CoordinateConversion.rd2Wgs movement['berth']['x'], movement['berth']['y']

        events.push movement
    else
      continue

  return events

# Get all the movements within a specific time range for a specific berth
window.getMovementsForBerth = (from, till, berth) ->

  movements = getMovements from, till

  movements.filter (movement) ->
    movement.berth.id == berth

# Plot all the berths on the map
window.plotBerths = () ->

  window.markers ?= {}
  for berth_id in Object.keys(window.berths)

    berth = window.berths[berth_id]

    icon = 'img/pin_gray.png'

    # Use the red pin when there is movement in the current time range for this berth
    if berth['movement']?
      icon = 'img/pin.png'

    marker = new google.maps.Marker
      position: berth.latlong,
      map: window.google_map,
      title: berth_id #,
      icon: icon

    window.markers[berth_id] = marker

    google.maps.event.addListener marker, 'click', () ->
      window.drawTimeLineForBerth parseInt(this.title)

  $.event.trigger('timerange_change', [$('#slider-range').slider('values', 0), $('#slider-range').slider('values', 1)])

# Remove all the berths from the map
window.removeBerths = () ->
  for id in Object.keys(window.markers)
    window.markers[id].setMap null
  window.markers = {}

# Draw all the events on the timeline for a specific berth
window.drawTimeLineForBerth = (berth) ->

  berth_object = window.berths[berth]

  #find nearby berths based on distance, in this case 500 meter
  nearby_berths = (other_berth for berth_id, other_berth of window.berths when google.maps.geometry.spherical.computeDistanceBetween(other_berth.latlong, berth_object.latlong) < 500)

  $('#berth_title').text 'Timeline for berth ' + berth_object['id'] + ': ' + berth_object['berthName']

  from_range = $('#slider-range').slider 'values', 0
  till_range = $('#slider-range').slider 'values', 1

  from = 0
  till = Infinity
  events = window.getMovementsForBerth from, till, berth
  
  #get the events from the nearby berths, but not from the current berth 
  #TODO: change this, no need to retreive events seperately, only to add them differently to the timeline
  nearby_events = (window.getMovementsForBerth from, till, otherberth.id for otherberth in nearby_berths when otherberth.id isnt berth)

  #add the events per berth to the events array
  events = events.concat nearby_berth_events for nearby_berth_events in nearby_events

  data = []

  for berthEvent, index in events

    eta = berthEvent['eta']
    etd = berthEvent['etd']

    type = berthEvent['type']

    #todo: fix this properly, keep eta's and etd's associated somewhere!
    if type is 'departure'
      continue

    type = type + ': ' + berthEvent['shipName']

    console.log berthEvent.berth.id == berth

    if etd?
      if berthEvent.berth.id == berth
        data.push
          start: eta,
          end: etd,
          content: type,
          className: "ourtraject"
      else
        data.push
          start: eta,
          end: etd,
          content: type,
          className: 'othertraject'
    else
      if berthEvent.berth.id == berth
        data.push
          start: eta,
          content: type,
          className: 'ourarrival'
      else
        data.push
          start: eta,
          content: type,
          className: 'otherarrival'

  window.timeline = new links.Timeline($('#mytimeline')[0])
  options =
    width: '100%',
    height: '300px',
    style: 'box'

  window.timeline.draw data, options
  window.timeline.setVisibleChartRange( new Date(from_range), new Date(till_range) )


# Toggle the drawing of berths
$('#berths').on 'click', () ->
  if $(this).data('enabled') is 0
    window.plotBerths()
    $(this).data 'enabled', 1
  else
    window.removeBerths()
    $(this).data 'enabled', 0

# Toggle the drawing of the heatmap
$('#ships').on 'click', () ->
  if $(this).data('enabled') is 0
    for position in window.positions
      window.heat_data.push
        location: new google.maps.LatLng position['latitude'], position['longitude']
        weight: 100
      $(this).data 'enabled', 1
  else
    window.heat_data.clear()
    $.event.trigger('timerange_change', [$('#slider-range').slider('values', 0), $('#slider-range').slider('values', 1)])
    $(this).data 'enabled', 0



# Onload:
jQuery ->

  # Fetch all vessel information and process it (note: this should have a callback mechanism)
  window.getVesselPosisitions()

  # Redraw when slider changes
  $(document).bind 'timerange_change', (e, from, till) ->

    movements = window.getMovements from, till

    if window.markers?
      for id in Object.keys(window.markers)
        marker = window.markers[id]
        marker.setIcon 'img/pin_gray.png'
        marker.setZIndex 1

    for movement in movements
      window.heat_data.push
        location: new google.maps.LatLng(movement['coordinate']['latitude'], movement['coordinate']['longitude']),
        weight: movement['weight']

      if window.markers?
        if window.markers[ movement['berth']['id']]?
         window.markers[ movement['berth']['id']].setIcon 'img/pin.png'
         marker.setZIndex Infinity
