--[[ Market Ledger - price history and market data
  Two answers to "is this a good price, and does it sell?":

  1. Your own history. Every Auction House scan saves one price per item per day (the last 30 days
     you scanned). From that: the average over the last two weeks and how today compares.
     It only knows asking prices, and only items you have scanned.

  2. TradeSkillMaster (optional). When TSM and its desktop app are installed, TSM knows what an item
     really sells for, how often a listing sells, and how many sell per day. Market Ledger asks for
     those numbers through TSM's public addon API (TSM_API). No TSM code is included here.
     The value names below were checked against the TSM build for WoW: Forever (App/API.lua and
     AuctionDBConfig.lua, 2026-11-13). A value TSM has no data for is simply left out.
]]

local _, ML = ...
local floor, max = math.floor, math.max
local now = time or os.time

local DAY = 24 * 60 * 60
local KEEP_POINTS = 30     -- days of history kept per item
local TREND_DAYS = 14      -- "usual price" looks this far back

-- ---------- 1. your own history ----------

local function book()
    ML.db.ledgerHistory = ML.db.ledgerHistory or {}
    local key = ML.Realm() .. ":" .. UnitFactionGroup("player")
    ML.db.ledgerHistory[key] = ML.db.ledgerHistory[key] or {}
    return ML.db.ledgerHistory[key]
end

-- Which day a moment falls on by the player's own clock, as a running day number. (Counting days by
-- the world clock made two scans minutes apart look like two days whenever midnight UTC fell between.)
local date = date or os.date
local function localDay(when)
    local ok, here, utc = pcall(function() return now(date("*t", when)), now(date("!*t", when)) end)
    local shift = ok and type(here) == "number" and type(utc) == "number" and (here - utc) or 0
    if shift < -DAY or shift > DAY then shift = 0 end
    return floor((when + shift) / DAY)
end

-- Saves today's price for an item (signature = the key Market Ledger saves prices under).
-- A second scan on the same day replaces the first.
function ML:RecordPrice(signature, price, when)
    if not (self.db and signature and type(price) == "number" and price > 0) then return end
    local history = book()
    local points = history[signature]
    if not points then
        points = {}
        history[signature] = points
    end
    local day = localDay(when or now())
    local last = points[#points]
    if last and last[1] >= day then
        -- same day (or a point saved under the old world-clock days): keep one point for today
        last[1], last[2] = day, price
        while #points >= 2 and points[#points - 1][1] >= day do table.remove(points, #points - 1) end
    else
        points[#points + 1] = { day, price }
    end
    while #points > KEEP_POINTS do table.remove(points, 1) end
end

-- A listing this many times above the usual price (and at least FAKE_GAP copper above it) is a joke or
-- a typo, like Fish Oil at 100 gold. Nobody buys it, so it is not the item's real price.
local FAKE_TIMES, FAKE_GAP = 10, 5000
local function looksFake(price, usual)
    return type(price) == "number" and type(usual) == "number" and usual > 0
        and price > usual * FAKE_TIMES and price - usual > FAKE_GAP
end

-- The middle value (the lower one of the two middles), so one silly price can't drag it.
local function middle(values)
    if #values == 0 then return nil end
    local sorted = {}
    for i, v in ipairs(values) do sorted[i] = v end
    table.sort(sorted)
    return sorted[floor((#sorted + 1) / 2)]
end

-- Your saved points for an item, without any that were a fake listing next to the rest.
local function realPoints(points)
    local values = {}
    for i, point in ipairs(points) do values[i] = point[2] end
    local mid = middle(values)
    local kept = {}
    for _, point in ipairs(points) do
        if not looksFake(point[2], mid) then kept[#kept + 1] = point end
    end
    return kept
end

-- What the item usually lists for, from your scans before today (nil if you have none).
function ML:UsualPrice(signature, when)
    local points = self.db and self.db.ledgerHistory and signature and book()[signature]
    if not points then return nil end
    local today, values = localDay(when or now()), {}
    for _, point in ipairs(realPoints(points)) do
        if point[1] < today and today - point[1] <= TREND_DAYS then values[#values + 1] = point[2] end
    end
    return middle(values)
end

-- Is this lowest ask a fake listing? Compared with your own usual price and TSM's sale price, whichever
-- is higher, so a real price jump is never thrown away. Returns the price it was compared with.
function ML:FakeAsk(signature, itemID, price, when)
    local usual = self:UsualPrice(signature, when)
    local data = itemID and self:MarketData(itemID)
    local market = data and data.market
    local reference = usual and market and max(usual, market) or usual or market
    if looksFake(price, reference) then return reference end
end

-- { average = usual asking price before today, change = today against it in percent, days = days scanned }
-- nil until an item has been scanned on two different days.
function ML:PriceTrend(signature)
    local points = self.db and self.db.ledgerHistory and signature and book()[signature]
    if points then points = realPoints(points) end
    if not points or #points < 2 then return nil end
    local latest = points[#points]
    local sum, count = 0, 0
    for i = 1, #points - 1 do
        if latest[1] - points[i][1] <= TREND_DAYS then
            sum, count = sum + points[i][2], count + 1
        end
    end
    if count == 0 then return nil end
    local average = floor(sum / count + 0.5)
    return { average = average, change = floor((latest[2] - average) / average * 100 + 0.5), days = count + 1 }
end

-- ---------- 2. TradeSkillMaster (optional) ----------

local function tsm()
    local api = _G.TSM_API
    return type(api) == "table" and type(api.GetCustomPriceValue) == "function" and api or nil
end

function ML:HasMarketData() return tsm() ~= nil end

local function value(api, source, item)
    local ok, result = pcall(api.GetCustomPriceValue, source, item)
    if issecretvalue and issecretvalue(result) then return end
    if ok and type(result) == "number" and result == result and result >= 0 then return result end
end

-- A cached realm listing reference, not a live quote. Preserve random-suffix gear
-- by converting the full link; never substitute its base item ID on conversion failure.
function ML:ListingReference(link)
    local api = tsm()
    if not api or type(api.ToItemString) ~= "function" or type(link) ~= "string" then return end
    local ok, item = pcall(api.ToItemString, link)
    if not ok or (issecretvalue and issecretvalue(item)) or type(item) ~= "string" then return end
    local price = value(api, "DBMinBuyout", item)
    if price and price > 0 then return floor(price), item end
end

-- TradeSkillMaster's saved lowest buyout on this realm for an item ID (copper), or nil.
-- Downloaded by the TSM desktop app, so its age is unknown: never treat it as a live price.
function ML:MinBuyout(itemID)
    local api = tsm()
    if not api or type(itemID) ~= "number" then return end
    local price = value(api, "DBMinBuyout", "i:" .. itemID)
    if price and price > 0 then return floor(price) end
end

-- What TradeSkillMaster says the materials from disenchanting this item are worth (copper),
-- or nil: no TSM, an item that cannot be disenchanted, or no prices for the materials.
-- This is TSM's own estimate from its own tables; Market Ledger adds nothing to it.
function ML:DisenchantValue(link)
    local api = tsm()
    if not api or type(api.ToItemString) ~= "function" or type(link) ~= "string" then return end
    local ok, item = pcall(api.ToItemString, link)
    if not ok or (issecretvalue and issecretvalue(item)) or type(item) ~= "string" then return end
    local worth = value(api, "Destroy", item)
    if worth and worth > 0 then return floor(worth) end
end

-- True when this character has learned Disenchant (spell 13262).
function ML:CanDisenchant()
    local known = false
    if IsPlayerSpell then
        local ok, yes = pcall(IsPlayerSpell, 13262)
        known = ok and not (issecretvalue and issecretvalue(yes)) and yes == true
    end
    if not known and C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, yes = pcall(C_SpellBook.IsSpellKnown, 13262)
        known = ok and not (issecretvalue and issecretvalue(yes)) and yes == true
    end
    return known
end

local cache, CACHE_SECONDS = {}, 60

-- { market = what it usually sells for (copper), saleRate = 0-1 share of listings that sell,
--   soldPerDay = how many sell per day } - each may be missing. nil without TradeSkillMaster.
function ML:MarketData(itemID)
    local api = tsm()
    if not api or not itemID then return nil end
    local saved = cache[itemID]
    if saved and now() - saved.at < CACHE_SECONDS then return saved.data end
    local item = "i:" .. itemID
    -- TSM rounds every answer to a whole number, so the two decimals are asked for times 1000,
    -- the same way TSM's own tooltip does it.
    local rate, perDay = value(api, "DBRegionSaleRate * 1000", item), value(api, "DBRegionSoldPerDay * 1000", item)
    local data = {
        market = value(api, "DBRegionSaleAvg", item) or value(api, "DBMarket", item)
            or value(api, "DBRegionMarketAvg", item),
        saleRate = rate and rate / 1000,
        soldPerDay = perDay and perDay / 1000,
    }
    if data.market then data.market = floor(data.market + 0.5) end
    if next(data) == nil then data = nil end
    cache[itemID] = { at = now(), data = data }
    return data
end

-- ---------- words for people ----------

-- "+18% vs usual" / "-25% vs usual" / "at its usual price"
function ML.TrendText(trend)
    if not trend then return nil end
    if trend.change == 0 then return "at its usual price" end
    return ("%+d%% vs usual"):format(trend.change)
end

-- "sells 40% of the time, about 12 a day"
function ML.SalesText(data)
    if not data then return nil end
    local parts = {}
    if data.saleRate then parts[#parts + 1] = ("sells %d%% of the time"):format(floor(data.saleRate * 100 + 0.5)) end
    if data.soldPerDay then
        local perDay = data.soldPerDay
        parts[#parts + 1] = perDay >= 10 and ("about %d a day"):format(floor(perDay + 0.5))
            or ("about %.1f a day"):format(perDay)
    end
    return #parts > 0 and table.concat(parts, ", ") or nil
end
