# Commands:
#   hubot dewit - Assigns each channel member a Secret Santa, and messages each one with details!

Util = require "util"
{ WebClient } = require "@slack/client"
moment = require "moment"

module.exports = (robot) ->
    if robot.adapter.options and robot.adapter.options.token
        web = new WebClient robot.adapter.options.token

        ### meta commands ###

        robot.respond /Make me the admin/i, (slackMsg) ->
            trySetAdmin robot, web, slackMsg

        robot.respond /Who are the admins/i, (slackMsg) ->
            postAdmins robot, web, slackMsg

        ### admin-only commands ###

        robot.respond /dewit/i, (slackMsg) ->
            dewit robot, web, slackMsg

        robot.respond /Add admin/i, (slackMsg) ->
            tryAddAdmin robot, web, slackMsg

### message handlers ###

dewit = (robot, web, slackMsg) ->
    if isAdminUser robot, slackMsg, extractUserId slackMsg
        dmPostMatches robot, web, slackMsg
        postMatchesSent robot, web, slackMsg
    else
       slackMsg.send 'Please wait for an admin to do that!'

trySetAdmin = (robot, web, slackMsg) ->
    if isAdminUser robot, slackMsg, extractUserId slackMsg
        slackMsg.send 'You are already an admin.'
        return

    admins = loadAdmins robot, slackMsg

    if admins.length
        slackMsg.send 'Admin(s) already exist!\n' + getAdminsMsgText robot, slackMsg
    else
        saveAdmin robot, slackMsg, extractUserId slackMsg
        slackMsg.send 'You are now the admin.'

tryAddAdmin = (robot, web, slackMsg) ->
    if !isAdminUser robot, slackMsg, extractUserId slackMsg
        slackMsg.send 'Only an admin can do that!'
        return

    msg = extractMsgText slackMsg
    startIndex = msg.lastIndexOf '@'
    userName = msg.substr startIndex + 1
    if !userName or userName.length == 0
        slackMsg.send 'Only a user can be made an admin.'
        return

    user = robot.brain.userForName userName
    if !user
        slackMsg.send 'Only a user can be made an admin.'
        return

    if isAdminUser robot, slackMsg, user.id
        slackMsg.send '<@' + user.id + '> is already an admin.'
        return

    admins = loadAdmins robot, slackMsg

    if admins.includes(user.id)
        slackMsg.send '<@' + user.id + '> is already an admin!'
    else
        saveAdmin robot, slackMsg, user.id
        slackMsg.send '<@' + user.id + '>  is now an admin.'

postAdmins = (robot, web, slackMsg) ->
    slackMsg.send getAdminsMsgText robot, slackMsg

postMatchesSent = (robot, web, slackMsg) ->
    slackMsg.send 'Users have been DM\'d with their matches!'

dmPostMatches = (robot, web, slackMsg) ->
    slackGetConversationMembers(web, extractRoomId slackMsg).then (channel) ->
        buyerUserIds = channel.members.filter((userId) -> !isBot robot, userId)
        recipientUserIds = []
        while true
            recipientUserIds = buyerUserIds
                    .map((a) -> { sort: Math.random(), value: a })
                    .sort((a, b) -> a.sort - b.sort)
                    .map((a) -> a.value)

            acceptable = true
            recipientUserIds.forEach (recipientUserId, i) ->
                if recipientUserId == buyerUserIds[i]
                    acceptable = false

            if acceptable
                break
            else
                console.debug 'Random shuffle failed, trying again'

        buyerUserIds.forEach (userId, i) ->
            slackDmPostMessage web, userId, 'You are the Secret Santa for <@' + recipientUserIds[i] + '>. Congratulations!'

### admin helpers ###

isAdminUser = (robot, slackMsg, userId) ->
    admins = loadAdmins robot, slackMsg
    userId in admins

getAdminsMsgText = (robot, slackMsg) ->
    admins = loadAdmins robot, slackMsg
    if not admins.length
        return 'There are no admins!'

    response = 'The admins are:'
    for userId in admins
        response += '\n<@' + userId + '>'

    response

### slack API calls ###

slackGetConversationMembers = (web, roomId) ->
    web.conversations.makeAPICall 'conversations.members', 'channel': roomId

slackDmPostMessage = (web, userId, msg) ->
    web.conversations.makeAPICall 'chat.postMessage', { 'channel': userId, 'text': msg }

### saved data helpers ###

makeDataKey = (part1, part2) ->
    part1 + '_' + part2

makeAdminKey = (slackMsg) ->
    makeDataKey (extractRoomId slackMsg), 'admins'

loadAdmins = (robot, slackMsg) ->
    (robot.brain.get makeAdminKey slackMsg) or []

saveAdmin = (robot, slackMsg, userId) ->
    admins = loadAdmins robot, slackMsg
    admins.push userId
    robot.brain.set (makeAdminKey slackMsg), admins

isBot = (robot, userId) ->
    robot.brain.userForId(userId).slack.is_bot

### incoming message helpers ###

extractUser = (slackMsg) ->
    slackMsg.message.user

extractUserId = (slackMsg) ->
    slackMsg.message.user.id

extractUserName = (slackMsg) ->
    slackMsg.message.user.name

extractRoomId = (slackMsg) ->
    slackMsg.message.room

extractMsgText = (slackMsg) ->
    slackMsg.message.text
