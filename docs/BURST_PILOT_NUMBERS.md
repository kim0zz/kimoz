# Burst pilot v0.2

> Historical three-hybrid pilot. Current full-roster parameters and A/B meanings are documented in FULL_ROSTER_SKILLS.md and GAME_DESIGN §47. These recorded results still describe the original pilot only.

## Selected production numbers

Variant B is the production default for this pilot. The three units keep their recurring cooldowns and shift damage out of basics into a stronger first skill cast.

| Hybrid | Basic damage / interval | Skill damage | First skill delay | Recurring cooldown |
| --- | ---: | ---: | ---: | ---: |
| Eagle–Hippo | 6 / 0.5 s | 80 dive + 2 s stun | 5 s | 12 s |
| Monkey–Hippo | 6 / 0.5 s | 65 banana + 1.25 s stun | 4.5 s | 10 s |
| Bear–Cheetah | 6 / 0.5 s | 3 × 24 cone hits | 3.5 s | 7 s |

The old-number comparison (variant A) uses the previous live values and the shared 2 s initial delay: Eagle–Hippo 9.2 / 0.5 s and 40 damage; Monkey–Hippo 9.7 / 0.5 s and 27 damage; Bear–Cheetah 9.7 / 0.5 s and 3 × 14 damage. Its recurring cooldowns are 12, 10, and 7 s respectively.

`CombatVariants.definitions("A"|"B")` supplies deep-cloned unit overrides. Variant A restores the old numbers; variant B reads the current pilot Resources. Simulation setup reads each skill's `initial_cooldown`. The explicit `startup_skill_delay` option still overrides that per-skill setting for tests. Passive thorns remain ready at tick 0.

## Calibration coverage

Both variants were run through 378 deterministic scenarios:

- 48 single-unit cases per hybrid: all eight lvl1 opponents, three layouts, both team orientations.
- 72 pair cases per hybrid: all 36 unordered lvl1 pairs, both orientations.
- 6 trio cases per hybrid: three representative lvl1 trios, both orientations.

All 48 single cases per hybrid were wins in both variants. Each hybrid both won and lost pair cases, preserving counterexamples. Variant B pair results were Eagle–Hippo 58 wins / 14 losses, Monkey–Hippo 66 / 6, and Bear–Cheetah 54 / 18. In the sampled trios, Eagle–Hippo won 2 and lost 4; Monkey–Hippo lost all 6; Bear–Cheetah lost all 6. Thus the pilot retained pair counters and had two lvl2 wins against trios overall, without treating trio wins as a guarantee.

No pilot died before its first cast in either variant (0 of 126 appearances per hybrid). Median first cast times in B were 5.00 s, 4.50 s, and 3.50 s, matching each definition's deadline.

## Damage and cast telemetry

Aggregate results across each hybrid's 126 appearances:

| Hybrid | Variant | Casts | Total damage | Skill damage | Skill share |
| --- | --- | ---: | ---: | ---: | ---: |
| Eagle–Hippo | A | 162 | 21,563 | 6,126 | 28.4% |
| Eagle–Hippo | B | 156 | 20,980 | 10,578 | 50.4% |
| Monkey–Hippo | A | 234 | 21,708 | 5,689 | 26.2% |
| Monkey–Hippo | B | 216 | 21,714 | 11,466 | 52.8% |
| Bear–Cheetah | A | 264 | 21,530 | 9,036 | 42.0% |
| Bear–Cheetah | B | 254 | 20,920 | 13,630 | 65.2% |

Totals are applied damage across the bounded scenarios, not a population DPS estimate. B makes the skill hit a much larger share of damage while total damage remains close to A. Cast counts are lower because the first cast is delayed and more power is delivered per use.

## Verification

- `tests/burst_pilot_tests.gd`: 13 checks passed, covering A/B values, cloned-resource immutability, per-skill startup deadlines, default 2 s behavior, explicit override, passive thorns, and recurring Eagle–Hippo cooldown.
- `scripts/testing/burst_pilot_runner.gd`: A and B each completed 378 scenarios with no unfinished scenario. These targeted pilot suites cover the lvl1 single, pair-counter, and representative trio requirements. The broader full lvl2 suite remains a separate project-level check.

## Post-selection peer and team check

After selecting B, a separate 84-case subset checked the three pilots against all 12 lvl2 hybrids in both orientations (72 duels), plus six mixed-team rosters in both orientations (12 matches). All cases completed, and all six mixed-team pairs produced mirrored outcomes.

Across the 24 pilot-vs-hybrid rows per unit, outcomes were Eagle–Hippo 6 wins / 16 losses / 2 draws, Monkey–Hippo 6 / 16 / 2, and Bear–Cheetah 12 / 10 / 2. These are diagnostic results for the sampled opponents, not a 50% target. They do not call for automatic buffs: a unit can contribute as a guarded carry, create an early-impact window, or provide value to a drafted team even when it loses a solo duel. The mixed teams produced wins for both sides across the six rosters, with every mirrored result matching.

Machine-readable results: `reports/burst_pilot/burst_A_final.json`, `reports/burst_pilot/burst_B_candidate1.json`, and the extracted 84-case `reports/burst_pilot/burst_B_final_coverage.json`. The original A/B reports carry the then-current `combat-v0.3-hybrids` label; the later `combat-v0.4-burst-pilot` change only updates that rules-version label and did not change combat behavior.

### Timing, duration, survival, and skill contribution

| Hybrid | Variant | Median fight duration | Actual first cast range | Survived | Applied skill damage / cast |
| --- | --- | ---: | ---: | ---: | ---: |
| Eagle–Hippo | A | 10.98 s | 2.00–2.00 s | 114 / 126 | 37.81 |
| Eagle–Hippo | B | 11.98 s | 5.00–5.48 s | 108 / 126 | 67.81 |
| Monkey–Hippo | A | 15.40 s | 2.00–3.63 s | 116 / 126 | 24.31 |
| Monkey–Hippo | B | 15.38 s | 4.50–4.50 s | 114 / 126 | 53.08 |
| Bear–Cheetah | A | 13.03 s | 2.00–9.72 s | 114 / 126 | 34.23 |
| Bear–Cheetah | B | 12.05 s | 3.50–9.72 s | 102 / 126 | 53.66 |

Actual first-cast time can exceed the initial cooldown when the target is out of skill range. The deadline marks readiness; it does not guarantee that an attack can begin or land at that exact time. Skill damage per cast is applied damage over the run divided by cast count, so misses, multi-target hits, and overkill affect the average.

The 84-case post-selection peer/team subset is the bounded final pilot check for singles, pair counters, and representative trios above plus lvl2 peers and mirrored team fights. It does not claim every lvl2 pairing or every possible roster is balanced. See [BURST_PILOT_PLAYTEST.md](BURST_PILOT_PLAYTEST.md) for the lab controls and playtest notes.
