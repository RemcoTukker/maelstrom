window.vesselUrl = 'http://141.176.110.144:8180/json/hackaton/';

status = $('#status')
log = $('#log')

window.movementImpact = (vessel) ->
  factors =
    length: 1.5
    grossTonnage: 0.05

  vessel['length'] * factors['length'] + vessel['grossTonnage'] * factors['grossTonnage']

window.getVesselPosisitions = () ->

  window.berthMovements = {}
  window.berths = {}
  window.positions = []

  $.getJSON vesselUrl + 'vesselpositions', (data, textStatus, jqXHR) ->

    i = 0
    for position in data

      i = i + 1

      pos = CoordinateConversion.rd2Wgs position.position['x'], position.position['y']

      window.positions.push pos

      $.getJSON vesselUrl + 'vesselvisits/' + position.vesselId, (data, textStatus, jqXHR) ->

        unless data[0]?
          return

        vesselId = data[0]['vessel']['id']
        movements = data[0]['movements']

        for movement in movements

          if movement['berthVisitArrival']
            etaBerth = movement['berthVisitArrival']['etaBerth']
            etdBerth = movement['berthVisitArrival']['etdBerth']
            weight = window.movementImpact data[0]['vessel']

            berth = movement['berthVisitArrival']['berth']
            berth['movement'] = true
            window.berths[berth['id']] ?= berth

            window.berthMovements[etaBerth] ?= []
            window.berthMovements[etaBerth].push
              eta: etaBerth,
              etd: etdBerth,
              weight: weight,
              type: 'arrival',
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
            window.berths[berth['id']] ?= berth

            window.berthMovements[etdBerth] ?= []
            window.berthMovements[etdBerth].push
              eta: etaBerth,
              etd: etdBerth,
              weight: weight,
              type: 'departure',
              berth:
                id: berth['id'],
                x: berth['x'],
                y: berth['y']




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

window.getMovementsForBerth = (from, till, berth) ->

  movements = getMovements from, till

  movements.filter (movement) ->
    movement.berth.id == berth


window.plotBerths = () ->

  window.markers ?= {}
  for berth_id in Object.keys(window.berths)

    berth = window.berths[berth_id]

    position = CoordinateConversion.rd2Wgs(berth.x, berth.y)
    pos = new google.maps.LatLng position['latitude'], position['longitude']

    icon = 'img/pin_gray.png'

    if berth['movement']?
      icon = 'img/pin.png'

    marker = new google.maps.Marker
      position: pos,
      map: window.google_map,
      title: berth_id #,
      icon: icon

    window.markers[berth_id] = marker
    google.maps.event.addListener marker, 'click', () ->
      # console.log 'Clicked marker', marker.title
      console.log 'Click op', parseInt(this.title)
      window.drawTimeLineForBerth parseInt(this.title)

  $.event.trigger('timerange_change', [$('#slider-range').slider('values', 0), $('#slider-range').slider('values', 1)])


window.removeBerths = () ->
  for id in Object.keys(window.markers)
    window.markers[id].setMap null
  window.markers = {}

window.drawTimeLineForBerth = (berth) ->

  berth_object = window.berths[berth]

  $('#berth_title').text 'Timeline for berth ' + berth_object['id'] + ': ' + berth_object['berthName']

  from_range = $('#slider-range').slider 'values', 0
  till_range = $('#slider-range').slider 'values', 1

  from = 0
  till = Infinity
  events = window.getMovementsForBerth from, till, berth

  data = []

  for berthEvent, index in events

    eta = berthEvent['eta']
    etd = berthEvent['etd']

    type = berthEvent['type']

    if type is 'departure'
      continue

    if etd?
      data.push
        start: eta,
        end: etd,
        content: type
    else
      data.push
        start: eta,
        content: type


  window.timeline = new links.Timeline($('#mytimeline')[0])
  options =
    width: '100%',
    height: '300px',
    # min: from,
    # max: till,
    style: 'box'

  # console.log data
  window.timeline.draw data, options
  window.timeline.setVisibleChartRange( new Date(from_range), new Date(till_range) )



$('#berths').on 'click', () ->
  if $(this).data('enabled') is 0
    window.plotBerths()
    $(this).data 'enabled', 1
  else
    window.removeBerths()
    $(this).data 'enabled', 0

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




jQuery ->

  # google.load "visualization", "1"

  window.getVesselPosisitions()

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
        # weight: 1

      if window.markers?
        if window.markers[ movement['berth']['id']]?
         window.markers[ movement['berth']['id']].setIcon 'img/pin.png'
         marker.setZIndex Infinity


