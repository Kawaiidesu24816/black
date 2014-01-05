/obj/item/weapon/hardware
	name = "Default hardware"
	icon = 'icons/obj/newComp.dmi'
	var/broken = 0
	var/hardware_type = "nothing"
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
		if(w < 300 || h < 300)
			return
		width = w
		heigth = h
		size = "[width]x[heigth]"

////////////////////DISKS AND IDs//////////////////////////

/obj/item/weapon/hardware/authentication
	name = "Auth module"
	hardware_type = "auth"

	var/obj/item/weapon/card/id/id
	var/logged = 0
	var/username = "unknown"
	var/assignment = "unassigned"
	var/list/access = list()

	Disconnect()
		logged = 0
		username = "unknown"
		assignment = "unassigned"
		if(mainframe && mainframe.hdd)
			for(var/datum/software/soft in mainframe.hdd.data)
				soft.LoginChange()
		..()

	proc/Login(var/inLog = 1)
		if(!mainframe) return
		if(logged)
			world << "Trying to login when logged at [mainframe.x], [mainframe.y], [mainframe.z]"
		if(!id)
			return
		username = id.registered_name
		assignment = id.assignment
		access = id.access
		logged = 1
		if(mainframe.hdd)
			for(var/datum/software/soft in mainframe.hdd.data)
				soft.LoginChange()
		if(inLog && mainframe.sys)
			mainframe.sys.AddLogs("Logged as [username]")

	proc/Logout(var/inLog = 1)
		if(!mainframe) return
		if(!logged)
			world << "Trying to logout when not logged at [mainframe.x], [mainframe.y], [mainframe.z]"
		username = "unknown"
		assignment = "unassigned"
		access = list()
		logged = 0
		if(mainframe.hdd)
			for(var/datum/software/soft in mainframe.hdd.data)
				soft.LoginChange()
		if(inLog && mainframe.sys)
			mainframe.sys.AddLogs("Logged out")

	proc/Insert(var/obj/item/weapon/card/id/insertedID)
		//Separated checks is important cause player can insert an ID when auth module is removed
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

	proc/CheckAccess(var/list/input)
		if(input.len <= 0)
			return 1
		for(var/req in input)
			if(req in access)
				return 1
		return 0

/obj/item/weapon/hardware/datadriver
	name = "Data reader"
	icon_state = "datareader"
	hardware_type = "reader"
	var/obj/item/weapon/hardware/memory/disk/disk

	proc/Insert(var/obj/item/weapon/hardware/memory/disk/d)
		if(disk)
			usr << "\red You can't insert your disk into driver. Something prevent it."
			return
		if(istype(d.loc, /mob))
			var/mob/user = d.loc
			user.drop_item()
		d.loc = src
		disk = d

	proc/Eject()
		if(!disk)
			return
		disk.loc = mainframe.loc
		disk = null

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

	proc/WriteOn(var/datum/software/soft, var/expand = 0)
		soft = soft.Copy()
		if(soft.size > current_free_space)
			return 0
		data.Add(soft)
		if(expand)
			total_memory += soft.size
		else
			current_free_space -= soft.size
		return 1

	proc/Remove(var/datum/software/soft, var/decrease = 0)
		if(!(soft in data))
			return 0
		data.Remove(soft)
		if(decrease)
			total_memory -= soft.size
		else
			current_free_space = min(total_memory, current_free_space + soft.size)
		del soft

	proc/Space()
		return "[current_free_space] of [total_memory] TeraByte"

	proc/Problem(var/datum/software/soft)
		//for(var/datum/software/app in data)
		//	if(app.name == soft.name)
		//		return 1
		if(soft.size > current_free_space)
			return 2
		return 0


/obj/item/weapon/hardware/memory/hdd
	name = "Harddrive"
	icon_state = "harddrive"
	hardware_type = "hdd"
	total_memory = 50
	current_free_space = 50

	Connect(var/obj/machinery/newComputer/mainframe/m)
		..()
		for(var/datum/software/soft in data)
			soft.Setup(m)

	Disconnect()
		..()
		for(var/datum/software/soft in data)
			soft.Disconnect()


/obj/item/weapon/hardware/memory/disk
	icon_state = "disk0"
	item_state = "card-id"
	var/list/default_soft = list(
	"/datum/software/app/medical_records"              ,\
	)
	var/protected = 0

	New()
		..()
		icon_state = "disk[rand(0,1)]"
		for(var/soft in default_soft)
			WriteOn(new soft())

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

/////////////////////////WIRELESS CONNECTION/////////////////////////////

/obj/item/weapon/hardware/wireless/connector
	name = "Connector"
	hardware_type = "connector"
	var/address = ""

	Connect(var/obj/machinery/newComputer/mainframe/m)
		..()
		GenerateAddress()

	Disconnect()
		..()
		address = "Local"

	proc/GenerateAddress()
		address = "[rand(1000, 9999)]-[rand(1000, 9999)]"
		for(var/obj/item/weapon/hardware/wireless/connector/con in world)
			if(con.address == address && con != src)
				GenerateAddress()
				break

	proc/SendSignal(var/datum/connectdata/reciever, var/datum/connectdata/sender, var/list/data)
		if(reciever == null)
			reciever = new /datum/connectdata()
		for(var/obj/item/weapon/hardware/wireless/connector/con in world)
			if(con.address != sender.address)
				con.RecieveSignal(reciever, sender, data)

	proc/RecieveSignal(var/datum/connectdata/reciever, var/datum/connectdata/sender, var/list/data)
		if(reciever.address && reciever.address != src.address)
			return //Refuse Connection
		if(!mainframe.on)
			return
		mainframe.RecieveSignal(reciever, sender, data)

/datum/connectdata
	var/address = ""
	var/id = ""

	New(var/a, var/i)
		address = a
		id = i

	proc/ToString()
		return address + ":" + id