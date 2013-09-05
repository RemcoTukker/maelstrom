# ShipPosition = require '../models/shipPosition'

module.exports =

  index: (req, res) ->
    req.models.shipPositions.count (err, count) ->
      res.render 'shipPositions',
        number_of_ship_positions: count