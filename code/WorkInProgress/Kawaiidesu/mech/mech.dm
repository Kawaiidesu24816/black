/obj/mecha/reworked
	icon_state = "ripley"
	initial_icon = "ripley"

	var/intent
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

	move_inside()
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