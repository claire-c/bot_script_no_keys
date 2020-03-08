
## Deploying 

    heroku create
    heroku buildpacks:set heroku/ruby
    git push heroku master

## Running

    heroku run bot

## Scheduling automated

    heroku addons:create scheduler:standard
