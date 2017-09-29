require 'sinatra'
require 'pp'
require 'net/http'
require 'twilio-ruby'
require 'spotify-client' 

# Configure Twilio
twilio_account_sid = ENV['TWILIO_ACCOUNT_SID']
twilio_auth_token = ENV['TWILIO_AUTH_TOKEN']
twilio_client = Twilio::REST::Client.new twilio_account_sid, twilio_auth_token

# Configure Spotify
config = {
  :access_token => ENV['SPOTIFY_ACCESS_TOKEN'],  # initialize the client with an access token to perform authenticated calls
  :raise_errors => true,  # choose between returning false or raising a proper exception when API calls fails

  # Connection properties
  :retries       => 0,    # automatically retry a certain number of times before returning
  :read_timeout  => 10,   # set longer read_timeout, default is 10 seconds
  :write_timeout => 10,   # set longer write_timeout, default is 10 seconds
  :persistent    => false # when true, make multiple requests calls using a single persistent connection. Use +close_connection+ method on the client to manually clean up sockets
}
spotify_client = Spotify::Client.new(config)

post '/receive_sms' do
    msg = /&Body=(.*?)&/.match(request.body.read)[1]
    pp msg 

    track_id = nil
    if msg.downcase().start_with? 'play+' 
        search_term = msg.split('+').drop(1).join(' ')
        res = spotify_client.search('track', search_term)
        track_id = res.fetch("tracks").fetch("items")[0].fetch("uri").split(":")[2]
    else
        track_id = /track%2F(.*)$/.match(msg)[1]
    end

    pp track_id 
    track = spotify_client.track(track_id)
    spotify_client.add_user_tracks_to_playlist('123031849', '5Vf9oOTnJGvfYVOrOqo2GH', uris = [track.fetch("uri")], position = nil)
    "success maybe?"
end
