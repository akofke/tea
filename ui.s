#This file describes the input and output methods of the program.
#The user inputs a number to select the program action

.data
#Reserving space for user values
key: .space 16 #equal to 128 bits
chunk: .space 8 #equal to 64 bits
quick: .space 33 #32 character quick encryption string
file_in: .space 17 #16 char filename input buffer
file_out: .space 17 #16 char filename output buffer
ret_addr: .space 4 #holds return address for func calls, protects when calling encryptor/file-io

#Specifies the different console outputs
ui_input: .asciiz "Please enter a number for what you would like to do:\n 0: Quick Encryption\n 1: Quick Decryption\n 2: File Encryption\n 3: File Decryption\n 4: Quit\n"
quick_encrypt: .asciiz "\nEnter the string you would like to encrypt: "
quick_decrypt: .asciiz "\nEnter the encrypted text you would like to decrypt: "
file_encrypt: .asciiz "\nEnter the full name of the plain text file you would like to encrypt: "
file_decrypt: .asciiz "\nEnter the full name of the encrypted file you would like to decrypt: "
decrypt_out: .asciiz "\nEnter the full name of the file you would like to output decryted text to: "
user_key: .asciiz "\nType in a key for use in encryption, which can be up to 16 characters. (Don't forget it!): "
error: .asciiz "\nYou did not enter a correct input. Please quit and try again."
exit_msg: .asciiz "\nThe program is now closing."

.text
main:
Input:	#Asks user for input, does appropriate routing of program
	la $a0, ui_input
	li $v0, 4
	syscall #generates initial input query

	li $v0, 5
	syscall #grabbing user's integer input, value will be in $v0

	add $t0, $zero, $zero
	beq $t0, $v0, Q_encrypt #branches to quick encrypt portion

	addi $t0, $zero, 1
	beq $t0, $v0, Q_decrypt #branches to quick decrypt portion

	addi $t0, $zero, 2
	beq $t0, $v0, F_encrypt #branches to file encrypt portion

	addi $t0, $zero, 3
	beq $t0, $v0, F_decrypt #branches to file decrypt

	addi $t0, $zero, 4
	beq $t0, $v0, Exit #branches to exit

	j Error

Q_encrypt:	#Handles quick string encryption calls ### need to re-null terminate string before outputting
	la $a0, quick_encrypt
	li $v0, 4
	syscall

	li $a1, 33 #allows for up to 32 characters to be input as a string (max size)
	la $a0, quick
	li $v0, 8
	syscall #takes in user's plain text input for a quick string operation
	
	jal Get_key

	addi $s0, $zero, 1 #s0 is not zero, so encrypt
	jal QuickChunker

	la $a0, quick
	li $v0, 4
	syscall

	j Input

Q_decrypt:	#Quick decryption calls ### need to re-null terminate string before outputting
	la $a0, quick_decrypt
	li $v0, 4
	syscall

	li $a1, 33
	la $a0, quick
	li $v0, 8
	syscall #takes in user's encrypted text for a quick string operation

	jal Get_key

	add $s0, $zero, $zero #s0 is zero, so decrypt
	jal QuickChunk

	la $a0, quick
	li $v0, 4
	syscall

	j Input

F_encrypt:	#File encryption
	la $a0, file_encrypt
	li $v0, 4
	syscall #prompts for input file name

	li $a1, 16
	la $a0, file_in
	li $v0, 8
	syscall #grabbing filename to encrypt

	jal Get_key

	##file reading, and then chunking for encryption input
	##create a file to enter encrypted text into, just gets an appended title

	j Input

F_decrypt:	#File decryption
	la $a0, file_decrypt
	li $v0, 4
	syscall #prompts for input file name

	li $a1, 16
	la $a0, file_in
	li $v0, 8
	syscall

	la $a0, decrypt_out
	li $v0, 4
	syscall #prompts for output file name

	li $a1, 16
	la $a0, file_out
	li $v0, 8
	syscall

	jal Get_key

	##file reading, and then chuinking for decryption input
	##create a file to enter decrypted text into, specified by user input

	j Input

Error:	#Prints an error message
	la $a0, error
	li $v0, 4
	syscall

	j Input

Exit: 	#Exits the programme
	la $a0, exit_msg
	li $v0, 4
	syscall

	li $v0, 10
	syscall #exits

Get_key:	#asks for the user's key, returns the value in $v0
	la $a0, user_key
	li $v0, 4
	syscall #asks for user key

	la $a0, key
	li $a1, 17
	li $v0, 8
	syscall #reads key
	jr $ra

QuickChunk:	#Creates 64b chunks, and passes them to the encryptor.
	la $a2, ret_addr
	sw $ra, 0($a2) #stores return address
	add $t0, $zero, $zero #counter within string
	add $t1, $zero, $zero #counter within a chunk

	j ChunkLoop
	
ChunkLoop:
	la $a2, chunk
	la $a3, quick

	addu $a3, $a3, $t0
	lw $t2, 0($a3)
	addi $t0, $t0, 4

	addu $a2, $a2, $t1
	sw $t2, 0($a2)
	addi $t1, $t1, 4
	#moves a byte from current chunk into chunk buffer

	addi $t7, $zero, 8
	beq $t1, $t7, ChunkDone #branches after loading 2 32b sections from quick
	j ChunkLoop

ChunkDone:	#chunk completely loaded. send to encryptor
		#if $t0(quick) (pointing to head of new chunk) is null terminator, finished
	##send chunk
	la $a0, key
	la $a1, chunk

	##if $s0 is equal to 0 (set before func call) then we are decrypting
	##else, execute encryption
	beq $s0, $zero, ChunkDecrypt

	jal tea_encrypt
	j ChunkSwap

ChunkDecrypt:
	jal tea_decrypt
	j ChunkSwap

ChunkSwap:
	##save encrypted chunk from buffer
	##currently will replace the original section with the encrypted chunk
	la $a2, chunk
	la $a3, quick
	lw $t5, 0($a2)
	addi $t4, $t0, -8 #backstep 2 words
	addu $a3, $a3, $t4
	sw $t5, 0($a3) #save first word

	lw $t5, 4($a2)
	addi $a3, $a3, 4
	sw $t5, 0($a3) #save second word

	la $a3, quick
	addu $a3, $a3, $t0
	lb $t6, 0($a3) #sign extends next byte in quick string while loading
	beq $t6, $zero, ChunkExit #exits chunking function when next section starts with null-terminator
	
	add $t1, $zero, $zero
	j ChunkLoop #continues chunking

ChunkExit:	#reached a null terminator-charactor
	la $a2, ret_addr
	lw $ra, 0($a2)
	jr $ra
