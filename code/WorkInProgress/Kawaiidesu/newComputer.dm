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
	var/current_screen_text = ""
	var/datum/software/current_soft = null

	var/list/default_soft = list(
	"/datum/software/OS" ,              \
	"/datum/software/app/textprinter" , \
	"/datum/software/app/crew_monitor", \
	)

	var/obj/item/weapon/hardware/screen/screen
	var/obj/item/weapon/hardware/memory/harddrive/harddrive
	var/obj/item/weapon/hardware/authentication/auth
	var/obj/item/weapon/hardware/datadriver/datadriver


	New()
		..()
		InstallHardware()

		for(var/soft in default_soft)
			harddrive.WriteOn(new soft())

	proc/InstallHardware() //For changing default hardware in childs
		screen = new /obj/item/weapon/hardware/screen(src)
		screen.ChangeScreenSize(400,500)
		screen.Connect(src)

		harddrive = new /obj/item/weapon/hardware/memory/harddrive(src)
		harddrive.ChangeMemorySize(100)
		harddrive.Connect(src)

		auth = new /obj/item/weapon/hardware/authentication(src)
		auth.Connect(src)

		datadriver = new /obj/item/weapon/hardware/authentication(src)
		datadriver.Connect(src)


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
		if(screen.broken)
			user.set_machine(src)
			user << browse("\red Screen is broken :(", "window=mainframe;size=[screen.size];can_resize=0")
			onclose(user,"mainframe")

		else if(current_soft)
			user.set_machine(src)
			current_screen_text = Header() + current_soft.Display(user) + Footer()
			user << browse(current_screen_text, "window=mainframe;size=[screen.size];can_resize=0")
			onclose(user,"mainframe")

		else
			current_screen_text = "Welcome to NanoTrasen BIOS.<BR>"
			current_screen_text += "Prepared for loading. Please, choose OS to boot:<BR>"
			for(var/datum/software/s in harddrive.data)
				if(s.isOS())
					current_screen_text += "<A href='?src=\ref[src];OS=\ref[s]'>[s.name]</A><BR>"

			user.set_machine(src)
			user << browse(current_screen_text, "window=mainframe;size=[screen.size];can_resize=0")
			onclose(user,"mainframe")

	attack_ai(var/mob/user as mob)
		world << "AI interact doesn't work right now"

	attack_paw(var/mob/user as mob)
		world << "Creature interact doesn't work right now"

	attackby(obj/item/O as obj, mob/user as mob)
		if(istype(O, /obj/item/weapon/card/id))
			if(auth)
				auth.Insert(O)
			else
				usr << "You can't find auth slot"
		else if(istype(O, /obj/item/weapon/hardware/memory/disk))
			if(datadriver)
				datadriver.Insert(O)
			else
				usr << "You can't find disk reader"


	Topic(href, href_list)
		if(href_list["on-close"])
			usr.unset_machine()
			usr << browse(null, "window=mainframe")

		if(href_list["BIOS"])
			SetCurrentSoft(null)

		else if(href_list["OS"])
			var/datum/software/os = locate(href_list["OS"])
			if(!os || !(os in harddrive.data)) return
			SetCurrentSoft(os)

		else if(current_soft)
			current_soft.Topic(href, href_list)

		src.updateUsrDialog()

		return

	proc/SetCurrentSoft(var/datum/software/soft = null)

		if(soft && soft in harddrive.data)
			current_soft = soft
			soft.Load(src)
		else
			current_soft = null
		update_icon()

	update_icon()
		if(stat & NOPOWER || !on)
			icon_state = "command[screen.broken ? "b" : "0"]"
		else if(current_soft)
			icon_state = current_soft.display_icon_state + "[screen.broken ? "b" : ""]"
		else
			icon_state = "command[screen.broken ? "b" : ""]"

	power_change()
		SetCurrentSoft(null)

	proc/Header()
		var/text = "<html><head><style type='text/css'>"
		text += ".prog{width:[screen.width]px;heigth:[screen.heigth]px;float:left;}"
		text += ".sys{width:200px;height:[screen.heigth]px;float:right;}"
		text += "</style></head><body><div class='prog'>"
		return text

	proc/Footer()
		var/text = "</div><div class='sys'>"
		if(auth.logged)
			text += "Logged in as [auth.username]<BR>"
			text += "[auth.assignment]"
			text += "<A href='?src=\ref[src];ejectid=1'>Eject ID</A>"
		else
			text += "Please <A href='?src=\ref[src];login=1'>login</A>"
		text += "</div></body></html>"
		return text