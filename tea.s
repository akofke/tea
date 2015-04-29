    .data
key: .word 234, 252, 2135, 2356

value: .word 54, 26

newline: .asciiz "\n"

    .text
    .global tea_main
tea_main:

    la $a0, key
    la $a1, value

    jal tea_encrypt

    la $t0, value
    lw $a0, 0($t0)
    li $v0, 1
    syscall
    
    la $t0, value
    lw $a0, 4($t0)
    li $v0, 1
    syscall


    j exit

exit:
    li $v0, 10
    syscall



    .global tea_encrypt
tea_encrypt:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    addi $sp, $sp, -24
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)

    lw $s0, 0($a1)      #v0
    lw $s1, 4($a1)      #v1

    # memory addresses of key and value array
    move $s4, $a0
    move $s5, $a1

    li $s2, 0           #sum

    # li $t9, 0x9e3779b9

    li $s3, 32          # loop index

encrypt_loop:

    # sum += delta
    li $t0, 0x9e3779b9
    addu $s2, $s2, $t0

    move $a0, $s1       #v1 
    lw $a1, 0($s4)      #k0
    lw $a2, 4($s4)      #k1
    move $a3, $s2

    jal feistel_round
    addu $s0, $s0, $v0

    # v0 += ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1)

    ###

    move $a0, $s0       #v0
    lw $a1, 8($s4)      #k2
    lw $a1, 12($s4)     #k3
    move $a3, $s2

    jal feistel_round
    addu $s1, $s1, $v0
    # v1 += ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) +k3)

    ###

    addi $s3, $s3, -1
    bgtz $s3, encrypt_loop
    b done



    .global tea_decrypt
tea_decrypt:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    addi $sp, $sp, -20
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)

    lw $s0, 0($a1)      #v0
    lw $s1, 4($a1)      #v1

    # memory addresses of key and value array
    move $s4, $a0 	#key
    move $s5, $a1	#value

    li $s2, 0xC6EF3720           #sum

    li $s3, 32          # loop index

decrypt_loop:
    move $a0, $s0
    lw $a1, 8($s4)
    lw $a2, 12($s4)
    move $a3, $s2

    jal feistel_round
    subu $s1, $s1, $v0

    move $a0, $s1
    lw $a1, 0($s4)
    lw $a2, 4($s4)
    move $a3, $s2

    jal feistel_round
    subu $s1, $s1, $v0

    li $t0, 0x9e3779b9
    subu $s2, $s2, $t0


    addi $s3, $s3, -1
    bgtz $s3, decrypt_loop
    b done

    
    

feistel_round:
    sll $t0, $a0, 4
    addu $t0, $t0, $a1

    addu $t1, $a0, $a3

    xor $t0, $t0, $t1

    srl $t1, $a0, 5
    addu $t1, $t1, $a2

    xor $v0, $t0, $t1
    jr $ra


done:
    sw $s0, 0($s5)
    sw $s1, 4($s5)
    
    lw $s5, 20($sp)
    lw $s4, 16($sp)
    lw $s3, 12($sp)
    lw $s2, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 24

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

    
