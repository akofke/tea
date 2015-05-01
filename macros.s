.macro PRINT_STR(%str_label)
    	la $a0, %str_label
    	li $v0, 4
    	syscall
.end_macro

.macro READ_STR(%label, %num_chars)
	la $a0, %label
	li $a1, %num_chars
	li $v0, 8
	syscall
.end_macro



.macro STRIP_NEWLINE(%str_label)
	li $t0, 0
loop:
	#read each char and compare to newline
	lb $t1, %str_label($t0)
	li $t2, '\n'
	beq $t1, $t2, done
	addi $t0, $t0, 1
	b loop
done:
	#replace newline character with null
	sb $zero, %str_label($t0)
.end_macro

.macro STR_CONCAT(%res, %first, %second)
	li $t0, 0
	li $t1, 0
first_loop:
	lb $t2, %first($t0)
	beq $t2, $zero, second_loop
	sb $t2, %res($t0)
	addi $t0, $t0, 1
	b first_loop

second_loop:
	lb $t2, %second($t1)
	beq $t2, $zero, done
	sb $t2, %res($t0)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	b second_loop
done:
	nop
.end_macro
	

.macro EXIT(%exit_value)
	li $a0, %exit_value
	li $v0, 17
	syscall
.end_macro


.macro CHECK_FILE_ERROR
	#after file syscalls, if an error occurred $v0 will be negative
	bltz $v0, err
	b no_err
err:
	PRINT_STR(file_error)
	b main
no_err:
	nop #keep going
.end_macro

.macro READ_BLOCK(%fd, %label)
	move $a0, %fd	#file descriptor
	la $a1, %label
	li $a2, 8	#read 8 bytes into block
	li $v0, 14	#read from file
	syscall
	
	CHECK_FILE_ERROR
.end_macro

.macro READ_BLOCK(%fd)
	READ_BLOCK(%fd, block)
.end_macro



.macro WRITE_BLOCK(%fd, %bytes)
	move $a0, %fd
	la $a1, block
	add $a2, $zero, %bytes
	li $v0, 15	#write to file
	syscall
	
	CHECK_FILE_ERROR
.end_macro

.macro WRITE_BLOCK(%fd)
	WRITE_BLOCK(%fd, 8)
.end_macro

.macro CLOSE_FILE(%fd)
	move $a0, %fd
	li $v0, 16	#close file
	syscall
.end_macro

.macro STR_COPY(%to, %from, %len)
	li $t0, 0
copy_loop:
	lb $t1, %from($t0)
	sb $t1, %to($t0)
	addi $t0, $t0, 1
	blt $t0, %len, copy_loop
.end_macro
	

	
		

