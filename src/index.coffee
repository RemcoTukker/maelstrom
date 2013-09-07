express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
# db = require './models'
# pg = require('pg')
orm = require('orm')
# mongoose = require 'mongoose'

#### Basic application initialization
# Create app instance.
app = express()

# Define Port
app.port = process.env.PORT or process.env.VMC_APP_PORT or 3000


# Config module exports has `setEnvironment` function that sets app settings depending on environment.
config = require "./config"
app.configure 'production', 'development', 'testing', ->
  config.setEnvironment app.settings.env

# db_url = process.env.DATABASE_URL || "postgres://#{config.DB_USER}:#{config.DB_PASS}@#{config.DB_HOST}:#{config.DB_PORT}/#{config.DB_NAME}"
# console.log "connecting to:", db_url
# db_stuff = orm.express db_url,
#   define: (db, models, next) ->
#     models.shipPositions = db.define 'shipPositions',
#       id: Number,
#       vesselName: String

# app.use db_stuff

# mongoose.connect db_config
# if app.settings.env != 'production'
#   mongoose.connect 'mongodb://localhost/example'
# else
#   console.log('If you are running in production, you may want to modify the mongoose connect path')

#### View initialization
# Add Connect Assets.
app.use assets()
# Set the public folder as static assets.
app.use express.static(process.cwd() + '/public')


# Set View Engine.
app.set 'view engine', 'jade'

# [Body parser middleware](http://www.senchalabs.org/connect/middleware-bodyParser.html) parses JSON or XML bodies into `req.body` object
app.use express.bodyParser()


#### Finalization
# Initialize routes
routes = require './routes'
routes(app)


# Export application object
module.exports = app

