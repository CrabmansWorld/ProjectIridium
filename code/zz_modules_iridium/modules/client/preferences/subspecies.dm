// IRIDIUM: selector for roundstart subspecies.
// First element will always be the parent species.

GLOBAL_LIST_INIT( selectable_subtypes, list(
	/datum/species/human/humanspacer,
	/datum/species/human/human,
	) )

/datum/preference/choiced/species/subtype
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "subtype"
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES

/datum/preference/choiced/species/subtype/compile_constant_data()
	var/list/data = ..()
	for(var/subtype in GLOB.selectable_subtypes)
		data[CHOICED_PREFERENCE_DISPLAY_NAMES][subtype] = subtype["name"]

	return data

/datum/preference/choiced/species/subtype/init_possible_values()
	var/list/values = list()
	for(var/subtype in GLOB.selectable_subtypes)
		values += subtype["name"]

	return values

/datum/preference/choiced/uplink_location/apply_to_human(mob/living/carbon/human/target, value)
	return
