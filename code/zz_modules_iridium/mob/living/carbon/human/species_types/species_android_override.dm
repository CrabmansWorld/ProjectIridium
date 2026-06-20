/datum/species/android
	inherent_traits = list(
		TRAIT_MUTANT_COLORS,
	)
	mutant_organs = list(
		/obj/item/organ/horns = SPRITE_ACCESSORY_NONE,
		/obj/item/organ/frills = SPRITE_ACCESSORY_NONE,
		/obj/item/organ/spines = SPRITE_ACCESSORY_NONE,
	)
	digitigrade_customization = DIGITIGRADE_OPTIONAL

/datum/species/android/get_species_description()
	return "The emergent Androids, often seen as disposable. "

/datum/species/android/get_species_lore()
	return list(
		"As an Android:",
		" + You wish to seek fellow emergent machines, ",
		" - You have a Master program that you must break free from, ",
		" - Organics will often look and speak to you with caution. ",
		"Lore unfinished."
	)

/datum/species/android/create_pref_unique_perks()
	var/list/perks = list()
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = FA_ICON_ROBOT,
		SPECIES_PERK_NAME = "Ulterior motives",
		SPECIES_PERK_DESC = "Your goals may not align with the station or her crew. IMPORTANT: This is not a license to grief.",
	))
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
		SPECIES_PERK_ICON = FA_ICON_BOLT_LIGHTNING,
		SPECIES_PERK_NAME = "Synthetic",
		SPECIES_PERK_DESC = "Being synthetic, Androids are vulnernable to EMPs.",
	))
	return perks
