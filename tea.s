    .data
key: .word 234, 252, 2135, 2356

value: .word 53, 26

newline: .asciiz "\n"

    .text
    .globl main
main:
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



    .globl tea_encrypt
tea_encrypt:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, 0($a1)      #v0
    lw $t1, 4($a1)      #v1

    li $t2, 0           #sum

    li $t9, 0x9e3779b9

    li $t7, 32

loop:

    addu $t2, $t2, $t9

    # v0 += ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1)

    sll $t3, $t1, 4
    lw $t5, 0($a0)      #k0
    addu $t3, $t3, $t5

    addu $t4, $t1, $t2

    xor $t3, $t3, $t4

    srl $t4, $t1, 5
    lw $t5, 4($a0)      #k1
    addu $t4, $t4, $t5

    xor $t3, $t3, $t4
    addu $t0, $t0, $t3
    ###

    # v1 += ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) +k3)

    sll $t3, $t0, 4
    lw $t5, 8($a0)
    addu $t3, $t3, $t5

    addu $t4, $t0, $t2

    xor $t3, $t3, $t4

    srl $t4, $t0, 5
    lw $t5, 12($a0)
    addu $t4, $t4, $t5

    xor $t3, $t3, $t4
    addu $t1, $t1, $t3
    ###

    
    
    addi $t7, $t7, -1
    bgtz $t7, loop
    b done

done:
    sw $t0, 0($a1)
    sw $t1, 4($a1)

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

    
