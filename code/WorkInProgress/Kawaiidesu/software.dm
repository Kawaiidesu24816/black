//This soft was created when computer not have some functionality so it not have important hardware checks

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////Crew Monitor////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

/datum/software/app/crew_monitor
	name = "Crew Monitor"
	size = 15
	display_icon = "crew"

	Display(var/mob/user)
		var/list/tracked = scan()
		var/t = "<TT><B>Crew Monitoring</B><HR>"
		t += "<BR><A href='?src=\ref[src];exit=1'>Exit to [mainframe.sys.name]</A>"
		t += "<BR><A href='?src=\ref[src];update=1'>Refresh</A> "
		t += "<table><tr><td width='40%'>Name</td><td width='20%'>Vitals</td><td width='40%'>Position</td></tr>"
		var/list/logs = list()
		for(var/obj/item/clothing/under/C in tracked)
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
		var/list/tracked = list()
		for(var/obj/item/clothing/under/C in world)
			if((C.has_sensor) && (istype(C.loc, /mob/living/carbon/human)))
				var/check = 0
				for(var/O in tracked)
					if(O == C)
						check = 1
						break
				if(!check)
					tracked.Add(C)
		return tracked

	Topic(href, href_list)
		if (mainframe.z > 6)
			usr << "\red <b>Unable to establish a connection</b>: \black You're too far away from the station!"
		updateUsrDialog()

/////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////Chat//////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/datum/software/app/chat
	name = "Station Chat"
	size = 5
	display_icon = "solar"
	var/saved_text = ""
	var/datum/address/host = null


	OnStart()
		var/list/req = list()
		var/datum/connectdata/self = GlobalAddress()
		req["message"] = self.ToString() + " connected"
		req["user"] = "System"
		req["soft_type"] = type
		mainframe.connector.SendSignal(null, self, req)

	Display()
		var/t = "<textarea rows='10' cols='[round((mainframe.screen.width - 200) / 9)]' readonly>" + saved_text + "</textarea>"
		t += {"
		<form name="ChatInput" action="byond://" method="get">
			<input type="hidden" name="src" value="\ref[src]" />
			<input type="text" name="new_message" size="15" />
			<input type="submit" value="Send" style="align:bottom;width=[mainframe.screen.x - 200]px;"/>
		</form>
		"}
		return t

	Request(var/datum/connectdata/sender, var/list/data)
		if(data["message"] && data["user"])
			if(data["soft_type"] != src.type) return
			if(data["user"] == "unknown") return
			NewMessage(data["message"], data["user"])

	Topic(href, href_list)
		if(href_list["new_message"])
			if(mainframe.auth.username == "unknown")
				NewMessage("Access denied. Please login", "System")
			else
				NewMessage(href_list["new_message"], mainframe.auth.username)
				var/list/req = list()
				req["message"] = href_list["new_message"]
				req["soft_type"] = type
				req["user"] = mainframe.auth.username
				mainframe.connector.SendSignal(null, GlobalAddress(), req)
		updateUsrDialog()

	Requirements()
		var/t = ""
		if(!mainframe.auth)
			t += "Need auth module\n"
		else if(!mainframe.auth.logged)
			t += "Try to login\n"
		if(!mainframe.connector)
			t += "Need net module\n"
		return t

	proc/NewMessage(var/text, var/user)
		saved_text += "\n<" + user + "> " + text

/////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////Medical Records////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

/datum/software/app/medical_records
	name = "Medical records"
	size = 10
	display_icon = "medcomp"
	required_access = list(access_medical, access_forensics_lockers)
	var/temp
	var/current_state = "mainscreen"
	var/datum/data/record/medical_record
	var/datum/data/record/medical_data

	Display(var/mob/user)


		var/access = mainframe.AccessProblem(required_access)
		if (access == 1)
			return "Auth module is not found"
		if (access == 2)
			return "Please login"
		if (access == 3)
			return "Not enough access"
		if (src.temp)
			return "<TT>[src.temp]</TT><BR><BR><A href='?src=\ref[src];temp=1'>Clear Screen</A>"
		var/t = ""
		switch(current_state)
			if("mainscreen")
				t += "<A href='?src=\ref[src];search=1'>Search Records</A><BR>"
				t += "<A href='?src=\ref[src];setstate=recordslist'>List Records</A><BR><BR>"
				t += "<A href='?src=\ref[src];setstate=viruses'>Virus Database</A><BR>"
				t += "<A href='?src=\ref[src];setstate=medbots'>Medbot Tracking</A><BR><BR>"
				t += "<A href='?src=\ref[src];setstate=maintance'>Record Maintenance</A><BR>"
			if("recordslist")
				t += "<B>Record List</B>:<HR>"
				if(!isnull(data_core.general))
					for(var/datum/data/record/R in sortRecord(data_core.general))
						t += "<A href='?src=\ref[src];d_rec=\ref[R]'>[R.fields["id"]]: [R.fields["name"]]<BR>"
				t += "<HR><A href='?src=\ref[src];screen=mainscreen'>Back</A>"
			if("maintance")
				t += "<B>Records Maintenance</B><HR>"
				t += "<A href='?src=\ref[src];back=1'>Backup To Disk</A><BR>"
				t += "<A href='?src=\ref[src];u_load=1'>Upload From disk</A><BR>"
				t += "<A href='?src=\ref[src];del_all=1'>Delete All Records</A><BR>"
				t += "<BR>\n<A href='?src=\ref[src];setstate=mainscreen'>Back</A>"
			if("record")
				var/icon/front = new(medical_record.fields["photo"], dir = SOUTH)
				var/icon/side = new(medical_record.fields["photo"], dir = WEST)
				user << browse_rsc(front, "front.png")
				user << browse_rsc(side, "side.png")
				t += "<CENTER><B>Medical Record</B></CENTER><BR>"
				if ((istype(medical_record, /datum/data/record) && data_core.general.Find(medical_record)))
					t += "<table><tr><td>Name: [medical_record.fields["name"]] \
							ID: [medical_record.fields["id"]]<BR>\n	\
							Sex: <A href='?src=\ref[src];field=sex'>[medical_record.fields["sex"]]</A><BR>\n	\
							Age: <A href='?src=\ref[src];field=age'>[medical_record.fields["age"]]</A><BR>\n	\
							Fingerprint: <A href='?src=\ref[src];field=fingerprint'>[medical_record.fields["fingerprint"]]</A><BR>\n	\
							Physical Status: <A href='?src=\ref[src];field=p_stat'>[medical_record.fields["p_stat"]]</A><BR>\n	\
							Mental Status: <A href='?src=\ref[src];field=m_stat'>[medical_record.fields["m_stat"]]</A><BR></td><td align = center valign = top> \
							Photo:<br><img src=front.png height=64 width=64 border=5><img src=side.png height=64 width=64 border=5></td></tr></table>"
				else
					t += "<B>General Record Lost!</B><BR>"
				if ((istype(src.medical_data, /datum/data/record) && data_core.medical.Find(src.medical_data)))
					t += "<BR><CENTER><B>Medical Data</B></CENTER><BR>"
					t += "Blood Type: <A href='?src=\ref[src];field=b_type'>[src.medical_data.fields["b_type"]]</A><BR>"
					t += "DNA: <A href='?src=\ref[src];field=b_dna'>[src.medical_data.fields["b_dna"]]</A><BR><BR>"
					t += "Minor Disabilities: <A href='?src=\ref[src];field=mi_dis'>[src.medical_data.fields["mi_dis"]]</A><BR>"
					t += "Details: <A href='?src=\ref[src];field=mi_dis_d'>[src.medical_data.fields["mi_dis_d"]]</A><BR>"
					t += "<BR>\nMajor Disabilities: <A href='?src=\ref[src];field=ma_dis'>[src.medical_data.fields["ma_dis"]]</A><BR>"
					t += "Details: <A href='?src=\ref[src];field=ma_dis_d'>[src.medical_data.fields["ma_dis_d"]]</A><BR>\n<BR>"
					t += "Allergies: <A href='?src=\ref[src];field=alg'>[src.medical_data.fields["alg"]]</A><BR>"
					t += "Details: <A href='?src=\ref[src];field=alg_d'>[src.medical_data.fields["alg_d"]]</A><BR>"
					t += "<BR>\nCurrent Diseases: <A href='?src=\ref[src];field=cdi'>[src.medical_data.fields["cdi"]]</A> (per disease info placed in log/comment section)<BR>"
					t += "Details: <A href='?src=\ref[src];field=cdi_d'>[src.medical_data.fields["cdi_d"]]</A><BR><BR>"
					t += "Important Notes:<BR>\n\t<A href='?src=\ref[src];field=notes'>[src.medical_data.fields["notes"]]</A><BR><BR>"
					t += "<CENTER><B>Comments/Log</B></CENTER><BR>"
					var/counter = 1
					while(src.medical_data.fields["com_[counter]"])
						t += "[src.medical_data.fields["com_[counter]"]]<BR><A href='?src=\ref[src];del_c=[counter]'>Delete Entry</A><BR><BR>"
						counter++
					t += "<A href='?src=\ref[src];add_c=1'>Add Entry</A><BR><BR>"
					t += "<A href='?src=\ref[src];del_r=1'>Delete Record (Medical Only)</A><BR><BR>"
				else
					t += "<B>Medical Record Lost!</B><BR>"
					t += "<A href='?src=\ref[src];new=1'>New Record</A><BR><BR>"
				t += "<A href='?src=\ref[src];print_p=1'>Print Record</A><BR>"
				t += "<A href='?src=\ref[src];setstate=mainscreen'>Back</A><BR>"
			if("viruses")
				t += "<CENTER><B>Virus Database</B></CENTER>"
				for (var/ID in virusDB)
					var/datum/data/record/v = virusDB[ID]
					t += "<br><a href='?src=\ref[src];vir=\ref[v]'>[v.fields["name"]]</a>"
					t += "<br><a href='?src=\ref[src];setstate=mainscreen'>Back</a>"
			if("medbots")
				t += "<center><b>Medical Robot Monitor</b></center>"
				t += "<a href='?src=\ref[src];setstate=mainscreen'>Back</a>"
				t += "<br><b>Medical Robots:</b>"
				var/bdat = null
				for(var/obj/machinery/bot/medbot/M in world)
					if(M.z != mainframe.z)	continue	//only find medibots on the same z-level as the computer
					var/turf/bl = get_turf(M)
					if(bl)	//if it can't find a turf for the medibot, then it probably shouldn't be showing up
						bdat += "[M.name] - <B>\[[bl.x],[bl.y]\]</B> - [M.on ? "Online" : "Offline"]<BR>"
						if((!isnull(M.reagent_glass)) && M.use_beaker)
							bdat += "Reservoir: \[[M.reagent_glass.reagents.total_volume]/[M.reagent_glass.reagents.maximum_volume]\]<br>"
						else
							bdat += "Using Internal Synthesizer.<br>"
				if(!bdat)
					t += "<BR><CENTER>None detected</CENTER>"
				else
					t += "<BR>[bdat]"
		return t

	Topic(href, href_list)
		if(..())
			return

		if (!( data_core.general.Find(src.medical_record) ))
			src.medical_record = null

		if (!( data_core.medical.Find(src.medical_data) ))
			src.medical_data = null

		if (href_list["temp"])
			src.temp = null

		if (!mainframe.AccessProblem(required_access))
			if(href_list["setstate"])
				current_state = href_list["setstate"]

				medical_record = null
				medical_data = null

			else if(href_list["vir"])
				var/datum/data/record/v = locate(href_list["vir"])
				temp = "<center>GNAv2 based virus lifeform V-[v.fields["id"]]</center>"
				temp += "<br><b>Name:</b> <A href='?src=\ref[src];field=vir_name;edit_vir=\ref[v]'>[v.fields["name"]]</A>"
				temp += "<br><b>Antigen:</b> [v.fields["antigen"]]"
				temp += "<br><b>Spread:</b> [v.fields["spread type"]] "
				temp += "<br><b>Details:</b><br> <A href='?src=\ref[src];field=vir_desc;edit_vir=\ref[v]'>[v.fields["description"]]</A>"

			if (href_list["del_all"])
				temp = "Are you sure you wish to delete all records?<br>\n\t<A href='?src=\ref[src];temp=1;del_all2=1'>Yes</A><br>\n\t<A href='?src=\ref[src];temp=1'>No</A><br>"

			if (href_list["del_all2"])
				for(var/datum/data/record/R in data_core.medical)
					//R = null
					del(R)
					//Foreach goto(494)
				temp = "All records deleted."

			if (href_list["field"])
				switch(href_list["field"])
					if("fingerprint")
						if (istype(src.medical_record, /datum/data/record))
							var/t1 = copytext(sanitize_uni(input("Please input fingerprint hash:", "Med. records", src.medical_record.fields["fingerprint"], null)  as text),1,MAX_MESSAGE_LEN)
							if (!t1) return
							src.medical_record.fields["fingerprint"] = t1
					if("sex")
						if (src.medical_record.fields["sex"] == "Male")
							src.medical_record.fields["sex"] = "Female"
						else
							src.medical_record.fields["sex"] = "Male"
					if("age")
						var/t1 = input("Please input age:", "Med. records", src.medical_record.fields["age"], null)  as num
						if (!t1) return
						src.medical_record.fields["age"] = t1
					if("mi_dis")
						var/t1 = copytext(sanitize_uni(input("Please input minor disabilities list:", "Med. records", src.medical_data.fields["mi_dis"], null)  as text),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["mi_dis"] = t1
					if("mi_dis_d")
						var/t1 = copytext(sanitize_uni(input("Please summarize minor dis.:", "Med. records", src.medical_data.fields["mi_dis_d"], null)  as message),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["mi_dis_d"] = t1
					if("ma_dis")
						var/t1 = copytext(sanitize_uni(input("Please input major diabilities list:", "Med. records", src.medical_data.fields["ma_dis"], null)  as text),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["ma_dis"] = t1
					if("ma_dis_d")
						var/t1 = copytext(sanitize_uni(input("Please summarize major dis.:", "Med. records", src.medical_data.fields["ma_dis_d"], null)  as message),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["ma_dis_d"] = t1
					if("alg")
						var/t1 = copytext(sanitize_uni(input("Please state allergies:", "Med. records", src.medical_data.fields["alg"], null)  as text),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["alg"] = t1
					if("alg_d")
						var/t1 = copytext(sanitize_uni(input("Please summarize allergies:", "Med. records", src.medical_data.fields["alg_d"], null)  as message),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["alg_d"] = t1
					if("cdi")
						var/t1 = copytext(sanitize_uni(input("Please state diseases:", "Med. records", src.medical_data.fields["cdi"], null)  as text),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["cdi"] = t1
					if("cdi_d")
						var/t1 = copytext(sanitize_uni(input("Please summarize diseases:", "Med. records", src.medical_data.fields["cdi_d"], null)  as message),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["cdi_d"] = t1
					if("notes")
						var/t1 = copytext(sanitize_uni(input("Please summarize notes:", "Med. records", src.medical_data.fields["notes"], null)  as message),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_data.fields["notes"] = t1
					if("p_stat")
						src.temp = text("<B>Physical Condition:</B><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=deceased'>*Deceased*</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=ssd'>*SSD*</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=active'>Active</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=unfit'>Physically Unfit</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=disabled'>Disabled</A><BR>", src, src, src, src, src)
					if("m_stat")
						src.temp = text("<B>Mental Condition:</B><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=insane'>*Insane*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=unstable'>*Unstable*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=watch'>*Watch*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=stable'>Stable</A><BR>", src, src, src, src)
					if("b_type")
						src.temp = text("<B>Blood Type:</B><BR>\n\t<A href='?src=\ref[];temp=1;b_type=an'>A-</A> <A href='?src=\ref[];temp=1;b_type=ap'>A+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=bn'>B-</A> <A href='?src=\ref[];temp=1;b_type=bp'>B+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=abn'>AB-</A> <A href='?src=\ref[];temp=1;b_type=abp'>AB+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=on'>O-</A> <A href='?src=\ref[];temp=1;b_type=op'>O+</A><BR>", src, src, src, src, src, src, src, src)
					if("b_dna")
						var/t1 = copytext(sanitize_uni(input("Please input DNA hash:", "Med. records", src.medical_record.fields["dna"], null)  as text),1,MAX_MESSAGE_LEN)
						if (!t1) return
						src.medical_record.fields["dna"] = t1
					if("vir_name")
						var/datum/data/record/v = locate(href_list["edit_vir"])
						if (v)
							var/t1 = copytext(sanitize(input("Please input pathogen name:", "VirusDB", v.fields["name"], null)  as text),1,MAX_MESSAGE_LEN)
							if (!t1) return
							v.fields["name"] = t1
					if("vir_desc")
						var/datum/data/record/v = locate(href_list["edit_vir"])
						if (v)
							var/t1 = copytext(sanitize(input("Please input information about pathogen:", "VirusDB", v.fields["description"], null)  as message),1,MAX_MESSAGE_LEN)
							if (!t1) return
							v.fields["description"] = t1

			else if (href_list["p_stat"])
				if (src.medical_record)
					switch(href_list["p_stat"])
						if("deceased")
							src.medical_record.fields["p_stat"] = "*Deceased*"
						if("ssd")
							src.medical_record.fields["p_stat"] = "*SSD*"
						if("active")
							src.medical_record.fields["p_stat"] = "Active"
						if("unfit")
							src.medical_record.fields["p_stat"] = "Physically Unfit"
						if("disabled")
							src.medical_record.fields["p_stat"] = "Disabled"

			else if (href_list["m_stat"])
				if (src.medical_record)
					switch(href_list["m_stat"])
						if("insane")
							src.medical_record.fields["m_stat"] = "*Insane*"
						if("unstable")
							src.medical_record.fields["m_stat"] = "*Unstable*"
						if("watch")
							src.medical_record.fields["m_stat"] = "*Watch*"
						if("stable")
							src.medical_record.fields["m_stat"] = "Stable"

			else if (href_list["b_type"])
				if (src.medical_data)
					switch(href_list["b_type"])
						if("an")
							src.medical_data.fields["b_type"] = "A-"
						if("bn")
							src.medical_data.fields["b_type"] = "B-"
						if("abn")
							src.medical_data.fields["b_type"] = "AB-"
						if("on")
							src.medical_data.fields["b_type"] = "O-"
						if("ap")
							src.medical_data.fields["b_type"] = "A+"
						if("bp")
							src.medical_data.fields["b_type"] = "B+"
						if("abp")
							src.medical_data.fields["b_type"] = "AB+"
						if("op")
							src.medical_data.fields["b_type"] = "O+"

			else if (href_list["del_r"])
				if (src.medical_data)
					src.temp = text("Are you sure you wish to delete the record (Medical Portion Only)?<br>\n\t<A href='?src=\ref[];temp=1;del_r2=1'>Yes</A><br>\n\t<A href='?src=\ref[];temp=1'>No</A><br>", src, src)

			else if (href_list["del_r2"])
				if (src.medical_data)
					//src.medical_data = null
					del(src.medical_data)

			else if (href_list["d_rec"])
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
				medical_record = R
				medical_data = M
				current_state = "record"

			else if (href_list["new"])
				if ((istype(src.medical_record, /datum/data/record) && !( istype(src.medical_data, /datum/data/record) )))
					var/datum/data/record/R = new /datum/data/record(  )
					R.fields["name"] = src.medical_record.fields["name"]
					R.fields["id"] = src.medical_record.fields["id"]
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
					medical_data = R
					current_state = "record"

			else if (href_list["add_c"])
				if (!( istype(src.medical_data, /datum/data/record) )) return
				var/t1 = copytext(sanitize_uni(input("Add Comment:", "Med. records", null, null)  as message),1,MAX_MESSAGE_LEN)
				if (!t1) return
				var/counter = 1
				while(src.medical_data.fields[text("com_[]", counter)])
					counter++
				medical_data.fields[text("com_[counter]")] = text("Made by [mainframe.auth.username] ([mainframe.auth.assignment]) on [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], [game_year]<BR>[t1]")

			else if (href_list["del_c"])
				if ((istype(src.medical_data, /datum/data/record) && src.medical_data.fields[text("com_[]", href_list["del_c"])]))
					medical_data.fields[text("com_[]", href_list["del_c"])] = "<B>Deleted</B>"

			else if (href_list["search"])
				var/t1 = input("Search String: (Name, DNA, or ID)", "Med. records", null, null)  as text
				if (!t1) return
				src.medical_record = null
				src.medical_data = null
				t1 = lowertext(t1)
				for(var/datum/data/record/R in data_core.medical)
					if ((lowertext(R.fields["name"]) == t1 || t1 == lowertext(R.fields["id"]) || t1 == lowertext(R.fields["b_dna"])))
						medical_data = R
					else
						//Foreach continue //goto(3229)
				if (!( src.medical_data ))
					src.temp = text("Could not locate record [].", t1)
				else
					for(var/datum/data/record/E in data_core.general)
						if ((E.fields["name"] == src.medical_data.fields["name"] || E.fields["id"] == src.medical_data.fields["id"]))
							src.medical_record = E
						else
							//Foreach continue //goto(3334)
					current_state = "mainscreen"
		updateUsrDialog()
//			else if (href_list["print_p"])
//				if (!( src.printing ))
//					src.printing = 1
//					sleep(50)
//					var/obj/item/weapon/paper/P = new /obj/item/weapon/paper( src.loc )
//					P.info = "<CENTER><B>Medical Record</B></CENTER><BR>"
//					if ((istype(src.medical_record, /datum/data/record) && data_core.general.Find(src.medical_record)))
//						P.info += text("Name: [] ID: []<BR>\nSex: []<BR>\nAge: []<BR>\nFingerprint: []<BR>\nPhysical Status: []<BR>\nMental Status: []<BR>", src.medical_record.fields["name"], src.medical_record.fields["id"], src.medical_record.fields["sex"], src.medical_record.fields["age"], src.medical_record.fields["fingerprint"], src.medical_record.fields["p_stat"], src.medical_record.fields["m_stat"])
//					else
//						P.info += "<B>General Record Lost!</B><BR>"
//					if ((istype(src.medical_data, /datum/data/record) && data_core.medical.Find(src.medical_data)))
//						P.info += text("<BR>\n<CENTER><B>Medical Data</B></CENTER><BR>\nBlood Type: []<BR>\nDNA: []<BR>\n<BR>\nMinor Disabilities: []<BR>\nDetails: []<BR>\n<BR>\nMajor Disabilities: []<BR>\nDetails: []<BR>\n<BR>\nAllergies: []<BR>\nDetails: []<BR>\n<BR>\nCurrent Diseases: [] (per disease info placed in log/comment section)<BR>\nDetails: []<BR>\n<BR>\nImportant Notes:<BR>\n\t[]<BR>\n<BR>\n<CENTER><B>Comments/Log</B></CENTER><BR>", src.medical_data.fields["b_type"], src.medical_data.fields["b_dna"], src.medical_data.fields["mi_dis"], src.medical_data.fields["mi_dis_d"], src.medical_data.fields["ma_dis"], src.medical_data.fields["ma_dis_d"], src.medical_data.fields["alg"], src.medical_data.fields["alg_d"], src.medical_data.fields["cdi"], src.medical_data.fields["cdi_d"], src.medical_data.fields["notes"])
//						var/counter = 1
//						while(src.medical_data.fields[text("com_[]", counter)])
//							P.info += text("[]<BR>", src.medical_data.fields[text("com_[]", counter)])
//							counter++
//					else
//						P.info += "<B>Medical Record Lost!</B><BR>"
//					P.info += "</TT>"
//					P.name = "paper- 'Medical Record'"
//					src.printing = null