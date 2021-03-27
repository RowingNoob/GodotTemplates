extends CanvasLayer

var data : Array # [data_name, data_holder]
var values : Array # [value_name, value]
var do_debug : bool = false # if the debugger is variable and is calculating
var debug_tog_btn : String = "F3" #debug toggle button

onready var v_container = $Control/VBoxContainer
onready var back_color = $Control/ColorRect
onready var ui = $Control

func add_data(data_name : String, data_holder) -> void: # data_name being the name of the variable you want to display, data_holder being the holder of that variable
	data.append([data_name, data_holder])

func _process(delta) -> void:
	if do_debug && Main.dev_mode:
		values.clear() # clearing values so we can get the correct values
		for i in data: # gets every item from the data array
			if i[1]: #making sure the data holder exists
				var value = i[1].get(i[0]) # gets the value from the selected variable
				values.append([i[0], value]) # adds that value alongside it's name to the values array
		
		for i in values: # gets every item from the values array
			if v_container.get_node_or_null(i[0]) != null: # if there is a label that already portrays this value
				v_container.get_node(i[0]).text = str(i[0], " : ", i[1]) # updates the label's value to match the current value
			else: # if there is no label that portrays this value
				var new_l = Label.new() # creates new label
				new_l.name = str(i[0]) # sets label's name
				new_l.text = str(i[0], " : ", i[1]) # sets label's text to the current value
				v_container.add_child(new_l) # adds the label to the v_container
		
		back_color.rect_size = v_container.rect_size # matching the backround color size to the bounds of the v_container

func _input(event):
	#print(event.as_text()) #To change the debug toggle button, uncomment this, press the button you want to toggle the debugger, and then copy the output and set debug_tog_btn as that
	if event.is_pressed() && event.as_text() == debug_tog_btn && Main.dev_mode: # if a button is pressed, and that button (as text) is equal to the debug toggle button
			do_debug = !do_debug #toggling the debug 
			ui.visible = do_debug #setting the visibility to do_debug's value
