if not GBB then
  GBB = GroupBulletinBoard_Addon or {}
end
local LSM = LibStub("LibSharedMedia-3.0")

local tconcat = table.concat
local wipe = GBB.api.wipe
local RAID_CLASS_COLORS_HEX = GBB.api.RAID_CLASS_COLORS_HEX
local has_wotlk = (GBB.api.content.expansion >= GBB.api.content.WOTLK)
local function GetDungeonPriority(dungeon)
  if not dungeon then return 0 end
  local prio = 0
  if GBB.RaidList[dungeon] then
    prio = prio + 10000
  elseif dungeon == "TRADE" then
    prio = prio + 100
  elseif dungeon == "MISC" then
    prio = prio + 50
  else
    prio = prio + 1000
  end
  local sortIndex = GBB.dungeonSort[dungeon]
  if sortIndex then
    if has_wotlk then
      if sortIndex >= GBB.WOTLKDUNGEONSTART then
        prio = prio + 300
      elseif sortIndex >= GBB.TBCDUNGEONSTART then
        prio = prio + 200
      else
        prio = prio + 100
      end
    else
      if sortIndex >= GBB.TBCDUNGEONSTART then
        prio = prio + 200
      else
        prio = prio + 100
      end
    end
  end
  return prio
end
local LastDungeon
local lastIsFolded

-- Forward declarations so the click handler installed in CreateItem (defined
-- earlier in the file than these helpers) can reach them via upvalues.
local GBB_MeasureFS
local FindLinkAtCursor

local function GetDynamicClassIcon(classFile, size, yoffset)
  local staticIcon = GBB.Tool.IconClass[classFile]
  if not staticIcon then return "" end
  local path = staticIcon:match("%|T(.-):%d+:%d+")
  if not path then return staticIcon end
  yoffset = yoffset or 0
  return string.format("|T%s:%d:%d:0:%d:64:64:0:64:0:64|t", path, size, size, yoffset)
end

local function requestSort_TOP_TOTAL(a, b)
  if not a or not b then return false end
  local sortA = a.dungeon and GBB.dungeonSort[a.dungeon]
  local sortB = b.dungeon and GBB.dungeonSort[b.dungeon]
  if not sortA or not sortB then return false end
  if sortA < sortB then
    return true
  elseif sortA == sortB then
    local startA = a.start or 0
    local startB = b.start or 0
    if startA > startB then
      return true
    elseif startA == startB then
      return (a.name or "") > (b.name or "")
    end
  end
  return false
end

local function requestSort_TOP_nTOTAL(a, b)
  if not a or not b then return false end
  local sortA = a.dungeon and GBB.dungeonSort[a.dungeon]
  local sortB = b.dungeon and GBB.dungeonSort[b.dungeon]
  if not sortA or not sortB then return false end
  if sortA < sortB then
    return true
  elseif sortA == sortB then
    local lastA = a.last or 0
    local lastB = b.last or 0
    if lastA > lastB then
      return true
    elseif lastA == lastB then
      local startA = a.start or 0
      local startB = b.start or 0
      if startA == startB then
        return (a.name or "") > (b.name or "")
      end
    end
  end
  return false
end

local function requestSort_nTOP_TOTAL(a, b)
  if not a or not b then return false end
  local sortA = a.dungeon and GBB.dungeonSort[a.dungeon]
  local sortB = b.dungeon and GBB.dungeonSort[b.dungeon]
  if not sortA or not sortB then return false end
  if sortA < sortB then
    return true
  elseif sortA == sortB then
    local startA = a.start or 0
    local startB = b.start or 0
    if startA < startB then
      return true
    elseif startA == startB then
      return (a.name or "") > (b.name or "")
    end
  end
  return false
end

local function requestSort_nTOP_nTOTAL(a, b)
  if not a or not b then return false end
  local sortA = a.dungeon and GBB.dungeonSort[a.dungeon]
  local sortB = b.dungeon and GBB.dungeonSort[b.dungeon]
  if not sortA or not sortB then return false end
  if sortA < sortB then
    return true
  elseif sortA == sortB then
    local lastA = a.last or 0
    local lastB = b.last or 0
    if lastA < lastB then
      return true
    elseif lastA == lastB then
      local startA = a.start or 0
      local startB = b.start or 0
      if startA == startB then
        return (a.name or "") > (b.name or "")
      end
    end
  end
  return false
end

local function CreateHeader(yy, dungeon)
  local AnchorTop = "GroupBulletinBoardFrame_ScrollChildFrame"
  local AnchorRight = "GroupBulletinBoardFrame_ScrollChildFrame"
  local ItemFrameName = "GBB.Dungeon_" .. dungeon
  local fontPath = LSM:Fetch("font", GBB.DB.fontFace, true)
  local fontSize = GBB.DB.fontSize

  if GBB.FramesEntries[dungeon] == nil then
    GBB.FramesEntries[dungeon] = CreateFrame("Frame", ItemFrameName, GroupBulletinBoardFrame_ScrollChildFrame,
      "GroupBulletinBoard_TmpHeader")
    GBB.FramesEntries[dungeon]:SetPoint("RIGHT", _G[AnchorRight], "RIGHT", 0, 0)
    _G[ItemFrameName .. "_name"]:SetPoint("RIGHT", GBB.FramesEntries[dungeon], "RIGHT", 0, 0)
    local fname, h = _G[ItemFrameName .. "_name"]:GetFont()
    _G[ItemFrameName .. "_name"]:SetHeight(h)
    _G[ItemFrameName]:SetHeight(h + 6)
    _G[ItemFrameName .. "_name"]:SetFont(fontPath, fontSize)
  else
    _G[ItemFrameName .. "_name"]:SetFont(fontPath, fontSize)
  end

  local colTXT
  if GBB.DB.ColorOnLevel then
    if GBB.dungeonLevel[dungeon][1] == 0 then
      colTXT = "|r"
    elseif GBB.dungeonLevel[dungeon][2] < GBB.UserLevel then
      colTXT = "|cFFAAAAAA"
    elseif GBB.UserLevel < GBB.dungeonLevel[dungeon][1] then
      colTXT = "|cffff4040"
    else
      colTXT = "|cff00ff00"
    end
  else
    colTXT = "|r"
  end

  if LastDungeon ~= nil and not (lastIsFolded and GBB.FoldedDungeons[dungeon]) then
    yy = yy + 6
  end

  if GBB.FoldedDungeons[dungeon] == true then
    colTXT = colTXT .. "[+] "
    lastIsFolded = true
  else
    lastIsFolded = false
  end

  local noIconDungeons = { MISC = true, TRADE = true, DEBUG = true, BAD = true, NIL = true }
  local headerIcon = ""
  if not noIconDungeons[dungeon] then
    local iconSize = fontSize + 6
    local tex = GBB.AchievementIcon.texture
    local l, r, t, b = unpack(GBB.AchievementIcon.texCoord)
    local texWidth, texHeight = 64, 64
    local left = l * texWidth
    local right = r * texWidth
    local top = t * texHeight
    local bottom = b * texHeight
    headerIcon = string.format("|T%s:%d:%d:0:-2:%d:%d:%d:%d:%d:%d|t ", tex, iconSize, iconSize, texWidth, texHeight,
      left, right, top, bottom)
  end

  _G[ItemFrameName .. "_name"]:SetText(headerIcon ..
    colTXT .. GBB.dungeonNames[dungeon] .. " |cFFAAAAAA" .. GBB.LevelRange(dungeon) .. "|r")
  _G[ItemFrameName .. "_name"]:SetFont(fontPath, fontSize)
  GBB.FramesEntries[dungeon]:SetPoint("TOPLEFT", _G[AnchorTop], "TOPLEFT", 10, -yy)
  GBB.FramesEntries[dungeon]:Show()

  yy = yy + _G[ItemFrameName]:GetHeight()
  if GBB.DB.Donttruncate then
    yy = yy
  end
  LastDungeon = dungeon
  return yy
end

local function CreateItem(yy, i, doCompact, req, forceHight)
  local AnchorTop = "GroupBulletinBoardFrame_ScrollChildFrame"
  local AnchorRight = "GroupBulletinBoardFrame_ScrollChildFrame"
  local ItemFrameName = "GBB.Item_" .. i

  if GBB.FramesEntries[i] == nil then
    GBB.FramesEntries[i] = CreateFrame("Button", ItemFrameName, GroupBulletinBoardFrame_ScrollChildFrame,
      "GroupBulletinBoard_TmpRequest")
    GBB.FramesEntries[i]:SetPoint("RIGHT", _G[AnchorRight], "RIGHT", 0, 0)

    _G[ItemFrameName .. "_name"]:SetPoint("TOPLEFT")
    _G[ItemFrameName .. "_time"]:SetPoint("TOP", _G[ItemFrameName .. "_name"], "TOP", 0, 0)

    local LSM = LibStub("LibSharedMedia-3.0")
    local fontPath = LSM:Fetch("font", GBB.DB.fontFace, true)
    local fontSize = GBB.DB.fontSize
    _G[ItemFrameName .. "_message"]:SetFont(fontPath, fontSize)
    _G[ItemFrameName .. "_name"]:SetFont(fontPath, fontSize)
    _G[ItemFrameName .. "_time"]:SetFont(fontPath, fontSize)

    if i > 0 then
      local frame = GBB.FramesEntries[i]
      if frame.SetHyperlinksEnabled then
        frame:SetHyperlinksEnabled(true)
      end
    end

    GBB.FramesEntries[i]:SetScript("OnMouseDown", function(self, button)
      -- A click on a hyperlink (item, achievement, profession, etc.) must
      -- behave like a standard chat link click, regardless of modifier keys.
      -- GBB's shift/ctrl/alt shortcuts only apply to clicks on plain text.
      if button == "LeftButton" then
        local msg = _G[self:GetName() .. "_message"]
        if msg then
          local x, y = GetCursorPosition()
          local scale = self:GetEffectiveScale()
          local left = msg:GetLeft()
          local top = msg:GetTop()
          local width = msg:GetWidth()
          local height = msg:GetHeight()
          if x and y and scale and scale > 0 and left and top and width and height then
            local cx, cy = x / scale, y / scale
            if cx >= left and cx <= left + width and cy <= top and cy >= top - height and FindLinkAtCursor then
              local link = FindLinkAtCursor(msg, cx)
              if link then
                SetItemRef(link, link, "LeftButton")
                return
              end
            end
          end
        end
      end
      GBB.ClickRequest(self, button)
    end)
  end

  local message = _G[ItemFrameName .. "_message"]
  local nameStr = _G[ItemFrameName .. "_name"]
  local timeStr = _G[ItemFrameName .. "_time"]

  local availableWidth = GroupBulletinBoardFrame:GetWidth() - 20 - 10 - 10
  if doCompact < 1 then
    availableWidth = availableWidth - 20
  end
  if not GBB.DB.ChatStyle then
    availableWidth = availableWidth - GBB.DB.widthNames - GBB.DB.widthTimes - 30
  end
  local msgWidth = availableWidth - 10
  message:SetWidth(msgWidth)

  if doCompact < 1 then
    message:SetPoint("TOPLEFT", nameStr, "BOTTOMLEFT", 0, 0)
    message:SetPoint("RIGHT", timeStr, "RIGHT", 0, 0)
  else
    message:SetPoint("TOPLEFT", nameStr, "TOPRIGHT", 10, 0)
    message:SetPoint("RIGHT", timeStr, "LEFT", -10, 0)
  end

  if req then
    local prefix = "|r"
    if GBB.DB.ColorByClass and req.class and RAID_CLASS_COLORS_HEX[req.class] then
      prefix = "|c" .. RAID_CLASS_COLORS_HEX[req.class]
    end

    local ClassIcon = ""
    if GBB.DB.ShowClassIcon and req.class and GBB.Tool.IconClass[req.class] then
      if doCompact < 1 or GBB.DB.ChatStyle then
        ClassIcon = GBB.Tool.IconClass[req.class]
      else
        ClassIcon = GBB.Tool.IconClassBig[req.class]
      end
    end

    local FriendIcon = (req.IsFriend and string.format(GBB.TxtEscapePicture, GBB.FriendIcon) or "") ..
        (req.IsGuildMember and string.format(GBB.TxtEscapePicture, GBB.GuildIcon) or "") ..
        (req.IsPastPlayer and string.format(GBB.TxtEscapePicture, GBB.PastPlayerIcon) or "")

    local suffix = "|r"
    if GBB.RealLevel[req.name] then
      suffix = " (" .. GBB.RealLevel[req.name] .. ")" .. suffix
    end

    local ti
    if GBB.DB.ShowTotalTime then
      ti = GBB.formatTime(time() - req.start)
    else
      ti = GBB.formatTime(time() - req.last)
    end

    local typePrefix
    local isHeroicRaid = (req.IsRaid and GBB.HeroicRaidList and GBB.HeroicRaidList[req.dungeon])
    if req.dungeon == "MISC" or req.dungeon == "TRADE" then
      typePrefix = ""
    elseif req.IsRaid and not isHeroicRaid then
      typePrefix = "|c00ffff00" .. "[" .. GBB.L["raidAbr"] .. "] "
    else
      local colorHex
      if req.IsHeroic then
        colorHex = GBB.Tool.RGBPercToHex(GBB.DB.HeroicDungeonColor.r, GBB.DB.HeroicDungeonColor.g,
          GBB.DB.HeroicDungeonColor.b)
        typePrefix = "|c00" .. colorHex .. "[" .. GBB.L["heroicAbr"] .. "] "
      else
        colorHex = GBB.Tool.RGBPercToHex(GBB.DB.NormalDungeonColor.r, GBB.DB.NormalDungeonColor.g,
          GBB.DB.NormalDungeonColor.b)
        typePrefix = "|c00" .. colorHex .. "[" .. GBB.L["normalAbr"] .. "] "
      end
    end

    local rawMessage
    if GBB.DB.ChatStyle then
      nameStr:SetText("")
      rawMessage = ClassIcon .. "[" .. prefix .. req.name .. suffix .. "]" .. FriendIcon .. ": " .. req.message
    else
      nameStr:SetText(ClassIcon .. prefix .. req.name .. suffix .. FriendIcon)
      rawMessage = typePrefix .. "|r" .. req.message
      timeStr:SetText(ti)
    end

    message:SetText(rawMessage)
    message:SetTextColor(GBB.DB.EntryColor.r, GBB.DB.EntryColor.g, GBB.DB.EntryColor.b, GBB.DB.EntryColor.a)
    timeStr:SetTextColor(GBB.DB.TimeColor.r, GBB.DB.TimeColor.g, GBB.DB.TimeColor.b, GBB.DB.TimeColor.a)
  else
    nameStr:SetText("Aag ")
    message:SetText("Aag ")
    timeStr:SetText("Aag ")
  end

  local singleLineHeight = GBB.DB.fontSize + 4
  if singleLineHeight < 14 then singleLineHeight = 14 end

  message:SetHeight(0)
  local fullHeight = message:GetStringHeight()
  if fullHeight < singleLineHeight then fullHeight = singleLineHeight end

  local textHeight
  if GBB.DB.Donttruncate then
    textHeight = fullHeight
  else
    textHeight = singleLineHeight
  end

  local h
  if GBB.DB.ChatStyle then
    h = textHeight
  else
    if doCompact < 1 then
      h = nameStr:GetStringHeight() + textHeight
    else
      h = math.max(nameStr:GetStringHeight(), textHeight)
    end
  end

  message:SetHeight(textHeight)
  GBB.FramesEntries[i]:SetHeight(h)

  if GBB.DB.ChatStyle then
    timeStr:Hide()
    nameStr:Hide()
    nameStr:SetWidth(1)
    timeStr:SetPoint("LEFT", _G[AnchorRight], "RIGHT", 0, 0)
  else
    timeStr:Show()
    nameStr:Show()
    local w = nameStr:GetStringWidth() + 10
    if w > GBB.DB.widthNames then GBB.DB.widthNames = w end
    nameStr:SetWidth(GBB.DB.widthNames)

    local wt = timeStr:GetStringWidth() + 10
    if wt > GBB.DB.widthTimes then GBB.DB.widthTimes = wt end
    timeStr:SetPoint("LEFT", _G[AnchorRight], "RIGHT", -GBB.DB.widthTimes, 0)
  end

  GBB.FramesEntries[i]:SetPoint("TOPLEFT", _G[AnchorTop], "TOPLEFT", 36, -yy)

  if req then
    GBB.FramesEntries[i]:Show()
  else
    GBB.FramesEntries[i]:Hide()
  end

  return h
end

local function IgnoreRequest(name)
  for ir, req in pairs(GBB.RequestList) do
    if type(req) == "table" and req.name == name then
      req.last = 0
    end
  end
  GBB.ClearNeeded = true
end

function GBB.Clear()
  if GBB.ClearNeeded or GBB.ClearTimer < time() then
    local newRequest = {}
    local now = time()
    local minLast = now

    for i, req in ipairs(GBB.RequestList) do
      if type(req) == "table" and req.dungeon and req.start and req.last and req.name then
        if req.last + GBB.DB.TimeOut > now then
          if req.last < minLast then
            minLast = req.last
          end
          newRequest[#newRequest + 1] = req
        end
      end
    end

    GBB.RequestList = newRequest
    GBB.ClearTimer = minLast + GBB.DB.TimeOut
    GBB.ClearNeeded = false
  end
end

function GBB.UpdateList()
  GBB.Clear()

  if not GroupBulletinBoardFrame:IsVisible() then
    return
  end

  local scrollFrame = GroupBulletinBoardFrame_ScrollFrame
  local savedScrollScript = scrollFrame:GetScript("OnScrollRangeChanged")
  scrollFrame:SetScript("OnScrollRangeChanged", nil)
  local scrollValue = scrollFrame:GetVerticalScroll()
  local scrollHeight = scrollFrame:GetHeight()

  local topDungeon = nil
  local topDungeonOffset = 0
  if GBB.dungeonHeaderY then
    local bestY = -1
    for dungeon, headerY in pairs(GBB.dungeonHeaderY) do
      if headerY <= scrollValue and headerY > bestY then
        bestY = headerY
        topDungeon = dungeon
        topDungeonOffset = scrollValue - headerY
      end
    end
  end

  GBB.UserLevel = UnitLevel("player")

  local validList = {}
  for _, v in ipairs(GBB.RequestList) do
    if v and type(v) == "table" and v.dungeon and v.start and v.last and v.name then
      validList[#validList + 1] = v
    end
  end
  GBB.RequestList = validList

  if GBB.DB.OrderNewTop then
    if GBB.DB.ShowTotalTime then
      table.sort(GBB.RequestList, requestSort_TOP_TOTAL)
    else
      table.sort(GBB.RequestList, requestSort_TOP_nTOTAL)
    end
  else
    if GBB.DB.ShowTotalTime then
      table.sort(GBB.RequestList, requestSort_nTOP_TOTAL)
    else
      table.sort(GBB.RequestList, requestSort_nTOP_nTOTAL)
    end
  end

  for i, f in pairs(GBB.FramesEntries) do
    f:Hide()
  end

  local yy = 0
  local count = 0
  local doCompact = 1
  if GBB.DB.CompactStyle and not GBB.DB.ChatStyle then
    doCompact = 0.85
  end

  LastDungeon = nil
  lastIsFolded = false
  local ownRequestDungeons = {}
  wipe(ownRequestDungeons)
  if GBB.DBChar.DontFilterOwn then
    local playername = GBB.api.UnitFullName("player")
    for i, req in ipairs(GBB.RequestList) do
      if req.name == playername and req.last + GBB.DB.TimeOut * 2 > time() then
        ownRequestDungeons[req.dungeon] = true
      end
    end
  end

  local itemHeight = CreateItem(yy, 0, doCompact, nil)
  if not GBB.FramesEntries[100] then
    for i = 1, 100 do
      CreateItem(yy, i, doCompact, nil)
    end
  end

  local currentDungeon = nil
  local shownCount = 0
  local newDungeonHeaderY = {}

  for i, req in ipairs(GBB.RequestList) do
    local isFiltered = (ownRequestDungeons[req.dungeon] == true or GBB.FilterDungeon(req.dungeon, req.IsHeroic, req.IsRaid))
    if isFiltered and req.last + GBB.DB.TimeOut > time() then
      count = count + 1

      if currentDungeon ~= req.dungeon then
        currentDungeon = req.dungeon
        shownCount = 0
        local headerStartY = yy
        yy = CreateHeader(yy, req.dungeon)
        newDungeonHeaderY[req.dungeon] = headerStartY
      end
      if GBB.FoldedDungeons[req.dungeon] ~= true then
        if not GBB.DB.EnableShowOnly or shownCount < GBB.DB.ShowOnlyNb then
          yy = yy + CreateItem(yy, i, doCompact, req, nil) + 2
          shownCount = shownCount + 1
        end
      end
    end
  end

  GBB.dungeonHeaderY = newDungeonHeaderY

  if yy < scrollHeight then
    yy = scrollHeight
  end

  local maxScroll = math.max(0, yy - scrollHeight)

  local targetY = scrollValue
  if topDungeon and newDungeonHeaderY[topDungeon] then
    targetY = newDungeonHeaderY[topDungeon] + topDungeonOffset
  end
  if targetY > maxScroll then targetY = maxScroll end
  if targetY < 0 then targetY = 0 end

  GroupBulletinBoardFrame_ScrollChildFrame:SetHeight(yy)
  scrollFrame:SetVerticalScroll(targetY)
  GBB.pendingScrollRestore = targetY

  if savedScrollScript then
    scrollFrame:SetScript("OnScrollRangeChanged", savedScrollScript)
  end

  local scrollBar = _G["GroupBulletinBoardFrame_ScrollFrameScrollBar"]
  if scrollBar then
    if maxScroll <= 0 then
      scrollBar:SetMinMaxValues(0, 0)
      scrollBar:Hide()
    else
      scrollBar:SetMinMaxValues(0, maxScroll)
      scrollBar:SetValue(targetY)
      scrollBar:Show()
    end
  end

  GroupBulletinBoardFrameStatusText:SetText(string.format(GBB.L["msgNbRequest"], count))
end

local nonLfgHyperlinks = {
  ["|Hglyph:"] = true,
  ["|Hspell:"] = true,
  ["|Henchant:"] = true,
  ["|Htalent:"] = true,
  ["|Htrade:"] = true,
}

local function hasNonLfgHyperlinks(msg)
  for k, v in pairs(nonLfgHyperlinks) do
    if strfind(msg, k, 1, true) then
      return true
    end
  end
  return false
end

function GBB.GetDungeons(msg, name)
  if msg == nil then return {} end
  if msg == "" then return {} end
  local dungeons = {}

  local isBad = false
  local isGood = false
  local isHeroic = false

  local runrequired = false
  local hasrun = false
  local runDungeon = ""

  local wordcount = 0

  if GBB.DB.TagsZhtw then
    for key, v in pairs(GBB.tagList) do
      if strfind(msg:lower(), key) then
        if v == GBB.TAGSEARCH then
          isGood = true
        elseif v == GBB.TAGBAD then
          break
        elseif v ~= nil then
          dungeons[v] = true
        end
      end
    end
    for key, v in pairs(GBB.HeroicKeywords) do
      if strfind(msg:lower(), key) then
        isHeroic = true
      end
    end
    wordcount = string.len(msg)
  else
    local parts = GBB.SplitNoNb(msg)
    for idx, p in ipairs(parts) do
      p = string.gsub(p, "^%d+", "")
      p = string.gsub(p, "[%[%]#]", "")
      parts[idx] = p
    end
    local raidList = { "icc", "rs", "voa", "naxx", "uld", "toc", "ony", "os", "eoe", "ulduar", "karazhan", "gruul", "mag",
      "ssc", "tk", "hyjal", "bt", "swp", "mc", "bwl", "aq", "zg" }
    for _, p in ipairs(parts) do
      for _, raid in ipairs(raidList) do
        local raidName, size, suffix = string.match(p, "^(" .. raid .. ")(%d+)([a-z]*)$")
        if not raidName then
          raidName, size = string.match(p, "^(" .. raid .. ")(%d+)$")
          suffix = ""
        end
        if raidName then
          local upperRaid = string.upper(raidName)
          dungeons[upperRaid] = true
          if suffix == "hc" or suffix == "h" or suffix == "hm" then
            isHeroic = true
          end
          break
        end
      end
    end
    for _, p in ipairs(parts) do
      if p == "run" or p == "runs" then
        hasrun = true
      end

      local x = GBB.tagList[p]

      if GBB.HeroicKeywords[p] ~= nil then
        isHeroic = true
      end

      if x == nil then
        if GBB.tagList[p .. "run"] ~= nil then
          runDungeon = GBB.tagList[p .. "run"]
          runrequired = true
        end
      elseif x == GBB.TAGBAD then
        isBad = true
        break
      elseif x == GBB.TAGSEARCH then
        isGood = true
      else
        dungeons[x] = true
      end
    end
    wordcount = #(parts)
  end

  if runrequired and hasrun and runDungeon and isBad == false then
    if runDungeon then
      dungeons[runDungeon] = true
    end
  end

  local nameLevel = 0
  if name ~= nil then
    if GBB.RealLevel[name] then
      nameLevel = GBB.RealLevel[name]
    else
      for dungeon, id in pairs(dungeons) do
        if dungeon then
          local levelInfo = GBB.dungeonLevel[dungeon]
          if levelInfo and levelInfo[1] and levelInfo[1] > 0 and nameLevel < levelInfo[1] then
            nameLevel = levelInfo[1]
          end
        end
      end
    end
  end

  if dungeons["DEADMINES"] and not dungeons["DMW"] and not dungeons["DME"] and not dungeons["DME"] and name ~= nil then
    if nameLevel > 0 and nameLevel < 40 then
      dungeons["DM"] = true
      dungeons["DM2"] = false
    else
      dungeons["DM"] = false
      dungeons["DM2"] = true
    end
  end

  if not dungeons["TRADE"] and not dungeons["MISC"]
      and hasNonLfgHyperlinks(msg) then
    isBad = true
    isGood = false
  end

  if isBad then
  elseif isGood then
    for ip, p in pairs(GBB.dungeonSecondTags) do
      local ok = false
      if dungeons[ip] == true then
        for it, t in ipairs(p) do
          if string.sub(t, 1, 1) == "-" then
            if dungeons[string.sub(t, 2)] == true then
              ok = true
            end
          elseif dungeons[t] == true then
            ok = true
          end
        end
        if ok == false then
          for it, t in ipairs(p) do
            if string.sub(t, 1, 1) ~= "-" then
              dungeons[t] = true
            end
          end
        end
      end
    end

    if next(dungeons) == nil then
      dungeons["MISC"] = true
    end
  elseif dungeons["TRADE"] then
    isGood = true
  end

  for ip, p in pairs(GBB.dungeonSecondTags) do
    if dungeons[ip] == true then
      dungeons[ip] = nil
    end
  end

  if GBB.DB.CombineSubDungeons then
    for ip, p in pairs(GBB.dungeonSecondTags) do
      if ip ~= "DEATHMINES" then
        for is, subDungeon in pairs(p) do
          if dungeons[subDungeon] then
            dungeons[ip] = true
            dungeons[subDungeon] = nil
          end
        end
      end
    end
  end

  return dungeons, isGood, isBad, wordcount, isHeroic
end

local function is_non_ascii(text)
  if not text then return false end
  for i = 1, #text do
    if text:byte(i) > 127 then return true end
  end
  return false
end

function GBB.ParseMessage(msg, name, guid, channel)
  if GBB.Initalized == false or name == nil or name == "" or msg == nil or msg == "" or string.len(msg) < 4 then
    return
  end

  if GBB.DB.FilterNonAsciiMessages and is_non_ascii(msg) then return end

  local requestTime = time()

  local parsedMsg = msg:gsub("|H.-|h%[.-%]|h", "")

  if GBB.DB.RemoveRaidSymbols then
    parsedMsg = string.gsub(parsedMsg, "{.-}", "*")
    msg = string.gsub(msg, "{.-}", "*")
  else
    parsedMsg = string.gsub(parsedMsg, "{.-}", GBB.Tool.GetRaidIcon)
    msg = string.gsub(msg, "{.-}", GBB.Tool.GetRaidIcon)
  end

  local fullName = name
  name = GBB.Tool.Split(name, "-")[1]

  local dungeonList, isGood, isBad, wordcount, isHeroic = GBB.GetDungeons(parsedMsg, name)
  if type(dungeonList) ~= "table" then return end
  if isBad then return end

  if GBB.DB.UseAllInLFG and isBad == false and isGood == false and string.lower(GBB.L["lfg_channel"]) == string.lower(channel) then
    isGood = true
    if next(dungeonList) == nil then
      dungeonList["MISC"] = true
    end
  elseif isGood == false or isBad == true then
    return
  end

  if wordcount <= 1 then return end

  if dungeonList["TRADE"] and isGood then
    local hasOther = false
    for d, _ in pairs(dungeonList) do
      if d ~= "TRADE" and d ~= "MISC" then
        hasOther = true
        break
      end
    end
    if hasOther then
      dungeonList["TRADE"] = nil
    end
  end

  local hasSpecific = false
  for d, _ in pairs(dungeonList) do
    if d ~= "MISC" then
      hasSpecific = true
      break
    end
  end
  if hasSpecific then
    dungeonList["MISC"] = nil
  end

  if not next(dungeonList) then
    return
  end

  local bestDungeon = nil
  local bestPriority = -1
  for d, _ in pairs(dungeonList) do
    local prio = GetDungeonPriority(d)
    if prio > bestPriority then
      bestPriority = prio
      bestDungeon = d
    end
  end

  if not bestDungeon then
    return
  end

  local finalDungeonList = { [bestDungeon] = true }

  if channel == "YELL" or channel == "EMOTE" then
    local throttle = GBB.SPAM_THROTTLE_SECONDS or 30
    for _, req in ipairs(GBB.RequestList) do
      if type(req) == "table" then
        local sameSender = (guid and guid ~= "" and req.guid == guid)
            or (req.fullName and req.fullName == fullName)
            or (req.name and req.name == name)
        if sameSender then
          if (req.last or 0) + throttle > requestTime then
            return
          end
          break
        end
      end
    end
  end

  for i = #GBB.RequestList, 1, -1 do
    local req = GBB.RequestList[i]
    if type(req) == "table" then
      if (guid and req.guid == guid) or (req.fullName == fullName) or (req.name == name) then
        table.remove(GBB.RequestList, i)
        GBB.ClearNeeded = true
      end
    end
  end

  local playerClass = nil
  if guid and guid ~= "" then
    local locClass, engClass = GetPlayerInfoByGUID(guid)
    if engClass and engClass ~= "" then
      playerClass = engClass
    end
    if not playerClass then
      local _, classFromUnit = UnitClass(name)
      if classFromUnit and classFromUnit ~= "" then
        playerClass = classFromUnit
      end
    end
  end
  if not playerClass and GBB.RealClass then
    playerClass = GBB.RealClass[name] or GBB.RealClass[fullName]
  end
  if not playerClass then
    local colorMatch = string.match(msg, "|c(%x%x%x%x%x%x%x%x)")
    if colorMatch then
      local r = tonumber("0x" .. colorMatch:sub(3, 4)) or 0
      local g = tonumber("0x" .. colorMatch:sub(5, 6)) or 0
      local b = tonumber("0x" .. colorMatch:sub(7, 8)) or 0
      if r > 0 or g > 0 or b > 0 then
        for class, color in pairs(GBB.Tool.ClassColor) do
          if math.abs(color.r * 255 - r) < 15 and math.abs(color.g * 255 - g) < 15 and math.abs(color.b * 255 - b) < 15 then
            playerClass = class
            break
          end
        end
      end
    end
  end

  if playerClass then
    GBB.RealClass[name] = playerClass
    GBB.RealClass[fullName] = playerClass
  end

  for dungeon, _ in pairs(finalDungeonList) do
    if not dungeon or dungeon == "" then break end
    local isRaid = GBB.RaidList[dungeon] ~= nil
    local newReq = {
      fullName = fullName,
      guid = guid,
      name = name,
      class = playerClass,
      start = requestTime,
      last = requestTime,
      dungeon = dungeon,
      message = msg,
      IsHeroic = isHeroic,
      IsRaid = isRaid,
      IsGuildMember = false,
      IsFriend = false,
      IsPastPlayer = GBB.GroupTrans[name] ~= nil,
    }
    table.insert(GBB.RequestList, newReq)
    GBB.ClearNeeded = true
    GBB.ScheduleUpdate()

    if GBB.FilterDungeon(dungeon, isHeroic, isRaid) and dungeon ~= "TRADE" and dungeon ~= "MISC" and GBB.FoldedDungeons[dungeon] ~= true then
      local dungeonTXT = GBB.dungeonNames[dungeon]
      if dungeonTXT ~= "" and GBB.AllowInInstance() then
        if GBB.DB.NotifyChat then
          local linkname = "|Hplayer:" .. name .. "|h[" .. name .. "]|h"
          if GBB.DB.OneLineNotification then
            DEFAULT_CHAT_FRAME:AddMessage(GBB.MSGPREFIX .. linkname .. ": " .. msg,
              GBB.DB.NotifyColor.r, GBB.DB.NotifyColor.g, GBB.DB.NotifyColor.b)
          else
            DEFAULT_CHAT_FRAME:AddMessage(
              GBB.MSGPREFIX .. string.format(GBB.L["msgNewRequest"], linkname, dungeonTXT),
              GBB.DB.NotifyColor.r * 0.8, GBB.DB.NotifyColor.g * 0.8, GBB.DB.NotifyColor.b * 0.8)
            DEFAULT_CHAT_FRAME:AddMessage(GBB.MSGPREFIX .. msg,
              GBB.DB.NotifyColor.r, GBB.DB.NotifyColor.g, GBB.DB.NotifyColor.b)
          end
        end
        if GBB.DB.NotifySound then
          PlaySound(GBB.NotifySound)
        end
      end
    end
    break
  end
end

function GBB.UnfoldAllDungeon()
  wipe(GBB.FoldedDungeons)
  GBB.DoUpdateList()
end

function GBB.FoldAllDungeon()
  for i = 1, GBB.NUM_DUNGEONS do
    GBB.FoldedDungeons[GBB.dungeonSort[i]] = true
  end
  GBB.DoUpdateList()
end

local function createMenu(DungeonID, req)
  if not GBB.PopupDynamic:Wipe("request" .. (DungeonID or "nil") .. (req and "request" or "nil")) then
    return
  end
  if req then
    GBB.PopupDynamic:AddItem(string.format(GBB.L["BtnWho"], req.name), false, WhoRequest, req.name)
    GBB.PopupDynamic:AddItem(string.format(GBB.L["BtnWhisper"], req.name), false, WhisperRequest, req.name)
    GBB.PopupDynamic:AddItem(string.format(GBB.L["BtnInvite"], req.name), false, InviteRequest, req.name)
    GBB.PopupDynamic:AddItem(string.format(GBB.L["BtnIgnore"], req.name), false, IgnoreRequest, req.name)
  end
  if DungeonID then
    GBB.PopupDynamic:AddItem(GBB.L["BtnFold"], false, GBB.FoldedDungeons, DungeonID)
    GBB.PopupDynamic:AddItem(GBB.L["BtnFoldAll"], false, GBB.FoldAllDungeon)
    GBB.PopupDynamic:AddItem(GBB.L["BtnUnFoldAll"], false, GBB.UnfoldAllDungeon)
  end

  local function refreshList()
    GBB.DoUpdateList()
  end

  GBB.PopupDynamic:AddItem(GBB.L["CboxShowTotalTime"], false, GBB.DB, "ShowTotalTime", nil, refreshList)
  GBB.PopupDynamic:AddItem(GBB.L["CboxOrderNewTop"], false, GBB.DB, "OrderNewTop", nil, refreshList)
  GBB.PopupDynamic:AddItem(GBB.L["CboxEnableShowOnly"], false, GBB.DB, "EnableShowOnly", nil, refreshList)
  GBB.PopupDynamic:AddItem(GBB.L["CboxChatStyle"], false, GBB.DB, "ChatStyle", nil, refreshList)
  GBB.PopupDynamic:AddItem(GBB.L["CboxCompactStyle"], false, GBB.DB, "CompactStyle", nil, refreshList)
  GBB.PopupDynamic:AddItem(GBB.L["CboxDonttruncate"], false, GBB.DB, "Donttruncate", nil, refreshList)
  GBB.PopupDynamic:AddItem(GBB.L["CboxNotifySound"], false, GBB.DB, "NotifySound", nil, refreshList)
  GBB.PopupDynamic:AddItem(GBB.L["CboxNotifyChat"], false, GBB.DB, "NotifyChat", nil, refreshList)
  GBB.PopupDynamic:AddItem(GBB.L["HeaderSettings"], false, GBB.Options.Open, 1)

  if has_wotlk then
    GBB.PopupDynamic:AddItem(GBB.L["WotlkPanelFilter"], false, GBB.Options.Open, 2)
  else
    GBB.PopupDynamic:AddItem(GBB.L["TBCPanelFilter"], false, GBB.Options.Open, 2)
  end

  GBB.PopupDynamic:AddItem(GBB.L["PanelAbout"], false, GBB.Options.Open, 6)
  GBB.PopupDynamic:AddItem(GBB.L["BtnCancel"], false)
  GBB.PopupDynamic:Show()
end

function GBB.ClickFrame(self, button)
  if button == "LeftButton" then
  else
    createMenu()
  end
end

function GBB.ClickDungeon(self, button)
  local id = string.match(self:GetName(), "GBB.Dungeon_(.+)")
  if id == nil or id == 0 then return end

  if button == "LeftButton" then
    if GBB.FoldedDungeons[id] then
      GBB.FoldedDungeons[id] = false
    else
      GBB.FoldedDungeons[id] = true
    end
    GBB.DoUpdateList()
  else
    createMenu(id)
  end
end

local function WhoRequest(name)
  SendWho(name)
end

local function WhisperRequest(name)
  ChatFrame_OpenChat("/w " .. name .. " ")
end

local function InviteRequest(name)
  InviteUnit(name)
end

function GBB.ClickRequest(self, button)
  local id = string.match(self:GetName(), "GBB.Item_(.+)")
  if id == nil or id == 0 then return end

  local req = GBB.RequestList[tonumber(id)]
  if not req then return end
  if button == "LeftButton" then
    if IsShiftKeyDown() then
      WhoRequest(req.name)
    elseif IsControlKeyDown() then
      InviteRequest(req.name)
    elseif IsAltKeyDown() then
      local msg = GBB.BuildInvWhisper(req.dungeon)
      SendChatMessage(msg, "WHISPER", nil, req.name)
      GBB.pretty_print(string.format("Template sent to %s: %s", req.name, msg))
    else
      WhisperRequest(req.name)
    end
  else
    createMenu(nil, req)
  end
end

FindLinkAtCursor = function(message, cursorX)
  local text = message:GetText()
  if not text then return nil end
  local left = message:GetLeft()
  if not left then return nil end

  local links = {}
  for link in text:gmatch("(|H.-|h%[.-%]|h)") do
    table.insert(links, link)
  end
  if #links == 0 then return nil end

  local relX = cursorX - left
  local font, size = message:GetFont()
  if not font then return nil end

  if not GBB_MeasureFS then
    GBB_MeasureFS = UIParent:CreateFontString(nil, "ARTWORK")
  end
  GBB_MeasureFS:SetFont(font, size or 12, "")

  local function stripCodes(s)
    s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
    s = s:gsub("|r", "")
    s = s:gsub("|T[^|]+|t", "")
    s = s:gsub("|H[^|]+|h(%b[])|h", function(cap) return cap:sub(2, -2) end)
    return s
  end

  local stripped = stripCodes(text)
  local pos = 1

  for _, link in ipairs(links) do
    local display = link:match("|h%[(.-)%]|h") or ""
    local linkPos = stripped:find(display, pos, true)
    if linkPos then
      GBB_MeasureFS:SetText(stripped:sub(1, linkPos - 1))
      local startX = GBB_MeasureFS:GetStringWidth()
      GBB_MeasureFS:SetText(stripped:sub(1, linkPos - 1 + #display))
      local endX = GBB_MeasureFS:GetStringWidth()
      if relX >= startX and relX <= endX then
        GBB_MeasureFS:SetText("")
        return link
      end
      pos = linkPos + #display
    end
  end

  GBB_MeasureFS:SetText("")
  return nil
end

local function ShowMessageTooltip(self, req)
  GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(req.message, 0.9, 0.9, 0.9, true)
  if GBB.DB.ChatStyle then
    GameTooltip:AddLine(string.format(GBB.L["msgLastTime"], GBB.formatTime(time() - req.last)) ..
      "|n" .. string.format(GBB.L["msgTotalTime"], GBB.formatTime(time() - req.start)))
  elseif GBB.DB.ShowTotalTime then
    GameTooltip:AddLine(string.format(GBB.L["msgLastTime"], GBB.formatTime(time() - req.last)))
  else
    GameTooltip:AddLine(string.format(GBB.L["msgTotalTime"], GBB.formatTime(time() - req.start)))
  end
  if GBB.DB.EnableGroup and GBB.GroupTrans and GBB.GroupTrans[req.name] then
    local entry = GBB.GroupTrans[req.name]
    GameTooltip:AddLine(GBB.Tool.IconClass[entry.class] ..
      "|c" .. RAID_CLASS_COLORS_HEX[entry.class] .. entry.name)
    if entry.dungeon then GameTooltip:AddLine(entry.dungeon) end
    if entry.Note then GameTooltip:AddLine(entry.Note) end
    GameTooltip:AddLine(SecondsToTime(GetServerTime() - entry.lastSeen))
  end
  if LogTracker then LogTracker:AddPlayerInfoToTooltip(req.name) end
  GameTooltip:Show()
end

local function UpdateTooltipForFrame(self)
  local id = self:GetName():match("GBB.Item_(.+)")
  if not id then return end
  local req = GBB.RequestList[tonumber(id)]
  if not req then return end

  local message = _G[self:GetName() .. "_message"]
  if message then
    local text = message:GetText()
    if text then
      local cx, cy = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      if cx and cy and scale and scale > 0 then
        cx = cx / scale
        cy = cy / scale
        local left = message:GetLeft()
        local top = message:GetTop()
        local width = message:GetWidth()
        local height = message:GetStringHeight()
        if left and top and width and height then
          if cx >= left and cx <= left + width and cy >= top - height and cy <= top then
            local link = FindLinkAtCursor(message, cx)
            if link then
              local linkType = link:match("|H([^:|]+)")
              if linkType == "trade" then
                GameTooltip:Hide()
                return
              end
              if self._gbb_lastLink ~= link then
                self._gbb_lastLink = link
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:ClearLines()
                local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
                if ok then
                  GameTooltip:Show()
                else
                  self._gbb_lastLink = nil
                  ShowMessageTooltip(self, req)
                end
              end
              return
            end
          end
        end
      end
    end
  end

  if self._gbb_lastLink ~= nil then
    self._gbb_lastLink = nil
    ShowMessageTooltip(self, req)
  end
end

function GBB.RequestShowTooltip(self)
  self._gbb_lastLink = nil
  self:SetScript("OnUpdate", UpdateTooltipForFrame)
  UpdateTooltipForFrame(self)
end

function GBB.RequestHideTooltip(self)
  self:SetScript("OnUpdate", nil)
  self._gbb_lastLink = nil
  GameTooltip:Hide()
end
