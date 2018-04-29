#!/usr/bin/ruby
::RBNACL_LIBSODIUM_GEM_LIB_PATH = "D:/Dev/DiibyBot/bot/libsodium.dll"
require 'discordrb'
require 'yaml'

config=nil
if File.file?("conf.yml")
	config=YAML.load_file("conf.yml")
	p config
else
	p "No configuration file found, aborting."
	abort
end

bot=Discordrb::Commands::CommandBot.new token: config['settings'][0], client_id: config['settings'][1], prefix: config['settings'][2]

modules = Dir['./modules/*.rb'].each {|x| x[/.*\//]}
modules.each_index {|x| modules[x]=modules[x].sub(/\.[^.]+\//,'')}

modules.each do |x|
	load './modules/'+x
	Kernel.const_get(x.sub(/\.[^.]+\z/,'').capitalize).send('main', bot, config['owners'])
end


bot.command(:quit, description:"Limited to owner, shutdowns bot.", usage:"quit") do |_event|
	break unless config['owners'][0]==_event.user.id
	
	modules.each do |x|
		Kernel.const_get(x.sub(/\.[^.]+\z/,'').capitalize).send('cleanup', bot)
	end
	
	exit(0)
end

bot.command(:reload, description:"Limited to owner, reloads all modules", usage:"reload") do |event|
	break unless config['owners'][0]==_event.user.id
	
	modules.each do |x|
		Kernel.const_get(x.sub(/\.[^.]+\z/,'').capitalize).send('cleanup', bot)
	end
	
	modules = Dir['./modules/*.rb'].each {|x| x[/.*\//]}
	modules.each_index {|x| modules[x]=modules[x].sub(/\.[^.]+\//,'')}
	
	modules.each do |x|
		load './modules/'+x
		Kernel.const_get(x.sub(/\.[^.]+\z/,'').capitalize).send('main', bot, config['owners'])
	end
	
	event << "Reloaded all modules!"
end

bot.command(:restart, description:"Limited to owner, restarts bot, reloading sourcefile.", usage:"restart") do |_event|
	break unless config['owners'][0]==_event.user.id
	
	confFile=File.open("db.yml","w+")
	confFile.write(YAML.dump(conf))
	confFile.close
	
	IO.popen("start cmd /C ruby.exe #{$0} #{ARGV.join(' ')}")
	sleep 5
	exit(0)
end

bot.command(:name, description:"Limited to owner, changes bot's name", usage:"name <name>") do |_event, newname|
	break unless config['owners'][0]==_event.user.id
	
	bot.profile.username=newname
end

bot.run