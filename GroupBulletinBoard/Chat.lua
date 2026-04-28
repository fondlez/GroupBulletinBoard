local _, GBB = GroupBulletinBoard_Loader.Main()
if not GBB then
  GBB = GroupBulletinBoard_Addon or {}
end

function GBB.CreateChatFrame(name, ...)
  local Frame = name and FCF_OpenNewWindow(name, true) or ChatFrame1
  if (...) then
    for index = 1, select('#', ...) do
      ChatFrame_AddMessageGroup(Frame, select(index, ...))
    end
  end
  return Frame
end

local function GetChannels()
  local channelList = { GetChannelList() }
  local channels = {}
  for i = 1, #channelList, 2 do
    table.insert(channels, {
      id = channelList[i],
      name = channelList[i + 1]
    })
  end

  return channels
end

local function SetChannels(ChanNames, Frame, ShouldRemove)
  ShouldRemove = ShouldRemove or false

  for k, _ in pairs(ChanNames) do
    if ShouldRemove == true and k ~= "" then
      ChatFrame_RemoveChannel(Frame, k)
    elseif k ~= "" then
      ChatFrame_AddChannel(Frame, k)
    end
  end
end

local function MissingChannels(ChanNames, ChannelsToAdd)
  local missingChannels = {}
  for k, _ in pairs(ChannelsToAdd) do
    if ChanNames[k] == nil and ChanNames[k] ~= "" then
      missingChannels[k] = 1
    end
  end
  return missingChannels
end

function GBB.InsertChat()
  local chatFrameInit = false
  local tabName = "LFG"


  for i = 1, NUM_CHAT_WINDOWS do
    local tab = _G["ChatFrame" .. i .. "Tab"]
    local name = tab:GetText()
    local shown = tab:IsShown()
    if name == tabName and shown == true then
      chatFrameInit = true
    end
  end

  if chatFrameInit == true then
    return
  end

  local ChannelsToAdd = { [GBB.L["world_channel"]] = 1, }



  local Frame = GBB.CreateChatFrame(tabName, "SAY", "EMOTE", "YELL", "GUILD", "OFFICER", "PARTY", "PARTY_LEADER", "RAID",
    "RAID_LEADER", "RAID_WARNING", "BATTLEGROUND", "BATTLEGROUND_LEADER", "SYSTEM", "MONSTER_WHISPER",
    "MONSTER_BOSS_WHISPER", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER")

  local channels = GetChannels()
  local channelNames = {}
  for _, v in pairs(channels) do
    channelNames[v["name"]] = v["isDisabled"]
  end

 
  local missingChannels = MissingChannels(channelNames, ChannelsToAdd)

  for k, _ in pairs(missingChannels) do
    JoinChannelByName(k, nil, Frame:GetID())

    channelNames[k] = 0
  end

  SetChannels(channelNames, Frame, false)

  FCF_SelectDockFrame(ChatFrame1)
  GBB.DB["NotifyChat"] = true
  GBB.OptionsUpdate()
end

function GBB.SendMessage(ChannelName, Msg)
  local index = GetChannelName(ChannelName)
  if (index ~= nil) then
    SendChatMessage(Msg, "CHANNEL", nil, index);
  end
end

function GBB.AnnounceInit()
  if GBB.api.client.version > GBB.api.client.TBC then
    GroupBulletinBoardFrameSelectChannel:SetNormalFontObject("GameFontNormal")
    GroupBulletinBoardFrameAnnounce:SetNormalFontObject("GameFontNormal")
  else
    GroupBulletinBoardFrameSelectChannel:SetTextFontObject("GameFontNormal")
    GroupBulletinBoardFrameAnnounce:SetTextFontObject("GameFontNormal")
  end

  local msg_request = GBB.DBChar.msg_request

  if msg_request and msg_request ~= "" then
    GroupBulletinBoardFrameAnnounceMsg:SetTextColor(1, 1, 1)
    GroupBulletinBoardFrameAnnounceMsg:SetText(msg_request)
  else
    GroupBulletinBoardFrameAnnounceMsg:SetTextColor(0.6, 0.6, 0.6)
    GroupBulletinBoardFrameAnnounceMsg:SetText(GBB.L["msgRequestHere"])
  end

  GroupBulletinBoardFrameAnnounce:SetText(GBB.L["BtnPostMsg"])
  GroupBulletinBoardFrameAnnounceMsg:HighlightText(0, 0)
  GroupBulletinBoardFrameAnnounceMsg:SetCursorPosition(0)
  GroupBulletinBoardFrameAnnounce:Disable()
  GroupBulletinBoardFrameAnnounceMsg:SetWidth(GroupBulletinBoardFrame:GetWidth() / 2 - 65)
end

function GBB.FocusLost()
  local t = GroupBulletinBoardFrameAnnounceMsg:GetText()

  if t == "" then
    GroupBulletinBoardFrameAnnounceMsg:SetTextColor(0.6, 0.6, 0.6)
    GroupBulletinBoardFrameAnnounceMsg:SetText(GBB.L["msgRequestHere"])
  end
end

function GBB.GetFocus()
  local t = GroupBulletinBoardFrameAnnounceMsg:GetText()
  if t == GBB.L["msgRequestHere"] then
    GroupBulletinBoardFrameAnnounceMsg:SetTextColor(1, 1, 1)
    GroupBulletinBoardFrameAnnounceMsg:SetText("")
  end
end

function GBB.EditAnnounceMessage_Changed()
  local t = GroupBulletinBoardFrameAnnounceMsg:GetText()
  if t == nil or t == "" or t == GBB.L["msgRequestHere"] then
    GBB.DBChar.msg_request = nil
    GroupBulletinBoardFrameAnnounce:Disable()
  else
    GroupBulletinBoardFrameAnnounce:Enable()
    GBB.DBChar.msg_request = t
  end
end

function GBB.Announce()
  local msg = GroupBulletinBoardFrameAnnounceMsg:GetText()

  if msg ~= nil and msg ~= "" and msg ~= GBB.L["msgRequestHere"] then
    GBB.SendMessage(GBB.DB.AnnounceChannel, msg)
    GroupBulletinBoardFrameAnnounceMsg:ClearFocus()
  end
end

-- Class icons/colors are intentionally NOT injected into the regular chat
-- frames for /yell or /emote. They should only appear inside the GBB request
-- list. Kept as a no-op stub for backward compatibility with any caller.
function GBB.HookChatColors()
end

function GBB.CreateChannelPulldown(frame, level, menuList)
  if level ~= 1 then return end
  local t = GBB.PhraseChannelList(GetChannelList())

  local info = UIDropDownMenu_CreateInfo()

  for i, channel in pairs(t) do
    local displayName = channel.name
    if displayName == "LookingForGroup" then
      displayName = "LFG"
    elseif displayName == "Guild Channel" then
      displayName = "Guild"
    elseif displayName == "GuildRecruitment" then
      displayName = "GR"
    elseif displayName == "LocalDefense" then
      displayName = "LD"
    end

    info.text = i .. ". " .. displayName
    info.checked = (channel.name == GBB.DB.AnnounceChannel)
    info.disabled = channel.hidden
    info.arg1 = i
    info.arg2 = channel.name
    info.func = function(self, arg1, arg2, checked)
      GBB.DB.AnnounceChannel = arg2
      local short = arg2
      if short == "LookingForGroup" then
        short = "LFG"
      elseif short == "Guild Channel" then
        short = "Guild"
      elseif short == "GuildRecruitment" then
        short = "GR"
      elseif short == "LocalDefense" then
        short = "LD"
      end
      GroupBulletinBoardFrameSelectChannel:SetText(short)
    end
    UIDropDownMenu_AddButton(info)
  end
end
