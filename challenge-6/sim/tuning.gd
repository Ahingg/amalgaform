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

# world data
const ARENA_W := 20
const ARENA_H := 12

# round manager
const WAVE_COUNT := 4
const WAVE_GAP := 3.0
const ENEMIES_BASE := 2.0

# --- casting ----------------------------------------------------------------

# Slow motion while the rune queue is open, decaying back to normal:
#     scale(t) = 1.0 - (1.0 - SLOW_MIN) * exp(-t / SLOW_TAU)
#
# SLOW_TAU is the single most important feel knob in the game: it decides how
# much real thinking time the player gets before the world speeds back up.
#   0.4 = tighter, punishes hesitation harder
#   0.8 = roomier, more forgiving
const SLOW_MIN := 0.12
const SLOW_TAU := 0.8

# Time to release a spell, in normal time — this is the cost that makes short
# chants worth discovering.
#     cast_time = CAST_BASE + CAST_PER_RUNE * rune_count
const CAST_BASE := 0.1
const CAST_PER_RUNE := 0.35

const MAX_RUNES := 4

# Power is split by how many DIFFERENT runes are in the queue, never by how many
# runes there are:
#     power[rune] = count[rune] / pow(kinds, SPREAD)
#
# Splitting by total count would make ["Fire","Fire"] produce two half-strength
# payloads that merge back into one full-strength one — repeats would be
# pointless, and half the grammar dies.
#
# SPREAD is the knob: 0 = mixing is free, 1 = full penalty for breadth.
# Using a power (not a subtraction) means it can never reach zero, so a
# three-kind spell is weak rather than silent.
const SPREAD := 0.5


# --- spell shapes -----------------------------------------------------------

const BULLET_SPEED := 8.0
const BULLET_LIFETIME := 1.2
const BULLET_SIZE := 0.6

# The water ball needs no aim point: its range is decided by the world — it
# bursts on contact, or when its lifetime runs out.
const WATERBALL_SPEED := 7.0
const WATERBALL_LIFETIME := 1.0
const WATERBALL_SIZE := 0.6

const PUDDLE_SIZE := 2.0
const PUDDLE_LIFETIME := 3.0

# A box, not a cone: Helper.overlap is axis-aligned, so a cone at 37 degrees
# cannot be expressed. Debt, deliberately taken.
const BURST_SIZE := 3.0
const BURST_LIFETIME := 0.3
const BURST_OFFSET := 1.5

const SPAWN_OFFSET := 0.7


# --- payload base values (before the SPREAD split) --------------------------

const FIRE_DAMAGE := 10.0
const KNOCKBACK_STRENGTH := 6.0
const KNOCKBACK_DURATION := 0.3


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
const WET_SLOW := 0.5
const WET_DURATION := 2.0

const MELEE_DAMAGE := 20.0

const SPELL_HOLD_BASE_MODIFIER := 0.08
