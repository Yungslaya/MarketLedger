# Market Ledger Companion

An optional Windows app for **Market Ledger**. You do not need it: the addon's **AI Help** window does the same job with copy and paste inside the game.

The Companion is for people who would rather hand the scan over as a file: one click with an API key, or an AI tool on your PC that reads and writes files.

## Get it

[Download MarketLedgerCompanion.pyw](https://github.com/Yungslaya/MarketLedger/releases/latest/download/MarketLedgerCompanion.pyw) and save it anywhere. You also need [Python 3](https://www.python.org/downloads/), which is free. Nothing else.

## Use it

1. In WoW, at the Auction House: open Market Ledger (`/ledger`), click **Scan Bags**, then type `/reload`. That writes your scan to disk.
2. Open the Companion. It finds your scan by itself.
3. Click **Copy for AI chat**, paste into any AI chat and send it. Copy the whole reply and click **Paste AI reply**. Or, with an API key, click **Ask now**.
4. Type `/reload` in WoW and open the **Plan** tab.

The gold line at the top of the Companion always says what to do next.

## Choose the way you want to ask

- **Normal ChatGPT or Claude chat:** use **Copy for AI chat**, paste into the chat you already use, then return with **Paste AI reply**. No symlink or API key is needed.
- **API:** select a provider, enter a model supported by that provider and your API key, then click **Ask now**. The provider may charge for the request. A chat subscription is not a key entered into this box.
- **Claude Code:** this button prepares a review folder for the separate Claude Code tool. It does not turn the regular Claude desktop chat into a file reader. If Claude Code is not installed, use the copy-and-paste route above.

Scan while TSM's data is available if you want that context in the report. The Companion receives only what the addon exported; it cannot fill in an unknown live auction price by itself. For Farm steps with map routes, keep ProfessionPal and optionally Shortest Path Forever installed in WoW. See [the main guide](../README.md) for setup, credits and troubleshooting.

Close this app before replacing it with an update. Reopen it and use **Load latest scan** after saving a newer scan from WoW.

## Files and data

- Reads `WTF\Account\...\SavedVariables\MarketLedger.lua` (your saved scan).
- Writes `Interface\AddOns\MarketLedger\LedgerPlan.lua` (the plan).
- Sends the scan (item names, counts and prices) to an AI only when you click **Ask now**. Your API key is never saved.

It never touches the running game. You still click every auction, sale and craft yourself.

Each plan line is checked against your scan before it is saved: unknown items are left out, and no step sells more than you have spare.
