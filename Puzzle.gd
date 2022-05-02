#controls the sliding puzzle
extends Node2D

signal puzzle_complete #used to tell other nodes that the puzzle is complete

var puzzle = [['Tile2','Tile5','Tile8'],['Tile1','Tile7','Tile3'],['Tile4','Tile6','Tile9']] #messed up grid stored in a 2D array
var solved = false #is the puzzle solved

#on load hide tile 9 to create a "blank space" in the board
func _ready():
	$Border.stop()
	$Border.animation = "default" #hides the picture from view
	$Tile9.visible = false
	update_puzzle() #display the messed up puzzle to the player

#game loop on every frame
func _process(delta):
	
	if !solved: #if the puzzle is not solved
	
		if Input.is_action_just_pressed("puzzle_down"): #down key pressed
			var blank = find_blank() #get the array location of the blank tile 
			
			#if the blank tile is not at the top of the grid, move the tile above it into its place
			if(blank[0] == 1 || blank[0] == 2): 
				puzzle[blank[0]][blank[1]] = puzzle[blank[0] -1][blank[1]]
				puzzle[blank[0] - 1][blank[1]] = 'Tile9'
			
			update_puzzle() #show the player the updated puzzle
		
		if Input.is_action_just_pressed("puzzle_up"): #up key pressed
			var blank = find_blank() #get the array location of the blank tile 
			
			#if the blank tile is not at the bottom of the grid, move the tile below it into its place
			if(blank[0] == 1 || blank[0] == 0):
				puzzle[blank[0]][blank[1]] = puzzle[blank[0] +1][blank[1]]
				puzzle[blank[0] + 1][blank[1]] = 'Tile9'
				
			update_puzzle() #show the player the updated puzzle
			
		if Input.is_action_just_pressed("puzzle_right"):
			var blank = find_blank() #get the array location of the blank tile 
			
			#if the blank tile is not at the left hand side of the grid, move the tile  to the left of it into its place
			if(blank[1] == 1 || blank[1] == 2):
				puzzle[blank[0]][blank[1]] = puzzle[blank[0]][blank[1] - 1]
				puzzle[blank[0]][blank[1] - 1] = 'Tile9'
				
			update_puzzle() #show the player the updated puzzle
			
		if Input.is_action_just_pressed("puzzle_left"):
			var blank = find_blank() #get the array location of the blank tile 
			
			#if the blank tile is not at the right hand side of the grid, move the tile to the right of it into its place
			if(blank[1] == 1 || blank[1] == 0):
				puzzle[blank[0]][blank[1]] = puzzle[blank[0]][blank[1] + 1]
				puzzle[blank[0]][blank[1] + 1] = 'Tile9'
				
			update_puzzle() #show the player the updated puzzle

#returns the array location of the blank tile
func find_blank():
	var found_row = 0 #the row where blank was found
	var i = 0 #iterator for row
	var found_col = 0 #the column where blank was found
	var j = 0 #iterator for column
	for row in puzzle: #loop every row
		j = 0 #reset column counter
		for col in row: #loop every column in the row
			if col == 'Tile9': #if the current location is the "blank" tile
				#set found variables and break the loop
				found_row = i
				found_col = j
				break 
			#move to next column
			j += 1
		#move to next row
		i += 1
		
	var found = [found_row, found_col] #create found tuple to send back
	return found #return tuple

#function to update the graphical form of the puzzle
func update_puzzle():
	var correct = ['Tile1','Tile2','Tile3','Tile4','Tile5','Tile6','Tile7','Tile8','Tile9'] #stores the correct order
	var order = [] #stores the current order of the tiles
	#loop the array and store the current values in order
	for row in puzzle:
		for col in row:
			order.append(col)
			
	var i = 0 #iterator variable
	for child in get_children(): #loop through child nodes of puzzle
		if child is Position2D: #for all the positions in order
			get_node(order[i]).position = child.position #set each tile in turn to their position based on array location
			i += 1 #increment iterator
	
	#if the order is correct the puzzle is solved. overlay the solved picture and animate it
	if order == correct:
		solved = true
		emit_signal("puzzle_complete")
		$Tile9.visible = true
		$Border.play()
		yield($Border,"animation_finished")
		$Border.animation = "complete"

#function for printing the array to the command line for testing purposes	
#func print_puzzle():
#	for row in puzzle:
#		print(row)
#	print(" ")
