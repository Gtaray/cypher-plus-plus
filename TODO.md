DAMAGE TYPES
* ~~add damage type list to settings~~
* ~~Weapon attacks have damage type field~~
* ~~Powers have damage type field~~
* ~~PCs have dmg reduction via effects~~
* ~~NPCs have dmg reduction via effects & their sheet~~

EFFECTS
* ~~EDGE effect~~
* ~~DEF effect~~
* ~~ATK effect - for flat bonus to the roll~~
* ~~ASSET effect~~
* ~~DMG effect~~
* ~~Custom effects~~
* ~~LEVEL: add's target number to NPC for specific rolls~~
	* When NPC is added to CT, read the modifications field to add these dynamically
* ~~PIERCE~~
* ~~VULN/RESIST/IMMUNE~~
* SHIELD
	* temp hp implementation
	* tags to only apply to damage to a stat (might/speed/intellect)
* ~~COST~~
* ~~MAXEFF~~
* ~~STAT/STATS~~ adds flat amount ot stats
* ~~SKILL~~ adds flat amount to skills (Filtered by skill names for even more granularity)
* ~~ARMOR~~
* ~~HINDER~~
* ~~EASE~~
* INIT
* trained, specialized, inability
* Auto avoid attack (succeed defense roll) for Block ability
	* Currently on-hold as it would require specifying melee/ranged distinctions, and that's not something that's currently in the system.

NPC ACTIONS
* ~~Add actions list to NPC sheet~~
* ~~Parse NPC Powers~~ This is out. Not parsing text. Just using the normal actions list.
* ~~NPC Actions list for each ability~~
	* ~~Attack action is a hidden defenseVs roll behind the scenes, and prompts the target to roll defense.~~
* ~~Ambient damage from NPCs doesn't immediately apply~~
* ~~Put "Ambient" as a type of damage but only when the action's holder is an NPC~~
* ~~Remove damage fields that don't apply to NPC in the damage action on NPCs only~~

PC ACTIONS
* ~~Add actions to PC powers~~
* ~~Rolls that target an NPC check for a PC's training/assets/modifiers and see if it reduces the target to 0, and if so, don't roll just annouce.~~
* ~~Attack action~~
* ~~Damage action~~
	* Weapon attacks still have no pierce amount
* ~~Heal~~
* ~~Effects~~
* ~~Remove generic roll and cost from character abilities~~
* Player vs Player attacks prompt defense roll
* Add prompt for upping the cost of an ability
* ~~dd a way to pay a cost without a roll~~
* ~~Add checkbox for using powers, and then a way to regain them when certain rests are taken.~~
* A way to specify that abilities should use 'weapon' damage, and then specify which weapon they're using
	* Could also go with a weapon refactor and there's an 'equipped' weapon button

ITEMS
* Add an actions tab where you can add actions for the item.
	* Maybe items in the inventory have the same actions list that abilities do? Probably not enough room for that.

ROLL REFACTORING
* ~~Add defense action to PCs~~
	* ~~Doesn't track state or automatically pick up when attacked~~
* ~~Add DefenseVs roll for enemies~~
* ~~Add stat action to PCs~~
* ~~Add skill action to PCs~~
* ~~Damage~~
	* ~~Ambient damgae ignores armor~~

MISC
* In addition to damage types, also have an attack types field. Attack types can be thing like "mundane", "psionic", "magic", "supernatural", "tech", etc. These can then be modified by the TN tag  NPCs can have. This way NPCs can modified defenses vs specific kinds of attacks
* Add a 'apply armor' checkbox for each damage type entry to denote whether the damage type bypasses armor. This is so that damage types can deal dmg to a might pool but also ignore armor. For now this can be worked around by specifying that the damage roll pierces.
* Add player intrusion button that prints "PLAYER INTRUSION" in chat
* ~~Easy / Hard button on the desktop to increase or lower the difficulty of the roll~~
* After applying edge, disable edge for the rest of the round (resets on CT turn end) 

COMBAT TRACKER CLEANUP
* get NPC health working better. Clamp values to min/max. 
* NPC health status seems wonky. Double check
