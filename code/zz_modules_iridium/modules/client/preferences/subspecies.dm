// TODO: Runtime at init_possible_values() leaves value list empty

// IRIDIUM: selector for roundstart subspecies.
// First element will always be the parent species.

/datum/preference/choiced/species/subtype
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "subtype"
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	randomizable_by_default = TRUE

/datum/preference/choiced/species/subtype/init_possible_values()
	var/list/values = list()
	for (var/selectable in GLOB.selectable_subtypes)
		values += selectable
	return values

// /datum/preference/choiced/species/subtype/apply_to_human(mob/living/carbon/human/target, value)
// 	// UNFINISHED
// 	return
