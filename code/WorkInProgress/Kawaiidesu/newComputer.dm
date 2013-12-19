/obj/machinery/newComputer/mainframe
	name = "Computer"
	desc = "Meow"
	icon = 'icons/obj/computer.dmi'
	icon_state = "command0"
	density = 1
	anchored = 1

	use_power = 1
	idle_power_usage = 1
	active_power_usage = 8
	power_channel = 0

	var/on = 0
	var/total_storage_space = 50
	var/current_screen = ""
	var/datum/software/current_soft = null
	var/list/datum/software/all_soft = new /list()

	New()
		all_soft += new /datum/software/OS()

	proc/TurnOn()
		if(stat & NOPOWER || use_power == 2)
			return
		use_power = 2
		on = 1
		update_icon()

	proc/TurnOff()
		use_power = 1
		on = 0
		update_icon()

	attack_hand(var/mob/user as mob)
		if(!on)
			TurnOn()
			return
		if(current_soft)
			user.set_machine(src)
			current_screen = current_soft.Display()
			user << browse(current_screen, "window=mainframe;size=400x500;can_resize=0")
			onclose(user,"mainframe")
		else
			current_screen = "Welcome to NanoTrasen BIOS.<BR>"
			current_screen += "Prepared for loading. Please, choose OS to load:<BR>"
			for(var/datum/software/s in all_soft)
				if(s.isOS())
					current_screen += "<A href='?src=\ref[src];OS=\ref[s]'>[s.name]</A><BR>"

			user.set_machine(src)
			user << browse(current_screen, "window=mainframe;size=400x500;can_resize=0")
			onclose(user,"mainframe")
		update_icon()
		return


	Topic(href, href_list)
		if(href_list["BIOS"])
			SetCurrentSoft(null)
			attack_hand(usr)
			return

		if(href_list["OS"])
			var/datum/software/os = locate(href_list["OS"])
			if(!os || !(os in src.all_soft)) return
			SetCurrentSoft(os)
			attack_hand(usr)
			return

		if(current_soft)
			current_soft.Topic(href)
			attack_hand(usr)
			return

		return

	proc/SetCurrentSoft(var/datum/software/soft = null)
		current_soft = soft
		if(soft)
			soft.Load(src)

	update_icon()
		if(stat & NOPOWER || !on)
			icon_state = "command0"
		else if(current_soft)
			icon_state = current_soft.display_icon_state
		else
			icon_state = "command"

	power_change()
		SetCurrentSoft(null)
		update_icon()


/datum/software
	var/name = "Default software."
	var/size = 0
	var/obj/machinery/newComputer/mainframe/mainframe
	var/current_text = ""
	var/display_icon_state = "command"

	proc/Display()
		return current_text

	proc/isOS()
		return 0

	proc/isApp()
		return 1

	proc/Load(var/obj/machinery/newComputer/mainframe/M)
		mainframe = M
		return

	Topic(href)
		return


/datum/software/OS
	name = "Default OS"
	display_icon_state = "ai-fixer"

	current_text = "Welcome to Station Operation System (SOS)"

	Display()
		return current_text

	isOS()
		return 1

	isApp()
		return 0

	Load(var/obj/machinery/newComputer/mainframe/M)
		..(M)
		current_text = "Welcome to Station Operation System (SOS)<BR>"
		current_text += "Current machine is [M].<BR>"
		current_text += "<A href='?src=\ref[M];BIOS=1'>Reset</A><BR>"