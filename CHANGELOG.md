# Market Ledger changes

Every released version, newest first.

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
