require 'cinch'
require 'net/http'
require 'uri'
require 'json'

IRC_CHANNEL = "#channel"
IRC_SERVER = "irc.yourserver.com"
IRC_PORT = 6667
IRC_NICK = "TraktBot"
IRC_SSL = true

TRAKT_APIKEY = ''
TRAKT_USERNAME = ''
TRAKT_PASSWORD = ''

class TraktPlugin
	include Cinch::Plugin

	@@last_time = 0

	def initialize(*args)
		@@last_time = ts_get()
		puts "last time: #{ @@last_time }"
		super
	end

	timer 300, method: :timed
	def timed
		ts = ts_get()

		res = trakt_get(@@last_time, ts)
		res["activity"].each  do |activity|
			chat_msg = ""
			u = activity["user"]["username"]
			x = u[0...-1]
			x1 = u[-1]
			username = "#{ x }.#{ x1 }"

			puts activity
			if activity["action"] == "scrobble"
				if activity["type"] == "movie"
					chat_msg = "#{ username } is watching '#{ activity["movie"]["title"] }' (#{ activity["movie"]["year"] })."
				elsif activity["type"] == "episode"
					chat_msg = "#{ username } is watching '#{ activity["episode"]["title"] }' (#{ activity["episode"]["season"]}x#{ activity["episode"]["episode"] }) of '#{ activity["show"]["title"] }' (#{ activity["show"]["year"] })."
				end
			elsif activity["action"] == "checkin"
				if activity["type"] == "movie"
					chat_msg = "#{ username } checked in to '#{ activity["movie"]["title"] }' (#{ activity["movie"]["year"] })."
				elsif activity["type"] == "episode"
					chat_msg = "#{ username } checked in to '#{ activity["episode"]["title"] }' (#{ activity["episode"]["season"]}x#{ activity["episode"]["episode"] }) of '#{ activity["show"]["title"] }' (#{ activity["show"]["year"] })."
				end
			elsif activity["action"] == "rating"
				if activity["type"] == "movie"
					chat_msg = "#{ username } rated the movie '#{ activity["movie"]["title"] }' (#{ activity["movie"]["year"] }) #{ activity["rating_advanced"] } out of 10."
				elsif activity["type"] == "show"
					chat_msg = "#{ username } rated the series '#{ activity["show"]["title"] }' (#{ activity["show"]["year"] }) #{ activity["rating_advanced"] } out of 10."
				elsif activity["type"] == "episode"
					chat_msg = "#{ username } rated the episode '#{ activity["episode"]["title"] }' (#{ activity["episode"]["season"]}x#{ activity["episode"]["episode"] }) of '#{ activity["show"]["title"] }' (#{ activity["show"]["year"] }) #{ activity["rating_advanced"] } out of 10."
				end
			elsif activity["action"] == "collection"
				if activity["type"] == "movie"
					chat_msg = "#{ username } added the movie '#{ activity["movie"]["title"] }' (#{ activity["movie"]["year"] }) to his/her collection."
				elsif activity["type"] == "episode"
					chat_msg = "#{ username } added the episode '#{ activity["episode"]["title"] }' (#{ activity["episode"]["season"]}x#{ activity["episode"]["episode"] }) of '#{ activity["show"]["title"] }' (#{ activity["show"]["year"] }) to his/her collection."
				end
			elsif activity["action"] == "seen"
				if activity["type"] == "movie"
					chat_msg = "#{ username } marked the movie '#{ activity["movie"]["title"] }' (#{ activity["movie"]["year"] }) as seen."
				elsif activity["type"] == "episode"
					chat_msg = "#{ username } marked the episode '#{ activity["episode"]["title"] }' (#{ activity["episode"]["season"]}x#{ activity["episode"]["episode"] }) of '#{ activity["show"]["title"] }' (#{ activity["show"]["year"] }) as seen."
				end
			end

			Channel(IRC_CHANNEL).send chat_msg
		end

		@@last_time = ts
	end

	def ts_get()
		url = "http://api.trakt.tv/server/time.json/#{ TRAKT_APIKEY }"
		resp = Net::HTTP.get_response(URI.parse(url))
		data = resp.body
		result = JSON.parse(data)
		result["timestamp"]
	end

	def trakt_get(start_ts, end_ts)
		url = "http://api.trakt.tv/activity/friends.json/#{ TRAKT_APIKEY }/all/all/#{ @@last_time }/#{ end_ts }"
		url = URI.parse(url)
		req = Net::HTTP::Post.new(url.path)
		req.basic_auth TRAKT_USERNAME, TRAKT_PASSWORD
		resp = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
		result = JSON.parse(resp.body)
		result
	end
end

bot = Cinch::Bot.new do
	configure do |c|
		c.nick = IRC_NICK
		c.server = IRC_SERVER
		c.channels = [IRC_CHANNEL]
		c.port = IRC_PORT
		c.verbose = true
		c.plugins.plugins = [TraktPlugin]
		c.ssl = IRC_SSL
	end
end

bot.start

