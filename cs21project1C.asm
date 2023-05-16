# CS 21 LAB 1 -- S1 AY 2022-2023
# Andrei Tiangco -- 11/08/2022
# cs21project1C.asm -- Peg Solitaire Solver

##### IDENTIFIERS #####
.eqv	peg		111
.eqv	hole		46
.eqv	board_size	7
##### IDENTIFIERS #####

##### MACROS #####
.macro newline()
	li		$a0, 10
	li		$v0, 11
	syscall
.end_macro

.macro assignChar(%var, %chr)
	li		$t2, %chr
	sb		$t2, (%var)
.end_macro

.macro get_element_address(%row, %col)
	move		$t1, $a0			# t1 = currRow
	mul		$t1, $t1, board_size		# t1 = currRow*7
	add		$t1, $t1, $a1			# t1 = currow*7 + currCol
	la		$v0, board
	addu		$v0, $v0, $t1
.end_macro

.macro modifyElement(%chr)
	get_element_address($a0, $a1)
	assignChar($v0, %chr)
.end_macro

.macro print(%str)
	la		$a0, %str
	li		$v0, 4
	syscall
.end_macro

.macro push_path()
	move		$t5, $s0			# $t5 = row
	addi		$t5, $t5, 49			# $t5 = (row + 1) + 48 --> ('1', '2', ...)
	sb		$t5, 0($t4)			# path[i][0] = char(row+1)
	addi		$t5, $t4, 1
	assignChar($t5, ',')				# path[i][1] = ','
	move		$t5, $s1
	addi		$t5, $t5, 49			# $t5 = (col + 1) + 48 -> ('1', '2', ...)
	sb		$t5, 2($t4)			# path[i][2] = char(col+1)
	addi		$t5, $t4, 3
	assignChar($t5, '-')				# path[i][3] = '-'
	addi		$t5, $t4, 4
	assignChar($t5, '>')				# path[i][4] = '>'
	addi		$t6, $t6, 49			# $t6 = (row' + 1) + 48 
	sb		$t6, 5($t4)			# path[i][5] = char(row'+1)
	addi		$t5, $t4, 6			
	assignChar($t5, ',')				# path[i][6] = ','
	addi		$t7, $t7, 49			# t7 = (col' + 1) = 48
	sb		$t7, 7($t4)			# path[i][7] = char(col'+1)
	addi		$t4, $t4, 8	
.end_macro
##### MACROS #####


.text
##### DRIVER PROGRAM #####
main:
	jal		init_board		# initialize peg board
	jal		find_dest		# find final destination of peg
	jal		count_pegs		# count current number of pegs	
	la		$t4, path		# final pointer to path array
	jal		peg_solve		# call peg solver function
	beqz		$v0, main_fail
main_success:
	print(yes)				# if return != 0, print 'YES'
	la		$t3, path		# start pointer to path array
main_printPath:
	beq		$t3, $t4, main_end	# if start ptr == final pointer
	newline()
	li		$t0, 0			
main_pathInner:
	beq		$t0, 8, main_printPath
	lb		$a0, ($t3)		
	li		$v0, 11			
	syscall
	addi		$t3, $t3, 1
	addi		$t0, $t0, 1
	j		main_pathInner
main_fail:
	print(no)				# if return == 0, print 'NO'
main_end:
	li		$v0,10 			# finish execution
	syscall


##### INITIALIZE BOARD #####
init_board:
	##### PREAMBLE #####
	subi		$sp, $sp, 32
	sw		$ra, 28($sp)
	sw		$s0, 24($sp)
	sw		$s1, 20($sp)
	##### PREAMBLE #####
	li		$s0, board_size		# counter for 7 lines
	la		$s1, board		# load start of board address
init_loop:
	beqz		$s0, init_return	# return after exhausting 7 lines
        li		$v0, 8 			# read string
        move		$a0, $s1		# pass curr address in board
        li		$a1, 8
        syscall	
        subi		$s0, $s0, 1 		# decrement counter
        addi		$s1, $s1, board_size	# move curr board address by 7 bytes
        j		init_loop
init_return:
	# newline()
	##### END #####
	lw		$ra, 28($sp)
	lw		$s0, 24($sp)
	lw		$s1, 20($sp)
	addi		$sp, $sp, 32
	##### END #####
 	jr		$ra


##### FIND AND SET DESTINATION COORDINATES #####
find_dest:
	##### PREAMBLE #####
	subi		$sp, $sp, 32
	sw		$ra, 28($sp)
	sw		$s0, 24($sp)
	sw		$s1, 20($sp)
	sw		$s2, 16($sp)
	##### PREAMBLE #####
	li		$s0, 0				# currRow = 0
	la		$s1, board			# s1 = base
dest_loop:
	beq		$s0, board_size, dest_return	# if currRow == 7, return
	li		$s2, 0				# currCol = 0
dest_innerloop:
	beq		$s2, board_size, dest_incrementRow
	lb		$t0, ($s1)			# access char/element at current address
	beq		$t0, 'O', dest_O		# if element == 'O'
	beq		$t0, 'E', dest_E		# if element == 'E'
	j		dest_incrementCol		
dest_O:
	sb		$s0, 0($gp)			# set global var to final X coord
	sb		$s2, 1($gp)			# set global var to final Y coord
	assignChar($s1, peg)				# if element == 'O', transform to peg
	j		dest_incrementCol		
dest_E:
	sb		$s0, 0($gp)			# set global var to final X coord
	sb		$s2, 1($gp)			# set global var to final Y coord
	assignChar($s1, hole)				# if element == 'E', transform to hole
dest_incrementCol:
	addi		$s2, $s2, 1			# increment column counter
	addi		$s1, $s1, 1			# access next element in flattened array
	j		dest_innerloop			# iterate through inner loop
dest_incrementRow:
	addi		$s0, $s0, 1			# increment row counter
	j		dest_loop			# iterate through outer loop
dest_return:
	##### END #####
	lw		$ra, 28($sp)
	lw		$s0, 24($sp)
	lw		$s1, 20($sp)
	lw		$s2, 16($sp)
	addi		$sp, $sp, 32
	##### END #####
	jr		$ra


##### COUNT PEGS #####
count_pegs:
	##### PREAMBLE #####
	subi		$sp, $sp, 32
	sw		$ra, 28($sp)
	sw		$s0, 24($sp)
	sw		$s1, 20($sp)
	sw		$s2, 16($sp)
	sw		$s3, 8($sp)
	##### PREAMBLE #####
	li		$s3, 0				# total = 0
	li		$s0, 0				# currRow = 0
	la		$s1, board
count_loop:
	beq		$s0, board_size, count_return	# if currRow == 7, return total
	li		$s2, 0				# currCol = 0
count_innerloop:
	beq		$s2, board_size, count_incrementRow	
	lb		$t0, ($s1)			# access char/element at current address
	bne		$t0, peg, count_incrementCol	# if element is a peg, total += 1
count_incrementTotal:
	addi		$s3, $s3, 1			# increment number of pegs
count_incrementCol:
	addi		$s2, $s2, 1			# increment column counter
	addi		$s1, $s1, 1			# move to next element in flattened address
	j		count_innerloop			# iterate through inner loop
count_incrementRow:
	addi		$s0, $s0, 1			# incrememnt row counter
	j		count_loop			# iterate through outer loop
count_return:
	sb		$s3, 2($gp)
	##### END #####
	lw		$ra, 28($sp)
	lw		$s0, 24($sp)
	lw		$s1, 20($sp)
	lw		$s2, 16($sp)
	lw		$s3, 8($sp)
	addi		$sp, $sp, 32
	##### END #####
	jr		$ra


##### SOLVE PEG BOARD #####
peg_solve:
	##### PREAMBLE #####
	subi		$sp, $sp, 32
	sw		$ra, 28($sp)
	sw		$s0, 24($sp)
	sw		$s1, 20($sp)
	sw		$s2, 16($sp)
	##### PREAMBLE #####
	lb		$t0, 2($gp)			# get total num of pegs
	li		$s0, 0				# currRow = 0
	bne		$t0, 1, solve_loopRow
##### BASE CASE #####
solve_correctLoc:					# if total == 1, check if peg in correct loc
	lb		$a0, 0($gp)			# get final X coord 
	lb		$a1, 1($gp)			# get final Y coord 
	get_element_address($a0, $a1)	
	lb		$v0, ($v0)		
	beq		$v0, peg, solve_return1		# return 1 if single peg exists at correct loc
##### BASE CASE #####
solve_loopRow:
	beq		$s0, board_size, solve_return0	# if all rows have been exhausted, return 0
	li		$s1, 0				# currCol = 0
solve_loopCol:
	beq		$s1, board_size, solve_incrementRow	
	li		$s2, 0				# dir = 0
solve_loopDir:
	beq		$s2, 4, solve_incrementCol
	move		$a0, $s0			
	move		$a1, $s1
	get_element_address($a0, $a1)	
	lb		$v0, ($v0)		
	bne		$v0, peg, solve_incrementCol	# return 0 if curr element is not a peg
	move		$a2, $s2
	jal		valid_jump			# call valid_jump(row, col, dir)
	bne		$v0, 1, solve_incrementDir	# if jump is not valid, move to next possible jump
	move		$a0, $s0
	move		$a1, $s1
	move		$a2, $s2
	jal		make_jump
	push_path()
	jal		peg_solve			# recursive call
	beq		$v0, 1, solve_return1		
##### BACKTRACK #####
solve_backtrack:
	subi		$t4, $t4, 8			# move back path pointer by 8 bytes
	move		$a0, $s0
	move		$a1, $s1
	move		$a2, $s2
	jal		undo_jump
##### BACKTRACK #####
solve_incrementDir:
	addi		$s2, $s2, 1			# move to next jump direction
	j		solve_loopDir			
solve_incrementCol:
	addi		$s1, $s1, 1			# move to next column
	j		solve_loopCol			
solve_incrementRow:
	addi		$s0, $s0, 1			# move to next row
	j		solve_loopRow
solve_return1:
	li		$v0, 1
	j		solve_return
solve_return0:
	li		$v0, 0
solve_return:
	##### END #####
	lw		$ra, 28($sp)
	lw		$s0, 24($sp)
	lw		$s1, 20($sp)
	lw		$s2, 16($sp)
	addi		$sp, $sp, 32
	##### END #####
	jr		$ra
	
	
##### VALID JUMP #####
valid_jump:
	##### PREAMBLE #####
	subi		$sp, $sp, 32
	sw		$ra, 28($sp)
	sw		$s0, 24($sp)
	sw		$s1, 20($sp)
	sw		$s2, 16($sp)
	##### PREAMBLE #####
	move		$s0, $a0
	move		$s1, $a1
	move		$s2, $a2
	beq		$s2, 1, valid_leftJump		# if dir == 1, check valid left jump
	beq		$s2, 2, valid_bottomJump	# if dir == 2, check valid bottom jump
	beq		$s2, 3, valid_rightJump		# if dir == 3, check valid right jump
valid_topJump:						# else, check valid top jump
	blt		$s0, 2, valid_return0		
	subi		$a0, $s0, 1
	get_element_address($a0, $a1)			
	lb		$v0, ($v0)			# get board[row-1][col]	
	bne		$v0, peg, valid_return0		
	subi		$a0, $s0, 2			
	get_element_address($a0, $a1)	
	lb		$v0, ($v0)			# get board[row-2][col]
	bne		$v0, hole, valid_return0
	j		valid_return1
valid_leftJump:
	blt		$s1, 2, valid_return0
	subi		$a1, $s1, 1
	get_element_address($a0, $a1)	
	lb		$v0, ($v0)			# get board[row][col-1]	
	bne		$v0, peg, valid_return0
	subi		$a1, $s1, 2
	get_element_address($a0, $a1)	
	lb		$v0, ($v0)			# get board[row][col-2]	
	bne		$v0, hole, valid_return0
	j		valid_return1
valid_bottomJump:
	bgt		$s0, 4, valid_return0
	addi		$a0, $s0, 1
	get_element_address($a0, $a1)	
	lb		$v0, ($v0)			# get board[row+1][col]	
	bne		$v0, peg, valid_return0
	addi		$a0, $s0, 2
	get_element_address($a0, $a1)			
	lb		$v0, ($v0)			# get board[row+2][col]	
	bne		$v0, hole, valid_return0
	j		valid_return1
valid_rightJump:
	bgt		$s1, 4, valid_return0
	addi		$a1, $s1, 1			
	get_element_address($a0, $a1)			
	lb		$v0, ($v0)			# get board[row][col+1]	
	bne		$v0, peg, valid_return0
	addi		$a1, $s1, 2
	get_element_address($a0, $a1)			
	lb		$v0, ($v0)			# get board[row][col+2]	
	bne		$v0, hole, valid_return0
	j		valid_return1
valid_return0:
	li		$v0, 0
	j		valid_return
valid_return1:
	li		$v0, 1
valid_return:
	##### END #####
	lw		$ra, 28($sp)
	lw		$s0, 24($sp)
	lw		$s1, 20($sp)
	lw		$s2, 16($sp)
	addi		$sp, $sp, 32
	##### END #####
	jr		$ra
	
	
##### MAKE JUMP #####
make_jump:
	##### PREAMBLE #####
	subi		$sp, $sp, 32
	sw		$ra, 28($sp)
	sw		$s0, 24($sp)
	sw		$s1, 20($sp)
	sw		$s2, 16($sp)
	##### PREAMBLE #####
	move		$s0, $a0			# s0 = row
	move		$s1, $a1			# s1 = col
	move		$s2, $a2			# s2 = dir
	modifyElement(hole)				# board[row][col] = '.'
	beq		$s2, 1, make_leftJump
	beq		$s2, 2, make_bottomJump
	beq		$s2, 3, make_rightJump
make_topJump:
	move		$a1, $s1
	subi		$a0, $s0, 1
	modifyElement(hole)				# board[row-1][col] = '.'
	subi		$a0, $s0, 2
	modifyElement(peg)				# board[row-2][col] = 'o'
	j		mjump_return
make_leftJump:
	move		$a0, $s0
	subi		$a1, $s1, 1
	modifyElement(hole)				# board[row][col-1] = '.'
	subi		$a1, $s1, 2
	modifyElement(peg)				# board[row][col-2] = 'o'
	j		mjump_return
make_bottomJump:
	move		$a1, $s1
	addi		$a0, $s0, 1
	modifyElement(hole)				# board[row+1][col] = '.'
	addi		$a0, $s0, 2
	modifyElement(peg)				# board[row+2][col] = 'o'
	j		mjump_return
make_rightJump:
	move		$a0, $s0
	addi		$a1, $s1, 1
	modifyElement(hole)				# board[row][col+1] = '.'
	addi		$a1, $s1, 2
	modifyElement(peg)				# board[row][col+2] = 'o'
mjump_return:
	move		$t6, $a0
	move		$t7, $a1
	lb		$t2, 2($gp)
	subi		$t2, $t2, 1		# decrement num of pegs
	sb		$t2, 2($gp)
	##### END #####
	lw		$ra, 28($sp)
	lw		$s0, 24($sp)
	lw		$s1, 20($sp)
	lw		$s2, 16($sp)
	addi		$sp, $sp, 32
	##### END #####
	jr		$ra


##### UNDO JUMP #####
undo_jump:
	##### PREAMBLE #####
	subi		$sp, $sp, 32
	sw		$ra, 28($sp)
	sw		$s0, 24($sp)
	sw		$s1, 20($sp)
	sw		$s2, 16($sp)
	##### PREAMBLE #####
	move		$s0, $a0
	move		$s1, $a1
	move		$s2, $a2
	modifyElement(peg)
	beq		$s2, 1, undo_leftJump
	beq		$s2, 2, undo_bottomJump
	beq		$s2, 3, undo_rightJump
undo_topJump:
	move		$a1, $s1
	subi		$a0, $s0, 1
	modifyElement(peg)
	subi		$a0, $s0, 2
	modifyElement(hole)
	j		ujump_return
undo_leftJump:
	move		$a0, $s0
	subi		$a1, $s1, 1
	modifyElement(peg)
	subi		$a1, $s1, 2
	modifyElement(hole)
	j		ujump_return
undo_bottomJump:
	move		$a1, $s1
	addi		$a0, $s0, 1
	modifyElement(peg)
	addi		$a0, $s0, 2
	modifyElement(hole)
	j		ujump_return
undo_rightJump:
	move		$a0, $s0
	addi		$a1, $s1, 1
	modifyElement(peg)
	addi		$a1, $s1, 2
	modifyElement(hole)
ujump_return:
	lb		$t2, 2($gp)
	addi		$t2, $t2, 1		# increment num of pegs
	sb		$t2, 2($gp)
	##### END #####
	lw		$ra, 28($sp)
	lw		$s0, 24($sp)
	lw		$s1, 20($sp)
	lw		$s2, 16($sp)
	addi		$sp, $sp, 32
	##### END #####
	jr		$ra

.data
board:	.space		49
path:	.space		64
yes:	.asciiz		"YES"
no:	.asciiz		"NO"
