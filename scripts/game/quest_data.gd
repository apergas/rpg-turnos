class_name QuestData extends Resource
## One side quest (data/quests/<id>.tres): who offers it, what it asks for, who hears the
## report, what it says and what it pays. QuestLog keeps how far it has gone. Figures are
## called by their ZoneData.npcs "name" (a board's is "Tablón"). Lines may hold
## StoryState.NAME_TAG.

## HUNT: defeat goal enemies of data id target. GATHER: bring goal items of Inventory id
## target (the inventory is the count). DELIVER: take key_item to the turn_in figure. FIND:
## talk to the figure target in target_zone, which is only on the map while it is sought,
## then report.
enum Kind { HUNT, GATHER, DELIVER, FIND }

@export var id := ""
## Its name in the Diario and in "Misión cumplida: ...".
@export var title := ""
@export var kind := Kind.HUNT
## Where it is offered: a zone id and a figure of that zone.
@export var zone := ""
@export var giver := ""
## A world flag that must be set before the quest is offered ("" for none). A quest
## already taken goes on whatever happens to the flag.
@export var needs := ""
## Who hears the report ("" : it ends on the spot, when the goal is reached).
@export var turn_in_zone := ""
@export var turn_in := ""
@export var target := ""
@export var target_zone := ""
@export var goal := 1
## DELIVER: the Inventory.KEY_ITEMS id handed over with the offer, taken at the end.
@export var key_item := ""
## A sentence for the Diario.
@export var objective := ""
## For the mission lines, after "Misión: ", kept short (the status window fits its longest
## line): with "%d / %d" for a HUNT or GATHER of several; report once it is time to go back.
@export var status := ""
@export var report := ""
## What is said when it is offered, by the target when found (FIND), by the turn_in figure
## while waiting (empty: its chapter lines) and at the end.
@export var offer_lines: Array[String] = []
@export var found_lines: Array[String] = []
@export var wait_lines: Array[String] = []
@export var done_lines: Array[String] = []
## What it pays. No quest gives EXP.
@export var reward_gold := 0
## Inventory id -> how many.
@export var reward_items := {}
## An Equipment id, or "".
@export var reward_equipment := ""
