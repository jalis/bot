require 'discordrb'
require 'twitch-api'

module Twitch
	@@client=Twitch::Client.new client_id: 'r92qo8y21vc1u4q5r6szfjhp9t1fbo'
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
	
	def Twitch.main(bot, owners)
		@@chkThread=Thread.new {
			users=Array.new
			live=Array.new
			while true
				sleep 60
				unless @@subbed.empty? then
					users=[]
					live=[]

					@@subbed.each do |k, v|
						users.push(v[1])
					end

					data=@@client.get_streams(user_id: users).data
					unless data.empty? then

						data.each do |x|
							chan=@@subbed.select{|k,v|v[1]==x.user_id}.keys[0].to_s
							live.push(chan)
							unless @@subbed[chan][0] then
								@@subbed[chan][0]=true
								@@subbed[chan].drop(2).each do |discordChannel|
									bot.send_message(discordChannel, "%s is live!\n%s\nhttps://twitch.tv/%s !" % [chan, x.title, chan])
								end
							end
						end
					end
					@@subbed.each do |k,v|
						unless live.include?(k) then
							@@subbed[k][0]=false
						end
					end
				end
			end
		}
		
		bot.command(:sub, min_args:1, max_args:1, description:'Subscribes this channel to receive notifications when the given Twitch channel goes live. Limited to owner.', usage:'sub <channel>') do |_event, chan|
			break unless owners.include?(_event.user.id)
			
			data=@@client.get_users(login: chan).data
			if data.empty? then
				_event << "No such channel exists!"
				break
			end
			id=data[0].id

			if @@subbed[chan]==nil then
				@@subbed[chan]=Array.new
				@@subbed[chan][0]=false
				@@subbed[chan][1]=id
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
				if @@subbed[chan].size<3 then
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
				v.drop(2).each do |x|
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
