# Market Ledger changes

Every released version, newest first.

## 1.7.0 (2026-11-22)

- **New Gear tab: cheap upgrades.** At the Auction House, click **Scan Gear**. Market Ledger reads the whole Auction House once and lists the gear that beats what you are wearing, up to a highest price you pick. Each bonus ("of the Bear", "of the Owl") has its own price and is judged by itself.
- **Judged for your role.** Tank, Damage, Spell damage or Healer. A shield on your arm starts you as Tank. Click **Change** to switch.
- **One block per slot.** Head, Chest, Legs and the rest each get their own block, with what you wear now at the top.
- **See what you gain.** Each row shows how much better it is, the price and the top gain. Hover a row for every stat change against your worn piece.
- **Click a column title to sort.** Better by, Price or Top gain. Click again to flip the order.
- **Search, don't hunt.** The **Search** button puts the item's name in the Auction House search box. You look and buy yourself.
- **New Flip tab: buy cheap, resell.** The same full scan finds items listed well under what they usually sell for. Each row shows what to buy, the price to pay, the resell price and the profit after the 5% cut. It needs TradeSkillMaster's sale prices, and it only picks items that sell often.
- **Check before you buy.** Click **Check** and Market Ledger looks at the live price. **Buy** never pays more than the price it checked. Check also works the profit out again from the live listings and refuses a buy that would no longer make money. Stackable goods (ore, cloth) show the real total first, then you click **Confirm**. Nothing is ever bought on its own.
- **See your flip profit.** Market Ledger writes down what each flip cost. When you take the money from an "Auction successful" mail, it matches the sale to what you paid. The Flip tab shows what you spent, what came back after the cut, your profit and what is still unsold. Click **Details** for each item.
- **Flips between scans.** With no full scan in the last 3 hours, the Flip tab uses TradeSkillMaster's saved lowest prices instead, marked **(TSM)**. Their age is unknown, so the live check decides.
- **Slow flips.** Pricey items that sell now and then, which bots skip. They need a bigger price gap and at least 1g profit, only the cheapest one is bought, and they stay on the list for a day. They show under their own line, marked **(slow)**, and may take a few days to sell.
- **Buy fast flips right away.** Right after a full scan, a chat line says how many flips were found. Fast flips show first, because they sell out in minutes.
- **Flips in AI Help.** The report lists the best flips, and the AI can add **Buy** steps to your plan. They show on the Plan tab with the same Check and Buy buttons. The AI is told to plan slow flips and to have you buy fast ones in the Flip tab right away.
- **Friendlier AI replies.** The AI now starts with a friendly line and gives an estimate of your total profit.
- The game allows one full scan every 15 minutes, for all addons together.

Fully restart WoW after updating (new files were added).

## 1.6.1 (2026-11-21)

- **Worn gear in the report.** Copy for AI now adds what your character is wearing: each slot with its item, item level and stats, plus your level and class. The AI can then tell you when a bag item is better than what you have on, so you equip it and don't sell it. Worn gear is never offered for sale.

Type `/reload` after updating.

## 1.6.0 (2026-11-21)

- **New look.** The window has a stone frame with gold corners, new fonts and red gold-edged buttons. Our other addons now look the same.
- **Price history no longer starts over.** The game sometimes gives addons a blank realm name. Market Ledger then saved prices in a new, empty spot, so every item showed "1 day scanned" and no usual price. It now keeps using your realm, and puts back anything saved in the wrong spot.
- **What's new window.** After an update, one window shows what changed, with a tab for each of our addons you have. Type `/ledger news` to see it again.

Fully restart WoW after updating (new files were added).

## 1.5.4 (2026-11-20)

- **Books you can learn are kept.** A soulbound pet Grimoire or class book was put on the Vendor tab (a Warlock's Grimoire of Sacrifice, for example). It now shows on the Keep tab with **Learn it**. A book you already know can still go to the vendor, and your own Always vendor rule still wins.

Type `/reload` after updating.

## 1.5.3 (2026-11-20)

- **Cheap gear keeps its price.** Gear can only be listed in whole silver, so undercutting a 2s item dropped it to 1s. When the undercut would cut more than 10%, Market Ledger now matches the lowest price instead.
- **No more "Sell form changed".** WoW's sell window puts in its own price a few seconds after Prepare. Create Auction now puts your amount and price back and posts.

Type `/reload` after updating.

## 1.5.2 (2026-11-18)

- **Farm picks for your faction.** The Farm tab and the report sent Alliance characters to Horde starting zones (Tirisfal Glades for Peacebloom, Durotar for Silverleaf). With ProfessionPal installed, farm picks now use your faction's zones and never pick the other faction's starting zones.

Type `/reload` after updating.

## 1.5.1 (2026-11-18)

- **Prepare follows the real price.** When a plan price was a spike (Iron Bar planned at 6s37 while bars were listing at 3s), Prepare kept the plan price. It now compares a big drop with the item's usual price and lists at the live price.
- **Spikes in a scan are checked twice.** If a scan answer comes back far over the item's usual price, Market Ledger asks the Auction House again and keeps the lower answer. Craft advice uses the usual price when an output price still looks like a spike.
- **Correct deposit.** The deposit estimate was about 3 times too high. It is now 20% of the vendor price, as the Auction House charges, and it learns the exact rate from your own postings.

Type `/reload` after updating.

## 1.5.0 (2026-11-18)

- **New look.** Market Ledger now looks like a big WoW tooltip, the same as ProfessionPal, Savings Pal and Battle Buddy.
- **Deposit shown.** Prepare tells you the deposit and that you get it back if the item sells. Point at a row to see its 24 hour deposit. A row says **Small gain** when one unsold listing would cost more than you gain over vendoring.
- **Your own rules.** Right-click a row to pick Always keep, Always vendor or Always auction for that item. Clear my rule undoes it. Hide this item is in the same menu.
- **Prices from TSM or Auctionator.** When your scan has no price for an item, TradeSkillMaster or Auctionator can fill it in, and the row says which one. Your own scan price is never replaced. The **Other prices** button at the top picks Both, TSM, Auctionator or Off. Market Ledger works without either addon.
- **Price on tooltips.** Point at any item to see your scan price and how old it is. Type `/ledger tooltip` to turn it off.
- **Disenchant answer.** If you are an enchanter and have TradeSkillMaster, an item says **Disenchant** on the Keep tab when TSM values its materials above both the auction and the vendor price. The number is TSM's estimate. You disenchant it yourself.
- **Five more languages.** Market Ledger now shows its tabs, buttons, answers and messages in German, French, Spanish, Russian and Simplified Chinese when your game uses that language. Item names come from the game. The report for the AI chat stays in English. Only English has been tested in the game. If something looks wrong in your language, please report it.

Asking prices are not sales.

Type `/reload` after updating.

## 1.4.5 (2026-11-17)

- **Reagent bag and quiver.** WoW's sell form only posts trade goods from your normal bags. Prepare now picks a stack from a normal bag first, posts what's there, and tells you how many more are in your reagent bag or quiver so you can move them over and sell them too.

Type `/reload` after updating.

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
