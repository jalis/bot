require 'discordrb'

module Matchmaking
	def Matchmaking.main(bot, owners)
		@@matches = Hash.new
		
		bot.command(:m, min_args:0, max_args:2, description:'Begin matchmaking on this channel with an optional keyword and time to match for in minutes.', usage:'!m <keyword> <time>') do |_event, key, matchtime|
			curtime=Time.new
			chid=_event.channel.id
			ch=_event.channel.name
			
			if @@matches[chid]==nil
				@@matches[chid]=Hash.new
			end
			
			if key==nil
				key=ch
				else
				key=key.downcase
			end
			
			if matchtime==nil
				matchtime=30
			end
			matchtime=matchtime.to_i
			
			matchtime=matchtime*60
			
			if @@matches[chid][key]!=nil
				if @@matches[chid][key][1]<curtime
					@@matches[chid][key].delete(1)
					@@matches[chid][key].delete(0)
					@@matches[chid].delete(key)
				elsif @@matches[chid][key][0]!=_event.user.id
					_event << "Another battle is coming your way! <@%s> <@%s>" % [@@matches[chid][key][0], _event.user.id.to_s]
					@@matches[chid][key].delete(1)
					@@matches[chid][key].delete(0)
					@@matches[chid].delete(key)
					break
				else
					@@matches[chid][key].delete(1)
					@@matches[chid][key].delete(0)
					@@matches[chid].delete(key)
					_event << "<@%i> has canceled matching for '%s'." % [ _event.user.id, key ]
					break
				end
			end
			if @@matches[chid][key]==nil
				@@matches[chid][key]=Array.new
				@@matches[chid][key][1]=Time.new
				@@matches[chid][key][1]=@@matches[chid][key][1]+matchtime
				@@matches[chid][key][0]=_event.user.id
				
				_event << "<@%i> is matching for '%s'!" % [ _event.user.id, key ]
				break
			end
		end
		
		bot.command(:hash, min_args:0, max_args:0, description:'Print matchmaking hash.', usage:'!hash') do |_event|
			break unless owners.include?(_event.user.id)
			
			_event << @@matches
		end
	end
	
	def Matchmaking.cleanup(bot)
		
	end
end
