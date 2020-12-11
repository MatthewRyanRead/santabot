# santabot

A Slack bot for setting up a Secret Santa exchange.  Just add it to a channel, invite everyone participating, set up the admin(s), and trigger it once you're ready!

## Commands

1. `@santabot Make me the admin`: Sets up the primary admin.  The first thing you should do!
2. `@santabot Add admin @someuser`: Makes `@someuser` a secondary admin.  Currently, they have the same powers as the primary admin.
3. `@santabot Who are the admins`: Lists all admins.
4. `@santabot dewit`: Performs the match!  Each non-bot user in the channel is DM'd a unique match via Slackbot.

## External Dependencies

Redis, for `hubot-brain`, which stores the admin info.  It will look on the default port, 6379.

## Installing

1. `npm i` (see [package.json](https://github.com/MatthewRyanRead/santabot/blob/master/package.json) for the tested versions of `npm`/`node`)
2. Create a Classic Slack app: https://api.slack.com/apps?new_classic_app=1
    - Follow the prompts until you get to the app dev home page
    - Create a Legacy bot user via the handy button on that page, following the prompts once again
        - The bot will be installed into your workspace at this point
    - Copy the Bot OAuth token (_not_ the User token) from the OAuth & Permissions page
3. Run `HUBOT_SLACK_TOKEN=$YOUR_TOKEN bin/hubot -a slack`

I am using a free Heroku setup to manage mine, following these instructions:
- [Hubot: Deploying to Heroku](https://hubot.github.com/docs/deploying/heroku/) (modified for Slack tokens rather than Campfire ones)
- [hubot-heroku-keepalive: Configuring & Waking Hubot Up](https://github.com/hubot-scripts/hubot-heroku-keepalive/blob/master/README.md#configuring)
- `heroku addons:create heroku-redis:hobby-dev`
