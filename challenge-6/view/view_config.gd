class_name ViewConfig
extends RefCounted

# ============================================================================
# VIEW CONSTANTS — one source of truth for everything view/ draws with
#
# Component names are kept as raw strings here rather than pointing at Comp.
# That is deliberate: view/ must never be the reason sim/ fails to parse, and
# a renaming spree in sim should degrade the picture, not kill the game.
# The cost is that this list has to be kept in step by hand — cheap, because
# these names change far less often than the numbers in sim/tuning.gd.
#
# Numbers that affect gameplay do NOT live here. They live in Tuning.
# ============================================================================

# --- component names ---------------------------------------------------------

const POSITION := "Position"
const SIZE := "Size"
const HEALTH := "Health"
const DELAY := "Delay"
const INVULNERABLE := "Invulnerable"
const PLAYER := "Player"
const MOVE_INTENT := "MoveIntent"
const FACING := "Facing"
const CAST_QUEUE := "CastQueue"
const CAST_RELEASE := "CastRelease"

const FIRE := "Fire"
const WATER := "Water"
const WIND := "Wind"


# --- palette -----------------------------------------------------------------

# Order matters: the first component an entity has wins the colour.
const COLORS := {
	"Player": Color(0.95, 0.9, 0.7),
	"Burn": Color(1.0, 0.45, 0.15),
	"Fire": Color(0.95, 0.3, 0.2),
	"Water": Color(0.25, 0.6, 1.0),
	"Wind": Color(0.4, 0.85, 0.75),
	"Damaged": Color(1.0, 0.85, 0.2),
	"Machine": Color(0.65, 0.55, 0.85),
	"Health": Color(0.55, 0.8, 0.4),
}

const NEUTRAL := Color(0.75, 0.75, 0.8)


# Component names printed under each entity, so the shape of an entity is
# visible while it changes. The most useful ECS debugging tool in the project.
const BADGE_ORDER := [
	"Position", "Velocity", "Size", "Delay", "Fire", "Water", "Wind",
	"Burn", "Damaged", "Health", "Invulnerable", "Wet",
	"Machine", "Recipe", "Lifetime", "Dead",
	"Player", "MoveIntent", "Facing", "Chase", "CastQueue", "CastRelease", "Knockback",
]


# --- casting input -----------------------------------------------------------

# J/K/L, not 1/2/3: the left hand never leaves WASD, so the runes have to sit
# under the right hand.
const RUNE_KEYS := {
	KEY_J: "Fire",
	KEY_K: "Water",
	KEY_L: "Wind",
}

# The first rune decides the shape of the spell. Naming it on screen the moment
# it is queued is feedback on what the player is holding — not a recipe list.
# The player still has to find out what each shape is good for.
const FORM_OF := {
	"Fire": "BULLET",
	"Water": "PUDDLE",
	"Wind": "CONE",
}


static func color_of(name: String) -> Color:
	return COLORS.get(name, NEUTRAL)
