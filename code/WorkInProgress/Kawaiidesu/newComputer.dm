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
	)

	var/obj/item/weapon/hardware/screen/screen
	var/obj/item/weapon/hardware/harddrive/harddrive


	New()
		..()
		screen = new /obj/item/weapon/hardware/screen(src)
		screen.ChangeScreenSize(400,500)

		harddrive = new /obj/item/weapon/hardware/harddrive(src)
		harddrive.ChangeMemorySize(100)

		for(var/soft in default_soft)
			harddrive.Install(new soft())


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
			current_screen_text = current_soft.Display()
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


	Topic(href, href_list)
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
		current_soft = soft
		if(soft)
			soft.Load(src)
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


/datum/software
	var/name = "Default software."
	var/size = 0
	var/obj/machinery/newComputer/mainframe/mainframe
	var/display_icon_state = "command"

	proc/Display()
		return ""

	proc/isOS()
		return 0

	proc/isApp()
		return 1

	proc/Load(var/obj/machinery/newComputer/mainframe/M)
		mainframe = M
		return

	Topic(href, href_list)
		return


/datum/software/OS
	name = "Default OS"
	size = 10
	display_icon_state = "ai-fixer"
	var/current_state = "Mainscreen"

	Display()
		var/new_text = ""
		switch(current_state)
			if("Mainscreen")
				new_text = "Welcome to Station Operation System (SOS)<BR>"
				new_text += "Current machine is [mainframe].<BR>"
				new_text += "<A href='?src=\ref[src];filemanager=1'>Launch filemanager</A><BR>"
				new_text += "------<BR>"
				for(var/datum/software/app/app in mainframe.harddrive.data)
					new_text += "<A href='?src=\ref[src];runapp=\ref[app]'>[app.name]</A><BR>"
				new_text += "------<BR>"
				new_text += "<A href='?src=\ref[mainframe];BIOS=1'>Reboot</A><BR>"
			if("Filemanager")
				var/obj/item/weapon/hardware/harddrive/hard = mainframe.harddrive
				new_text = "Welcome to SOS File Manager. <A href='?src=\ref[src];mainscreen=1'>Return to main menu</A><BR>"
				new_text += "You have [hard.current_free_space] TeraByte memory of total [hard.total_memory].<BR>"
				new_text += "Installed programms is:<BR>"
				var/list/datum/software/apps = list()
				for(var/datum/software/soft in hard.data)
					if(soft.isOS())
						new_text += "\red [soft.name]<BR>"
					else
						apps += soft
				new_text += "------<BR>"
				for(var/datum/software/soft in apps)
					new_text += "[soft.name]<BR>"

		return new_text

	isOS()
		return 1

	isApp()
		return 0

	Load(var/obj/machinery/newComputer/mainframe/M)
		..(M)

	Topic(href, href_list)
		if(href_list["mainscreen"])
			current_state = "Mainscreen"
		else if(href_list["filemanager"])
			current_state = "Filemanager"
		else if(href_list["runapp"])
			var/datum/software/app/app = locate(href_list["runapp"])
			world << app
			mainframe.SetCurrentSoft(app)
			app.launchedBy = src
		mainframe.updateUsrDialog()

/datum/software/app
	var/datum/software/OS/launchedBy


/datum/software/app/textprinter
	name = "Text Printer"
	size = 5
	display_icon_state = "comm"

	Display()
		var/new_text = "Welcome to Text Printer 501.1217<BR>"
		new_text += "<A href='?src=\ref[src];exit=1'>Exit to [launchedBy.name].</A>"
		return new_text

	Topic(href, href_list)
		if(href_list["exit"])
			mainframe.SetCurrentSoft(launchedBy)
			mainframe.updateUsrDialog()


/obj/item/weapon/hardware
	name = "Default hardware"
	var/broken = 0

	var/procPower = 0 //Changing this var value will do nothing
	var/memory = 0    //Changing this var value will do nothing
	var/temperature = T20C

	proc/hasProcPower()
		return 0

	proc/hasMemory()
		return 0

/obj/item/weapon/hardware/screen
	var/size = "200x200"

	proc/ChangeScreenSize(var/width, var/heigth)
		if(!isnum(width) || !isnum(heigth))
			return
		if(width < 100 || heigth < 100)
			return
		size = "[width]x[heigth]"

/obj/item/weapon/hardware/harddrive
	var/total_memory = 50
	var/current_free_space = 50
	var/list/datum/software/data = list()

	proc/ChangeMemorySize(var/value)
		total_memory = value
		current_free_space = value
		data = list()

	proc/Install(var/datum/software/soft)
		if(soft in data)
			return 0
		if(soft.size > current_free_space)
			return 0
		data += soft
		current_free_space -= soft.size
		return 1
