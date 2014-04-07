-- Title: Quorum
-- Desc: A Meeting/Voting Add-On for
--      The Elder Scrolls Online
-- Author: @archpoet, <archipoetae@gmail.com>
-- Date: 2014.04.06
-- Repo: https://github.com/archipoeta/quorum

local Q = {}
local wm = WINDOW_MANAGER

--require "luasql.mysql"
--local env = mysql()

Q.version = "1.0.0"
Q.characterName = GetDisplayName()
Q.guilds = { GetGuildName(1), GetGuildName(2), GetGuildName(3), GetGuildName(4), GetGuildName(5) }

local function AddSlashCommands()
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

local function QPairsByKeys (t, f)
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

local function QMotionBodyOK(ok, cancel, control)
	local text = control:GetText()
	control:SetText("")
	control:LoseFocus()
	control:SetHidden(true)
	
	ok:SetHidden(true)
	cancel:SetHidden(true)
	
	CHAT_SYSTEM:AddMessage(text)
	ZO_ChatWindowTextEntryEditBox:SetText(text)
	
	QShowMainMotions()
end

local function QMotionBodyCANCEL(ok, cancel, control)
	control:LoseFocus()
	control:SetHidden(true)
	ok:SetHidden(true)
	cancel:SetHidden(true)
	
	QShowMainMotions()
end

local function QHandleMotion( key, value )
	if not ( string.find( key, 'I move to' ) ) then
		CHAT_SYSTEM:AddMessage(value)
		ZO_ChatWindowTextEntryEditBox:SetText(value)
	else
		for i = 51, 500, 25 do
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
		
		ok:SetHandler( "OnMouseDown", function() QMotionBodyOK(ok, cancel, control) end )
		cancel:SetHandler( "OnMouseDown", function() QMotionBodyCANCEL(ok, cancel, control) end )
	end
end

local function QShowActions( actions )
	local delta_y = 1

	for i = 1, 500, 25 do
		if ( wm:GetControlByName( i ) ) then
			local control = wm:GetControlByName( i )
			control:SetText("")
		end
	end
	
	for key, value in QPairsByKeys( actions ) do
		if not ( wm:GetControlByName( delta_y ) ) then
			local control = wm:CreateControl(delta_y, Quorum, CT_LABEL)
			control:SetParent(Quorum)
			control:SetAnchor(TOPLEFT, Quorum, TOPLEFT, 5, 85 + delta_y)
			control:SetResizeToFitDescendents(true)
			control:SetMouseEnabled(true)
			control:SetFont("ZoFontGame")
			control:SetText(key)
			control:SetHandler( "OnMouseDown", function() QHandleMotion(key, value) end )
			control:SetHandler( "OnMouseEnter", function()
				control:SetColor(0,1,0,1)
			end )
			control:SetHandler( "OnMouseExit", function()
				control:SetColor(240,240,240,1)
			end )
		else
			local control = wm:GetControlByName( delta_y )
			control:SetText(key)
			control:SetHandler( "OnMouseDown", function() QHandleMotion(key, value) end )
		end
		delta_y = delta_y + 25
	end

end

function QShowHelpMenu()
	local motions = {
		["\t\ta. Title: Quroum"] = "",
		["\t\tb. Desc: Meeting add-on for ESO"] = "",
		["\t\td. Author: @archpoet"] = "",
		["\t\tc. Version: " .. Q.version ] = "",
		["\t\te. Help: http://imperialsenate.org/forum"] = "",
	}

	QShowActions( motions )
end

function QShowMainMotions()
	local motions = {
		["1. Stand to Speak"] = "*SEEKS RECOGNITION OF THE CHAIR*",	
		["2. I move to/that"] = "MOTION TO/THAT... ",
		["3. Second a Motion"] = "SECONDED.",
	}

	QShowActions( motions )
end

function QShowPrivMotions()
	local motions = {
		["1. Close Meeting"] = "MOTION TO ADJOURN.",
		["2. Take A Break"] = "MOTION TO RECESS.",
		["3. Complaint"] = "QUESTION OF PRIVILEGE.",
		["4. Follow Agenda"] = "CALL FOR THE ORDERS OF THE DAY.",
		["5. Skip Motion"] = "MOTION TO TABLE THE QUESTION.",
	}

	QShowActions( motions )
end

function QShowSubMotions()
	local motions = {
		["1. Amend Motion"] = "MOTION TO AMEND.",
		["2. Substitute Motion"] = "MOTION TO SUBSTITUTE.",
	}

	QShowActions( motions )
end

function QShowIncidentMotions()
	local motions = {
		["1. Get Information"] = "POINT OF INFORMATION.",
		["2. Enforce Rules"] = "POINT OF ORDER.",
		["3. Ignore Rules"] = "MOTION TO SUSPEND THE RULE.",
		["4. Appeal Chair Decision"] = "MOTION TO APPEAL FROM THE DECISION OF THE CHAIR.",
	}

	QShowActions( motions )
end

function QShowOtherMotions()
	local motions = {
		["1. Reconsider tabled Motion"] = "MOTION TO TAKE FROM THE TABLE.",
		["2. Reconsider voted Motion"] = "MOTION TO RECONSIDER.",
		["3. Rescind/Revoke voted Motion"] = "MOTION TO RESCIND.",
		["4. Amend enacted/voted Motion"] = "MOTION TO AMEND.",
	}
	
	QShowActions( motions )
end

function QShowChairActions()
	local motions = {
		["1. Begin Meeting"] = "CALL TO ORDER.",
		["2. Recognize Speaker"] = "THE CHAIR RECOGNIZES ",
		["3. Open Debate on a Motion"] = "IT HAS BEEN MOVED AND SECONDED, IS THERE ANY DISCUSSION?",
	}
	
	QShowActions( motions )
end

function QShowVotingActions()
	local motions = {
		["1. Yes"] = "YEA.",
		["2. No"] = "NAY.",
		["3. Abstain from Voting"] = "I ABSTAIN.",
	}
	
	QShowActions( motions )
end

AddSlashCommands()

-- TODO:
-- Add EVENT_MANAGER for reading chat here,
-- parse lines of guild chat to watch for votes,motions,etc.