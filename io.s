    .globl open_enc_read
open_enc_read:
	#Open file for reading
	li   $v0, 13       
	la   $a0, file_enc_in     # output file name
	li   $a1, 0        # flag for reading
	li   $a2, 0        # mode (dont worry about this)
	syscall            # open file
	  
	move $s6, $v0      # moves file descriptor from $v0 to $s6

	j open_enc_write
	
    .globl open_enc_write
open_enc_write:
	# Open file for writing (does not have to exist)
	li   $v0, 13       
	la   $a0, file_enc_out     # output file name
	li   $a1, 1        # flag for writing
	li   $a2, 0        # mode 
	syscall            # open file
  
	move $s5, $v0      # moves file descriptor from $v0 to $s6    
  
	j read
	
    .globl open_dec_read
open_dec_read:
	#Open file for reading
	li   $v0, 13       
	la   $a0, file_dec_in     # output file name
	li   $a1, 0        # flag for reading
	li   $a2, 0        # mode (dont worry about this)
	syscall            # open file
	  
	move $s6, $v0      # moves file descriptor from $v0 to $s6

	j open_dec_write
 
  
    .globl open_dec_write
open_dec_write:
	# Open file for writing (does not have to exist)
	li   $v0, 13       
	la   $a0, file_dec_out     # output file name
	li   $a1, 1        # flag for writing
	li   $a2, 0        # mode 
	syscall            # open file
  
	move $s5, $v0      # moves file descriptor from $v0 to $s6    
  
	j read  
read:
	#Read from file
	li   $v0, 14       
	move $a0, $s6      # file descriptor 
	la   $a1, buffer   # address of buffer to which to read
	li   $a2, 8       # max characters to read
	syscall            # read from file

	#Part of read, store number characters read in another register
	la $s0, ($v0)       #0 if end of file, negative if error. will be used to check look

	#loads buffer for encryption / decryption
	la $a0, key
	la $a1, buffer
	beq $t0, $zero, file_enc
	j file_dec
	
file_enc:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $t0, 4($sp)
	jal tea_encrypt
	
	lw $ra, 0($sp)
	lw $t0, 4($sp)
	addi $sp, $sp, 8
	
	j write

file_dec:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $t0, 4($sp)
	jal tea_decrypt
	
	lw $ra, 0($sp)
	lw $t0, 4($sp)
	addi $sp, $sp, 8
	
	j write
	
write:
  # Write to file 
  
  blez $s0, closeread #first check to see if we're at the end
  
  li   $v0, 15       # system call for write to file
  move $a0, $s5      # file descriptor 
  
  la   $a1, buffer   # address of buffer 
  li   $a2, 8        # write length
  syscall            # write to file   
  
  ## clears the buffer
  la $t1, buffer
  sw $zero, 0($t1)
  sw $zero, 4($t1)
  
  j read 
  
closeread:
  # Close the file 
  li   $v0, 16       # system call for close file 
  move $a0, $s6      # file descriptor to close
  syscall            # close file
  
  j closewrite
  
closewrite:
  # Close the file 
  li   $v0, 16       # system call for close file
  move $a0, $s5      # file descriptor to close
  syscall            # close file
  
  j main	
