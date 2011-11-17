Robot = require '../robot'
faye = require 'faye'

class Faye extends Robot.Adapter

  run: ->
    # Client Options
    options = 
      server: process.env.HUBOT_FAYE_SERVER
      port: process.env.HUBOT_FAYE_PORT || 80
      path: process.env.HUBOT_FAYE_PATH || 'bayeux'
      user: process.env.HUBOT_FAYE_USER || 'anonymous'
      password: process.env.HUBOT_FAYE_PASSWORD || ''
    
    if not options.server
      throw Error('You need to set HUBOT_FAYE_SERVER env vars for faye to work')

    # Connect to faye server
    @client = new faye.Client options.server + ':' + options.port + '/' + options.path

    # Share the options
    @options = options

    @client.subscribe '/chat/*', (message) =>
      console.log 'Faye Adapter got message from ' + message.user + ' saying '+ message.message
      @receive new Robot.TextMessage message.user, message.message
  
  send: (user, strings...) =>
    for str in strings
      if user.room
        console.log "#{user.room} #{str}"
        # @client.publish('/chat/nicolas'
      else
        console.log "@#{user.name} #{str}"
        @client.publish '/chat/paris',
          user:     @robot.name,
          message:  str

  reply: (user, strings...) ->
    for str in strings
      @send user, "#{user.name}: #{str}"

  # join: (channel) ->
  #   self = @
  #   @bot.join channel, () ->
  #     console.log('joined %s', channel)

module.exports = Faye