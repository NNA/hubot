# Get Public Info from Quintonic.fr

jsdom = require 'jsdom'
 
module.exports = (robot) ->
  
  robot.respond /(quintonic|qt) count/i, (msg) ->
    msg.http('http://quintonic.fr/membres')
      .get() (err, res, body) ->
        count = getUsersCount body
        msg.send "#{count} membres sur quintonic !"

  getUsersCount = (html) ->
    users = 0
    jsdom.env html, (err, window) ->
      content = window.document.getElementById('discover_widget').innerHTML
      begin = content.indexOf('class="color"') + 14
      end = content.indexOf('/span') - 1
      users = content.substring begin, end
    users