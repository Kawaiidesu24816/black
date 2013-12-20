/obj/item/weapon/hardware
	name = "Default hardware"
	var/broken = 0

	var/temperature = T20C

/obj/item/weapon/hardware/screen
	var/size = "200x200"

	proc/ChangeScreenSize(var/width, var/heigth)
		if(!isnum(width) || !isnum(heigth))
			return
		if(width < 100 || heigth < 100)
			return
		size = "[width]x[heigth]"

/obj/item/weapon/hardware/harddrive
	var/total_space = 50
	var/current_free_space = 50
	var/list/datum/software/data = list()

	proc/ChangeMemorySize(var/value)
		total_space = value
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

	proc/Uninstall(var/datum/software/soft)
		if(!(soft in data))
			return 0
		data -= soft
		current_free_space = min(total_space, current_free_space + soft.size)

/obj/item/weapon/hardware/authentication
	var/obj/item/weapon/id/id

	proc/CheckAccess(var/list/required_access)
		if(required_access.len <= 0)
			return 1
		accesses = required_access & id.access
		world << accesses
		if(accesses.len > 0)
			return 1
		return 0