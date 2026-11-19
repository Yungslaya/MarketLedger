--[[ Market Ledger - other languages

  English is written in the code. When the game runs in another language, text made with the
  window kit passes through ML.T() on its way to the screen:
    1. a whole line that has a translation is swapped for it;
    2. "Auction ×5" style lines translate the word and keep the number;
    3. a line built from parts ("Plan: 2 of 5 done") is matched by a pattern and rebuilt;
    4. anything else stays in English.
  Item names come from the game. The report for the AI chat always stays in English.

  A language file adds its lines with ML:AddLocale("deDE", { lines }, { patterns }).
]]
local _, ML = ...

local locale = (GetLocale and GetLocale()) or "enUS"
if locale == "esMX" then locale = "esES" end
ML.locale = locale
ML.LOCALES = {}

local lines, patterns

function ML:AddLocale(code, exact, shaped)
    ML.LOCALES[code] = { exact = exact or {}, patterns = shaped or {} }
    if code == ML.locale then lines, patterns = ML.LOCALES[code].exact, ML.LOCALES[code].patterns end
end

-- For tests: switch language after loading.
function ML:UseLocale(code)
    ML.locale = code
    local l = ML.LOCALES[code]
    lines, patterns = l and l.exact or nil, l and l.patterns or nil
    ML.tCache = {}
end

ML.tCache = {}
local function translate(text)
    local hit = lines[text]
    if hit then return hit end
    local lead, core, tail = text:match("^(%s*)(.-)([%s:]*)$")
    if core ~= "" and core ~= text and lines[core] then return lead .. lines[core] .. tail end
    -- "Auction ×5", "Vendor ×2"
    local word, count = text:match("^(.-) ×(%d+)$")
    if word and lines[word] then return lines[word] .. " ×" .. count end
    for i = 1, #patterns do
        local rule = patterns[i]
        if text:find(rule[1]) then return (text:gsub(rule[1], rule[2])) end
    end
    return nil
end

function ML.T(text)
    if not lines or type(text) ~= "string" or text == "" then return text end
    if issecretvalue and issecretvalue(text) then return text end
    local cached = ML.tCache[text]
    if cached ~= nil then return cached or text end
    local out = translate(text)
    ML.tCache[text] = out or false
    return out or text
end

local function localize(fs)
    if not fs or rawget(fs, "mlLocalized") then return fs end
    rawset(fs, "mlLocalized", true)
    local set, setf = fs.SetText, fs.SetFormattedText
    if set then
        fs.SetText = function(self, text, ...) return set(self, ML.T(text), ...) end
    end
    if set and setf then
        fs.SetFormattedText = function(self, format, ...)
            local ok, text = pcall(string.format, format, ...)
            if ok then return set(self, ML.T(text)) end
            return setf(self, format, ...)
        end
    end
    return fs
end
ML.LocalizeText = localize

-- Every text and button made with the kit from here on is translated by itself. With
-- ProfessionPal installed the kit is ProfessionPal's; its own lines are handled there.
local baseText, baseButton = ML.UIText, ML.UIButton
if baseText then
    ML.UIText = function(...) return localize(baseText(...)) end
end
if baseButton then
    ML.UIButton = function(parent, label, ...)
        local button = baseButton(parent, ML.T(label), ...)
        local set = button and button.SetText
        if set then button.SetText = function(self, text) return set(self, ML.T(text)) end end
        return button
    end
end

-- Without ProfessionPal: languages the Latin fonts cannot draw use the game's own font.
if not ML.Pal and (locale == "ruRU" or locale == "zhCN" or locale == "zhTW" or locale == "koKR")
    and type(STANDARD_TEXT_FONT) == "string" then
    ML.FONT, ML.TITLE_FONT = STANDARD_TEXT_FONT, STANDARD_TEXT_FONT
end
