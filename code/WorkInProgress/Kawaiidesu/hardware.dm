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
		if(w < 300 || h < 300)
			return
		width = w
		heigth = h
		size = "[width]x[heigth]"

////////////////////DISKS AND IDs//////////////////////////

/obj/item/weapon/hardware/authentication
	var/obj/item/weapon/card/id/id
	var/logged = 0
	var/username = "unknown"
	var/assignment = "unassigned"
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
		if(inLog && mainframe.sys)
			mainframe.sys.AddLogs("Logged as [username]")

	proc/Logout(var/inLog = 1)
		if(!logged)
			world << "Trying to logout when not logged at [mainframe.x], [mainframe.y], [mainframe.z]"
		username = "unknown"
		assignment = "unassigned"
		access = list()
		logged = 0
		if(inLog && mainframe.sys)
			mainframe.sys.AddLogs("Logged out")

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

	proc/CheckAccess(var/list/input)
		world << input.len
		world << "----"
		world << access.len
		for(var/req in input)
			if(req in access)
				world << "[req] is right"
				return 1
		return 0

/obj/item/weapon/hardware/datadriver
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
	total_memory = 50
	current_free_space = 50


/obj/item/weapon/hardware/memory/disk
	icon = 'icons/obj/cloning.dmi'
	icon_state = "datadisk0"
	item_state = "card-id"
	var/list/default_soft = list(
	"/datum/software/app/medical_records"              ,\
	)
	var/protected = 0

	New()
		..()
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
	var/address = ""

	New()
		..()
		GenerateAddress()

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

/datum/netconnection
	var/datum/netconnection/node
	var/datum/software/soft
	var/address
	var/id

	proc/Clear()
		del src