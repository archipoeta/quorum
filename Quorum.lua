-- Title: Quorum
-- Desc: A Meeting/Voting Add-On for
--      The Elder Scrolls Online
-- Author: @archpoet, <archipoetae@gmail.com>
-- Date: 2014.04.06
-- Repo: https://github.com/archipoeta/quorum

Q = {}

Q.version = "1.0.1"
Q.formatRegex = " >\t"
Q.characterName = GetDisplayName()

Q.guilds = {
	GetGuildName(1), GetGuildName(2), GetGuildName(3), GetGuildName(4), GetGuildName(5)
}
Q.guildChannels = {
	CHAT_CHANNEL_GUILD_1, CHAT_CHANNEL_GUILD_2, CHAT_CHANNEL_GUILD_3, CHAT_CHANNEL_GUILD_4, CHAT_CHANNEL_GUILD_5
}

local wm = WINDOW_MANAGER

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

function Q.MotionBodyOK(ok, cancel, control)
	local text = control:GetText()
	control:SetText("")
	control:LoseFocus()
	control:SetHidden(true)
	
	ok:SetHidden(true)
	cancel:SetHidden(true)
	
	CHAT_SYSTEM:AddMessage(text)
	ZO_ChatWindowTextEntryEditBox:SetText( Q.formatRegex .. text)
	
	Q.ShowMainMotions()
end

function Q.MotionBodyCANCEL(ok, cancel, control)
	control:LoseFocus()
	control:SetHidden(true)
	ok:SetHidden(true)
	cancel:SetHidden(true)
	
	Q.ShowMainMotions()
end

function Q.HandleMotion( key, value )
	if not ( string.find( key, 'I move to' ) ) then
		if not ( value == 0 ) then
			CHAT_SYSTEM:AddMessage(value)
			ZO_ChatWindowTextEntryEditBox:SetText( Q.formatRegex .. value )
		end
	else
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
	end
end

function Q.ShowActions( actions )
	for j = 1, 10, 1 do
		if ( wm:GetControlByName( j ) ) then
			local control = wm:GetControlByName( j )
			control:SetText("")
		end
	end

	local i = 1
	local delta_y = 1
	
	for key, value in Q.PairsByKeys( actions ) do
		if not ( wm:GetControlByName( i ) ) then
			local control = wm:CreateControl( i, Quorum, CT_LABEL )
			control:SetParent(Quorum)
			control:SetAnchor(TOPLEFT, Quorum, TOPLEFT, 5, 85 + delta_y)
			control:SetResizeToFitDescendents(true)
			control:SetMouseEnabled(true)
			control:SetFont("ZoFontGame")
			control:SetText(key)
			control:SetHandler( "OnMouseDown", function() Q.HandleMotion(key, value) end )
			control:SetHandler( "OnMouseEnter", function()
				control:SetColor(0,1,0,1)
			end )
			control:SetHandler( "OnMouseExit", function()
				control:SetColor(240,240,240,1)
			end )
		else
			local control = wm:GetControlByName( i )
			control:SetText(key)
			control:SetHandler( "OnMouseDown", function() Q.HandleMotion(key, value) end )
		end
		delta_y = delta_y + 25
		i = i + 1
	end
end

function Q.ShowHelpMenu()
	local motions = {
		["\ta. Title: Quroum"]					= 0,
		["\tb. Desc: Meeting add-on for ESO"]	= 0,
		["\td. Author: @archpoet"]				= 0,
		["\tc. Version: " .. Q.version ] 		= 0,
		["\te. Help: http://imperialsenate.org/forum"]	= 0,
	}

	Q.ShowActions( motions )
end

function Q.ShowMainMotions()
	local motions = {
		["1. Stand to Speak/Request Floor"]	= "*SEEKS RECOGNITION OF THE CHAIR*",	
		["2. I move to/that"]	= "MOTION TO/THAT... ",
		["3. Second a Motion"]	= "SECONDED.",
	}

	Q.ShowActions( motions )
end

function Q.ShowPrivMotions()
	local motions = {
		["1. Close Meeting"]	= "MOTION TO ADJOURN.",
		["2. Take A Break"]		= "MOTION TO RECESS.",
		["3. Complaint"]		= "QUESTION OF PRIVILEGE.",
		["4. Follow Agenda"]	= "CALL FOR THE ORDERS OF THE DAY.",
	}

	Q.ShowActions( motions )
end

function Q.ShowSubMotions()
	local motions = {
		["1. Skip Motion"]			= "MOTION TO TABLE THE QUESTION.",
		["2. Close Debate"]			= "MOTION TO THE PREVIOUS QUESTION.",
		["3. Limit/Extend Debate"]	= "MOTION TO LIMIT DEBATE.",
		["3. Amend Motion"]			= "MOTION TO AMEND.",
		["4. Substitute Motion"]	= "MOTION TO SUBSTITUTE.",
	}

	Q.ShowActions( motions )
end

function Q.ShowIncidentMotions()
	local motions = {
		["1. Get Information"]			= "POINT OF INFORMATION.",
		["2. Enforce Rules"]			= "POINT OF ORDER.",
		["3. Ignore Rules"]				= "MOTION TO SUSPEND THE RULE.",
		["4. Appeal Chair Decision"]	= "MOTION TO APPEAL FROM THE DECISION OF THE CHAIR.",
		["5. Withdraw Your Motion"]		= "MOTION TO WITHDRAW.",
		["6. Objection to Motion"]		= "OBJECTION TO CONSIDERATION OF THE QUESTION.",
		["7. Split Motion into Parts"]	= "MOTION TO DIVIDE THE QUESTION.",
	}

	Q.ShowActions( motions )
end

function Q.ShowOtherMotions()
	local motions = {
		["1. Reconsider skipped Motion"]	= "MOTION TO TAKE FROM THE TABLE.",
		["2. Reconsider voted Motion"]		= "MOTION TO RECONSIDER.",
		["3. Rescind/Revoke voted Motion"]	= "MOTION TO RESCIND.",
		["4. Amend enacted/voted Motion"]	= "MOTION TO AMEND.",
	}
	
	Q.ShowActions( motions )
end

function Q.ShowChairActions()
	local motions = {
		["1. Begin Meeting"]			= "CALL TO ORDER.",
		["2. Recognize Speaker"]		= "THE CHAIR RECOGNIZES ",
		["3. Open Debate on a Motion"]	= "IT HAS BEEN MOVED AND SECONDED, IS THERE ANY DISCUSSION?",
	}
	
	Q.ShowActions( motions )
end

function Q.ShowVotingActions()
	local motions = {
		["1. Yes"]					= "YEA.",
		["2. No"]					= "NAY.",
		["3. Abstain from Voting"]	= "I ABSTAIN.",
	}
	
	Q.ShowActions( motions )
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

function Q.OnMessageReceived(eventCode, messageType, fromName, text)
	local num = Q.IsIn(messageType, Q.guildChannels)
	if ( num and string.find( text, Q.formatRegex ) ) then
		CHAT_SYSTEM:AddMessage( "Text matched the output of this add-on: " .. text )
		local guild = Q.guilds[num]
		
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

-- TODO:
-- Add EVENT_MANAGER for reading chat here,
-- parse lines of guild chat to watch for votes,motions,etc.

Q.AddSlashCommands()
EVENT_MANAGER:RegisterForEvent("Quorum", EVENT_CHAT_MESSAGE_CHANNEL, Q.OnMessageReceived)