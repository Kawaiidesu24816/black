//This soft was created when computer have all base functionality so it have important hardware checks

/datum/software/app/textfile
	name = "Text file"
	size = 5
	display_icon = "solar"
	var/saved_text = ""

	Display()
		//var/t = html_encode(saved_text)
		var/t = {"
		<form name="textfield" action="byond://" method="get">
			<input type="hidden" name="src" value="\ref[src]" />
			<textarea name="set_text" value="" rows="15" cols="30">[saved_text]</textarea><BR>
			<input type="submit" value="Save" style="align:bottom;width=[mainframe.screen.x - 200]px;"/>
		</form>
		"}
		return t

	Topic(href, href_list)
		if(href_list["set_text"])
			saved_text = html_decode(href_list["set_text"])
		updateUsrDialog()

	Copy()
		//Transfer some data
		var/datum/software/app/textfile/txt = new /datum/software/app/textfile()
		txt.saved_text = saved_text
		return txt
