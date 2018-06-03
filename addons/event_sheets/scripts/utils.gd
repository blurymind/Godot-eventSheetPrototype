var variableTypeIndex = ["null","Bool","Integer","Float","String","Vector2","Rect2","Vector3","Transform2D","Plane","Quat","AABB","Basis","Transform","Color","NodePath","RID","Object","Dictionary","Array","PoolByteArray","PoolIntArray","PoolRealArray","PoolStringArray","PoolVector2Array","PoolVector3Array","PoolColorArray"]

func getMethodData(node,methodName):
	var methodsArr = node.get_method_list()
	var result = {}
	result["returnType"] = "null"
	for methodId in range(methodsArr.size()):
		## find out if a return type exists and if so what it is
		if methodName == methodsArr[methodId]["name"]:
			if methodsArr[methodId]["name"].substr(0,1) != "_":
				if methodsArr[methodId]["name"].substr(0,4) == ("get_"):
					result["returnType"] = variableTypeIndex[methodsArr[methodId]["return"]["type"]]
					print(methodName,"---returns:",variableTypeIndex[methodsArr[methodId]["return"]["type"]])
			return result

func regexFindWithPos(expression,inputString):
	var result = []
	var ex = RegEx.new()
	ex.compile(expression)
	for matched in ex.search_all(inputString):
		for string in matched.get_strings():
			if string.length() > 0:
#				print("word:",string," Pos:",matched.get_start(),":",matched.get_end())
				result.append({"word":string,"start":matched.get_start(),"end":matched.get_end()})
				break
	return result

func regexFind(expression,inputString):
	var result = []
	var ex = RegEx.new()
	ex.compile(expression)
	for matched in ex.search_all(inputString):
		for string in matched.get_strings():
			result.append(string)
	return result

func regexReplace(expression,inputString,replaceWith=""):
	var result = inputString
	var ex = RegEx.new()
	ex.compile(expression)
	for matched in ex.search_all(inputString):
		print("mached:",matched.get_string())
		print("mached:",matched.get_end())
		result=result.substr(0,matched.get_start()) + replaceWith + result.substr(matched.get_start()+matched.get_strings()[1].length()+3,inputString.length())
	if result.length() == inputString.length():
		print("failed finding text:",result)
		result = inputString
	return result

func CapitalizedToSnakeCase(capitalizedString):
	var result = ""
	var ex = RegEx.new()
	ex.compile("([A-Z]{1}[|a-z0-9]{0,200})")
	for matched in ex.search_all(capitalizedString):
		result += matched.get_string() + "_"
	result = result.to_lower().substr(0,result.length()-1)
	result = result.replace("integer","int")
	result = result.replace("transform2","transform_2")
	result = result.replace("node2_d","node_2d")
	result = result.replace("node3_d","node_3d")
	result = result.replace("null","close")
	return result

func dir_contents(path,filetype):
	var dir = Directory.new()
	var collectedFilePaths = []
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if !dir.current_is_dir():
				if file_name.substr(file_name.rfind("."),file_name.length()) == filetype:
					collectedFilePaths.append(path + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return collectedFilePaths

var icons = {}
func guessedPathIcon(nodeClass):
	if icons.size() == 0:
		print("Loading icons into memory for the first time...")
		for file in dir_contents("res://addons/event_sheets/icons/",".svg"):
			icons[file] = load(file)
		print(icons.size()," icons Loaded")

	var guessedRootIconPath = "res://addons/event_sheets/icons/icon_"+CapitalizedToSnakeCase(nodeClass)+".svg"
	print("Trying to find icon::",guessedRootIconPath)
	if !icons.has("res://addons/event_sheets/icons/icon_"+CapitalizedToSnakeCase(nodeClass)+".svg"):
		guessedRootIconPath = ""
	return guessedRootIconPath

var resultingChildNodes = []
func getChildNodes(rootNode):
	resultingChildNodes = []
	getallnodes(rootNode)
	return resultingChildNodes
func getallnodes(node):
	for N in node.get_children():
		if N.get_child_count() > 0:
			if N.get_name().find("@@") == -1 and N.is_inside_tree():
				resultingChildNodes.append(N)
			getallnodes(N)
		else:
			if N.get_name().find("@@") == -1 and N.is_inside_tree():
				resultingChildNodes.append(N)
	return resultingChildNodes