// Defines for Species IDs. Used to refer to the name of a species, for things like bodypart names or species preferences.
#define SPECIES_SPACER "humanspacer"

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
