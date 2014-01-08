//TO DO: DO SOMETHING WITH INSTALLING/REMOVING HARDWARE

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
	var/opened = 0
	var/datum/software/os/sys = null


	New()
		..()
		InstallDefault()

	proc/InstallDefault() //For changing default hardware and soft in childs
		var/obj/item/weapon/hardware/screen/screen = new /obj/item/weapon/hardware/screen(src)
		screen.ChangeScreenSize(500,500)
		hard.Add(screen)

		var/obj/item/weapon/hardware/memory/hdd/hdd = new /obj/item/weapon/hardware/memory/hdd(src)
		hdd.ChangeMemorySize(25)
		hard.Add(hdd)

		hard.Add(new /obj/item/weapon/hardware/authentication(src))

		hard.Add(new /obj/item/weapon/hardware/datadriver(src))

		hard.Add(new /obj/item/weapon/hardware/wireless/connector(src))

		for(var/item/weapon/hardware/h in hard)
			h.Connect(src)

		//It is more easy way than use list of strings of ways of default soft
		//hdd.WriteOn(new /datum/software/os/sos(), 1)
		//hdd.WriteOn(new /datum/software/app/textfile(), 1)

		//for(var/datum/software/soft in hdd.data)
		//	soft.Setup(src)

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
		if(SecurityAlert())
			usr.unset_machine()
			usr << browse(null, "window=mainframe")
			return
		if(opened)
			var/t = ""
			if(hdd)
				t += "<A href='?src=\ref[src];eject_module=hdd';usr=null>Eject [hdd.name]</A><BR>"
			if(auth)
				t += "<A href='?src=\ref[src];eject_module=auth'>Eject [auth.name]</A><BR>"
			if(reader)
				t += "<A href='?src=\ref[src];eject_module=reader'>Eject [reader.name]</A><BR>"
			if(connector)
				t += "<A href='?src=\ref[src];eject_module=connector'>Eject [connector.name]</A><BR>"
			user.set_machine(src)
			user << browse(t, "window=mainframe_hardware;size=250x400px")
			onclose(user,"mainframe")
		if(!on)
			TurnOn()
			return
		else if(hdd)
			var/t = ""
			if(sys)
				t = sys.Display(user)
			else
				t = "Welcome to NanoTrasen BIOS.<BR>"
				t += "Prepared for loading. Please, choose OS to boot:<BR>"
				for(var/datum/software/os/s in hdd.data)
					t += "<A href='?src=\ref[src];OS=\ref[s]'>[s.GetName()]</A><BR>"
			user.set_machine(src)
			user << browse(t, "window=mainframe;size=[screen.size];can_resize=0")
			onclose(user,"mainframe")
		else
			user.set_machine(src)
			user << browse("HDD is not found.", "window=mainframe;size=[screen.size];can_resize=0")
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
			if(reader)
				reader.Insert(O)
			else
				usr << "You can't find disk reader"
		else if(istype(O, /obj/item/weapon/hardware))
			Insert(O)

		updateUsrDialog()


	Topic(href, href_list)
		//Functionality Processing
		if(href_list["on-close"])
			usr.unset_machine()
			usr << browse(null, "window=mainframe")

		else if(href_list["turnoff"])
			TurnOff()

		else if(href_list["BIOS"])
			LaunchOS(null)

		else if(href_list["OS"])
			var/datum/software/os = locate(href_list["OS"])
			if(os && os in hdd.data) LaunchOS(os)

		else if(href_list["eject_module"])
			Eject(href_list["eject_module"])

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
			return //Update will be made in soft Topic()

		updateUsrDialog()

	proc/LaunchOS(var/datum/software/os/newos = null)

		if(newos && newos in hdd.data)
			sys = newos
			sys.Setup(src)
		else
			sys = null
			if(auth.logged)
				auth.Logout(0)
		update_icon()

	//Hardware problems
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

	proc/NetProblem()
		if(!connector)
			return 1
		return 0

	//Net stuff
	proc/RecieveSignal(var/datum/connectdata/reciever, var/datum/connectdata/sender, var/list/data)
		if(!on) return
		if(!hdd) return
		if(!sys) return
		if(!reciever.id)
			for(var/datum/software/soft in hdd.data)
				soft.Request(sender, data)
		else
			for(var/datum/software/soft in hdd.data)
				if(reciever.id == soft.id)
					soft.Request(sender, data)


	update_icon()//Change to overlays when sprites will be ready
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

	updateUsrDialog()
		if(!SecurityAlert())
			..()

	proc/HardwareChange()
		if(hdd)
			for(var/datum/software/soft in hdd.data)
				soft.HardwareChange()

	proc/SecurityAlert() //Protection against non-fair using
		if(!in_range(src, usr) && !istype(usr, /mob/living/silicon))
			world << "Security Alert in ([x], [y], [z]). Try to avoid any message like this."
			return 1
		return 0

	proc/Eject(var/module)
		world << usr
		switch(module)
			if("hdd")
				if(hdd)
					hdd.Disconnect()
					hdd.loc = src.loc
					hdd = null
					HardwareChange()
			if("auth")
				if(auth)
					auth.Disconnect()
					auth.loc = src.loc
					auth = null
					HardwareChange()
			if("reader")
				if(reader)
					reader.Disconnect()
					reader.loc = src.loc
					reader = null
					HardwareChange()
			if("connector")
				if(connector)
					connector.Disconnect()
					connector.loc = src.loc
					connector = null
					HardwareChange()

	proc/Insert(var/obj/item/weapon/hardware/module)
		if(module.hardware_type == "nothing")
			usr << "It's nothing. How you get it?"
			return

		switch(module.hardware_type)
			if("auth")
				if(istype(module.loc, /mob))
					usr.drop_item()
				module.loc = src
				auth = module
				auth.Connect(src)
				HardwareChange()
			if("hdd")
				if(istype(module.loc, /mob))
					usr.drop_item()
				module.loc = src
				hdd = module
				hdd.Connect(src)
				HardwareChange()
			if("reader")
				if(istype(module.loc, /mob))
					usr.drop_item()
				module.loc = src
				reader = module
				reader.Connect(src)
				HardwareChange()
			if("connector")
				if(istype(module.loc, /mob))
					usr.drop_item()
				module.loc = src
				connector = module
				connector.Connect(src)
				HardwareChange()
			else
				usr << "You can't insert this module"


