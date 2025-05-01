/// ENTRANCE ///
/obj/machinery/computer/arcade/collapsing_rift
	name = "IS-0083"
	desc = "An arcade machine, spewing an ominous black sludge..."
	circuit = /obj/item/circuitboard/computer/arcade/collapsing_rift
	/// If we have an active turf reservation, define it here.
	var/datum/turf_reservation/rift_reservation/our_reservation
	/// The current template we're running.
	var/datum/map_template/collapsing_rift/our_current_template
	/// Whoever's inside the machine right now.
	var/mob/living/our_player
	/// List of people who've already played this round, used to prevent them from treating this as an infinite source of loot.
	var/list/winners_and_losers = list()

/obj/item/circuitboard/computer/arcade/collapsing_rift
	name = "IS-0083"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/arcade/collapsing_rift


/obj/machinery/computer/arcade/collapsing_rift/Destroy(force)
	if(our_player)
		yank_em_out(our_player)
	return ..()


/obj/machinery/computer/arcade/collapsing_rift/attack_tk(mob/user)
	return // No remote escapes; please and thanks.


/obj/machinery/computer/arcade/collapsing_rift/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(our_player)
		balloon_alert(user, "in use!")
		return
	if(!check_target_eligibility(user))
		return
	user.played_game()
	var/datum/map_template/collapsing_rift/picked_template = pick(subtypesof(/datum/map_template/collapsing_rift))
	our_current_template = new picked_template
	var/datum/turf_reservation/rift_reservation/new_reservation = SSmapping.request_turf_block_reservation(our_current_template.width, our_current_template.height, 1, reservation_type = /datum/turf_reservation/rift_reservation)
	var/turf/bottom_left = new_reservation.bottom_left_turfs[1]
	if(!bottom_left)
		to_chat(user, span_warning("Failed to reserve a game for you! Contact our technical support."))
		return
	our_current_template.load(bottom_left)
	new_reservation.rift_template = our_current_template
	our_reservation = new_reservation
	link_arcade_turfs(new_reservation)
	RegisterSignal(user, COMSIG_GLOB_MOB_DEATH, PROC_REF(yank_em_out))
	our_player = user
	do_sparks(3, FALSE, get_turf(user))
	user.forceMove(locate(
		bottom_left.x + our_current_template.landing_zone_x_offset,
		bottom_left.y + our_current_template.landing_zone_y_offset,
		bottom_left.z,
	))
	// SHOG TODO: start timer here


/obj/machinery/computer/arcade/collapsing_rift/proc/link_arcade_turfs(datum/turf_reservation/rift_reservation/current_reservation)
	var/turf/rift_bottom_left = current_reservation.bottom_left_turfs[1]
	var/area/misc/condo/current_area = get_area(rift_bottom_left)
	current_area.reservation = current_reservation
	for(var/obj/structure/collapsing_rift_hatch/found_hatch in current_area.get_all_contents())
		if(found_hatch.hatch_id)
			continue // Has an ID already, ignore
		found_hatch.connected_bin_or_arcade = WEAKREF(src)


/obj/machinery/computer/arcade/collapsing_rift/proc/yank_em_out(mob/living/user)
	if(user.stat == DEAD) // rip bozo
		user.lost_game()
	else
		user.won_game()
	user.forceMove(get_turf(get_step(src, dir))) /// leave the arena now and rest... you've earned it
	do_sparks(3, FALSE, get_turf(user))
	if(our_player.ckey)
		winners_and_losers += our_player.ckey
	our_player = null
	QDEL_NULL(our_reservation)
	QDEL_NULL(our_current_template)

/// Sanitycheck to prevent exploitation / repeat plays
/obj/machinery/computer/arcade/collapsing_rift/proc/check_target_eligibility(mob/to_be_checked)
	if(!iscarbon(to_be_checked))
		return // Some of these rely on hands and would absolutely just kill other people.
	if(to_be_checked.ckey in winners_and_losers) // this also blocks people who've respawned from playing again but. good. honestly
		say("YOUR SYNAPSES ARE NOT READY FOR ANOTHER SESSION. RETURN IN ONE DAY'S - CST - TIME.")
		return
	if(tgui_alert(to_be_checked, "You feel [src] pulling you inwards as your hands reach for the controls... are you sure you want to do this?", "Death Wish?", list("Yes", "No")) == "No")
		return
	if(!src.Adjacent(to_be_checked))
		to_chat(to_be_checked, span_warning("You too far away from [src] to enter it!"))
		return FALSE
	if(to_be_checked.incapacitated)
		to_chat(to_be_checked, span_warning("You aren't able to activate [src] anymore!"))
		return FALSE
	return TRUE

/// EXIT ///
/obj/structure/collapsing_rift_hatch
	name = "escape hatch"
	desc = "Don't look a gift horse in the mouth; climb inside!"
	icon = /obj/machinery/disposal/bin::icon
	icon_state = /obj/machinery/disposal/bin::icon_state
	/// Weakref to the arcade/bin we're linked to
	var/datum/weakref/connected_bin_or_arcade
	/// Hatch ID. What other hatch are we connected to, if any?
	var/hatch_id

/obj/structure/collapsing_rift_hatch/Initialize(mapload)
	. = ..()
	if(hatch_id)
		for(var/obj/structure/collapsing_rift_hatch/found_hatch in src.loc)
			if(found_hatch == src)
				continue
			if(found_hatch.hatch_id == hatch_id)
				connected_bin_or_arcade = WEAKREF(found_hatch)
				return

/obj/structure/collapsing_rift_hatch/mouse_drop_receive(mob/living/target, mob/user, params)
	. = ..()
	var/target_atom = connected_bin_or_arcade.resolve()
	if(!target_atom) // shit's fucked
		to_chat(target, "The [src] rejects you! That can't be good!")
		return
	if(istype(target_atom, /obj/machinery/computer/arcade/collapsing_rift))
		var/obj/machinery/computer/arcade/collapsing_rift/found_arcade = target_atom
		if(target == found_arcade.our_player)
			found_arcade.yank_em_out(found_arcade.our_player)
			return
	/// Not an arcade but a hatch; just tp them outright
	do_sparks(3, FALSE, get_turf(target))
	target.forceMove(get_turf(target_atom))

/// TURF RESERVATION ///
/datum/turf_reservation/rift_reservation
	var/datum/map_template/collapsing_rift/rift_template

/// MAP TEMPLATES ///
/datum/map_template/collapsing_rift
	var/landing_zone_x_offset
	var/landing_zone_y_offset

/datum/map_template/collapsing_rift/deep_space_one
	name = "Collapsing Rift - Deep Space One"
	mappath = "_maps/nova/collapsing_rifts/desone.dmm"
	landing_zone_x_offset = 14
	landing_zone_y_offset = 5

/// AREA ///
/area/misc/collapsing_rift
	name = "Collapsing Rift"
	icon = 'icons/area/areas_ruins.dmi'
	icon_state = "hilbertshotel"
	requires_power = FALSE
	default_gravity = STANDARD_GRAVITY
	area_flags = NOTELEPORT | HIDDEN_AREA | UNLIMITED_FISHING
	static_lighting = TRUE
	mood_bonus = /area/centcom/holding::mood_bonus
	mood_message = span_bold("I need to leave.")
	var/datum/turf_reservation/reservation

/// TURFS ///
/turf/open/chasm/collapsing_rift
	name = "Collapsing Rift"
	desc = "The consequences for messing with time have never been so much fun! You should probably be running, though."
	icon = 'modular_nova/modules/aesthetics/floors/icons/floors.dmi'
	icon_state = "collapsingrift"
	opacity = FALSE
	smoothing_flags = NONE
	canSmoothWith = NONE
	baseturfs = /turf/open/chasm/collapsing_rift
	light_range = 4 //need some visibility for chasm turfs, no matter the type
	light_power = 1
	light_color = COLOR_STARLIGHT
