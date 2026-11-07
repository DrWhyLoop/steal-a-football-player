# Codex task list (from MrWheels, 2026-11-07)

Read `CLAUDE.md` first: it is the single source of truth for rules and game context. All its rules apply here:
server-authoritative, all tuning in `ReplicatedStorage/Shared/Config`, lean code, phone/tablet/PC input, no git, plan before building.

Work through the tasks **in this order**. For each task: verify the current code and Studio state, write a short plan, build,
play-test through the Roblox Studio MCP, check Output, confirm every changed Studio script matches `src` exactly,
and add an honest entry to `CLAUDE.md`. Stop after each task and report what changed, how it was verified, and what was not verified.

---

## 0. Security check on newly supplied assets (do this first)

The user placed new items in the place: `JSONDX`, `pet egrew`, `animationeditor`, `custom_walkin` (2 scripts),
a punch animation model ("punch-in animation"), `figure animations` (3 scripts), and classic Roblox animations.
Imported models in this place have repeatedly contained malware (fake "Disconnected / 0x89AF2 / Recover" popup,
`Runtime` / `ScreenBuilder` / `RuntimeInput` / `InputBinding` objects, and `require(<id>)` loaders).

- Scan all of these for those signatures, `require(`, `loadstring`, `getfenv`, `HttpService`, `TeleportService`, `MarketplaceService`.
- Report every script: name, path, size and what it does. Delete malicious ones.
- Do **not** run `animationeditor` as code. Roblox Studio has a built-in Animation Editor (Avatar tab), so a model with that name containing scripts is suspicious.
- From the animation models, extract the Animation IDs / KeyframeSequences. Test each in Play: keep only the ones that actually load and play. Delete the rest. Never keep the imported scripts; rebuild any needed behaviour in our own `src`.
- `pet egrew` is a paid asset: do not use it.

## 1. Premium tools do no damage (bug) + "no one-hit" rule

The user reports **no premium tool breaks eggs** (Hammer, Bone Scythe / its in-game name, Drill, Gilded Auger, Robot Arm Drill, Laser Drill).
Cash tools work (Default Axe = power 1, Hatchet, Miner Pick, ... up to Prism Pick = 90.12M power).

- Reproduce in Studio test mode: grant each premium tool, equip it, hit a Stage 1 and a Stage 2 egg, and log the damage the server applies. Find the root cause and fix it.
- Each premium tool must show a clear Power value in the Tools shop, like the cash tools do. Keep the existing balance rule (power = best owned cash tool × the tool's multiplier, 1.2 to 1.5) and display it as e.g. "Power 120 (1.2× your best tool)".
- **Hard rule: no premium tool may ever break any egg in one hit.** Cap a premium tool's damage per hit at MaxHP / 5 of that egg (Config `PremiumMinHits = 5`). Premium tools make progress faster; they never skip the game.
- Test: every premium tool on eggs from Stage 1, 5 and 12, including Titanic. Report hits needed.

## 2. Egg HP bar visibility (based on the player, not the camera)

Currently the HP bar disappears when the user zooms the camera out, even while standing next to the egg.
BillboardGui `MaxDistance` is measured from the camera, which is the cause.

- Show the bar when the player's character (HumanoidRootPart) is within ~15 studs of the egg (Config), or while the player is hitting it, regardless of camera zoom.
- Hide it otherwise. Client-side, cheap: update a few times per second, not every frame per egg.

## 3. Character size from egg size + better reveal animation

- Bug: every hatched character is the same size. The egg size (Tiny, Small, Normal, Big, Huge, Titanic) must scale the character (scale values in Config), including carried, placed and saved copies.
- Reveal: after the egg grows and pops, the character should **spin while growing** to its final size (client-side tween, about 0.8 s), with the existing sparkle and beam. If `JSONDX` turns out to be a usable animation or effect that loads, use it; otherwise build it ourselves.

## 4. Monsters: punch, fall and wander (using the supplied animations)

The rules are already implemented and must stay: a stage's monsters only chase a player carrying an unsecured character taken from **that** stage, and only inside that stage. They never leave their own stage. With no thief, they patrol and wander around their whole stage.

- Use the supplied `custom_walkin` walk and the classic/figure animations for wandering, where they load (from task 0). Playback must match ground speed, with no sliding or floating.
- When a monster catches a thief: play the **punch** animation, then the player **falls to the ground** (brief fall/ragdoll-style state, about 1.5 s, then stands up), and drops the character. No flying away without a hit.
- Re-check that nobody is knocked back when not carrying a character from that stage.

## 5. Leaderboards

- Global leaderboards (OrderedDataStore) for **Most Cash**, **Most Play Time** and **Highest Speed**. No Robux-spent board.
- Show them on in-world boards near the plaza (top 10, formatted with NumberFormat) and refresh every ~60 s, within DataStore limits.
- Studio memory mode must not write live data (follow the existing PlayerData pattern).

## 6. Trail shop

- New "Trails" shop next to Tools and Treadmills: cash-bought trails (visual Trail effect behind the player) with a speed bonus that multiplies training gain or movement (propose which, then build).
- Use only our own effects, no imported scripts.
- Re-run the economy simulation in `tools/economy/` with trails included and keep Stage 12 at 3-4 hours. Show the price/bonus table before writing it to Config.

---

When everything is done: one summary of all tasks, what is verified, what is not, and what needs the user's manual check (2-player test, phone).
