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

        ### primary commands ###

        robot.hear /dewit/i, (slackMsg) ->
            dmPostMatches robot, web, slackMsg
            postMatchesSent robot, web, slackMsg

        ### admin-only commands ###

        # TODO: "Add @name as admin"
        # TODO: admin ability to remove newer admin

### message handlers ###

trySetAdmin = (robot, web, slackMsg) ->
    if isAdminUser robot, slackMsg
        slackMsg.send 'You are already an admin.'
        return

    admins = loadAdmins robot, slackMsg

    if admins.length
        slackMsg.send 'Admin(s) already exist!\n' + getAdminsMsgText robot, slackMsg
    else
        saveAdmin robot, slackMsg
        slackMsg.send 'You are now the admin.'

postAdmins = (robot, web, slackMsg) ->
    slackMsg.send getAdminsMsgText robot, slackMsg

postMatchesSent = (robot, web, slackMsg) ->
    slackMsg.send 'Users have been DM\'d with their matches!'

dmPostMatches = (robot, web, slackMsg) ->
    slackGetConversationMembers(web, extractRoomId slackMsg).then (channel) ->
        buyerUserIds = channel.members.filter((userId) -> !robot.brain.userForId(userId).slack.is_bot)
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

isAdminUser = (robot, slackMsg) ->
    admins = loadAdmins robot, slackMsg
    (extractUserId slackMsg) in admins

getAdminsMsgText = (robot, slackMsg) ->
    admins = loadAdmins robot, slackMsg
    if not admins.length
        return 'There are no admins!'

    response = 'The admins are:'
    for userId in admins
        user = robot.brain.userForId userId
        response += '\n@' + user.name

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

saveAdmin = (robot, slackMsg, userId = extractUserId slackMsg) ->
    admins = loadAdmins robot, slackMsg
    admins.push userId
    robot.brain.set (makeAdminKey slackMsg), admins

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
