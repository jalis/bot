require 'discordrb'
require 'net/http'
require 'json'

module Steamhost
	@@steam_api_key='4FC20D1D4E24758A03450936868285AC'
	
	def Steamhost.vanityToID(vanity)
		url = 'https://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=%s&format=json&vanityurl=%s' % [@@steam_api_key, vanity]
		uri = URI(url)
		res = Net::HTTP.get(uri)
		id = JSON.parse(res)['response']['steamid']
		return id
	end
	
	def Steamhost.getSteamUserSummary(id)
		url = 'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=%s&format=json&steamids=%s' % [@@steam_api_key, id]
		uri = URI(url)
		res = Net::HTTP.get(uri)
		summary=JSON.parse(res)['response']['players'][0]
		return summary
	end
	
	def Steamhost.main(bot, owners)
		bot.command(:getlink, min_args:1, max_args:1, description:'Gets "Join Game" link for provided steam vanity or user id', usage:'getlink <user id or vanity>') do |_event, id|
			real_id=Steamhost.vanityToID(id)
			if real_id==nil then
				real_id=id
			end
			user_summary=Steamhost.getSteamUserSummary(real_id)
			
			if user_summary==nil then
				_event << "Error: No user found with given Steam Vanity or User ID."
				break
			end
			
			construct_link='steam://joinlobby/'
			
			game_id=user_summary['gameid']
			if game_id==nil then
				_event << "User is not hosting a game."
				break
				else
				construct_link << game_id
				construct_link << '/'
			end
			lobby_id=user_summary['lobbysteamid']
			if lobby_id==nil then
				_event << "User is not hosting a game."
				break
				else
				construct_link << lobby_id
				construct_link << '/'
			end
			construct_link << real_id
			
			_event << "<@%i> is hosting \"%s\"!\nLink to lobby: %s" % [_event.user.id, user_summary['gameextrainfo'], construct_link]
		end
	end
	def Steamhost.cleanup(bot)
		
	end
		
end