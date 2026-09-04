class_name Tuning
extends RefCounted

# ============================================================================
# GAME NUMBERS — one source of truth
#
# Every number here changes how the game FEELS. They live in sim/ because they
# are rules, not presentation. The view layer reads them so it can display them
# honestly (a cast-time readout that disagrees with the real cast time is worse
# than no readout at all).
#
# Rule: if a number appears in more than one file, it belongs here.
# ============================================================================

# --- casting ----------------------------------------------------------------

# Slow motion while the rune queue is open, decaying back to normal:
#     scale(t) = 1.0 - (1.0 - SLOW_MIN) * exp(-t / SLOW_TAU)
#
# SLOW_TAU is the single most important feel knob in the game: it decides how
# much real thinking time the player gets before the world speeds back up.
#   0.4 = tighter, punishes hesitation harder
#   0.8 = roomier, more forgiving
const SLOW_MIN := 0.12
const SLOW_TAU := 0.6

# Time to release a spell, in normal time — this is the cost that makes short
# chants worth discovering.
#     cast_time = CAST_BASE + CAST_PER_RUNE * rune_count
const CAST_BASE := 0.25
const CAST_PER_RUNE := 0.25

const MAX_RUNES := 4


# --- movement ---------------------------------------------------------------

# The enemy MUST be slower than the player, otherwise kiting is impossible and
# the whole casting window stops mattering. Aim for 60-75% of player speed.
const PLAYER_SPEED := 4.0
const ENEMY_SPEED := 2.6


# --- combat -----------------------------------------------------------------

const INVULNERABLE_TIME := 0.5

# Wet: how much it slows, and for how long. This is the reward for discovering
# that damage is exposure time — too small and the discovery feels flat, too
# large and fire alone becomes pointless.
const WET_FACTOR := 0.5
const WET_DURATION := 2.0
