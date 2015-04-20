require 'highline/import'
require 'platform-api'
require 'rendezvous'

class HerokuInfoExtractor

  def initialize(auth_token)
    @heroku = PlatformAPI.connect_oauth(auth_token)
  end

  def extract(appname_array)
    apps_to_extract_from = appname_array.empty? ? get_all_apps : appname_array
    apps_to_extract_from.inject({}) do |result, app|
      result.merge(get_client_location_web_themes(app))
    end
  end

  private

  def extraction_command
    'NEWRELIC_AGENT_ENABLED=false rails runner "puts({ Client.first.name => Location.all.inject({}) { |result, location| result.update(location.name => location.website.web_templates.all.find{ |temp| temp.web_theme }.web_theme.name) } }.to_json)" 2>/dev/null'
  end

  def get_client_location_web_themes(application_name)
    response = @heroku.dyno.create(application_name, {'attach' => true, 'command' => extraction_command})
    rz = Rendezvous.new({input:StringIO.new, output:StringIO.new, url: response['attach_url'], activity_timeout:300})
    rz.start
    JSON.parse(rz.output.string)
  end

  def get_all_apps
    # This could be expensive if you have 100 apps on the account - could limit it
    @heroku.app.list.map { |app| app["name"] }
  end
end

auth = ask( "Please provide your heroku oauth token: " ) { |auth_token| auth_token.echo = false }
apps_input = ask( "Please provide apps in CSV format (empty will default to all apps available to oauth token): ")

apps = apps_input.split(',').map(&:strip)

extractor = HerokuInfoExtractor.new('ea33e132-4291-48ae-8e17-e58856cec4de')
puts extractor.extract(apps)
