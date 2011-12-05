evtInterceptor = incoming: (message, callback) ->
  if message.data?.evt?  
    console.log "--#{message.data.clientId} #{message.data.evt} #{message.channel} new user_list => #{message.data.user_list}"
  else
    callback(message)

module.exports = evtInterceptor