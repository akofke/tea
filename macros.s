.macro PRINT_STR(%str_label)
    la $a0, %str_label
    li $v0, 4
    syscall
.end_macro

.macro MESSAGE_DIALOG_STR(%message_label, %info_label)
	la $a0, %message_label
	la $a1, %info_label
	li $v0, 59
	syscall
.end_macro