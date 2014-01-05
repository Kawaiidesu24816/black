/datum/software
	var/name = "Default software."
	var/size = 0
	var/obj/machinery/newComputer/mainframe/mainframe
	var/display_icon = "command"
	var/id = ""

	//Output. Used in computer
	//Return: string of display you want
	proc/Display(var/mob/user)
		return ""

	//Connecting with main
	proc/Setup(var/obj/machinery/newComputer/mainframe/M)
		mainframe = M
		GenerateID()

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
		return

	//Called by computer so we DON'T know we have or not any hardware
	proc/HardwareChange()
		return

	///////////////////////////////////////////
	//Don't change this stuff without necessity

	//Update window
	proc/updateUsrDialog()
		mainframe.updateUsrDialog()

	//Unique local ID
	proc/GenerateID()
		id = "[rand(1000,9999)]"
		for(var/datum/software/soft in mainframe.hdd.data) //Soft are in hdd so we sure we have hdd
			if(soft.id == id && soft != src)
				GenerateID()
				break

	//ID and IP
	proc/GlobalAddress()
		if(!mainframe.NetProblem())
			return new /datum/connectdata(mainframe.connector.address, id)
		return new /datum/connectdata("Local", id)

	proc/Disconnect()
		mainframe = null
		id = null

	proc/Connected()
		if(mainframe)
			return 1
		return 0

	///////////////////////////////////////////

/datum/software/app
	var/list/required_access = list() //Not a req_one_access cause we have own auth sys
	var/required_os = /datum/software/os/sos

/datum/software/os
	name = "Default OS"
	size = 10
	display_icon = "ai-fixer"
	var/list/logs = list()

	Display(var/mob/user)
		return ""

	Setup(var/obj/machinery/newComputer/mainframe/M)
		..(M)

	proc/AddLogs(var/text)
		logs += text

	proc/GetIconName()
		return display_icon