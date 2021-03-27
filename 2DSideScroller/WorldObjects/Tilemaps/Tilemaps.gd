extends Node

var static_objects={
	0 : preload("res://2DSideScroller/Entities/Static/Spikes/Spikes.tscn") # create one of these for every scene you want to add to the tileset, (tile_index) : (scene)
}


func _ready():
	for i in $StaticObjects.get_used_cells(): # going through al tiles placed
		var new_obj = static_objects[$StaticObjects.get_cellv(i)].instance() #creating a new object depending on the index of the tile
		new_obj.position = $StaticObjects.map_to_world(i) + (new_obj.size/2) #setting the new object's position to the tile's position
		
		#matching the scene rotation to the tile rotation----
		if $StaticObjects.is_cell_transposed(i.x, i.y) && $StaticObjects.is_cell_x_flipped(i.x, i.y):
			new_obj.rotation_degrees = 90
		elif $StaticObjects.is_cell_x_flipped(i.x, i.y) && $StaticObjects.is_cell_y_flipped(i.x, i.y):
			new_obj.rotation_degrees = 180
		elif $StaticObjects.is_cell_transposed(i.x, i.y) && $StaticObjects.is_cell_y_flipped(i.x, i.y):
			new_obj.rotation_degrees = 270
		#----
		
		get_parent().call_deferred("add_child", new_obj) #adding the new object to the game
		
		$StaticObjects.set_cellv(i, -1) #removing the tile
