local _, GBB = GroupBulletinBoard_Loader.Main()
if not GBB then
  GBB = GroupBulletinBoard_Addon or {}
end
local TOCNAME = "GroupBulletinBoard"
local print = GBB.api and GBB.api.print or function(...) DEFAULT_CHAT_FRAME:AddMessage(...) end
local RAID_CLASS_COLORS_HEX = GBB.api and GBB.api.RAID_CLASS_COLORS_HEX or {}


local has_wotlk = (GBB.api.content.expansion >= GBB.api.content.WOTLK)
GBB.ResizeTimer = 0
GBB.colors = {
  highlight = function(word)
    return string.format("|cffff9f69%s|r", word)
  end,
  blue = function(word)
    return string.format("|cff209ff9%s|r", word)
  end,
  white = function(word)
    return string.format("|cffffffff%s|r", word)
  end,
  red = function(word)
    return string.format("|cffff2f2f%s|r", word)
  end,
  orange = function(word)
    return string.format("|cffff8f2f%s|r", word)
  end,
  grey = function(word)
    return string.format("|cff9f9f9f%s|r", word)
  end,
  green = function(word)
    return string.format("|cff2fff5f%s|r", word)
  end
}

function GBB.pretty_print(message, color_fn)
  local c = color_fn or GBB.colors.blue
  DEFAULT_CHAT_FRAME:AddMessage(string.format("%s: %s", c("GroupBulletinBoard"), message))
end

local function SafeGetAddOnMetadata(addon, field)
  if addon and GetAddOnMetadata then
    return GetAddOnMetadata(addon, field) or "Unknown"
  end
  return "Unknown"
end
GBB.Version = SafeGetAddOnMetadata(TOCNAME, "Version")
GBB.Title = GetAddOnMetadata(TOCNAME, "Title")
GBB.Icon = "Interface\\Icons\\spell_holy_prayerofshadowprotection"
GBB.MiniIcon = "Interface\\Icons\\spell_holy_prayerofshadowprotection"
GBB.AchievementIcon = {
  texture = "Interface\\AchievementFrame\\UI-Achievement-TinyShield",
  texCoord = { 0, 0.625, 0, 0.625 }
}
GBB.FriendIcon = "Interface\\LootFrame\\toast-star"
GBB.GuildIcon = "Interface\\COMMON\\Indicator-Green"
GBB.PastPlayerIcon = "Interface\\COMMON\\Indicator-Yellow"
GBB.TxtEscapePicture = "|T%s:0|t"
GBB.NotifySound = "FriendJoinGame"

local PartyChangeEvent = { "GROUP_JOINED", "GROUP_LEFT",
  "LOADING_SCREEN_DISABLED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD" }

GBB.MSGPREFIX = "GBB: "
GBB.TAGBAD = "---"
GBB.TAGSEARCH = "+++"

GBB.Initalized = false
GBB.ElapsedSinceListUpdate = 0
GBB.LFG_Timer = 0
GBB.LFG_UPDATETIME = 10
GBB.TBCDUNGEONBREAK = 57
GBB.DUNGEONBREAK = 25
GBB.COMBINEMSGTIMER = 10
GBB.MAXCOMPACTWIDTH = 350
-- Minimum interval (seconds) between updates of an existing entry coming
-- from /yell or /emote for the same sender. Server-side rate limits already
-- throttle /lfg and /trade (~60s) but /yell and /emote are not limited, so
-- spammers would otherwise constantly rotate the request list. New senders
-- still appear instantly; only re-updates of an existing entry are delayed.
GBB.SPAM_THROTTLE_SECONDS = 30

function GBB.GetGearScore()
  if GearScore_GetScore then
    local gs = GearScore_GetScore(UnitName("player"), "player")
    if gs and gs > 0 then return math.floor(gs) end
  end
  return nil
end

function GBB.FormatGearScore(gs)
  if not gs or gs <= 0 then return nil end
  if gs < 1000 then
    return tostring(gs)
  end
  local rounded = math.floor((gs + 50) / 100) * 100
  local kVal = rounded / 1000
  if kVal == math.floor(kVal) then
    return string.format("%dk", kVal)
  else
    return string.format("%.1fk", kVal)
  end
end

function GBB.ProperCaseClass(englishClass)
  if not englishClass then return "Unknown" end
  return englishClass:sub(1, 1):upper() .. englishClass:sub(2):lower()
end

function GBB.GetActiveSpec()
  local maxPoints = 0
  local activeTab = 1
  for i = 1, GetNumTalentTabs() do
    local _, _, points = GetTalentTabInfo(i)
    if points and points > maxPoints then
      maxPoints = points
      activeTab = i
    end
  end
  local tabName = GetTalentTabInfo(activeTab)
  return tabName or "Unknown"
end

GBB.RaidAchievements = {
  ["ICC"]  = { 4531, 4604, 4628, 4632, 4528, 4605, 4629, 4633, 4529, 4606, 4630, 4634, 4527, 4607, 4631, 4635, 4530, 4597, 4583, 4584 },
  ["TOGC"] = { 3917, 3916, 3918, 3812 },
  ["RS"]   = { 4817, 4815, 4818, 4816 },
  ["ONY"]  = { 2189, 2190 },
  ["ULDR"] = { 2894, 2895 },
  ["NAXX"] = { 2140, 2141 },
}

function GBB.GetBestAchievement(dungeonID)
  if not dungeonID or not GBB.RaidAchievements[dungeonID] then return nil end
  for _, achieveId in ipairs(GBB.RaidAchievements[dungeonID]) do
    if select(4, GetAchievementInfo(achieveId)) then
      return achieveId
    end
  end
  return nil
end

function GBB.BuildInvWhisper(dungeonID)
  local _, englishClass = UnitClass("player")
  local spec = GBB.GetActiveSpec()
  local gs = GBB.GetGearScore()

  local parts = {}
  parts[#parts + 1] = GBB.ProperCaseClass(englishClass)
  parts[#parts + 1] = spec

  local gsFormatted = GBB.FormatGearScore(gs)
  if gsFormatted then
    parts[#parts + 1] = gsFormatted .. " gs"
  end

  if dungeonID then
    local achieveId = GBB.GetBestAchievement(dungeonID)
    if achieveId then
      local link = GetAchievementLink(achieveId)
      if link then
        parts[#parts + 1] = link
      end
    end
  end

  return table.concat(parts, " ")
end

function GBB.AllowInInstance()
  local inInstance, instanceType = IsInInstance()
  if instanceType == "arena" then
    instanceType = "pvp"
  elseif instanceType == "scenario" then
    instanceType = "party"
  end
  return GBB.DB["NotfiyIn" .. instanceType]
end

function GBB.Split(msg)
  return GBB.Tool.Split(string.gsub(string.lower(msg), "[%p%s%c]", "+"), "+")
end

function GBB.SplitNoNb(msg)
  local msgOrg = string.lower(msg)
  msg = string.gsub(string.lower(msg), "[´`]", "'")
  msg = string.gsub(msg, "''", "'")
  local msg2 = GBB.Tool.stripChars(msg)

  local result = GBB.Tool.iMerge(
    GBB.Tool.Split(string.gsub(msgOrg, "[%p%s%c]", "+"), "+"),
    GBB.Tool.Split(string.gsub(msgOrg, "[%p%c]", ""), " "),
    GBB.Tool.Split(string.gsub(msgOrg, "[%c%s]", "+"), "+"),
    GBB.Tool.Split(string.gsub(msgOrg, "[%p%s%c%d]", "+"), "+"),
    GBB.Tool.Split(string.gsub(msg, "[%p%s%c]", "+"), "+"),
    GBB.Tool.Split(string.gsub(msg, "[%p%c]", ""), " "),
    GBB.Tool.Split(string.gsub(msg, "[%c%s]", "+"), "+"),
    GBB.Tool.Split(string.gsub(msg, "[%p%s%c%d]", "+"), "+"),
    GBB.Tool.Split(string.gsub(msg2, "[%p%s%c]", "+"), "+"),
    GBB.Tool.Split(string.gsub(msg2, "[%p%c]", ""), " "),
    GBB.Tool.Split(string.gsub(msg2, "[%c%s]", "+"), "+"),
    GBB.Tool.Split(string.gsub(msg2, "[%p%s%c%d]", "+"), "+")
  )

  local filtered = {}
  for _, v in ipairs(result) do
    if v and v ~= "" then
      table.insert(filtered, v)
    end
  end

  local add = {}

  for it, tag in ipairs(filtered) do
    for is, suffix in ipairs(GBB.suffixTags) do
      if tag ~= suffix and string.sub(tag, -string.len(suffix)) == suffix then
        tinsert(add, string.sub(tag, 1, -string.len(suffix) - 1))
        tinsert(add, suffix)
      end
    end
  end

  result = GBB.Tool.iMerge(filtered, add)

  return result
end

function GBB.LevelRange(dungeon, short)
  if short then
    if GBB.dungeonLevel[dungeon][1] > 0 then
      return string.format(GBB.L["msgLevelRangeShort"], GBB.dungeonLevel[dungeon][1], GBB.dungeonLevel[dungeon]
        [2])
    end
  elseif GBB.dungeonLevel[dungeon][1] > 0 then
    return string.format(GBB.L["msgLevelRange"], GBB.dungeonLevel[dungeon][1], GBB.dungeonLevel[dungeon][2])
  end
  return ""
end

function GBB.FilterDungeon(dungeon, isHeroic, isRaid)
  if dungeon == nil then return false end
  if isHeroic == nil then isHeroic = false end
  if isRaid == nil then isRaid = false end

  if not GBB.DBChar then return false end
  if not GBB.dungeonLevel or not GBB.dungeonLevel[dungeon] then return false end

  local maxLevel = GBB.api.content.maxPlayerLevel or 80

  local inLevelRange = false
  if not isHeroic then
    local levelInfo = GBB.dungeonLevel[dungeon]
    if levelInfo and levelInfo[1] and levelInfo[2] then
      inLevelRange = (levelInfo[1] <= GBB.UserLevel and GBB.UserLevel <= levelInfo[2])
    end
  else
    inLevelRange = (GBB.UserLevel == maxLevel)
  end

  local filterKey = "FilterDungeon" .. dungeon
  local isFiltered = GBB.DBChar[filterKey] or false

  local heroicOnly = GBB.DBChar["HeroicOnly"]
  local normalOnly = GBB.DBChar["NormalOnly"]
  local heroicCondition = (heroicOnly == false or isHeroic)
  local normalCondition = (normalOnly == false or isHeroic == false)
  local raidCondition = isRaid or (heroicCondition and normalCondition)

  local levelCondition = (GBB.DBChar.FilterLevel == false or inLevelRange)

  return isFiltered and raidCondition and levelCondition
end

function GBB.formatTime(sec)
  return string.format(GBB.L["msgTimeFormat"], math.floor(sec / 60), sec % 60)
end

function GBB.PhraseChannelList(...)
  local t = {}
  for i = 1, select("#", ...), 2 do
    t[select(i, ...)] = { name = select(i + 1, ...), hidden = false }
  end
  t[20] = { name = GBB.L.GuildChannel, hidden = false }
  return t
end

function GBB.JoinLFG()
  if GBB.Initalized == true and GBB.LFG_Successfulljoined == false then
    if GBB.L["world_channel"] ~= nil and GBB.L["world_channel"] ~= "" then
      local id, _ = GetChannelName(GBB.L["world_channel"])
      if id ~= nil and id > 0 then
        GBB.LFG_Successfulljoined = true
      else
        JoinChannelByName(GBB.L["world_channel"])
      end
    else
      GBB.LFG_Successfulljoined = true
    end
  end
end

function GBB.BtnSelectChannel()
  if UIDROPDOWNMENU_OPEN_MENU ~= GBB.FramePullDownChannel then
    UIDropDownMenu_Initialize(GBB.FramePullDownChannel, GBB.CreateChannelPulldown, "MENU")
  end
  ToggleDropDownMenu(nil, nil, GBB.FramePullDownChannel, GroupBulletinBoardFrameSelectChannel, 0, 0)
end

function GBB.SaveAnchors()
  GBB.DB.X = GroupBulletinBoardFrame:GetLeft()
  GBB.DB.Y = GroupBulletinBoardFrame:GetTop()
  GBB.DB.Width = GroupBulletinBoardFrame:GetWidth()
  GBB.DB.Height = GroupBulletinBoardFrame:GetHeight()
end

function GBB.ResizeFrameList()
  local w
  GroupBulletinBoardFrame_ScrollFrame:SetHeight(GroupBulletinBoardFrame:GetHeight() - 55 - 25)
  w = GroupBulletinBoardFrame:GetWidth() - 20 - 10 - 10
  GroupBulletinBoardFrame_ScrollFrame:SetWidth(w)
  GroupBulletinBoardFrame_ScrollChildFrame:SetWidth(w)
  GroupBulletinBoardFrame_ScrollFrame:UpdateScrollChildRect()
end

function GBB.ResetWindow()
  GroupBulletinBoardFrame:ClearAllPoints()
  GroupBulletinBoardFrame:SetPoint("Center", UIParent, "Center", 0, 0)
  GroupBulletinBoardFrame:SetWidth(800)
  GroupBulletinBoardFrame:SetHeight(500)
  GBB.SaveAnchors()
  GBB.ResizeFrameList()
end

function GBB.ShowWindow()
  GroupBulletinBoardFrame:Show()
  GBB.ClearNeeded = true
  GBB.UpdateList()
  GBB.ResizeFrameList()
end

function GBB.HideWindow()
  GroupBulletinBoardFrame:Hide()
end

function GBB.ToggleWindow()
  if GroupBulletinBoardFrame:IsVisible() then
    GBB.HideWindow()
  else
    GBB.ShowWindow()
  end
end

function GBB.BtnClose()
  GBB.HideWindow()
end

function GBB.BtnSettings(button)
  if button == "LeftButton" then
    GBB.Options.Open(2)
  else
    GBB.Popup_Minimap("cursor", false)
  end
end

function GBB.CreateTagListLOC(loc)
  for id, tag in pairs(GBB.badTagsLoc[loc]) do
    if GBB.DB.OnDebug and GBB.tagList[tag] ~= nil then
      print(GBB.MSGPREFIX .. "DoubleTag:" .. tag .. " - " .. GBB.tagList[tag] .. " / " .. GBB.TAGBAD)
    end
    GBB.tagList[tag] = GBB.TAGBAD
  end

  for id, tag in pairs(GBB.searchTagsLoc[loc]) do
    if GBB.DB.OnDebug and GBB.tagList[tag] ~= nil then
      print(GBB.MSGPREFIX .. "DoubleTag:" .. tag .. " - " .. GBB.tagList[tag] .. " / " .. GBB.TAGSEARCH)
    end
    GBB.tagList[tag] = GBB.TAGSEARCH
  end

  for id, tag in pairs(GBB.suffixTagsLoc[loc]) do
    if GBB.DB.OnDebug and tContains(GBB.suffixTags, tag) then
      print(GBB.MSGPREFIX .. "DoubleSuffix:" .. tag)
    end
    if tContains(GBB.suffixTags, tag) == false then tinsert(GBB.suffixTags, tag) end
  end

  for dungeon, tags in pairs(GBB.dungeonTagsLoc[loc]) do
    for id, tag in pairs(tags) do
      if GBB.DB.OnDebug and GBB.tagList[tag] ~= nil then
        print(GBB.MSGPREFIX .. "DoubleTag:" .. tag .. " - " .. GBB.tagList[tag] .. " / " .. dungeon)
      end
      GBB.tagList[tag] = dungeon
    end
  end

  for _, tag in pairs(GBB.heroicTagsLoc[loc]) do
    GBB.HeroicKeywords[tag] = 1
  end
end

function GBB.CreateTagList()
  GBB.tagList = {}
  GBB.suffixTags = {}
  GBB.HeroicKeywords = {}

  if GBB.DB.TagsEnglish then
    GBB.CreateTagListLOC("enGB")
  end
  if GBB.DB.TagsGerman then
    if GBB.DB.TagsEnglish == false then
      GBB.CreateTagListLOC("enGB")
    end
    GBB.CreateTagListLOC("deDE")
  end
  if GBB.DB.TagsRussian then
    GBB.CreateTagListLOC("ruRU")
  end
  if GBB.DB.TagsFrench then
    GBB.CreateTagListLOC("frFR")
  end
  if GBB.DB.TagsZhtw then
    GBB.CreateTagListLOC("zhTW")
  end
  if GBB.DB.TagsCustom then
    GBB.searchTagsLoc["custom"] = GBB.Split(GBB.DB.Custom.Search)
    GBB.badTagsLoc["custom"] = GBB.Split(GBB.DB.Custom.Bad)
    GBB.suffixTagsLoc["custom"] = GBB.Split(GBB.DB.Custom.Suffix)
    GBB.heroicTagsLoc["custom"] = GBB.Split(GBB.DB.Custom.Heroic)

    GBB.dungeonTagsLoc["custom"] = {}
    for index = 1, GBB.NUM_DUNGEONS do
      GBB.dungeonTagsLoc["custom"][GBB.dungeonSort[index]] = GBB.Split(GBB.DB.Custom[GBB.dungeonSort[index]])
    end

    GBB.CreateTagListLOC("custom")
  end
end

local function hooked_createTooltip(self)
  local name, unit = self:GetUnit()
  if (name) and (unit) and UnitIsPlayer(unit) then
    if GBB.DB.EnableGuild then
      local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(unit)
      if guildName and guildRankName then
        self:AddLine(GBB.Tool.RGBtoEscape(GBB.DB.ColorGuild) .. "< " .. guildName .. " / " .. guildRankName .. " >")
      end
    end

    if GBB.DB.EnableGroup and GBB.GroupTrans and GBB.GroupTrans[name] then
      local inInstance, instanceType = IsInInstance()

      if instanceType == "none" then
        local entry = GBB.GroupTrans[name]

        self:AddLine(" ")
        self:AddLine(GBB.L.msgLastSeen)
        if entry.dungeon then
          self:AddLine(entry.dungeon)
        end
        if entry.Note then
          self:AddLine(entry.Note)
        end
        self:AddLine(SecondsToTime(GetServerTime() - entry.lastSeen))
        self:Show()
      end
    end
  end
end

function GBB.Popup_Minimap(frame, notminimap)
  local txt = "nil"
  if type(frame) == "table" then txt = frame:GetName() or "nil" end
  if not GBB.PopupDynamic:Wipe(txt .. (notminimap and "notminimap" or "minimap")) then
    return
  end

  GBB.PopupDynamic:AddItem(GBB.L["HeaderSettings"], false, GBB.Options.Open, 1)

  if has_wotlk then
    GBB.PopupDynamic:AddItem(GBB.L["WotlkPanelFilter"], false, GBB.Options.Open, 2)
  else
    GBB.PopupDynamic:AddItem(GBB.L["TBCPanelFilter"], false, GBB.Options.Open, 2)
  end

  GBB.PopupDynamic:AddItem(GBB.L["PanelAbout"], false, GBB.Options.Open, 6)

  GBB.PopupDynamic:AddItem("", true)
  GBB.PopupDynamic:AddItem(GBB.L["CboxNotifyChat"], false, GBB.DB, "NotifyChat")
  GBB.PopupDynamic:AddItem(GBB.L["CboxNotifySound"], false, GBB.DB, "NotifySound")

  if notminimap ~= false then
    GBB.PopupDynamic:AddItem("", true)
    GBB.PopupDynamic:AddItem(GBB.L["CboxLockMinimapButton"], false, GBB.DB.MinimapButton, "lock")
    GBB.PopupDynamic:AddItem(GBB.L["CboxLockMinimapButtonDistance"], false, GBB.DB.MinimapButton, "lockDistance")
  end
  GBB.PopupDynamic:AddItem("", true)
  GBB.PopupDynamic:AddItem(GBB.L["BtnCancel"], false)

  GBB.PopupDynamic:Show(frame, 0, 0)
end

local function SetupResizing()
  local frame = GroupBulletinBoardFrame
  frame:SetMinResize(500, 205)

  local anchor = CreateFrame("Button", nil, frame)
  anchor:EnableMouse(true)
  anchor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  anchor:SetWidth(20)
  anchor:SetHeight(20)
  anchor:SetFrameStrata("HIGH")
  anchor:SetScript("OnMouseDown",
    function()
      frame:StartSizing("BOTTOMRIGHT")
    end)
  anchor:SetScript("OnMouseUp",
    function()
      frame:StopMovingOrSizing("BOTTOMRIGHT")
    end)
end

function GBB.Init()
  SetupResizing()

  GBB.UserLevel = UnitLevel("player")
  GBB.UserName = (GBB.api.UnitFullName("player"))
  GBB.ServerName = GetRealmName()

  if not GroupBulletinBoardDb then GroupBulletinBoardDb = {} end
  if not GroupBulletinBoardDbChar then GroupBulletinBoardDbChar = {} end
  GBB.DB = GroupBulletinBoardDb
  GBB.DBChar = GroupBulletinBoardDbChar

  if (type(GBB.DB.FontSize) == "table") then
    GBB.DB.FontSize = nil
  end

  if not GBB.DBChar.channel then GBB.DBChar.channel = {} end
  if not GBB.DB.MinimapButton then GBB.DB.MinimapButton = {} end
  if not GBB.DB.Custom then GBB.DB.Custom = {} end
  if not GBB.DB.CustomLocales then GBB.DB.CustomLocales = {} end
  if not GBB.DB.CustomLocalesDungeon then GBB.DB.CustomLocalesDungeon = {} end
  if not GBB.DB.fontFace then
    GBB.DB.fontFace = "Friz Quadrata TT"
  end
  if not GBB.DB.fontSize then
    GBB.DB.fontSize = 12
  end
  GBB.DB.FontSize = nil
  if not GBB.DB.DisplayLFG then GBB.DB.DisplayLFG = false end
  if GBB.DB.Donttruncate == nil then GBB.DB.Donttruncate = false end

  if GBB.DB.OnDebug == nil then GBB.DB.OnDebug = false end
  GBB.DB.widthNames = 93
  GBB.DB.widthTimes = 50
  GBB.DBChar["FilterDungeonDEBUG"] = true
  GBB.DBChar["FilterDungeonBAD"] = true

  GBB.DB.showminimapbutton = nil
  GBB.DB.minimapPos = nil

  GBB.L = GBB.LocalizationInit()
  GBB.dungeonNames = GBB.GetDungeonNames()
  GBB.RaidList = GBB.GetRaids()
  GBB.dungeonSort = GBB.GetDungeonSort()

  GBB.RequestList = {}
  GBB.FramesEntries = {}

  GBB.FoldedDungeons = {}

  GBB.MAXTIME = time() + 60 * 60 * 24 * 365

  GBB.ClearNeeded = true
  GBB.ClearTimer = GBB.MAXTIME
  GBB.whoCooldown = {}
  GBB.suppressWhoOutput = true

  GBB.LFG_Timer = time() + GBB.LFG_UPDATETIME
  GBB.LFG_Successfulljoined = false

  if GroupBulletinBoardFrameTitleIcon then
    GroupBulletinBoardFrameTitleIcon:SetTexture(GBB.Icon)
  end

  GBB.AnnounceInit()
  if GBB.DB.DisplayLFG == false then
    GroupBulletinBoardFrameAnnounce:Hide()
    GroupBulletinBoardFrameAnnounceMsg:Hide()
  end

  if GBB.DB.AnnounceChannel and GBB.DB.AnnounceChannel ~= "" then
    GroupBulletinBoardFrameSelectChannel:SetText(GBB.DB.AnnounceChannel)
  end

  local x, y, w, h = GBB.DB.X, GBB.DB.Y, GBB.DB.Width, GBB.DB.Height
  if not x or not y or not w or not h then
    GBB.SaveAnchors()
  else
    GroupBulletinBoardFrame:ClearAllPoints()
    GroupBulletinBoardFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    GroupBulletinBoardFrame:SetWidth(w)
    GroupBulletinBoardFrame:SetHeight(h)
  end

  local function doDBSet(DB, var, value)
    if value == nil then
      DB[var] = not DB[var]
    elseif tContains({ "true", "1", "enable" }, value) then
      DB[var] = true
    elseif tContains({ "false", "0", "disable" }, value) then
      DB[var] = false
    end
    DEFAULT_CHAT_FRAME:AddMessage(GBB.MSGPREFIX .. "Set " .. var .. " to " .. tostring(DB[var]))
    GBB.OptionsUpdate()
  end

  GBB.Tool.SlashCommand({ "/gbb", "/groupbulletinboard" }, {
    { "notify", "", {
      { "chat", "", {
        { "%", GBB.L["CboxNotifyChat"], doDBSet, GBB.DB, "NotifyChat" }
      } },
      { "sound", "", {
        { "%", GBB.L["CboxNotifySound"], doDBSet, GBB.DB, "NotifySound" }
      } },
    } },
    { "debug", "", {
      { "%", GBB.L["CboxOnDebug"], doDBSet, GBB.DB, "OnDebug" }
    } },
    { "reset", GBB.L["SlashReset"], function()
      GBB.ResetWindow()
      GBB.ShowWindow()
    end },
    { { "config", "setup", "options" }, GBB.L["SlashConfig"],  GBB.Options.Open, 1 },
    { "about",                          GBB.L["SlashAbout"],   GBB.Options.Open, 6 },
    { "",                               GBB.L["SlashDefault"], GBB.ToggleWindow },
  })

  GBB.OptionsInit()

  GBB.CreateTagList()

  GBB.MinimapButton.Init(GBB.DB.MinimapButton, GBB.Icon,
    function(self, button)
      if button == "LeftButton" then
        GBB.ToggleWindow()
      else
        GBB.Popup_Minimap(self.button, true)
      end
    end,
    GBB.Title
  )

  GBB.FramePullDownChannel = CreateFrame("Frame", "GBB.PullDownMenu", UIParent, "UIDropDownMenuTemplate")
  local LSM = LibStub("LibSharedMedia-3.0")
  local fontPath = LSM:Fetch("font", GBB.DB.fontFace, false)
  if not fontPath then
    fontPath = "Fonts\\FRIZQT__.TTF"
  end
  GroupBulletinBoardFrameTitle:SetFont(fontPath, GBB.DB.fontSize)
  if GBB.DB.AnnounceChannel == nil then
    if GBB.L["world_channel"] ~= "" then
      GBB.DB.AnnounceChannel = GBB.L["world_channel"]
    else
      _, GBB.DB.AnnounceChannel = GetChannelList()
    end
  end

  GroupBulletinBoardFrameSelectChannel:SetText(GBB.DB.AnnounceChannel)

  GBB.ResizeFrameList()

  if GBB.DB.EscapeQuit then
    tinsert(UISpecialFrames, GroupBulletinBoardFrame:GetName())
  end

  GBB.Tool.EnableSize(GroupBulletinBoardFrame, 8, nil, function()
    GBB.ResizeFrameList()
    GBB.SaveAnchors()
    GBB.ScheduleUpdate()
  end)
  GBB.Tool.EnableMoving(GroupBulletinBoardFrame, GBB.SaveAnchors)

  GBB.PatternWho1 = GBB.Tool.CreatePattern(WHO_LIST_FORMAT)
  GBB.PatternWho2 = GBB.Tool.CreatePattern(WHO_LIST_GUILD_FORMAT)
  GBB.PatternOnline = GBB.Tool.CreatePattern(ERR_FRIEND_ONLINE_SS)
  GBB.RealLevel = {}
  GBB.RealClass = {}
  GBB.lastWhoTime = 0
  GBB.RealLevel[GBB.UserName] = GBB.UserLevel

  GBB.Initalized = true
  GBB.nextUpdateTime = 0
  GBB.updatePending = false
  GBB.pendingScrollRestore = nil
  GBB.PopupDynamic = GBB.Tool.CreatePopup(GBB.OptionsUpdate)

  GroupBulletinBoardFrame_GroupFrame:Hide()
  GBB.DB.EnableGroup = false

  GameTooltip:HookScript("OnTooltipSetUnit", hooked_createTooltip)
  GBB.HookChatColors()

  local function SafeGetAddOnMetadata(addon, field)
    if addon and GetAddOnMetadata then
      return GetAddOnMetadata(addon, field) or "Unknown"
    end
    return "Unknown"
  end
  GBB.Version = SafeGetAddOnMetadata(TOCNAME, "Version")
end

local function Event_CHAT_MSG_SYSTEM(arg1)
  if not GBB.Initalized then return end

  if GBB.suppressWhoOutput and (string.find(arg1, "Players online") or string.find(arg1, "Who:") or string.find(arg1, "Нет игроков") or string.find(arg1, "Игроки онлайн")) then
    return
  end
end

local function Event_CHAT_MSG_CHANNEL(msg, name, _3, _4, _5, _6, _7, channelID, channel, _10, _11, guid)
  if not GBB.Initalized then return end
  if GBB.DBChar and GBB.DBChar.channel and GBB.DBChar.channel[channelID] then
    GBB.ParseMessage(msg, name, guid, channel)
  end
end

local function Event_GuildMessage(msg, name, _3, _4, _5, _6, _7, channelID, channel, _10, _11, guid)
  Event_CHAT_MSG_CHANNEL(msg, name, _3, _4, _5, _6, _7, 20, GBB.L.GuildChannel, _10, _11, guid)
end

local function Event_CHAT_MSG_YELL(msg, name, ...)
  if not GBB.Initalized then return end
  local guid = select(12, ...)
  GBB.ParseMessage(msg, name, guid, "YELL")
end

local function Event_CHAT_MSG_EMOTE(msg, name, ...)
  if not GBB.Initalized then return end
  local guid = select(12, ...)
  GBB.ParseMessage(msg, name, guid, "EMOTE")
end

function GBB.OnShow()
  GBB.InterfaceOptionsFrame.Rise()
  GBB.Options.DoRefresh()
end

function GBB.OnHide()
  GBB.InterfaceOptionsFrame.Sink()
end

function GBB.OnLoad()
  GBB.Tool.RegisterEvent("ADDON_LOADED", function(addon)
    if addon == TOCNAME then
      GBB.Init()
    end
  end)
  GBB.Tool.RegisterEvent("CHAT_MSG_SYSTEM", Event_CHAT_MSG_SYSTEM)
  GBB.Tool.RegisterEvent("CHAT_MSG_CHANNEL", Event_CHAT_MSG_CHANNEL)
  GBB.Tool.RegisterEvent("CHAT_MSG_GUILD", Event_GuildMessage)
  GBB.Tool.RegisterEvent("CHAT_MSG_OFFICER", Event_GuildMessage)
  GBB.Tool.RegisterEvent("CHAT_MSG_YELL", Event_CHAT_MSG_YELL)
  GBB.Tool.RegisterEvent("CHAT_MSG_EMOTE", Event_CHAT_MSG_EMOTE)
  GBB.Tool.RegisterEvent("GUILD_ROSTER_UPDATE", function()
    for i, req in ipairs(GBB.RequestList) do
      if type(req) == "table" and not req.class then
        for j = 1, GetNumGuildMembers() do
          local guildName, rankName, rankIndex, level, classFileName, zone, publicNote, officerNote, online, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid2 =
              GetGuildRosterInfo(j)
          if guildName == req.name or guildName == req.fullName then
            if class and class ~= "" then
              req.class = class
              GBB.ClearNeeded = true
            end
            break
          end
        end
      end
    end
    if GBB.UpdateList then GBB.UpdateList() end
  end)

  for i, event in ipairs(PartyChangeEvent) do
    GBB.Tool.RegisterEvent(event, GBB.UpdateGroupList)
  end

  GBB.Tool.OnUpdate(GBB.OnUpdate)
end

function GBB.OnSizeChanged()
  if GBB.Initalized == true then
    GBB.ResizeFrameList()
    GroupBulletinBoardFrame_ScrollFrame:UpdateScrollChildRect()
    GBB.ScheduleUpdate()
  end
end

function GBB.OnUpdate(elapsed)
  if GBB.Initalized == true then
    if GBB.LFG_Timer < time() and GBB.LFG_Successfulljoined == false then
      GBB.JoinLFG()
      GBB.LFG_Timer = time() + GBB.LFG_UPDATETIME
    end

    if GBB.updatePending and GBB.nextUpdateTime <= GetTime() then
      GBB.updatePending = false
      GBB.firstScheduledTime = nil
      GBB.DoUpdateList()
    end

    if GBB.pendingScrollRestore then
      local sf = GroupBulletinBoardFrame_ScrollFrame
      sf:SetVerticalScroll(GBB.pendingScrollRestore)
      GBB.pendingScrollRestore = nil
    end
  end
end

function GBB.ScheduleUpdate()
  local now = GetTime()
  if not GBB.updatePending then
    GBB.firstScheduledTime = now
  end
  GBB.updatePending = true
  if GBB.firstScheduledTime and (now - GBB.firstScheduledTime) >= 3 then
    GBB.nextUpdateTime = now
  else
    GBB.nextUpdateTime = now + 0.5
  end
end

function GBB.DoUpdateList()
  if GroupBulletinBoardFrame:IsVisible() then
    GBB.UpdateList()
  end
  GBB.ElapsedSinceListUpdate = 0
end

function GBB.ApplyFontToAllFrames()
  local LSM = LibStub("LibSharedMedia-3.0")
  local fontPath = LSM:Fetch("font", GBB.DB.fontFace, true)
  local fontSize = GBB.DB.fontSize

  if GroupBulletinBoardFrameTitle then
    GroupBulletinBoardFrameTitle:SetFont(fontPath, fontSize)
  end

  if GroupBulletinBoardFrameSelectChannel then
    GroupBulletinBoardFrameSelectChannel:SetFont(fontPath, fontSize)
  end
  if GroupBulletinBoardFrameAnnounce then
    GroupBulletinBoardFrameAnnounce:SetFont(fontPath, fontSize)
  end

  if GBB.UpdateList then GBB.UpdateList() end
end
