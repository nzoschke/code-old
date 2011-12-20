Code
====

Code is a multi-tenant HTTP Git service, that can be run as a Heroku app.

Quick Start
-----------

Clone the repo, install dependencies and run the specs.

```sh
git clone git@github.com:nzoschke/code.git && cd code
bundle install
rake
```

Deploy the app to Heroku

```sh
APP=code-$(whoami)
heroku create $APP -s cedar

heroku addons:add heroku-shared-postgresql
heroku addons:add redistogo
heroku addons:add securekey

HEROKU_API_KEY=$(grep -a2 api.heroku.com ~/.netrc | tail -1 | cut -d" " -f4)
HEROKU_DATABASE_URL=$(heroku config -s | grep HEROKU_SHARED_POSTGRESQL | cut -d= -f2)
LOG_TOKEN=$(docbrown app:info $APP | grep ^log_token | sed 's/.*: //g')
REDISTOGO_URL=$(heroku config -s | grep REDISTOGO_URL | cut -d= -f2)

heroku config:add                   \
  DATABASE_URL=$HEROKU_DATABASE_URL \
  HEROKU_API_KEY=$HEROKU_API_KEY    \
  HEROKU_APP=$APP                   \
  LOG_TOKEN=$LOG_TOKEN              \
  NUM_PROCESSES=2                   \
  RACK_ENV=production               \
  REDIS_URL=$REDISTOGO_URL

git push heroku master

heroku run 'sequel -E -m db/migrations $DATABASE_URL'
heroku scale web=2 monitor=1
```

Test a push, authenticating with your Heroku username and password

```sh
TESTAPP=canary-$(whoami)
heroku create $TESTAPP -s cedar
GIT_DIR=spec/fixtures/rack/ git push https://$APP.herokuapp.com/$TESTAPP.git master
```

Review logs at the admin site: https://$APP.herokuapp.com/pushes