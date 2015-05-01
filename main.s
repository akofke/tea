	.include "macros.s"

    .data
    .globl key, block

# 128 bit symmetric encryption key
key: .space 16

# 64 bit block used in the encryption algorithm
block: .space 8

# 32 character input string for quick encrpytion and decryption
quick_input: .space 32

	.globl buffer
buffer: .space 8 #file buffer

#Specifies the different console outputs
ui_input_msg: .asciiz "Please enter a number for what you would like to do:\n 0: Quick Encryption\n 1: Quick Decryption\n 2: File Encryption\n 3: File Decryption\n 4: Quit\n"
quick_encrypt_msg: .asciiz "\nEnter the string you would like to encrypt: "
quick_decrypt_msg: .asciiz "\nEnter the encrypted text you would like to decrypt: "
quick_cyphertext_msg: .asciiz "Your cyphertext is: \n"

file_encrypt: .asciiz "\nThe file being encrypted should be encrypt.txt"
file_decrypt: .asciiz "\nThe file being decrypted should be secure.txt"
decrypt_out: .asciiz "\nThe decrypted text will go into the file cracked.txt"
user_key_promt: .asciiz "\nType in a key for use in encryption, which can be up to 16 characters. (Don't forget it!): "
error: .asciiz "\nYou did not enter a correct input. Please quit and try again."
exit_msg: .asciiz "\nThe program is now closing."
newline: .asciiz "\n"

	.globl file_enc_in, file_enc_out, file_dec_in, file_dec_out
file_enc_in: .asciiz "encrypt.txt"
file_enc_out: .asciiz "secure.txt"
file_dec_in: .asciiz "secure.txt"
file_dec_out: .asciiz "cracked.txt"


    .text

    .globl main
main:

	#Asks user for input, does appropriate routing of program
	la $a0, ui_input_msg
	li $v0, 4
	syscall #generates initial input query

	li $v0, 5
	syscall #grabbing user's integer input, value will be in $v0

	add $t0, $zero, $zero
	beq $t0, $v0, quick_encrypt #branches to quick encrypt portion

	addi $t0, $zero, 1
	beq $t0, $v0, quick_decrypt #branches to quick decrypt portion

	addi $t0, $zero, 2
	#beq $t0, $v0, F_encrypt #branches to file encrypt portion

	addi $t0, $zero, 3
	#beq $t0, $v0, F_decrypt #branches to file decrypt

	addi $t0, $zero, 4
	beq $t0, $v0, Exit #branches to exit

	j Error

    
quick_encrypt:	#Handles quick string encryption calls ### need to re-null terminate string before outputting
	la $a0, quick_encrypt_msg
	li $v0, 4
	syscall

	li $a1, 33 #allows for up to 32 characters to be input as a string (max size)
	la $a0, quick_input
	li $v0, 8
	syscall #takes in user's plain text input for a quick string operation
	
	jal Get_key

	addi $s0, $zero, 1 #s0 is not zero, so encrypt
	jal QuickChunk

	PRINT_STR(quick_cyphertext_msg)
	PRINT_STR(quick_input)
	PRINT_STR(newline)
	# MESSAGE_DIALOG_STR(quick_cyphertext_msg, quick_input)
	

	j main

quick_decrypt:	#Quick decryption calls ### need to re-null terminate string before outputting
	la $a0, quick_decrypt_msg
	li $v0, 4
	syscall

	li $a1, 33
	la $a0, quick_input
	li $v0, 8
	syscall #takes in user's encrypted text for a quick string operation

	jal Get_key

	add $s0, $zero, $zero #s0 is zero, so decrypt
	jal QuickChunk

	PRINT_STR(quick_input)
	PRINT_STR(newline)

	j main

F_encrypt:	#File encryption
	la $a0, file_encrypt
	li $v0, 4
	syscall #Signifes file encryption
	
	jal Get_key

	add $t0, $zero, $zero #encrypting
	##file reading, and then chunking for encryption input
	##create a file to enter encrypted text into, just gets an appended title
	jal open_enc_read
	j main

F_decrypt:	#File decryption
	la $a0, file_decrypt
	li $v0, 4
	syscall #signifies we are doing decryption on a file
	
	la $a0, decrypt_out
	li $v0, 4
	syscall #lets user know the output destination

	jal Get_key

	addi $t0, $zero, 1 #decrypting
	##file reading, and then chuinking for decryption input
	##create a file to enter decrypted text into, specified by user input

	jal open_dec_read
	j main

Error:	#Prints an error message
	la $a0, error
	li $v0, 4
	syscall

	j main

Exit: 	#Exits the programme
	la $a0, exit_msg
	li $v0, 4
	syscall

	li $v0, 10
	syscall #exits

Get_key:	#asks for the user's key, returns the value in $v0
	la $a0, user_key_promt
	li $v0, 4
	syscall #asks for user key

	la $a0, key
	li $a1, 17
	li $v0, 8
	syscall #reads key
	jr $ra

QuickChunk:	#Creates 64b chunks, and passes them to the encryptor.
	#sw $ra, ret_addr #stores return address
	add $s1, $zero, $zero #counter within string
	add $t1, $zero, $zero #counter within a chunk

	j ChunkLoop
	
ChunkLoop:
	la $a2, block
	la $a3, quick_input

	addu $a3, $a3, $s1
	lw $t2, 0($a3)
	addi $s1, $s1, 4

	addu $a2, $a2, $t1
	sw $t2, 0($a2)
	addi $t1, $t1, 4
	#moves a byte from current chunk into chunk buffer

	addi $t7, $zero, 8
	beq $t1, $t7, ChunkDone #branches after loading 2 32b sections from quick
	j ChunkLoop

ChunkDone:	#chunk completely loaded. send to encryptor
	##send chunk
	la $a0, key
	la $a1, block
	
	addi $sp, $sp, -8
	sw $s1, 4($sp)
	sw $ra, 0($sp)

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
	lw $s1, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	
	la $a2, block
	la $a3, quick_input
	lw $t5, 0($a2) #first half loaded
	addi $t4, $s1, -8 #backstep 2 words
	addu $a3, $a3, $t4
	sw $t5, 0($a3) #save first word

	lw $t5, 4($a2) #second half loaded
	addi $a3, $a3, 4
	sw $t5, 0($a3) #save second word

	la $a3, quick_input
	addu $a3, $a3, $s1
	lb $t6, 0($a3) #sign extends next byte in quick string while loading
	beq $t6, $zero, ChunkExit #exits chunking function when next section starts with null-terminator
	
	add $t1, $zero, $zero
	j ChunkLoop #continues chunking

ChunkExit:	#reached a null terminator-charactor
	#lw $ra, ret_addr
	jr $ra

