require 'discordrb'
#require 'google_drive'

module Ranbat
	@@ranbats
	if File.file?("ranbat.yml")
		@@ranbats=YAML.load_file("ranbat.yml")
		p @@ranbats
		else
		confFile=File.open("ranbat.yml","w+")
		@@ranbats=YAML.load_file(confFile)
		@@ranbats=Hash.new
		confFile.write(YAML.dump(@@ranbats))
		confFile.close
	end
	
#	@@gdsession=GoogleDrive::Session.from_config("gdconfig.json")
	
	def Ranbat.main(bot, owners)
		bot.command(:newranbat, min_args:1, description:'Create a new ranbat database with given arguments.', usage:'newranbat <name> [nth place points]...') do |_event, name, *points|
			if @@ranbats[name]!=nil then
				_event << "Ranbat by name '%s' already exists!" % [ name ]
				break
			end
			
			@@ranbats[name]=Hash.new
			@@ranbats[name]['owners']=Array.new
			@@ranbats[name]['owners'].push(_event.user.id)
			
			if points!=nil then
				@@ranbats[name]['points']=*points
			else
				@@ranbats[name]['points']=Array.new
			end
			
			@@ranbats[name]['points'].map!(&:to_i)
			
			@@ranbats[name]['players']=Hash.new
			@@ranbats[name]['results']=Hash.new
			@@ranbats[name]['spreadsheet']=""
			
			_event << "Created new ranbat under the name '%s'!" % [name]
			
			confFile=File.open("ranbat.yml","w+")
			confFile.write(YAML.dump(@@ranbats))
			confFile.close
			return nil
		end
		
		bot.command(:setscoring, min_args:2, description:'Sets the scoring system for given ranbat.', usage:'setscoring <name> [nth place points]...') do |_event, name, *points|
			if @@ranbats[name]==nil
				_event << "No ranbat by name '%s' exists!" % [name]
				break
			end
			
			unless @@ranbats[name]['owners'].include?(_event.user.id) then
				_event << "Only the owner(s) may modify a ranbat!"
				break
			end
			
			if points.kind_of?(Array) then
				@@ranbats[name]['points']=*points
			else
				@@ranbats[name]['points'].clear
				@@ranbats[name]['points'].push(points)
			end
			
			@@ranbats[name]['points'].map!(&:to_i)
			
			_event << "Modified scoring system for '%s'!" % [name]
			
			confFile=File.open("ranbat.yml","w+")
			confFile.write(YAML.dump(@@ranbats))
			confFile.close
			return nil
		end
		
		bot.command(:addscore, min_args:2, description:'Adds an automatically dated and scored result for ranbat with given name.', usage:'addscore <name> [nth placing player\'s name]...') do |_event, name, *players|
			if @@ranbats[name]==nil
				_event << "No ranbat by name '%s' exists!" % [name]
				break
			end
			
			unless @@ranbats[name]['owners'].include?(_event.user.id) then
				_event << "Only the owner(s) may modify a ranbat!"
				break
			end
			
			curtime=Time.new
			
			unless players.kind_of?(Array) then
				players=Array.new(players)
			end
			
			players.map!(&:downcase)
			
			@@ranbats[name]['results'][curtime]=players
			
			pntlength=@@ranbats[name]['points'].length
			
			players.each_index do |i|
				points=0
				if i>=pntlength then
					points=@@ranbats[name]['points'][-1]
				else
					points=@@ranbats[name]['points'][i]
				end
				
				if @@ranbats[name]['players'].has_key?(players[i]) then
					@@ranbats[name]['players'][players[i]]+=points
				else
					@@ranbats[name]['players'][players[i]]=points
				end
			end
			
			_event << "Successfully added scores!"
		end
		
		bot.command(:ranbathash, min_args:0, max_args: 0, description:'Prints @@ranbats. Limited to owners.', usage:'ranbathash') do |_event|
			_event << @@ranbats
		end
	end
	
	def Ranbat.cleanup(bot)
		
	end
end
