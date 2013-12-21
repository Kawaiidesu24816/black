/datum/software
	var/name = "Default software."
	var/size = 0
	var/obj/machinery/newComputer/mainframe/mainframe
	var/display_icon = "command"

	proc/Display(var/mob/user)
		return ""

	proc/Load(var/obj/machinery/newComputer/mainframe/M)
		mainframe = M
		return

	Topic(href, href_list)
		return

	proc/updateUsrDialog()
		mainframe.updateUsrDialog()

	proc/CheckAccess()
		return 1

	proc/Copy()
		return new type()

///////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////OS///////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/software/os
	name = "Default OS"
	size = 10
	display_icon = "ai-fixer"
	var/current_state = "Mainscreen"
	var/datum/software/app/current_prog
	var/lastlogs[5]
	var/list/alllogs = list()

	Display(var/mob/user)
		var/text = Header()
		if(current_prog)
			text +=  current_prog.Display()
		else
			switch(current_state)
				if("Mainscreen")
					text += "Welcome to Station Operation System (SOS)<BR>"
					text += "Current machine is [mainframe].<BR>"
					text += "<A href='?src=\ref[src];filemanager=1'>Launch filemanager</A><BR>"
					text += "------<BR>"
					for(var/datum/software/app/app in mainframe.harddrive.data)
						text += "<A href='?src=\ref[src];runapp=\ref[app]'>[app.name]</A><BR>"
					text += "------<BR>"
					text += "<A href='?src=\ref[mainframe];BIOS=1'>Reboot</A><BR>"
				if("Filemanager")
					text += "Welcome to SOS File Manager. <A href='?src=\ref[src];mainscreen=1'>Return to main menu</A><BR>"
					text += "You have [mainframe.harddrive.Space()] memory.<BR>"
					text += "Installed programms is:<BR>"
					for(var/datum/software/os/soft in mainframe.harddrive.data)
						text += "\red[soft.name]<BR>"
					text += "------<BR>"
					for(var/datum/software/app/soft in mainframe.harddrive.data)
						text += "<A href='?src=\ref[src];removesoft=\ref[soft]'>(R)</A>[soft.name]<BR>"
					text += "------<BR>"
					if(!mainframe.datadriver)
						text += "\red Datadriver not found.<BR>"
					else
						text += "Prepared to install<BR>"
						if(mainframe.datadriver.disk)
							for(var/datum/software/soft in mainframe.datadriver.disk.data)
								var/state = mainframe.harddrive.Problem(soft)
								if(!state)
									text += "\green <A href='?src=\ref[src];installsoft=\ref[soft]'>[soft.name]</A>"
								else if(state == 1)
									text += "[soft.name] is already installed."
								else if(state == 2)
									text += "\red Have not enough space to install [soft.name]"
								text += "<BR>"
						else
							text += "Datadriver is ready to read disk"

		return text + Footer()

	Load(var/obj/machinery/newComputer/mainframe/M)
		..(M)
		for(var/i = 1; i <= 5; i++)
			lastlogs[i] = ""

	Topic(href, href_list)
		if(href_list["mainscreen"])
			current_state = "Mainscreen"
		else if(href_list["filemanager"])
			current_state = "Filemanager"
		else if(href_list["runapp"])
			var/datum/software/app/app = locate(href_list["runapp"])
			SetCurrentProg(app)
		else if(href_list["installsoft"])
			var/datum/software/soft = locate(href_list["installsoft"])
			mainframe.harddrive.WriteOn(soft.Copy())
		else if(href_list["removesoft"])
			var/datum/software/soft = locate(href_list["removesoft"])
			mainframe.harddrive.Remove(soft)
		updateUsrDialog()

	proc/Header()
		var/text = "<html><head><style type='text/css'>"
		text += ".prog{width:[mainframe.screen.width]px;heigth:[mainframe.screen.heigth]px;float:left;}"
		text += ".sys{width:200px;height:[mainframe.screen.heigth]px;float:right;background:#ccc;position:absolute;top:0px;left:[mainframe.screen.width]px;}"
		text += "</style></head><body><div class='prog'>"
		return text

	proc/Footer()
		var/text = "</div><div class='sys'>"
		if(mainframe.auth)
			if(mainframe.auth.logged)
				text += "Logged in as [mainframe.auth.username]<BR>"
				text += "[mainframe.auth.assignment]<BR>"
				text += "<A href='?src=\ref[mainframe];logout=1'>Logout</A><BR>"
			else
				text += "Please <A href='?src=\ref[mainframe];login=1'>login</A><BR>"
			if(mainframe.auth.id)
				text += "<A href='?src=\ref[mainframe];ejectid=1'>Eject ID</A><BR>"
		if(mainframe.datadriver)
			if(mainframe.datadriver.disk)
				text += "<A href='?src=\ref[mainframe];ejectdisk=1'>Eject Disk</A><BR>"
		text += "------<BR>"
		for(var/i = 1; i <= 5; i++)
			text += lastlogs[i] + "<BR>"
		text += "</div></body></html>"
		return text

	proc/SetCurrentProg(var/datum/software/app/app = null)
		if(app)
			current_prog = app
			app.Load(mainframe)
		else
			current_prog = null


	proc/AddLogs(var/text)
		for(var/i = 5; i >= 2; i--)
			lastlogs[i] = lastlogs[i - 1]
		lastlogs[1] = text
		alllogs += text

	proc/GetIconName()
		if(current_prog)
			return current_prog.display_icon
		return display_icon

/datum/software/app
	var/list/required_access = list() //Not a req_one_access cause we have own auth sys

	Topic(href, href_list)
		. = 0
		if(href_list["exit"])
			mainframe.sys.SetCurrentProg()
			. = 1
		updateUsrDialog()
		return


/datum/software/app/texttyper
	name = "Text Typer"
	size = 5
	display_icon = "comm"

	Display(var/mob/user)
		var/new_text = "Welcome to [name] 501.1217<BR>"
		new_text += "<A href='?src=\ref[src];exit=1'>Exit to [mainframe.sys.name].</A>"
		return new_text

	Topic(href, href_list)
		if(..(href, href_list)) return
		updateUsrDialog()

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////CREW MONITOR////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

/datum/software/app/crew_monitor
	name = "Crew Monitor"
	size = 15
	display_icon = "crew"
	var/list/tracked = list()

	Display(var/mob/user)
	//	if(!istype(user, /mob/living/silicon) && get_dist(src, user) > 1)
	//		user.unset_machine()
	//		user << browse(null, "window=powcomp")
	//		return
	//	user.set_machine(src)
		src.scan()
		var/t = "<TT><B>Crew Monitoring</B><HR>"
		t += "<BR><A href='?src=\ref[src];exit=1'>Exit to [mainframe.sys.name]</A>"
		t += "<BR><A href='?src=\ref[src];update=1'>Refresh</A> "
		t += "<table><tr><td width='40%'>Name</td><td width='20%'>Vitals</td><td width='40%'>Position</td></tr>"
		var/list/logs = list()
		for(var/obj/item/clothing/under/C in src.tracked)
			var/log = ""
			var/turf/pos = get_turf(C)
			if((C) && (C.has_sensor) && (pos) && (pos.z == mainframe.z) && C.sensor_mode)
				if(istype(C.loc, /mob/living/carbon/human))

					var/mob/living/carbon/human/H = C.loc

					var/dam1 = round(H.getOxyLoss(),1)
					var/dam2 = round(H.getToxLoss(),1)
					var/dam3 = round(H.getFireLoss(),1)
					var/dam4 = round(H.getBruteLoss(),1)

					var/life_status = "[H.stat > 1 ? "<font color=red>Deceased</font>" : "Living"]"
					var/damage_report = "(<font color='blue'>[dam1]</font>/<font color='green'>[dam2]</font>/<font color='orange'>[dam3]</font>/<font color='red'>[dam4]</font>)"

					if(H.wear_id)
						log += "<tr><td width='40%'>[H.wear_id.name]</td>"
					else
						log += "<tr><td width='40%'>Unknown</td>"

					switch(C.sensor_mode)
						if(1)
							log += "<td width='15%'>[life_status]</td><td width='40%'>Not Available</td></tr>"
						if(2)
							log += "<td width='20%'>[life_status] [damage_report]</td><td width='40%'>Not Available</td></tr>"
						if(3)
							var/area/player_area = get_area(H)
							log += "<td width='20%'>[life_status] [damage_report]</td><td width='40%'>[player_area.name] ([pos.x], [pos.y])</td></tr>"
			logs += log
		logs = sortList(logs)
		for(var/log in logs)
			t += log
		t += "</table>"
		t += "</FONT></PRE></TT>"
		return t


	proc/scan()
		for(var/obj/item/clothing/under/C in world)
			if((C.has_sensor) && (istype(C.loc, /mob/living/carbon/human)))
				var/check = 0
				for(var/O in src.tracked)
					if(O == C)
						check = 1
						break
				if(!check)
					src.tracked.Add(C)
		return 1

	Topic(href, href_list)
		if(..(href, href_list)) return
		if (mainframe.z > 6)
			usr << "\red <b>Unable to establish a connection</b>: \black You're too far away from the station!"
		updateUsrDialog()

/////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////Medical Records////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*datum/software/app/medical_records
	name = "Medical records"
	size = 10
	display_icon_state = "medcomp"
	var/temp

	Display()

		if (src.temp)
			return text("<TT>[src.temp]</TT><BR><BR><A href='?src=\ref[src];temp=1'>Clear Screen</A>")
		dat = text("Confirm Identity: <A href='?src=\ref[];scan=1'>[]</A><HR>", src, (src.scan ? text("[]", src.scan.name) : "----------"))
		if (mainframe.auth.logged)
			switch(src.screen)
				if(1.0)
					dat += "<A href='?src=\ref[src];search=1'>Search Records</A>"
					dat += "<BR><A href='?src=\ref[src];screen=2'>List Records</A>"
					dat += "<BR>"
					dat += "<BR><A href='?src=\ref[src];screen=5'>Virus Database</A>"
					dat += "<BR><A href='?src=\ref[src];screen=6'>Medbot Tracking</A>"
					dat += "<BR>"
					dat += "<BR><A href='?src=\ref[src];screen=3'>Record Maintenance</A>"
					dat += "<BR><A href='?src=\ref[src];logout=1'>{Log Out}</A><BR>"
				if(2.0)
					dat += "<B>Record List</B>:<HR>"
					if(!isnull(data_core.general))
						for(var/datum/data/record/R in sortRecord(data_core.general))
							dat += text("<A href='?src=\ref[];d_rec=\ref[]'>[]: []<BR>", src, R, R.fields["id"], R.fields["name"])
					dat += text("<HR><A href='?src=\ref[];screen=1'>Back</A>", src)
				if(3.0)
					dat += text("<B>Records Maintenance</B><HR>\n<A href='?src=\ref[];back=1'>Backup To Disk</A><BR>\n<A href='?src=\ref[];u_load=1'>Upload From disk</A><BR>\n<A href='?src=\ref[];del_all=1'>Delete All Records</A><BR>\n<BR>\n<A href='?src=\ref[];screen=1'>Back</A>", src, src, src, src)
				if(4.0)
					var/icon/front = new(active1.fields["photo"], dir = SOUTH)
					var/icon/side = new(active1.fields["photo"], dir = WEST)
					user << browse_rsc(front, "front.png")
					user << browse_rsc(side, "side.png")
					dat += "<CENTER><B>Medical Record</B></CENTER><BR>"
					if ((istype(src.active1, /datum/data/record) && data_core.general.Find(src.active1)))
						dat += "<table><tr><td>Name: [active1.fields["name"]] \
								ID: [active1.fields["id"]]<BR>\n	\
								Sex: <A href='?src=\ref[src];field=sex'>[active1.fields["sex"]]</A><BR>\n	\
								Age: <A href='?src=\ref[src];field=age'>[active1.fields["age"]]</A><BR>\n	\
								Fingerprint: <A href='?src=\ref[src];field=fingerprint'>[active1.fields["fingerprint"]]</A><BR>\n	\
								Physical Status: <A href='?src=\ref[src];field=p_stat'>[active1.fields["p_stat"]]</A><BR>\n	\
								Mental Status: <A href='?src=\ref[src];field=m_stat'>[active1.fields["m_stat"]]</A><BR></td><td align = center valign = top> \
								Photo:<br><img src=front.png height=64 width=64 border=5><img src=side.png height=64 width=64 border=5></td></tr></table>"
					else
						dat += "<B>General Record Lost!</B><BR>"
					if ((istype(src.active2, /datum/data/record) && data_core.medical.Find(src.active2)))
						dat += text("<BR>\n<CENTER><B>Medical Data</B></CENTER><BR>\nBlood Type: <A href='?src=\ref[];field=b_type'>[]</A><BR>\nDNA: <A href='?src=\ref[];field=b_dna'>[]</A><BR>\n<BR>\nMinor Disabilities: <A href='?src=\ref[];field=mi_dis'>[]</A><BR>\nDetails: <A href='?src=\ref[];field=mi_dis_d'>[]</A><BR>\n<BR>\nMajor Disabilities: <A href='?src=\ref[];field=ma_dis'>[]</A><BR>\nDetails: <A href='?src=\ref[];field=ma_dis_d'>[]</A><BR>\n<BR>\nAllergies: <A href='?src=\ref[];field=alg'>[]</A><BR>\nDetails: <A href='?src=\ref[];field=alg_d'>[]</A><BR>\n<BR>\nCurrent Diseases: <A href='?src=\ref[];field=cdi'>[]</A> (per disease info placed in log/comment section)<BR>\nDetails: <A href='?src=\ref[];field=cdi_d'>[]</A><BR>\n<BR>\nImportant Notes:<BR>\n\t<A href='?src=\ref[];field=notes'>[]</A><BR>\n<BR>\n<CENTER><B>Comments/Log</B></CENTER><BR>", src, src.active2.fields["b_type"], src, src.active2.fields["b_dna"], src, src.active2.fields["mi_dis"], src, src.active2.fields["mi_dis_d"], src, src.active2.fields["ma_dis"], src, src.active2.fields["ma_dis_d"], src, src.active2.fields["alg"], src, src.active2.fields["alg_d"], src, src.active2.fields["cdi"], src, src.active2.fields["cdi_d"], src, src.active2.fields["notes"])
						var/counter = 1
						while(src.active2.fields[text("com_[]", counter)])
							dat += text("[]<BR><A href='?src=\ref[];del_c=[]'>Delete Entry</A><BR><BR>", src.active2.fields[text("com_[]", counter)], src, counter)
							counter++
						dat += text("<A href='?src=\ref[];add_c=1'>Add Entry</A><BR><BR>", src)
						dat += text("<A href='?src=\ref[];del_r=1'>Delete Record (Medical Only)</A><BR><BR>", src)
					else
						dat += "<B>Medical Record Lost!</B><BR>"
						dat += text("<A href='?src=\ref[src];new=1'>New Record</A><BR><BR>")
					dat += text("\n<A href='?src=\ref[];print_p=1'>Print Record</A><BR>\n<A href='?src=\ref[];screen=2'>Back</A><BR>", src, src)
				if(5.0)
					dat += "<CENTER><B>Virus Database</B></CENTER>"
					for (var/ID in virusDB)
						var/datum/data/record/v = virusDB[ID]
						dat += "<br><a href='?src=\ref[src];vir=\ref[v]'>[v.fields["name"]]</a>"
						dat += "<br><a href='?src=\ref[src];screen=1'>Back</a>"
				if(6.0)
					dat += "<center><b>Medical Robot Monitor</b></center>"
					dat += "<a href='?src=\ref[src];screen=1'>Back</a>"
					dat += "<br><b>Medical Robots:</b>"
					var/bdat = null
					for(var/obj/machinery/bot/medbot/M in world)
							if(M.z != src.z)	continue	//only find medibots on the same z-level as the computer
						var/turf/bl = get_turf(M)
						if(bl)	//if it can't find a turf for the medibot, then it probably shouldn't be showing up
							bdat += "[M.name] - <b>\[[bl.x],[bl.y]\]</b> - [M.on ? "Online" : "Offline"]<br>"
							if((!isnull(M.reagent_glass)) && M.use_beaker)
								bdat += "Reservoir: \[[M.reagent_glass.reagents.total_volume]/[M.reagent_glass.reagents.maximum_volume]\]<br>"
							else
								bdat += "Using Internal Synthesizer.<br>"
					if(!bdat)
						dat += "<br><center>None detected</center>"
					else
						dat += "<br>[bdat]"
					else
		else
			dat += text("<A href='?src=\ref[];login=1'>{Log In}</A>", src)
	return text

	Topic(href, href_list)
		if(..())
			return

		if (!( data_core.general.Find(src.active1) ))
			src.active1 = null

		if (!( data_core.medical.Find(src.active2) ))
			src.active2 = null

		if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
			usr.set_machine(src)

			if (href_list["temp"])
				src.temp = null

			if (href_list["scan"])
				if (src.scan)

					if(ishuman(usr))
						scan.loc = usr.loc

						if(!usr.get_active_hand())
							usr.put_in_hands(scan)

						scan = null

					else
						src.scan.loc = src.loc
						src.scan = null

				else
					var/obj/item/I = usr.get_active_hand()
					if (istype(I, /obj/item/weapon/card/id))
						usr.drop_item()
						I.loc = src
						src.scan = I

			else if (href_list["logout"])
				src.authenticated = null
				src.screen = null
				src.active1 = null
				src.active2 = null

			else if (href_list["login"])

				if (istype(usr, /mob/living/silicon/ai))
					src.active1 = null
					src.active2 = null
					src.authenticated = usr.name
					src.rank = "AI"
					src.screen = 1

				else if (istype(usr, /mob/living/silicon/robot))
					src.active1 = null
					src.active2 = null
					src.authenticated = usr.name
					var/mob/living/silicon/robot/R = usr
					src.rank = "[R.modtype] [R.braintype]"
					src.screen = 1

				else if (istype(src.scan, /obj/item/weapon/card/id))
					src.active1 = null
					src.active2 = null

					if (src.check_access(src.scan))
						src.authenticated = src.scan.registered_name
						src.rank = src.scan.assignment
						src.screen = 1

			if (src.authenticated)

				if(href_list["screen"])
					src.screen = text2num(href_list["screen"])
					if(src.screen < 1)
						src.screen = 1

					src.active1 = null
					src.active2 = null

				if(href_list["vir"])
					var/datum/data/record/v = locate(href_list["vir"])
					src.temp = "<center>GNAv2 based virus lifeform V-[v.fields["id"]]</center>"
					src.temp += "<br><b>Name:</b> <A href='?src=\ref[src];field=vir_name;edit_vir=\ref[v]'>[v.fields["name"]]</A>"
					src.temp += "<br><b>Antigen:</b> [v.fields["antigen"]]"
					src.temp += "<br><b>Spread:</b> [v.fields["spread type"]] "
					src.temp += "<br><b>Details:</b><br> <A href='?src=\ref[src];field=vir_desc;edit_vir=\ref[v]'>[v.fields["description"]]</A>"

				if (href_list["del_all"])
					src.temp = text("Are you sure you wish to delete all records?<br>\n\t<A href='?src=\ref[];temp=1;del_all2=1'>Yes</A><br>\n\t<A href='?src=\ref[];temp=1'>No</A><br>", src, src)

				if (href_list["del_all2"])
					for(var/datum/data/record/R in data_core.medical)
						//R = null
						del(R)
						//Foreach goto(494)
					src.temp = "All records deleted."

				if (href_list["field"])
					var/a1 = src.active1
					var/a2 = src.active2
					switch(href_list["field"])
						if("fingerprint")
							if (istype(src.active1, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please input fingerprint hash:", "Med. records", src.active1.fields["fingerprint"], null)  as text),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active1 != a1))
									return
								src.active1.fields["fingerprint"] = t1
						if("sex")
							if (istype(src.active1, /datum/data/record))
								if (src.active1.fields["sex"] == "Male")
									src.active1.fields["sex"] = "Female"
								else
									src.active1.fields["sex"] = "Male"
						if("age")
							if (istype(src.active1, /datum/data/record))
								var/t1 = input("Please input age:", "Med. records", src.active1.fields["age"], null)  as num
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active1 != a1))
									return
								src.active1.fields["age"] = t1
						if("mi_dis")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please input minor disabilities list:", "Med. records", src.active2.fields["mi_dis"], null)  as text),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["mi_dis"] = t1
						if("mi_dis_d")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please summarize minor dis.:", "Med. records", src.active2.fields["mi_dis_d"], null)  as message),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["mi_dis_d"] = t1
						if("ma_dis")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please input major diabilities list:", "Med. records", src.active2.fields["ma_dis"], null)  as text),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["ma_dis"] = t1
						if("ma_dis_d")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please summarize major dis.:", "Med. records", src.active2.fields["ma_dis_d"], null)  as message),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["ma_dis_d"] = t1
						if("alg")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please state allergies:", "Med. records", src.active2.fields["alg"], null)  as text),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["alg"] = t1
						if("alg_d")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please summarize allergies:", "Med. records", src.active2.fields["alg_d"], null)  as message),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["alg_d"] = t1
						if("cdi")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please state diseases:", "Med. records", src.active2.fields["cdi"], null)  as text),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["cdi"] = t1
						if("cdi_d")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please summarize diseases:", "Med. records", src.active2.fields["cdi_d"], null)  as message),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["cdi_d"] = t1
						if("notes")
							if (istype(src.active2, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please summarize notes:", "Med. records", src.active2.fields["notes"], null)  as message),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
									return
								src.active2.fields["notes"] = t1
						if("p_stat")
							if (istype(src.active1, /datum/data/record))
								src.temp = text("<B>Physical Condition:</B><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=deceased'>*Deceased*</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=ssd'>*SSD*</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=active'>Active</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=unfit'>Physically Unfit</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=disabled'>Disabled</A><BR>", src, src, src, src, src)
						if("m_stat")
							if (istype(src.active1, /datum/data/record))
								src.temp = text("<B>Mental Condition:</B><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=insane'>*Insane*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=unstable'>*Unstable*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=watch'>*Watch*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=stable'>Stable</A><BR>", src, src, src, src)
						if("b_type")
							if (istype(src.active2, /datum/data/record))
								src.temp = text("<B>Blood Type:</B><BR>\n\t<A href='?src=\ref[];temp=1;b_type=an'>A-</A> <A href='?src=\ref[];temp=1;b_type=ap'>A+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=bn'>B-</A> <A href='?src=\ref[];temp=1;b_type=bp'>B+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=abn'>AB-</A> <A href='?src=\ref[];temp=1;b_type=abp'>AB+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=on'>O-</A> <A href='?src=\ref[];temp=1;b_type=op'>O+</A><BR>", src, src, src, src, src, src, src, src)
						if("b_dna")
							if (istype(src.active1, /datum/data/record))
								var/t1 = copytext(sanitize_uni(input("Please input DNA hash:", "Med. records", src.active1.fields["dna"], null)  as text),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active1 != a1))
									return
								src.active1.fields["dna"] = t1
						if("vir_name")
							var/datum/data/record/v = locate(href_list["edit_vir"])
							if (v)
								var/t1 = copytext(sanitize(input("Please input pathogen name:", "VirusDB", v.fields["name"], null)  as text),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active1 != a1))
									return
								v.fields["name"] = t1
						if("vir_desc")
							var/datum/data/record/v = locate(href_list["edit_vir"])
							if (v)
								var/t1 = copytext(sanitize(input("Please input information about pathogen:", "VirusDB", v.fields["description"], null)  as message),1,MAX_MESSAGE_LEN)
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active1 != a1))
									return
								v.fields["description"] = t1
						else

				if (href_list["p_stat"])
					if (src.active1)
						switch(href_list["p_stat"])
							if("deceased")
								src.active1.fields["p_stat"] = "*Deceased*"
							if("ssd")
								src.active1.fields["p_stat"] = "*SSD*"
							if("active")
								src.active1.fields["p_stat"] = "Active"
							if("unfit")
								src.active1.fields["p_stat"] = "Physically Unfit"
							if("disabled")
								src.active1.fields["p_stat"] = "Disabled"

				if (href_list["m_stat"])
					if (src.active1)
						switch(href_list["m_stat"])
							if("insane")
								src.active1.fields["m_stat"] = "*Insane*"
							if("unstable")
								src.active1.fields["m_stat"] = "*Unstable*"
							if("watch")
								src.active1.fields["m_stat"] = "*Watch*"
							if("stable")
								src.active1.fields["m_stat"] = "Stable"


				if (href_list["b_type"])
					if (src.active2)
						switch(href_list["b_type"])
							if("an")
								src.active2.fields["b_type"] = "A-"
							if("bn")
								src.active2.fields["b_type"] = "B-"
							if("abn")
								src.active2.fields["b_type"] = "AB-"
							if("on")
								src.active2.fields["b_type"] = "O-"
							if("ap")
								src.active2.fields["b_type"] = "A+"
							if("bp")
								src.active2.fields["b_type"] = "B+"
							if("abp")
								src.active2.fields["b_type"] = "AB+"
							if("op")
								src.active2.fields["b_type"] = "O+"


				if (href_list["del_r"])
					if (src.active2)
						src.temp = text("Are you sure you wish to delete the record (Medical Portion Only)?<br>\n\t<A href='?src=\ref[];temp=1;del_r2=1'>Yes</A><br>\n\t<A href='?src=\ref[];temp=1'>No</A><br>", src, src)

				if (href_list["del_r2"])
					if (src.active2)
						//src.active2 = null
						del(src.active2)

				if (href_list["d_rec"])
					var/datum/data/record/R = locate(href_list["d_rec"])
					var/datum/data/record/M = locate(href_list["d_rec"])
					if (!( data_core.general.Find(R) ))
						src.temp = "Record Not Found!"
						return
					for(var/datum/data/record/E in data_core.medical)
						if ((E.fields["name"] == R.fields["name"] || E.fields["id"] == R.fields["id"]))
							M = E
						else
							//Foreach continue //goto(2540)
					src.active1 = R
					src.active2 = M
					src.screen = 4

				if (href_list["new"])
					if ((istype(src.active1, /datum/data/record) && !( istype(src.active2, /datum/data/record) )))
						var/datum/data/record/R = new /datum/data/record(  )
						R.fields["name"] = src.active1.fields["name"]
						R.fields["id"] = src.active1.fields["id"]
						R.name = text("Medical Record #[]", R.fields["id"])
						R.fields["b_type"] = "Unknown"
						R.fields["b_dna"] = "Unknown"
						R.fields["mi_dis"] = "None"
						R.fields["mi_dis_d"] = "No minor disabilities have been declared."
						R.fields["ma_dis"] = "None"
						R.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
						R.fields["alg"] = "None"
						R.fields["alg_d"] = "No allergies have been detected in this patient."
						R.fields["cdi"] = "None"
						R.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
						R.fields["notes"] = "No notes."
						data_core.medical += R
						src.active2 = R
						src.screen = 4

				if (href_list["add_c"])
					if (!( istype(src.active2, /datum/data/record) ))
						return
					var/a2 = src.active2
					var/t1 = copytext(sanitize_uni(input("Add Comment:", "Med. records", null, null)  as message),1,MAX_MESSAGE_LEN)
					if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))) || src.active2 != a2))
						return
					var/counter = 1
					while(src.active2.fields[text("com_[]", counter)])
						counter++
					src.active2.fields[text("com_[counter]")] = text("Made by [authenticated] ([rank]) on [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], [game_year]<BR>[t1]")

				if (href_list["del_c"])
					if ((istype(src.active2, /datum/data/record) && src.active2.fields[text("com_[]", href_list["del_c"])]))
						src.active2.fields[text("com_[]", href_list["del_c"])] = "<B>Deleted</B>"

				if (href_list["search"])
					var/t1 = input("Search String: (Name, DNA, or ID)", "Med. records", null, null)  as text
					if ((!( t1 ) || usr.stat || !( src.authenticated ) || usr.restrained() || ((!in_range(src, usr)) && (!istype(usr, /mob/living/silicon)))))
						return
					src.active1 = null
					src.active2 = null
					t1 = lowertext(t1)
					for(var/datum/data/record/R in data_core.medical)
						if ((lowertext(R.fields["name"]) == t1 || t1 == lowertext(R.fields["id"]) || t1 == lowertext(R.fields["b_dna"])))
							src.active2 = R
						else
							//Foreach continue //goto(3229)
					if (!( src.active2 ))
						src.temp = text("Could not locate record [].", t1)
					else
						for(var/datum/data/record/E in data_core.general)
							if ((E.fields["name"] == src.active2.fields["name"] || E.fields["id"] == src.active2.fields["id"]))
								src.active1 = E
							else
								//Foreach continue //goto(3334)
						src.screen = 4

				if (href_list["print_p"])
					if (!( src.printing ))
						src.printing = 1
						sleep(50)
						var/obj/item/weapon/paper/P = new /obj/item/weapon/paper( src.loc )
						P.info = "<CENTER><B>Medical Record</B></CENTER><BR>"
						if ((istype(src.active1, /datum/data/record) && data_core.general.Find(src.active1)))
							P.info += text("Name: [] ID: []<BR>\nSex: []<BR>\nAge: []<BR>\nFingerprint: []<BR>\nPhysical Status: []<BR>\nMental Status: []<BR>", src.active1.fields["name"], src.active1.fields["id"], src.active1.fields["sex"], src.active1.fields["age"], src.active1.fields["fingerprint"], src.active1.fields["p_stat"], src.active1.fields["m_stat"])
						else
							P.info += "<B>General Record Lost!</B><BR>"
						if ((istype(src.active2, /datum/data/record) && data_core.medical.Find(src.active2)))
							P.info += text("<BR>\n<CENTER><B>Medical Data</B></CENTER><BR>\nBlood Type: []<BR>\nDNA: []<BR>\n<BR>\nMinor Disabilities: []<BR>\nDetails: []<BR>\n<BR>\nMajor Disabilities: []<BR>\nDetails: []<BR>\n<BR>\nAllergies: []<BR>\nDetails: []<BR>\n<BR>\nCurrent Diseases: [] (per disease info placed in log/comment section)<BR>\nDetails: []<BR>\n<BR>\nImportant Notes:<BR>\n\t[]<BR>\n<BR>\n<CENTER><B>Comments/Log</B></CENTER><BR>", src.active2.fields["b_type"], src.active2.fields["b_dna"], src.active2.fields["mi_dis"], src.active2.fields["mi_dis_d"], src.active2.fields["ma_dis"], src.active2.fields["ma_dis_d"], src.active2.fields["alg"], src.active2.fields["alg_d"], src.active2.fields["cdi"], src.active2.fields["cdi_d"], src.active2.fields["notes"])
							var/counter = 1
							while(src.active2.fields[text("com_[]", counter)])
								P.info += text("[]<BR>", src.active2.fields[text("com_[]", counter)])
								counter++
						else
							P.info += "<B>Medical Record Lost!</B><BR>"
						P.info += "</TT>"
						P.name = "paper- 'Medical Record'"
						src.printing = null

		updateUsrDialog()
		return
		*/