#define AHELP_FIRST_MESSAGE "Please adminhelp before leaving the round, even if there are no administrators online!"

/*
	IRIDIUM EXLCUSIVE: major refactor.
	Gutting the entire cryo system to work with bare tg.
*/

/*
 * Cryogenic refrigeration unit. Basically a despawner.
 * Stealing a lot of concepts/code from sleepers due to massive laziness.
 * The despawn tick will only fire if it's been more than time_till_despawned ticks
 * since time_entered, which is world.time when the occupant moves in.
 * ~ Zuhayr
 */
GLOBAL_LIST_EMPTY(cryopod_computers)

GLOBAL_LIST_EMPTY(ghost_records)

/// A list of all cryopods that aren't quiet, to be used by the "Send to Cryogenic Storage" VV action.
GLOBAL_LIST_EMPTY(valid_cryopods)

// Cryo announcement

/datum/aas_config_entry/cryopod_announcement
	name = "Cryopod transfer"
	announcement_lines_map = list(
		"Message" = "%PERSON has been transferred from the station via cryogenics. A new place for %RANK has been opened."
	)
	vars_and_tooltips_map = list(
		"PERSON" = "will be replaced with the name of the crewmember",
		"RANK" = "will be replaced with the job of the crewmember",
	)

//Main cryopod console.

/obj/machinery/computer/cryopod
	name = "cryogenic oversight console"
	desc = "An interface between crew and the cryogenic storage oversight systems."
	icon = 'code/z_imported_modules/modular_nova/modules/cryosleep/icons/cryogenics.dmi'
	icon_state = "cellconsole_1"
	icon_keyboard = null
	icon_screen = null
	use_power = FALSE
	density = FALSE
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE
	req_one_access = list(ACCESS_COMMAND, ACCESS_ARMORY) // Heads of staff or the warden can go here to claim recover items from their department that people went were cryodormed with.
	verb_say = "coldly states"
	verb_ask = "queries"
	verb_exclaim = "alarms"

	/// Used for logging people entering cryosleep and important items they are carrying.
	var/list/frozen_crew
	/// The items currently stored in the cryopod control panel.
	var/list/frozen_items

	/// The channel to be broadcast on, works via refactored AAS machinery.
	var/announcement_channel = RADIO_CHANNEL_COMMON

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/cryopod, 32)

/obj/machinery/computer/cryopod/Initialize(mapload)
	. = ..()
	GLOB.cryopod_computers += src

/obj/machinery/computer/cryopod/Destroy()
	GLOB.cryopod_computers -= src
	return ..()

/obj/machinery/computer/cryopod/update_icon_state()
	if(machine_stat & (NOPOWER|BROKEN))
		icon_state = "cellconsole"
		return ..()
	icon_state = "cellconsole_1"
	return ..()

/obj/machinery/computer/cryopod/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		return

	add_fingerprint(user)

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CryopodConsole", name)
		ui.open()

/obj/machinery/computer/cryopod/ui_data(mob/user)
	var/list/data = list()
	data["frozen_crew"] = frozen_crew

	/// The list of references to the stored items.
	var/list/item_ref_list = list()
	/// The associative list of the reference to an item and its name.
	var/list/item_ref_name = list()

	for(var/obj/item/item in frozen_items)
		var/ref = REF(item)
		item_ref_list += ref
		item_ref_name[ref] = item.name

	data["item_ref_list"] = item_ref_list
	data["item_ref_name"] = item_ref_name

	// Check Access for item dropping.
	var/item_retrieval_allowed = allowed(user)
	data["item_retrieval_allowed"] = item_retrieval_allowed

	var/obj/item/card/id/id_card
	if(isliving(user))
		var/mob/living/person = user
		id_card = person.get_idcard()
	if(id_card?.registered_name)
		data["account_name"] = id_card.registered_name

	return data

/obj/machinery/computer/cryopod/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("item_get")
			// This is using references, kinda clever, not gonna lie. Good work Zephyr
			var/item_get = params["item_get"]
			var/obj/item/item = locate(item_get)
			if(item in frozen_items)
				item.forceMove(drop_location())
				ui.user.put_in_hands(item)
				LAZYREMOVE(frozen_items, item)
				visible_message("[src] dispenses \the [item].")
				message_admins("[item] was retrieved by [ui.user] from cryostorage at [ADMIN_COORDJMP(src)]")
			else
				CRASH("Invalid REF# for ui_act. Not inside internal list!")
			return TRUE

		else
			CRASH("Illegal action for ui_act: '[action]'")

/obj/machinery/computer/cryopod/proc/announce(message_type, user, rank, datum/job/occupant_job)
	switch(message_type)
		if("CRYO_JOIN")
			aas_config_announce(/datum/aas_config_entry/cryopod_announcement, list(
				"PERSON" = user,
				"RANK" = rank,
			), src, list(announcement_channel), "Awakening")
		if("CRYO_LEAVE")
			var/already_announced = FALSE
			if (occupant_job)
				for (var/department in occupant_job.departments_list)
					var/datum/job_department/dep = SSjob.joinable_departments_by_type[department]
					// Announce all command staff or heads of departments in their respected radio channels.
					if (!(dep.department_bitflags & DEPARTMENT_BITFLAG_COMMAND) && !istype(occupant_job, dep.department_head))
						continue

					aas_config_announce(/datum/aas_config_entry/cryopod_announcement, list(
						"PERSON" = user,
						"RANK" = rank,
					), src, list(dep.default_radio_channel), "Removing", istype(occupant_job, dep.department_head))

					// If we announced on computer's channel, don't announce again.
					if (dep.default_radio_channel == announcement_channel)
						already_announced = TRUE

			if (!already_announced)
				aas_config_announce(/datum/aas_config_entry/cryopod_announcement, list(
					"PERSON" = user,
					"RANK" = rank,
				), src, list(announcement_channel), "Removing")


// Cryopods themselves.
/obj/machinery/cryopod
	name = "cryogenic freezer"
	desc = "Suited for Cyborgs and Humanoids, the pod is a safe place for personnel affected by the Space Sleep Disorder to get some rest."
	icon = 'code/z_imported_modules/modular_nova/modules/cryosleep/icons/cryogenics.dmi'
	icon_state = "cryopod-open"
	base_icon_state = "cryopod"
	use_power = FALSE
	density = TRUE
	anchored = TRUE
	state_open = TRUE
	interaction_flags_mouse_drop = FORBID_TELEKINESIS_REACH

	var/open_icon_state = "cryopod-open"
	/// Whether the cryopod respects the minimum time someone has to be disconnected before they can be put into cryo by another player
	var/allow_timer_override = FALSE
	/// Minimum time for someone to be SSD before another player can cryo them.
	var/ssd_time = 30 MINUTES //Replace with "cryo_min_ssd_time" CONFIG

	/// Time until despawn when a mob enters a cryopod. You cannot other people in pods unless they're catatonic.
	var/time_till_despawn = 30 SECONDS

	///Weakref to our controller
	var/datum/weakref/control_computer_weakref
	COOLDOWN_DECLARE(last_no_computer_message)
	/// if false, plays announcement on cryo
	var/quiet = FALSE
	/// Has the occupant been tucked in?
	var/tucked = FALSE
	/// If this cryopod should despawn the occupant to the ghost cafe
	// var/despawn_to_ghostcafe // IRIDIUM DEL
	/// The timerid of the cryo countdown, so we can stop it if the mob leaves the pod.
	var/timerid

/obj/machinery/cryopod/quiet
	quiet = TRUE

/obj/machinery/cryopod/Initialize(mapload)
	..()
	if(!quiet)
		GLOB.valid_cryopods += src
	return INITIALIZE_HINT_LATELOAD //Gotta populate the cryopod computer GLOB first

/obj/machinery/cryopod/post_machine_initialize()
	. = ..()
	update_icon()
	find_control_computer()

// This is not a good situation
/obj/machinery/cryopod/Destroy()
	GLOB.valid_cryopods -= src
	control_computer_weakref = null
	return ..()

/obj/machinery/cryopod/proc/find_control_computer(urgent = FALSE)
	for(var/cryo_console in GLOB.cryopod_computers)
		var/obj/machinery/computer/cryopod/console = cryo_console
		if(get_area(console) == get_area(src))
			control_computer_weakref = WEAKREF(console)
			break

	// Don't send messages unless we *need* the computer, and less than five minutes have passed since last time we messaged
	if(!control_computer_weakref && urgent && COOLDOWN_FINISHED(src, last_no_computer_message))
		COOLDOWN_START(src, last_no_computer_message, 5 MINUTES)
		log_admin("Cryopod in [get_area(src)] could not find control computer!")
		message_admins("Cryopod in [get_area(src)] could not find control computer!")
		last_no_computer_message = world.time

	return control_computer_weakref != null

/obj/machinery/cryopod/close_machine(atom/movable/target, density_to_set = TRUE)
	if(!control_computer_weakref)
		find_control_computer(TRUE)
	if(!isliving(target) || !state_open || panel_open)
		return
	target.forceMove(src)
	set_occupant(target)
	..()
	var/mob/living/mob_occupant = occupant
	if(mob_occupant && mob_occupant.stat != DEAD)
		to_chat(occupant, span_notice("<b>You feel cool air surround you. You go numb as your senses turn inward.</b>"))

	var/mob/living/carbon/human/human_occupant = occupant
	// if(istype(human_occupant) && human_occupant.mind)
	// 	human_occupant.save_individual_persistence(mob_occupant.ckey || mob_occupant.mind?.key)

	timerid = addtimer(CALLBACK(src, PROC_REF(initiate_despawn_occupant)), time_till_despawn, TIMER_DELETE_ME|TIMER_STOPPABLE)
	RegisterSignal(src, COMSIG_MACHINERY_SET_OCCUPANT, PROC_REF(on_set_occupant))
	RegisterSignal(human_occupant, COMSIG_MOB_GHOSTIZED, PROC_REF(on_occupant_ghosted))

/// Called when the mob leaves the pod.
/obj/machinery/cryopod/proc/on_set_occupant(datum/source, mob/living/new_occupant)
	SIGNAL_HANDLER

	stop_cryo_timer()

/// Stop the cryo process.
/obj/machinery/cryopod/proc/stop_cryo_timer()

	if(timerid)
		deltimer(timerid)
		timerid = null

	UnregisterSignal(src, COMSIG_MACHINERY_SET_OCCUPANT)

	if(occupant)
		UnregisterSignal(occupant, COMSIG_MOB_GHOSTIZED)

/// Immediately despawn them and stop the timer when they ghost.
/obj/machinery/cryopod/proc/on_occupant_ghosted(datum/source)
	on_set_occupant(src)
	initiate_despawn_occupant()

/obj/machinery/cryopod/open_machine(drop = TRUE, density_to_set = FALSE)
	..()
	set_density(TRUE)
	name = initial(name)
	tucked = FALSE

/obj/machinery/cryopod/container_resist_act(mob/living/user)
	visible_message(span_notice("[occupant] emerges from [src]!"),
		span_notice("You climb out of [src]!"))
	open_machine()

/obj/machinery/cryopod/relaymove(mob/user)
	container_resist_act(user)

/// Despawn the mob. To be called via addtimer or when the mob ghosts.
/obj/machinery/cryopod/proc/initiate_despawn_occupant()
	stop_cryo_timer()

	if(!occupant)
		return

	var/mob/living/mob_occupant = occupant
	if(mob_occupant.stat == DEAD)
		open_machine()

	if(!mob_occupant.client)
		if(!control_computer_weakref)
			find_control_computer(urgent = TRUE)

	despawn_occupant()

/// This function can not be undone; do not call this unless you are sure.
/// Handles despawning the player.
/obj/machinery/cryopod/proc/despawn_occupant()
	var/mob/living/mob_occupant = occupant

	var/occupant_ckey = mob_occupant.ckey || mob_occupant.mind?.key
	var/occupant_name = mob_occupant.real_name
	var/occupant_rank = mob_occupant.mind?.assigned_role.title
	var/occupant_job = mob_occupant.mind?.assigned_role

	SSjob.FreeRole(occupant_rank)

	// Handle holy successor removal
	// var/list/holy_successors = list_holy_successors()
	// if(mob_occupant in holy_successors) // if this mob was a holy successor then remove them from the pool
	// 	GLOB.holy_successors -= WEAKREF(mob_occupant)

	// if(mob_occupant.mind)
	// 	// Handle freeing the high priest role for the next chaplain in line
	// 	if(mob_occupant.mind.holy_role == HOLY_ROLE_HIGHPRIEST)
	// 		reset_religion()
	// else
	// 	// handle the case of the high priest no longer having a mind
	// 	var/datum/weakref/current_highpriest = GLOB.current_highpriest
	// 	if(current_highpriest?.resolve() == mob_occupant)
	// 		reset_religion()

	// var/obj/item/card/id/auth_card = mob_occupant.get_idcard(TRUE)
	// var/off_duty_component = auth_card?.GetComponent(/datum/component/off_duty_timer)
	// var/datum/id_trim/job/plexagon_selfserve_target_trim = /datum/computer_file/program/crew_self_serve::target_trim
	// Delete them from datacore and ghost records.
	var/announce_rank = null
	// It is possible to join round from ghost cafe without leaving it. So we prioritize general manifest first to avoid ghost roles announcements IC.
	for(var/datum/record/crew/possible_target_record as anything in GLOB.manifest.general)
		if (possible_target_record.name != occupant_name)
			continue

		var/match_rank = occupant_rank == "N/A" || possible_target_record.trim == occupant_rank
		// Off-duty crew manifest changed to Assistant trim and assignment. It doesn't work for off-duties without ID, but oh well.
		// var/match_offduty = off_duty_component && possible_target_record.trim == plexagon_selfserve_target_trim.assignment

		if(match_rank)
			announce_rank = possible_target_record.rank
			qdel(possible_target_record)
			break

	if(!announce_rank) // No need to loop over all of those if we already found it beforehand.
		for(var/list/record as anything in GLOB.ghost_records)
			if(record["name"] == occupant_name)
				announce_rank = record["rank"]
				GLOB.ghost_records -= record
				break

	// Borgs job var is null for some reason, and they are not in records, so we handle them separately.
	if (iscyborg(occupant))
		var/mob/living/silicon/robot/borg = occupant
		announce_rank = "[borg.designation] Cyborg"

	var/obj/machinery/computer/cryopod/control_computer = control_computer_weakref?.resolve()
	if(!control_computer)
		control_computer_weakref = null
	else
		LAZYADD(control_computer.frozen_crew, list(list("name" = occupant_name, "job" = occupant_rank)))

		// Make an announcement and log the person entering storage. If set to quiet, does not make an announcement.
		if(!quiet)
			control_computer.announce("CRYO_LEAVE", mob_occupant.real_name, announce_rank, occupant_job)

	visible_message(span_notice("[src] hums and hisses as it moves [mob_occupant.real_name] into storage."))

	// if(!HAS_TRAIT_FROM(mob_occupant, TRAIT_FREE_GHOST, TRAIT_GHOSTROLE)) // Don't let ghost cafe people store items
	// 	for(var/obj/item/item_content in mob_occupant)
	// 		if (!istype(item_content, /obj/item) || HAS_TRAIT(item_content, TRAIT_NODROP) || (item_content.item_flags & (ABSTRACT | DROPDEL)) || (item_content.flags_1 & HOLOGRAM_1)) //IRIS EDIT. ORIGINAL CODE: if(!istype(item_content) || HAS_TRAIT(item_content, TRAIT_NODROP) || (item_content.item_flags & ABSTRACT|DROPDEL) || (item_content.flags_1 & HOLOGRAM_1))
	// 			continue
	// 		if (issilicon(mob_occupant) && istype(item_content, /obj/item/mmi))
	// 			continue
	// 		if(control_computer)
	// 			if(istype(item_content, /obj/item/modular_computer))
	// 				var/obj/item/modular_computer/computer = item_content
	// 				for(var/datum/computer_file/program/messenger/message_app in computer.stored_files)
	// 					message_app.invisible = TRUE
	// 			mob_occupant.transferItemToLoc(item_content, control_computer, force = TRUE, silent = TRUE)
	// 			item_content.dropped(mob_occupant)
	// 			LAZYADD(control_computer.frozen_items, item_content)
	// 		else
	// 			mob_occupant.transferItemToLoc(item_content, drop_location(), force = TRUE, silent = TRUE)

	// Borgs will splash the ground with their beaker reagents on qdel, let's make sure this does not happen
	if(iscyborg(occupant))
		var/mob/living/silicon/robot/cyborg_occupant = occupant
		var/obj/item/borg/apparatus/beaker/borg_beaker = (locate() in cyborg_occupant.model.modules) || (locate() in cyborg_occupant.held_items)
		if(borg_beaker && borg_beaker.stored)
			var/obj/item/reagent_containers/reagent_container = borg_beaker.stored
			reagent_container.reagents?.clear_reagents()

	GLOB.joined_player_list -= occupant_ckey

	// if(isnull(mob_occupant.ckey)) // they ghosted early
	// 	for(var/mob/dead/observer/ghost as anything in GLOB.dead_player_list) // so we must find them in the list
	// 		if(ghost.ckey == occupant_ckey)
	// 			occupant_ghost_mob = ghost
	// else
	// 	occupant_ghost_mob = mob_occupant.ghostize() // otherwise they're just sitting patiently in the pod waiting, ghost them

	// Ghost cafe cryopods
	// if(despawn_to_ghostcafe)
	// 	var/obj/effect/mob_spawn/ghost_role/ghostcafe_spawner

	QDEL_NULL(occupant)
	open_machine()
	name = initial(name)

/obj/machinery/cryopod/mouse_drop_receive(mob/living/target, mob/user, params)
	if(!istype(target) || !ismob(target) || isanimal(target) || !istype(user.loc, /turf) || target.buckled)
		return

	if(occupant)
		to_chat(user, span_notice("[src] is already occupied!"))
		return

	if(target.stat == DEAD)
		to_chat(user, span_notice("Dead people can not be put into cryo."))
		return

// Allows admins to enable players to override SSD Time check.
	if(allow_timer_override)
		if(tgui_alert(user, "Would you like to place [target] into [src]?", "Place into Cryopod?", list("Yes", "No")) != "No")
			to_chat(user, span_danger("You put [target] into [src]. [target.p_Theyre()] in the cryopod."))
			log_admin("[key_name(user)] has put [key_name(target)] into a overridden stasis pod.")
			message_admins("[key_name(user)] has put [key_name(target)] into a overridden stasis pod. [ADMIN_JMP(src)]")

			add_fingerprint(target)

			close_machine(target)
			name = "[name] ([target.name])"

// Allows players to cryo others. Checks if they have been AFK for 30 minutes.
	// if(target.key && user != target)
	// 	if (target.get_organ_by_type(/obj/item/organ/brain) ) //Target the Brain
	// 		if(!target.mind || target.ssd_indicator ) // Is the character empty / AI Controlled
	// 			if(target.lastclienttime + ssd_time >= world.time)
	// 				to_chat(user, span_notice("You can't put [target] into [src] for another [round(((ssd_time - (world.time - target.lastclienttime)) / (1 MINUTES)), 1)] minutes."))
	// 				log_admin("[key_name(user)] has attempted to put [key_name(target)] into a stasis pod, but they were only disconnected for [round(((world.time - target.lastclienttime) / (1 MINUTES)), 1)] minutes.")
	// 				message_admins("[key_name(user)] has attempted to put [key_name(target)] into a stasis pod. [ADMIN_JMP(src)]")
	// 				return
	// 			else if(tgui_alert(user, "Would you like to place [target] into [src]?", "Place into Cryopod?", list("Yes", "No")) == "Yes")
	// 				if(target.mind.assigned_role.req_admin_notify)
	// 					tgui_alert(user, "They are an important role! [AHELP_FIRST_MESSAGE]")
	// 				to_chat(user, span_danger("You put [target] into [src]. [target.p_Theyre()] in the cryopod."))
	// 				log_admin("[key_name(user)] has put [key_name(target)] into a stasis pod.")
	// 				message_admins("[key_name(user)] has put [key_name(target)] into a stasis pod. [ADMIN_JMP(src)]")

	// 				add_fingerprint(target)

	// 				close_machine(target)
	// 				name = "[name] ([target.name])"

		else if(iscyborg(target))
			to_chat(user, span_danger("You can't put [target] into [src]. [target.p_Theyre()] online."))
		else
			to_chat(user, span_danger("You can't put [target] into [src]. [target.p_Theyre()] conscious."))
		return

	if(target == user)
		var/fridge_text = "Enter cryosleep?" + CONFIG_GET(string/cryo_policy)
		// if(!despawn_to_ghostcafe || !quiet)
		// 	fridge_text += " ([CONFIG_GET(string/cryo_policy)])"
		if(tgui_alert(target, fridge_text, "Enter Cryopod?", list("Yes", "No")) != "Yes")
			return

	if(target == user)
		if(target.mind.assigned_role.req_admin_notify)
			tgui_alert(target, "You're an important role! [AHELP_FIRST_MESSAGE]")
		var/datum/antagonist/antag = target.mind.has_antag_datum(/datum/antagonist)
		if(antag)
			tgui_alert(target, "You're \a [antag.name]! [AHELP_FIRST_MESSAGE]")

	if(LAZYLEN(target.buckled_mobs) > 0)
		if(target == user)
			to_chat(user, span_danger("You can't fit into the cryopod while someone is buckled to you."))
		else
			to_chat(user, span_danger("You can't fit [target] into the cryopod while someone is buckled to them."))
		return

	if(!istype(target) || !can_interact(user) || !target.Adjacent(user) || !ismob(target) || isanimal(target) || !istype(user.loc, /turf) || target.buckled)
		return
		// rerun the checks in case of shenanigans

	if(occupant)
		to_chat(user, span_notice("[src] is already occupied!"))
		return

	if(target == user)
		visible_message(span_infoplain("[user] starts climbing into the cryo pod."))
	else
		visible_message(span_infoplain("[user] starts putting [target] into the cryo pod."))

	to_chat(target, span_warning("<b>If you remain in the pod for [time_till_despawn /10] seconds or ghost, your character will be permanently removed from the round.</b>"))

	log_admin("[key_name(target)] entered a stasis pod.")
	message_admins("[key_name_admin(target)] entered a stasis pod. [ADMIN_JMP(src)]")
	add_fingerprint(target)

	close_machine(target)
	name = "[name] ([target.name])"

// Attacks/effects.
/obj/machinery/cryopod/blob_act()
	return // Sorta gamey, but we don't really want these to be destroyed.

/obj/machinery/cryopod/update_icon_state()
	icon_state = state_open ? open_icon_state : base_icon_state
	return ..()

/obj/machinery/cryopod/despawn_to_ghostcafe
	name = "Ghost Cafe Pod"
	desc = parent_type::desc + " This one is primed to ship its occupant to the ghost cafe."
	icon_state = "ghostcafepod-open"
	base_icon_state = "ghostcafepod"
	open_icon_state = "ghostcafepod-open"
	// despawn_to_ghostcafe = TRUE
	time_till_despawn = 4 SECONDS


/// Special wall mounted cryopod for the prison, making it easier to autospawn.
/obj/machinery/cryopod/prison
	icon_state = "prisonpod-open"
	open_icon_state = "prisonpod-open"
	base_icon_state = "prisonpod"
	density = FALSE

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/cryopod/prison, 18)

//IRIS EDIT: makes prisonpods no longer locked to DENSITY=FALSE, which had previously prevented them from being used at all
/obj/machinery/cryopod/prison/close_machine(atom/movable/target, density_to_set = TRUE)
	. = ..()
	// Flick the pod for a second when user enters
	flick("prisonpod-open", src)
	set_density(FALSE)

/obj/machinery/cryopod/prison/open_machine(drop = TRUE, density_to_set = FALSE)
	..()
	set_density(FALSE)

#undef AHELP_FIRST_MESSAGE
