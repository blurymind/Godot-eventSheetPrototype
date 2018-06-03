
onready var u = load("res://addons/event_sheets/scripts/utils.gd").new()
onready var helperMenu = null

var menuFilter = null
func recreateHelperMenu():
#	if get_parent().get_node("helperMenu") != null:
#		get_parent().get_node("helperMenu").free()
	helperMenu = PopupMenu.new()
	get_parent().add_child(helperMenu)
#	get_parent().add_child(helperMenu)
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

func bringUpHelperMenu(menuType="getter",scopeRoot=""):
	populatePopUp(menuType,scopeRoot)
	helperMenu.set_position(get_global_mouse_position())
	helperMenu.show()

var helperMenuData = {} ## required for filtering later on
 ## required for filtering later on
func populatePopUp(menuType="getter",scopeRoot=""):
	recreateHelperMenu()
	helperMenuData = {}
#	print("clicked on word:",wordUnderCursor)

#	helperMenu = get_parent().get_node("helperMenu")

	menuFilter.grab_focus()
	var itemIdx = 1

	print("Populating menu, filter:")
	for node in getChildNodes(scopeRoot):
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
		if u.icons.has(guessedRootIconPath):
			helperMenu.set_item_icon(itemIdx,u.icons[guessedRootIconPath])

		helperMenuData[itemIdx] = {"icon":u.icons[guessedRootIconPath],"itemLabel":rootItemLabel,"itemName":rootItemName,"tooltip":menuMetadata["nodePath"]}
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
					menuDataGetterSorted[menuDataGetterSorted.size()-1].append(u.variableTypeIndex[menuMetadata["nodeMethods"][methodId]["return"]["type"]])

				if menuMetadata["nodeMethods"][methodId]["name"].substr(0,4) == ("set_"):
					menuDataSetterSorted.append([menuMetadata["nodeMethods"][methodId]["name"]])
					
					menuDataSetterSorted[menuDataSetterSorted.size()-1].append([])
					for argument in range(menuMetadata["nodeMethods"][methodId]["args"].size()):
						var argumentNameType = {}
						argumentNameType[menuMetadata["nodeMethods"][methodId]["args"][argument]["name"]] = u.variableTypeIndex[menuMetadata["nodeMethods"][methodId]["args"][argument]["type"]]
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
				submenu.set_item_icon(submenu.get_item_count()-1,u.icons[guessedRootIconPath]) 
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
				if u.icons.has(guessedIconPath):
					submenu.set_item_icon(submenu.get_item_count()-1,u.icons[guessedIconPath]) 
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
