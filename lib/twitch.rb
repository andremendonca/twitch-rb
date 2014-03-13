require "curb"
require "json"

class Twitch
  def initialize(options = {})
    @client_id = options[:client_id] || nil
    @secret_key = options[:secret_key] || nil
    @redirect_uri = options[:redirect_uri] || nil
    @scope = options[:scope] || nil
    @access_token = options[:access_token] || nil

    @base_url = "https://api.twitch.tv/kraken"
  end

  public

  def getLink
    scope = ""
    @scope.each { |s| scope += s + '+' }
    "https://api.twitch.tv/kraken/oauth2/authorize?response_type=code&client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&scope=#{scope}"
  end

  def auth(code)
    path = "/oauth2/token"
    url = @base_url + path
    post(url, {
      :client_id => @client_id,
      :client_secret => @secret_key,
      :grant_type => "authorization_code",
      :redirect_uri => @redirect_uri,
      :code => code
    })
  end

  # User

  def getUser(user)
    path = "/users/" + user
    get(url path)
  end

  def getYourUser
    return false if !@access_token
    path = "/user?oauth_token=#{@access_token}"
    get(url path)
  end

  # Teams

  def getTeams
    path = "/teams/"
    get(url path)
  end


  def getTeam(team_id)
    path = "/teams/" + team_id
    get(url path)
  end

  # Subscription

  def getChannelSubscription(user, channel)
    return false if !@access_token
    path = "/users/#{user}/subscriptions/#{channel}?oauth_token=#{@access_token}"
    get(url path)
  end

  # Channel

  def getChannel(channel)
    path = "/channels/" + channel
    get(url path)
  end

  def getYourChannel
    return false if !@access_token
    path = "/channel?oauth_token=#{@access_token}"
    get(url path)
  end

  def editChannel(channel, status, game)
    return false if !@access_token
    path = "/channels/#{channel}/?oauth_token=#{@access_token}"
    data = {
      :channel =>{
        :game => game,
        :status => status
      }
    }
    put(url path, data)
  end

  def runCommercial(channel, length = 30)
    return false if !@access_token
    path = "/channels/#{channel}/commercial?oauth_token=#{@access_token}"
    post(url path, {
      :length => length
    })
  end

  # Streams

  def getStream(stream_name)
    path = "/stream/#{stream_name}"
    get(url path)
  end

  def getStream(stream_name)
    path = "/streams/#{stream_name}"
    get(url path)
  end

  def getStreams(options = {})
    query = buildQueryString(options)
    path = "/streams" + query
    get(url path)
  end

  def getFeaturedStreams(options = {})
    query = buildQueryString(options)
    path = "/streams/featured" + query
    get(url path)
  end

  def getSummeraizedStreams(options = {})
    query = buildQueryString(options)
    path = "/streams/summary" + query
    get(url path)
  end

  def getYourFollowedStreams
    path = "/streams/followed?oauth_token=#{@access_token}"
    get(url path)
  end

  #Games

  def getTopGames(options = {})
    query = buildQueryString(options)
    path = "/games/top" + query
    get(url path)
  end

  #Search

  def searchStreams(options = {})
    query = buildQueryString(options)
    path = "/search/streams" + query
    get(url path)
  end

  def searchGames(options = {})
    query = buildQueryString(options)
    path = "/search/games" + query
    get(ur path)
  end

  # Videos

  def getChannelVideos(channel, options = {})
    query = buildQueryString(options)
    path = "/channels/#{channel}/videos" + query
    get(url path)
  end

  def getVideo(video_id)
    path = "/videos/#{video_id}/"
    get(url path)
  end

  private

  API_ERRORS = {
    502 => '502 Bad Gateway',
    503 => '503 Service Unavailable',
    401 => '503 Invalid Token'
  }

  def url (path)
    @base_url + path
  end

  def respond resp
    API_ERRORS.values.each do |err|
      if resp.body_str.include? err
        error = API_ERRORS.index err
        errorMessage = err
      end
    end

    return {:body => errorMessage, :response => error} if defined? error
    {:body => JSON.parse(resp.body_str), :response => resp.response_code}
  end

  def buildQueryString(options)
    query = "?"
    options.each do |key, value|
      query += "#{key}=#{value.to_s.gsub(" ", "+")}&"
    end
    query = query[0...-1]
  end

  def post(url, data)
    JSON.parse(Curl.post(url, data).body_str)
    resp = Curl.post(url, data)
    respond resp
  end

  def get(url)
    resp = Curl.get url
    respond resp
  end

  def put(url, data)
    resp = Curl.put(url,data.to_json) do |curl|
      curl.headers['Accept'] = 'application/json'
      curl.headers['Content-Type'] = 'application/json'
      curl.headers['Api-Version'] = '2.2'
    end
    respond resp
  end
end
