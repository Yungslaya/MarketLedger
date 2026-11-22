--[[ Market Ledger - Flip tab: buy cheap, resell at the usual price

  The same full Auction House scan the Gear tab uses also keeps the four cheapest listings of every
  item. After the scan, items listed well under what they usually sell for (TradeSkillMaster's sale
  price) are kept as flips. Gear is left out: its random bonus ("of the Bear") changes its price.

  A flip only counts when:
    - it sells often enough (TradeSkillMaster's sale rate and sold per day),
    - buying the cheap listings and reselling just under the next listing (or at the usual price,
      whichever is lower) makes enough after the 5% cut and the deposit you may lose,
    - the cost fits the "Spend up to" limit.

  Slow flips: pricey items that sell only now and then (under once a day, or under a quarter of
  listings sell). Bots go for fast sellers and leave these alone, so a cheap one can sit for hours.
  They need a bigger gap (30% under usual), at least 1g profit and 40% of the cost, only the cheapest
  listing is bought, and they stay on the list for a day. They may take a few days to sell.

  Without a fresh full scan (none yet, or older than 3 hours), flips come from TradeSkillMaster's saved
  lowest prices instead. Their age is unknown, so the live check before buying matters even more.

  Buying is always your own clicks. Check searches the item live. Buy only works at or under the
  checked price. Stackable goods (ore, cloth) show the real total first and need one more click to
  confirm. Nothing is ever bought on its own.

  Profit: each purchase made here is written down with what it cost. When you take the money from an
  "Auction successful" mail, the sale is matched to those purchases (oldest first), so the Flip tab
  can say what you spent, what came back after the Auction House cut, and what is still unsold.
  Only purchases made with Market Ledger count, and deposits lost on unsold listings are not counted.

  Saved per realm and faction: ML.db.ledgerFlip[realm:faction] = { at = time, items = { [id] = { unit, count, ... } } }
]]

local _, ML = ...
local Flip = {}
ML.Flip = Flip

local floor, max, min = math.floor, math.max, math.min
local now = time or os.time
local KEEP = 5                  -- cheapest listings kept per item (the last one only says where the price goes next)
local MIN_RATE = 0.25           -- TradeSkillMaster sale rate a flip needs
local MIN_PER_DAY = 1           -- and how many sell per day (whole region)
local MIN_PROFIT, MIN_SHARE = 300, 0.20   -- at least 3s and 20% of the cost
local CHEAP = 0.85              -- only items listed under 85% of the usual price are kept after a scan
local OLD = 3 * 60 * 60         -- flips older than this are not put in the AI report
local SLOW_RATE, SLOW_PER_DAY = 0.15, 0.1   -- slow flips: still sells now and then
local SLOW_CHEAP = 0.70         -- and is listed under 70% of the usual price
local SLOW_PROFIT, SLOW_SHARE = 10000, 0.40 -- at least 1g and 40% of the cost
local SLOW_OLD = 24 * 60 * 60   -- slow flips stay on the list this long after a scan
local MOST = 40                 -- rows shown
local BATCH = 300               -- items checked per frame after a scan
local BUDGETS = { 5000, 10000, 50000, 200000, 1000000, 0 }   -- "Spend up to" choices in copper; 0 = any

local function read(fn, ...)
    if not fn then return end
    local ok, a, b, c, d, e, f, g, h, i, j, k = pcall(fn, ...)
    if not ok or (issecretvalue and issecretvalue(a)) then return end
    return a, b, c, d, e, f, g, h, i, j, k
end

local function after(seconds, fn)
    if C_Timer and C_Timer.After then C_Timer.After(seconds, fn) else fn() end
end

local function money(copper)
    if ML.Money then return ML.Money(copper) end
    return tostring(copper) .. "c"
end

local function span(seconds)
    if seconds < 90 then return "1 min" end
    if seconds < 5400 then return ("%d min"):format(floor(seconds / 60 + 0.5)) end
    if seconds < 172800 then return ("%d hours"):format(floor(seconds / 3600 + 0.5)) end
    return ("%d days"):format(floor(seconds / 86400 + 0.5))
end

local function bookKey()
    local faction = read(UnitFactionGroup, "player")
    return type(faction) == "string" and (ML.Realm() .. ":" .. faction) or nil
end

local function charKey()
    local name = read(UnitName, "player")
    return type(name) == "string" and (name .. "-" .. ML.Realm()) or nil
end

-- This auction house's saved flip scan. Never creates anything.
local function saved()
    local all, key = ML.db and ML.db.ledgerFlip, bookKey()
    local mine = type(all) == "table" and key and all[key]
    return type(mine) == "table" and type(mine.items) == "table" and mine or nil
end

local function changed(message)
    if Flip.Changed then pcall(Flip.Changed, message) end
end

-- ---------- 1. During the full scan ----------

local collecting   -- item ID -> { unit, count, unit, count, ... } cheapest first, while a scan is read

function Flip.Begin() collecting = {} end

-- One listing from the full scan (other players' only). buyout is for the whole stack.
function Flip.Note(id, buyout, count)
    if not collecting then return end
    count = (type(count) == "number" and count > 0) and count or 1
    local unit = floor(buyout / count)
    if unit < 1 then return end
    local list = collecting[id]
    if not list then
        collecting[id] = { unit, count }
        return
    end
    -- keep the KEEP cheapest, in order
    local n = #list / 2
    local at = n + 1
    for i = 1, n do
        if unit < list[i * 2 - 1] then at = i; break end
    end
    if at > KEEP then return end
    table.insert(list, at * 2 - 1, count)
    table.insert(list, at * 2 - 1, unit)
    while #list > KEEP * 2 do table.remove(list) end
end

-- "fast" (sells often), "slow" (sells now and then) or nil (too rarely) for TSM's numbers.
local function speed(data)
    local rate, perDay = data.saleRate or 0, data.soldPerDay or 0
    if rate >= MIN_RATE and perDay >= MIN_PER_DAY then return "fast" end
    if rate >= SLOW_RATE and perDay >= SLOW_PER_DAY then return "slow" end
end

-- Is a profit big enough for this kind of flip?
local function worth(profit, cost, slow)
    if slow then return profit >= SLOW_PROFIT and profit >= cost * SLOW_SHARE end
    return profit >= MIN_PROFIT and profit >= cost * MIN_SHARE
end

-- Is this item gear (its price depends on its random bonus)? Bags are fine.
local function isGear(id)
    local _, _, _, where = read((C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant, id)
    return type(where) == "string" and where ~= "" and where ~= "INVTYPE_NON_EQUIP_IGNORE"
        and where ~= "INVTYPE_NON_EQUIP" and where ~= "INVTYPE_BAG"
end

-- The scan is read. Keep only items listed well under their usual price, a few per frame so the game
-- does not stall. An empty read keeps the old flips.
function Flip.Finish(total)
    local list = collecting
    collecting = nil
    if not (list and total and total > 0 and ML.db and bookKey()) then return end
    local key = bookKey()
    if not ML:HasMarketData() then
        ML.db.ledgerFlip = type(ML.db.ledgerFlip) == "table" and ML.db.ledgerFlip or {}
        ML.db.ledgerFlip[key] = { at = now(), items = {}, noMarket = true }
        changed()
        return
    end
    local ids = {}
    for id in pairs(list) do ids[#ids + 1] = id end
    local kept, watch, index = {}, {}, 0
    local function part()
        local last = min(index + BATCH, #ids)
        for i = index + 1, last do
            local id = ids[i]
            local listings = list[id]
            local data = not isGear(id) and ML:MarketData(id)
            local kind = data and data.market and speed(data)
            if kind == "fast" then
                -- sells often: worth watching later with TSM's saved prices, between full scans
                watch[#watch + 1] = id
                if listings[1] < data.market * CHEAP then kept[id] = listings end
            elseif kind == "slow" and listings[1] < data.market * SLOW_CHEAP then
                kept[id] = listings
            end
        end
        index = last
        if index < #ids then
            after(0, part)
        else
            ML.db.ledgerFlip = type(ML.db.ledgerFlip) == "table" and ML.db.ledgerFlip or {}
            table.sort(watch)
            ML.db.ledgerFlip[key] = { at = now(), items = kept, watch = watch }
            Flip.reset()
            changed()
            Flip.Announce(kept)
        end
    end
    part()
end

-- ---------- 2. Picking the flips ----------

function Flip.Budget()
    local picked = ML.db and ML.db.ledgerFlipBudget
    for _, budget in ipairs(BUDGETS) do
        if budget == picked then return budget end
    end
    return 50000
end

local picked, pickedFor, pickedBudget, loading = nil, nil, nil, 0
function Flip.reset() picked = nil end

-- The best way to flip one item, or nil: how many of the cheap listings to buy, and the resell price.
local function bestFlip(id, listings, budget, onlySlow)
    local data = ML:MarketData(id)
    if not (data and data.market) then return end
    local rate = data.saleRate or 0
    local kind = speed(data)
    if not kind or (onlySlow and kind ~= "slow") then return end
    local slow = kind == "slow"
    if slow and listings[1] >= data.market * SLOW_CHEAP then return end
    local _, _, _, _, _, _, _, _, _, _, vendor = read((C_Item and C_Item.GetItemInfo) or GetItemInfo, id)
    local n = #listings / 2
    -- with all KEEP listings saved there may be more above them: never buy the last one kept, so the
    -- next price up is always known. With fewer, nothing else is on sale above them.
    local limit = n >= KEEP and KEEP - 1 or n
    if slow then limit = min(limit, 1) end   -- slow sellers: only the cheapest listing
    local best
    local qty, cost = 0, 0
    for k = 1, limit do
        qty, cost = qty + listings[k * 2], cost + listings[k * 2 - 1] * listings[k * 2]
        if budget > 0 and cost > budget then break end
        -- resell just under the next listing left on sale, never above the usual price
        local nextUnit = listings[k * 2 + 1]
        local resell = nextUnit and min(data.market, nextUnit - 1) or data.market
        local net = floor(resell * 0.95)
        local deposit = ML.Deposit and ML.Deposit(type(vendor) == "number" and vendor or 0, qty) or 0
        -- an unsold listing costs its deposit: count the share that likely won't sell
        local profit = net * qty - cost - floor((deposit or 0) * (1 - rate))
        if worth(profit, cost, slow) and (not best or profit > best.profit) then
            best = { id = id, qty = qty, cost = cost, maxUnit = listings[k * 2 - 1], resell = resell,
                profit = profit, market = data.market, rate = rate, perDay = data.soldPerDay,
                deposit = deposit, listings = listings, alone = nextUnit == nil, slow = slow or nil }
        end
    end
    return best
end

-- Is the saved full scan recent enough to trust its listings?
local function fresh(data) return data and not data.noMarket and now() - (data.at or 0) <= OLD end
Flip.Fresh = function() return fresh(saved()) end
local function slowFresh(data) return data and not data.noMarket and now() - (data.at or 0) <= SLOW_OLD end

-- Right after a full scan: one chat line, so the fast flips can be bought before anyone else does.
function Flip.Announce(kept)
    local budget, fast, slow = Flip.Budget(), 0, 0
    for id, listings in pairs(kept or {}) do
        local flip = type(listings) == "table" and #listings >= 2 and bestFlip(id, listings, budget)
        if flip then
            if flip.slow then slow = slow + 1 else fast = fast + 1 end
        end
    end
    if fast + slow == 0 or not DEFAULT_CHAT_FRAME then return end
    local parts = {}
    if fast > 0 then parts[#parts + 1] = fast .. (fast == 1 and " fast flip" or " fast flips") end
    if slow > 0 then parts[#parts + 1] = slow .. (slow == 1 and " slow flip" or " slow flips") end
    DEFAULT_CHAT_FRAME:AddMessage(("|cffd9b56bMarket Ledger:|r found %s. Open the Flip tab now%s"):format(
        table.concat(parts, " and "), fast > 0 and ": fast ones sell out in minutes." or "."))
end

-- A flip from TradeSkillMaster's saved lowest price (age unknown), or nil. Nothing is known about the
-- listings above it, so it resells at TSM's usual price; the live check decides the rest.
local function tsmFlip(id, budget)
    local data = ML:MarketData(id)
    if not (data and data.market) or isGear(id) then return end
    local rate = data.saleRate or 0
    if rate < MIN_RATE or (data.soldPerDay or 0) < MIN_PER_DAY then return end
    local unit = ML:MinBuyout(id)
    if not unit or unit >= data.market * CHEAP then return end
    local _, _, _, _, _, _, _, stack, _, _, vendor = read((C_Item and C_Item.GetItemInfo) or GetItemInfo, id)
    -- stackable goods: up to 20 (or what the spend limit allows); anything else: one
    local qty = 1
    if type(stack) == "number" and stack > 1 then qty = min(20, budget > 0 and floor(budget / unit) or 20) end
    if qty < 1 or (budget > 0 and unit * qty > budget) then return end
    local cost, net = unit * qty, floor(data.market * 0.95)
    local deposit = ML.Deposit and ML.Deposit(type(vendor) == "number" and vendor or 0, qty) or 0
    local profit = net * qty - cost - floor((deposit or 0) * (1 - rate))
    if profit < MIN_PROFIT or profit < cost * MIN_SHARE then return end
    return { id = id, qty = qty, cost = cost, maxUnit = unit, resell = data.market, profit = profit,
        market = data.market, rate = rate, perDay = data.soldPerDay, deposit = deposit, tsm = true }
end

-- Item IDs to look at with TSM's saved prices: the last full scan's watch list, and items you scanned.
local function watchList(data)
    local ids, seenIds = {}, {}
    local function add(id)
        if type(id) == "number" and not seenIds[id] then seenIds[id] = true; ids[#ids + 1] = id end
    end
    for _, id in ipairs(data and type(data.watch) == "table" and data.watch or {}) do add(id) end
    local prices, key = ML.db and ML.db.ledgerPrices, bookKey()
    for signature in pairs(type(prices) == "table" and key and type(prices[key]) == "table" and prices[key] or {}) do
        add(tonumber(tostring(signature):match("^(%d+)")))
    end
    return ids
end

-- All flips, best profit first: from the fresh full scan, else from TSM's saved prices.
-- Also returns how many names the game is still loading.
function Flip.Picks()
    local data = saved()
    if not ML:HasMarketData() then return {}, 0 end
    local budget = Flip.Budget()
    local scanned, slowOk = fresh(data), slowFresh(data)
    local mode = (scanned and "scan" or "tsm") .. (slowOk and ":slow:" or ":") .. tostring(data and data.at)
    if picked and pickedFor == mode and pickedBudget == budget and loading == 0 then return picked, 0 end
    local candidates = {}
    if not scanned then
        for _, id in ipairs(watchList(data)) do candidates[#candidates + 1] = tsmFlip(id, budget) or false end
    end
    if slowOk then
        -- a fresh scan gives every flip; an older one (under a day) still gives the slow ones
        for id, listings in pairs(data.items) do
            candidates[#candidates + 1] = type(listings) == "table" and #listings >= 2
                and bestFlip(id, listings, budget, not scanned) or false
        end
    end
    local found, waiting = {}, 0
    for _, flip in ipairs(candidates) do
        if flip then
            local name = read((C_Item and C_Item.GetItemInfo) or GetItemInfo, flip.id)
            if type(name) == "string" then
                flip.name = name
                found[#found + 1] = flip
            else
                waiting = waiting + 1
                if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, flip.id) end
            end
        end
    end
    -- fast flips first (they go first), then slow ones; best profit first in each
    table.sort(found, function(a, b)
        if (a.slow or false) ~= (b.slow or false) then return not a.slow end
        if a.profit ~= b.profit then return a.profit > b.profit end
        return a.name < b.name
    end)
    while #found > MOST do table.remove(found) end
    picked, pickedFor, pickedBudget, loading = found, mode, budget, waiting
    return found, waiting
end

-- ---------- 3. Check, then buy (your clicks only) ----------
-- state[id] = { phase = "checking" | "ready" | "starting" | "confirm", ... }

local state = {}
local pending   -- the purchase the game is working on: { id, qty, name, total, auctionID }
local function stateOf(id) return state[id] end

local function bought()
    local all, key = ML.db and ML.db.ledgerFlipBought, charKey()
    local mine = type(all) == "table" and key and all[key]
    return type(mine) == "table" and mine or {}
end
-- How many of an item you have bought with Market Ledger (it tells the Plan tab a Buy step is done).
function Flip.BoughtCount(id) return bought()[id] or 0 end
-- This character's flip book: item ID -> { name, bought, spent, sold, earned, soldCost, lots = { { qty, unit } } }
local function book(create)
    local key = charKey()
    if not (ML.db and key) then return end
    if create then
        ML.db.ledgerFlipBook = type(ML.db.ledgerFlipBook) == "table" and ML.db.ledgerFlipBook or {}
        ML.db.ledgerFlipBook[key] = type(ML.db.ledgerFlipBook[key]) == "table" and ML.db.ledgerFlipBook[key] or {}
    end
    local all = ML.db.ledgerFlipBook
    return type(all) == "table" and type(all[key]) == "table" and all[key] or nil
end

local function addBought(id, qty, total, name)
    local key = charKey()
    if not (ML.db and key) then return end
    ML.db.ledgerFlipBought = type(ML.db.ledgerFlipBought) == "table" and ML.db.ledgerFlipBought or {}
    local mine = ML.db.ledgerFlipBought[key] or {}
    ML.db.ledgerFlipBought[key] = mine
    mine[id] = (mine[id] or 0) + qty
    -- what it cost, for the profit later
    local entry = book(true)[id] or { bought = 0, spent = 0, sold = 0, earned = 0, soldCost = 0, lots = {} }
    book(true)[id] = entry
    entry.name = name or entry.name
    entry.bought, entry.spent = entry.bought + qty, entry.spent + total
    entry.lots[#entry.lots + 1] = { qty, total / qty }
end

-- A sale came in: count units of a flipped item sold for this much (after the Auction House cut).
-- Matched to the oldest purchases first. Units you had before flipping are not counted.
local function addSold(name, count, received)
    local all = book()
    if not all or type(name) ~= "string" then return end
    for _, entry in pairs(all) do
        local left = entry.name == name and entry.bought - entry.sold or 0
        if left > 0 then
            local units = min(count, left)
            local cost = 0
            local need = units
            while need > 0 and entry.lots[1] do
                local lot = entry.lots[1]
                local take = min(need, lot[1])
                cost, need, lot[1] = cost + take * lot[2], need - take, lot[1] - take
                if lot[1] <= 0 then table.remove(entry.lots, 1) end
            end
            local got = floor(received * units / count + 0.5)
            entry.sold = entry.sold + units
            entry.earned = entry.earned + got
            entry.soldCost = entry.soldCost + floor(cost + 0.5)
            return true, units, got, floor(cost + 0.5)
        end
    end
end
Flip._sold = addSold   -- tests

-- What you paid each for the flipped units of an item you still have (oldest purchases first), or nil.
function Flip.PaidEach(id)
    local entry = (book() or {})[id]
    if not entry or entry.bought - entry.sold <= 0 then return end
    local units, cost = 0, 0
    for _, lot in ipairs(entry.lots) do units, cost = units + lot[1], cost + lot[1] * lot[2] end
    if units > 0 then return floor(cost / units + 0.5) end
end

-- Totals over every flip: spent, bought, sold units, money back, cost of what sold, units still unsold.
function Flip.Record()
    local t = { spent = 0, earned = 0, soldCost = 0, left = 0, items = {} }
    for id, entry in pairs(book() or {}) do
        t.spent, t.earned, t.soldCost = t.spent + entry.spent, t.earned + entry.earned, t.soldCost + entry.soldCost
        t.left = t.left + (entry.bought - entry.sold)
        t.items[#t.items + 1] = { id = id, name = entry.name or ("item " .. id), bought = entry.bought, spent = entry.spent,
            sold = entry.sold, earned = entry.earned, profit = entry.earned - entry.soldCost, left = entry.bought - entry.sold }
    end
    table.sort(t.items, function(a, b) return a.name < b.name end)
    t.profit = t.earned - t.soldCost
    return t
end

-- ---------- reading auction sales from the mailbox ----------
-- "Auction successful" mails are read when you take their money (by hand, Open All, or a mail addon).
local lastMail = {}
local function readSale(index)
    if type(index) ~= "number" or not GetInboxInvoiceInfo then return end
    local kind, name, _, bid, _, _, cut, _, _, count = read(GetInboxInvoiceInfo, index)
    if kind ~= "seller" or type(name) ~= "string" or type(bid) ~= "number" then return end
    count = type(count) == "number" and count > 0 and count or 1
    -- the same mail can be taken twice in a moment (money, then the whole mail): count it once
    local _, _, _, subject, _, _, daysLeft = read(GetInboxHeaderInfo, index)
    local key = table.concat({ name, bid, count, tostring(subject), floor((tonumber(daysLeft) or 0) * 1000) }, "|")
    if lastMail[key] and now() - lastMail[key] < 60 then return end
    lastMail[key] = now()
    local counted, units, got, cost = addSold(name, count, bid - (type(cut) == "number" and cut or 0))
    if not counted then return end
    -- one line in chat for every flip sale, so the result is easy to see
    local profit = got - cost
    local line = ("|cffd9b56bMarket Ledger:|r flip sold: %d %s for %s, paid %s. %s"):format(units, name, money(got),
        money(cost), profit >= 0 and ("|cff40e040Profit " .. money(profit) .. "|r") or ("|cffff5050Loss " .. money(-profit) .. "|r"))
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(line) end
    changed()
end
if hooksecurefunc then
    for _, fn in ipairs({ "TakeInboxMoney", "AutoLootMailItem" }) do
        if type(_G[fn]) == "function" then pcall(hooksecurefunc, fn, readSale) end
    end
end

-- The button's words for a flip.
function Flip.Button(flip)
    local s = stateOf(flip.id)
    if not s then return "Check" end
    if s.phase == "checking" or s.phase == "starting" then return "Wait..." end
    if s.phase == "ready" then return ("Buy %d for %s"):format(s.qty, money(s.total)) end
    if s.phase == "confirm" then return "Confirm " .. money(s.total) end
    return "Check"
end

local ah = C_AuctionHouse

-- The live search answered: what can be bought at or under the planned price right now.
local function results(event, resultKey, s)
    local wantQty, maxUnit = s.flip.qty, s.flip.maxUnit
    if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
        local count = read(ah.GetNumCommoditySearchResults, resultKey) or 0
        local qty, total, lowest, nextUnit = 0, 0, nil, nil
        for i = 1, count do
            local row = read(ah.GetCommoditySearchResultInfo, resultKey, i)
            local unit, amount = row and row.unitPrice, row and row.quantity or 0
            local mineThere = row and row.numOwnerItems or 0
            if type(unit) == "number" and unit > 0 and amount > mineThere then
                lowest = lowest or unit
                if unit > maxUnit or qty >= wantQty then nextUnit = unit; break end
                local free = amount - mineThere
                local take = min(free, wantQty - qty)
                qty, total = qty + take, total + take * unit
                if take < free then nextUnit = unit; break end   -- some left at this price
            end
        end
        return qty, total, lowest, true, nil, nextUnit
    end
    -- Regular items: buyoutAmount is the price of ONE item. A row's quantity is how many are on sale at
    -- that price (the game groups them), not a stack. Buying takes one of them. (Dividing the price by
    -- the quantity made a 4g row of five look like 80s each, and a 4g item was bought as a "flip".)
    local count = read(ah.GetNumItemSearchResults, resultKey) or 0
    local best, lowest
    for i = 1, count do
        local row = read(ah.GetItemSearchResultInfo, resultKey, i)
        local price = row and row.buyoutAmount
        if type(price) == "number" and price > 0 and not row.containsOwnerItem then
            lowest = min(lowest or price, price)
            if price <= maxUnit and (not best or price < best.price) then
                best = { auctionID = row.auctionID, price = price, more = (row.quantity or 1) > 1 }
            end
        end
    end
    if not best then return 0, 0, lowest, false end
    -- the cheapest one left after you buy: another in the same row, or the next row up
    local nextUnit = best.more and best.price or nil
    for i = 1, count do
        local row = read(ah.GetItemSearchResultInfo, resultKey, i)
        local price = row and row.buyoutAmount
        if type(price) == "number" and price > 0 and not row.containsOwnerItem and row.auctionID ~= best.auctionID then
            nextUnit = min(nextUnit or math.huge, price)
        end
    end
    return 1, best.price, lowest, false, best.auctionID, nextUnit
end

-- Called with every search result while a check waits. Returns true when it was ours.
function Flip.Results(event, resultKey)
    if issecretvalue and issecretvalue(resultKey) then return end
    local id = event == "COMMODITY_SEARCH_RESULTS_UPDATED" and resultKey
        or (type(resultKey) == "table" and resultKey.itemID)
    local s = type(id) == "number" and state[id]
    if not (s and s.phase == "checking") then return end
    local qty, total, lowest, commodity, auctionID, nextUnit = results(event, resultKey, s)
    if qty < 1 then
        state[id] = nil
        changed(lowest and ("%s is now %s each, over your %s. Not bought."):format(s.flip.name, money(lowest), money(s.flip.maxUnit))
            or (s.flip.name .. " is sold out. Not bought."))
        return true
    end
    -- Is it still worth it? Resell just under what is left on sale (never above the usual price).
    local profitText = ""
    local data = ML:MarketData(id)
    if data and data.market then
        local resell = nextUnit and min(data.market, nextUnit - 1) or data.market
        local _, _, _, _, _, _, _, _, _, _, vendor = read((C_Item and C_Item.GetItemInfo) or GetItemInfo, id)
        local deposit = ML.Deposit and ML.Deposit(type(vendor) == "number" and vendor or 0, qty) or 0
        local profit = floor(resell * 0.95) * qty - total - floor((deposit or 0) * (1 - (data.saleRate or 0)))
        if not worth(profit, total, s.flip.slow) then
            state[id] = nil
            changed(("Not worth it now: you would resell at %s, %s. Not bought."):format(money(resell),
                profit > 0 and ("only about " .. money(profit) .. " profit") or "no profit"))
            return true
        end
        profitText = (", about %s profit"):format(money(profit))
    end
    s.phase, s.qty, s.total, s.commodity, s.auctionID = "ready", qty, total, commodity, auctionID
    changed(("Still cheap: %d for %s%s. Click Buy to buy."):format(qty, money(total), profitText))
    return true
end

local function atAuctionHouse(open)
    if not open then return "Go to the Auction House to buy." end
    if ML.ScanRunning and ML.ScanRunning() then return "Wait for Scan Bags to finish." end
    if ML:InCombat() then return "Not in combat." end
end

-- A flip's button was clicked. Returns the line to show.
function Flip.Buy(flip, open)
    local id = flip.id
    local problem = atAuctionHouse(open)
    if problem then return problem end
    local s = state[id]
    if not s or s.phase == "checking" and now() - s.at > 6 then
        -- 1. Check: a fresh search for this one item
        if not (ah and ah.SendSearchQuery and ah.MakeItemKey) then return "This game version cannot search." end
        if read(ah.IsThrottledMessageSystemReady) == false then return "The Auction House is busy. Click again." end
        local key = read(ah.MakeItemKey, id)
        state[id] = { phase = "checking", flip = flip, at = now() }
        local ok, accepted = pcall(ah.SendSearchQuery, key, {}, true)
        if not ok or accepted == false then
            state[id] = nil
            return "The search was refused. Click again in a moment."
        end
        local mine = state[id]
        after(6, function()
            if state[id] == mine and mine.phase == "checking" then
                state[id] = nil
                changed("The Auction House did not answer. Click Check again.")
            end
        end)
        if state[id] and state[id].phase == "ready" then return end   -- already answered
        return "Checking the live price of " .. flip.name .. "..."
    end
    if s.phase == "checking" or s.phase == "starting" then return "Still checking. One moment." end
    local gold = read(GetMoney) or 0
    if s.phase == "ready" then
        if gold < s.total then
            state[id] = nil
            return ("Not enough gold: this costs %s."):format(money(s.total))
        end
        if not s.commodity then
            -- 2. One click buys one listing, at the checked price
            if not (ah.PlaceBid and s.auctionID) then state[id] = nil; return "This game version cannot buy." end
            local ok = pcall(ah.PlaceBid, s.auctionID, s.total)
            state[id] = nil
            if not ok then return "The game refused the purchase." end
            pending = { id = id, qty = s.qty, auctionID = s.auctionID, name = flip.name, total = s.total }
            return ("Buying %d %s for %s..."):format(s.qty, flip.name, money(s.total))
        end
        -- 2. Stackable goods: ask the game for the real total first
        if not ah.StartCommoditiesPurchase then state[id] = nil; return "This game version cannot buy." end
        s.phase = "starting"
        local ok = pcall(ah.StartCommoditiesPurchase, id, s.qty)
        if not ok then state[id] = nil; return "The game refused the purchase." end
        if s.phase == "confirm" then return end   -- the total already came back
        return "Asking the game for the total..."
    end
    if s.phase == "confirm" then
        if gold < s.total then
            pcall(ah.CancelCommoditiesPurchase)
            state[id] = nil
            return ("Not enough gold: this costs %s."):format(money(s.total))
        end
        -- 3. Confirm: buys exactly the checked amount
        local ok = pcall(ah.ConfirmCommoditiesPurchase, id, s.qty)
        state[id] = nil
        if not ok then return "The game refused the purchase." end
        pending = { id = id, qty = s.qty, name = flip.name, total = s.total }
        return ("Buying %d %s for %s..."):format(s.qty, flip.name, money(s.total))
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE", "COMMODITY_PURCHASE_SUCCEEDED",
    "COMMODITY_PURCHASE_FAILED", "AUCTION_HOUSE_PURCHASE_COMPLETED", "AUCTION_HOUSE_CLOSED" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, a, b)
    if event == "AUCTION_HOUSE_CLOSED" then
        for id, s in pairs(state) do
            if s.phase == "confirm" or s.phase == "starting" then pcall(ah.CancelCommoditiesPurchase) end
            state[id] = nil
        end
        return
    end
    if event == "COMMODITY_PRICE_UPDATED" then
        -- a = the new unit price, b = the total
        for id, s in pairs(state) do
            if s.phase == "starting" then
                if type(b) == "number" and b <= s.flip.maxUnit * s.qty and (type(a) ~= "number" or a <= s.flip.maxUnit) then
                    s.phase, s.total = "confirm", b
                    changed(("Total for %d %s: %s. Click Confirm to buy."):format(s.qty, s.flip.name, money(b)))
                else
                    pcall(ah.CancelCommoditiesPurchase)
                    state[id] = nil
                    changed(("The price went up to %s. Not bought."):format(money(type(b) == "number" and b or 0)))
                end
            end
        end
    elseif event == "COMMODITY_PRICE_UNAVAILABLE" then
        for id, s in pairs(state) do
            if s.phase == "starting" then state[id] = nil end
        end
        changed("The game could not price that. Not bought.")
    elseif event == "COMMODITY_PURCHASE_SUCCEEDED" or event == "AUCTION_HOUSE_PURCHASE_COMPLETED" then
        local p = pending
        if p and (event == "COMMODITY_PURCHASE_SUCCEEDED" or a == nil or a == p.auctionID) then
            pending = nil
            addBought(p.id, p.qty, p.total, p.name)
            changed(("Bought %d %s for %s. It goes to your mailbox."):format(p.qty, p.name, money(p.total)))
        end
    elseif event == "COMMODITY_PURCHASE_FAILED" then
        pending = nil
        changed("The purchase failed. Nothing was bought.")
    end
end)

-- ---------- 4. Rows for the Flip tab ----------

local retries, retryWaiting = 0, false

function Flip.Lines()
    local data = saved()
    local budget = Flip.Budget()
    local scanLabel = ML.Gear and ML.Gear.ScanLabel and ML.Gear.ScanLabel() or "Full Scan"
    local title = "No flips yet. Click Full Scan at the Auction House."
    if fresh(data) then title = ("Flips from %s ago. Buy fast ones first."):format(span(now() - data.at))
    elseif data then title = ("Last full scan %s ago. Showing TSM's saved prices."):format(span(now() - data.at)) end
    local lines = {
        { page = "Flip", flipControl = "scan", wide = true, button = scanLabel == "Scan Gear" and "Full Scan" or scanLabel,
            title = title },
        { page = "Flip", flipControl = "budget", wide = true, button = "Change",
            title = "Spend up to: " .. (budget == 0 and "any amount" or money(budget)) .. " per flip" },
    }
    -- how your flips went
    local results = Flip.Record()
    if #results.items > 0 then
        local open = ML.db and ML.db.ledgerFlipDetails
        lines[#lines + 1] = { page = "Flip", flipControl = "details", wide = true, button = open and "Hide" or "Details",
            title = ("Your flips: spent %s, got back %s. Profit %s%s"):format(money(results.spent), money(results.earned),
                (results.profit >= 0 and "+" or "-") .. money(math.abs(results.profit)),
                results.left > 0 and (", " .. results.left .. " still to sell.") or ".") }
        if open then
            for _, item in ipairs(results.items) do
                lines[#lines + 1] = { page = "Flip", flipResult = item, wide = true,
                    title = ("   %s: bought %d for %s, sold %d for %s%s"):format(item.name, item.bought, money(item.spent),
                        item.sold, money(item.earned), item.left > 0 and (", " .. item.left .. " left") or ""),
                    action = item.sold > 0 and ((item.profit >= 0 and "+" or "-") .. money(math.abs(item.profit))) or "" }
            end
            lines[#lines + 1] = { page = "Flip", flipControl = "clear", wide = true, button = "Clear",
                title = "   Start the flip record over" }
        end
    end
    if not ML:HasMarketData() or (data and data.noMarket) then
        lines[#lines + 1] = { title = "Flips need TradeSkillMaster's sale prices. Install TSM and its desktop app." }
        return lines
    end
    local picks, waiting = Flip.Picks()
    if not fresh(data) and #picks > 0 then
        lines[#lines + 1] = { title = "From TSM's saved prices (age unknown). Check looks at the live price first." }
    end
    local slowShown = false
    for _, flip in ipairs(picks) do
        if flip.slow and not slowShown then
            slowShown = true
            lines[#lines + 1] = { title = "Slow flips: pricey items bots skip. They may take a few days to sell." }
        end
        lines[#lines + 1] = { page = "Flip", flip = flip, id = flip.id, name = flip.name,
            title = flip.name .. " ×" .. flip.qty .. (flip.tsm and " (TSM)" or "") .. (flip.slow and " (slow)" or ""), action = "+" .. money(flip.profit),
            auction = money(flip.maxUnit), vendor = money(flip.resell), button = Flip.Button(flip) }
    end
    if #picks == 0 and (data or waiting > 0) then
        lines[#lines + 1] = { title = waiting > 0 and "Loading item names from the game..."
            or fresh(data) and "No good flips in this scan. Try another scan later."
            or "No good flips in TSM's saved prices. A full scan may find more." }
    end
    if waiting == 0 then retries = 0
    elseif not retryWaiting and retries < 10 then
        retries, retryWaiting = retries + 1, true
        after(2, function() retryWaiting = false; Flip.reset(); changed() end)
    end
    return lines
end

-- A Flip tab row (or a Buy step on the Plan tab) was clicked. Returns the line to show.
function Flip.Act(entry, open)
    if entry.flipControl == "scan" then return ML.Gear.Scan(open) end
    if entry.flipControl == "details" then
        ML.db.ledgerFlipDetails = not ML.db.ledgerFlipDetails or nil
        return
    end
    if entry.flipControl == "clear" then
        local all, key = ML.db.ledgerFlipBook, charKey()
        if type(all) == "table" and key then all[key] = nil end
        ML.db.ledgerFlipDetails = nil
        return "Flip record cleared."
    end
    if entry.flipControl == "budget" then
        local current = Flip.Budget()
        for i, budget in ipairs(BUDGETS) do
            if budget == current then ML.db.ledgerFlipBudget = BUDGETS[i % #BUDGETS + 1]; break end
        end
        Flip.reset()
        return "Spend limit changed."
    end
    if entry.flip then return Flip.Buy(entry.flip, open) end
end

function Flip.Tooltip(owner, entry)
    local flip = entry.flip
    if not (flip and GameTooltip) then return end
    GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
    GameTooltip:SetText(flip.name, 1, 1, 1)
    if flip.resell then
        GameTooltip:AddLine(("Buy %d for %s in all, resell at %s each."):format(flip.qty, money(flip.cost), money(flip.resell)), 1, 0.82, 0, true)
        GameTooltip:AddLine(("Profit after the 5%% cut: about %s."):format(money(flip.profit)), 0.25, 0.88, 0.25, true)
        GameTooltip:AddLine(("TSM: usually sells for %s, sells %d%% of the time, about %s a day."):format(
            money(flip.market), floor(flip.rate * 100 + 0.5), flip.perDay >= 10 and tostring(floor(flip.perDay + 0.5))
            or ("%.1f"):format(flip.perDay)), 0.6, 0.8, 1, true)
        if flip.deposit and flip.deposit > 0 then
            GameTooltip:AddLine(("Deposit when you list: about %s, lost if it does not sell."):format(money(flip.deposit)), 0.8, 0.8, 0.8, true)
        end
        if flip.slow then
            GameTooltip:AddLine("Slow flip: it sells now and then, not every hour. List it and be patient; it may take a few days.", 1, 0.5, 0.3, true)
        end
        if flip.tsm then
            GameTooltip:AddLine("Buy price from TSM's saved lowest price. Its age is unknown.", 1, 0.5, 0.3, true)
        elseif flip.alone then
            GameTooltip:AddLine("Nothing else is listed: the resell price is TSM's usual price.", 1, 0.5, 0.3, true)
        end
    else
        GameTooltip:AddLine(("Pay at most %s each."):format(money(flip.maxUnit)), 1, 0.82, 0, true)
    end
    GameTooltip:AddLine("Check looks again right before you buy. A higher price, or a buy that would no longer make a profit, is refused.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end

-- ---------- 5. The AI report ----------

function Flip.ReportLines()
    local data = saved()
    local picks = Flip.Picks()
    local lines = {}
    local results = Flip.Record()
    if #results.items > 0 then
        lines[#lines + 1] = "Flip results so far (bought with Market Ledger; sales read from auction mail after the 5% cut; lost deposits not counted):"
        lines[#lines + 1] = "name | bought | spent | sold | money back | profit on what sold | still to sell"
        for _, item in ipairs(results.items) do
            lines[#lines + 1] = table.concat({ item.name, item.bought, item.spent, item.sold, item.earned, item.profit, item.left }, " | ")
        end
    end
    if #picks == 0 then return lines end
    lines[#lines + 1] = "Flip speed: TSM sold per day under 1 is a slow flip (bots skip these; it may take days to sell). "
        .. "Fast flips sell out in minutes, so the player buys them in the Flip tab right after the scan."
    local header = {
        fresh(data) and ("Flip options (buy these cheap listings and resell; full scan %s ago; asking prices, not proof of sales):")
            :format(span(now() - data.at))
            or "Flip options (from TradeSkillMaster's saved lowest prices, age unknown; Market Ledger checks the live price before buying):",
        "name | buy quantity | highest unit price to pay | resell price each | expected profit total | TSM sale rate | TSM sold per day | item id",
    }
    for _, line in ipairs(header) do lines[#lines + 1] = line end
    -- slow flips first: they are the ones still there when the plan comes back
    local order = {}
    for _, flip in ipairs(picks) do if flip.slow then order[#order + 1] = flip end end
    for _, flip in ipairs(picks) do if not flip.slow then order[#order + 1] = flip end end
    for i = 1, min(#order, 12) do
        local flip = order[i]
        lines[#lines + 1] = table.concat({ flip.name, flip.qty, flip.maxUnit, flip.resell, flip.profit,
            floor(flip.rate * 100 + 0.5) .. "%", ("%.1f"):format(flip.perDay), flip.id }, " | ")
    end
    return lines
end
