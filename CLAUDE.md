# Steal a Footballer — project rules
- Lean code: no dead code, no unused functions/variables, no duplicated logic. Reuse helpers. Smallest clear solution wins, but stay readable (no code golf).
- Before adding code, check whether existing code can be extended instead.
- After each task, remove anything your change made unused.
- Server-authoritative: the server validates all damage, drops, carrying, placing, stealing and cash. Clients only send requests.
- All tuning values live in ReplicatedStorage/Shared/Config. No magic numbers in scripts.
- Must work on phone, tablet and PC (no mouse-only input).
- In-game names only. Never use real footballer names anywhere.
- Never run git commands. I handle git myself.
- Always show a plan and wait for my OK before building.

# Game overview
"Steal a Footballer" — a Roblox steal-and-collect game (like Steal a Brainrot / Steal an Egg) with original cartoon football-legend characters.

Core loop:
- Players mine cubes with a pickaxe in a 12-stage hallway (Stage 1 nearest the bases, 80 studs wide, stages grow 40→150 studs long).
- A broken cube drops a character card of that stage's tier; the player carries it back (slower for higher tiers) and places it in one of 10 slots on their plot. Placed characters earn cash per second.
- Tiers: Stages 1-2 Common, 3-4 Rare, 5-7 Epic, 8-9 Legendary, 10-11 Mythic, 12 GOAT. GOAT cubes only spawn as a timed Stage 12 event. A random Golden Cube (stages 4-11) drops one tier higher, capped at Mythic.
- 6 plots per server, max 6 players.

Built so far: greybox world, cubes, pickaxe, cards, carrying, plots, slots, cash, Golden Cube.
In progress / next: stealing from other plots, base lock, stage guards, then a CharacterFactory that builds 100 characters from data recipes on a blank R15 block rig.
Later: saving (DataStore), shop, game passes, Stage 12 GOAT bosses.

Characters: all names are invented in-game names (e.g. Crimson Demon, Pocket Storm). Never use real player names, faces, crests, kits, numbers or logos.

Studio work goes through the Roblox Studio MCP. Cloud sessions can only edit code in src/.
