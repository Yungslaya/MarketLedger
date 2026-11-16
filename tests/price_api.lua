-- Run from repository root: texlua tests/price_api.lua
-- Loads the real Market Ledger files with mocked WoW services. Checks MarketLedger:PriceForItem and
-- that the real Scan Bags and Clear Prices actions tell ProfessionPal to redraw.
unpack = unpack or table.unpack
table.maxn = table.maxn or function(t) local n = 0; for k in pairs(t) do if type(k) == "number" and k > n then n = k end end; return n end
local frames, registered = {}, {}
local function widget(parent)
       local w = { parent = parent, shown = true, scripts = {}, enabled = true }
       local m = {
           SetScript = function(s, k, f) s.scripts[k] = f end, GetScript = function(s, k) return s.scripts[k] end,
           HookScript = function(s, k, f) s.scripts[k] = f end,
           RegisterEvent = function(s, e) registered[e] = registered[e] or {}; table.insert(registered[e], s) end,
           IsShown = function(s) return s.shown end, IsVisible = function(s) return s.shown end,
           Show = function(s) s.shown = true; if s.scripts.OnShow then s.scripts.OnShow(s) end end,
           Hide = function(s) s.shown = false end, SetShown = function(s, v) s.shown = v and true or false end,
           SetText = function(s, v) s.text = v end, GetText = function(s) return s.text end,
           IsEnabled = function(s) return s.enabled end, Enable = function(s) s.enabled = true end,
           Disable = function(s) s.enabled = false end, SetEnabled = function(s, v) s.enabled = v end,
          GetWidth = function() return 800 end, GetHeight = function() return 600 end,
          GetScale = function() return 1 end, GetEffectiveScale = function() return 1 end,
          GetFrameLevel = function() return 1 end, GetNumPoints = function() return 0 end,
          GetVerticalScroll = function() return 0 end, GetVerticalScrollRange = function() return 0 end,
          GetStringWidth = function() return 50 end, GetStringHeight = function() return 14 end,
          GetLeft = function() return 0 end, GetTop = function() return 0 end,
          CreateFontString = function(s) return widget(s) end, CreateTexture = function(s) return widget(s) end,
          CreateLine = function(s) return widget(s) end, CreateAnimationGroup = function(s) return widget(s) end,
          CreateAnimation = function(s) return widget(s) end, GetFontString = function(s) return widget(s) end,
      }
      return setmetatable(w, { __index = function(_, k) return m[k] or (type(k) == "string" and k:match("^%u") and function() end) or nil end })
end
function CreateFrame(_, name, parent) local w = widget(parent); w.name = name; frames[#frames + 1] = w; if name then _G[name] = w end; return w end
local function fire(event, ...) for _, f in ipairs(registered[event] or {}) do if f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end end end
local function button(label) for _, f in ipairs(frames) do if f.text == label and f.scripts.OnClick then return f end end end

UIParent = widget(); GameTooltip = widget(); UISpecialFrames = {}
local realm, faction = "Forever", "Alliance"
GetRealmName = function() return realm end
UnitFactionGroup = function() return faction end
UnitName = function() return "Tester" end
UnitLevel = function() return 60 end
GetLocale = function() return "enUS" end
GetTime = function() return 100 end
time = function() return 1700000000 end
date = os.date
InCombatLockdown = function() return false end
IsShiftKeyDown = function() return false end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
hooksecurefunc = function() end
SlashCmdList = {}
NUM_BAG_SLOTS, BACKPACK_CONTAINER, BANK_CONTAINER = 4, 0, -1
Enum = { PlayerInteractionType = { Auctioneer = 21, Merchant = 5 }, ItemQuality = {} }
local timers = {}
C_Timer = { After = function(delay, fn) timers[#timers + 1] = { delay = delay, fn = fn } end,
                    NewTicker = function() return { Cancel = function() end } end,
                    NewTimer = function() return { Cancel = function() end } end }
local function runZeroTimers()
      local again = true
      while again do
             again = false
             for i, t in ipairs(timers) do
                    if t.delay == 0 then table.remove(timers, i); t.fn(); again = true; break end
             end
      end
end
local ahOpen = true
C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function() return ahOpen end }
C_AddOns = { GetAddOnMetadata = function() return "1.3.7" end }
C_ChatInfo = { RegisterAddonMessagePrefix = function() end }
ItemLocation = { CreateFromBagAndSlot = function() return {} end }
C_Item = { CanBeAuctioned = function() return true end, GetItemInfo = function(link) return "Copper Ore", nil, 1, 1, 1, "Trade Goods", "", 20, "", "", 5 end,
                   GetItemCount = function() return 0 end }
C_Container = {
      GetContainerNumSlots = function(bag) return bag == 0 and 1 or 0 end,
      GetContainerItemInfo = function(bag, slot)
             if bag == 0 and slot == 1 then
                    return { hyperlink = "|cffffffff|Hitem:2770::::::::60:::::|h[Copper Ore]|h|r", itemID = 2770, stackCount = 20, isBound = false }
             end
      end,
      GetContainerItemQuestInfo = function() return {} end,
}
local function key(id, level) return { itemID = id, itemLevel = level or 0, itemSuffix = 0, battlePetSpeciesID = 0 } end
local searchSent = 0
C_AuctionHouse = {
      MakeItemKey = function(id) return key(id) end,
      GetItemKeyFromItemLink = function() return key(2770) end,
      SendSearchQuery = function() searchSent = searchSent + 1; return true end,
      IsThrottledMessageSystemReady = function() return true end,
      GetNumCommoditySearchResults = function() return 1 end,
      GetCommoditySearchResultInfo = function() return { unitPrice = 1250 } end,
}

-- ProfessionPal stand-in: records redraw requests.
local redraws = 0
_G.ProfessionPal = { OnMarketLedgerPrices = function(self) assert(self == _G.ProfessionPal); redraws = redraws + 1 end }
local ML = {}
for _, file in ipairs({ "Core.lua", "History.lua", "LedgerPlan.lua", "Ledger.lua", "Notices.lua" }) do
      local chunk = assert(loadfile("MarketLedger/" .. file))
      local ok, err = pcall(chunk, "MarketLedger", ML)
      assert(ok, file .. " failed to load under mocks: " .. tostring(err))
end
assert(ML.Pal == _G.ProfessionPal and _G.MarketLedger == ML)
MarketLedgerDB = {}
fire("PLAYER_LOGIN")
assert(ML.db == MarketLedgerDB)

local function deep(v)
      if type(v) ~= "table" then return type(v) .. ":" .. tostring(v) end
      local e = {}; for k, x in pairs(v) do e[#e + 1] = tostring(k) .. "=" .. deep(x) end
      table.sort(e); return "{" .. table.concat(e, ",") .. "}"
end
local function none(...) local a, b = ... ; return select("#", ...) == 2 and a == nil and b == nil end

-- 1. empty database: nothing found, nothing created
local before = deep(ML.db)
assert(none(ML:PriceForItem(2770)))
assert(deep(ML.db) == before, "lookups must not create saved tables")

-- 2. invalid item IDs
for _, bad in ipairs({ "2770", -1, 0, 1.5, 0/0, math.huge, -math.huge, false, {} }) do assert(none(ML:PriceForItem(bad))) end

-- 3. pre-1.3.7 price without a time: unavailable until rescanned
ML.db.ledgerPrices = { ["Forever:Alliance"] = { ["2770:0:0:0"] = 1250 } }
assert(none(ML:PriceForItem(2770)))
ML.db.ledgerPriceAt = { ["Forever:Alliance"] = {} }

-- 4. valid
ML.db.ledgerPriceAt["Forever:Alliance"]["2770:0:0:0"] = 1699990000
local c, t = ML:PriceForItem(2770); assert(c == 1250 and t == 1699990000)

-- 5. unseen faction and realm: nothing, and nothing created
before = deep(ML.db)
faction = "Horde"; assert(none(ML:PriceForItem(2770))); faction = "Alliance"
realm = "Other"; assert(none(ML:PriceForItem(2770))); realm = "Forever"
assert(deep(ML.db) == before)

-- 6. exact key resolves but has no price: never borrow another version's price
local P, T = ML.db.ledgerPrices["Forever:Alliance"], ML.db.ledgerPriceAt["Forever:Alliance"]
P["2771:0:0:0"], T["2771:0:0:0"] = nil, nil
P["2771:5:0:0"], T["2771:5:0:0"] = 900, 1699990000
assert(none(ML:PriceForItem(2771)), "exact key without a price must not fall back")

-- 7. no usable item key: one plain entry is accepted, several are ambiguous, odd keys are ignored
C_AuctionHouse.MakeItemKey = function() return nil end
c = ML:PriceForItem(2771); assert(c == 900, "fallback when WoW gives no item key")
P["2771:7:0:0"], T["2771:7:0:0"] = 950, 1699990000
assert(none(ML:PriceForItem(2771)), "two levels saved = ambiguous")
P["27710:0:0:0"], T["27710:0:0:0"] = 1, 1699990000           -- different item that shares a prefix
P["2772:0:3:0"], T["2772:0:3:0"] = 5, 1699990000             -- suffixed version is not plain
P[42] = 7                                                      -- malformed key
assert(none(ML:PriceForItem(2772)))
C_AuctionHouse.MakeItemKey = function() return "not a table" end
assert(none(ML:PriceForItem(2771)))
C_AuctionHouse.MakeItemKey = function(id) return key(id) end

-- 8. malformed saved values
for _, pair in ipairs({ { 0/0, 1 }, { math.huge, 1 }, { 0.4, 1 }, { -3, 1 }, { "12", 1 }, { 12, 0/0 }, { 12, math.huge }, { 12, -1 }, { 12, "x" } }) do
       P["2773:0:0:0"], T["2773:0:0:0"] = pair[1], pair[2]
       assert(none(ML:PriceForItem(2773)), "bad saved value " .. tostring(pair[1]) .. "/" .. tostring(pair[2]))
end
P["2773:0:0:0"], T["2773:0:0:0"] = 12.9, 1699990000
c = ML:PriceForItem(2773); assert(c == 12, "fractional copper rounds down")
P["2773:0:0:0"], T["2773:0:0:0"] = nil, nil

-- 9. blacklisted items keep their informational price
ML.db.ledgerBlacklist = { [2770] = true }
assert(ML:PriceForItem(2770) == 1250)
ML.db.ledgerBlacklist = {}

-- 10. read-only across every kind of lookup
before = deep(ML.db)
for _, id in ipairs({ 2770, 2771, 2772, 2773, 9999 }) do ML:PriceForItem(id) end
assert(deep(ML.db) == before)

-- 11. the real Scan Bags button: records price + time, finishes, tells ProfessionPal once
P["2770:0:0:0"], T["2770:0:0:0"] = nil, nil
ML:Toggle()
local scanButton = assert(button("Scan Bags"), "Scan Bags button")
redraws = 0
scanButton.scripts.OnClick(scanButton)
assert(searchSent == 1, "one search for the one bag item")
fire("COMMODITY_SEARCH_RESULTS_UPDATED", 2770)
runZeroTimers()
c, t = ML:PriceForItem(2770)
assert(c == 1250 and t == 1700000000, "scanned price and its real time")
assert(redraws == 1, "scan completion tells ProfessionPal")
-- an unanswered item keeps its older time
P["2774:0:0:0"], T["2774:0:0:0"] = 300, 1600000000
assert(select(2, ML:PriceForItem(2774)) == 1600000000)

-- 12. the real Clear Prices button tells ProfessionPal too
redraws = 0
local clear = assert(button("Clear Prices"), "Clear Prices button")
clear.scripts.OnClick(clear)
assert(redraws == 1 and none(ML:PriceForItem(2770)), "clearing prices tells ProfessionPal")

-- 13. a failing ProfessionPal never breaks Market Ledger
_G.ProfessionPal.OnMarketLedgerPrices = function() error("boom") end
clear.scripts.OnClick(clear)

print("PASS: PriceForItem (empty DB, invalid IDs, old saves, faction/realm, exact key without price, fallback/ambiguous/malformed keys, NaN/inf/sub-copper values, blacklist, read-only) and real Scan Bags / Clear Prices notifications")
