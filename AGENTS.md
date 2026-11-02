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
