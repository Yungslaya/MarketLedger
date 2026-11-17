# Market Ledger changes

Every released version, newest first.

## 1.4.4 (2026-11-17)

- **Live price on Prepare now works on every item.** On some servers Prepare couldn't look items up and quietly used your scan price instead, so some listings weren't the lowest. It now uses the same lookup as Scan Bags.
- If WoW's sell form takes fewer than planned (for example 20 of 24), Market Ledger says so: post, then click Prepare again for the rest.

Type `/reload` after updating.

## 1.4.3 (2026-11-17)

- **Sell the whole stack plan at once.** Trade goods (ore, stone, cloth and so on) now post your full amount across all your bag stacks, instead of stopping at 20.
- **Live price after posting.** Right after a scan or a post the Auction House is busy for a moment. Prepare now waits for it instead of quietly using your scan price, and tells you if it had to.
- The Debug window now shows which Market Ledger version you have.

Type `/reload` after updating.

## 1.4.2 (2026-11-17)

- **Undercut on Prepare.** Prepare now lists just under the lowest other listing so yours sells first. The new button next to Scale picks how much: smallest (1 copper for trade goods, 1 silver for other items), 1%, 2%, 5%, or match the lowest. Troll listings are still ignored, and with no other listings your scan price is used.
- Prices are easier to read: 8s 64c instead of 0g 08s 64c.
- A Prepare button no longer keeps saying Create Auction after you prepare a different item.
- Long messages at the top of the window stay inside the window.

Type `/reload` after updating.

## 1.4.1 (2026-11-17)

- **Prepare ignores troll listings.** If the only other listing is a silly price (way above what the item usually sells for), Prepare keeps your scan price and tells you, instead of filling the sell form with it and saving it as your price.

Type `/reload` after updating.

## 1.4.0 (2026-11-17)

- **Price fix.** Items sold in stacks (like Upper Map Fragment) were shown far too cheap, so Market Ledger could tell you to vendor something worth silver. Run **Scan Bags** again after updating to replace the wrong prices.
- **Live price on Prepare.** When you click Prepare, Market Ledger checks the lowest price other players are asking right now and fills the sell form with it, so an older scan no longer makes you undercut or overprice. Your own listings are skipped. If the live price is less than half your scan price, the scan price is kept and you get a warning to check first.

Type `/reload` after updating.

## 1.3.9 (2026-11-17)

- **Auction House fixes.** After you post a whole stack, the game's sell form could still point at the empty bag slot and show errors ("GetAvailablePostCount" or "GetCurrentItemLevel") on the next Prepare or scan. Market Ledger now clears that leftover first.
- **Update messages** now only come from real CurseForge releases, so you never hear about a version that isn't out yet.

Type `/reload` after updating.

## 1.3.8 (2026-11-17)

- **Prices in ProfessionPal.** With ProfessionPal 1.3.9, the Farm Planner shows the Auction House asking price for the material you pick, once Market Ledger has scanned it. Materials you haven't scanned show "No price data".
- Prices saved before this version show up there after your next **Scan Bags**.
- **Clear Prices** also clears the prices shown in ProfessionPal.

Type `/reload` after updating.

## 1.3.7 (2026-11-17)

- **Prices in ProfessionPal.** With ProfessionPal 1.3.9 or newer, Farm Planner shows an Auction House price estimate for the material you select, once Market Ledger has scanned that material. Materials you haven't scanned show "No price data".
- Prices saved before this version show there after your next **Scan Bags**.
- **Clear Prices** also clears the prices shown in ProfessionPal.

Type `/reload` after updating.

## 1.3.6 (2026-11-16)

- **Update notices.** If someone in your guild or group has a newer version, you get one message saying an update is out in the CurseForge app. Only version numbers are shared, and nothing is sent in combat.

Fully restart WoW after updating (a new file was added).

## 1.3.5 (2026-11-16)

- **Sell, craft or smelt: checked every scan.** Every recipe you know that uses something in your bags is now compared with selling the materials, for every profession: smelting ore, potions from herbs, cloth, leather and more.
- Each one says **craft it**, **small gain**, **sell the materials** or **price unknown**. Before, smelting was hidden unless it beat selling the ore by a lot.
- The Craft tab shows all of them, and AI Help is asked to give a sell-or-craft answer for each. Only the "craft it" ones set your materials aside.
- **Better farm zones.** With ProfessionPal 1.3.7, Farm picks use the best zones from Wowhead's and Icy Veins' farming guides, marked **(BEST)**. Mithril now points to The Hinterlands instead of Desolace.
- **Stuck Auction House.** If WoW's Auction House stops answering, the scan now says so after 20 seconds and tells you to log out and back in, instead of just waiting.

Type `/reload` after updating. Run Scan Bags again to price the bars and potions you could make.

## 1.3.4 (2026-11-16)

- **Sell what you craft without scanning again.** The AI Help report now says what each recipe makes, like Smelt Iron making Iron Bar, along with the price your scan found for it.
- A plan can sell the crafted item right away: after the Craft step, an Auction step for the bars or stones gets a **Prepare** button as soon as they are in your bags, with the price already filled in.
- If the AI forgets to add that sell step, Market Ledger adds it for you, at the scanned price.
- The optional Companion app reads plans the same way.

Type `/reload` after updating. Get a fresh plan from AI Help to use this.

## 1.3.3 (2026-11-15)

- Fake listings are ignored. If the cheapest listing is more than 10 times the usual price (like Fish Oil at 100 gold), Market Ledger treats the price as unknown instead of telling you to list there.
- These show on the Keep tab as "Only a fake listing", and AI Help lists them separately.
- Fake prices no longer push up an item's usual price, including any already saved.

Type `/reload` after updating.

## 1.3.2 (2026-11-15)

- The "Enter this price" message now points to `/ledgerdebug`, the right command.
- The Debug window says plainly how to copy its text.

Type `/reload` after updating.

## 1.3.1 (2026-11-14)



- Scans move on as results arrive, match item variants more reliably, and report incomplete results clearly.

- Busy scans preserve their place. Click **Scan Bags** to resume a paused scan.

- New **Debug** button for recent scan and selling events.

- Advice exports compare vendor value with an optional TSM minimum-buyout reference after the estimated auction cut. They also show the minimum ask needed to beat the vendor. Cached references stay separate from live scan prices; deposits are excluded.

- Advice instructions ask for an actual comparison and put PLAN steps in one easy-to-copy code block.

- Expanded [setup guide](https://github.com/Yungslaya/MarketLedger#readme) for every tab, TSM, AI plans, the Companion and farm routes.



#### Try it



1. Type `/reload`. Open the Auction House, then `/ledger`, and click **Scan Bags**.

2. Optional: enable the Forever-compatible [TradeSkillMaster](https://www.tradeskillmaster.com/) addons and configure its desktop app for your realm. Available price/sales context is read automatically. Stop other active auction scans or click TSM's **WoW UI** if the AH remains busy.

3. Use **AI Help → Copy for AI**, paste into your preferred chat, then return the PLAN through **Paste reply → Save plan**. No API key or extra app is needed for this route. Review each sale before clicking.

4. With [ProfessionPal](https://github.com/Yungslaya/ProfessionPal), use **Farm → Map**. Add [Shortest Path Forever](https://github.com/cjber/shortest-path-forever) for travel routes. **Next** skips a spot; **Clear** or **Stop route** ends guidance.



Prices are asking prices or labeled references, not guaranteed sales. Map spots are possible spawns. You still sell, craft, travel and gather yourself.



The optional Companion is included below as `MarketLedgerCompanion.pyw`. Close it before updating, then reopen it. [Companion instructions](https://github.com/Yungslaya/MarketLedger/tree/main/Companion).



Thanks to the **TradeSkillMaster team**, **cjber and the Shortest Path Forever contributors**, and **Wowhead's database contributors** for their tools, APIs and location data. See [credits and links](https://github.com/Yungslaya/MarketLedger#credits).

## 1.3.0 (2026-11-14)

Market Ledger used to be part of ProfessionPal. It is now its own addon. Your saved prices, blacklist and settings move over by themselves the first time it loads. Open it with `/ledger`.

- **AI Help with no extra app.** Copy your scan as text, paste it into any AI chat, and paste the reply back. The Plan tab lists the picks and ticks them off as you sell.
- **Price history.** Every scan saves one price per item per day. After a second day, hovering a row shows its usual price and how today compares.
- **Real sales numbers** when [TradeSkillMaster](https://tradeskillmaster.com) and its desktop app are installed: what an item sells for, how often a listing sells, and how many sell a day.
- **Farm tab** when [ProfessionPal](https://github.com/Yungslaya/ProfessionPal) is installed: what to gather for gold at your skill and level, with **Map** buttons.
- **Craft rows make the whole amount.** One click opens the crafting window, the next makes them all.

Every auction, sale and craft is still one click from you. Scan prices are asking prices, not sales.

ProfessionPal, TradeSkillMaster and Shortest Path Forever are all optional. `MarketLedgerCompanion.pyw` below is an optional desktop app (needs Python 3) for people who use an API key or an AI tool on their PC.

This is a new addon. **Fully restart WoW** after installing.
