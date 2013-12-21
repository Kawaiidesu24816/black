/obj/item/weapon/hardware
	name = "Default hardware"
	var/broken = 0
	var/obj/machinery/newComputer/mainframe/mainframe

	var/temperature = T20C

	proc/Connect(var/obj/machinery/newComputer/mainframe/m)
		mainframe = m

	proc/Disconnect()
		mainframe = null

/obj/item/weapon/hardware/screen
	var/size = "200x200"
	var/width = 200
	var/heigth = 200

	proc/ChangeScreenSize(var/w, var/h)
		if(!isnum(w) || !isnum(h))
			return
		if(w < 100 || h < 100)
			return
		width = w
		heigth = h
		size = "[width + 200]x[heigth]"

////////////////////DISKS AND IDs//////////////////////////

/obj/item/weapon/hardware/authentication
	var/obj/item/weapon/card/id/id
	var/logged = 0
	var/username
	var/assignment
	var/list/access = list()

	proc/Login(var/inLog = 1)
		if(logged)
			world << "Trying to login when logged at [mainframe.x], [mainframe.y], [mainframe.z]"
		if(!id)
			return
		username = id.registered_name
		assignment = id.assignment
		access = id.access
		logged = 1
		if(inLog)
			mainframe.AddLogs("Logged as [username]")

	proc/Logout(var/inLog = 1)
		if(!logged)
			world << "Trying to logout when not logged at [mainframe.x], [mainframe.y], [mainframe.z]"
		username = ""
		assignment = ""
		access = list()
		logged = 0
		if(inLog)
			mainframe.AddLogs("Logged out")

	proc/Insert(var/obj/item/weapon/card/id/insertedID)
		if(id)
			usr << "\red You can't insert your ID into slot. Something prevent it."
			return
		if(istype(insertedID.loc, /mob))
			var/mob/user = insertedID.loc
			user.drop_item()
		insertedID.loc = src
		id = insertedID

	proc/Eject()
		if(!id)
			return
		id.loc = mainframe.loc
		id = null

/obj/item/weapon/hardware/datadriver
	var/obj/item/weapon/hardware/memory/disk/data

	proc/Insert(var/obj/item/weapon/hardware/memory/disk/d)
		if(data)
			usr << "\red You can't insert your disc into driver. Something prevent it."
			return
		if(istype(d.loc, /mob))
			var/mob/user = d.loc
			user.drop_item()
		d.loc = src
		data = d

	proc/Eject()
		if(!data)
			return
		data.loc = mainframe.loc
		data = null

/////////////////////////MEMORY/////////////////////

/obj/item/weapon/hardware/memory
	name = "Memory"
	var/total_memory = 30
	var/current_free_space = 30
	var/list/datum/software/data = list()

	proc/ChangeMemorySize(var/value)
		total_memory = value
		current_free_space = value
		data = list()

	proc/WriteOn(var/datum/software/soft)
		if(soft in data)
			return 0
		if(soft.size > current_free_space)
			return 0
		data += soft
		current_free_space -= soft.size
		return 1

	proc/Remove(var/datum/software/soft)
		if(!(soft in data))
			return 0
		data -= soft
		current_free_space = min(total_memory, current_free_space + soft.size)

	proc/Space()
		return "[current_free_space] of [total_memory] TeraByte"


/obj/item/weapon/hardware/memory/harddrive
	total_memory = 50
	current_free_space = 50

	proc/CanInstall(var/datum/software/soft)
		if(soft in data)
			return "This soft is already installed"
		if(soft.size > current_free_space)
			return "\red You have not enough space for install"
		return "\green All ready for installing"

/obj/item/weapon/hardware/memory/disk
	icon = 'icons/obj/cloning.dmi'
	icon_state = "datadisk0"
	item_state = "card-id"
	var/protected = 0

	WriteOn(var/datum/software/soft)
		if(!protected)
			..(soft)

	Remove(var/datum/software/soft)
		if(!protected)
			..(soft)

	verb/Flip()
		set src in view(1)
		protected = !protected
		usr << "You [protected ? "close" : "open"] disk to write"