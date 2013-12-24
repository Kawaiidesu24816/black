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
	"/datum/software/os/sos"              ,\
	"/datum/software/app/texttyper"       ,\
	"/datum/software/app/crew_monitor"    ,\
	"/datum/software/app/medical_records" ,\
	"/datum/software/app/textfile"        ,\
	)

	//Hardware
	var/obj/item/weapon/hardware/screen/screen
	var/obj/item/weapon/hardware/memory/hdd/hdd
	var/obj/item/weapon/hardware/authentication/auth
	var/obj/item/weapon/hardware/datadriver/reader


	New()
		..()
		InstallDefault()

	proc/InstallDefault() //For changing default hardware and soft in childs
		screen = new /obj/item/weapon/hardware/screen(src)
		screen.ChangeScreenSize(400,500)
		screen.Connect(src)

		hdd = new /obj/item/weapon/hardware/memory/hdd(src)
		hdd.ChangeMemorySize(25)
		hdd.Connect(src)

		auth = new /obj/item/weapon/hardware/authentication(src)
		auth.Connect(src)

		reader = new /obj/item/weapon/hardware/datadriver(src)
		reader.Connect(src)

		hdd.WriteOn(new /datum/software/os/sos(), 1)
		hdd.WriteOn(new /datum/software/app/texttyper(), 1)
		hdd.WriteOn(new /datum/software/app/crew_monitor(), 1)
		hdd.WriteOn(new /datum/software/app/medical_records(), 1)
		hdd.WriteOn(new /datum/software/app/textfile(), 1)

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
		usr.unset_machine()
		usr << browse(null, "window=mainframe")
		LaunchOS(null)

	attack_hand(var/mob/user as mob)
		if(!on)
			TurnOn()
			return
		var/t = ""
		if(sys)
			t = sys.Display(user)
		else
			t = "Welcome to NanoTrasen BIOS.<BR>"
			t += "Prepared for loading. Please, choose OS to boot:<BR>"
			for(var/datum/software/os/s in hdd.data)
				t += "<A href='?src=\ref[src];OS=\ref[s]'>[s.name]</A><BR>"
		user.set_machine(src)
		user << browse(t, "window=mainframe;size=[screen.size];can_resize=0")
		onclose(user,"mainframe")
		update_icon()

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
			if(reader)
				reader.Insert(O)
			else
				usr << "You can't find disk reader"

		updateUsrDialog()


	Topic(href, href_list)
		if(href_list["on-close"])
			usr.unset_machine()
			usr << browse(null, "window=mainframe")

		else if(href_list["turnoff"])
			TurnOff()
			return

		else if(href_list["BIOS"])
			LaunchOS(null)

		else if(href_list["OS"])
			var/datum/software/os = locate(href_list["OS"])
			if(!os || !(os in hdd.data)) return
			LaunchOS(os)

		else if(href_list["hddwriteon"])
			if(hdd)
				var/datum/software/soft = locate(href_list["hddwriteon"])
				hdd.WriteOn(locate(soft))
				soft.Setup(src)

		else if(href_list["hddremove"])
			if(hdd)
				var/datum/software/soft = locate(href_list["hddwriteon"])
				hdd.Remove(locate(soft))

		else if(href_list["diskwriteon"])
			if(!ReaderProblem()) reader.disk.WriteOn(locate(href_list["diskwriteon"]))

		else if(href_list["diskremove"])
			if(!ReaderProblem()) reader.disk.Remove(locate(href_list["diskremove"]))

		else if(href_list["ejectid"])
			if(auth) auth.Eject()

		else if(href_list["ejectdisk"])
			if(reader) reader.Eject()

		else if(href_list["login"])
			if(auth) auth.Login()

		else if(href_list["logout"])
			if(auth) auth.Logout()

		else if(sys)
			sys.Topic(href, href_list)

		updateUsrDialog()

	proc/LaunchOS(var/datum/software/os/newos = null)

		if(newos && newos in hdd.data)
			sys = newos
			sys.Setup(src)
		else
			sys = null
			if(auth.logged)
				auth.Logout(0)

	proc/AccessProblem(var/list/access)
		if(!auth)
			return 1
		if(!auth.logged)
			return 2
		if(!auth.CheckAccess(access))
			return 3
		return 0

	proc/MemoryProblem()
		if(!hdd)
			return 1
		return 0

	proc/ReaderProblem()
		if(!reader)
			return 1
		if(!reader.disk)
			return 2
		return 0

	update_icon()
		if(stat & NOPOWER || !on)
			icon_state = "command[screen.broken ? "b" : "0"]"
		else if(sys)
			icon_state = sys.GetIconName() + "[screen.broken ? "b" : ""]"
		else
			icon_state = "command[screen.broken ? "b" : ""]"

	power_change()
		LaunchOS(null)

	process()
		if(on && sys)
			for(var/datum/software/soft in hdd.data)
				soft.Update()
