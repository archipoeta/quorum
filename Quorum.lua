-- Title: Quorum
-- Desc: A Meeting/Voting Add-On for
--      The Elder Scrolls Online
-- Author: @archpoet, <archipoetae@gmail.com>
-- Date: 2014.04.06
-- Repo: https://github.com/archipoeta/quorum

if ( Q == nil ) then Q = {} end
local wm = WINDOW_MANAGER

Q.version = "1.0.4"

function Q.init()
	Q.character_name = GetDisplayName()
	Q.quora = {}

	Q.guild_names = {
		GetGuildName(1), GetGuildName(2), GetGuildName(3), GetGuildName(4), GetGuildName(5)
	}

	Q.guild_channels = {
		CHAT_CHANNEL_GUILD_1, CHAT_CHANNEL_GUILD_2, CHAT_CHANNEL_GUILD_3, CHAT_CHANNEL_GUILD_4, CHAT_CHANNEL_GUILD_5
	}

	Q.format_regex = " ~\t"
	Q.default_color = { 207, 220, 189 }	--ElderScrolls Default-Text (Cream/Tan)
	Q.close_hover_color = { 255, 192, 0 }	-- Orange
	Q.title_hover_color = { 0, 192, 255 }	-- Aqua
	Q.tab_hover_color = { 128, 128, 240 }	-- Periwinkle

	Q.tab_colors = {
		{ 255, 221, 255 }, -- Violet
		{ 255, 221, 255 },
		{ 221, 255, 255 }, -- Cyan
		{ 255, 221, 221 }, -- Red
		{ 221, 221, 255 }, -- Indigo
		{ 221, 221, 255 },
		{ 221, 221, 255 }
	}
	
	for i = 1, #Q.guild_names do
		if not ( Q.guild_names[i] == "" ) then
			local player = GetPlayerGuildMemberIndex(i)
			local name, note, rank, stat, last = GetGuildMemberInfo( i, player )
			Q.quora[ i ] = {
				guild_name = Q.guild_names[i],
				meeting_in_progress = false,
				vote_in_progress = false,
				votes = { ["yea"] = {}, ["nay"] = {}, ["abs"] = {}, },
				chair = "N/A",
				speaker = "N/A",
				move = 0,
				motion_body = "",
				player_rank = rank,
			}
		end
	end

end

function Q.init_saved_vars()
	Q.quora = ZO_SavedVars:NewAccountWide( "Quorum_SavedVariables", 1, "quora", Q.quora )
end

function Q.AddSlashCommands()
	SLASH_COMMANDS["/quo"] = function()
		if ( Quorum.hidden ) then
			Quorum:SetHidden(false)
			Quorum.hidden = false
		else
			Quorum:SetHidden(true)
			Quorum.hidden = true
		end
	end
	SLASH_COMMANDS["/g1invite"] = function(extra)
		if ( extra == nil or extra == "" ) then
			return p("Please provide the name of someone to invite")
		else
			GuildInvite( 1, tostring(extra) )
		end
	end
	SLASH_COMMANDS["/g2invite"] = function(extra)
		if ( extra == nil or extra == "" ) then
			return p("Please provide the name of someone to invite")
		else
			GuildInvite( 2, tostring(extra) )
		end
	end
	SLASH_COMMANDS["/g3invite"] = function(extra)
		if ( extra == nil or extra == "" ) then
			return p("Please provide the name of someone to invite")
		else
			GuildInvite( 3, tostring(extra) )
		end
	end
	SLASH_COMMANDS["/g4invite"] = function(extra)
		if ( extra == nil or extra == "" ) then
			return p("Please provide the name of someone to invite")
		else
			GuildInvite( 4, tostring(extra) )
		end
	end
	SLASH_COMMANDS["/g5invite"] = function(extra)
		if ( extra == nil or extra == "" ) then
			return p("Please provide the name of someone to invite")
		else
			GuildInvite( 5, tostring(extra) )
		end
	end	
end

function Q.ElementHoverOn(element, rgb)
	element:SetColor( rgb[1]/255, rgb[2]/255, rgb[3]/255, 1 )
end

function Q.ElementHoverOff(element, rgb)
	element:SetColor( rgb[1]/255, rgb[2]/255, rgb[3]/255, 1 )
end

function Q.get_table_length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function Q.HandleMotion( key, value )
	if ( string.find( key, 'Guild:\t' ) ) then
		if ( value > 5 ) then
			value = 1
		elseif ( value ~= 5 ) then
			value = value + 1
		end
			
		if ( Q.guild_names[ value ] == "" ) then
			value = 1
		end
				
		Q.ShowSummary(value)
	elseif ( string.find( key, 'I move to' ) ) then
		for i = 3, 10, 1 do
			if ( wm:GetControlByName( i ) ) then
				local control = wm:GetControlByName( i )
				control:SetText("")
			end
		end
		local control = wm:GetControlByName( "QuorumMotionBody" )
		control:SetHidden(false)
		control:SetText(value)
		control:SetPasteEnabled(true)
		--control:SetKeyboardEnabled(true)
		control:TakeFocus()
		
		local ok = wm:GetControlByName( "QuorumMotionBodyOK" )
		ok:SetHidden(false)
		ok:SetMouseEnabled(true)
		local cancel = wm:GetControlByName( "QuorumMotionBodyCANCEL" )
		cancel:SetHidden(false)
		cancel:SetMouseEnabled(true)
		
		ok:SetHandler( "OnMouseDown", function() Q.MotionBodyOK(ok, cancel, control) end )
		cancel:SetHandler( "OnMouseDown", function() Q.MotionBodyCANCEL(ok, cancel, control) end )
	else
		if not ( value == 0 ) then
			CHAT_SYSTEM:AddMessage(value)
			ZO_ChatWindowTextEntryEditBox:SetText( "/g" .. Q.active_guild .. Q.format_regex .. "|cDA77FF" .. value .. "|r" )
		end		
	end
end

function Q.IsIn(value, array)
	if (#array == 0) then
		return false
	end
	for i = 1, #array do
		if (array[i] == value) then
			return i
		end
	end
	return false
end

function Q.MotionBodyOK(ok, cancel, control)
	local text = control:GetText()
	control:SetText("")
	control:LoseFocus()
	control:SetHidden(true)
	
	ok:SetHidden(true)
	cancel:SetHidden(true)
	
	CHAT_SYSTEM:AddMessage(text)
	ZO_ChatWindowTextEntryEditBox:SetText( "/g" .. Q.active_guild .. Q.format_regex .. "|cDA77FF" .. text .. "|r" )
	
	Q.ShowMainMotions()
end

function Q.MotionBodyCANCEL(ok, cancel, control)
	control:LoseFocus()
	control:SetHidden(true)
	ok:SetHidden(true)
	cancel:SetHidden(true)
	
	Q.ShowMainMotions()
end

function Q.PairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0
	local iter = function ()
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

function Q.ShowActions( actions )
	for j = 1, 10, 1 do
		if ( wm:GetControlByName( j ) ) then
			local control = wm:GetControlByName( j )
			control:SetText("")
		end
	end

	local delta_y = 1

	for i = 1, #actions, 1 do
		for j = 1, #actions[i], 1 do
			if not ( wm:GetControlByName( i ) ) then
				local control = wm:CreateControl( i, Quorum, CT_LABEL )
				control:SetParent(Quorum)
				control:SetAnchor(TOPLEFT, Quorum, TOPLEFT, 5, 43 + delta_y)
				control:SetResizeToFitDescendents(true)
				control:SetMouseEnabled(true)
				control:SetFont("ZoFontGame")
				control:SetText(actions[i][1])
				control:SetHandler( "OnMouseDown", function() Q.HandleMotion(actions[i][1], actions[i][2]) end )
				control:SetHandler( "OnMouseEnter", function()
					control:SetColor(0,1,0,1)
				end )
				control:SetHandler( "OnMouseExit", function()
					control:SetColor(240,240,240,1)
				end )
			else
				local control = wm:GetControlByName( i )
				control:SetText(actions[i][1])
				control:SetHandler( "OnMouseDown", function() Q.HandleMotion(actions[i][1], actions[i][2]) end )
			end
		end
		delta_y = delta_y + 25
	end
end

function Q.ShowHelpMenu()
	local motions = {
		{ "\t\t Title: Quroum", 0 },
		{ "\t\t Desc: Meeting Add-On for ESO", 0 },
		{ "\t\t Author: @archpoet", 0 },
		{ "\t\t Version: " .. Q.version, 0 },
		{ "\t\t http://imperialsenate.org/forum", 0 },
	}

	Q.ShowActions( motions )
end

function Q.ShowMainMotions()
	local motions = {
		{ "1.\t\t I move to/that", "I MOVE THAT ... " },
		{ "2.\t\t Second a Motion", "SECONDED." },
		{ "3.\t\t Yield the Floor", "I YIELD." },
		{ "4.\t\t Withdraw Your Motion", "MOTION TO WITHDRAW." },
		{ Q.info },
	}

	Q.ShowActions( motions )
end

function Q.ShowPrivMotions()
	local motions = {
		{ "1.\t\t Close Meeting", "MOTION TO ADJOURN." },
		{ "2.\t\t Take A Break", "MOTION TO RECESS." },
		{ "3.\t\t Complain about noise, heat, etc.", "QUESTION OF PRIVILEGE." },
		{ "4.\t\t Follow Agenda", "CALL FOR THE ORDERS OF THE DAY." },
	}

	Q.ShowActions( motions )
end

function Q.ShowSubMotions()
	local motions = {
		{ "1.\t\t Skip Motion", "MOTION TO TABLE THE QUESTION." },
		{ "2.\t\t Close Debate and Vote", "MOTION TO THE PREVIOUS QUESTION." },
		{ "3.\t\t Limit/Extend Debate", "MOTION TO LIMIT DEBATE." },
		{ "3.\t\t Amend Motion", "MOTION TO AMEND." },
		{ "4.\t\t Substitute Motion", "MOTION TO SUBSTITUTE." },
	}

	Q.ShowActions( motions )
end

function Q.ShowIncidentMotions()
	local motions = {
		{ "1.\t\t Get Information", "POINT OF INFORMATION." },
		{ "2.\t\t Enforce Rules", "POINT OF ORDER." },
		{ "3.\t\t Ignore Rules", "MOTION TO SUSPEND THE RULE." },
		{ "4.\t\t Appeal Chair Decision", "MOTION TO APPEAL FROM THE DECISION OF THE CHAIR." },
		{ "5.\t\t Objection to Motion", "OBJECTION TO CONSIDERATION OF THE QUESTION." },
		{ "6.\t\t Split Motion into Parts", "MOTION TO DIVIDE THE QUESTION." },
	}

	Q.ShowActions( motions )
end

function Q.ShowOtherMotions()
	local motions = {
		{ "1.\t\t Reconsider skipped Motion", "MOTION TO TAKE FROM THE TABLE." },
		{ "2.\t\t Reconsider voted Motion", "MOTION TO RECONSIDER." },
		{ "3.\t\t Rescind/Revoke voted Motion", "MOTION TO RESCIND." },
		{ "4.\t\t Amend carried/voted Motion", "MOTION TO AMEND." },
	}
	
	Q.ShowActions( motions )
end

function Q.ShowChairActions()
	local motions = {
		{ "1.\t\t Begin Meeting", "CALL TO ORDER." },
		{ "2.\t\t Recognize Speaker", "THE CHAIR RECOGNIZES : " },
		{ "3.\t\t Recess Meeting", "MEETING IS IN RECESS." },
		{ "4.\t\t End Meeting", "MEETING IS ADJOURNED." },
	}
	
	Q.ShowActions( motions )
end

function Q.ShowChairAnswers()
	local motions = {
		{ "1.\t\t Enforce Order", "POINT OF ORDER." },
		{ "2.\t\t Point Accepted", "YOUR POINT IS WELL TAKEN." },
		{ "3.\t\t Point Denied", "YOUR POINT IS NOT WELL TAKEN." },
		{ "4.\t\t Motion Succeeds", "MOTION CARRIED." },
		{ "5.\t\t Motion Fails", "MOTION DENIED." },		
		{ "6.\t\t Sustain Objection", "SUSTAINED." },
		{ "7.\t\t Overrule Objection", "OVERRULED." },
	}
	
	Q.ShowActions( motions )
end

function Q.ShowChairQuestions()
	local motions = {
		{ "1.\t\t Any Seconds?", "MOTION ON THE FLOOR, DO I HEAR A SECOND?" },
		{ "2.\t\t Open Debate on a Motion", "IT HAS BEEN MOVED AND SECONDED, IS THERE ANY DISCUSSION?" },
		{ "3.\t\t Ask for Point", "WHAT IS YOUR POINT?" },
		{ "4.\t\t Two-thirds to Close Debate", "THE QUESTION HAS BEEN CALLED. SHALL IT BE PUT?" },
		{ "5.\t\t Open Vote on a Motion", "THE QUESTION HAS BEEN PUT. ALL IN FAVOR, OPPOSED?" },
		{ "6.\t\t Ask speaker to yield", "WILL YOU YIELD THE FLOOR?" },
	}
	
	Q.ShowActions( motions )
end

function Q.ShowVotingActions()
	local motions = {
		{ "1.\t\t Yes", "YEA." },
		{ "2.\t\t No", "NAY." },
		{ "3.\t\t Abstain from Voting", "I ABSTAIN." },
	}
	
	Q.ShowActions( motions )
end

function Q.ShowSummary( guild )
	for j = 1, 10, 1 do
		if ( wm:GetControlByName( j ) ) then
			local control = wm:GetControlByName( j )
			control:SetText("")
		end
	end

	local meetings = {}

	if ( guild == nil ) or ( guild == 0 ) then
		if not ( Q.active_guild == nil ) then
			guild = Q.active_guild
		else
			guild = 1
		end
	end

	Q.active_guild = guild

	local meeting_count = 0
	local v = Q.quora[guild]

	if ( v ~= nil and type(v) == "table" ) then
		--if ( v.meeting_in_progress == true ) then
			--meeting_count = meeting_count + 1
			Q.ShowActions( {
				{ "Guild:\t\t " .. tostring(v.guild_name) .. "\t\t>>", guild },
				{ "Meeting Now:\t\t " .. tostring(v.meeting_in_progress), 0 },
				{ "Chair:\t\t " .. tostring(v.chair), 0 },
				{ "Floor:\t\t " .. tostring(v.speaker), 0 },
				{ "Move:\t\t "  .. tostring(v.move), 0 },
				{ "Question:\t\t " .. tostring(v.motion_body), 0 },
				{ "Voting Now:\t\t " .. tostring(v.vote_in_progress), 0 },
				{ "Votes:\t\t " .. tostring( Q.get_table_length(v.votes.yea) ) .. " / " .. tostring( Q.get_table_length(v.votes.nay) ) .. " / " .. tostring( Q.get_table_length(v.votes.abs) ), 0 },
			} )
		--end

		if ( v.player_rank > 2 ) or ( v.player_rank == nil ) then
			Section7:SetHidden(true)
			Section7.hidden = true
			Section8:SetHidden(true)
			Section8.hidden = true
			Section9:SetHidden(true)
			Section9.hidden = true			
		elseif ( v.player_rank < 2 ) then
			Section7:SetHidden(false)
			Section7.hidden = false
			Section8:SetHidden(false)
			Section8.hidden = false
			Section9:SetHidden(false)
			Section9.hidden = false			
		end

		if ( v.meeting_in_progress == false ) then
			--Q.ShowActions( { { "No Meeting currently in session.", 0 } } )
			Notify:SetText( "No Meeting." )
		end
	end
end

-- parse lines of guild chat to watch for votes,motions,etc.
function Q.OnMessageReceived(event_code, message_type, from_name, text)
	local guild_id = Q.IsIn(message_type, Q.guild_channels)
	if ( guild_id and string.find( text, Q.format_regex ) ) then
		--CHAT_SYSTEM:AddMessage( "Text matched the output of this add-on: " .. text )
		local message = text:gsub( Q.format_regex, "" )
		
		if ( string.find( message, "CALL TO ORDER." ) ) then
			Quorum:SetHidden(false)
			Quorum.hidden = false		

			Q.quora[guild_id].meeting_in_progress = true
			Q.quora[guild_id].chair = from_name
			Q.quora[guild_id].speaker = from_name
			Q.quora[guild_id].motion_body = message

			Notify:SetText( "/g" .. guild_id .. ": " .. message )
		elseif ( string.find( message, "THE CHAIR RECOGNIZES" ) ) then
			local name = string.match( message, ": (.*)")
			Q.quora[guild_id].speaker = name
		elseif ( string.find( message, "QUESTION HAS BEEN CALLED" ) ) then
			Notify:SetText( "/g" .. guild_id .. ": " .. "Vote to close debate on this question." )
			Q.quora[guild_id].speaker = "N/A"

		elseif ( string.find( message, "QUESTION HAS BEEN PUT" ) ) then
			Q.quora[guild_id].vote_in_progress = true
			Notify:SetText( "/g" .. guild_id .. ": " .. "Vote on Main Motion." )
			Q.quora[guild_id].speaker = "N/A"			

		elseif ( string.find( message, "YEA." ) ) then
			if ( Q.quora[guild_id].votes.yea[ Q.character_name ] == nil ) then
				Q.quora[guild_id].votes.yea[ Q.character_name ] = 1
				Q.quora[guild_id].votes.nay[ Q.character_name ] = nil
				Q.quora[guild_id].votes.abs[ Q.character_name ] = nil
			end
		elseif ( string.find( message, "NAY." ) ) then
			if ( Q.quora[guild_id].votes.nay[ Q.character_name ] == nil ) then
				Q.quora[guild_id].votes.nay[ Q.character_name ] = 1
				Q.quora[guild_id].votes.yea[ Q.character_name ] = nil
				Q.quora[guild_id].votes.abs[ Q.character_name ] = nil				
			end		
		elseif ( string.find( message, "I ABSTAIN." ) ) then
			if ( Q.quora[guild_id].votes.abs[ Q.character_name ] == nil ) then
				Q.quora[guild_id].votes.abs[ Q.character_name ] = 1
				Q.quora[guild_id].votes.yea[ Q.character_name ] = nil
				Q.quora[guild_id].votes.nay[ Q.character_name ] = nil
			end		
		elseif ( string.find( message, "MEETING IS ADJOURNED." ) ) then
			Q.quora[guild_id].meeting_in_progress = false
			Q.quora[guild_id].vote_in_progress = false
			Q.quora[guild_id].chair = "N/A"
			Q.quora[guild_id].speaker = "N/A"
			Q.quora[guild_id].move = 0
			Q.quora[guild_id].motion_body = message
		elseif ( string.find( message, "MEETING IS IN RECESS." ) ) then
			Q.quora[guild_id].meeting_in_progress = false
			Q.quora[guild_id].vote_in_progress = false
			Q.quora[guild_id].chair = "N/A"
			Q.quora[guild_id].speaker = "N/A"
			Q.quora[guild_id].move = 0
			Q.quora[guild_id].motion_body = message
		else
			Q.quora[guild_id].motion_body = message
		end

		if ( Q.quora[guild_id].speaker == Q.character_name ) then
			Notify:SetText( "/g" .. guild_id .. ": " .. "|c66FF66You have the floor!|r" )
		else
			Notify:SetText( "/g" .. guild_id .. ": " .. "|cFF6666You do not have the floor.|r" )
		end
--		SpamFilter.Debug("Validating message from "..fromName.." at "..tostring(GetTimeStamp()))
--		local ruleBroken = RuleBroken(fromName, text)
--		if (not IsIgnored(fromName) and ruleBroken ~= nil) then
--			-- Queue the player to be ignored ...
--			SpamFilter.ignoreQueue[fromName] = true
			
--			if not SpamFilter.ignoreQueueRunning then
--				zo_callLater(ProcessIgnoreQueue, 1);
--				SpamFilter.ignoreQueueRunning = true
--			end
			
			-- ... and queue the note to be set (since this is updated after event processing)
--			SpamFilter.noteNew = string.format(SpamFilter.EmitStrings.note, ruleBroken, GetDateStringFromTimestamp(GetTimeStamp()), GetTimeString())
			
--			SpamFilter.Emit(string.format(SpamFilter.EmitStrings.filtered, fromName, ruleBroken))
--		end
	end
end

--
-- MAIN
--

Q.init()
Q.AddSlashCommands()
EVENT_MANAGER:RegisterForEvent("Quorum", EVENT_CHAT_MESSAGE_CHANNEL, Q.OnMessageReceived)