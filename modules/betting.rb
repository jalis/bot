require 'yaml'
require 'discordrb'

module Betting
	def Betting.main(bot, owners)
		@@conf
		if File.file?("db.yml")
			@@conf=YAML.load_file("db.yml")
			p @@conf
			else
			confFile=File.open("db.yml","w+")
			@@conf=YAML.load_file(@@confFile)
			@@conf=Hash.new
			@@conf['startmoney']=20
			@@conf['bets']=Hash.new
			@@conf['users']=Hash.new
			confFile.write(YAML.dump(@@conf))
			confFile.close
		end
		
		bot.command(:startmoney, min_args:1, max_args:1, description:'Sets the starting money for users', usage:'startmoney <amount>') do |_event, amount|
			break unless owners.include?(_event.user.id)
			
			@@conf['startmoney']=amount.to_i
			_event << 'Starting money set to D$%i' % [@@conf['startmoney']]
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
		
		bot.command(:bet, min_args:2, description:'Start a bet.', usage:'bet <amount> <subject>') do |_event, amount, *subject|
			if @@conf['users'][_event.user.id.to_s]==nil
				@@conf['users'][_event.user.id.to_s]=Array.new(2)
				@@conf['users'][_event.user.id.to_s][0]=@@conf['startmoney']
				@@conf['users'][_event.user.id.to_s][1]=0
			end
			
			if (@@conf['users'][_event.user.id.to_s][0]-@@conf['users'][_event.user.id.to_s][1]) < amount.to_i
				_event << 'Not enough money to make this bet!'
				break
			end
			@@conf['users'][_event.user.id.to_s][1]+=amount.to_i
			
			i=0
			while @@conf['bets'][i.to_s]!=nil do
				i+=1
			end
			
			@@conf['bets'][i.to_s]=Array.new(6)
			@@conf['bets'][i.to_s][0]=amount.to_i
			@@conf['bets'][i.to_s][1]=subject.join(' ')
			@@conf['bets'][i.to_s][2]=_event.user.id.to_s
			@@conf['bets'][i.to_s][3]=nil
			@@conf['bets'][i.to_s][4]=nil
			@@conf['bets'][i.to_s][5]=nil
			_event << '<@%i> bet D$%i on "%s"!' % [_event.user.id, @@conf['bets'][i.to_s][0], @@conf['bets'][i.to_s][1]]
			_event << 'Match the bet with *!match %i*' % [i]
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
		
		bot.command(:match, min_args:1, max_args:1, description:'Match a bet', usage:'match <bet ID>') do |_event, betID|
			if @@conf['users'][_event.user.id.to_s]==nil
				@@conf['users'][_event.user.id.to_s]=Array.new(2)
				@@conf['users'][_event.user.id.to_s][0]=@@conf['startmoney']
				@@conf['users'][_event.user.id.to_s][1]=0
			end
			
			if @@conf['bets'][betID]==nil
				_event << "Invalid bet ID!"
				break
			end
			
			if _event.user.id == @@conf['bets'][betID][2]
				_event << "Can't match your own bet, cheater!"
				break
			end
			
			if @@conf['bets'][betID][3]!=nil
				_event << "Bet already matched!"
				break
			end
			
			if (@@conf['users'][_event.user.id.to_s][0] - @@conf['users'][_event.user.id.to_s][1]) < @@conf['bets'][betID][0]
				_event << 'Not enough money to match the bet!'
				break
			end
			
			@@conf['users'][_event.user.id.to_s][1]+=@@conf['bets'][betID][0]
			
			@@conf['bets'][betID][3]=_event.user.id.to_s
			_event << '<@%i> just matched your bet for "%s", <@%i>!' % [_event.user.id, @@conf['bets'][betID][1], @@conf['bets'][betID][2]]
			_event << 'To resolve the bet, type *!resolve %s <1 or 2>*, 1 for the bet maker and 2 for the matcher' % [betID]
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
		
		bot.command(:resolve, min_args:2, max_args:2, description:'Resolves a bet', usage:'resolve <bet ID> <1 or 2>, 1 means the maker won, 2 means the matcher won.') do |_event, id, winner|
			if @@conf['bets'][id]==nil
				_event << "No such bet!"
				break
			end
			
			if @@conf['bets'][id][3]==nil
				_event << "Bet not yet matched!"
				break
			end
			
			if @@conf['bets'][id][2]!=_event.user.id.to_s and @@conf['bets'][id][3]!=_event.user.id.to_s
				_event << "Only bet maker or matcher can resolve the bet!"
				break
			end
			
			if @@conf['bets'][id][4]==nil
				if _event.user.id.to_s == @@conf['bets'][id][2]
					@@conf['bets'][id][4]=3
					else
					@@conf['bets'][id][4]=2
				end
				@@conf['bets'][id][5]=winner.to_i
				_event << "According to <@%i>, <@%s> won the D$%i bet on \"%s\", <@%s>.\nIf this is correct, type *!accept %s*\nIf this is incorrect, type *!decline %s*" % [_event.user.id, @@conf['bets'][id][winner.to_i+1], @@conf['bets'][id][0], @@conf['bets'][id][1], @@conf['bets'][id][@@conf['bets'][id][4]], id, id]
				else
				_event << 'Resolution already proposed!'
				break
			end
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
		
		bot.command(:accept, min_args:1, max_args:1, description:"Accept the proposed results of the bet", usage:"accept <bet ID>") do |_event, id|
			if @@conf['bets'][id]==nil
				_event << 'No such bet!'
				break
			end
			
			if @@conf['bets'][id][4]==nil
				_event << 'No resolution proposed yet!'
				break
			end
			
			if _event.user.id.to_s != @@conf['bets'][id][@@conf['bets'][id][4]]
				_event << 'Only <@%s> can accept this resolution!' % [ @@conf['bets'][id][4-@@conf['bets'][id][5]] ]
				break
			end
			
			if @@conf['bets'][id][5] == 1
				@@conf['users'][@@conf['bets'][id][2]][0]+=@@conf['bets'][id][0]
				@@conf['users'][@@conf['bets'][id][2]][1]-=@@conf['bets'][id][0]
				@@conf['users'][@@conf['bets'][id][3]][0]-=@@conf['bets'][id][0]
				@@conf['users'][@@conf['bets'][id][3]][1]-=@@conf['bets'][id][0]
				_event << "Congratulations <@%i>! You just won D$%i" % [@@conf['bets'][id][2].to_i, @@conf['bets'][id][0]]
				elsif @@conf['bets'][id][5] == 2
				@@conf['users'][@@conf['bets'][id][3]][0]+=@@conf['bets'][id][0]
				@@conf['users'][@@conf['bets'][id][3]][1]-=@@conf['bets'][id][0]
				@@conf['users'][@@conf['bets'][id][2]][0]-=@@conf['bets'][id][0]
				@@conf['users'][@@conf['bets'][id][2]][1]-=@@conf['bets'][id][0]
				_event << "Congratulations <@%i>! You just won D$%i" % [@@conf['bets'][id][3].to_i, @@conf['bets'][id][0]]
			end
			
			@@conf['bets'].delete(id)
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
		
		bot.command(:decline, min_args:1, max_args:1, description:"Decline the proposed results of the bet", usage:"decline <bet ID>") do |_event, id|
			if @@conf['bets'][id]==nil
				_event << 'No such bet!'
				break
			end
			
			if @@conf['bets'][id][4]==nil
				_event << 'No resolution proposed yet!'
				break
			end
			
			if _event.user.id.to_s != @@conf['bets'][id][2] and _event.user.id.to_s != @@conf['bets'][id][3]
				_event << 'Only <@%s> and <@%s> can decline this resolution!' % [ @@conf['bets'][id][2], @@conf['bets'][id][3] ]
				break
			end
			
			@@conf['bets'][id][4]=nil
			@@conf['bets'][id][5]=nil
			
			_event << 'Resolution declined!'
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
		
		bot.command(:abort, min_args:1, description:"Abort an ongoing bet.", usage:"abort <bet ID>") do |_event, id|
			if @@conf['bets'][id]==nil
				_event << "No such bet!"
				break
			end
			
			if _event.user.id.to_s!=@@conf['bets'][id][2]
				_event << "Only bet maker can abort a bet!"
				break
			end
			
			if @@conf['bets'][id][3]!=nil
				_event << "Can't abort matched bet!"
				break
			end
			
			_event << 'Deleting "%s".' % [@@conf['bets'][id][1]]
			@@conf['users'][@@conf['bets'][id][2]][1]-=@@conf['bets'][id][0]
			if @@conf['bets'][id][3]!=nil
				@@conf['users'][@@conf['bets'][id][3]][1]-=@@conf['bets'][id][0]
			end
			@@conf['bets'].delete(id)
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
		
		bot.command(:wealth, description:'Shows your D$', usage:'wealth') do |_event|
			if @@conf['users'][_event.user.id.to_s]==nil
				@@conf['users'][_event.user.id.to_s]=Array.new(2)
				@@conf['users'][_event.user.id.to_s][0]=@@conf['startmoney']
				@@conf['users'][_event.user.id.to_s][1]=0
			end
			
			_event << "<@%i> you have D$%i!\nYou're currently betting D$%i of your money!" % [_event.user.id, @@conf['users'][_event.user.id.to_s][0], @@conf['users'][_event.user.id.to_s][1]]
		end
		
		bot.command(:bets, description:'Lists all active bets', usage:'bets') do |_event|
			if @@conf['bets'].empty?
				_event << "No active bets!"
				break
			end
			
			matchedBets=""
			unmatchedBets=""
			
			@@conf['bets'].each do |x, value|
				if @@conf['bets'][x][3]==nil
					unmatchedBets << "\n" << x.to_s << ': "' << @@conf['bets'][x][1] << '"' << " for D$" << @@conf['bets'][x][0].to_s << ", made by *" << bot.users[@@conf['bets'][x][2].to_i].username << "*."
					else
					matchedBets << "\n" << x.to_s << ': "' << @@conf['bets'][x][1] << '"' << " for D$" << @@conf['bets'][x][0].to_s << ", made by *" << bot.users[@@conf['bets'][x][2].to_i].username << "*, matched by *" << bot.users[@@conf['bets'][x][3].to_i].username << "*."
				end
			end
			returnStr="-------\n**Matched bets:**"+matchedBets+"\n\n**Waiting for matches:**"+unmatchedBets
			
			_event << returnStr
		end
		
		bot.command(:reset, description:"Limited to owner, resets economy (and database).", usage:"reset") do |_event|
			break unless owners.include?(_event.user.id)
			
			@@conf.delete('users')
			@@conf.delete('bets')
			
			@@conf['users']=Hash.new
			@@conf['bets']=Hash.new
			
			
			_event << "Economy reset!"
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
		
		bot.command(:top, min_args:1, max_args:1, description:"Lists top 3 gamblers", usage:"top <top #>") do |_event, amount|
			top=Hash.new
			
			@@conf['users'].each do |key, value|
				top[key]=value[0]
			end
			
			realTop=top.sort_by {|key, value| value * -1}
			
			topString="Top %i gamblers:\n" % [amount.to_i]
			
			i=0
			while i < amount.to_i and i < realTop.length
				topString << "\n#%i: *%s* with D$%i" % [i+1, bot.users[realTop[i][0].to_i].username, realTop[i][1]]
				i+=1
			end
			
			
			_event << topString
		end
		
		bot.command(:clear, description:"Limited to owner, clears all bets.", usage:"clear") do |_event|
			break unless owners.include?(_event.user.id)
			
			@@conf.delete('bets')
			@@conf['bets']=Hash.new
			
			@@conf['users'].each do |k|
				@@conf['users'][k][1]=0
			end
			
			_event << "Cleared all bets!"
			
			confFile=File.open("db.yml","w+")
			confFile.write(YAML.dump(@@conf))
			confFile.close
			return nil
		end
	end
	def Betting.cleanup(bot)
		confFile=File.open("db.yml","w+")
		confFile.write(YAML.dump(@@conf))
		confFile.close
	end
end
