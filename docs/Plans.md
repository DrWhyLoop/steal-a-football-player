# Plans

Approved plans are kept here so they are never lost. Implementation history goes to docs/History.md.

## Section 3: Upgrades shop (approved 2026-11-13, built the same day)
Lives inside the "More" menu of the right-hand nav dock. Permanent upgrades, kept on rebirth, saved in PlayerData as `Upgrades = {id = level}`.
All numbers live in `Config.Upgrades`. Server validates every purchase (id, level, cost, balance, rate limit).

| Upgrade | Levels | Effect per level | Currency | Costs |
|---|---|---|---|---|
| Income | 10 | +2.5% plot income (cap +25%) | Quest Tokens | 20, 30, 45, 65, 90, 120, 160, 210, 270, 350 |
| Speed gain | 10 | +5% Speed Points gain | Cash | 1e6, 4e6, 1.5e7, 5e7, 1.5e8, 4e8, 1.2e9, 4e9, 1.2e10, 4e10 |
| Collect pad range | 5 | +1.5 studs | Quest Tokens | 15, 25, 40, 60, 90 |
| Cage luck | 5 | +0.1 luck (max +0.5) | Quest Tokens | 30, 50, 80, 120, 180 |

- Cage luck adds to the rolled luck; total luck is clamped at `Config.Luck.LuckyMax` (4), so it never pushes a Lucky Cage past 4.
- Extra slots: dropped.
- Hooks: CashService (income), TreadmillService (speed gain), SlotService (pad range), CardService via PlayerReward.Luck (luck).
- Files: Server/UpgradeShop.luau, Client/UpgradeUI.luau (built on UIKit.Panel).
- RULE: Quest Tokens are never sold for Robux, directly or indirectly (see CLAUDE.md and Config.Quests).
- Sim (tools/economy/luck.py stage12): see docs/History.md for the Stage 12 numbers.

## Nav dock (approved 2026-11-13)
Four main buttons (Tools, Quests, Rebirth, Index) plus "More" (Trails, Treadmills, Feedback, Upgrades). The label stays "Tools".

## Stage looks (Part 1, approved and built 2026-11-13)
Per-stage floor/wall materials and colours, decor, kept plants, client lighting mood, empty ServerStorage.StageProps folders and tools/PlaceStageProps.luau. See docs/History.md.

## Part 2 (approved 2026-11-13, NOT built yet; build only after the next OK)
- **Collection sets:** one set per tier (Common 1-2, Rare 3-4, Epic 5-7, Legendary 8-9, Mythic 10-11, GOAT 12): own every roster footballer of the tier in Gold or better. Bonus to plot income: 1 / 1.5 / 2 / 3 / 4 / 5 % (total 16.5%). A Diamond-or-better star per tier pays half of that (total 8.25%). Combined cap +25%. Sim: tools/economy/sets.py (even if all sets were instant, Stage 12 arrives at 3.53 h; the Gold requirement makes the real effect smaller).
- **Twists (server-validated, phone-safe), checked with tools/economy/escape_twists.py (well-played escape B >= 97%, random-cage escape A >= 60%, recommended speed, 4,000 trips each):**
  - 3 Sandlot gusts: every 15 s, 1.5 s push, 50% slow. A 69.8% / B 98.3%.
  - 4 Quarry minecarts: 3 lanes, 1 s stun, hit chance A 6% / B 1.2% per crossing. A 77.5% / B 98.9%.
  - 7 Rust Harbor containers: path +4% (the proposed +8% gave A 56.7%, below the floor). A 61.4% / B 98.6%.
  - 8 Ember lava: 12% of the floor, 35% slow (kept at 35%). A 65.3% / B 99.0%.
  - 9 Frost ice: 15% of the floor, 15% slow/grip loss. A 62.3% / B 98.8%.
  - 11 Storm lightning: one strike per 8 s on a carrier, undodged strike drops the card. A 79.0% / B 99.2%.
  - Other stages (1, 2, 5, 6, 10, 12) keep their baseline escape (A 65-100%, B 98.2-100%); their twists (speed strips, clover luck, lantern blackout, mist, neon boost strips, Golden Hour) do not slow carriers and are not in the sim.
- **First-arrival reward:** once per account (profile field, never reset by a rebirth): big banner, sound (verify it loads), and cash = 90 s of that stage's tier income per second.
