// IRIDIUM: selector for roundstart subspecies.
// First element will always be the parent species.

GLOBAL_LIST_INIT( sub_human, list(
	"human",
	"spacer",
) )

GLOBAL_LIST_INIT( subspecies_list, list(
	"human",
) )

/datum/preference/choiced/subspecies
	var/sub_list = list()

/datum/preference/choiced/subspecies/find_sub_human_list(mob/living/carbon/human/target)
	if (!GLOB.subspecies_list.find(mob/living/carbon/human/target.race))
		CRASH("Target datum has no species")
		return 0
	return GLOB.subspecies_list.find(mob/living/carbon/human/target.race)
