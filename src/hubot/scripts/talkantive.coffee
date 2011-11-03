# Respond to custom answers
# - when asked <regexp_of_question> answer <response> - teach your bot to answer to <regexp_of_question> with <response> 
# - forget answers - remove every teached answer from brain bot
#
# TODO :
# * BUG: Support regexp when redefining an answer to existing question
# * FEATURE: Only users with roles = TEACHER_ROLE can teach something to the bot 
# * FEATURE: Display possible questions in help
# * FEATURE: Add context to match questions (the same question can have two meanings depending on context)

module.exports = (robot) ->  

  basic_knowledge = [
    {question: "(what( is|'s))?( your)? favorite (smart)?phone", answer: 'Samsung Galaxy S2'},
    {question: 'favorite (os|operating system|platform)', answer: 'Linux'}
  ]

  respond_to_answer = (item) ->
    robot.brain.data.knowledge ?= []
    robot.respond new RegExp(item.question, 'i'), (msg) ->
      for item in robot.brain.data.knowledge
        break if msg.match[0].replace(robot.name,'').match new RegExp(item.question, 'i') # change replace with with regex
      msg.send item.answer if item?.answer? 

  robot.brain.on 'loaded', =>
    console.log "Loading knowledge"

    robot.brain.data.knowledge ?= []

    robot.brain.data.knowledge = basic_knowledge if robot.brain.data.knowledge.length == 0

    for item in robot.brain.data.knowledge
      respond_to_answer(item)

  robot.respond /when asked (.*) (reply|answer|return|say) (.*)$/i, (msg) ->
    question = msg.match[1]
    answer = msg.match[3]

    matching_questions = (item for item in robot.brain.data.knowledge when item.question == question) # should be match instead of ==
    if matching_questions.length > 0
      for matching_question in matching_questions
        if matching_question.answer == answer
          msg.send "I already know that"
        else
          robot.brain.data.knowledge.pop {question: question, answer: matching_question.answer}
          robot.brain.data.knowledge.push {question: question, answer: answer}
          msg.send "I thought \"#{matching_question.answer}\" but I will now answer \"#{answer}\""
    else
      robot.brain.data.knowledge.push({question: question, answer: answer})
      respond_to_answer({question: question, answer: answer})
      msg.send "OK, I will answer \"#{answer}\" when asked \"#{question}\""
  
  robot.respond /(forget)( all)? (answers|replies)$/i, (msg) ->
    robot.brain.data.knowledge = []
    msg.send "OK, I've forgot all answers"
