/// ENTRACNE ///
/obj/machinery/computer/arcade/collapsing_rift
	name = "IS-0083"
	desc = "An arcade machine, spewing an ominous black sludge..."
	circuit = /obj/item/circuitboard/computer/arcade/collapsing_rift
	/// If we have an active turf reservation, define it here.
	var/datum/turf_reservation/rift_reservation/our_reservation

/obj/item/circuitboard/computer/arcade/collapsing_rift
	name = "IS-0083"
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/computer/arcade/collapsing_rift

/obj/machinery/computer/arcade/collapsing_rift/attack_tk(mob/user)
	return // No remote escapes; please and thanks.

/obj/machinery/computer/arcade/collapsing_rift/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!iscarbon(user))
		return // Some of these rely on hands and would absolutely just kill other people.
	if(tgui_alert(user, "You feel the [src] pulling you inwards as your hands reach for the controls... are you sure you want to do this?", "Death Wish?", list("Yes", "No")) == "No")
		return
	if(our_reservation)
		balloon_alert(user, "in use!")
		return
	if(!check_target_eligibility(user))
		return
	user.played_game()
	var/datum/map_template/collapsing_rift/picked_template = pick(subtypesof(/datum/map_template/collapsing_rift))
	var/datum/turf_reservation/rift_reservation/new_reservation = SSmapping.request_turf_block_reservation(picked_template.width, picked_template.height, 1, reservation_type = /datum/turf_reservation/rift_reservation)
	var/turf/bottom_left = new_reservation.bottom_left_turfs[1]
	if(!bottom_left)
		to_chat(user, span_warning("Failed to reserve a game for you! Contact our technical support."))
		return
	picked_template.load(bottom_left)
	new_reservation.rift_template = picked_template
	our_reservation = new_reservation
	link_arcade_turfs(new_reservation)
	do_sparks(3, FALSE, get_turf(user))
	user.forceMove(locate(
		bottom_left.x + picked_template.landing_zone_x_offset,
		bottom_left.y + picked_template.landing_zone_y_offset,
		bottom_left.z,
	))
	// SHOG TODO: start timer here

/obj/machinery/computer/arcade/collapsing_rift/proc/link_arcade_turfs(datum/turf_reservation/rift_reservation/current_reservation)
	var/turf/rift_bottom_left = current_reservation.bottom_left_turfs[1]
	var/area/misc/condo/current_area = get_area(rift_bottom_left)
	current_area.reservation = current_reservation

/// Sanitycheck to prevent exploitation
/obj/machinery/computer/arcade/collapsing_rift/proc/check_target_eligibility(mob/to_be_checked)
	if(!src.Adjacent(to_be_checked))
		to_chat(to_be_checked, span_warning("You too far away from \the [src] to enter it!"))
		return FALSE
	if(to_be_checked.incapacitated)
		to_chat(to_be_checked, span_warning("You aren't able to activate \the [src] anymore!"))
		return FALSE
	return TRUE

/// EXIT ///

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
	landing_zone_x_offset = 2
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
