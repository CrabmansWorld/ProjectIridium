// IRIDIUM: selector for roundstart subspecies.
// First element will always be the parent species.

GLOBAL_LIST_INIT( human, list(
	SPECIES_HUMAN,
	SPECIES_SPACER,
) )

GLOBAL_LIST_INIT( subspecies_list, list(
	SPECIES_HUMAN,
) )

/datum/preference/choiced/subtype
	savefile_key = "subtype"
	savefile_identifier = PREFERENCE_CHARACTER
	priority = PREFERENCE_CATEGORY_FEATURES

/datum/preference/choiced/subtype/init_possible_values()
	for ( var/possible_subtype in GLOB.subspecies_list )
		if (possible_subtype == GLOB.preference_entries[/datum/preference/choiced/species])
			return GLOB[possible_subtype]
	return list(/datum/preference/choiced/species)

