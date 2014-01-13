/obj/mecha/reworked
	icon_state = "ripley"
	initial_icon = "ripley"

	var/intent
	var/curr_mod = "lhand"
	var/obj/item/weapon/mechpart/rhand
	var/obj/item/weapon/mechpart/lhand
	var/obj/item/weapon/mechpart/back

	New()
		..()
		AttachPart(new /obj/item/weapon/mechpart/hand/right(src))
		AttachPart(new /obj/item/weapon/mechpart/hand/left(src))

	proc/AttachPart(obj/item/weapon/mechpart/part)
		if(!part.slot) return
		switch(part.slot)
			if("rhand")
				if(!rhand)
					rhand = part
					if(usr) usr.drop_item()
					part.loc = src
			if("lhand")
				if(!lhand)
					lhand = part
					if(usr) usr.drop_item()
					part.loc = src
			if("back")
				if(!back)
					back = part
					if(usr) usr.drop_item()
					part.loc = src
		update_icon()

	proc/DetachPart(slot)
		switch(slot)
			if("rhand")
				if(rhand)
					rhand.loc = src.loc
					rhand = null
			if("lhand")
				if(lhand)
					lhand.loc = src.loc
					lhand = null
			if("back")
				if(back)
					back.loc = src.loc
					back = null
		update_icon()

	proc/SetIntent(i)
		if(i in list("push", "grab", "harm", "destroy"))
			intent = i

	update_icon()
		..()
		overlays = list()
		if(rhand)
			overlays += image(rhand.icon, rhand.icon_state)
		if(lhand)
			overlays += image(lhand.icon, lhand.icon_state)
		if(back)
			overlays += image(back.icon, back.icon_state)

	moved_inside()
		if(!..()) return
		var/list/obj/screen/scr_lst = list()
		var/obj/screen/s
		if(lhand)
			s = new /obj/screen/mecha()
			s.name = "lhand"
			s.master = src
			s.icon = 'icons/mob/screen1_Orange.dmi'
			if(curr_mod == "lhand")
				s.icon_state = "hand_active"
			else
				s.icon_state = "hand_inactive"
			s.screen_loc = "7:16,2:12"
			scr_lst.Add(s)

		if(rhand)
			s = new /obj/screen/mecha()
			s.name = "rhand"
			s.master = src
			s.icon = 'icons/mob/screen1_Orange.dmi'
			if(curr_mod == "rhand")
				s.icon_state = "hand_active"
			else
				s.icon_state = "hand_inactive"
			s.screen_loc = "8:16,2:12"
			scr_lst.Add(s)

		occupant.client.screen += scr_lst

	go_out()
		if(!occupant) return
		if(occupant.client)
			for(var/obj/screen/scr in occupant.client.screen)
				if(istype(scr, /obj/screen/mecha))
					occupant.client.screen.Remove(scr)
		..()

/obj/item/weapon/mechpart
	name = "Mech parts"
	health = 100
	icon = 'parts.dmi'
	var/slot = "Nothing"
	var/icon_std  //Standard

	New()
		..()
		update_icon()

	update_icon()
		if(health > 80)
			icon_state = icon_std + "_std"
		else if(health > 0)
			icon_state = icon_std + "_dmg"
		else
			icon_state = icon_std + "_dst"

/obj/item/weapon/mechpart/hand

/obj/item/weapon/mechpart/hand/right
	slot = "rhand"
	icon_std = "rhand"

/obj/item/weapon/mechpart/hand/left
	slot = "lhand"
	icon_std = "lhand"

/obj/screen/mecha
	name = "mecha"

/obj/screen/mecha/Click(location, control, params)
	if(!istype(master, /obj/mecha/reworked)) return
	var/obj/mecha/reworked/m = master
	switch(name)
		if("lhand")
			if(m.lhand && m.curr_mod != "lhand")
				m.curr_mod = "lhand"
				m.update_screen()
		if("rhand")
			if(m.rhand && m.curr_mod != "rhand")
				m.curr_mod = "rhand"
				m.update_screen()

/obj/mecha/reworked/proc/update_screen()
	if(!occupant) return
	for(var/obj/screen/mecha/m in occupant.client.screen)
		switch(m.name)
			if("lhand")
				if(curr_mod == "lhand")
					m.icon_state = "hand_active"
				else
					m.icon_state = "hand_inactive"
			if("rhand")
				if(curr_mod == "rhand")
					m.icon_state = "hand_active"
				else
					m.icon_state = "hand_inactive"