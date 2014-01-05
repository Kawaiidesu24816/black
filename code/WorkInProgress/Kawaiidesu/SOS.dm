/datum/software/os/sos
	name = "SOS"
	size = 10
	display_icon = "ai-fixer"
	var/current_state = "mainscreen"
	var/lastlogs[5]
	var/datum/software/app/current_prog

	Display(var/mob/user)
		var/t = Header()
		if(current_prog)
			t +=  current_prog.Display()
		else
			switch(current_state)
				if("mainscreen")
					t += "Welcome to Station Operation System (SOS)<BR>"
					t += "<A href='?src=\ref[src];setstate=filemanager'>Launch filemanager</A><BR>"
					t += "------<BR>"
					for(var/datum/software/app/app in mainframe.hdd.data)
						t += "<A href='?src=\ref[src];runapp=\ref[app]'>[app.GetName()]</A><BR>"
					t += "------<BR>"
					t += "<A href='?src=\ref[mainframe];turnoff=1'>Turn Off</A><BR>"
					t += "<A href='?src=\ref[mainframe];BIOS=1'>Reboot</A><BR>"
				if("filemanager")
					var/rstate = mainframe.ReaderProblem()

					t += "Welcome to SOS File Manager."// <A href='?src=\ref[src];setstate=mainscreen'>Return to main menu</A><BR>"
					t += "You have [mainframe.hdd.Space()] memory.<BR>"
					t += "Installed programms is:<BR>"
					for(var/datum/software/os/soft in mainframe.hdd.data)
						t += "[soft.GetName()]<BR>"
					t += "------<BR>"
					for(var/datum/software/app/soft in mainframe.hdd.data)
						if(!rstate && !mainframe.reader.disk.Problem(soft))
							t += "<A href='?src=\ref[mainframe];diskwriteon=\ref[soft]'>(C)</A>"
						else
							t += "(C)"
						t += "<A href='?src=\ref[mainframe];hddremove=\ref[soft]'>(R)</A>"
						t += "[soft.GetName()]<BR>"
					t += "------<BR>"

					//Disk
					if(rstate == 1)
						t += "Datadriver is not found<BR>"
					else if(rstate == 2)
						t += "Please insert disk<BR>"
					else if(!rstate)
						t += "Disk have [mainframe.reader.disk.Space()] memory<BR>"
						t += "Files on disk<BR>"
						for(var/datum/software/soft in mainframe.reader.disk.data)
							if(!mainframe.hdd.Problem(soft))
								t += "<A href='?src=\ref[mainframe];hddwriteon=\ref[soft]'>(C)</A>"
							else
								t += "(C)"
							t += "<A href='?src=\ref[mainframe];diskremove=\ref[soft]'>(R)</A>"
							t += "[soft.name]<BR>"
				//if("sharescreen") MADNESS! NEVER UNCOMMENT THAT!
				//	if(connections.len > 0)
				//		for(var/datum/netconnection/con in connections)
				//			t += "SHARED SCREEN! <BR>"
				//			t += con.node.soft.Display(user)
				//			break
				//	else
				//		t += "<A href='?src=\ref[src];testsignal=1'>TEST</A><BR>"

		return t + Footer()

	Setup(var/obj/machinery/newComputer/mainframe/M)
		..(M)
		for(var/i = 1; i <= 5; i++)
			lastlogs[i] = ""

	Topic(href, href_list)
		if(href_list["setstate"])
			current_state = href_list["setstate"]

		else if(href_list["runapp"])
			var/s = locate(href_list["runapp"])
			if(istype(s, /datum/software/app))
				Run(s)

		else if(href_list["closeapp"])
			Close()

		updateUsrDialog()



		//<script language="javascript">
		//function send(type, value)
		//{
		//	window.location="byond://?src=\ref[src]&"type"="value";
		//}
		//</script>

	proc/Header()
		var/text = {"
		<html><head>
		<style type='text/css'>
		.prog{width:[mainframe.screen.width - 200]px;heigth:[mainframe.screen.heigth]px;float:left;}
		.sys{width:200px;height:[mainframe.screen.heigth]px;float:right;background:#ccc;position:absolute;top:0px;left:[mainframe.screen.width - 200]px;}
		</style>

		</head><body><div class='prog'>
		"}
		return text

	proc/Footer()
		var/text = "</div><div class='sys'>"
		if(mainframe.auth)
			if(mainframe.auth.logged)
				text += {"
				Logged in as [mainframe.auth.username]<BR>
				[mainframe.auth.assignment]<BR>
				<A href='?src=\ref[mainframe];logout=1'>Logout</A><BR>
				"}
			else
				text += "Please <A href='?src=\ref[mainframe];login=1'>login</A><BR>"
			if(mainframe.auth.id)
				text += "<A href='?src=\ref[mainframe];ejectid=1'>Eject ID</A><BR>"
		if(mainframe.reader)
			if(mainframe.reader.disk)
				text += "<A href='?src=\ref[mainframe];ejectdisk=1'>Eject Disk</A><BR>"
		if(current_prog || current_state != "mainscreen")
			text += "<A href='?src=\ref[src];closeapp=1'>Exit to main menu</A><BR>"
		text += "------<BR>"
		for(var/i = 1; i <= 5; i++)
			text += lastlogs[i] + "<BR>"
		text += "</div></body></html>"
		return text

	AddLogs(var/text)
		for(var/i = 5; i >= 2; i--)
			lastlogs[i] = lastlogs[i - 1]
		lastlogs[1] = text
		logs += text

	GetIconName()
		if(current_prog)
			return current_prog.display_icon
		return display_icon

	Request(var/datum/connectdata/sender, var/list/data)
		..()

	Run(var/datum/software/app/soft)
		Close()
		if(soft.Requirements()) return
		if(soft.required_sys && !soft.required_sys == src.type) return
		current_prog = soft
		current_prog.OnStart()
		mainframe.update_icon()

	Close()
		if(!current_prog) return
		current_prog.OnExit()
		current_prog = null
		mainframe.update_icon()