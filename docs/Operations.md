# Operations and release checks

## Data ownership
The server owns purchases, income, training, slot state and profile snapshots. DataDelve is an editor for inspecting data; it is not the saving system. Live profiles use FootballerProfiles_v1, keyed by UserId. Studio tests are explicitly memory-only and do not prove published persistence. Do not enable Studio API access against production stores merely to silence imported-asset errors.

## Premium setup
Create a pass for this published experience in Creator Hub, set it for sale, and enter its ID in Config.Treadmills.Catalog's Celestial entry. No purchase of somebody else's pass is required. Planned price is 4,999 Robux. Keep GamePassId=0 until the owner is ready. The server checks the actual sale/price and verifies pass ownership. No pass sales or actual Robux-spend totals are claimed by this implementation.

## Private report review
Use owner-only Creator Hub/DataDelve access to FootballerReports_v1. Open Inbox_YYYYMMDD (UTC). Review New records by timestamp, category, sender and target UserIds. Check available evidence before acting; a report alone is not proof. Record Status, reviewer UserId, review time and resolution in the private record after review. Do not expose inboxes to ordinary players or publish report details. Roblox Report Abuse remains the route for platform safety violations. This is a manual process; there is no automated ban system or free-text communication channel.

## Required before public release
- Test real leave/rejoin persistence, failed loads/saves, session contention and shutdown with a separate test data-store name.
- Implement durable item IDs/ownership transactions and test stealing against both servers crashing. Current per-profile snapshots are not atomic across owners and can duplicate/lose a stolen item after a crash.
- Test two real players, phone/tablet controls, treadmill footprints and final character appearance with the 3D viewport visible.
- Review/fix imported SocialInteractions, Dialogue System, HD Admin and leaderboard dependencies; a Creator Store listing is not a safety certificate.
- Tune prices, earnings, training and travel time with players. Current prices are provisional.
- Verify the premium pass setup in a published test experience before enabling its button.

## Currency
Cash is capped at 9e15; points at 1e15. Current display suffixes are K/M/B/T/Qa/Qi. Larger ranges need a deliberate large-number representation, not an extra suffix on imprecise numbers.
