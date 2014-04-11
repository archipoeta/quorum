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
	Q.account_name = GetDisplayName()
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
				notify_text = "No Meeting.",
				floor_queue = {},
			}
		end
	end

end

function Q.init_saved_vars()
	Q.quora = ZO_SavedVars:NewAccountWide( "Quorum_SavedVariables", 1, "quora", Q.quora )
end

function Q.add_slash_commands()
	SLASH_COMMANDS["/quo"] = function()
		if ( Quorum.hidden ) then
			Quorum:SetHidden(false)
			Quorum.hidden = false
		else
			Quorum:SetHidden(true)
			Quorum.hidden = true
		end
	end

	SLASH_COMMANDS["/gdemote"]		= function (extra) Q.guild_demote( Q.active_guild, extra) end
	SLASH_COMMANDS["/ginvite"]		= function (extra) Q.guild_invite( Q.active_guild, extra) end
	SLASH_COMMANDS["/gkick"]		= function (extra) Q.guild_remove( Q.active_guild, extra) end
	SLASH_COMMANDS["/gpromote"]		= function (extra) Q.guild_promote( Q.active_guild, extra) end
	SLASH_COMMANDS["/gquit"]		= function (extra) Q.guild_leave( Q.active_guild ) end

	SLASH_COMMANDS["/g1demote"]		= function (extra) Q.guild_demote( 1, extra) end
	SLASH_COMMANDS["/g1invite"]		= function (extra) Q.guild_invite( 1, extra) end
	SLASH_COMMANDS["/g1kick"]		= function (extra) Q.guild_remove( 1, extra) end
	SLASH_COMMANDS["/g1promote"]	= function (extra) Q.guild_promote( 1, extra) end
	SLASH_COMMANDS["/g1quit"]		= function (extra) Q.guild_leave( 1 ) end
	
	SLASH_COMMANDS["/g2demote"]		= function (extra) Q.guild_demote( 2, extra) end
	SLASH_COMMANDS["/g2invite"]		= function (extra) Q.guild_invite( 2, extra) end
	SLASH_COMMANDS["/g2kick"]		= function (extra) Q.guild_remove( 2, extra) end
	SLASH_COMMANDS["/g2promote"]	= function (extra) Q.guild_promote( 2, extra) end
	SLASH_COMMANDS["/g2quit"]		= function (extra) Q.guild_leave( 2 ) end
	
	SLASH_COMMANDS["/g3demote"]		= function (extra) Q.guild_demote( 3, extra) end
	SLASH_COMMANDS["/g3invite"]		= function (extra) Q.guild_invite( 3, extra) end
	SLASH_COMMANDS["/g3kick"]		= function (extra) Q.guild_remove( 3, extra) end
	SLASH_COMMANDS["/g3promote"]	= function (extra) Q.guild_promote( 3, extra) end
	SLASH_COMMANDS["/g3quit"]		= function (extra) Q.guild_leave( 3 ) end
	
	SLASH_COMMANDS["/g4demote"]		= function (extra) Q.guild_demote( 4, extra) end
	SLASH_COMMANDS["/g4invite"]		= function (extra) Q.guild_invite( 4, extra) end
	SLASH_COMMANDS["/g4kick"]		= function (extra) Q.guild_remove( 4, extra) end
	SLASH_COMMANDS["/g4promote"]	= function (extra) Q.guild_promote( 4, extra) end
	SLASH_COMMANDS["/g4quit"]		= function (extra) Q.guild_leave( 4 ) end
	
	SLASH_COMMANDS["/g5demote"]		= function (extra) Q.guild_demote( 5, extra) end
	SLASH_COMMANDS["/g5invite"]		= function (extra) Q.guild_invite( 5, extra) end
	SLASH_COMMANDS["/g5kick"]		= function (extra) Q.guild_remove( 5, extra) end	
	SLASH_COMMANDS["/g5promote"]	= function (extra) Q.guild_promote( 5, extra) end
	SLASH_COMMANDS["/g5quit"]		= function (extra) Q.guild_leave( 5 ) end

end

function Q.element_hover_on(element, rgb)
	element:SetColor( rgb[1]/255, rgb[2]/255, rgb[3]/255, 1 )
end

function Q.element_hover_off(element, rgb)
	element:SetColor( rgb[1]/255, rgb[2]/255, rgb[3]/255, 1 )
end

function Q.get_table_length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function Q.guild_demote( guild, player )
	if ( player == nil or player == "" ) then
		return d("Please provide the name of a guild member to demote.")
	else
		GuildDemote( guild, tostring(player) )
	end
end

function Q.guild_invite( guild, player )
	if ( player == nil or player == "" ) then
		return d("Please provide the name of someone to invite.")
	else
		GuildInvite( guild, tostring(player) )
	end
end

function Q.guild_leave( guild )
	GuildLeave( guild )
end

function Q.guild_promote( guild, player )
	if ( player == nil or player == "" ) then
		return d("Please provide the name of a guild member to promote.")
	else
		GuildPromote( guild, tostring(player) )
	end
end

function Q.guild_remove( guild, player )
	if ( player == nil or player == "" ) then
		return d("Please provide the name of a guild member to remove.")
	else
		GuildRemove( guild, tostring(player) )
	end
end

function Q.handle_motion( key, value )
	if ( string.find( key, 'Active:\t' ) ) then
		if ( value > 5 ) then
			value = 1
		elseif ( value ~= 5 ) then
			value = value + 1
		end
			
		if ( Q.guild_names[ value ] == "" ) then
			value = 1
		end
				
		Q.show_summary(value)
	elseif ( string.find( key, 'Recognize Speaker' ) ) then
		local first = Q.quora[ Q.active_guild ].floor_queue[1]
		ZO_ChatWindowTextEntryEditBox:SetText( "/g" .. Q.active_guild .. " " .. Q.format_regex .. "|cDA77FF" .. value .. "|r" .. first )
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
			ZO_ChatWindowTextEntryEditBox:SetText( "/g" .. Q.active_guild .. " " .. Q.format_regex .. "|cDA77FF" .. value .. "|r" )
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
	ZO_ChatWindowTextEntryEditBox:SetText( "/g" .. Q.active_guild .. " " .. Q.format_regex .. "|cDA77FF" .. text .. "|r" )
	
	Q.show_main_motions()
end

function Q.MotionBodyCANCEL(ok, cancel, control)
	control:LoseFocus()
	control:SetHidden(true)
	ok:SetHidden(true)
	cancel:SetHidden(true)
	
	Q.show_main_motions()
end

function Q.show_actions( actions )
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
				control:SetHandler( "OnMouseDown", function() Q.handle_motion(actions[i][1], actions[i][2]) end )
				control:SetHandler( "OnMouseEnter", function()
					control:SetColor(0,1,0,1)
				end )
				control:SetHandler( "OnMouseExit", function()
					control:SetColor(240,240,240,1)
				end )
			else
				local control = wm:GetControlByName( i )
				control:SetText(actions[i][1])
				control:SetHandler( "OnMouseDown", function() Q.handle_motion(actions[i][1], actions[i][2]) end )
			end
		end
		delta_y = delta_y + 25
	end
end

function Q.show_help_menu()
	local motions = {
		{ "\t\t Title: Quroum", 0 },
		{ "\t\t Desc: Meeting Add-On for ESO", 0 },
		{ "\t\t Author: @archpoet", 0 },
		{ "\t\t Version: " .. Q.version, 0 },
		{ "\t\t http://imperialsenate.org/forum", 0 },
	}

	Q.show_actions( motions )
end

function Q.show_main_motions()
	local motions = {
		{ "1.\t\t I move to/that", "I MOVE THAT ... " },
		{ "2.\t\t Second a Motion", "SECONDED." },
		{ "3.\t\t Yield the Floor", "I YIELD." },
		{ "4.\t\t Skip Debate, Vote", "MOTION TO ADOPT." },		
		{ "5.\t\t Withdraw Your Motion", "MOTION TO WITHDRAW." },
		{ Q.info },
	}

	Q.show_actions( motions )
end

function Q.show_priv_motions()
	local motions = {
		{ "1.\t\t Close Meeting", "MOTION TO ADJOURN." },
		{ "2.\t\t Take A Break", "MOTION TO RECESS." },
		{ "3.\t\t Complain about noise, heat, etc.", "QUESTION OF PRIVILEGE." },
		{ "4.\t\t Follow Agenda", "CALL FOR THE ORDERS OF THE DAY." },
	}

	Q.show_actions( motions )
end

function Q.show_sub_motions()
	local motions = {
		{ "1.\t\t Skip Motion", "MOTION TO TABLE THE QUESTION." },
		{ "2.\t\t Close Debate and Vote", "MOTION TO THE PREVIOUS QUESTION." },
		{ "3.\t\t Limit/Extend Debate", "MOTION TO LIMIT DEBATE." },
		{ "3.\t\t Amend Motion", "MOTION TO AMEND." },
		{ "4.\t\t Substitute Motion", "MOTION TO SUBSTITUTE." },
	}

	Q.show_actions( motions )
end

function Q.show_incident_motions()
	local motions = {
		{ "1.\t\t Get Information", "POINT OF INFORMATION." },
		{ "2.\t\t Enforce Rules", "POINT OF ORDER." },
		{ "3.\t\t Ignore Rules", "MOTION TO SUSPEND THE RULE." },
		{ "4.\t\t Appeal Chair Decision", "MOTION TO APPEAL FROM THE DECISION OF THE CHAIR." },
		{ "5.\t\t Objection to Motion", "OBJECTION TO CONSIDERATION OF THE QUESTION." },
		{ "6.\t\t Split Motion into Parts", "MOTION TO DIVIDE THE QUESTION." },
	}

	Q.show_actions( motions )
end

function Q.show_other_motions()
	local motions = {
		{ "1.\t\t Reconsider skipped Motion", "MOTION TO TAKE FROM THE TABLE." },
		{ "2.\t\t Reconsider voted Motion", "MOTION TO RECONSIDER." },
		{ "3.\t\t Rescind/Revoke voted Motion", "MOTION TO RESCIND." },
		{ "4.\t\t Amend carried/voted Motion", "MOTION TO AMEND." },
	}
	
	Q.show_actions( motions )
end

function Q.show_chair_actions()
	local motions = {
		{ "1.\t\t Begin Meeting", "CALL TO ORDER." },
		{ "2.\t\t Recognize Speaker", "THE CHAIR RECOGNIZES : " },
		{ "3.\t\t Recess Meeting", "MEETING IS IN RECESS." },
		{ "4.\t\t End Meeting", "MEETING IS ADJOURNED." },
	}
	
	Q.show_actions( motions )
end

function Q.show_chair_answers()
	local motions = {
		{ "1.\t\t Enforce Order", "POINT OF ORDER." },
		{ "2.\t\t Point Accepted", "YOUR POINT IS WELL TAKEN." },
		{ "3.\t\t Point Denied", "YOUR POINT IS NOT WELL TAKEN." },
		{ "4.\t\t Motion Succeeds", "MOTION CARRIED." },
		{ "5.\t\t Motion Fails", "MOTION LOST." },		
		{ "6.\t\t Sustain Objection", "SUSTAINED." },
		{ "7.\t\t Overrule Objection", "OVERRULED." },
	}
	
	Q.show_actions( motions )
end

function Q.show_chair_questions()
	local motions = {
		{ "1.\t\t Any Seconds?", "MOTION ON THE FLOOR, DO I HEAR A SECOND?" },
		{ "2.\t\t Open Debate on a Motion", "IT HAS BEEN MOVED AND SECONDED, IS THERE ANY DISCUSSION?" },
		{ "3.\t\t Ask for Point", "WHAT IS YOUR POINT?" },
		{ "4.\t\t Two-thirds to Close Debate", "THE QUESTION HAS BEEN CALLED. SHALL IT BE PUT?" },
		{ "5.\t\t Open Vote on a Motion", "THE QUESTION HAS BEEN PUT. ALL IN FAVOR, OPPOSED?" },
		{ "6.\t\t Ask speaker to yield", "WILL YOU YIELD THE FLOOR?" },
	}
	
	Q.show_actions( motions )
end

function Q.show_voting_actions()
	local motions = {
		{ "1.\t\t Yes", "YEA." },
		{ "2.\t\t No", "NAY." },
		{ "3.\t\t Abstain from Voting", "I ABSTAIN." },
	}
	
	Q.show_actions( motions )
end

function Q.show_summary( guild )
	for j = 1, 10, 1 do
		if ( wm:GetControlByName( j ) ) then
			local control = wm:GetControlByName( j )
			control:SetText("")
		end
	end

	if ( guild == nil ) or ( guild == 0 ) then
		if not ( Q.active_guild == nil ) then
			guild = Q.active_guild
		else
			guild = 1
		end
	end

	Q.active_guild = guild
	SetDisplayedGuild( Q.active_guild )

	local meeting_count = 0
	local v = Q.quora[guild]

	if ( v ~= nil and type(v) == "table" ) then
		Q.show_actions( {
			{ "Active:\t\t |cAAFF99" .. tostring(v.guild_name) .. "|r\t\t>>", guild },
			{ "Meeting Now:\t\t " .. tostring(v.meeting_in_progress), 0 },
			{ "Chair:\t\t " .. tostring(v.chair), 0 },
			{ "Floor:\t\t " .. tostring(v.speaker), 0 },
			{ "Move:\t\t "  .. tostring(v.move), 0 },
			{ "Question:\t\t " .. tostring(v.motion_body), 0 },
			{ "Voting Now:\t\t " .. tostring(v.vote_in_progress), 0 },
			{ "Votes:\t\t " .. tostring( Q.get_table_length(v.votes.yea) ) .. " / " .. tostring( Q.get_table_length(v.votes.nay) ) .. " / " .. tostring( Q.get_table_length(v.votes.abs) ), 0 },
		} )

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

		Notify:SetText( Q.quora[guild].notify_text )
		
	end
end

-- parse lines of guild chat to watch for votes,motions,etc.
function Q.on_message_received(event_code, message_type, from_name, text)
	local guild_id = Q.IsIn(message_type, Q.guild_channels)
	
	if not ( guild_id == false ) then
		if ( string.find( text, Q.format_regex ) ) then

			local message = text:gsub( Q.format_regex, "" )

			if ( string.find( message, "CALL TO ORDER." ) ) then
				Quorum:SetHidden(false)
				Quorum.hidden = false		

				Q.quora[guild_id].meeting_in_progress = true
				Q.quora[guild_id].chair = from_name
				Q.quora[guild_id].speaker = from_name
				Q.quora[guild_id].motion_body = message
				--Q.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. message
			elseif ( string.find( message, "SEEKS RECOGNITION" ) ) then
				table.insert( Q.quora[guild_id].floor_queue, from_name )
			elseif ( string.find( message, "THE CHAIR RECOGNIZES : " ) ) then
				local first = Q.quora[ guild_id ].floor_queue[1]
				table.remove( Q.quora[ guild_id ].floor_queue, 1 )
				Q.quora[ guild_id ].speaker = first
			elseif ( string.find( message, "QUESTION HAS BEEN CALLED" ) ) then
				Q.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. "Vote to close debate on this question."
				Q.quora[guild_id].speaker = "N/A"
			elseif ( string.find( message, "QUESTION HAS BEEN PUT" ) ) then
				Q.quora[guild_id].vote_in_progress = true
				Q.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. "Vote on Main Motion."
				Q.quora[guild_id].speaker = "N/A"			
			elseif ( string.find( message, "YEA." ) ) then
				if ( Q.quora[guild_id].votes.yea[ Q.account_name ] == nil ) then
					Q.quora[guild_id].votes.yea[ Q.account_name ] = 1
					Q.quora[guild_id].votes.nay[ Q.account_name ] = nil
					Q.quora[guild_id].votes.abs[ Q.account_name ] = nil
				end
			elseif ( string.find( message, "NAY." ) ) then
				if ( Q.quora[guild_id].votes.nay[ Q.account_name ] == nil ) then
					Q.quora[guild_id].votes.nay[ Q.account_name ] = 1
					Q.quora[guild_id].votes.yea[ Q.account_name ] = nil
					Q.quora[guild_id].votes.abs[ Q.account_name ] = nil				
				end
			elseif ( string.find( message, "I ABSTAIN." ) ) then
				if ( Q.quora[guild_id].votes.abs[ Q.account_name ] == nil ) then
					Q.quora[guild_id].votes.abs[ Q.account_name ] = 1
					Q.quora[guild_id].votes.yea[ Q.account_name ] = nil
					Q.quora[guild_id].votes.nay[ Q.account_name ] = nil
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
			elseif ( string.find( message, "I MOVE THAT|MOTION TO" ) ) then
				Q.quora[guild_id].motion_body = message
			end

		end

		if ( guild_id == Q.active_guild ) then
			if ( Q.account_name == tostring( Q.quora[guild_id].speaker ) ) then
				Q.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. "|c66FF66You have the floor!|r"
			else
				Q.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. "|cFF6666You do not have the floor.|r"
			end		
			Notify:SetText( Q.quora[guild_id].notify_text )
		end
	
	end
end

--
-- MAIN
--

Q.init()
Q.add_slash_commands()
EVENT_MANAGER:RegisterForEvent("Quorum", EVENT_CHAT_MESSAGE_CHANNEL, Q.on_message_received)