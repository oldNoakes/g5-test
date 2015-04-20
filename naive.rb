require 'highline/import'
require 'rest-client'

# Get auth token - have hardcoded for now with mine
# Get all apps - again, have hardcoded to verify implementation
# For each app
#   Post to dynos under the app to run the command we are looking for (currently injecting values in)
#   Attempt to attach to rendezvous endpoint to capture output
#

# curl -L -v https://api.heroku.com/apps/murmuring-refuge-8335/dynos -H "Authorization: Bearer " -H "Accept: application/vnd.heroku+json; version=3" -H "Content-Type: application/json" -X POST -d '{ "attach":true, "command":"rails runner \"puts app.remote_addr\"" }'

class HerokuInfoExtractor

  def initialize(auth_token)
    @auth_token = auth_token
  end

  def run_command
    response = RestClient.get 'https://api.heroku.com/apps/murmuring-refuge-8335/dynos', { :Authorization => "Bearer #{@auth_token}", :Accept => 'application/vnd.heroku+json; version=3' }
    puts response
  end
end

auth = ask( "Please provide your heroku bearer token: " ) { |auth_token| auth_token.echo = false }
extractor = HerokuInfoExtractor.new(auth)
extractor.run_command
