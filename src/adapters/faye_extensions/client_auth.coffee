clientAuth = outgoing: (message, callback) ->
      # Again, leave non-subscribe messages alone
      if (message.channel is not '/meta/subscribe' and !/chat/.test(message.channel))
        return callback message
      
      crypto = require 'crypto'
      sha1   = crypto.createHash 'sha1'

      # Add ext field if it's not present
      message.ext ?= {}

      #Set the auth token
      message.ext.group = message.channel
      message.ext.user_id = '0';
      message.ext.user_name = process.env.HUBOT_FAYE_USER;
      message.ext.avatar = process.env.HUBOT_FAYE_AVATAR;
      password = process.env.HUBOT_FAYE_PASSWORD

      sha1.update "#{password}/chat/#{message.ext.group}"
      message.ext.authToken = sha1.digest 'hex'

      #Carry on and send the message to the server
      callback message

module.exports = clientAuth