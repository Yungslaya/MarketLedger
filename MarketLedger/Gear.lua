--[[ Market Ledger - Gear tab: cheap upgrades on the Auction House

  One click on Scan Gear asks the game for its full Auction House list. The game allows that once every
  15 minutes, for all addons together. From the list Market Ledger keeps the cheapest buyout of every
  piece of gear this character can wear right now. Each random bonus ("of the Bear") is kept by itself,
  because the bonus decides what the item is worth to you.

  The Gear tab then shows the pieces that beat what you have on, best first, up to a price you pick.
  "Better" is a simple score: each stat counts a set amount for your role (a tank wants Stamina and
  Armor, a caster wants Intellect). The numbers are rough on purpose; hover a row to see the real stats.

  Nothing is bought for you. Search only fills in the Auction House search box.
  Saved per character: ML.db.ledgerGear[name-realm] = { at = time, items = { [item string] = copper } }
]]

local _, ML = ...
local Gear = {}
ML.Gear = Gear

local floor, max, min = math.floor, math.max, math.min
local now = time or os.time
local COOLDOWN = 15 * 60      -- the game's own limit on full scans
local BATCH = 800             -- listings read per frame
local BELOW = 12              -- gear needing a level this far under yours is never an upgrade
local PER_SLOT, MOST = 5, 80  -- rows shown per slot, and in all
local PRICES = { 5000, 10000, 20000, 50000, 0 }   -- "highest price" choices in copper; 0 = any price

-- Call a game function safely. Nil on an error or a hidden ("secret") value.
local function read(fn, ...)
    if not fn then return end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if not ok or (issecretvalue and issecretvalue(a)) then return end
    return a, b, c, d, e, f, g
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

local function charKey()
    local name = read(UnitName, "player")
    return type(name) == "string" and (name .. "-" .. ML.Realm()) or nil
end

-- This character's saved scan. Never creates anything.
local function saved()
    local all, key = ML.db and ML.db.ledgerGear, charKey()
    local mine = type(all) == "table" and key and all[key]
    return type(mine) == "table" and type(mine.items) == "table" and mine or nil
end

-- ---------- 1. Which slot an item goes in ----------

-- equip location -> the inventory slots it can go in
local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 },
    INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 },
}
local SLOT_NAME = { "Head", "Neck", "Shoulder", nil, "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands",
    "Ring", "Ring", "Trinket", "Trinket", "Back", "Weapon", "Off hand", "Ranged" }
-- the order the slot blocks are shown in
local GROUP_ORDER = { "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet",
    "Ring", "Trinket", "Weapon", "Off hand", "Ranged" }

local function equipSlot(item)
    local lookup = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _, _, _, where = read(lookup, item)
    if type(where) == "string" and not (issecretvalue and issecretvalue(where)) and SLOTS[where] then return where end
end

-- ---------- 2. Roles and what each stat is worth ----------
-- Each line: a piece of the game's stat name, and what one point is worth. The first match wins.
-- Armor is "RESISTANCE0". These are our own rough numbers for leveling gear.

local WEIGHTS = {
    tank = { { "_VS_", 0 }, { "FERAL", 0 }, { "STAMINA", 1 }, { "RESISTANCE0", 0.06 }, { "DEFENSE", 1 },
        { "DODGE", 6 }, { "PARRY", 6 }, { "BLOCK", 0.3 }, { "STRENGTH", 0.6 }, { "AGILITY", 0.5 },
        { "ATTACK_POWER", 0.3 }, { "DAMAGE_PER_SECOND", 2 }, { "HIT", 3 }, { "CRIT", 3 } },
    strength = { { "_VS_", 0 }, { "FERAL", 0 }, { "STRENGTH", 1 }, { "AGILITY", 0.6 }, { "STAMINA", 0.5 },
        { "ATTACK_POWER", 0.5 }, { "CRIT", 8 }, { "HIT", 8 }, { "DAMAGE_PER_SECOND", 3 }, { "RESISTANCE0", 0.01 } },
    agility = { { "_VS_", 0 }, { "FERAL", 0 }, { "AGILITY", 1 }, { "STRENGTH", 0.5 }, { "STAMINA", 0.5 },
        { "ATTACK_POWER", 0.5 }, { "CRIT", 8 }, { "HIT", 8 }, { "DAMAGE_PER_SECOND", 3 }, { "RESISTANCE0", 0.01 } },
    caster = { { "_VS_", 0 }, { "HEALING", 0.4 }, { "SPELL", 1.2 }, { "INTELLECT", 1 }, { "STAMINA", 0.6 },
        { "SPIRIT", 0.4 }, { "REGEN", 2.5 }, { "RESISTANCE0", 0.01 } },
    healer = { { "_VS_", 0 }, { "HEALING", 1.2 }, { "SPELL", 0.8 }, { "INTELLECT", 1 }, { "SPIRIT", 0.8 },
        { "REGEN", 3 }, { "STAMINA", 0.4 }, { "RESISTANCE0", 0.01 } },
}
local ROLE_NAME = { tank = "Tank", strength = "Damage (Strength)", agility = "Damage (Agility)",
    caster = "Spell damage", healer = "Healer" }
-- the roles a class can pick, the usual one first
local CLASS_ROLES = {
    WARRIOR = { "strength", "tank" }, PALADIN = { "strength", "tank", "healer" }, ROGUE = { "agility" },
    HUNTER = { "agility" }, DRUID = { "agility", "tank", "caster", "healer" },
    SHAMAN = { "caster", "strength", "healer" }, MAGE = { "caster" }, WARLOCK = { "caster" },
    PRIEST = { "caster", "healer" },
}

local function classRoles()
    local _, class = read(UnitClass, "player")
    return CLASS_ROLES[class] or { "strength", "agility", "tank", "caster", "healer" }
end

function Gear.Role()
    local roles, key = classRoles(), charKey()
    local picked = ML.db and type(ML.db.ledgerGearRole) == "table" and key and ML.db.ledgerGearRole[key]
    for _, role in ipairs(roles) do
        if role == picked then return role, roles end
    end
    -- no pick yet: a shield on your arm means you tank
    local offhand = read(GetInventoryItemLink, "player", 17)
    if type(offhand) == "string" and equipSlot(offhand) == "INVTYPE_SHIELD" then
        for _, role in ipairs(roles) do
            if role == "tank" then return role, roles end
        end
    end
    return roles[1], roles
end

local function worth(role, key)
    key = key:upper()
    for _, pair in ipairs(WEIGHTS[role]) do
        if key:find(pair[1], 1, true) then return pair[2] end
    end
    return 0
end

-- The game's stat table for an item, as plain numbers only. Nil when the game has not loaded it yet.
local function plainStats(fn, link)
    local stats = read(fn, link)
    if type(stats) ~= "table" or (issecrettable and issecrettable(stats)) then return end
    local plain = {}
    for key, amount in pairs(stats) do
        if type(key) == "string" and type(amount) == "number" then plain[key] = amount end
    end
    return plain
end
-- The game has two names for this call. If the first gives nothing, the second is asked too.
local function statsOf(link)
    local stats = plainStats(C_Item and C_Item.GetItemStats, link)
    if (stats == nil or next(stats) == nil) and GetItemStats and GetItemStats ~= (C_Item and C_Item.GetItemStats) then
        stats = plainStats(GetItemStats, link) or stats
    end
    return stats
end

-- The stat's name for people. Two get our own short word so a row stays narrow.
local function statName(key)
    local upper = key:upper()
    if upper:find("DAMAGE_PER_SECOND", 1, true) then return "DPS" end
    if upper:find("RESISTANCE0", 1, true) then return "Armor" end
    local text = _G[key]
    return type(text) == "string" and text ~= "" and text or key
end

local RANGED = { INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true }

-- noDamage: leave weapon damage out. A bow or gun is only a stat stick unless you are a hunter.
local function score(role, stats, noDamage)
    local total = 0
    for key, amount in pairs(stats or {}) do
        if not (noDamage and key:upper():find("DAMAGE_PER_SECOND", 1, true)) then
            total = total + amount * worth(role, key)
        end
    end
    return total
end

-- ---------- 3. Reading the Auction House list ----------

local wornGear   -- defined in part 4; the scan calls it first to remember your own gear

local state, token, progress = "idle", 0, 0
function Gear.State() return state, progress end

function Gear.CooldownLeft()
    local asked = ML.db and ML.db.ledgerGearAsked
    return type(asked) == "number" and max(0, COOLDOWN - (now() - asked)) or 0
end

local function changed(message)
    if Gear.Changed then pcall(Gear.Changed, message) end
end

-- One key per bonus: the item's ID, its random suffix and its bonus IDs. Everything that differs from
-- copy to copy (enchant, who made it, the level it dropped at) is left out.
function Gear.Key(link)
    local text = type(link) == "string" and link:match("item:([%-%d:]+)")
    if not text then return end
    local fields = {}
    for value in (text .. ":"):gmatch("([^:]*):") do fields[#fields + 1] = value end
    local id = tonumber(fields[1])
    if not id then return end
    local count = tonumber(fields[13]) or 0
    local parts = { "item", fields[1], "", "", "", "", "", fields[7] or "", "", "", "", "", fields[12] or "", tostring(count) }
    for i = 1, count do parts[#parts + 1] = fields[13 + i] or "" end
    return table.concat(parts, ":"), id
end

local function readList()
    local A = C_AuctionHouse
    local total = read(A.GetNumReplicateItems) or 0
    token = token + 1
    local mine, items, kept, pending = token, {}, 0, {}
    local me, level = read(UnitName, "player"), read(UnitLevel, "player") or 0
    local wearable = {}   -- item ID -> true/false, so each kind of item is judged once
    state, progress = "reading", 0
    if ML.Flip then ML.Flip.Begin() end   -- the same list also gives the Flip tab its prices
    changed()

    local function isGear(id)
        if wearable[id] == nil then
            local fits = equipSlot(id) ~= nil
            if fits then
                local _, _, _, _, needs = read((C_Item and C_Item.GetItemInfo) or GetItemInfo, id)
                if type(needs) == "number" and needs < level - BELOW then fits = false end
            end
            wearable[id] = fits
        end
        return wearable[id]
    end
    local function keep(link, buyout)
        local key = Gear.Key(link)
        if not key then return false end
        if not items[key] then kept = kept + 1 end
        if not items[key] or buyout < items[key] then items[key] = buyout end
        return true
    end
    local function finish()
        if mine ~= token then return end
        state = "idle"
        -- an empty list (the window closed, or nothing came) keeps the old prices
        if total > 0 and ML.db and charKey() then
            ML.db.ledgerGear = type(ML.db.ledgerGear) == "table" and ML.db.ledgerGear or {}
            ML.db.ledgerGear[charKey()] = { at = now(), items = items }
            if ML.Flip then pcall(ML.Flip.Finish, total) end
            changed(("Full scan done. %d listings read, %d pieces you can wear."):format(total, kept))
        else
            changed("The Auction House sent an empty list. Try again in 15 minutes.")
        end
    end
    local function again(tries)
        if mine ~= token then return end
        local left = {}
        for _, wait in ipairs(pending) do
            local link = read(A.GetReplicateItemLink, wait[1])
            if not (link and keep(link, wait[2])) then left[#left + 1] = wait end
        end
        pending = left
        if #pending > 0 and tries < 3 then after(2, function() again(tries + 1) end) else finish() end
    end
    local function part(first)
        if mine ~= token then return end
        local last = min(first + BATCH, total) - 1
        for i = first, last do
            -- name, texture, count, quality, usable, level, levelType, minBid, minIncrement, buyout, bid,
            -- highBidder, bidder, owner, ownerFull, saleStatus, itemID, hasAllInfo
            local ok, _, _, count, quality, usable, _, _, _, _, buyout, _, _, _, owner, _, _, id, loaded =
                pcall(A.GetReplicateItemInfo, i)
            if ok and type(id) == "number" and type(buyout) == "number" and buyout > 0 and owner ~= me and ML.Flip then
                ML.Flip.Note(id, buyout, count)
            end
            if ok and type(id) == "number" and type(buyout) == "number" and buyout > 0
                and (count or 1) <= 1 and (quality or 0) >= 2 and usable ~= false and owner ~= me and isGear(id) then
                local link = loaded and read(A.GetReplicateItemLink, i)
                if not (link and keep(link, buyout)) then
                    pending[#pending + 1] = { i, buyout }
                    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
                end
            end
        end
        progress = total > 0 and floor((last + 1) / total * 100) or 100
        if last + 1 < total then
            after(0, function() part(last + 1) end)
        elseif #pending > 0 then
            after(1, function() again(1) end)
        else
            finish()
        end
    end
    part(0)
end
Gear._read = readList   -- tests

-- Starts a full scan. Returns the line to show the player.
function Gear.Scan(atAuctionHouse)
    local A = C_AuctionHouse
    if not (A and A.ReplicateItems and A.GetNumReplicateItems and A.GetReplicateItemInfo) then
        return "This game version has no full Auction House list."
    end
    if state ~= "idle" then return "Still scanning. Wait a few seconds." end
    if not atAuctionHouse then return "Go to the Auction House, then start the full scan." end
    local left = Gear.CooldownLeft()
    if left > 0 then
        return ("The game allows one full scan every 15 minutes. Try again in %s."):format(span(left))
    end
    wornGear()   -- remember your own gear before the game loads thousands of other items
    ML.db.ledgerGearAsked = now()
    state, progress = "waiting", 0
    token = token + 1
    local mine = token
    if not pcall(A.ReplicateItems) then
        state = "idle"
        return "The scan could not start. Try again."
    end
    -- no answer: another addon scanned in the last 15 minutes. Read what the game still has, if anything.
    after(20, function()
        if state ~= "waiting" or mine ~= token then return end
        if (read(A.GetNumReplicateItems) or 0) > 0 then
            readList()
        else
            state = "idle"
            changed("The Auction House did not answer. Another addon may have scanned in the last 15 minutes.")
        end
    end)
    if state == "idle" then return end   -- already answered: the "done" line is on screen
    return "Asking the Auction House for its full list. This takes a few seconds."
end

local events = CreateFrame("Frame")
pcall(events.RegisterEvent, events, "REPLICATE_ITEM_LIST_UPDATE")
pcall(events.RegisterEvent, events, "AUCTION_HOUSE_CLOSED")
local lastRead = 0
events:SetScript("OnEvent", function(_, event)
    if not ML.db then return end
    if event == "AUCTION_HOUSE_CLOSED" then
        if state ~= "idle" then
            token = token + 1
            state = "idle"
            changed("Auction House closed. The gear scan stopped.")
        end
        return
    end
    -- our scan, or another addon's full scan: read it once (the game can send this more than once)
    if state == "reading" or (state == "idle" and now() - lastRead < 10) then return end
    -- another addon's scan is only read once you have used the Gear tab
    if state == "idle" and type(ML.db.ledgerGear) ~= "table" and type(ML.db.ledgerFlip) ~= "table" then return end
    if state == "idle" then ML.db.ledgerGearAsked = now() end
    lastRead = now()
    local ok, problem = pcall(readList)
    if not ok then
        state = "idle"
        changed("The gear scan hit a problem: " .. tostring(problem))
    end
end)

-- ---------- 4. What beats your worn gear ----------

-- Slots where every item has Armor or damage. No stats there means the game has not told us yet.
local ALWAYS_STATS = { [1] = true, [3] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true,
    [10] = true, [15] = true, [16] = true }

-- Stats of your own gear, kept once read. A full scan loads thousands of items, and for a while after it
-- the game can stop answering for the pieces you wear (seen in game: every slot but one came back blank).
local wornSeen = {}

-- What is in each slot now: { link, name, stats, where, unknown }.
-- unknown = the game gave no stats for a worn item. That slot is skipped: it is never treated as empty.
wornGear = function()
    local worn = {}
    for slot = 1, 18 do
        local link = read(GetInventoryItemLink, "player", slot)
        if type(link) == "string" then
            local name = read((C_Item and C_Item.GetItemInfo) or GetItemInfo, link)
            local stats, where = statsOf(link), equipSlot(link)
            if stats and next(stats) then
                wornSeen[link] = stats
            elseif wornSeen[link] then
                stats = wornSeen[link]
            end
            worn[slot] = { link = link, name = type(name) == "string" and name or link:match("%[(.-)%]") or "?",
                stats = stats or {}, where = where,
                unknown = stats == nil or (next(stats) == nil and (ALWAYS_STATS[slot] or where == "INVTYPE_SHIELD")) }
        else
            -- something is worn there, but the game gave no link for it yet
            local id = read(GetInventoryItemID, "player", slot)
            if type(id) == "number" and id > 0 then
                worn[slot] = { name = "item " .. id, stats = {}, unknown = true }
                if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
            end
        end
    end
    return worn
end

-- May this kind of item go in your hands at all, with what you wield now and your role?
local function handsFit(where, role, worn)
    local main, off = worn[16], worn[17]
    if where == "INVTYPE_2HWEAPON" then return role ~= "tank" end
    if where == "INVTYPE_WEAPONOFFHAND" then
        return off ~= nil and (off.where == "INVTYPE_WEAPON" or off.where == "INVTYPE_WEAPONOFFHAND")
    end
    if where == "INVTYPE_SHIELD" or where == "INVTYPE_HOLDABLE" then
        if main and main.where == "INVTYPE_2HWEAPON" and role ~= "tank" then return false end
        if where == "INVTYPE_HOLDABLE" then return role == "caster" or role == "healer" end
    end
    return true
end

-- "+311 Armor": the one change that counts most for your role.
local function biggestGain(role, stats, old, noDamage)
    local best, text = 0, ""
    for key, amount in pairs(stats) do
        local more = amount - (old[key] or 0)
        local value = more * worth(role, key)
        if noDamage and key:upper():find("DAMAGE_PER_SECOND", 1, true) then value = 0 end
        if value > best then
            local label = statName(key)
            -- the column is narrow: a long plain-letter name is cut short (the hover has the full name)
            if #label > 14 and not label:find("[\128-\255]") then label = label:sub(1, 13) .. "." end
            best, text = value, ((more % 1 == 0) and "+%d %s" or "+%.1f %s"):format(more, label)
        end
    end
    return text, best
end

function Gear.MaxPrice()
    local picked = ML.db and ML.db.ledgerGearMax
    for _, price in ipairs(PRICES) do
        if price == picked then return price end
    end
    return 10000
end

-- What the game said about each scanned item, kept for this scan: key -> { name, where, needs, stats }.
-- Asking again on every redraw was slow, and it pushed your own gear out of the game's item memory.
local seen, seenFor = {}, nil

-- Every upgrade under the price limit, in no order. Also returns how many items the game is still
-- loading, the names of the slots skipped because your worn piece could not be read, and what you wear.
function Gear.Upgrades()
    local data = saved()
    if not data then return {}, 0, {}, {} end
    if seenFor ~= data then seen, seenFor = {}, data end
    local role = Gear.Role()
    local worn, top, level = wornGear(), Gear.MaxPrice(), read(UnitLevel, "player") or 60
    local _, class = read(UnitClass, "player")
    local stick = class ~= "HUNTER"   -- a bow or gun counts for its stats only
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local found, byName, loading = {}, {}, 0
    local unread, unreadList = {}, {}
    for key, price in pairs(data.items) do
        local known = seen[key]
        if not known then
            local where = equipSlot(key)
            if where then
                local name, _, _, _, needs = read(info, key)
                local stats = type(name) == "string" and statsOf(key)
                if stats then
                    known = { name = name, where = where, needs = needs, stats = stats }
                    seen[key] = known
                else
                    loading = loading + 1
                end
            end
        end
        if known and type(price) == "number" and (top == 0 or price <= top) and handsFit(known.where, role, worn)
            and (type(known.needs) ~= "number" or known.needs <= level) then
            local where, name, stats = known.where, known.name, known.stats
            local noDamage = stick and RANGED[where] or false
            -- compare with the weaker of the slots it can go in (two rings, two trinkets)
            local slot, old, oldScore, skip
            for _, candidate in ipairs(SLOTS[where]) do
                local has = worn[candidate]
                if has and has.unknown then skip = candidate end
                local value = has and score(role, has.stats, noDamage) or 0
                if not oldScore or value < oldScore then slot, old, oldScore = candidate, has, value end
            end
            -- a two-hander replaces both hands
            if where == "INVTYPE_2HWEAPON" and worn[17] then
                if worn[17].unknown then skip = 17 end
                oldScore = oldScore + score(role, worn[17].stats)
            end
            local mine = score(role, stats, noDamage)
            if skip then
                local group = SLOT_NAME[skip]
                if not unread[group] then unread[group] = true; unreadList[#unreadList + 1] = group end
            elseif mine > oldScore and mine - oldScore >= max(1, oldScore * 0.03) then
                local best, bestValue = biggestGain(role, stats, old and old.stats or {}, noDamage)
                local entry = { key = key, name = name, price = price, slot = slot, gain = mine - oldScore,
                    percent = oldScore > 0 and floor((mine - oldScore) / oldScore * 100 + 0.5) or nil,
                    old = old, best = best, bestValue = bestValue }
                -- the same item and bonus can be listed under two keys: keep the cheaper one
                local same = byName[name]
                if not same then
                    byName[name] = entry
                    found[#found + 1] = entry
                elseif price < same.price then
                    same.key, same.price = key, price
                end
            end
        end
    end
    table.sort(unreadList)
    return found, loading, unreadList, worn
end

-- ---------- 5. Sorting ----------
-- Click a column title to sort by it. Click it again to flip the order.

local SORT_COLUMN = { action = "gain", auction = "price", vendor = "best" }
local SORT_WORD = { gain = "how much better", price = "price", best = "top gain" }

local function sortState()
    local saved = ML.db and ML.db.ledgerGearSort
    if type(saved) == "table" and SORT_WORD[saved.by] then return saved.by, saved.high == true end
    return "gain", true
end

-- column = "action", "auction" or "vendor" (the window's own names). Returns the line to show.
function Gear.SortBy(column)
    local by, high = sortState()
    local new = SORT_COLUMN[column]
    if not new then return end
    if new == by then high = not high else high = new ~= "price" end   -- a new column starts the useful way round
    ML.db.ledgerGearSort = { by = new, high = high }
    return ("Sorted by %s, %s first."):format(SORT_WORD[new], high and "highest" or "lowest")
end

-- The three column titles; the one sorted by says which way.
function Gear.Headers()
    local by, high = sortState()
    local mark = high and " (high)" or " (low)"
    return "Better by" .. (by == "gain" and mark or ""), "Price" .. (by == "price" and mark or ""),
        "Top gain" .. (by == "best" and mark or "")
end

local function sorted(list)
    local by, high = sortState()
    local field = by == "gain" and "gain" or by == "price" and "price" or "bestValue"
    table.sort(list, function(a, b)
        local x, y = a[field] or 0, b[field] or 0
        if x ~= y then
            if high then return x > y end
            return x < y
        end
        if a.price ~= b.price then return a.price < b.price end
        return a.name < b.name
    end)
    return list
end

-- ---------- 6. Rows for the Gear tab ----------

local retries, retryStarted, retryWaiting = 0, 0, false

local function scanButton()
    if state == "waiting" then return "Scanning" end
    if state == "reading" then return ("Reading %d%%"):format(progress) end
    return "Scan Gear"
end
Gear.ScanLabel = scanButton

function Gear.Lines()
    local data = saved()
    local role, roles = Gear.Role()
    local top = Gear.MaxPrice()
    local count = 0
    for _ in pairs(data and data.items or {}) do count = count + 1 end
    local lines = {
        { page = "Gear", gear = "scan", wide = true, button = scanButton(),
            title = data and ("Prices from %s ago. %d pieces you can wear."):format(span(now() - data.at), count)
                or "No gear prices yet. Click Scan Gear at the Auction House." },
        { page = "Gear", gear = "price", wide = true, button = "Change",
            title = "Highest price: " .. (top == 0 and "any" or money(top)) },
    }
    if #roles > 1 then
        lines[#lines + 1] = { page = "Gear", gear = "role", wide = true, button = "Change",
            title = "Judged for: " .. ROLE_NAME[role] }
    end
    if not data then
        wornGear()   -- remember your own gear now, before a scan fills the game's item memory
        return lines
    end
    local upgrades, loading, unread, worn = Gear.Upgrades()
    if #unread > 0 then
        -- never call a slot empty because the game was slow to describe what is in it
        lines[#lines + 1] = { title = "Could not read your worn "
            .. (#unread > 3 and (#unread .. " slots") or table.concat(unread, ", ")) .. " yet. Skipped for now." }
        loading = loading + 1
    end
    -- one block per slot, in the order you wear them, so a slot's choices sit together
    local groups = {}
    for _, entry in ipairs(upgrades) do
        local group = SLOT_NAME[entry.slot]
        groups[group] = groups[group] or {}
        table.insert(groups[group], entry)
    end
    local shown = 0
    for _, group in ipairs(GROUP_ORDER) do
        local list = groups[group]
        if list and shown < MOST then
            local names = {}
            for slot = 1, 18 do
                if SLOT_NAME[slot] == group and worn[slot] then names[#names + 1] = worn[slot].name end
            end
            lines[#lines + 1] = { gearHead = group, title = "|cffd9b56b" .. group .. "|r   "
                .. (#names > 0 and ("you wear " .. table.concat(names, " and ")) or "nothing worn") }
            for i, entry in ipairs(sorted(list)) do
                if i > PER_SLOT or shown >= MOST then break end
                shown = shown + 1
                lines[#lines + 1] = { page = "Gear", gear = "item", title = entry.name, name = entry.name,
                    link = entry.key, old = entry.old, button = "Search", group = group,
                    action = entry.percent and ("+" .. min(entry.percent, 999) .. "%") or "New",
                    auction = money(entry.price), vendor = entry.best }
            end
        end
    end
    if #upgrades == 0 then
        lines[#lines + 1] = { title = loading > 0 and "Loading item details from the game..."
            or top == 0 and "Nothing on the Auction House beats what you wear."
            or ("No upgrade up to %s. Raise the highest price, or scan again later."):format(money(top)) }
    end
    -- item details still coming from the game: draw again every 2 seconds, for about half a minute
    if loading == 0 then
        retries = 0
    elseif not retryWaiting then
        if now() - retryStarted > 60 then retries, retryStarted = 0, now() end
        if retries < 15 then
            retries = retries + 1
            retryWaiting = true
            after(2, function()
                retryWaiting = false
                changed()
            end)
        end
    end
    return lines
end

-- A row's button was clicked. Returns the line to show the player.
function Gear.Act(entry, atAuctionHouse)
    if entry.gear == "scan" then return Gear.Scan(atAuctionHouse) end
    if entry.gear == "price" then
        local current = Gear.MaxPrice()
        for i, price in ipairs(PRICES) do
            if price == current then ML.db.ledgerGearMax = PRICES[i % #PRICES + 1]; break end
        end
        return "Highest price changed."
    end
    if entry.gear == "role" then
        local role, roles = Gear.Role()
        for i, name in ipairs(roles) do
            if name == role then
                ML.db.ledgerGearRole = type(ML.db.ledgerGearRole) == "table" and ML.db.ledgerGearRole or {}
                ML.db.ledgerGearRole[charKey() or "?"] = roles[i % #roles + 1]
                break
            end
        end
        return "Now judged for: " .. ROLE_NAME[Gear.Role()] .. "."
    end
    if entry.gear == "item" then
        -- fill in the game's own search box; you look and buy yourself
        local frame = _G.AuctionHouseFrame
        local bar = frame and frame.IsShown and frame:IsShown() and frame.SearchBar
        if bar and bar.SearchBox and bar.SearchBox.SetText and bar.StartSearch then
            local ok = pcall(function()
                if frame.SetDisplayMode and AuctionHouseFrameDisplayMode then
                    frame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
                end
                bar.SearchBox:SetText(entry.name)
                bar:StartSearch()
            end)
            if ok then return "Searching for " .. entry.name .. ". Check the name and price before you buy." end
        end
        return "At the Auction House, search for: " .. entry.name
    end
end

-- Hover: the item's own tooltip, then how it compares with what you wear.
function Gear.Tooltip(owner, entry)
    if entry.gear ~= "item" or not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
    if not pcall(GameTooltip.SetHyperlink, GameTooltip, entry.link) then
        GameTooltip:SetText(entry.name, 1, 1, 1)
    end
    local role = Gear.Role()
    local stats, old = statsOf(entry.link) or {}, entry.old and entry.old.stats or {}
    local keys, seen = {}, {}
    for key in pairs(stats) do keys[#keys + 1] = key; seen[key] = true end
    for key in pairs(old) do
        if not seen[key] then keys[#keys + 1] = key end
    end
    table.sort(keys)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(entry.old and ("Against your " .. entry.old.name .. ":") or "That slot is empty now.", 1, 0.82, 0, true)
    for _, key in ipairs(keys) do
        local more = (stats[key] or 0) - (old[key] or 0)
        if more ~= 0 then
            local label = statName(key)
            local counts = worth(role, key) > 0
            local good = more > 0
            GameTooltip:AddLine(((more % 1 == 0) and "%+d %s" or "%+.1f %s"):format(more, label),
                counts and (good and 0.25 or 1) or 0.6, counts and (good and 0.88 or 0.3) or 0.6, counts and 0.25 or 0.6)
        end
    end
    GameTooltip:AddLine("Grey lines do not count for " .. ROLE_NAME[role] .. ".", 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
end

-- Lines for the Debug window: what the Gear tab sees on you right now.
function Gear.DebugLines()
    local role = Gear.Role()
    local data, count = saved(), 0
    for _ in pairs(data and data.items or {}) do count = count + 1 end
    local known = 0
    for _ in pairs(seen) do known = known + 1 end
    local lines = { ("Gear: role=%s state=%s saved=%d max=%d described=%d retries=%d"):format(role, state, count,
        Gear.MaxPrice(), known, retries) }
    local worn = wornGear()
    local _, class = read(UnitClass, "player")
    local stick = class ~= "HUNTER"
    for slot = 1, 18 do
        local has = worn[slot]
        if has then
            local stats = 0
            for _ in pairs(has.stats) do stats = stats + 1 end
            lines[#lines + 1] = ("Gear worn %d %s: %s | link=%s stats=%d score=%.1f%s"):format(slot,
                SLOT_NAME[slot] or "?", has.name, has.link and "yes" or "NO", stats,
                score(role, has.stats, slot == 18 and stick), has.unknown and " UNREAD" or "")
        elseif SLOT_NAME[slot] then
            lines[#lines + 1] = ("Gear worn %d %s: empty"):format(slot, SLOT_NAME[slot])
        end
    end
    return lines
end
