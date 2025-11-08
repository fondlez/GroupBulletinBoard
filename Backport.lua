local _, addon = GroupBulletinBoard_Loader.Main()

local _G = _G or getfenv(0)

local api = {}
addon.api = api

api.LOCALIZED_CLASS_NAMES_MALE = {
  [ "DEATHKNIGHT" ] = "Deathknight",
  [ "DRUID" ] = "Druid",
  [ "HUNTER" ] = "Hunter",
  [ "MAGE" ] = "Mage",
  [ "PALADIN" ] = "Paladin",
  [ "PRIEST" ] = "Priest",
  [ "ROGUE" ] = "Rogue",
  [ "SHAMAN" ] = "Shaman",
  [ "WARLOCK" ] = "Warlock",
  [ "WARRIOR" ] = "Warrior",
}

api.RAID_CLASS_COLORS_HEX = {
  [ "DEATHKNIGHT" ] = "ffc41f3b",
  [ "DRUID" ] = "ffff7d0a",
  [ "HUNTER" ] = "ffabd473",
  [ "MAGE" ] = "ff3fc7eb",
  [ "PALADIN" ] = "fff58cba",
  [ "PRIEST" ] = "ffffffff",
  [ "ROGUE" ] = "fffff569",
  [ "SHAMAN" ] = "ff0070de",
  [ "WARLOCK" ] = "ff8788ee",
  [ "WARRIOR" ] = "ffc79c6e",
}

do -- CLIENT VERSION
  local GetBuildInfo = _G.GetBuildInfo
  
  local function getClient()
      local display_version, build_number, build_date, ui_version 
        = GetBuildInfo()
      ui_version = ui_version or 11200
      return ui_version, display_version, build_number, build_date
  end
  
  local client = {}
  api.client = client
  
  client.VANILLA = 0
  client.TBC = 1
  client.WOTLK = 2
  client.CATA = 3
  client.MOP = 4
  client.is_unknown = false
  
  local ui_version = getClient()
  client.ui_version = ui_version
  
  local function getCompatibility()
    if not ui_version or ui_version <= 11200 then 
      return client.VANILLA
    elseif ui_version >= 20000 and ui_version <= 20400 then 
      return client.TBC
    elseif ui_version >= 30000 and ui_version <= 30300 then
      return client.WOTLK
    elseif ui_version >= 40000 and ui_version <= 40300 then
      return client.CATA
    elseif ui_version >= 50000 and ui_version <= 50400 then
      return client.MOP
    else
      client.is_unknown = true
      return client.MOP
    end
  end
  
  client.version = getCompatibility()
end

do -- CONTENT
  local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
  local MAX_PLAYER_LEVEL_TABLE  = _G.MAX_PLAYER_LEVEL_TABLE
  
  local content = {}
  api.content = content

  content.VANILLA = 0
  content.TBC = 1
  content.WOTLK = 2
  content.expansion = GetAccountExpansionLevel and 
    GetAccountExpansionLevel() or 0
  content.maxPlayerLevel = MAX_PLAYER_LEVEL_TABLE and 
    MAX_PLAYER_LEVEL_TABLE[expansion] or 60
end

do -- GROUP CHECKS
  local GetNumPartyMembers = _G.GetNumPartyMembers
  local GetNumRaidMembers = _G.GetNumRaidMembers

  api.IsInParty = function() 
    return GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 
  end

  api.IsInRaid = function() 
    return GetNumRaidMembers() > 0 
  end

  api.IsInGroup = function()
    return IsInParty() or IsInRaid()
  end
end

api.UnitFullName = UnitFullName or UnitName

api.SetSize = function( frame, width, height )
  if not frame then return end

  frame:SetWidth( width )
  frame:SetHeight( height )
end

api.wipe = table.wipe or function( tab )
  for k, _ in pairs( tab ) do tab[ k ] = nil end
  return tab
end

local chat_frame = _G.DEFAULT_CHAT_FRAME

api.print = function( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20 )
  if (arg1 or arg2 or arg3 or arg4 or arg5 or arg6 or arg7 or arg8 or arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg1 ) )
  end
  if (arg2 or arg3 or arg4 or arg5 or arg6 or arg7 or arg8 or arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg2 ) )
  end
  if (arg3 or arg4 or arg5 or arg6 or arg7 or arg8 or arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg3 ) )
  end
  if (arg4 or arg5 or arg6 or arg7 or arg8 or arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg4 ) )
  end
  if (arg5 or arg6 or arg7 or arg8 or arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg5 ) )
  end
  if (arg6 or arg7 or arg8 or arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg6 ) )
  end
  if (arg7 or arg8 or arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg7 ) )
  end
  if (arg8 or arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg8 ) )
  end
  if (arg9 or arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg9 ) )
  end
  if (arg10 or arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg10 ) )
  end
  if (arg11 or arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg11 ) )
  end
  if (arg12 or arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring( arg12 ) )
  end
  if (arg13 or arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then
    chat_frame:AddMessage( tostring(arg13 ) )
  end
  if (arg14 or arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then chat_frame:AddMessage( tostring( arg14 ) ) end
  if (arg15 or arg16 or arg17 or arg18 or arg19 or arg20) then chat_frame:AddMessage( tostring( arg15 ) ) end
  if (arg16 or arg17 or arg18 or arg19 or arg20) then chat_frame:AddMessage( tostring( arg16 ) ) end
  if (arg17 or arg18 or arg19 or arg20) then chat_frame:AddMessage( tostring( arg17 ) ) end
  if (arg18 or arg19 or arg20) then chat_frame:AddMessage( tostring( arg18 ) ) end
  if (arg19 or arg20) then chat_frame:AddMessage( tostring( arg19 ) ) end
  if (arg20) then chat_frame:AddMessage( tostring( arg20 ) ) end
end

SLASH_RL1 = "/rl"
SlashCmdList[ "RL" ] = _G.ReloadUI