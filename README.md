# Market Ledger

See what to auction, vendor, craft, keep or farm in WoW: Forever. Open `/ledger` or the **Market Ledger** button in ProfessionPal.

[Download](https://github.com/Yungslaya/MarketLedger/releases/latest/download/MarketLedger.zip) · [Latest changes](https://github.com/Yungslaya/MarketLedger/releases/latest)

Also on CurseForge. Version 1.3.7 · for WoW: Forever (interface 16001)

## What's new

- **1.3.9:** Fixes two Auction House errors after posting a whole stack. Type `/reload` after updating.
- **1.3.8:** ProfessionPal 1.3.9 shows your scanned Auction House prices in its Farm Planner. Run Scan Bags after updating. Type `/reload` after updating.

- **1.3.6:** A message tells you when a newer version is out in the CurseForge app. Fully restart WoW after updating (a new file was added).
- **1.3.5:** Every scan compares selling your materials with crafting or smelting them, for every profession. Farm picks use the guides' best zones. Type `/reload` after updating.
- **1.3.4:** Plans can sell what you craft, like Iron Bars, at the scanned price without scanning again. Type `/reload` after updating.
- **1.3.3:** Fake listings (like Fish Oil at 100 gold) are ignored instead of treated as the price. Type `/reload` after updating.
- **1.3.2:** Small fixes to two in-game messages. Type `/reload` after updating.
- **1.3.1:** Faster scans that wait when the Auction House is busy. A **Debug** button. The AI Help report compares vendor and auction prices for you.

Used the version built into ProfessionPal? Install this addon and fully restart WoW once. Your saved prices, blacklist and settings move over. [All changes](CHANGELOG.md)

## Start here

1. Install Market Ledger. No other addon is required for bag scanning and selling.
2. Open the Auction House, then `/ledger`.
3. Set **Sell up to** to the percentage of spare stock you want to offer. ProfessionPal reserves are protected when installed.
4. Click **Scan Bags** and wait for **Scan complete**. This searches items relevant to your bags and available craft/farm picks, not every auction in the house.
5. Pick a tab and review the quantities before selling.

The stock limit belongs to the current plan. Selling half should not keep halving the remainder. Starting a new scan starts a new stock plan based on your current bags.

Drag the window to move it, drag its bottom-right corner to resize it, and use its percentage button to change scale. **Clear Prices** clears saved scan prices. Prices survive reloads and logouts.

## Use each tab

| Tab | What to do |
| --- | --- |
| Auction | Click **Prepare**. Review quantity and unit price in WoW's selling window, then use **Create Auction** and any confirmation WoW presents. |
| Vendor | Visit a merchant and click **Sell** for the row. Soulbound bag items with a sell value can appear here. |
| Craft | With ProfessionPal, review the recipe and amount. **Craft it** opens the profession and selects the recipe; another click crafts when materials and the station are available. Missing-material guidance shows what you still need. |
| Keep | Read why an item is reserved, protected or missing a reliable price. |
| Farm | With ProfessionPal, choose a gatherable item and click **Map** for its suggested zone. |
| Blacklist | Right-click a bag-item row to exclude it from selling recommendations. Use this tab to restore it. |
| Plan | Follow imported advice in order. Completed sale/craft quantities are tracked as your bags change. |

Active quest items, blacklisted items and known profession reserves are protected. Blacklist gear or supplies you personally want to keep. Each sale or craft needs your click.

## Use ChatGPT, Claude or another AI chat

No API key is required for this route.

1. Finish **Scan Bags**.
2. Open **AI Help**, click **Copy for AI**, and press Ctrl+C.
3. Paste into your preferred chat. The report explains stock limits, price information and the required plan format.
4. Copy the returned PLAN code block. Click **Paste reply** in Market Ledger, paste it, then **Save plan**.
5. Open **Plan** and check each proposed action before clicking it.

You can also paste the whole response. Names must match the report, quantities must stay within spare stock, and Auction prices are copper **per item**. The importer checks supported steps against the report; advice can still be wrong. After a rescan or major bag changes, request a fresh plan.

The report includes item names, counts, recipes and prices. You choose which chat receives it. The addon itself does not connect to an AI service.

## Add TradeSkillMaster for price context

1. Install the WoW: Forever-compatible [TradeSkillMaster addons](https://www.tradeskillmaster.com/) and set up their desktop app for your realm using TSM's instructions.
2. Let its data update, then start WoW with TSM enabled.
3. Run a Market Ledger scan. Hover an item or use **Copy for AI** to see available TSM data. No separate linking step is needed.

Your scan shows **asking prices**, not completed sales. The usual-price trend comes from earlier scans. TSM adds regional sale-price/rate/volume context when available; some price fields can fall back to market averages. These references do not promise your next sale.

Vendor comparisons can include TSM's cached realm minimum buyout for the item's full link. Its age is unknown here. It never silently replaces an unknown scan price. Comparisons assume a 5% auction cut and exclude deposits: review the actual selling window, especially for tiny gains.

**AH busy?** Stop another active auction scan, or click **WoW UI** in TSM, then return to Market Ledger. A paused scan resumes with **Scan Bags**. TSM can stay loaded, preserving its price context. Market Ledger does not disable TSM or automatically cancel its work.

## Farm routes with ProfessionPal and Shortest Path Forever

1. Install [ProfessionPal](https://github.com/Yungslaya/ProfessionPal). Learn Mining, Herbalism or Skinning for relevant Farm picks.
2. Optionally install [Shortest Path Forever](https://github.com/cjber/shortest-path-forever). Fully restart WoW after adding addons.
3. Open **Farm**, or a Farm step in **Plan**, and click **Map**.
4. ProfessionPal opens the zone and gathering spots. With Shortest Path Forever, it requests a road/travel route through that addon's public API. Otherwise it uses a normal map pin.
5. Follow it yourself. **Next** skips a spot; **Clear** on the map or **Stop route** in ProfessionPal ends the guide.

Spots show possible spawns, not currently available nodes. Consider demand and travel time as well as asking price. Nothing moves or gathers for you.

## Troubleshooting

- Stop other auction scans before resuming a paused scan.
- Click **Debug**, copy the report, and describe what you clicked and what happened. It contains scan/selling events, not chat history.
- Unknown prices stay unknown. Rescan rather than treating them as zero.
- For crafting, check materials, selected profession and the required anvil, fire or other station.
- TSM is optional. Craft/Farm integration needs ProfessionPal; road routing also needs Shortest Path Forever.

## Credits

- Price and sales numbers from [TradeSkillMaster](https://www.tradeskillmaster.com/) when you have it (optional).
- Road routes by [Shortest Path Forever](https://github.com/cjber/shortest-path-forever) by cjber (optional).
- Gathering spots from the [Wowhead WoW: Forever database](https://www.wowhead.com/forever), through ProfessionPal.
- Best farming zones from Wowhead's farming guides and Icy Veins' WoW: Forever leveling guides, through ProfessionPal.

None of their code is included.
