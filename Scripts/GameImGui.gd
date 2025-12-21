extends Node

class MenuBarItem:
	extends RefCounted

	var name := "unnamed"
	var mainMenuItemName := "Debug"
	var enabled := true
	var functions: Array[Callable] = []
	var subMenuNames: Array[String] = []
	var uniquePath: String = ""
	var isWindow := false
	#var windowName := "unnamed window"
	var isWindowShown := false


var _menuItemMap: Dictionary[String, MenuBarItem] = { }
var _windowMap: Dictionary[String, MenuBarItem] = { }
var _fontScale: = 2

var _frameTimeRateTimer := 0.0
var _averageFrameTimes := [0.0]
var _averageFramesCount := 30


func _process(delta: float) -> void:
	# TODO: add is imgui enabled, use a shotcut?
	_ShowMainMenuBar()
	_ShowWindows()

	var frameTimePollingRate := 0.25 # seconds
	_frameTimeRateTimer += delta
	if (_frameTimeRateTimer >= frameTimePollingRate):
		_frameTimeRateTimer -= frameTimePollingRate
		_averageFrameTimes.append(1.0 / Engine.get_frames_per_second())
		if (_averageFrameTimes.size() > _averageFramesCount):
			_averageFrameTimes.pop_front()


func _ready() -> void:
	_averageFrameTimes.resize(_averageFramesCount)
	_averageFrameTimes.fill(0.0)
	_DemoSetup()

	RegisterMainMenuWindow("Godot", "Info", _InfoWindow)
	RegisterMainMenuWindow("ImGui", "Godot ImGui Demo", _DemoWindow)

	var showDemoWindowFn := func() -> void:
		# find comments at https://github.com/ocornut/imgui/blob/master/imgui_demo.cpp
		ImGui.ShowDemoWindow()
	RegisterMainMenuWindow("ImGui", "Dear ImGui Demo", showDemoWindowFn)


## Adds a menu item option for non-window things
func RegisterMainMenuItem(mainMenuItemName: String, itemName: String, fn: Callable, subMenuNames: Array[String] = []) -> void:
	if (fn.is_null() or !fn.is_valid()):
		push_warning("Invalid function passed in for RegisterMainMenuItem with name '%s'" % itemName)
		return

	var allNames := subMenuNames.duplicate()
	allNames.push_front(mainMenuItemName)
	allNames.push_back(itemName)
	var uniquePath := "/".join(allNames)

	if (_menuItemMap.has(uniquePath)):
		# combine the window calls
		_menuItemMap[uniquePath].functions.append(fn)
		return

	var newMenuItem := MenuBarItem.new()
	newMenuItem.name = itemName
	newMenuItem.mainMenuItemName = mainMenuItemName
	newMenuItem.functions.append(fn)
	newMenuItem.subMenuNames = subMenuNames
	newMenuItem.uniquePath = uniquePath
	newMenuItem.isWindow = false
	_menuItemMap[uniquePath] = newMenuItem


# TODO: Optionally seperate window name from menu item name?
func RegisterMainMenuWindow(mainMenuItemName: String, windowName: String, windowFn: Callable, subMenuNames: Array[String] = []) -> void:
	if (windowFn.is_null() or !windowFn.is_valid()):
		push_warning("Invalid function passed in for RegisterMainMenuWindow with window name '%s'" % windowName)
		return

	if (_windowMap.has(windowName)):
		# combine the window calls, which ever called first sets the menu names
		_windowMap[windowName].functions.append(windowFn)
		return

	var newMenuItem := MenuBarItem.new()
	newMenuItem.name = windowName
	newMenuItem.mainMenuItemName = mainMenuItemName
	newMenuItem.functions.append(windowFn)
	newMenuItem.subMenuNames = subMenuNames
	newMenuItem.uniquePath = windowName
	newMenuItem.isWindow = true
	_windowMap[windowName] = newMenuItem


func _ShowMainMenuBar() -> void:
	if (ImGui.BeginMainMenuBar()):
		ImGui.SetWindowFontScale(_fontScale)

		for menuItemPath: String in _menuItemMap.keys():
			_BeginMenuItem(_menuItemMap[menuItemPath])

		for itemName: String in _windowMap.keys():
			_BeginMenuItem(_windowMap[itemName])

		if (ImGui.BeginMenuEx("Edit", false)):
			ImGui.MenuItemEx("Undo", "CTRL+Z")
			ImGui.MenuItemEx("Redo", "CTRL+Y", false, false) # Disabled item
			ImGui.Separator()
			ImGui.MenuItemEx("Cut", "CTRL+X")
			ImGui.MenuItemEx("Copy", "CTRL+C")
			ImGui.MenuItemEx("Paste", "CTRL+V")
			ImGui.EndMenu()

		ImGui.EndMainMenuBar()


func _BeginMenuItem(menuItem: MenuBarItem) -> void:
	if (!ImGui.BeginMenu(menuItem.mainMenuItemName)):
		return

	var menuCount: int = 0
	var showMenuItem := true
	for menuName in menuItem.subMenuNames:
		if (ImGui.BeginMenu(menuName)):
			if (menuCount % 2 == 0):
				# for some reason it forgets the font scale every 3rd nest of the menu
				ImGui.SetWindowFontScale(_fontScale)

			menuCount += 1
		else:
			showMenuItem = false
			break

	# true when all sub menus are shown
	if (showMenuItem):
		if (menuItem.isWindow):
			if (ImGui.MenuItemEx("Show " + menuItem.name, "", false, !menuItem.isWindowShown)):
				_ShowWindow(menuItem)
		else:
			if (ImGui.MenuItem(menuItem.name)):
				_ExecuteMenuItem(menuItem)

	for i in menuCount:
		ImGui.EndMenu() # End Sub Menu

	ImGui.EndMenu()
	# End Main Menu


func _ExecuteMenuItem(menuItem: MenuBarItem) -> void:
	for function: Callable in menuItem.functions:
		function.call()


func _ShowWindow(windowMenuItem: MenuBarItem) -> void:
	windowMenuItem.isWindowShown = true
	ImGui.SetWindowFocusStr(windowMenuItem.name)


func _HideWindow(windowMenuItem: MenuBarItem) -> void:
	windowMenuItem.isWindowShown = false


func _ShowWindows() -> void:
	for windowName: String in _windowMap.keys():
		var windowMenuItem := _windowMap[windowName]
		if (!windowMenuItem.isWindowShown):
			continue

		var open: Array[bool] = [true] # is set to false if the close button is pressed
		if (!ImGui.Begin(windowName, open)):
			# Collapsed or fully clipped, no need to setup window
			ImGui.End()
			continue

		ImGui.SetWindowFontScale(_fontScale)
		for function: Callable in windowMenuItem.functions:
			function.call()
		ImGui.End()

		var closeButtonPressed := open[0] == false
		if (closeButtonPressed):
			_HideWindow(windowMenuItem)


func _InfoWindow() -> void:
	var godotVersionString: String = Engine.get_version_info().string
	ImGui.TextLinkOpenURLEx("Godot %s" % godotVersionString, "https://www.godotengine.org")
	ImGui.Text(
		"Memory Use: %.1f MB / peak %.1f MB" % [
			OS.get_static_memory_usage() / 1000000.0,
			OS.get_static_memory_peak_usage() / 1000000.0,
		],
	)

	ImGui.Text("FPS: %s" % Engine.get_frames_per_second())

	ImGui.PushItemWidth(-1) # make next fill width
	ImGui.PlotLinesEx("##Frame Time Plot", _averageFrameTimes, _averageFrameTimes.size(), 0, "Frame Time (ms)", 0.0, 0.016, Vector2(0, 100), 4)
	ImGui.PopItemWidth()

# Godot Imgui Demo
var myfloat := [0.0]
var mystr: Array[String] = [""]
var values := [2.0, 4.0, 0.0, 3.0, 1.0, 5.0]
var items: Array[String] = ["zero", "one", "two", "three", "four", "five"]
var current_item := [2]
var anim_counter := 0
var wc_topmost: ImGuiWindowClassPtr
var ms_items := items
var ms_selection: Array[int] = []
var table_items: Array[Variant] = []


func _DemoSetup() -> void:
	var io := ImGui.GetIO()
	io.ConfigFlags |= ImGui.ConfigFlags_ViewportsEnable

	wc_topmost = ImGuiWindowClassPtr.new()
	wc_topmost.ViewportFlagsOverrideSet = ImGui.ViewportFlags_TopMost | ImGui.ViewportFlags_NoAutoMerge

	var style := ImGui.GetStyle()
	style.Colors[ImGui.Col_PlotHistogram] = Color.REBECCA_PURPLE
	style.Colors[ImGui.Col_PlotHistogramHovered] = Color.SLATE_BLUE

	for i in range(items.size()):
		table_items.append([i, items[i]])


func _DemoWindow() -> void:
	var gdver: String = Engine.get_version_info()["string"]

	if ImGui.TreeNode("Demo"):
		ImGui.Text("ImGui in")
		ImGui.SameLine()
		ImGui.TextLinkOpenURLEx("Godot %s" % gdver, "https://www.godotengine.org")
		ImGui.Text(
			"mem %.1f KiB / peak %.1f KiB" % [
				OS.get_static_memory_usage() / 1024.0,
				OS.get_static_memory_peak_usage() / 1024.0,
			],
		)
		ImGui.Separator()

		ImGui.DragFloat("myfloat", myfloat)
		ImGui.Text(str(myfloat[0]))
		ImGui.InputText("mystr", mystr, 32)
		ImGui.Text(mystr[0])

		ImGui.PlotHistogram("histogram", values, values.size())
		ImGui.PlotLines("lines", values, values.size())
		ImGui.ListBox("choices", current_item, items, items.size())
		ImGui.Combo("combo", current_item, items)
		ImGui.Text("choice = %s" % items[current_item[0]])

		ImGui.SeparatorText("Multi-Select")
		if ImGui.BeginChild("MSItems", Vector2(0, 0), ImGui.ChildFlags_FrameStyle):
			var flags := ImGui.MultiSelectFlags_ClearOnEscape | ImGui.MultiSelectFlags_BoxSelect1d
			var ms_io := ImGui.BeginMultiSelectEx(flags, ms_selection.size(), ms_items.size())
			apply_selection_requests(ms_io)
			for i in range(items.size()):
				var is_selected := ms_selection.has(i)
				ImGui.SetNextItemSelectionUserData(i)
				ImGui.SelectableEx(ms_items[i], is_selected)
			ms_io = ImGui.EndMultiSelect()
			apply_selection_requests(ms_io)
		ImGui.EndChild()
		ImGui.TreePop()

	if ImGui.TreeNode("Sortable Table"):
		if ImGui.BeginTable("sortable_table", 2, ImGui.TableFlags_Sortable):
			ImGui.TableSetupColumn("ID", ImGui.TableColumnFlags_DefaultSort)
			ImGui.TableSetupColumn("Name")
			ImGui.TableSetupScrollFreeze(0, 1)
			ImGui.TableHeadersRow()

			var sort_specs := ImGui.TableGetSortSpecs()
			if sort_specs.SpecsDirty:
				for spec: ImGuiTableColumnSortSpecsPtr in sort_specs.Specs:
					var col := spec.ColumnIndex
					if spec.SortDirection == ImGui.SortDirection_Ascending:
						table_items.sort_custom(func(lhs: Array, rhs: Array) -> bool: return lhs[col] < rhs[col])
					else:
						table_items.sort_custom(func(lhs: Array, rhs: Array) -> bool: return lhs[col] > rhs[col])
				sort_specs.SpecsDirty = false

			for i in range(table_items.size()):
				ImGui.TableNextRow()
				ImGui.TableNextColumn()
				ImGui.Text("%d" % table_items[i][0])
				ImGui.TableNextColumn()
				ImGui.Text(table_items[i][1] as String)
			ImGui.EndTable()
		ImGui.TreePop()

	ImGui.SetNextWindowClass(wc_topmost)
	ImGui.SetNextWindowSize(Vector2(200, 200), ImGui.Cond_Once)
	if ImGui.Begin("topmost viewport window"):
		ImGui.TextWrapped("when this is a viewport window outside the main window, it will stay on top")
	ImGui.End()


func _physics_process(_delta: float) -> void:
	anim_counter += 1
	if anim_counter >= 10:
		anim_counter = 0
		values.push_back(values.pop_front())


func apply_selection_requests(ms_io: ImGuiMultiSelectIOPtr) -> void:
	for req: ImGuiSelectionRequestPtr in ms_io.Requests:
		if req.Type == ImGui.SelectionRequestType_SetAll:
			if req.Selected:
				ms_selection = range(ms_items.size())
			else:
				ms_selection.clear()
		elif req.Type == ImGui.SelectionRequestType_SetRange:
			for i in range(req.RangeFirstItem, req.RangeLastItem + 1):
				if req.Selected:
					ms_selection.append(i)
				else:
					ms_selection.erase(i)
