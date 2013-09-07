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

  $.getJSON vesselUrl + 'vesselpositions', (data, textStatus, jqXHR) ->

    status.text 'Vessel positions received'
    i = 0
    for position in data

      # if i > 50
        # break

      i = i + 1

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
  console.log 'test'

  for berth_id in Object.keys(window.berths)

    berth = window.berths[berth_id]
    console.log berth
    position = CoordinateConversion.rd2Wgs(berth.x, berth.y)
    pos = new google.maps.LatLng position['latitude'], position['longitude']

    marker = new google.maps.Marker
      position: pos,
      map: window.google_map,
      title: berth_id

    google.maps.event.addListener marker, 'click', () ->
      console.log 'Clicked marker', marker.title


window.drawTimeLineForBerth = (berth) ->
  from = $('#slider-range').slider 'values', 0
  till = $('#slider-range').slider 'values', 1
  events = window.getMovementsForBerth from, till, berth

  data = []

  for berthEvent, index in events

    console.log berthEvent['eta']

    eta = berthEvent['eta']
    etd = berthEvent['etd']

    type = berthEvent['type']

    console.log eta, etd, type

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

  console.log data, options
  window.timeline.draw data, options




jQuery ->

  # google.load "visualization", "1"

  window.getVesselPosisitions()

  $(document).bind 'timerange_change', (e, from, till) ->

    movements = window.getMovements from, till

    for movement in movements
      window.heat_data.push
        location: new google.maps.LatLng(movement['coordinate']['latitude'], movement['coordinate']['longitude']),
        weight: movement['weight']
        # weight: 1
