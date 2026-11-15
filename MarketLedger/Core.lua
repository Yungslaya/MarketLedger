--[[ Market Ledger - base
  Everything the ledger needs to run on its own: saved settings, a small window kit, and the
  links to other addons. None of those addons is required.

    ProfessionPal (optional)  - holds back materials your profession guide needs, offers crafts,
                                gives the Farm tab its picks and Map buttons, and shares its theme.
    TradeSkillMaster (optional) and Shortest Path Forever (optional) are reached from Ledger.lua
    and through ProfessionPal's map guide.

  Market Ledger began as a part of ProfessionPal. Saved prices, plans and settings are copied
  over from ProfessionPal the first time this addon loads.
]]

local _, ML = ...
_G.MarketLedger = ML

local Pal = _G.ProfessionPal   -- loads first when installed (OptionalDeps)
ML.Pal = Pal

-- ---------- small helpers ----------

local function safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local results = { pcall(fn, ...) }
    if results[1] then return unpack(results, 2, table.maxn(results)) end
    return nil
end
ML.safe = safe

local function isNumber(value)
    if type(value) ~= "number" then return false end
    if issecretvalue and safe(issecretvalue, value) then return false end
    return true
end

function ML:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Market Ledger:|r " .. tostring(message))
    end
end

function ML:InCombat() return safe(InCombatLockdown) and true or false end

function ML:PlayerLevel()
    local level = safe(UnitLevel, "player")
    return isNumber(level) and level or 1
end

-- How many of an item you hold. bagsOnly = leave the bank out.
function ML:Count(item, bagsOnly)
    if item == nil then return 0 end
    local count
    if C_Item and C_Item.GetItemCount then
        count = safe(C_Item.GetItemCount, item, not bagsOnly, false, false, not bagsOnly)
        if count == nil then count = safe(C_Item.GetItemCount, item, not bagsOnly) end
    end
    if count == nil and GetItemCount then count = safe(GetItemCount, item, not bagsOnly) end
    return isNumber(count) and count or 0
end

-- ---------- look ----------
-- With ProfessionPal installed, its colours, fonts and window kit are used as they are, so both
-- addons always match (themes included). Without it, the same look is built here.

if Pal and Pal.UIWindow and Pal.UIButton and Pal.UIText and Pal.Skin then
    ML.C, ML.THEME, ML.Skin = Pal.C, Pal.THEME, Pal.Skin
    ML.UIText, ML.UIButton, ML.UIWindow = Pal.UIText, Pal.UIButton, Pal.UIWindow
    -- ProfessionPal sets its font when its theme loads, so read it at the time of use.
    setmetatable(ML, { __index = function(_, key)
        if key == "FONT" or key == "TITLE_FONT" then return Pal[key] end
    end })
else
    ML.FONT, ML.TITLE_FONT = "Fonts\\ARIALN.TTF", "Fonts\\FRIZQT__.TTF"
    ML.C = {
        gold = { 0.94, 0.78, 0.47 }, white = { 0.93, 0.94, 0.96 }, green = { 0.45, 0.87, 0.60 },
        red = { 1.00, 0.25, 0.25 }, orange = { 1.00, 0.55, 0.15 }, gray = { 0.69, 0.74, 0.81 },
        yellow = { 1.00, 0.86, 0.25 },
    }
    ML.THEME = {
        bg = { 0.083, 0.063, 0.045, 0.97 }, band = { 0.148, 0.109, 0.073, 1 },
        border = { 0.382, 0.286, 0.161, 1 }, inset = { 0.120, 0.093, 0.064, 0.96 },
        btn = { 0.157, 0.116, 0.077, 1 }, btnHover = { 0.235, 0.175, 0.104, 1 },
        btnSel = { 0.170, 0.151, 0.102, 1 }, btnBorder = { 0.390, 0.288, 0.157, 1 },
        selBorder = { 0.750, 0.600, 0.330, 1 },
    }
    local WHITE = "Interface\\Buttons\\WHITE8X8"
    local C, T = ML.C, ML.THEME

    -- Dark panel with a thin border. bandHeight adds the lighter header strip.
    function ML.Skin(frame, bandHeight, colors)
        colors = colors or {}
        if frame.SetBackdrop then
            frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 } })
            frame:SetBackdropColor(unpack(colors.bg or T.bg))
            frame:SetBackdropBorderColor(unpack(colors.border or T.border))
        end
        if bandHeight and not frame.band then
            local band = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
            band:SetTexture(WHITE)
            band:SetVertexColor(unpack(T.band))
            band:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
            band:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
            band:SetHeight(bandHeight)
            frame.band = band
        end
    end

    function ML.UIText(parent, size, color, justify)
        local text = parent:CreateFontString(nil, "OVERLAY")
        size = math.max(14, size)
        text:SetFont(size >= 18 and ML.TITLE_FONT or ML.FONT, size, "")
        text:SetShadowOffset(1, -1)
        text:SetShadowColor(0, 0, 0, 1)
        text:SetTextColor(unpack(color or C.white))
        text:SetJustifyH(justify or "LEFT")
        return text
    end

    function ML.UIButton(parent, label, width, height, onClick)
        local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
        button:SetSize(width, height or 30)
        ML.Skin(button, nil, { bg = T.btn, border = T.btnBorder })
        local text = ML.UIText(button, 15, C.white, "CENTER")
        text:SetPoint("LEFT", button, "LEFT", 4, 0)
        text:SetPoint("RIGHT", button, "RIGHT", -4, 0)
        button:SetFontString(text)
        button:SetText(label)
        button.selected = false
        local function paint(self, hover)
            if not self.SetBackdropColor then return end
            self:SetBackdropColor(unpack(self.selected and T.btnSel or (hover and T.btnHover or T.btn)))
            self:SetBackdropBorderColor(unpack(self.selected and T.selBorder or T.btnBorder))
        end
        button:SetScript("OnEnter", function(self) if self:IsEnabled() then paint(self, true) end end)
        button:SetScript("OnLeave", function(self) paint(self, false) end)
        function button:SetSelected(on) self.selected = on and true or false; paint(self, false) end
        button:SetScript("OnClick", onClick)
        return button
    end

    function ML.UIWindow(name, width, title)
        local window = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
        window:SetSize(width, 300)
        window:SetFrameStrata("MEDIUM")
        window:SetClampedToScreen(true)
        ML.Skin(window, 40)
        window.title = ML.UIText(window, 18, C.gold, "CENTER")
        window.title:SetPoint("TOPLEFT", window, "TOPLEFT", 18, -11)
        window.title:SetText(title)
        local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -2, -2)
        window:EnableMouse(true)
        window:SetMovable(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", function(self) self:StartMoving() end)
        window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        window:Hide()
        if UISpecialFrames then table.insert(UISpecialFrames, name) end
        return window
    end
end

-- ---------- ProfessionPal link ----------
-- Each of these answers "nothing" when ProfessionPal is not installed, so the ledger never has to ask.

ML.professions = Pal and Pal.professions or {}
ML.byKey = Pal and Pal.byKey or {}
ML.ZONE_MAP = Pal and Pal.ZONE_MAP or {}
ML.ZONE_LEVEL = Pal and Pal.ZONE_LEVEL or {}
ML.NODES = Pal and Pal.NODES or {}
ML.FARMABLE = Pal and Pal.FARMABLE or {}

function ML:GetSkill(def) if Pal then return Pal:GetSkill(def) end end
function ML:StepFor(def, skill) if Pal then return Pal:StepFor(def, skill) end end
function ML.CraftsFor(...) return Pal and Pal.CraftsFor(...) or 0 end
function ML:ZoneOptions(def, st) return Pal and Pal:ZoneOptions(def, st) or {} end
function ML:NodeCount(name, map) return Pal and Pal.NodeCount and Pal:NodeCount(name, map) or 0 end
function ML:GearMats(item) if Pal then return Pal:GearMats(item) end end
function ML:MatsReady(item) if Pal then return Pal:MatsReady(item) end end
function ML:CraftGear(item, amount)
    if Pal then return Pal:CraftGear(item, amount) end
    self:Print("Install ProfessionPal to craft from here.")
end

-- Recipes this character knows (name -> recipe ID). ProfessionPal collects them.
function ML.KnownRecipes(character)
    local known = Pal and Pal.db and Pal.db.recipeIDs
    return known and known[character]
end

-- Opens the world map on a zone with the farm spots drawn (ProfessionPal's map guide).
if Pal and Pal.ShowZoneOnMap then
    function ML:ShowZoneOnMap(st, zone) return Pal:ShowZoneOnMap(st, zone) end
end

-- Tools every gatherer and crafter should keep one of, used when ProfessionPal is not there to say.
ML.BASIC_TOOLS = { [2901] = true, [5956] = true, [7005] = true, [6256] = true, [6219] = true }

-- ---------- saved settings ----------

-- Everything Market Ledger kept inside ProfessionPal's saved settings before it became its own addon.
local MOVED = { "auctionTestPercent", "ledgerAdviceExport", "ledgerBlacklist", "ledgerExportScan", "ledgerHeight",
    "ledgerPastedPlan", "ledgerPlanProgress", "ledgerPrices", "ledgerScale", "ledgerScanAt", "ledgerStockPlans",
    "ledgerWidth" }

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, inner in pairs(value) do out[key] = copy(inner) end
    return out
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    if type(MarketLedgerDB) ~= "table" then MarketLedgerDB = {} end
    ML.db = MarketLedgerDB
    local old = _G.ProfessionPalDB
    if not ML.db.movedFromProfessionPal and type(old) == "table" then
        for _, key in ipairs(MOVED) do
            if ML.db[key] == nil and old[key] ~= nil then ML.db[key] = copy(old[key]) end
        end
        ML.db.movedFromProfessionPal = true
    end
end)
