extends TextEdit
tool

var testStringParser = '$"/root/root/Event_Sheet".get_custom_minimum_size() == <:Vector3:>'
var testStringParser2 = '$"/root/root".set_anchor( margin:<:Integer:>, anchor:<:Float:>, keep_margin:<:Bool:>, push_opposite_anchor:<:Bool:> )'
#set_margins_preset( preset:<:Integer:>, resize_mode:<:Integer:>, margin:<:Integer:> )

var scopeRoot
###https://github.com/godotengine/godot/issues/12541
onready var helperMenu = null
### Style ###########
var conditionOperators = ["and","or","not"]
var conditionOperatorsCol = Color(1,0,1)
var variableTypeIndex = ["null","Bool","Integer","Float","String","Vector2","Rect2","Vector3","Transform2D","Plane","Quat","AABB","Basis","Transform","Color","NodePath","RID","Object","Dictionary","Array","PoolByteArray","PoolIntArray","PoolRealArray","PoolStringArray","PoolVector2Array","PoolVector3Array","PoolColorArray"]
var icons = {}

onready var u = load("res://addons/event_sheets/scripts/utils.gd").new()
#onready var h = load("res://addons/event_sheets/scripts/helper.gd").new()
## todo - move the helper menu to its own shared script - so we can reuse it in other places
func _ready():
#	print(getMethodData(self,"get_line"))
#	print("===== getter test ======")
#	u.regexFindWithPos('([^" ]+)|("[^"]*")',testStringParser)
#	print("==== Setter test =====")
#	u.regexFindWithPos('"[^"]+|(\\S+)|"',testStringParser2)
	connect("text_changed",self,"textChangeFunc")
	connect("focus_exited",self,"switchToPreviewMode")
	get_parent().get_node("Label").connect("gui_input",self,"inputOnLabel")
	get_parent().get_node("Label").connect("meta_clicked",self,"userClickedLabelTag")
	get_parent().get_node("Label").connect("meta_hover_started",self,"userHoveredLabelTag")
	
	recreateHelperMenu()
	for word in conditionOperators:
		add_keyword_color( word, conditionOperatorsCol)
		
	for file in u.dir_contents("res://addons/event_sheets/icons/",".svg"):
		icons[file] = load(file)
	get_menu().add_item("API >")
	get_menu().set_item_icon(8,icons["res://addons/event_sheets/icons/icon_godot.svg"])
	get_menu().connect("id_pressed",self,"textEditMenuPressed")
	
	if Engine.is_editor_hint():
		scopeRoot = get_tree().get_edited_scene_root().get_parent()
	else:
		scopeRoot = get_tree().get_root()
	switchToPreviewMode()

func switchToPreviewMode():
	switchToEditMode()
	hide()
	get_parent().get_node("Label").bbcode_text = parseToRichTextLabel() 
	get_parent().get_node("Label").rect_min_size.y =  rect_min_size.y * 1.1 +30
	get_parent().get_node("Label").show()

var nodePathPattern = '\\$"([/ A-Za-z0-9_)]+/[ A-Za-z0-9_]+)"'
var nodeNamePattern = '\\$"[/ A-Za-z0-9_)]+/([ A-Za-z0-9_]+)"'
var nodeMethodPattern = '"[/ A-Za-z0-9_)]+".(.*)\\('
var lineBBreplacePattern = '\\$"([/ A-Za-z0-9_)]+/[ A-Za-z0-9_]+)"'
var iconsPath = "res://addons/event_sheets/icons/icon_"
func parseToRichTextLabel():
	print("Parsing:",text)
	var bbCodeResult = ""
	var lineCount = 0
	var charCount = 0
	var lStart
	var lEnd
	for line in text.split("\n"):
		print("LINE:",line)
		lineCount +=1
		var lineLength = line.length() + 1
		bbCodeResult += "[url="+ str(charCount)+":"+ str(lineLength+charCount) +"//line]"
		
#		bbCodeResult +=  "[color=gray]" + str(lineCount) + ".[/color]" +"[/url]"
		

		for logic in u.regexFindWithPos('([^" ]+)|("[^"]*")',line):
#		for logic in regexFindWithPos('"[^"]+|(\\S+)|"',line):
			print("LOGIC:",logic)
			lStart = str(charCount+logic["start"])
			lEnd = str(charCount+logic["end"])
			### Node Path to BB code
			if u.regexFind('(".*")',logic["word"]).size() > 0:
				var nodeName = u.regexFind('".*/(.*)"',logic["word"])[1]
				var nodePath = u.regexFind('"(.*)"',logic["word"])[1]
				var nodeClass = null
				if scopeRoot.get_node(nodePath) != null:
					nodeClass = scopeRoot.get_node(nodePath).get_class()
					print("Node Class:",nodeClass)
				else: print("Node can not be found:",nodePath)
				var guessedRootIconPath = u.guessedPathIcon(nodeClass)
				var lineBBcode = "[url=" +  lStart + ":" + lEnd + "//nodePath:" + nodePath + "]"
				lineBBcode += "[img]" +  guessedRootIconPath + "[/img]"
				lineBBcode += " [color=yellow]" + nodeName + "[/color][/url]"
				bbCodeResult += lineBBcode
			
			### Node method
			if u.regexFind('\\.(.*)\\(',logic["word"]).size() > 0:
				var lineBBcode = "[url=" +  lStart + ":" + lEnd + "//method:" + logic["word"] + "]"
				lineBBcode += "[color=aqua]"+logic["word"].replace("get_","")+"[/color]" +"[/url]"
				bbCodeResult += lineBBcode
#
			########## Comparison symbol ##############
			if logic["word"] == "==" or logic["word"] == "!=" or logic["word"] == "<" or logic["word"] == ">":
				var parseEqualsBB = "[url=" + lStart + ":" + lEnd + "//compare:"+logic["word"]+"]"
				var compareLabel = logic["word"].replace("==","[color=#b4ff99] = [/color]").replace("!=","[color=#ff7c7c]not =[/color]").replace(">","[color=#e2adff] > [/color]").replace("<","[color=#adffcc] < [/color]")
				parseEqualsBB += compareLabel + "[/url]"
				bbCodeResult += " " + parseEqualsBB#replaceTextfromToPos(text,logic["start"],logic["end"],parseEqualsBB)

			########## Variable placeholder ############ 
			if u.regexFind('<:([A-Za-z0-9]+):>',logic["word"]).size() > 0:
				var guessedRootIconPath= ""
				if !icons.has("res://addons/event_sheets/icons/icon_"+u.CapitalizedToSnakeCase(u.regexFind('<:([A-Za-z0-9]+):>',logic["word"])[1])+".svg"):
					guessedRootIconPath = ""
				else: guessedRootIconPath = "res://addons/event_sheets/icons/icon_"+u.CapitalizedToSnakeCase(u.regexFind('<:([A-Za-z0-9]+):>',logic["word"])[1])+".svg"
#				var lineBBcode =

				var setVarBB = "[url=" + lStart + ":" + lEnd + "//var:" + u.regexFind('<:([A-Za-z0-9]+):>',logic["word"])[1] + "]"
				setVarBB += "[color=#ffa8e7]( [img]" +  guessedRootIconPath + "[/img] )[/color]"
				setVarBB += "[/url] "
				bbCodeResult += " " + setVarBB
		charCount += lineLength
	
	if get_parent().get_name() == "Conditions":
		if charCount >1:
			bbCodeResult += "[url=" + str(charCount) + ":" + "//mathOperator:]...[/url]"
		else:
			bbCodeResult += "[url="+str(charCount)+"//Add:Condition][img]res://addons/event_sheets/icons/icon_add.svg[/img] Add Condition[/url]\n"
	
	if get_parent().get_name() == "Actions":
		bbCodeResult += "\n"
		bbCodeResult += "[url="+str(charCount)+"//Add:Action][img]res://addons/event_sheets/icons/icon_add.svg[/img] Add Action[/url]\n"
	return bbCodeResult

var cReplaceTextPos = Vector2(-1,-1)
func userClickedLabelTag(Meta):
	print(Meta)
#	([0-9]+):([0-9]+)//
	cReplaceTextPos.x = -1
	cReplaceTextPos.y = -1
	if u.regexFind('([0-9]+):([0-9]+)//',Meta).size() > 1:
		cReplaceTextPos.x = int(u.regexFind('([0-9]+):([0-9]+)//',Meta)[1])
		cReplaceTextPos.y = int(u.regexFind('([0-9]+):([0-9]+)//',Meta)[2])

	if Meta.length() > 1:
		if Meta.find("compare:") != -1:
			setCompareMenuPopUp(Meta)
		if Meta.find("//line") != -1:
			print("todo menu: add line above, add line bellow, remove line <number>,")
		if Meta.find("//Add:") != -1:## add a new line at the bottom
			if cReplaceTextPos.x == -1 or cReplaceTextPos.y == -1: ##there is no start and end , so it must be a request for a new row
				cursor_set_line(get_line_count())## so we add new commands to the bottom
			else:
				## this needs to happen after user clicks on menu
				text = replaceTextfromToPos(text,cReplaceTextPos.x,cReplaceTextPos.y,"foo")
			bringUpHelperMenu()
#			h.bringUpHelperMenu("getter",scopeRoot)

var compareMenu
var metaLinkClicked
func setCompareMenuPopUp(Meta):
	metaLinkClicked = Meta
	compareMenu = PopupMenu.new()
	compareMenu.add_item("Equals")
	compareMenu.set_item_metadata(0,"==")
	compareMenu.add_item("Not Equals")
	compareMenu.set_item_metadata(1,"!=")
	compareMenu.add_item("Greater")
	compareMenu.set_item_metadata(2,">")
	compareMenu.add_item("Less than")
	compareMenu.set_item_metadata(3,"<")
	compareMenu.set_position(get_global_mouse_position())
	add_child(compareMenu)
	compareMenu.show()
	compareMenu.connect("id_pressed",self,"compareMenuPressed")

func compareMenuPressed(ID):
	var subStart =int(u.regexFind('([0-9]+):[0-9]+//',metaLinkClicked)[1])
	var subEnd =int(u.regexFind('[0-9]+:([0-9]+)//',metaLinkClicked)[1])
	print("START:",subStart)
	print("END:",subEnd)
	text = replaceTextfromToPos(text,subStart,subEnd,compareMenu.get_item_metadata(ID))
	print("Replaced:",replaceTextfromToPos(text,subStart,subEnd,compareMenu.get_item_metadata(ID)))
	switchToPreviewMode()
	compareMenu.queue_free()

func replaceTextfromToPos(rawText,from,to,with):
	var result = rawText.substr(0,from)
	result += with
	result += rawText.substr(to,rawText.length())
	return result

func userHoveredLabelTag(Meta):
	get_parent().get_node("Label").hint_tooltip = Meta


func textEditMenuPressed(ID):
	if ID == 8:
		bringUpHelperMenu()

func inputOnLabel(event):
	if event.is_class("InputEventMouseButton") and event.button_index == BUTTON_LEFT and event.doubleclick:
		switchToEditMode()

func _input(event):
#	return
	if event.is_class("InputEventMouseButton") and !event.pressed and event.button_index == BUTTON_LEFT  and !event.is_echo():
		print(get_word_under_cursor())
		if get_node("helperMenu") != null:
			if !get_focus_owner().get_groups().has("helperMenuGrp"):
				recreateHelperMenu()

func switchToEditMode():
	get_parent().get_node("Label").hide()
	show()

func icon(iconName):
	iconName = "[img]" + iconsPath + iconName + ".svg[/img]"
	return iconName


var menuFilter = null
func recreateHelperMenu():
	if get_parent().get_node("helperMenu") != null:
		get_parent().get_node("helperMenu").free()
#	lastMenuFocused = null
	helperMenu = PopupMenu.new()
	get_parent().add_child(helperMenu)
	helperMenu.set_name("helperMenu")
	helperMenu.add_to_group("helperMenuGrp")
#	helperMenu.clear()
	helperMenu.popup_exclusive = true
#	print(helperMenu.get_path())
	menuFilter = LineEdit.new()
	menuFilter.placeholder_text = "filter"
	menuFilter.set_name("menuFilter")
	helperMenu.add_child(menuFilter)
	menuFilter.add_to_group("helperMenuGrp")
	menuFilter.connect("text_changed",self,"rootFilterTextUpdated")
#	menuFilter.connect("focus_entered",self,"helperMenuGetsFocus")
	menuFilter.rect_min_size.x = 300
#	menuFilter.grab_focus()


func rootFilterTextUpdated(filterInput):
	helperMenu.clear()
	helperMenu.add_item("filter")
	for item in helperMenuData:
		if filterInput in helperMenuData[item]["itemName"] or filterInput in helperMenuData[item]["itemName"].to_lower() or filterInput.length() < 2:
			helperMenu.add_submenu_item(helperMenuData[item]["itemLabel"],helperMenuData[item]["itemName"])
			var addedItemIndex = helperMenu.get_item_count()-1
			helperMenu.set_item_tooltip(addedItemIndex, helperMenuData[addedItemIndex]["tooltip"])
			helperMenu.set_item_icon(addedItemIndex,helperMenuData[addedItemIndex]["icon"])

func subFilterTextUpdated(filterInput):
	print("S Filter:",filterInput)
	filterInput = filterInput.replace(" ","_")
	while lastMenuFocused.get_item_count() > 1:
		lastMenuFocused.remove_item(lastMenuFocused.get_item_count()-1)
#	subMenuData[submenu.get_item_count()-1]={"methodName" : methodName,"icon": submenu.get_item_icon(submenu.get_item_count()-1)} 
#	submenu.set_item_metadata(0,{"path":'$"'+menuMetadata["nodePath"]+'"',"data":subMenuData})
	for item in lastMenuFocused.get_item_metadata(0)["data"]:
		if filterInput in lastMenuFocused.get_item_metadata(0)["data"][item]["methodName"] or filterInput in lastMenuFocused.get_item_metadata(0)["data"][item]["methodName"].to_lower() or filterInput.length() < 2:
			lastMenuFocused.add_item(lastMenuFocused.get_item_metadata(0)["data"][item]["methodName"])
			var addedItemIndex = lastMenuFocused.get_item_count()-1
			lastMenuFocused.set_item_icon(addedItemIndex,lastMenuFocused.get_item_metadata(0)["data"][item]["icon"])

func bringUpHelperMenu():
	for node in get_tree().get_nodes_in_group("helperMenuGrp"):
		node.queue_free()
	populatePopUp()
	helperMenu.set_position(get_global_mouse_position())
	helperMenu.show()
var helperMenuData = {} ## required for filtering later on
 ## required for filtering later on
func populatePopUp():
	recreateHelperMenu()
	helperMenuData = {}
	print("clicked on word:",wordUnderCursor)
	var menuType = ""
	helperMenu = get_parent().get_node("helperMenu")
	if get_parent().get_name() == "Conditions":
		helperMenu.add_item("Getters:")
		menuType = "getter"
	if get_parent().get_name() == "Actions":
		helperMenu.add_item("Setters:")
		menuType = "setter"
	menuFilter.grab_focus()
	var itemIdx = 1

	print("Populating menu, filter:")
	for node in u.getChildNodes(scopeRoot):
		var menuMetadata = {}
		menuMetadata["idx"] = itemIdx
		
		if Engine.is_editor_hint():
			menuMetadata["nodePath"] = str(node.get_path()).substr(str(node.get_path()).rfind("@@")+7,str(node.get_path()).length())
		else:
			menuMetadata["nodePath"] = str(node.get_path())

		menuMetadata["nodeClass"] = node.get_class()
		menuMetadata["nodeProperties"] = node.get_property_list()
		menuMetadata["nodeMethods"] = node.get_method_list()
		menuMetadata["nodeID"] = node.get_instance_id()

		var rootItemName = ""
		for sufix in range(menuMetadata["nodePath"].split("/").size()-1):
			if rootItemName.find("_") == -1:
				rootItemName += "|"
			rootItemName += "_"
		rootItemName += node.get_name()
		var rootItemLabel = rootItemName+ "@" + str(node.get_instance_id())
		rootItemLabel += " (" + node.get_class() + ")"

		var submenu = PopupMenu.new()
		submenu.set_name(rootItemName)
		helperMenu.add_child(submenu)
		helperMenu.add_submenu_item(rootItemLabel,rootItemName)
		helperMenu.set_item_tooltip(itemIdx,menuMetadata["nodePath"])
		##animated_sprite <--- AnimatedSprite
		var guessedRootIconPath = "res://addons/event_sheets/icons/icon_"+u.CapitalizedToSnakeCase(node.get_class())+".svg"
		if icons.has(guessedRootIconPath):
			helperMenu.set_item_icon(itemIdx,icons[guessedRootIconPath])

		helperMenuData[itemIdx] = {"icon":icons[guessedRootIconPath],"itemLabel":rootItemLabel,"itemName":rootItemName,"tooltip":menuMetadata["nodePath"]}
		##add set or get methods
		submenu.add_item("   ")
		submenu.popup_exclusive = true
		submenu.connect("id_pressed",self,"submenuPressed")
		submenu.connect("mouse_entered",self,"submenuEnteredFun")
		submenu.add_to_group("helperMenuGrp")
#		submenu.set_item_metadata(0,['$"'+menuMetadata["nodePath"]+'"'])
#		subMenuData[0] = {"meta":'$"'+menuMetadata["nodePath"]+'"'}
		###### Collect and Sort Data for Menus #############
		var menuDataSetterSorted = []
		var menuDataGetterSorted = []
		for methodId in range(menuMetadata["nodeMethods"].size()):
			if menuMetadata["nodeMethods"][methodId]["name"].substr(0,1) != "_":

				if menuMetadata["nodeMethods"][methodId]["name"].substr(0,4) == ("get_"):
					menuDataGetterSorted.append([menuMetadata["nodeMethods"][methodId]["name"]])
					menuDataGetterSorted[menuDataGetterSorted.size()-1].append(variableTypeIndex[menuMetadata["nodeMethods"][methodId]["return"]["type"]])

				if menuMetadata["nodeMethods"][methodId]["name"].substr(0,4) == ("set_"):
					menuDataSetterSorted.append([menuMetadata["nodeMethods"][methodId]["name"]])
					
					menuDataSetterSorted[menuDataSetterSorted.size()-1].append([])
					for argument in range(menuMetadata["nodeMethods"][methodId]["args"].size()):
						var argumentNameType = {}
						argumentNameType[menuMetadata["nodeMethods"][methodId]["args"][argument]["name"]] = variableTypeIndex[menuMetadata["nodeMethods"][methodId]["args"][argument]["type"]]
						menuDataSetterSorted[menuDataSetterSorted.size()-1][1].append(argumentNameType)
		
#		print(menuDataSetterSorted)
		################## CREATE SUBMENUS #####################
		if menuType == "setter": 
			menuDataSetterSorted.sort()
			for method in menuDataSetterSorted: ## Populate Setters
				var methodName = method[0] + "( "
				for argument in method[1]:
					methodName +=str(argument).replace("(","").replace(":",":<:").replace(")",":>")
#					methodName += "<" + str(argument).replace("(","").replace(")","") + ">"
					methodName += ", "
				methodName += " )"
				submenu.add_item(methodName)
				submenu.set_item_icon(submenu.get_item_count()-1,icons[guessedRootIconPath]) 
#				subMenuData[submenu.get_item_count()-1]["methodName"] = methodName
		
		var subMenuData = {}
		if menuType == "getter" or menuType == "setter": 
			menuDataGetterSorted.sort()
			var methodIdx = 1
			for method in menuDataGetterSorted: ##populate getters
			## todo: some getters require arguments which are not shown atm
				var methodName = method[0] + "() == <:" + str(method[1]) + ":>"
				submenu.add_item(methodName)

				var guessedIconPath = "res://addons/event_sheets/icons/icon_"+u.CapitalizedToSnakeCase(method[1])+".svg"
#				var guessedIconPath = u.guessedPathIcon(method[1])
				if icons.has(guessedIconPath):
					submenu.set_item_icon(submenu.get_item_count()-1,icons[guessedIconPath]) 
#					subMenuData[submenu.get_item_count()-1]["icon"] = icons[guessedIconPath]
				subMenuData[submenu.get_item_count()-1]={"methodName" : methodName,"icon": submenu.get_item_icon(methodIdx)} 
				methodIdx += 1
			submenu.set_item_metadata(0,{"path":'$"'+menuMetadata["nodePath"]+'"',"data":subMenuData})
#			submenu.set_item_metadata(0,[0]subMenuData)
		itemIdx += 1
var menuTextToInsert = ""
func submenuPressed( ID ):
	print("subMenuIndex:",ID)
	print("of Menu:",lastMenuFocused)
	print(lastMenuFocused.get_item_text(ID))
	print(lastMenuFocused.get_name())
	insert_text_at_cursor(lastMenuFocused.get_item_metadata(0)["path"] +'.'+lastMenuFocused.get_item_text(ID)+"\n")
	switchToPreviewMode()

var lastMenuFocused = null
func submenuEnteredFun():
#	print(get_focus_owner())
	if !get_focus_owner().is_class("PopupMenu"):return
	lastMenuFocused = get_focus_owner()
	if get_focus_owner().get_node("menuFilter") == null:
		var subMenuFilter = LineEdit.new()
		subMenuFilter.placeholder_text = "filter"
		subMenuFilter.set_name("menuFilter")
		get_focus_owner().add_child(subMenuFilter)
		subMenuFilter.connect("text_changed",self,"subFilterTextUpdated")
#		subMenuFilter.connect("mouse_entered",self,"helperMenuGetsFocus")
		subMenuFilter.add_to_group("helperMenuGrp")
		subMenuFilter.rect_min_size.x = 300
#	get_focus_owner().get_node("menuFilter").grab_focus() ## <-- doesnt work 

func textChangeFunc():
	var newSize = (get_line_count() * 19)+15
	rect_min_size.y = newSize
	get_parent().get_node("Label").rect_min_size.y = newSize

var wordUnderCursor = ""
func _on_addCondition_pressed():
	wordUnderCursor = get_word_under_cursor()
#	selectWordUnderCursor()
	### conditional autocompletion
	if wordUnderCursor.length() == 0 and text.length()>3:
#		get_parent().get_node("Conditions").text += "\n"
		get_parent().get_node("Conditions").cursor_set_line(get_parent().get_node("Conditions").get_line_count())
		get_parent().get_node("Conditions").insert_text_at_cursor("and ")
	else:
		pass
	bringUpHelperMenu()
	print("Add condition")

func _on_addAction_pressed():
	wordUnderCursor = get_word_under_cursor()
	bringUpHelperMenu()
	print("Add action")
