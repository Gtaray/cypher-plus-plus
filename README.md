# Cypher++

A complete overhaul of many of the systems in the Cypher ruleset to bring it closer to the standard I would expect from Fantasy Grounds rulesets

## WARNING

This extension rewrites and overwrites about 90% of the Cypher ruleset. As such, it is almost certainly incompatible with any other extension specifically made for Cypher.

## Features

Cypher++ is a grab-bag collection of features I wanted for my own game. It is designed to be flexible and easy to use, since Cypher is all about flexibility and ease of use.

### System Changes

* Added damage type support. You can access the damage type list via the "Damage Types" button in the options menu. These damage types suport damage reduction/modification of specific types of damage.
* Added an "EASE" and "HINDER" button on the desktop that will ease or hinder the next roll that's made after clicking the button.
* When making a stat, skill, attack, or defense roll, and are targeting an NPC, the difficulty calculation is processed more closely to how it is described in the book. That is, you start with the difficulty based on the target's level, which is then modified up or down by effects, effort, assets, etc. When the roll is displayed in chat, the difficulty icon will display the actual difficulty of the roll (including all modifications). This is then compared to the d20 roll, and success/failure is reported. 
	* When you do not target an NPC with these rolls, it operates the same as before, where the difficulty icon will display what difficulty the roll succeeds after including all of the modifications.
	* If a PC targets a PC with an attack roll, all difficulty reductions are converted to a +3 to the roll's modifier, and then the target is prompted to roll a defense roll. All difficulty mods of the defense roll are similarly converted to +3 to the roll's modifier. Then the two numbers are compared to see who wins.

### Effects

* Added a comprehensive list of effects to support all the ways characters can have their rolls modified.

| Effect | Value  | Descriptors                | Notes                                                                       |
|--------|--------|----------------------------|-----------------------------------------------------------------------------|
| ASSET  | Number | [roll type] [stat] [skill] | Adds an asset to the roll. Capped at 2                                      |
| EDGE   | Number | [roll type] [stat]         | Adjusts a character's Edge                                                  |
| MAXEFF | Number | [roll type] [stat]         | Adjusts the maximum effort that can be applied                              |
| STAT   | Number | [stat]                     | Adds a flat number to stat rolls*                                           |
| SKILL  | Number | [stat] [skill]             | Adds a flat number to skill rolls*                                          |
| ATK    | Number | [stat]                     | Adds a flat number to attack rolls*                                         |
| DEF    | Number | [stat]                     | Adds a flat number to defense rolls*                                        |
| DMG    | Number | [stat] [damage type]       | Adds a flat amount to damage rolls*                                         |
| RESIST | Number | [damage type]              | Flat damage reduction for the specified damage type                         |
| VULN   | Number | [damage type]              | Flat damage increase for the specified damage type                          |
| IMMUNE | Number | [damage type]              | Takes 0 damage of the specified type                                        |
| ARMOR  | Number |                            | Increases armor                                                             |
| EASE   | -      | [roll type] [stat] [skill] | Eases the difficulty of a roll                                              |
| HINDER | -      | [roll type] [stat] [skill] | Hinders the difficulty of a roll                                            |
| COST   | Number | [stat] armor               | Modifies the amount of a stat pool paid to activate abilities, apply effort |
| LEVEL  | Number | [roll type] [stat]         | Modifies the level of an NPC, which affects their difficulty                |
| PIERCE | Number | [damage type]              | Causes damage dealt to bypass an amount of armor (normal armor rules apply) |

* [roll type] = stat, skill, attack/atk, defense/def
* [stat] = might, speed, intellect
* [skill] = any skill name
* [damage type] = any damage type
* \* If a roll has a modifier greater than 3, it will be converted to the appropriate difficulty reduction.

| Condition   | Effect                                                                                                                  |
|-------------|-------------------------------------------------------------------------------------------------------------------------|
| Dazed       | Hinders attack and defense rolls made by this creature, or eases attacks made against this creature                     |
| Staggered   | Hinders Might attack and defense rolls made by this creature, or eases Might attacks made against this creature         |
| Frostbitten | Hinders Speed attack and defense rolls made by this creature, or eases Speed attacks made against this creature         |
| Confused    | Hinders Intellect attack and defense rolls made by this creature, or eases Intellect attacks made against this creature |


### PC Sheet

* The Action tab of the PC sheet has been modified to display stat pools and defense roll buttons. This was done to lessen the need to jump between tabs during encounters.
* PC attacks have been completely overhauled. Clicking the 'settings' button next to each attack will open a window with the properties for that attack. 
* PC attacks with the "Weapon" type have an 'equipped' icon visible. You can toggle which weapon is currently equipped. Abilities can then specify they want to use the attack or damage from an equipped weapon.
* PC abilities have had their roll properties removed. Instead, PC Abilities can now have roll actions added to them through the radial menu. These operate much like other popular rulesets. Supported actions include: stat rolls, attacks, damage, healing, and effects.
	* You can specify the cost of an ability in the ability itself, or in an individual action. This is useful if an ability has multiple options, but each option costs the same.
* Added a 'used' checkbox next to PC abilities that can be enabled by setting an ability's recharge period. These abilities will recharge based on the period set (first recovery, last recovery, any recovery, or manually).
* Weapon (and ability) damage has an added "Damage Type" field to support damage modification based on damage type

### NPC Sheet

* Added a section to the PC sheet where you can enter damage type resistances, immunities, and vulnerabilities. 
* Added a section to the NPC sheet where you can enter individual attacks and abilities. Just like the PC sheet, these abilities can have actions attached to them through the radial menu. 
	* Because NPCs and PCs share the same action list, NPCs have a "stat" action that doesn't actually do anything. Ignore it.
	* For NPCs the "attack" action, when targeting a PC, will pop up a prompt for the player to make a defense roll. If the PC being attacked is not currently held by an active player (if the player is absent, but their PC is being GM-controlled, for example) the defense roll will run automatically.