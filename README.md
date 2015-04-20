# g5-test

Example code for pulling out specific information from rails console for Heroku.

### Usage

~~~
ruby extract.rb
~~~

Will prompt for:
  * [Heroku OAuth token](https://devcenter.heroku.com/articles/platform-api-quickstart#authentication)
  * A comma separate list of apps you want to query
    * if you do not enter any, it will simply query heroku for ALL apps that the OAuth token has access to and use that

Example:

~~~
ruby extract.rb

Please provide your heroku oauth token:
Please provide apps in CSV format (empty will default to all apps available to oauth token): g5-cms-1t9dz1wn-jm-real-estate
~~~

### Implementation

The code connects to the heroku plaform api and does the following:

1. Spin up a dyno against each app that runs a specific command to dump the requested info in JSON format to stdout on the heroku host
2. Captures the rendezvous attachment URL from each API call and connects to it to grab the output into a StringIO object
3. Parases the return JSON string back into a Hash object on the client side and merge is with any other existing hashes of info
4. Wrote a very basic reporting mechanism - both the reporting mechanism and the extraction are public on the class since I think the raw data is likely more useful - the reporting was just put in to make it look nice on the command line

Implemented using:
  * [Heroku platform-api gem](https://github.com/heroku/platform-api)
  * [Heroku Rendezvous gem](https://github.com/heroku/rendezvous.rb)

Inspiration drawn from innumerable sources but big ones were:
  * [This github issue](https://github.com/heroku/heroku/issues/617) which showed me it was possible to run command line via the API
    * Referenced this version of the Rakefile from the stringer codebase: https://github.com/swanson/stringer/commit/f0e18622cada3c30acffc430a2f117ff55ef182a#diff-52c976fc38ed2b4e3b1192f8a8e24cff which gave me the api target
  * [Heroku platform API](https://devcenter.heroku.com/articles/platform-api-reference#app) - this caused me to start going down the path of implementing this using the rest-client gem (was testing using curl on command line so seemed the logical move) before finding the platform-api gem

Wish I had more interim commits to show prior to this but a great deal of work was spent:
  * Initially on the command line with curl figuring out the API
  * Then in IRB sorting out how to do what I had found with curl via the ruby API
  * Once I had nailed the commmand that had to be run, the API endpoint that could execute it for me and the method to grab the output from that execution - just put it all together

### Concerns

* No unit tests - typically would try to TDD this kind of work but I treated it more like a spike due to my unfamiliarity with the Heroku interface
    * There are numerous places that it would be good to put in some tests and some validations to verify that data is always available
    * In the example apps that you provided me, the only wrinkle that came up was that not all web_templates had web_themes so had to find the one that had it attached -> e.g.

~~~
Location.first.website.web_templates.first.web_theme
=> nil

Location.first.website.web_templates.all.find{ |temp| temp.web_theme }.web_theme.name
=> Ivy
~~~
* Speed - running this against 2 apps with Benchmark enabled took 26 seconds - not sure how scalable this is to hundreds of apps
* Each call creates a one-off dyno on the app - not sure if this would impact cost or the application performance
* To try and ensure that only get the data requested gets returned in the output capture, I switched off new relic via an ENV variable on the command and redirected stderr to /dev/null -> this means we lose any valuable error info if the command fails on a specific host

### Improvements

* Not doing anything useful with the output other than dumping into a very basic report
* Currently, if this process gets through 99% of the apps and then fails, you lose everything AND don't get any useful capture from the command failure -> should be hardened to cope with failures on individual apps and potentially capture the stderr from the remote box
