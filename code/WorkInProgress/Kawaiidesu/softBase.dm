//There is soft vars and methods declaration
//Use this to make new soft easy

/datum/software
	var/name = "Default software."
	var/size = 0
	var/obj/machinery/newComputer/mainframe/M
	var/display_icon = "command"
	var/id = ""

	//Output. Used in computer
	//Return: string of display you want
	proc/Display(var/mob/user)
		return ""

	//Connecting with main
	proc/Connect(var/obj/machinery/newComputer/mainframe/m)
		M = m
		GenerateID()

	//Disconnect to prevent using programms when hdd is disconnected
	proc/Disconnect()
		M = null
		id = null

	proc/Connected()
		if(M)
			return 1
		return 0

	//Menu controls. If you want to make some protection you will do it in SecurityCheck() in computer
	Topic(href, href_list)
		return

	//Create new instance of soft
	//Return: new same type object
	proc/Copy()
		return new type()

	//Network. This stuff will catch global request after processing in connector
	proc/Request(var/datum/connectdata/sender, var/list/data)
		return

	//Check of required hardware before launch
	//Return: 0 if ready or string of problem
	proc/Requirements()
		return 0

	proc/GetName()
		return name

	//Events
	proc/OnStart()
		return

	proc/OnExit()
		return

	//Called by computer every processing tick
	proc/Update()
		return

	//Called by auth so we know we have auth
	proc/LoginChange()
		if(Requirements())
			M.CloseApp()

	//Called by computer so we DON'T know we have or not any hardware
	proc/HardwareChange()
		if(Requirements())
			M.CloseApp()

	///////////////////////////////////////////
	//Don't change this stuff without necessity

	//Update window
	proc/updateUsrDialog()
		M.updateUsrDialog()

	//Unique local ID
	//Edit by: Editor TEH Chaos-neutral
	proc/GenerateID()
		var/idlist = list()
		for (var/datum/software/soft in M.Data())
			if (soft != src)
				idlist += soft.id
		var/newid = rand(1000, 9999)
		while (newid in idlist)
			newid = rand(1000, 9999)
		id = newid

	//ID and IP
	proc/GlobalAddress()
		if(!M.NetworkTrouble())
			return new /datum/connectdata(M.connector.address, id)
		return new /datum/connectdata("Local", id)

	///////////////////////////////////////////

/datum/software/app
	var/list/required_access = list() //Not a req_one_access cause we have own auth sys
	var/required_sys = /datum/software/os/sos

	proc/Exit()
		M.sys.Close()

/datum/software/os
	name = "Default OS"
	size = 10
	display_icon = "ai-fixer"
	var/list/logs = list()

	proc/AddLogs(var/text)
		logs += text

	proc/GetIconName()
		return display_icon

	proc/Run(var/datum/software/soft)
		return

	proc/Close()
		return