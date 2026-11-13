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
