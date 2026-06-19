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
