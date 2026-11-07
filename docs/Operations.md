# Operations and release checks

## Data ownership
The server owns purchases, income, training, slot state and profile snapshots. DataDelve is an editor for inspecting data; it is not the saving system. Live profiles use FootballerProfiles_v1, keyed by UserId. Studio tests are explicitly memory-only and do not prove published persistence. Do not enable Studio API access against production stores merely to silence imported-asset errors.

## Premium setup (Celestial game pass)
Create a pass for this published experience in Creator Hub, set it for sale, and paste its ID into Config.Treadmills.Catalog's Celestial entry (GamePassId; 0 = not available). The price shown in the Treadmills menu is the live Roblox price, fetched by the server (refreshed every 5 minutes and again at every tap); if the price cannot be read or the pass is off sale the row says "Price unavailable" and its button is disabled. No purchase of somebody else's pass is required. Inside Studio, Config.Purchases.StudioTestMode simulates the pass (test pass ID, price, ownership, outcome) and never calls Marketplace; live servers always use the real Marketplace. Before enabling it publicly, buy the pass once from a second account in a published test experience and check the log (below).

## Premium setup (2x Cash game pass)
Create a second pass the same way and paste its ID into Config.CashPass.GamePassId (0 = not available). It permanently doubles the cash a player earns from their plot (Config.CashPass.Multiplier; daily and index rewards are not doubled). It has its own row in the Treadmills menu with the live Roblox price, and uses the same purchase, log, regrant and refund-strike flow as Celestial (key "DoubleCash"). Verify it with a real purchase from a second account before enabling it.

## Premium setup (premium tools)
Create one game pass per premium tool the same way and paste each ID into its Config.PremiumTools entry (GamePassId; 0 = not available): Hammer, Marrow Reaper, Drill, Gilded Auger, Robot Arm Drill. The Laser Drill is shown as Coming soon and has no pass. Each uses the same purchase, live-price, log, regrant and refund-strike flow as Celestial (key = the tool Id) and appears in the Tools menu under PREMIUM TOOLS. A premium tool's power is always the player's best owned cash tool times its Multiplier (at most 1.5), so no price you set can break the economy. Verify each pass with a real purchase from a second account before enabling it.

## Robux purchase safety
- Code: Purchases.luau (prompts, ownership, refund strikes, developer-product receipts) and PurchaseLog.luau. Every Robux event is written to the FootballerPurchaseLog_v1 DataStore, key U_<UserId>, newest 200 events per player: prompt shown/blocked (with reason), prompt finished, ownership check on join, granted, grant failed, refund strike, revoked, receipts and support actions, each with UserId, pass/product, price, time and server JobId. Writes are buffered (flushed every 30s, on leave and on shutdown).
- Kid safety rules: a Robux button only opens Roblox's own purchase window after an explicit tap and always shows the exact live price; nothing prompts on join; no countdowns, pressure popups or discount banners; at most one prompt per 10 seconds per player; owned items are never re-prompted. Never add paid random items; if one is ever added it must show its odds before the purchase.
- Ownership is stored in the profile (Entitlements). On join an owned pass the profile lacks is re-granted (logged as Regrant). A refund is only acted on after two confirmed "not owned" results on separate joins at least one hour apart (Config.Purchases.RevokeStrikes / RevokeStrikeGapSeconds); each strike is logged, an API error never counts, and a confirmed "owned" clears the strikes.
- Developer products: none exist. If one is added, put it in Config.Purchases.Products and test it with a published test product; ProcessReceipt applies the grant and records the receipt ID together and persists both with ONE profile save, returns PurchaseGranted only after that save succeeded, refuses a receipt already being processed, never grants twice and returns NotProcessedYet on any failure.
- Support tool (owner only, Studio command bar): put tools/PurchaseSupport.luau at ServerStorage.PurchaseSupport, enable Studio access to API services for the experience, then S.History(userId) lists the log and S.Regrant(userId, "Celestial", "reason") restores an item a verified buyer is missing. It refuses an empty reason, an unknown item, a missing profile and a player with an active session, and logs the operator and reason. Do not use it to grant free items.
- Refunds are handled by Roblox customer support, not by the game. Our job is the log and, for a verified buyer, the regrant.
## Private report review
Use owner-only Creator Hub/DataDelve access to FootballerReports_v1. Open Inbox_YYYYMMDD (UTC). Review New records by timestamp, category, sender and target UserIds. Check available evidence before acting; a report alone is not proof. Record Status, reviewer UserId, review time and resolution in the private record after review. Do not expose inboxes to ordinary players or publish report details. Roblox Report Abuse remains the route for platform safety violations. This is a manual process; there is no automated ban system or free-text communication channel.

## Required before public release
- Test real leave/rejoin persistence, failed loads/saves, session contention and shutdown with a separate test data-store name.
- Implement durable item IDs/ownership transactions and test stealing against both servers crashing. Current per-profile snapshots are not atomic across owners and can duplicate/lose a stolen item after a crash.
- Test two real players, phone/tablet controls, treadmill footprints and final character appearance with the 3D viewport visible.
- Review/fix imported SocialInteractions, Dialogue System, HD Admin and leaderboard dependencies; a Creator Store listing is not a safety certificate.
- Tune prices, earnings, training and travel time with players. Current prices are provisional.
- Verify the premium pass in a published test experience with a real purchase from a second account (prompt, grant, log, rejoin, refund strikes) before enabling it; Studio test mode proves the logic, not Roblox's behaviour.

## Currency
Cash is capped at 9e15; points at 1e15. Current display suffixes are K/M/B/T/Qa/Qi. Larger ranges need a deliberate large-number representation, not an extra suffix on imprecise numbers.
