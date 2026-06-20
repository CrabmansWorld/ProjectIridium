// IRIDIUM: selector for roundstart subspecies.
// First element will always be the parent species.

// INIT_POSSIBLE_VALUES() IS A SPECIES OVERRIDE FUNCTION

GLOBAL_LIST_INIT( human, list(
	SPECIES_HUMAN,
	SPECIES_SPACER,
) )

GLOBAL_ALIST_INIT( shadow, list(
	SPECIES_SHADOW,
	SPECIES_ANTIHEPIAN,
	SPECIES_FRONTIERSHADOW,
) )

/datum/preference/choiced/species/subtype
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE
	savefile_key = "subtype"
	main_feature_name = "Subspecies"
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES

/datum/preference/choiced/species/subtype/init_possible_values()
	return GLOB.human

/datum/preference/choiced/species/subtype/apply_to_human(mob/living/carbon/human/target, value)
	target.set_species(value, icon_update = FALSE, pref_load = TRUE)
