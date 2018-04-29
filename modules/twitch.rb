require 'discordrb'
require 'json'
require 'net/http'

module Twitch
	@@clientID='r92qo8y21vc1u4q5r6szfjhp9t1fbo'
	@@chkThread
	
	@@subbed
	if File.file?("twitch.yml")
		@@subbed=YAML.load_file("twitch.yml")
		p @@subbed
		else
		confFile=File.open("twitch.yml","w+")
		@@subbed=YAML.load_file(confFile)
		@@subbed=Hash.new
		confFile.write(YAML.dump(@@subbed))
		confFile.close
	end
	
	def Twitch.checkStreams(streams)
		status=Hash.new
		streams.each do |stream|
			url = 'https://api.twitch.tv/kraken/streams/%s?client_id=%s' % [stream, @@clientID]
			uri = URI(url)
			res = Net::HTTP.get(uri)
			status[stream] = JSON.parse(res)
		end
		return status
	end
	
	def Twitch.main(bot, owners)
		@@chkThread=Thread.new {
			while true
				sleep 60
				if @@subbed.empty? == false then
					status=Twitch.checkStreams(@@subbed.keys)
					status.each do |k, v|
						if v['stream']!=nil then
							if @@subbed[k][0] then
								@@subbed[k].drop(1).each do |chan|
									bot.send_message(chan, "%s is playing '%s' at %s !" % [ v['stream']['channel']['display_name'], v['stream']['game'], v['stream']['channel']['url'] ])
								end
								@@subbed[k][0]=false
							end
						else
							@@subbed[k][0]=true
						end
					end
				end
			end
		}
		
		bot.command(:sub, min_args:1, max_args:1, description:'Subscribes this channel to receive notifications when the given Twitch channel goes live. Limited to owner.', usage:'sub <channel>') do |_event, chan|
			break unless owners.include?(_event.user.id)
			
			if @@subbed[chan]==nil then
				@@subbed[chan]=Array.new
				@@subbed[chan][0]=true
			else
				if @@subbed[chan].index(_event.channel.id)!=nil then
					_event << "Channel is already subscribed for updates on %s! To unsubscribe, use !unsub." % [chan]
					break
				end
			end
			
			@@subbed[chan].push(_event.channel.id)
			_event << "Channel now subscribed for '%s'" % [chan]
			
			confFile=File.open("twitch.yml","w+")
			confFile.write(YAML.dump(@@subbed))
			confFile.close
			return nil
		end
		
		bot.command(:unsub, min_args:1, max_args:1, description:'Unsubscribes this channel from receiving notifications about the given Twitch channel. Limited to owner.', usage:'unsub <channel>') do |_event, chan|
			break unless owners.include?(_event.user.id)
			
			if @@subbed[chan]==nil || @@subbed[chan].delete(_event.channel.id)==nil then
				_event << "Channel is not subscribed for updates on %s!" % [chan]
			else
				if @@subbed[chan].size<2 then
					@@subbed.delete(chan)
				end
				_event << "Successfully unsubscribed from updates on %s!" % [chan]
			end
			
			confFile=File.open("twitch.yml","w+")
			confFile.write(YAML.dump(@@subbed))
			confFile.close
			return nil
		end
		
		bot.command(:subs, min_args:0, max_args:0, description:'Shows all subscribed to Twitch channels and what Discord channels are subscribed to them.', usage:'subs') do |_event|
			text=""

			@@subbed.each do |k, v|
				text << "Twitch channel %s:\n" % [k]
				v.drop(1).each do |x|
					text << "<#%i>\n" % [x]
				end
				text << "\n\n"
			end
			
			_event << text
		end
		bot.command(:subhash ,min_args:0, max_args:0, description:'Prints the Twitch subscription hash. Limited to owner.', usage:'subhash') do |_event|
			break unless owners.include?(_event.user.id)
			
			_event << @@subbed
		end
	end
		
	def Twitch.cleanup(bot)
		@@chkThread.exit
		
		confFile=File.open("twitch.yml","w+")
		confFile.write(YAML.dump(@@subbed))
		confFile.close
	end
end
