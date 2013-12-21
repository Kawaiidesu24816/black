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
	var/datum/software/os/sys = null
	var/list/default_soft = list(
	"/datum/software/os" ,              \
	"/datum/software/app/texttyper"   , \
	"/datum/software/app/crew_monitor", \
	)

	var/obj/item/weapon/hardware/screen/screen
	var/obj/item/weapon/hardware/memory/harddrive/harddrive
	var/obj/item/weapon/hardware/authentication/auth
	var/obj/item/weapon/hardware/datadriver/datadriver


	New()
		..()
		InstallDefaultHardware()
		for(var/soft in default_soft)
			harddrive.WriteOn(new soft())

	proc/InstallDefaultHardware() //For changing default hardware in childs
		screen = new /obj/item/weapon/hardware/screen(src)
		screen.ChangeScreenSize(400,500)
		screen.Connect(src)

		harddrive = new /obj/item/weapon/hardware/memory/harddrive(src)
		harddrive.ChangeMemorySize(100)
		harddrive.Connect(src)

		auth = new /obj/item/weapon/hardware/authentication(src)
		auth.Connect(src)

		datadriver = new /obj/item/weapon/hardware/datadriver(src)
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
			text = "\red Screen is broken :("
		else if(sys)
			text = sys.Display(user)

		else
			text = "Welcome to NanoTrasen BIOS.<BR>"
			text += "Prepared for loading. Please, choose OS to boot:<BR>"
			for(var/datum/software/os/s in harddrive.data)
				text += "<A href='?src=\ref[src];OS=\ref[s]'>[s.name]</A><BR>"
		user.set_machine(src)
		user << browse(text, "window=mainframe;size=[screen.size];can_resize=0")
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

		updateUsrDialog()


	Topic(href, href_list)
		if(href_list["on-close"])
			usr.unset_machine()
			usr << browse(null, "window=mainframe")

		else if(href_list["BIOS"])
			SetCurrentOS(null)

		else if(href_list["OS"])
			var/datum/software/os = locate(href_list["OS"])
			if(!os || !(os in harddrive.data)) return
			SetCurrentOS(os)

		else if(href_list["ejectid"])
			if(auth) auth.Eject()

		else if(href_list["ejectdisk"])
			if(datadriver) datadriver.Eject()

		else if(href_list["login"])
			if(auth) auth.Login()

		else if(href_list["logout"])
			if(auth) auth.Logout()

		else if(sys)
			sys.Topic(href, href_list)

		updateUsrDialog()

	proc/SetCurrentOS(var/datum/software/os/newos = null)

		if(newos && newos in harddrive.data)
			sys = newos
			sys.Load(src)
		else
			sys = null
			auth.Logout(0)
		update_icon()

	update_icon()
		if(stat & NOPOWER || !on)
			icon_state = "command[screen.broken ? "b" : "0"]"
		else if(sys)
			icon_state = sys.GetIconName() + "[screen.broken ? "b" : ""]"
		else
			icon_state = "command[screen.broken ? "b" : ""]"

	power_change()
		SetCurrentOS(null)

	proc/AddLogs(var/text)
		if(sys)
			sys.AddLogs(text)

	proc/SetIcon(var/text)
		if(!text)
			icon_state = "command[on ? "" : "0"]"
		else
			icon_state = text