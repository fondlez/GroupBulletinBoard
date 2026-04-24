local _, GBB = GroupBulletinBoard_Loader.Main()
local M = {}

GBB.InterfaceOptionsFrame = M

local function get_main_frame()
  return InterfaceOptionsFrame
end

local function get_categories_frame()
  return InterfaceOptionsFrameCategories
end

local function get_addons_frame()
  return InterfaceOptionsFrameAddOns
end

function M.Enlarge()
  local main_frame = get_main_frame()
  local addons_frame = get_addons_frame()
  local categories_frame = get_categories_frame()

  M.main_width = main_frame:GetWidth()
  M.main_height = main_frame:GetHeight()
  M.addons_height = addons_frame:GetHeight()
  M.categories_height = categories_frame:GetHeight()

  main_frame:SetWidth( 900 )
  main_frame:SetHeight( 680 )
  addons_frame:SetHeight( 590 )
  categories_frame:SetHeight( 590 )
end

function M.RevertSize()
  local main_frame = get_main_frame()
  local addons_frame = get_addons_frame()
  local categories_frame = get_categories_frame()

  if M.main_width then main_frame:SetWidth( M.main_width ) end
  if M.main_height then main_frame:SetHeight( M.main_height ) end
  if M.addons_height then addons_frame:SetHeight( M.addons_height ) end
  if M.categories_height then categories_frame:SetHeight( M.categories_height ) end
end

function M.Sink()
  local frame = get_main_frame()

  if M.main_strata then frame:SetFrameStrata( M.main_strata ) end
end

function M.Rise()
  local frame = get_main_frame()

  M.main_strata = frame:GetFrameStrata()
  frame:SetFrameStrata( "DIALOG" )
end

