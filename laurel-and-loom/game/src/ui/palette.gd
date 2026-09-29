class_name Palette
extends RefCounted
## The art-direction palette (docs/ART_DIRECTION.md). Everything drawn in the
## game takes its colour from here.

const MARBLE := Color("#ECE7DC")
const MARBLE_SHADE := Color("#E0D9CB")
const VEIN := Color("#B9B2A6")
const TRAVERTINE := Color("#D8C9AC")
const INK := Color("#1F1A17")
const INK_SOFT := Color("#4A423B")
const GOLD := Color("#C9A24B")
const GOLD_DEEP := Color("#9C7A2E")
const BRONZE := Color("#8C6A43")
const JASPER := Color("#5B7FA6")
const JASPER_DEEP := Color("#3F5F86")
const LAPIS := Color("#23385E")
const LAPIS_DEEP := Color("#172642")
const TERRACOTTA := Color("#C4683C")
const TERRACOTTA_DEEP := Color("#9E4E2A")
const POMPEIAN := Color("#A3362C")
const VERDIGRIS := Color("#4F8B7D")
const OLIVE := Color("#6C7A3B")
const LAUREL := Color("#5E7C46")
const MEADOW := Color("#7E9459")
const CYPRESS := Color("#2E472F")
const STONE := Color("#9A9187")
const STONE_DEEP := Color("#6F675E")

## Team field colours for cameos and ranges.
const TEAM_FIELD := [JASPER, TERRACOTTA]
const TEAM_FIELD_DEEP := [JASPER_DEEP, TERRACOTTA_DEEP]
## Relief colour: white on jasper, black-figure on terracotta.
const TEAM_RELIEF := [MARBLE, INK]

const MOVE_FILL := Color(0.357, 0.498, 0.651, 0.42)
const ATTACK_FILL := Color(0.639, 0.212, 0.173, 0.38)
const HEAL_FILL := Color(0.31, 0.545, 0.49, 0.42)
const DANGER_EDGE := Color(0.639, 0.212, 0.173, 0.85)
const DANGER_FILL := Color(0.639, 0.212, 0.173, 0.16)

## Omen tints for beads: fair, middling, ill.
const OMEN_TINT := [Color("#7FA58A"), Color("#C9B98A"), Color("#B0685A")]


static func grey_marble(c: Color) -> Color:
	var l := c.get_luminance()
	return Color(l, l * 0.98, l * 0.95, c.a).lerp(MARBLE_SHADE, 0.35)
