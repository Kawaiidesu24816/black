//This soft was created when computer have all base functionality so it have important hardware checks

///////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////TEXT FILE////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
/datum/software/app/textfile
	name = "Text file"
	size = 5
	display_icon = "solar"
	var/saved_text = ""
	var/file_name = "Text file"

	Display()
		//var/t = html_encode(saved_text)
		var/t = {"
		<form name="textfield" action="byond://" method="get">
			<input type="hidden" name="src" value="\ref[src]" />
			<input type="text" name="set_name" value="[file_name]" />
			<input type="submit" value="Rename" style="align:bottom;width=[M.screen.x - 200]px;"/>
		</form>
		<form name="textfield" action="byond://" method="get">
			<input type="hidden" name="src" value="\ref[src]" />
			<textarea name="set_text" rows="15" cols="30">[saved_text]</textarea><BR>
			<input type="submit" value="Save" style="align:bottom;width=[M.screen.x - 200]px;"/>
		</form>
		"}
		return t

	Topic(href, href_list)
		if(href_list["set_text"])
			saved_text = href_list["set_text"]
		else if(href_list["set_name"])
			file_name = copytext(href_list["set_name"], 1, 30)
		updateUsrDialog()

	Copy()
		//Transfer some data
		var/datum/software/app/textfile/txt = new /datum/software/app/textfile()
		txt.saved_text = saved_text
		return txt

	GetName()
		return file_name + ".text"

	//Stuff for using by apps
	proc/AddText(var/t = "")
		if(!Connected()) return
		saved_text += "<BR>" + t

	proc/Clear()
		if(!Connected()) return
		saved_text = ""

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
		req["message"] = self.ToString() + " connected as [M.User()]([M.Assignment()])"
		req["user"] = "System"
		req["soft_type"] = type
		M.connector.SendSignal(null, self, req)

	Display()
		var/t = "<textarea rows='10' cols='[round((M.screen.width - 200) / 9)]' readonly>" + saved_text + "</textarea>"
		t += {"
		<form name="ChatInput" action="byond://" method="get">
			<input type="hidden" name="src" value="\ref[src]" />
			<input type="text" name="new_message" size="15" />
			<input type="submit" value="Send" style="align:bottom;width=[M.screen.x - 200]px;"/>
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
			if(M.auth.username == "unknown")
				NewMessage("Access denied. Please login", "System")
			else
				NewMessage(href_list["new_message"], M.auth.username)
				var/list/req = list()
				req["message"] = href_list["new_message"]
				req["soft_type"] = type
				req["user"] = M.auth.username
				M.connector.SendSignal(null, GlobalAddress(), req)
		updateUsrDialog()

	Requirements()
		if(!M.auth)
			return "Need auth module"
		else if(!M.auth.logged)
			return "Try to login"
		if(!M.connector)
			return "Need net module"
		return 0

	proc/NewMessage(var/text, var/user)
		saved_text += "\n<" + user + "> " + text