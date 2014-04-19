-- Title: Quorum
-- Desc: A Meeting/Voting Add-On for
--      The Elder Scrolls Online
-- Author: @archpoet, <archipoetae@gmail.com>
-- Date: 2014.04.06
-- Repo: https://github.com/archipoeta/quorum

if ( Q == nil ) then Q = {} end

local wm = WINDOW_MANAGER
local LAM = LibStub:GetLibrary("LibAddonMenu-1.0")

Q.version = "1.0.7"

--
-- INIT
--
function Q.init()
	Q.saved = {
		["addon_visible"] = true,
		["account_name"] = GetDisplayName(),
		["active_guild"] = 1,
		["quora"] = {},

		["format_regex"] = "~{(%d+)%.(%d+)%.(%d+)}	",

		["default_color"] = { 207, 220, 189 },	--ElderScrolls Default-Text (Cream/Tan)
		["close_hover_color"] = { 255, 192, 0 },	-- Orange
		["title_hover_color"] = { 0, 192, 255 },	-- Aqua
		["tab_hover_color"] = { 128, 128, 240 },	-- Periwinkle
		["chat_output_color"] = { 221, 128, 255, 255 }, --

		["tab_colors"] = {
			{ 255, 221, 255 }, -- Violet
			{ 255, 221, 255 },
			{ 221, 255, 255 }, -- Cyan
			{ 255, 221, 221 }, -- Red
			{ 221, 221, 255 }, -- Indigo
			{ 221, 221, 255 },
			{ 221, 221, 255 }
		},

		["display_position"] = { ["x"] = 200, ["y"] = 0 },

		["guild_names"] = {
			GetGuildName(1), GetGuildName(2), GetGuildName(3), GetGuildName(4), GetGuildName(5)
		},
		["guild_channels"] = {
			CHAT_CHANNEL_GUILD_1, CHAT_CHANNEL_GUILD_2, CHAT_CHANNEL_GUILD_3, CHAT_CHANNEL_GUILD_4, CHAT_CHANNEL_GUILD_5, CHAT_CHANNEL_SAY
		},
		
		["quorum_map"] = {
			["about"] = {
				["default"] = {
					{["option"] = "Title: Quroum",},
					{["option"] = "Desc: Meeting Add-On for ESO",},
					{["option"] = "Author: @archpoet",},
					{["option"] = "Version: " .. Q.version,},
					{["option"] = "http://imperialsenate.org/forum",},
				}
			},

			[1] = {
				["motions"] = {
					{
						["id"] = nil,
						["name"] = nil,
						["option"] = "No meeting currently in Session.",
						["value"] = nil,
					}
				},
				["incidentals"] = {},
				["chair"] = {
					{
						["id"] = "~{1.1.1}	",
						["name"] = "call_to_order",
						["option"] = "CALL TO ORDER",
						["value"] = "CALL TO ORDER.",
						["desc"] = "Begin Meeting. As the presiding officer (chair) of the meeting, call it to order.",
						["help"] = "Only use this to begin a meeting. Never for bringing order to unruly Senators.",
						["recv"] = function (guild_id, from_name, message)
							Q.toggle_addon_visible(true)
							Q.saved.active_guild = guild_id
							Q.saved.quora[guild_id].meeting_in_progress = true
							Q.saved.quora[guild_id].chair = from_name
							Q.saved.quora[guild_id].speaker = from_name
							Q.saved.quora[guild_id].motion_body = message
							Q.saved.quora[guild_id].move = 2
							Q.show_map_step(2)
						end,
					},
				},
			},
			[2] = {
				["motions"] = {
					{
						["id"] = "~{2.2.1}	",
						["name"] = "request_speaker",
						["option"] = "REQUEST THE FLOOR.",
						["value"] = "SEEKS RECOGNITION OF THE CHAIR.",
						["desc"] = "Request to speak. You must wait to be recognized by the chair before continuing.",
						["help"] = "Use this anytime you wish to have the floor. If you fail to obtain recognition before speaking, you may be out of order.",
						["recv"] = function (guild_id, from_name, message)
							table.insert( Q.saved.quora[guild_id].floor_queue, from_name )
						end,
					}
				},
				["incidentals"] = {

				},
				["chair"] = {
					{
						["id"] = "~{2.1.1}	",
						["name"] = "recognize_speaker",
						["option"] = "RECOGNIZE SPEAKER.",
						["value"] = function()
							if ( Q.get_table_length( Q.saved.quora[ Q.saved.active_guild ].floor_queue ) > 0 ) then
								ZO_ChatWindowTextEntryEditBox:SetText(
									"/g" .. Q.saved.active_guild .. " " .. "~{2.1.1}	" .. "|c" .. Q.saved.chat_motion_color .. "THE CHAIR RECOGNIZES : |r" .. Q.saved.quora[ Q.saved.active_guild ].floor_queue[1]
								)
							else
								d( "NO REQUESTORS QUEUED TO SPEAK." )
							end
						end,
						["desc"] = "Recognize a requestor as speaker. This gives them the floor.",
						["help"] = "Only one member is permitted to hold the floor at a time, therefore ask previous speakers to yield before recognizing new ones.",
						["recv"] = function (guild_id, from_name, message)
							Q.saved.quora[ guild_id ].speaker = Q.saved.quora[ guild_id ].floor_queue[1]						
							table.remove( Q.saved.quora[ guild_id ].floor_queue, 1 )
							Q.show_map_step(3)
						end,
					},
				},
			},
			[3] = {
				["motions"] = {
					{
						["id"] = "~{3.2.1}	",
						["name"] = "default_motion",
						["option"] = "I MOVE TO/THAT ...",
						["value"] = function() Q.default_motion_action("I MOVE THAT ... ") end,
						["desc"] = "Put a motion before the quorum of senators, (i.e. bring up new business.)",
						["help"] = "Use this when you want to bring up something new. An issue or suggestion that hasn't been put before the senate previously.",
						["recv"] = function ( guild_id, from_name, message )
							Q.saved.quora[guild_id].motion_body = message
							Q.saved.quora[guild_id].notify_text = "Motion on the floor needs second."
							Q.show_map_step(4)
						end,
					},

					{ "4.\t\t Skip Debate, Vote", "MOTION TO ADOPT." },
					{ "5.\t\t Withdraw Your Motion", "MOTION TO WITHDRAW." },
				},
				["incidentals"] = {
					{
						["id"] = "~{3.3.1}	",
						["name"] = "question_of_priv",
						["option"] = "QUESTION OF PRIVILEGE.",
						["value"] = "QUESTION OF PRIVILEGE.",
						["desc"] = "Complain about noise, heat, etc.",
						["help"] = "Basically, to complain about any distractions within the control of the chair, preventing you from focusing on the meeting.",
					},
					{
						["id"] = "~{3.3.2}	",
						["name"] = "orders_of_day",
						["option"] = "CALL FOR THE ORDERS.",
						["value"] = "CALL FOR THE ORDERS OF THE DAY.",
						["desc"] = "A call to adhere to the agenda (a deviation from the agenda requires Suspending the Rules.)",
						["help"] = "Calling for the meeting to come back on track if it's gone on a tangent topic.",
					},
				},
				["chair"] = {
					
				},
			},
			[4] = {
				["motions"] = {
					{
						["id"] = "~{4.2.1}	",
						["name"] = "second_motion",
						["option"] = "SECOND THE MOTION.",
						["value"] = "SECOND.",
						["desc"] = "Second the Motion on the floor. This is a critical step: if no one seconds, generally the motion is lost.",
						["help"] = "Certain actions do not require seconds.",
						["recv"] = function (guild_id, from_name, message)
							Q.saved.quora[guild_id].notify_text = "Motion on the floor seconded."
							Q.show_map_step(3)
						end,
					},
					{
						["id"] = "~{4.2.2}	",
						["name"] = "yield_action",
						["option"] = "YIELD THE FLOOR.",
						["value"] = "I YIELD.",
						["desc"] = "When you are finished speaking, or have been asked to yield.",
						["help"] = "You are not required to yield if you are not finished, however you may be legitimately interrupted.",
						["recv"] = function (guild_id, from_name, message)
							Q.saved.quora[ guild_id ].speaker = "N/A"
							Q.show_map_step(3)
						end,
					},
				},

			},

		},
	}
end

function Q.on_init( event, name )
	if name ~= "Quorum" then return end
	EVENT_MANAGER:UnregisterForEvent(name, event)
	Q.init()
	Q.load_saved_vars()
	Q.add_slash_commands()
	Q.create_settings_ui()
	Q.show_summary( Q.saved.active_guild )
	EVENT_MANAGER:RegisterForEvent("Quorum", EVENT_CHAT_MESSAGE_CHANNEL, Q.on_message_received)	
end

function Q.load_saved_vars()
	Q.saved = ZO_SavedVars:NewAccountWide( "Quorum_SavedVariables", Q.version, "saved", Q.saved )
	Q.toggle_addon_visible( Q.saved.addon_visible )
	local x = Q.saved.display_position.x 
	local y = Q.saved.display_position.y
	Quorum:SetAnchor( CENTER, GuiRoot, CENTER, x, y )

	for i = 1, #Q.saved.guild_names do
		if not ( Q.saved.guild_names[i] == "" ) then
			local player = GetPlayerGuildMemberIndex(i)
			local name, note, rank, stat, last = GetGuildMemberInfo( i, player )
			Q.saved.quora[ i ] = {
				guild_name = Q.saved.guild_names[i],
				meeting_in_progress = false,
				vote_in_progress = false,
				votes = { ["yea"] = {}, ["nay"] = {}, ["abs"] = {}, },
				chair = "N/A",
				speaker = "N/A",
				move = 1,
				motion_body = "",
				player_rank = rank,
				notify_text = "No Meeting.",
				floor_queue = {},
				recruit_msg = "",
			}
		end
	end
end

function Q.create_settings_ui()
	Q.saved.SettingsWindow = LAM:CreateControlPanel("Quorum_Settings", "|cDA77FFQuorum|r")
	LAM:AddHeader(Q.saved.SettingsWindow, "Quorum_About", "by @archpoet.")
	LAM:AddHeader(Q.saved.SettingsWindow, "Quorum_UIOptions", "Options")
	LAM:AddColorPicker(Q.saved.SettingsWindow, "Quorum_ChatColor", "Chat Output Color", "This changes the color of the chat output.", Q.get_chatcolor_setting, Q.set_chatcolor_setting, false, "")
end

function Q.get_chatcolor_setting() return unpack( Q.saved.chat_output_color ) end
function Q.set_chatcolor_setting(r,g,b,a)
	Q.saved.chat_output_color = { r, g, b, a }
end

--
-- UTIL
--
function Q.dec_2_hex( colors )
	return '|c' .. Q.DEC_HEX(colors[1]*255) .. Q.DEC_HEX(colors[2]*255) .. Q.DEC_HEX(colors[3]*255)
end

function Q.DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
	if IN == 0 then
		OUT=0
		return OUT
	end 	
    while IN > 0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end

function Q.get_table_length(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function Q.is_in(value, array)
	if (array == nil) then
		return false
	end
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

function Q.element_hover_on(element, rgb)
	element:SetColor( rgb[1]/255, rgb[2]/255, rgb[3]/255, 1 )
end

function Q.element_hover_off(element, rgb)
	element:SetColor( rgb[1]/255, rgb[2]/255, rgb[3]/255, 1 )
end

function Q.pairs_by_keys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

function Q.toggle_addon_visible(toggle)
	if ( toggle == true ) then
		Quorum:SetHidden(false)
		Quorum.hidden = false
		Q.saved.addon_visible = true
	elseif ( toggle == false ) then
		Quorum:SetHidden(true)
		Quorum.hidden = true
		Q.saved.addon_visible = false
	end
end

--
--
--
function Q.handle_action( key, value )
	if ( type(value) == "function" ) then
		value()
	elseif ( string.find( key, Q.saved.format_regex ) ) then
		ZO_ChatWindowTextEntryEditBox:SetText( "/g" .. Q.saved.active_guild .. " " .. key .. Q.dec_2_hex( Q.saved.chat_output_color ) .. value .. "|r" )
	end
end

function Q.cycle_guild_list(num)
	if ( num > 5 ) then
		num = 1
	else
		num = num + 1
	end
			
	if ( Q.saved.guild_names[ num ] == "" ) then
		num = 1
	end
	
	return num
end

function Q.default_motion_action(text)
	for i = 3, 10, 1 do
		if ( wm:GetControlByName( i ) ) then
			local control = wm:GetControlByName( i )
			control:SetText("")
		end
	end
	local control = wm:GetControlByName( "QuorumMotionBody" )
	control:SetHidden(false)
	control:SetText(text)
	control:SetPasteEnabled(true)
	--control:SetKeyboardEnabled(true)
	control:TakeFocus()
		
	local ok = wm:GetControlByName( "QuorumMotionBodyOK" )
	ok:SetHidden(false)
	ok:SetMouseEnabled(true)
	local cancel = wm:GetControlByName( "QuorumMotionBodyCANCEL" )
	cancel:SetHidden(false)
	cancel:SetMouseEnabled(true)
		
	ok:SetHandler( "OnMouseDown", function() Q.motion_body_ok(ok, cancel, control) end )
	cancel:SetHandler( "OnMouseDown", function() Q.motion_body_cancel(ok, cancel, control) end )
end

function Q.motion_body_ok(ok, cancel, control)
	local text = control:GetText()
	control:SetText("")
	control:LoseFocus()
	control:SetHidden(true)
	
	ok:SetHidden(true)
	cancel:SetHidden(true)
	
	CHAT_SYSTEM:AddMessage(text)
	ZO_ChatWindowTextEntryEditBox:SetText( "/g" .. Q.saved.active_guild .. " " .. "~{3:2:1}	" .. Q.dec_2_hex( Q.saved.chat_output_color ) .. text .. "|r" )
	
	Q.show_main_motions()
end

function Q.motion_body_cancel(ok, cancel, control)
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

	if ( type( actions["default"] ) == "table" ) then
		Q.place_actions( actions["default"] )
	elseif ( type( actions["chair"] ) == "table" and
		( Q.saved.quora[ Q.saved.active_guild ].chair == Q.saved.account_name or
		( Q.saved.quora[ Q.saved.active_guild ].player_rank < 3 and Q.saved.quora[ Q.saved.active_guild ].move == 1 )
		) ) then
		Q.place_actions( actions["chair"] )
	elseif ( type( actions["motions"] ) == "table" ) then
		Q.place_actions( actions["motions"] )
	end

	if ( type( actions["incidentals"] ) == "table" and Q.get_table_length( actions["incidentals"] ) > 0 ) then
		Incidentals:SetHidden(false)
		Incidentals:SetMouseEnabled(true)
		Incidentals:SetHandler( "OnMouseDown", function()
			Q.place_actions( actions["incidentals"] )
			Incidentals:SetText("<< Back.")

			Incidentals:SetHandler( "OnMouseDown", function()
				Q.show_actions( actions )
				Incidentals:SetText("Interrupt! >>")

			end )

		end )

	end

end

function Q.place_actions( table )
	local delta_y = 1
	for i = 1, #table, 1 do
		if ( table[i]["id"] == nil ) then
			table[i]["id"] = ""
		end
		if ( table[i]["option"] == nil ) then
			table[i]["option"] = ""
		end
		if ( table[i]["desc"] == nil ) then
			table[i]["desc"] = ""
		end

		local control = {}

		if not ( wm:GetControlByName( i ) ) then
			control = wm:CreateControl( i, Quorum, CT_LABEL )
			control:SetParent(Quorum)
			control:SetAnchor(TOPLEFT, Quorum, TOPLEFT, 15, 72 + delta_y)
			control:SetResizeToFitDescendents(true)
			control:SetMouseEnabled(true)
			control:SetFont("ZoFontGame")
			control:SetDimensionConstraints(250,50,580,200)
			control:SetText( table[i]["option"] .. "\n|cCCCCCC" .. table[i]["desc"] .. "|r" )
			control:SetHandler( "OnMouseDown", function() Q.handle_action(table[i]["id"], table[i]["value"]) end )
		else
			control = wm:GetControlByName( i )
			control:SetText( table[i]["option"] .. "\n|cCCCCCC" .. table[i]["desc"] .. "|r" )
			Tooltip:SetText( table[i]["help"] )
			control:SetHandler( "OnMouseDown", function() Q.handle_action(table[i]["id"], table[i]["value"]) end )
		end

		control:SetHandler( "OnMouseEnter", function()
			control:SetColor(0,1,0,1)
			if ( table[i]["help"] ~= nil) then
				Tooltip:SetText( table[i]["help"] )
				Tooltip:SetHidden(false)
				Tooltip:SetDrawTier(1)
				Tooltip:SetResizeToFitDescendents(true)
				Tooltip:SetDimensionConstraints(1,1,200,220)
				--Tooltip:SetResizeToFitPadding( 200, 100 )
				Tooltip:SetAnchor( TOPLEFT, Quorum, TOPLEFT, 100, 100 )
			end
		end )
		
		control:SetHandler( "OnMouseExit", function()
			control:SetColor(240,240,240,1)
			Tooltip:SetHidden(true)
		end )

		delta_y = delta_y + 25
	end
end

function Q.show_map_step(step)
	local stage_table = Q.saved.quorum_map[ step ]
	Q.show_actions( stage_table )
end

function Q.show_main_motions()
	local motions = {
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
		if ( Q.saved.active_guild == nil ) then
			guild = 1
		else
			guild = Q.saved.active_guild
		end
	end

	Q.saved.active_guild = guild
	SetDisplayedGuild( Q.saved.active_guild )

	local meeting_count = 0
	local v = Q.saved.quora[guild]
	
	if ( v ~= nil and type(v) == "table" ) then

		local meeting_string = ""
		if (v.meeting_in_progress == true) then
			meeting_string = "|cAAFFAAYes|r"
		else
			meeting_string = "|cFFAAAANo|r"
		end

		local voting_string = ""
		if (v.voting_in_progress == true) then
			voting_string = "|cAAFFAAYes|r"
		else
			voting_string = "|cFFAAAANo|r"
		end

		Q.show_actions( {
			["motions"] = {
				{ ["option"] = "Active Guild:\t\t |cAAFF99" .. tostring(v.guild_name) .. "|r\t\t>>", ["value"] = function() Q.show_summary( Q.cycle_guild_list( guild ) ) end, },
				{ ["option"] = "Meeting Now:\t\t " .. meeting_string, },
				{ ["option"] = "Chair:\t\t " .. tostring(v.chair), },
				{ ["option"] = "Floor:\t\t " .. tostring(v.speaker), },
				{ ["option"] = "Move:\t\t "  .. tostring(v.move), },
				{ ["option"] = "Question:\t\t " .. tostring(v.motion_body), },
				{ ["option"] = "Voting Now:\t\t " .. voting_string, },
				{ ["option"] = "Votes:\t\t " .. tostring( Q.get_table_length(v.votes.yea) ) .. " / " .. tostring( Q.get_table_length(v.votes.nay) ) .. " / " .. tostring( Q.get_table_length(v.votes.abs) ), },
			}
		} )

		Notify:SetText( Q.saved.quora[guild].notify_text )
		
	end
end

-- parse lines of guild chat to watch for votes,motions,etc.
function Q.on_message_received(event_code, message_type, from_name, text)
	local guild_id = Q.is_in(message_type, Q.saved.guild_channels)
	section_map = { "chair", "motions", "incidentals" }
	
	if not ( guild_id == false ) then
		-- let the active_guild run a meeting in /say
		if ( guild_id == 6 ) then
			guild_id = Q.saved.active_guild
		end

		if ( string.find( text, Q.saved.format_regex ) ) then
	--Q.saved.quora[ Q.saved.active_guild ].move = step
			local step, section, elem = text:match( Q.saved.format_regex )
			local message = text:gsub( Q.saved.format_regex, "" )

			if ( type( Q.saved.quorum_map[ tonumber(step) ][ section_map[ tonumber(section) ] ][ tonumber(elem) ].recv ) == "function" ) then

				Q.saved.quorum_map[ tonumber(step) ][ section_map[ tonumber(section) ] ][ tonumber(elem) ].recv( guild_id, from_name, message )

			elseif ( string.find( message, "QUESTION HAS BEEN CALLED" ) ) then
				Q.saved.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. "Vote to close debate on this question."
				Q.saved.quora[guild_id].speaker = "N/A"
			elseif ( string.find( message, "QUESTION HAS BEEN PUT" ) ) then
				Q.saved.quora[guild_id].vote_in_progress = true
				Q.saved.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. "Vote on Main Motion."
				Q.saved.quora[guild_id].speaker = "N/A"			
			elseif ( string.find( message, "YEA." ) ) then
				if ( Q.saved.quora[guild_id].votes.yea[ Q.account_name ] == nil ) then
					Q.saved.quora[guild_id].votes.yea[ Q.account_name ] = 1
					Q.saved.quora[guild_id].votes.nay[ Q.account_name ] = nil
					Q.saved.quora[guild_id].votes.abs[ Q.account_name ] = nil
				end
			elseif ( string.find( message, "NAY." ) ) then
				if ( Q.saved.quora[guild_id].votes.nay[ Q.account_name ] == nil ) then
					Q.saved.quora[guild_id].votes.nay[ Q.account_name ] = 1
					Q.saved.quora[guild_id].votes.yea[ Q.account_name ] = nil
					Q.saved.quora[guild_id].votes.abs[ Q.account_name ] = nil
				end
			elseif ( string.find( message, "I ABSTAIN." ) ) then
				if ( Q.saved.quora[guild_id].votes.abs[ Q.account_name ] == nil ) then
					Q.saved.quora[guild_id].votes.abs[ Q.account_name ] = 1
					Q.saved.quora[guild_id].votes.yea[ Q.account_name ] = nil
					Q.saved.quora[guild_id].votes.nay[ Q.account_name ] = nil
				end
			elseif ( string.find( message, "MEETING IS ADJOURNED." ) ) then
				Q.saved.quora[guild_id].meeting_in_progress = false
				Q.saved.quora[guild_id].vote_in_progress = false
				Q.saved.quora[guild_id].chair = "N/A"
				Q.saved.quora[guild_id].speaker = "N/A"
				Q.saved.quora[guild_id].move = 0
				Q.saved.quora[guild_id].motion_body = message
			elseif ( string.find( message, "MEETING IS IN RECESS." ) ) then
				Q.saved.quora[guild_id].meeting_in_progress = false
				Q.saved.quora[guild_id].vote_in_progress = false
				Q.saved.quora[guild_id].chair = "N/A"
				Q.saved.quora[guild_id].speaker = "N/A"
				Q.saved.quora[guild_id].move = 0
				Q.saved.quora[guild_id].motion_body = message
			elseif ( string.find( message, "I MOVE THAT|MOTION TO" ) ) then
				Q.saved.quora[guild_id].motion_body = message
			end

			if ( guild_id == Q.saved.active_guild ) then
				if ( Q.saved.account_name == tostring( Q.saved.quora[guild_id].speaker ) ) then
					Q.saved.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. "|c66FF66You have the floor!|r"
				else
					Q.saved.quora[guild_id].notify_text = "/g" .. guild_id .. ": " .. Q.saved.quora[guild_id].speaker .. "|cFF6666 has the floor.|r"
				end
			end

			Notify:SetText( Q.saved.quora[guild_id].notify_text )
		end
	
	end
end

--
-- SLASH COMMAND RELATED
--
function Q.add_slash_commands()
	SLASH_COMMANDS["/quo"] = function()
		if ( Quorum.hidden ) then
			Q.toggle_addon_visible(true)
		else
			Q.toggle_addon_visible(false)
		end
	end

	SLASH_COMMANDS["/gdemote"]		= function (extra) Q.guild_demote( Q.saved.active_guild, extra) end
	SLASH_COMMANDS["/ginvite"]		= function (extra) Q.guild_invite( Q.saved.active_guild, extra) end
	SLASH_COMMANDS["/gkick"]		= function (extra) Q.guild_remove( Q.saved.active_guild, extra) end
	SLASH_COMMANDS["/gpromote"]		= function (extra) Q.guild_promote( Q.saved.active_guild, extra) end
	SLASH_COMMANDS["/grecruit"]		= function (extra) Q.guild_recruit( Q.saved.active_guild, extra) end
	SLASH_COMMANDS["/gquit"]		= function (extra) Q.guild_leave( Q.saved.active_guild ) end

	SLASH_COMMANDS["/g1demote"]		= function (extra) Q.guild_demote( 1, extra) end
	SLASH_COMMANDS["/g1invite"]		= function (extra) Q.guild_invite( 1, extra) end
	SLASH_COMMANDS["/g1kick"]		= function (extra) Q.guild_remove( 1, extra) end
	SLASH_COMMANDS["/g1promote"]	= function (extra) Q.guild_promote( 1, extra) end
	SLASH_COMMANDS["/g1recruit"]	= function (extra) Q.guild_recruit( 1, extra) end
	SLASH_COMMANDS["/g1quit"]		= function (extra) Q.guild_leave( 1 ) end
	
	SLASH_COMMANDS["/g2demote"]		= function (extra) Q.guild_demote( 2, extra) end
	SLASH_COMMANDS["/g2invite"]		= function (extra) Q.guild_invite( 2, extra) end
	SLASH_COMMANDS["/g2kick"]		= function (extra) Q.guild_remove( 2, extra) end
	SLASH_COMMANDS["/g2promote"]	= function (extra) Q.guild_promote( 2, extra) end
	SLASH_COMMANDS["/g2recruit"]	= function (extra) Q.guild_recruit( 2, extra) end	
	SLASH_COMMANDS["/g2quit"]		= function (extra) Q.guild_leave( 2 ) end
	
	SLASH_COMMANDS["/g3demote"]		= function (extra) Q.guild_demote( 3, extra) end
	SLASH_COMMANDS["/g3invite"]		= function (extra) Q.guild_invite( 3, extra) end
	SLASH_COMMANDS["/g3kick"]		= function (extra) Q.guild_remove( 3, extra) end
	SLASH_COMMANDS["/g3promote"]	= function (extra) Q.guild_promote( 3, extra) end
	SLASH_COMMANDS["/g3recruit"]	= function (extra) Q.guild_recruit( 3, extra) end	
	SLASH_COMMANDS["/g3quit"]		= function (extra) Q.guild_leave( 3 ) end
	
	SLASH_COMMANDS["/g4demote"]		= function (extra) Q.guild_demote( 4, extra) end
	SLASH_COMMANDS["/g4invite"]		= function (extra) Q.guild_invite( 4, extra) end
	SLASH_COMMANDS["/g4kick"]		= function (extra) Q.guild_remove( 4, extra) end
	SLASH_COMMANDS["/g4promote"]	= function (extra) Q.guild_promote( 4, extra) end
	SLASH_COMMANDS["/g4recruit"]	= function (extra) Q.guild_recruit( 4, extra) end	
	SLASH_COMMANDS["/g4quit"]		= function (extra) Q.guild_leave( 4 ) end
	
	SLASH_COMMANDS["/g5demote"]		= function (extra) Q.guild_demote( 5, extra) end
	SLASH_COMMANDS["/g5invite"]		= function (extra) Q.guild_invite( 5, extra) end
	SLASH_COMMANDS["/g5kick"]		= function (extra) Q.guild_remove( 5, extra) end
	SLASH_COMMANDS["/g5promote"]	= function (extra) Q.guild_promote( 5, extra) end
	SLASH_COMMANDS["/g5recruit"]	= function (extra) Q.guild_recruit( 5, extra) end
	SLASH_COMMANDS["/g5quit"]		= function (extra) Q.guild_leave( 5 ) end

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

function Q.guild_recruit( guild, message )
	if ( message == nil or message == "" ) then
		ZO_ChatWindowTextEntryEditBox:SetText( Q.saved.quora[ guild ].recruit_msg )
	else
		Q.saved.quora[ guild ].recruit_msg = tostring(message)
	end
end

function Q.guild_remove( guild, player )
	if ( player == nil or player == "" ) then
		return d("Please provide the name of a guild member to remove.")
	else
		GuildRemove( guild, tostring(player) )
	end
end

--
-- MAIN
--
EVENT_MANAGER:RegisterForEvent( "Quorum", EVENT_ADD_ON_LOADED , Q.on_init )