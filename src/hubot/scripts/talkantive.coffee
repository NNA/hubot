# Respond to custom answers
# - when asked <regexp_of_question> answer <response> - teach your bot to answer to <regexp_of_question> with <response> 
# - forget answers - remove every teached answer from brain bot
#
# TODO :
# * FEATURE: Only users with roles = TEACHER_ROLE can teach something to the bot 
# * FEATURE: Display possible questions in help
# * FEATURE: Add context to match questions (the same question can have two meanings depending on context)

module.exports = (robot) ->  
  
  # TODO: refactor @knowledge = robot.brain.data.knowledge

  basic_knowledge = {
    1: {regexp: "(what( is|'s))?( your)? favorite (smart)?phone", answer: 'Samsung Galaxy S2'},
    2: {regexp: 'favorite (os|operating system|platform)', answer: 'Linux'}
  }

  respondToAnswer = (item) ->
    robot.brain.data.knowledge ?= {}
    robot.respond new RegExp(item.regexp, 'i'), (msg) ->
      #refactor using fct questionWithRegExp
      for key, item of robot.brain.data.knowledge
        break if msg.match[0].replace(robot.name,'').match new RegExp(item.regexp, 'i') # change replace with with regex
      msg.send item.answer if item?.answer? 

  robot.brain.on 'loaded', =>
    console.log "Loading knowledge"

    robot.brain.data.knowledge ?= {}

    robot.brain.data.knowledge = basic_knowledge if Object.keys(robot.brain.data.knowledge).length == 0
    for key, item of robot.brain.data.knowledge
      respondToAnswer(item)

  robot.respond /(when )?asked (.*) (reply|answer|return|say) (.*)$/i, (msg) ->
    question = msg.match[2]
    answer = msg.match[4]
    
    for key, item of robot.brain.data.knowledge# when item.regexp == question # should be match instead of ==
      break if item.regexp == question
        
    if item?.regexp == question
      if item.answer == answer
        msg.send "I already know that"
      else
        msg.send "I thought \"#{item.answer}\" but I will now answer \"#{answer}\""
        robot.brain.data.knowledge[key].answer = answer
    else
      new_question = {regexp: question, answer: answer}
      next_id = Object.keys(robot.brain.data.knowledge).length+1
      robot.brain.data.knowledge[next_id] = new_question
      respondToAnswer(new_question)
      msg.send "OK, I will answer \"#{answer}\" when asked \"#{question}\""
  
  robot.respond /(forget)( all)? (answers|replies)$/i, (msg) ->
    robot.brain.data.knowledge = {}
    msg.send "OK, I've forgot all answers"
