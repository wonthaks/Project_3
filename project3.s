.data
	empty: .asciiz "Input is empty."
	long: .asciiz "Input is too long."
	invalid: .asciiz "Invalid base-N number."
	buffer: .space 1000 #store 1000 bytes to accomodate for end of character array
.text
main:
	li $v0, 8		#load 8 in $v0 to read string input from user
	la $a0, buffer	#load buffer into $a0
	li $a1, 1000		#5 in $a1 to store 1000 bytes in buffer
	syscall
	
	add $s0, $a0, $zero	#copy contents of $a0 to $s0
	li $t9, 10			#load 10 into $t9 to use to check for Line Feed character
	li $t8, 0			#load 0 to initialize length of string
	li $t7, 0			#load 0 to use to check whether a space character is between the input string or not (0 indicates string has not started yet, while > 0 means the string has)
	li $t6, 0			#$t6 will be used to calculate the output sum after
	li $t5, 1			#$t5 currently holds the max exponent to use in calculation
	li $t4, 0			#register used to count invalids (and space if string started)
	li $t3, 0			#register to track whether spaces were found between characters
	li $s2, 0			#register to track space invalids
	li $s3, 0			#register to track whether space was found between characters
	li $s4, 0			#register to track whether invalids were found
	addi $s0, $s0, -1	#decrement stack pointer by 1 to account for loop after
	add $s1, $s0, $zero	#copy contents from $s0 into $s1 to use to calculate output later on
	addi $s1, $s1, 1	#increment stack pointer by 1 to use in after loop

loopOne:
	addi $s0, $s0, 1	#add 1 to $s0 to increment stack pointer
	lb $t2, 0($s0)		#load byte from stack (character) into $t2

	li $t0, 97			#load 97 into $t7 to use to compare for valid character (uppercase)
	bge $t2, $t0, checkValidLower	#branch to checkValidLower if  $t2 >= $t0
	
	li $t0, 65			#if previous statement did not execute, load 65 into $t0
	bge $t2, $t0, checkValidUpper	#branch to checkValidUpper if  $t2 >= $t0
	
	li $t0, 48			#if again previous statement did not execute, load 48 into $t0
	bge $t2, $t0, checkValidInteger	#branch to checkValidInteger if  $t2 >= $t0
	
	li $t0, 32			#load 32 into $t0 to use to compare for space character
	beq $t2, $t0, checkSpaceBetween	#if $t2 contains a space character, branch to check whether it is okay to skip or not
	
	beq $t2, $t9, checkLengthAndCalculate	#if the char is LineFeed, then input has ended (so branch to checkLengthAndCalculate)
	addi $t4, $t4, 1	#else, increment the invalid count
	li $t7, 1			#indicate string has started	
	add $t8, $t8, $s2	#add invalid space length to total length
	li $s2, 0			#reload 0 into invalid space length
	li $s4, 1			#load 1 to $s4 to keep track of invalidity
	j loopOne			#and loop again

checkSpaceBetween:
	li $t0, 0			#load 0 into $t0 to compare with value stored in $t7 to see whether space is valid to skip or not
	bgt $t7, $t0, incrementSpaceInvalid	#if value in $t7 is greater than 0, then branch to incrementSpaceInvalid
	j loopOne			#else, go back to original loop (space character skipped)

incrementSpaceInvalid:
	addi $s2, $s2, 1	#add 1 to invalid space length tracker
	li $t3, 1			#load 1 into $t3 to keep track of whether the space was between characters
	j loopOne			#jump back to main loop

checkLengthAndCalculate:
	add $t8, $t8, $t4	#add invalid length to real length
	li $t0, 4			#load 4 into $t0 to check for length of string
	bgt $t8, $t0, handleLonger		#if length is longer than 4, branch to handleLonger
	li $t0, 0			#load 0 into $t0 this time to check if string is empty
	beq $t8, $t0, handleEmpty		#if string is empty, branch to handleEmpty
	li $t0, 1			#load 1 into $t0 to check for invalidity
	beq $s4, $t0, handleInvalid		#if string is invalid, jump to handleInvalid
	li $t0, 1			#load 1 into $t0 to check if spaces were in between characters (since length was less than 4 and more than 0)
	beq $s3, $t0, handleInvalid		#if spaces were between characters and length is less than 4, branch to handleInvalid
	
	addi $sp, $sp, -8 			#decrement stack pointer to use to store exponent value to use and length as parameter
	add $v0, $t5, $zero			#return register for recursive function that holds exponent
	add $a0, $t8, $zero			#argument is length of valid string
	sw $a0, 0($sp)		#store length of string as parameter to pass in
	jal calculateExponent			#else, jump to subprogram calculateExponent (which redirects to calculateOutput)
	add $t5, $v0, $zero		#copy exponent from $v0 to $t5
	addi $sp, $sp, 8		#increment stack pointer to cancel space
	
	addi $sp, $sp, -12		#decrement stack pointer to store exponent value and output value
	add $v0, $t6, $zero		#copy sum to return into return register ($v0)
	add $a0, $t5, $zero		#copy exponent into argument register ($a0)
	add $a1, $s1, $zero		#copy stack pointer to use to get valid characters from string to calculate
	sw $a0, 0($sp)			#save arguments to use in recursive function
	sw $a1, 4($sp)			#$a0 = exponent, $a1 = stack pointer
	jal calculateOutput		#calculate Output
	add $t6, $v0, $zero		#copy sum (return value) from return register to $t6
	addi $sp, $sp, 12		#cancel space
	j outputSum		#output sum and exit program
	
checkValidLower:
	li $t0, 4			#load 4 into $t0 to check for length of string
	bgt $t8, $t0, handleLonger		#if length is longer than 4, branch to handleLonger
	li $t0, 114			#load 114 into $t0 to check for valid lowercase letter
	ble $t2, $t0, incrementLength	#if char is within range, branch to incrementLength
	addi $t4, $t4, 1	#else, increment invalid count
	li $s4, 1			#keep track of invalidity
	j loopOne			#then, go back to loop

checkValidUpper:
	li $t0, 4			#load 4 into $t0 to check for length of string
	bgt $t8, $t0, handleLonger		#if length is longer than 4, branch to handleLonger
	li $t0, 82			#load 82 into $t0 to check for valid uppercase letter
	ble $t2, $t0, incrementLength	#if char is within range, branch to incrementLength
	addi $t4, $t4, 1	#else, increment invalid count
	li $s4, 1			#keep track of invalidity
	j loopOne			#then, go back to loop

checkValidInteger:
	li $t0, 4			#load 4 into $t0 to check for length of string
	bgt $t8, $t0, handleLonger		#if length is longer than 4, branch to handleLonger
	li $t0, 57			#load 82 into $t0 to check for valid integer
	ble $t2, $t0, incrementLength	#if char is within range, branch to incrementLength
	addi $t4, $t4, 1	#else, increment invalid count
	li $s4, 1			#keep track of invalidity
	j loopOne			#then, go back to loop

incrementLength:
	addi $t8, $t8, 1		#increment length by 1
	li $t7, 1				#load 1 into $t7 to keep track of whether string has started or not (to check for space character validity)
	li $t0, 0				#load 0 into $t0 to check whether spaces were found between characters
	bgt $s2, $t0, invalidSpace	#if invalid spaces were found, branch to invalidSpace
incrementLengthPart2:
	add $t8, $t8, $s2		#add invalid lengths to length of string
	li $s2, 0				#reinitialize invalid space lengths to 0 again
	j loopOne				#go back to loopOne

invalidSpace:
	li $s3, 1				#load 1 into $s3 to keep track of invalidity due to space
	j incrementLengthPart2		#jump back to incrementLengthPart2

handleLonger:
	li $v0, 4				#load 4 into $v0 to print out string
	la $a0, long			#load address of string message into $a0
	syscall					#print out string message
	j exit				#jump to exit

handleInvalid:
	li $v0, 4				#load 4 into $v0 to print out string
	la $a0, invalid			#load address of string message into $a0
	syscall					#print out string message
	j exit				#jump to exit

handleEmpty:
	li $v0, 4				#load 4 into $v0 to print out string
	la $a0, empty			#load address of string message into $a0
	syscall					#print out string message
	j exit				#jump to exit

outputSum:
	li $v0, 1		#to print out integer
	add $a0, $t6, $zero		#move contents of sum register to $a0 to print sum after
	syscall
	j exit		#jump to exit
	
exit:
    li $v0, 10		#to end the script
    syscall

calculateExponent:
	addi $sp, $sp, -8 		#make space for values to store
	sw $ra, 4($sp)			#save return address into stack pointer
	sw $a0, 0($sp)			#save argument (length)
	li $t0, 1				#store 1 in $t0 to compare with
	bne	$t0, $a0, calculateExponentMain		#if length is not 1, go to recursive part of subprogram
	addi $sp, $sp, 8		#if length is 1, cancel space
	jr $ra			#return
calculateExponentMain:
	addi $a0, $a0, -1		#decrement $a0 by 1 (length - 1)
	jal calculateExponent	#recursive call
	lw $a0, 0($sp)			#restore original argument
	lw $ra, 4($sp)			#restore return address
	addi $sp, $sp, 8		#cancel space
	li $t0, 28				#load 28 into $t0 to use
	mult $t0, $v0			#multiply current exponent to return with 28
	mflo $v0				#store result in $v0
	jr $ra

calculateOutput:
	addi $sp, $sp, -12	#make space for values to store
	sw $ra, 8($sp)		#save return address into stack pointer
	sw $a1, 4($sp)		#save argument (stack pointer for string)
	sw $a0, 0($sp)		#save argument (exponent)
	li $t0, 32			#load 32 into $t0 to use to compare for space character
	lb $t2, 0($a1)		#load current char to use to compare
	beq $t2, $t0, ignoreSpace	#ignore space if it is, else move on
	li $t0, 10			#load 10 into $t0 to use to compare for lineFeed character
	lb $t1, 0($a1)		#load character from string stack pointer into $t1
	bne $t1, $t0, calculateOutputMain	#if current character is not lineFeed character, go to calculateOutputMain
	addi $sp, $sp, 12	#cancel space
	jr $ra				#return
ignoreSpace:
	addi $a1, $a1, 1	#increment stack pointer for string
	addi $sp, $sp, 12	#cancel space
	j calculateOutput	#ignore space and return to beginning of subprogram (this instance)
calculateOutputMain:
	addi $a1, $a1, 1	#increment stack pointer to get next character
	li $t0, 28			#load 28 into $t0 to use to divide exponent
	div $a0, $t0		#divide exponent by 28
	mflo $a0			#move result into $a0
	jal calculateOutput	#recursive call
	lw $a0, 0($sp)		#restore original argument (exponent)
	lw $a1, 4($sp)		#restore original argument (stack pointer for string)
	lw $ra, 8($sp)		#restore return address
	addi $sp, $sp, 12	#cancel space
	li $t0, 97			#load 97 into $t0 to use to compare for valid lowercase character
	lb $t2, 0($a1)		#load byte from string stack pointer
	blt $t2, $t0, calculateUpperCase	#if current char is less than 97, it cannot be lowercase character
calculateLowerCase:
	addi $t2, $t2, -87 	#subtract 87 from $t2 to make it so that lowercase a is equal to 10
	mult $t2, $a0		#multiply value in $t2 by exponent
	mflo $t0			#move result into temp register
	add $v0, $v0, $t0	#add result into return register
	jr $ra	#return
calculateUpperCase:
	li $t0, 65			#load 65 into $t0 to use to compare for uppercase char
	blt $t2, $t0, calculateInteger		#if current char is less than 65, it cannot be uppercase character
	addi $t2, $t2, -55	#subtract 55 from $t2 to make it so that uppercase A is equal to 10
	mult $t2, $a0		#multiply value in $t2 by exponent
	mflo $t0			#move result into temp register
	add $v0, $v0, $t0	#add result into return register
	jr $ra	#return
calculateInteger:
	li $t0, 48			#load 48 into $t0
	blt $t2, $t0, endOfCal		#if current char is less than 48, it cannot be integer
	addi $t2, $t2, -48	#subtract 48 from $t2 to make it so that integer 0 is equal to 0
	mult $t2, $a0		#multiply value in $t2 by exponent
	mflo $t0			#move result into temp register
	add $v0, $v0, $t0	#add result into return register
	jr $ra	#return
endOfCal:
	li $t0, 28			#to restore exponent because spaces are ignored
	mult $a0, $t0		#multiply exponent by 28
	mflo $a0			#move result into $a0
	jr $ra				#return (because it is space, it should be ignored)