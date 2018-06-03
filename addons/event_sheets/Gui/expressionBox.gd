extends TextEdit
tool 

func _ready():
	set_syntax_coloring(true) 
	set_highlight_all_occurrences(true)
	add_keyword_color( "shit", Color(1,0,1) )
#	get_menu().add_icon_item()
	
	connect("text_changed",self,"textChangedFunc")
#	get_tree().get_edited_scene_root()
	
#	for item in getChildNodes(get_tree().get_edited_scene_root()):
##		if str(item.get_name().find("@@")) == -1:
##			print(get_node(item).get_name())
#		var namePrefixDepth = ""
#		print(str(item.get_path()))
##		print(str(item).split("/").size())
#		var objName = item.get_name()
#		var objIcon = item.get_icon()
#		print(objName)
##			var objIcon = get_node(item).get_ic
##			get_menu().add_item(get_node(item).get_name())
#		get_menu().add_icon_item(objIcon,objName)
#	for item in get_tree().get_root().get_children():
#		print(item)

 

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

var resultingChildNodes = []
func getChildNodes(rootNode):
	resultingChildNodes = []
	getallnodes(rootNode)
#	print(resultingChildNodes)
#	print(resultingChildNodes.size())
	return resultingChildNodes

func textChangedFunc():
	print("yaya")

func getallnodes(node):
	for N in node.get_children():
		if N.get_child_count() > 0:
#			print("["+N.get_name()+"]")
			
			resultingChildNodes.append(N)
			getallnodes(N)
		else:
            # Do something
#			print("- "+N.get_name())
			resultingChildNodes.append(N)
	return resultingChildNodes