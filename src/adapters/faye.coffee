Robot = require '../robot'
faye = require 'faye'
fs = require 'fs'

class Faye extends Robot.Adapter

  run: ->
    # Client Options
    options = 
      server: process.env.HUBOT_FAYE_SERVER
      port: process.env.HUBOT_FAYE_PORT || 80
      path: process.env.HUBOT_FAYE_PATH || 'bayeux'
      user: process.env.HUBOT_FAYE_USER || 'anonymous'
      password: process.env.HUBOT_FAYE_PASSWORD || ''
      rooms: process.env.HUBOT_FAYE_ROOMS?.split(',') ? ['test_room']
      extensions_dir: process.env.HUBOT_FAYE_EXTENSIONS_DIR || 'faye_extensions'
    
    if not options.server
      throw Error('You need to set HUBOT_FAYE_SERVER env vars for faye to work')

    # Connect to faye server
    @client = new faye.Client options.server + ':' + options.port + '/' + options.path

    # Load all faye extensions
    for file in fs.readdirSync("./src/adapters/#{options.extensions_dir}")
      @client.addExtension require("./#{options.extensions_dir}/#{file}")

    for room in options.rooms
      console.log "Subscribing to room #{room}"

      #subscribe to every rooms
      @client.subscribe "/chat/#{room}", (message) =>
        console.log 'Faye Adapter got message from ' + message.username + ' saying '+ message.message
        @receive new Robot.TextMessage message.username, message.message

    # Share the options
    @options = options    
  
  send: (user, strings...) =>
    for str in strings
      if user.room
        console.log "#{user.room} #{str}"
        # @client.publish('/chat/nicolas'
      else
        console.log "@#{user.name} #{str}"
        @client.publish '/chat/nicolas',
          username:     @robot.name,
          message:      str

  reply: (user, strings...) ->
    for str in strings
      @send user, "#{user.name}: #{str}"

  join: (channel) ->
    console.log "### Faye Adapter #{@robot.name} has join channel /chat/#{channel}"
    @client.publish "/chat/#{channel}",
      username:     @robot.name,
      message:      "#{@robot.name} has join"

module.exports = Faye