Layover = Layover or {}
local UI = {}
Layover.UI = UI

local MAX_ROWS = 14
local MAX_SUGGEST = 7

local function backdrop(frame)
  local tpl = _G.BackdropTemplateMixin and "BackdropTemplate" or nil
  if tpl and not frame.SetBackdrop then
    -- Frame already created with the mixin when possible.
  end
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.05, 0.07, 0.10, 0.92)
    frame:SetBackdropBorderColor(0.35, 0.55, 0.75, 0.9)
  end
end

local function create(frameType, name, parent, template)
  if template then
    local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
    if ok and frame then
      return frame
    end
  end
  return CreateFrame(frameType, name, parent)
end

local function makeButton(parent, name, w, h, text)
  local b = create("Button", name, parent, "UIPanelButtonTemplate")
  b:SetWidth(w)
  b:SetHeight(h)
  if b.SetText then
    b:SetText(text)
  end
  return b
end

function UI.init()
  if UI.frame or not CreateFrame then
    return
  end
  local template = _G.BackdropTemplateMixin and "BackdropTemplate" or nil
  local f = create("Frame", "LayoverFrame", UIParent, template)
  f:SetWidth(360)
  f:SetHeight(430)
  f:SetFrameStrata("MEDIUM")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self)
    if not UI.locked then
      self:StartMoving()
    end
  end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    Layover.Saved.setUIPoint(point, x, y)
  end)
  backdrop(f)

  local saved = Layover.Saved.getUI()
  if saved.point and saved.x then
    f:SetPoint(saved.point, UIParent, saved.point, saved.x, saved.y)
  else
    f:SetPoint("RIGHT", UIParent, "RIGHT", -40, 40)
  end

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -12)
  title:SetText("Layover")

  local eta = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  eta:SetPoint("TOPRIGHT", -36, -14)
  eta:SetText("")
  UI.etaText = eta

  local close = create("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)
  close:SetScript("OnClick", function()
    f:Hide()
  end)

  local dest = create("EditBox", "LayoverDestBox", f, "InputBoxTemplate")
  dest:SetAutoFocus(false)
  dest:SetWidth(250)
  dest:SetHeight(20)
  dest:SetPoint("TOPLEFT", 18, -38)
  dest:SetMaxLetters(60)
  dest:SetScript("OnEnterPressed", function(self)
    local text = self:GetText()
    UI.hideSuggestions()
    if text and text ~= "" then
      Layover.command(text)
    end
    self:ClearFocus()
  end)
  dest:SetScript("OnTextChanged", function(self, user)
    if user then
      UI.updateSuggestions(self:GetText())
    end
  end)
  dest:SetScript("OnEscapePressed", function(self)
    UI.hideSuggestions()
    self:ClearFocus()
  end)
  UI.destBox = dest

  local go = makeButton(f, "LayoverGoButton", 52, 22, "Go")
  go:SetPoint("LEFT", dest, "RIGHT", 8, 0)
  go:SetScript("OnClick", function()
    local text = dest:GetText()
    UI.hideSuggestions()
    if text and text ~= "" then
      Layover.command(text)
    end
  end)

  local destLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  destLabel:SetPoint("TOPLEFT", dest, "BOTTOMLEFT", -2, -4)
  destLabel:SetText("Destination")
  UI.destLabel = destLabel

  local suggest = create("Frame", "LayoverSuggestFrame", f, template)
  suggest:SetWidth(250)
  suggest:SetHeight(18 * MAX_SUGGEST + 8)
  suggest:SetPoint("TOPLEFT", dest, "BOTTOMLEFT", -6, -2)
  suggest:SetFrameStrata("HIGH")
  backdrop(suggest)
  suggest:Hide()
  UI.suggestFrame = suggest
  UI.suggestButtons = {}
  for i = 1, MAX_SUGGEST do
    local b = CreateFrame("Button", nil, suggest)
    b:SetWidth(238)
    b:SetHeight(18)
    b:SetPoint("TOPLEFT", 6, -4 - (i - 1) * 18)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", 2, 0)
    b:SetScript("OnClick", function(self)
      if self.nodeId then
        UI.hideSuggestions()
        dest:SetText(self.nodeName or "")
        dest:ClearFocus()
        Layover.routeTo({ nodeId = self.nodeId, name = self.nodeName }, "search")
      end
    end)
    UI.suggestButtons[i] = b
  end

  local skip = makeButton(f, "LayoverSkipButton", 70, 22, "Skip")
  skip:SetPoint("TOPLEFT", 14, -84)
  skip:SetScript("OnClick", function()
    Layover.skipStep()
  end)

  local clear = makeButton(f, "LayoverClearButton", 70, 22, "Clear")
  clear:SetPoint("LEFT", skip, "RIGHT", 6, 0)
  clear:SetScript("OnClick", function()
    Layover.clearRoute()
  end)

  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("LEFT", clear, "RIGHT", 10, 0)
  hint:SetText("/lo  /layover")
  UI.hint = hint

  UI.rows = {}
  for i = 1, MAX_ROWS do
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", 16, -114 - (i - 1) * 18)
    fs:SetPoint("RIGHT", -16, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText("")
    UI.rows[i] = fs
  end

  local note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  note:SetPoint("BOTTOMLEFT", 16, 14)
  note:SetPoint("BOTTOMRIGHT", -16, 14)
  note:SetJustifyH("LEFT")
  note:SetText("")
  UI.note = note

  f:Hide()
  UI.frame = f
  UI.locked = false
end

function UI.show()
  if not UI.frame then
    UI.init()
  end
  if UI.frame then
    UI.frame:Show()
    UI.refresh()
  end
end

function UI.hide()
  if UI.frame then
    UI.frame:Hide()
  end
end

function UI.toggle()
  if not UI.frame then
    UI.init()
  end
  if UI.frame:IsShown() then
    UI.frame:Hide()
  else
    UI.show()
  end
end

function UI.hideSuggestions()
  if UI.suggestFrame then
    UI.suggestFrame:Hide()
  end
end

function UI.updateSuggestions(text)
  if not UI.suggestFrame then
    return
  end
  local snap = Layover.Adapter.getSnapshot()
  local results = Layover.Destinations.search(text, snap.faction, MAX_SUGGEST)
  if not results or #results == 0 then
    UI.suggestFrame:Hide()
    return
  end
  for i = 1, MAX_SUGGEST do
    local b = UI.suggestButtons[i]
    local r = results[i]
    if r then
      b:Show()
      b.nodeId = r.node.id
      b.nodeName = r.node.name
      local extra = ""
      if r.node.kind == "dungeon" or r.node.kind == "raid" then
        extra = "  |cffaaaaaa" .. r.node.kind .. "|r"
      end
      b.text:SetText(r.node.name .. extra)
    else
      b:Hide()
      b.nodeId = nil
    end
  end
  UI.suggestFrame:SetHeight(18 * math.min(MAX_SUGGEST, #results) + 8)
  UI.suggestFrame:Show()
end

local STATUS_COLOR = {
  done = { 0.55, 0.55, 0.55 },
  skipped = { 0.55, 0.55, 0.55 },
  current = { 1.0, 0.82, 0.0 },
  pending = { 0.92, 0.92, 0.92 },
}

function UI.refresh()
  if not UI.frame then
    return
  end
  local state = Layover.state
  if not state or not state.ok then
    UI.etaText:SetText("")
    UI.destLabel:SetText("Destination")
    UI.note:SetText("Place a map pin, or type /lo <destination>.")
    for i = 1, MAX_ROWS do
      UI.rows[i]:SetText("")
    end
    return
  end
  local destName = state.to and state.to.name or "Destination"
  UI.destLabel:SetText(destName)
  if UI.destBox and destName and destName ~= "Map pin" then
    UI.destBox:SetText(destName)
  end
  if state.complete then
    UI.etaText:SetText("Arrived")
  else
    UI.etaText:SetText((state.remainingEta or state.eta or "") .. " left")
  end
  local rows = Layover.Steps.checklist(state)
  for i = 1, MAX_ROWS do
    local fs = UI.rows[i]
    local row = rows[i]
    if row then
      local mark = "[ ]"
      if row.status == "done" then
        mark = "[x]"
      elseif row.status == "skipped" then
        mark = "[-]"
      elseif row.status == "current" then
        mark = " > "
      end
      fs:SetText(string.format("%s %d. %s  (~%s)", mark, row.index, row.label, row.eta))
      local c = STATUS_COLOR[row.status] or STATUS_COLOR.pending
      fs:SetTextColor(c[1], c[2], c[3])
    else
      fs:SetText("")
    end
  end
  if state.suggestion then
    UI.note:SetText("Tip: " .. state.suggestion.text)
  elseif state.complete then
    UI.note:SetText("You have arrived.")
  else
    UI.note:SetText("")
  end
end

function UI.notify(msg)
  if Layover.Adapter and Layover.Adapter.print then
    Layover.Adapter.print(msg)
  end
end
