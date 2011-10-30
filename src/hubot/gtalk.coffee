Robot = require '../robot'
Xmpp  = require 'node-xmpp'

class Gtalkbot extends Robot
  run: ->
    
    # Client Options
    options = 
      jid: process.env.HUBOT_GTALK_USERNAME
      password: process.env.HUBOT_GTALK_PASSWORD
      host: 'talk.google.com'
      port: 5222
      keepaliveInterval: 30000 # ms interval to send whitespace to xmpp server

    # Connect to gtalk servers
    @client = new Xmpp.Client options

    # Events
    @client.on 'online', @.online
    # @client.on 'chat', @.chat
    @client.on 'stanza', @.read
    @client.on 'error', @.error
    
    # Log options
    @options = options
    # console.log options

  error: (error) =>
    console.error error

  online: =>
    console.log 'Hubot XMPP client online'

    @client.send new Xmpp.Element('presence', type: 'unsubscribed' )
      .c('show').t('chat')

    # join each room
    # http://xmpp.org/extensions/xep-0045.html for XMPP chat standard
    # for room in @options.rooms
    #   @client.send(new Xmpp.Element('presence', to: "#{room}/#{@name}" )
    #     .c('x', xmlns: 'http://jabber.org/protocol/muc' )
    #     .c('history', seconds: 1 )) # prevent the server from confusing us with old messages
    #                                 # and it seems that servers don't reliably support maxchars
    #                                 # or zero values
    
    # @client.send(new Xmpp.Element('presence', to: @options.jid )
    #     .c('x', xmlns: 'http://jabber.org/protocol/muc' )
    #     .c('history', seconds: 1 )) # prevent the server from confusing us with old messages
    #                                 # and it seems that servers don't reliably support maxchars
    #                                 # or zero values

    # send raw whitespace for keepalive
    setInterval =>
      @client.send ' '
    , @options.keepaliveInterval
  
  read: (stanza) =>
    console.log 'Received msg'
        
    if stanza.attrs.type is 'error'
      console.error '[xmpp error]' + stanza
      return

    switch stanza.name
      when 'message'
        @readMessage stanza
      when 'presence'
        @readPresence stanza
  
  readMessage: (stanza) =>
    # ignore non-messages
    return if stanza.attrs.type not in ['groupchat', 'direct', 'chat']

    # ignore our own messages
    return if @options.jid in stanza.attrs.from

    # ignore messages from the server. on Openfire, this includes "This room is not anonymous"
    # return if stanza.attrs.from in @options.rooms

    # ignore empty bodies (i.e., topic changes -- maybe watch these someday)
    body = stanza.getChild 'body'
    return unless body

    message = body.getText()

    # [room, from] = stanza.attrs.from.split '/'
    from = stanza.attrs.from

    # note that 'from' isn't a full JID, just the local user part
    user = @userForId from
    # user.room = room
    user.type = stanza.attrs.type

    @receive new Robot.TextMessage user, message

  readPresence: (stanza) =>
    console.log 'Read Presence'
    jid = new Xmpp.JID(stanza.attrs.from)
    bareJid = jid.bare().toString()

    # xmpp doesn't add types for standard available mesages
    # note that upon joining a room, server will send available
    # presences for all members
    # http://xmpp.org/rfcs/rfc3921.html#rfc.section.2.2.1
    stanza.attrs.type ?= 'available'

    switch stanza.attrs.type
      when 'subscribe'
        console.log "#{stanza.attrs.from} subscribed to us"

        @client.send new Xmpp.Element('presence',
            from: stanza.attrs.to
            to:   stanza.attrs.from
            id:   stanza.attrs.id
            type: 'subscribed'
        )
      when 'probe'
        console.log "probe"
        @client.send new Xmpp.Element('presence',
            from: stanza.attrs.to
            to:   stanza.attrs.from
            id:   stanza.attrs.id
        )
      when 'available'
        console.log "available"
        if bareJid not in @options.rooms
          from = stanza.attrs.from
        else
          # room presence is stupid, and optional for some anonymous rooms
          # http://xmpp.org/extensions/xep-0045.html#enter-nonanon
          from = stanza.getChild('x', 'http://jabber.org/protocol/muc#user')?.getChild('item')?.attrs?.jid

        return if not from?

        # for now, user IDs and user names are the same. we don't
        # use full JIDs as user ID, since we don't get them in
        # standard groupchat messages
        jid = new Xmpp.JID(from)
        userId = userName = jid.user

        console.log "Availability received for #{userId}"

        user = @userForId userId, name: userName
        user.jid = jid.toString()

  send: (user, strings...) ->
    console.log 'send'
    for str in strings
      # console.log "Sending to #{user.room}: #{str}"
      console.log "Sending to #{from}: #{str}"

      to = if user.type in ['direct', 'chat'] then "#{user.room}/#{user.id}" else user.room

      # console.log "from #{@options.username}, to #{to}"
      console.log "from #{@options.jid}, to #{to}"

      # message = new Xmpp.Element('message',
      #             from: @options.username
      #             to: to
      #             type: user.type
      #           ).
      #           c('body').t(str)
      message = new Xmpp.Element('message',
            from: from
            to: to
            type: user.type
          ).
          c('body').t(str)

      @client.send message

  reply: (user, strings...) ->
    console.log 'reply'
    for str in strings
      @send user, "#{user.name}: #{str}"
  ##############################################################""

  # online: =>
  #   console.log 'Hubot is online, talk.google.com!'

  # chat: (from,message) =>
  #   @receive new Robot.TextMessage from, message
  
  # send: (user, strings...) ->
  #   for str in strings
  #     Xmpp.send user, str

  # reply: (user, strings...) ->
  #   for str in strings
  #     @send user, "#{str}"

  # error: (err) =>
  #   console.error err

module.exports = Gtalkbot