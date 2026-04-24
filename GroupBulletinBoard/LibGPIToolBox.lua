local _, GBB = GroupBulletinBoard_Loader.Main()
if not GBB then
  GBB = GroupBulletinBoard_Addon or {}
end
local TOCNAME = "GroupBulletinBoard"

local function safe_require(global, default)
  if not _G[global] then
    _G[global] = default or function() end
  end
end

safe_require("ICON_TAG_LIST", {})
safe_require("RAID_CLASS_COLORS", {})
safe_require("CLASS_SORT_ORDER",
  { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" })
safe_require("LOCALIZED_CLASS_NAMES_MALE", {
  DEATHKNIGHT = "Death Knight",
  DRUID = "Druid",
  HUNTER = "Hunter",
  MAGE = "Mage",
  PALADIN = "Paladin",
  PRIEST = "Priest",
  ROGUE = "Rogue",
  SHAMAN = "Shaman",
  WARLOCK = "Warlock",
  WARRIOR = "Warrior",
})
safe_require("UIParent", CreateFrame("Frame"))
safe_require("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
  tooltip:SetOwner(parent, "ANCHOR_NONE")
  tooltip:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 0, 0)
end)
safe_require("GetCursorInfo", nil)
safe_require("InCombatLockdown", function() return false end)
safe_require("GetAddOnMetadata", function() return "Unknown" end)
safe_require("LibStub", function() return nil end)

if not tContains then
  function tContains(t, v)
    if not t then return false end
    for i = 1, #t do
      if t[i] == v then return true end
    end
    return false
  end
end
if not tinsert then
  tinsert = table.insert
end

local print = GBB.api and GBB.api.print or function(...) DEFAULT_CHAT_FRAME:AddMessage(...) end
local LOCALIZED_CLASS_NAMES_MALE = _G.LOCALIZED_CLASS_NAMES_MALE

GBB.Tool = GBB.Tool or {}
local Tool = GBB.Tool

Tool.IconClass = {
  ["WARRIOR"]     = "|TInterface\\Icons\\INV_Sword_27:16:16:0:0:64:64:0:64:0:64|t",
  ["PALADIN"]     = "|TInterface\\Icons\\Ability_ThunderBolt:16:16:0:0:64:64:0:64:0:64|t",
  ["HUNTER"]      = "|TInterface\\Icons\\inv_weapon_bow_07:16:16:0:0:64:64:0:64:0:64|t",
  ["ROGUE"]       = "|TInterface\\Icons\\inv_throwingknife_04:16:16:0:0:64:64:0:64:0:64|t",
  ["PRIEST"]      = "|TInterface\\Icons\\inv_staff_30:16:16:0:0:64:64:0:64:0:64|t",
  ["SHAMAN"]      = "|TInterface\\Icons\\Spell_Nature_BloodLust:16:16:0:0:64:64:0:64:0:64|t",
  ["MAGE"]        = "|TInterface\\Icons\\inv_staff_13:16:16:0:0:64:64:0:64:0:64|t",
  ["WARLOCK"]     = "|TInterface\\Icons\\Spell_Nature_Drowsy:16:16:0:0:64:64:0:64:0:64|t",
  ["DRUID"]       = "|TInterface\\Icons\\inv_misc_monsterclaw_04:16:16:0:0:64:64:0:64:0:64|t",
  ["DEATHKNIGHT"] = "|TInterface\\Icons\\Spell_Deathknight_ClassIcon:16:16:0:0:64:64:0:64:0:64|t",
}

Tool.IconClassBig = {
  ["WARRIOR"]     = "|TInterface\\Icons\\INV_Sword_27:18:18:0:0:64:64:0:64:0:64|t",
  ["PALADIN"]     = "|TInterface\\Icons\\Ability_ThunderBolt:18:18:0:0:64:64:0:64:0:64|t",
  ["HUNTER"]      = "|TInterface\\Icons\\inv_weapon_bow_07:18:18:0:0:64:64:0:64:0:64|t",
  ["ROGUE"]       = "|TInterface\\Icons\\inv_throwingknife_04:18:18:0:0:64:64:0:64:0:64|t",
  ["PRIEST"]      = "|TInterface\\Icons\\inv_staff_30:18:18:0:0:64:64:0:64:0:64|t",
  ["SHAMAN"]      = "|TInterface\\Icons\\Spell_Nature_BloodLust:18:18:0:0:64:64:0:64:0:64|t",
  ["MAGE"]        = "|TInterface\\Icons\\inv_staff_13:18:18:0:0:64:64:0:64:0:64|t",
  ["WARLOCK"]     = "|TInterface\\Icons\\Spell_Nature_Drowsy:18:18:0:0:64:64:0:64:0:64|t",
  ["DRUID"]       = "|TInterface\\Icons\\inv_misc_monsterclaw_04:18:18:0:0:64:64:0:64:0:64|t",
  ["DEATHKNIGHT"] = "|TInterface\\Icons\\Spell_Deathknight_ClassIcon:18:18:0:0:64:64:0:64:0:64|t",
}

Tool.RaidIconNames = ICON_TAG_LIST
Tool.RaidIcon = {
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
}
Tool.RoleIcon = {
  ["TANK"]    = "|TInterface\\RaidFrame\\Raid-RoleIcons.blp:16:16:0:0:64:64:0:32:0:32|t",
  ["HEALER"]  = "|TInterface\\RaidFrame\\Raid-RoleIcons.blp:16:16:0:0:64:64:32:64:0:32|t",
  ["DAMAGER"] = "|TInterface\\RaidFrame\\Raid-RoleIcons.blp:16:16:0:0:64:64:0:32:32:64|t",
}

Tool.Classes = CLASS_SORT_ORDER
Tool.ClassName = LOCALIZED_CLASS_NAMES_MALE
Tool.ClassColor = RAID_CLASS_COLORS

Tool.NameToClass = {}
for eng, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do
  Tool.NameToClass[name] = eng
  Tool.NameToClass[eng] = eng
end

local _tableAccents = {
  ["À"] = "A",
  ["Á"] = "A",
  ["Â"] = "A",
  ["Ã"] = "A",
  ["Ä"] = "Ae",
  ["Å"] = "A",
  ["Æ"] = "AE",
  ["Ç"] = "C",
  ["È"] = "E",
  ["É"] = "E",
  ["Ê"] = "E",
  ["Ë"] = "E",
  ["Ì"] = "I",
  ["Í"] = "I",
  ["Î"] = "I",
  ["Ï"] = "I",
  ["Ð"] = "D",
  ["Ñ"] = "N",
  ["Ò"] = "O",
  ["Ó"] = "O",
  ["Ô"] = "O",
  ["Õ"] = "O",
  ["Ö"] = "Oe",
  ["Ø"] = "O",
  ["Ù"] = "U",
  ["Ú"] = "U",
  ["Û"] = "U",
  ["Ü"] = "Ue",
  ["Ý"] = "Y",
  ["Þ"] = "P",
  ["ß"] = "ss",
  ["à"] = "a",
  ["á"] = "a",
  ["â"] = "a",
  ["ã"] = "a",
  ["ä"] = "ae",
  ["å"] = "a",
  ["æ"] = "ae",
  ["ç"] = "c",
  ["è"] = "e",
  ["é"] = "e",
  ["ê"] = "e",
  ["ë"] = "e",
  ["ì"] = "i",
  ["í"] = "i",
  ["î"] = "i",
  ["ï"] = "i",
  ["ð"] = "eth",
  ["ñ"] = "n",
  ["ò"] = "o",
  ["ó"] = "o",
  ["ô"] = "o",
  ["õ"] = "o",
  ["ö"] = "oe",
  ["ø"] = "o",
  ["ù"] = "u",
  ["ú"] = "u",
  ["û"] = "u",
  ["ü"] = "ue",
  ["ý"] = "y",
  ["þ"] = "p",
  ["ÿ"] = "y",
}

function Tool.stripChars(str)
  return string.gsub(str, "[%z\1-\127\194-\244][\128-\191]*", _tableAccents)
end

function Tool.Split(inputstr, sep)
  if sep == nil then sep = "%s" end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    local found = false
    for i = 1, #t do
      if t[i] == str then
        found = true; break
      end
    end
    if not found then table.insert(t, str) end
  end
  return t
end

function Tool.iMerge(t1, ...)
  for index = 1, select("#", ...) do
    local var = select(index, ...)
    if type(var) == "table" then
      for i, v in ipairs(var) do
        if v and not tContains(t1, v) then
          tinsert(t1, v)
        end
      end
    else
      if var and not tContains(t1, var) then
        tinsert(t1, var)
      end
    end
  end
  return t1
end

local function EnterHyperlink(self, link, text)
  local part = Tool.Split(link, ":")
  if part[1] == "spell" or part[1] == "unit" or part[1] == "item" or part[1] == "enchant" or part[1] == "player" or part[1] == "quest" or part[1] == "trade" then
    if GameTooltip_SetDefaultAnchor then
      GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    else
      GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
      GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "TOPRIGHT", 0, 0)
    end
    GameTooltip:ClearLines()
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
  end
end

local function LeaveHyperlink(self)
  GameTooltip:Hide()
end

local function HookItemRefTooltipSetHyperlink(self, link, ...)
  local linkType = string.match(link, "^([^:]+)")
  if linkType == "trade" then
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "TOPRIGHT", 0, 0)
    GameTooltip:ClearLines()
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
  end
end

function Tool.EnableHyperlink(frame)
  if frame.SetHyperlinksEnabled then
    frame:SetHyperlinksEnabled(true)
  end
  frame:SetScript("OnHyperlinkEnter", EnterHyperlink)
  frame:SetScript("OnHyperlinkLeave", LeaveHyperlink)
end

Tool.EnterHyperlink = EnterHyperlink
Tool.LeaveHyperlink = LeaveHyperlink

if not Tool.HookInstalled then
  hooksecurefunc(ItemRefTooltip, "SetHyperlink", HookItemRefTooltipSetHyperlink)
  Tool.HookInstalled = true
end

local eventFrame

local function EventHandler(self, event, ...)
  if not self._GPIPRIVAT_events then return end
  for i, Entry in pairs(self._GPIPRIVAT_events) do
    if Entry and Entry[1] == event and type(Entry[2]) == "function" then
      Entry[2](...)
    end
  end
end

local function UpdateHandler(self, ...)
  if not self._GPIPRIVAT_updates then return end
  for i, Entry in pairs(self._GPIPRIVAT_updates) do
    if type(Entry) == "function" then
      Entry(...)
    end
  end
end

function Tool.RegisterEvent(event, func)
  if type(func) ~= "function" then return end
  if eventFrame == nil then
    eventFrame = CreateFrame("Frame")
  end
  if eventFrame._GPIPRIVAT_events == nil then
    eventFrame._GPIPRIVAT_events = {}
    eventFrame:SetScript("OnEvent", EventHandler)
  end
  tinsert(eventFrame._GPIPRIVAT_events, { event, func })
  eventFrame:RegisterEvent(event)
end

function Tool.OnUpdate(func)
  if type(func) ~= "function" then return end
  if eventFrame == nil then
    eventFrame = CreateFrame("Frame")
  end
  if eventFrame._GPIPRIVAT_updates == nil then
    eventFrame._GPIPRIVAT_updates = {}
    eventFrame:SetScript("OnUpdate", UpdateHandler)
  end
  tinsert(eventFrame._GPIPRIVAT_updates, func)
end

local function MovingStart(self)
  self:StartMoving()
end

local function MovingStop(self)
  self:StopMovingOrSizing()
  if self._GPIPRIVAT_MovingStopCallback then
    self._GPIPRIVAT_MovingStopCallback(self)
  end
end

function Tool.EnableMoving(frame, callback)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", MovingStart)
  frame:SetScript("OnDragStop", MovingStop)
  frame._GPIPRIVAT_MovingStopCallback = callback
end

function Tool.GuildNameToIndex(name, searchOffline)
  if type(name) ~= "string" or name == "" then return end
  name = string.lower(name)
  for i = 1, GetNumGuildMembers(searchOffline) do
    local fullName = GetGuildRosterInfo(i)
    if fullName then
      local memberName = string.match(fullName, "^([^%-]+)") or fullName
      if string.lower(memberName) == name then
        return i
      end
    end
  end
end

function Tool.RunSlashCmd(cmd)
end

function Tool.RGBtoEscape(r, g, b, a)
  if type(r) == "table" then
    a = r.a
    g = r.g
    b = r.b
    r = r.r
  end
  r = r ~= nil and r <= 1 and r >= 0 and r or 1
  g = g ~= nil and g <= 1 and g >= 0 and g or 1
  b = b ~= nil and b <= 1 and b >= 0 and b or 1
  a = a ~= nil and a <= 1 and a >= 0 and a or 1
  return string.format("|c%02x%02x%02x%02x", a * 255, r * 255, g * 255, b * 255)
end

function Tool.RGBPercToHex(r, g, b)
  r = r <= 1 and r >= 0 and r or 0
  g = g <= 1 and g >= 0 and g or 0
  b = b <= 1 and b >= 0 and b or 0
  return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function Tool.GetRaidIcon(name)
  local x = string.gsub(string.lower(name), "[%{%}]", "")
  return ICON_TAG_LIST[x] and Tool.RaidIcon[ICON_TAG_LIST[x]] or name
end

function Tool.UnitDistanceSquared(uId)
  local range
  if UnitIsUnit(uId, "player") then
    range = 0
  else
    local distanceSquared, checkedDistance = UnitDistanceSquared(uId)
    if checkedDistance then
      range = distanceSquared
    elseif IsItemInRange(8149, uId) then
      range = 64
    elseif CheckInteractDistance(uId, 3) then
      range = 100
    elseif CheckInteractDistance(uId, 2) then
      range = 121
    elseif IsItemInRange(14530, uId) then
      range = 324
    elseif IsItemInRange(21519, uId) then
      range = 529
    elseif IsItemInRange(1180, uId) then
      range = 1089
    elseif UnitInRange(uId) then
      range = 1849
    else
      range = 10000
    end
  end
  return range
end

function Tool.Merge(t1, ...)
  for index = 1, select("#", ...) do
    for i, v in pairs(select(index, ...)) do
      t1[i] = v
    end
  end
  return t1
end

function Tool.CreatePattern(pattern, maximize)
  pattern = string.gsub(pattern, "[%(%)%-%+%[%]]", "%%%1")
  if not maximize then
    pattern = string.gsub(pattern, "%%s", "(.-)")
  else
    pattern = string.gsub(pattern, "%%s", "(.+)")
  end
  pattern = string.gsub(pattern, "%%d", "%(%%d-%)")
  if not maximize then
    pattern = string.gsub(pattern, "%%%d%$s", "(.-)")
  else
    pattern = string.gsub(pattern, "%%%d%$s", "(.+)")
  end
  pattern = string.gsub(pattern, "%%%d$d", "%(%%d-%)")
  return pattern
end

function Tool.Combine(t, sep, first, last)
  if type(t) ~= "table" then return "" end
  sep = sep or " "
  first = first or 1
  last = last or #t
  local ret = ""
  for i = first, last do
    ret = ret .. sep .. tostring(t[i])
  end
  return string.sub(ret, string.len(sep) + 1)
end

function Tool.iSplit(inputstr, sep)
  if sep == nil then sep = "%s" end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    if not tContains(t, str) then
      table.insert(t, tonumber(str))
    end
  end
  return t
end

local ResizeCursor
local SizingStop = function(self, button)
  self:GetParent():StopMovingOrSizing()
  if self.GPI_DoStop then self.GPI_DoStop(self:GetParent()) end
end

local SizingStart = function(self, button)
  self:GetParent():StartSizing(self.GPI_SIZETYPE)
  if self.GPI_DoStart then self.GPI_DoStart(self:GetParent()) end
end

local SizingEnter = function(self)
  if _G.GetCursorInfo and type(_G.GetCursorInfo) == "function" then
    if _G.GetCursorInfo() then return end
  end
  ResizeCursor:Show()
  ResizeCursor.Texture:SetTexture(self.GPI_Cursor)
  ResizeCursor.Texture:SetRotation(math.rad(self.GPI_Rotation), 0.5, 0.5)
end

local SizingLeave = function(self, button)
  ResizeCursor:Hide()
end

local sizecount = 0
local CreateSizeBorder = function(frame, name, a1, x1, y1, a2, x2, y2, cursor, rot, OnStart, OnStop)
  sizecount = sizecount + 1
  local FrameSizeBorder = CreateFrame("Frame", (frame:GetName() or TOCNAME .. sizecount) .. "_size_" .. name, frame)
  FrameSizeBorder:SetPoint("TOPLEFT", frame, a1, x1, y1)
  FrameSizeBorder:SetPoint("BOTTOMRIGHT", frame, a2, x2, y2)
  FrameSizeBorder.GPI_SIZETYPE = name
  FrameSizeBorder.GPI_Cursor = cursor
  FrameSizeBorder.GPI_Rotation = rot
  FrameSizeBorder.GPI_DoStart = OnStart
  FrameSizeBorder.GPI_DoStop = OnStop
  FrameSizeBorder:SetScript("OnMouseDown", SizingStart)
  FrameSizeBorder:SetScript("OnMouseUp", SizingStop)
  FrameSizeBorder:SetScript("OnEnter", SizingEnter)
  FrameSizeBorder:SetScript("OnLeave", SizingLeave)
  return FrameSizeBorder
end

local ResizeCursor_Update = function(self)
  local X, Y = GetCursorPosition()
  local Scale = self:GetEffectiveScale()
  self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", X / Scale, Y / Scale)
end

function Tool.EnableSize(frame, border, OnStart, OnStop)
  if not ResizeCursor then
    ResizeCursor = CreateFrame("Frame", nil, UIParent)
    ResizeCursor:Hide()
    ResizeCursor:SetWidth(24)
    ResizeCursor:SetHeight(24)
    ResizeCursor:SetFrameStrata("TOOLTIP")
    ResizeCursor.Texture = ResizeCursor:CreateTexture()
    ResizeCursor.Texture:SetAllPoints()
    ResizeCursor:SetScript("OnUpdate", ResizeCursor_Update)
  end
  border = border or 8
  frame:EnableMouse(true)
  frame:SetResizable(true)
  CreateSizeBorder(frame, "BOTTOM", "BOTTOMLEFT", border, border, "BOTTOMRIGHT", -border, 0,
    "Interface\\CURSOR\\UI-Cursor-SizeLeft", 45, OnStart, OnStop)
  CreateSizeBorder(frame, "TOP", "TOPLEFT", border, 0, "TOPRIGHT", -border, -border,
    "Interface\\CURSOR\\UI-Cursor-SizeLeft", 45, OnStart, OnStop)
  CreateSizeBorder(frame, "LEFT", "TOPLEFT", 0, -border, "BOTTOMLEFT", border, border,
    "Interface\\CURSOR\\UI-Cursor-SizeRight", 45, OnStart, OnStop)
  CreateSizeBorder(frame, "RIGHT", "TOPRIGHT", -border, -border, "BOTTOMRIGHT", 0, border,
    "Interface\\CURSOR\\UI-Cursor-SizeRight", 45, OnStart, OnStop)
  CreateSizeBorder(frame, "TOPLEFT", "TOPLEFT", 0, 0, "TOPLEFT", border, -border,
    "Interface\\CURSOR\\UI-Cursor-SizeRight", 0, OnStart, OnStop)
  CreateSizeBorder(frame, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0, "BOTTOMLEFT", border, border,
    "Interface\\CURSOR\\UI-Cursor-SizeLeft", 0, OnStart, OnStop)
  CreateSizeBorder(frame, "TOPRIGHT", "TOPRIGHT", 0, 0, "TOPRIGHT", -border, -border,
    "Interface\\CURSOR\\UI-Cursor-SizeLeft", 0, OnStart, OnStop)
  CreateSizeBorder(frame, "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0, "BOTTOMRIGHT", -border, border,
    "Interface\\CURSOR\\UI-Cursor-SizeRight", 0, OnStart, OnStop)
end

local PopupDepth
local function PopupClick(self, arg1, arg2, checked)
  if type(self.value) == "table" then
    self.value[arg1] = not self.value[arg1]
    self.checked = self.value[arg1]
    if arg2 then arg2(self.value, arg1, checked) end
  elseif type(self.value) == "function" then
    self.value(arg1, arg2)
  end
end

local function PopupAddItem(self, text, disabled, value, arg1, arg2)
  local c = self._Frame._GPIPRIVAT_Items.count + 1
  self._Frame._GPIPRIVAT_Items.count = c
  if not self._Frame._GPIPRIVAT_Items[c] then
    self._Frame._GPIPRIVAT_Items[c] = {}
  end
  local t = self._Frame._GPIPRIVAT_Items[c]
  t.text = text or ""
  t.disabled = disabled or false
  t.value = value
  t.arg1 = arg1
  t.arg2 = arg2
  t.MenuDepth = PopupDepth
end

local function PopupAddSubMenu(self, text, value)
  if text ~= nil and text ~= "" then
    PopupAddItem(self, text, "MENU", value)
    PopupDepth = value
  else
    PopupDepth = nil
  end
end

local PopupLastWipeName
local function PopupWipe(self, WipeName)
  self._Frame._GPIPRIVAT_Items.count = 0
  PopupDepth = nil
  if UIDROPDOWNMENU_OPEN_MENU == self._Frame then
    ToggleDropDownMenu(nil, nil, self._Frame, self._where, self._x, self._y)
    if WipeName == PopupLastWipeName then return false end
  end
  PopupLastWipeName = WipeName
  return true
end

local function PopupCreate(frame, level, menuList)
  if level == nil then return end
  local info = UIDropDownMenu_CreateInfo()
  for i = 1, frame._GPIPRIVAT_Items.count do
    local val = frame._GPIPRIVAT_Items[i]
    if val.MenuDepth == menuList then
      if val.disabled == "MENU" then
        info.text = val.text
        info.notCheckable = true
        info.disabled = false
        info.value = nil
        info.arg1 = nil
        info.arg2 = nil
        info.func = nil
        info.hasArrow = true
        info.menuList = val.value
      else
        info.text = val.text
        if type(val.value) == "table" then
          info.checked = val.value[val.arg1] or false
          info.notCheckable = false
        else
          info.notCheckable = true
        end
        info.disabled = (val.disabled == true or val.text == "")
        info.keepShownOnClick = (val.disabled == "keep")
        info.value = val.value
        info.arg1 = val.arg1
        if type(val.value) == "table" then
          info.arg2 = frame._GPIPRIVAT_TableCallback
        elseif type(val.value) == "function" then
          info.arg2 = val.arg2
        end
        info.func = PopupClick
        info.hasArrow = false
        info.menuList = nil
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end
end

local function PopupShow(self, where, x, y)
  where = where or "cursor"
  if UIDROPDOWNMENU_OPEN_MENU ~= self._Frame then
    UIDropDownMenu_Initialize(self._Frame, PopupCreate, "MENU")
  end
  ToggleDropDownMenu(nil, nil, self._Frame, where, x, y)
  self._where = where
  self._x = x
  self._y = y
end

function Tool.CreatePopup(TableCallback)
  local popup = {}
  popup._Frame = CreateFrame("Frame", "wtf", UIParent, "UIDropDownMenuTemplate")
  popup._Frame._GPIPRIVAT_TableCallback = TableCallback
  popup._Frame._GPIPRIVAT_Items = {}
  popup._Frame._GPIPRIVAT_Items.count = 0
  popup.AddItem = PopupAddItem
  popup.SubMenu = PopupAddSubMenu
  popup.Show = PopupShow
  popup.Wipe = PopupWipe
  return popup
end

local function SelectTab(self)
  if not self._gpi_combatlock or not InCombatLockdown() then
    local parent = self:GetParent()
    PanelTemplates_SetTab(parent, self:GetID())
    for i = 1, parent.numTabs do
      parent.Tabs[i].content:Hide()
    end
    self.content:Show()
    if parent.Tabs[self:GetID()].OnSelect then
      parent.Tabs[self:GetID()].OnSelect(self)
    end
  end
end

function Tool.TabHide(frame, id)
  if id and frame.Tabs and frame.Tabs[id] then
    frame.Tabs[id]:Hide()
  elseif not id and frame.Tabs then
    for i = 1, frame.numTabs do frame.Tabs[i]:Hide() end
  end
end

function Tool.TabShow(frame, id)
  if id and frame.Tabs and frame.Tabs[id] then
    frame.Tabs[id]:Show()
  elseif not id and frame.Tabs then
    for i = 1, frame.numTabs do frame.Tabs[i]:Show() end
  end
end

function Tool.SelectTab(frame, id)
  if id and frame.Tabs and frame.Tabs[id] then
    SelectTab(frame.Tabs[id])
  end
end

function Tool.TabOnSelect(frame, id, func)
  if id and frame.Tabs and frame.Tabs[id] then
    frame.Tabs[id].OnSelect = func
  end
end

function Tool.GetSelectedTab(frame)
  if frame.Tabs then
    for i = 1, frame.numTabs do
      if frame.Tabs[i].content:IsShown() then return i end
    end
  end
  return 0
end

function Tool.AddTab(frame, name, tabFrame, combatlockdown)
  local frameName
  if type(frame) == "string" then
    frameName = frame
    frame = _G[frameName]
  else
    frameName = frame:GetName()
  end
  if type(tabFrame) == "string" then tabFrame = _G[tabFrame] end
  frame.numTabs = frame.numTabs and frame.numTabs + 1 or 1
  if frame.Tabs == nil then frame.Tabs = {} end
  frame.Tabs[frame.numTabs] = CreateFrame("Button", frameName .. "Tab" .. frame.numTabs, frame,
    "CharacterFrameTabButtonTemplate")
  frame.Tabs[frame.numTabs]:SetID(frame.numTabs)
  frame.Tabs[frame.numTabs]:SetText(name)
  frame.Tabs[frame.numTabs]:SetScript("OnClick", SelectTab)
  frame.Tabs[frame.numTabs]._gpi_combatlock = combatlockdown
  frame.Tabs[frame.numTabs].content = tabFrame
  tabFrame:Hide()
  if frame.numTabs == 1 then
    frame.Tabs[frame.numTabs]:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 4)
  else
    frame.Tabs[frame.numTabs]:SetPoint("TOPLEFT", frame.Tabs[frame.numTabs - 1], "TOPRIGHT", -14, 0)
  end
  SelectTab(frame.Tabs[frame.numTabs])
  SelectTab(frame.Tabs[1])
  return frame.numTabs
end

local DataBrocker = false
function Tool.AddDataBrocker(icon, onClick, onTooltipShow, text)
  if LibStub ~= nil and DataBrocker ~= true then
    local Launcher = LibStub('LibDataBroker-1.1', true)
    if Launcher ~= nil then
      DataBrocker = true
      Launcher:NewDataObject(TOCNAME, {
        type = "launcher",
        icon = icon,
        OnClick = onClick,
        OnTooltipShow = onTooltipShow,
        tocname = TOCNAME,
        label = text or GetAddOnMetadata(TOCNAME, "Title"),
      })
    end
  end
end

local slash, slashCmd
local function slashUnpack(t, sep)
  local ret = ""
  if sep == nil then sep = ", " end
  for i = 1, #t do
    if i ~= 1 then ret = ret .. sep end
    ret = ret .. t[i]
  end
  return ret
end

function Tool.PrintSlashCommand(prefix, subSlash, p)
  p = p or print
  prefix = prefix or ""
  subSlash = subSlash or slash
  local colCmd = "|cFFFF9C00"
  for i, subcmd in ipairs(subSlash) do
    local words = (type(subcmd[1]) == "table") and "|r(" .. colCmd .. slashUnpack(subcmd[1], "|r/" .. colCmd) ..
        "|r)" .. colCmd or subcmd[1]
    if words == "%" then words = "<value>" end
    if subcmd[2] ~= nil and subcmd[2] ~= "" then
      p(colCmd .. ((type(slashCmd) == "table") and slashCmd[1] or slashCmd) .. " " .. prefix .. words ..
        "|r: " .. subcmd[2])
    end
    if type(subcmd[3]) == "table" then
      Tool.PrintSlashCommand(prefix .. words .. " ", subcmd[3], p)
    end
  end
end

local function DoSlash(deep, msg, subSlash)
  for i, subcmd in ipairs(subSlash) do
    local ok = (type(subcmd[1]) == "table") and tContains(subcmd[1], msg[deep]) or
        (subcmd[1] == msg[deep] or (subcmd[1] == "" and msg[deep] == nil))
    if subcmd[1] == "%" then
      local para = Tool.iMerge({ unpack(subcmd, 4) }, { unpack(msg, deep) })
      return subcmd[3](unpack(para))
    end
    if ok then
      if type(subcmd[3]) == "function" then
        return subcmd[3](unpack(subcmd, 4))
      elseif type(subcmd[3]) == "table" then
        return DoSlash(deep + 1, msg, subcmd[3])
      end
    end
  end
  Tool.PrintSlashCommand(Tool.Combine(msg, " ", 1, deep - 1) .. " ", subSlash)
  return nil
end

local function mySlashs(msg)
  if msg == "help" then
    local colCmd = "|cFFFF9C00"
    print("|cFFFF1C1C" ..
      GetAddOnMetadata(TOCNAME, "Title") ..
      " " .. GetAddOnMetadata(TOCNAME, "Version") .. " by " .. GetAddOnMetadata(TOCNAME, "Author"))
    print(GetAddOnMetadata(TOCNAME, "Notes"))
    if type(slashCmd) == "table" then
      print("SlashCommand:", colCmd, slashUnpack(slashCmd, "|r, " .. colCmd), "|r")
    end
    Tool.PrintSlashCommand()
  else
    DoSlash(1, Tool.Split(msg, " "), slash)
  end
end

function Tool.SlashCommand(cmds, subcommand)
  slash = subcommand
  slashCmd = cmds
  if type(cmds) == "table" then
    for i, cmd in ipairs(cmds) do
      _G["SLASH_" .. TOCNAME .. i] = cmd
    end
  else
    _G["SLASH_" .. TOCNAME .. "1"] = cmds
  end
  SlashCmdList[TOCNAME] = mySlashs
end

function Tool.InDateRange(startDate, endDate)
  local currentMonth, currentDay = date("%m/%d"):match("(%d+)/(%d+)")
  local startMonth, startDay = startDate:match("(%d+)/(%d+)")
  local endMonth, endDay = endDate:match("(%d+)/(%d+)")
  if (startMonth <= currentMonth and currentMonth <= endMonth) and
      ((currentMonth == startMonth and currentDay >= startDay) or (currentMonth == endMonth and currentDay < endDay)) then
    return true
  else
    return false
  end
end
