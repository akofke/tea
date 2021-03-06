	.include "macros.s"
	
	.data
key: .space 16
block: .space 8

decrypt_buffer: .space 8

input_filename: .space 255
output_filename: .space 259 
cyphertext_extension: .asciiz ".tea"


main_promt: .asciiz "Please enter a number for what you would like to do:\n  0: Encrypt a File\n  1: Decrypt a File\n  2: Exit\nYour Option: "
exiting: .asciiz "Goodbye!"
success: .asciiz "Success! Your output is in file "
file_error: .asciiz "Error during file I/O, most likely you entered a file name that does not exist.\n"
newline: .asciiz "\n"

encr_key_promt: .asciiz "Enter a password key, up to 16 characters: "
decr_key_promt: .asciiz "Enter the key used to encrypt the file: "

encr_file_promt: .asciiz "Enter the name of the file you would like to encrypt: "
decr_file_promt: .asciiz "Enter the name of the encrypted file: "
decr_out_promt: .asciiz "Enter a name for the decrypted file: "



	.text
	.globl main
main:
	PRINT_STR(main_promt)
	
	#read option integer
	li $v0, 5
	syscall
	move $t0, $v0
	
	PRINT_STR(newline)
	
	beq $t0, 0, file_encrypt
	beq $t0, 1, file_decrypt
	
	PRINT_STR(exiting)
	EXIT(0)
	
	
file_encrypt:
	PRINT_STR(encr_file_promt)
	READ_STR(input_filename, 256)
	PRINT_STR(newline)
	
	STRIP_NEWLINE(input_filename)
	STR_CONCAT(output_filename, input_filename, cyphertext_extension)
	
	PRINT_STR(encr_key_promt)
	READ_STR(key, 17)
	PRINT_STR(newline)
	
	jal open_file_read
	move $s0, $v0
	
	jal open_file_write
	move $s1, $v0
	
	b file_encrypt_loop
	
file_decrypt:
	PRINT_STR(decr_file_promt)
	READ_STR(input_filename, 256)
	PRINT_STR(newline)
	
	STRIP_NEWLINE(input_filename)
	
	PRINT_STR(decr_out_promt)
	READ_STR(output_filename, 260)
	STRIP_NEWLINE(output_filename)
	PRINT_STR(newline)
	
	PRINT_STR(decr_key_promt)
	READ_STR(key, 17)
	PRINT_STR(newline)
	
	jal open_file_read
	move $s0, $v0
	
	jal open_file_write
	move $s1, $v0
	
	READ_BLOCK($s0, block)
	b file_decrypt_loop
	
	
file_encrypt_loop:
	READ_BLOCK($s0)
	bne $v0, 8, pad_eof	# if 8 bytes were read, we haven't reached the eof

	# run block through encryption algorithm
	la $a0, key
	la $a1, block
	jal tea_encrypt
	
	# write encrypted block to output file
	WRITE_BLOCK($s1)
	b file_encrypt_loop
	
pad_eof:
	li $t2, 8
	sub $t0, $t2, $v0		#number of bytes needed to pad block to 8 bytes
	move $t1, $v0		# index of first empty byte
pad_loop:
	sb $t0, block($t1)	# pad remainder of block with the number of leftover bytes e.g. "e n d \n 00 00 00 00" becomes "e n d \n 04 04 04 04"
	addi $t1, $t1, 1
	beq $t1, 8, pad_done
	b pad_loop
pad_done:
	#encrypt and write final block
	la $a0, key
	la $a1, block
	jal tea_encrypt
	WRITE_BLOCK($s1)
	b file_done

file_decrypt_loop:
	
	la $a0, key
	la $a1, block
	jal tea_decrypt
	
	READ_BLOCK($s0, decrypt_buffer)
	beqz $v0, strip_padding
	
	WRITE_BLOCK($s1, 8)
	
	STR_COPY(block, decrypt_buffer, 8)
	
	b file_decrypt_loop
strip_padding:
	lb $t0, block+7	#get the last byte of the block, its value will be the number of bytes to strip
	li $t1, 8
	sub $a2, $t1, $t0	# subtract number of padding bytes from 8 to get the correct number of bytes to write
	WRITE_BLOCK($s1, $a2)
	
	b file_done
	


file_done:
	CLOSE_FILE($s0)
	CLOSE_FILE($s1)
	
	PRINT_STR(success)
	PRINT_STR(output_filename)
	PRINT_STR(newline)
	
	# b main
	EXIT(0)
	
open_file_read:
	la $a0, input_filename
	li $a1, 0	#read-only flag
	li $a2, 0	#ignored mode argument
	li $v0, 13	#open file
	syscall
	
	CHECK_FILE_ERROR
	jr $ra

open_file_write:
	la $a0, output_filename
	li $a1, 1	#write only, creates if it doesn't exist
	li $a2, 0
	li $v0, 13
	syscall
	
	CHECK_FILE_ERROR
	jr $ra
	
	
	
