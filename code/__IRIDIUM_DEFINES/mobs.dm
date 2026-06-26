// Defines for Species IDs. Used to refer to the name of a species, for things like bodypart names or species preferences.
#define SPECIES_SPACER "humanspacer"

#define SPECIES_ANTIHEPIAN "antihepian"
#define SPECIES_FRONTIERSHADOW "frontiershadow"


// Makes a separate skintone list for spacer races (Consult The Lore:tm:)
GLOBAL_LIST_INIT(spacer_tones, sort_list(list(
	"albino",
	"mediterranean",
	"indian",
	"mixed1",
	"mixed2",
	"mixed3",
	"mixed4",
	"african1",
	"african2"
	)))

GLOBAL_LIST_INIT(spacer_tone_names, list(
	"african1" = "Medium brown",
	"african2" = "Dark brown",
	"albino" = "Albino",
	"indian" = "Brown",
	"mediterranean" = "Olive",
	"mixed1" = "Chestnut",
	"mixed2" = "Walnut",
	"mixed3" = "Coffee",
	"mixed4" = "Macadamia",
))

// Subspecies

GLOBAL_LIST_INIT(selectable_subtypes, init_selectable_subtypes())

/proc/init_selectable_subtypes()
	var/list/keys = list()
	// FIND HUMAN SUBSPECIES
	for (var/datum/species/human/subtype/sub_unit as anything in /datum/species/human/subtype)
		keys += sub_unit

	// FIND SHADOW SUBSPECIES
	for (var/datum/species/shadow/subtype/sub_unit as anything in /datum/species/shadow/subtype)
		keys += sub_unit
	return keys
