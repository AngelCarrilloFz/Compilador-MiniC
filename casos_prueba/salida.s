#######################
# DATOS
	.data

_a:
	.word 0
_b:
	.word 0
_c:
	.word 0
$str1:
	.asciiz"Inicio del programa\n"
$str2:
	.asciiz"a"
$str3:
	.asciiz"\n"
$str4:
	.asciiz"No a y b\n"
$str5:
	.asciiz"c = "
$str6:
	.asciiz"\n"
$str7:
	.asciiz"Final"
$str8:
	.asciiz"\n"

############################
# CÓDIGO
	.text
	.globl main
main:
	li $t0, 0
	sw $t0, _a
	li $t0, 0
	sw $t0, _b
	li $t0, 5
	li $t1, 2
	add $t0, $t0, $t1
	li $t1, 2
	sub $t0, $t0, $t1
	sw $t0, _c
	li $v0, 4
	la $a0, $str1
	syscall
	lw $t0, _a
	beqz $t0, $label5
	li $v0, 4
	la $a0, $str2
	syscall
	li $v0, 4
	la $a0, $str3
	syscall
	b $label6
$label5:
	lw $t1, _b
	beqz $t1, $label3
	li $v0, 4
	la $a0, $str4
	syscall
	b $label4
$label3:
$label1:
	lw $t2, _c
	beqz $t2, $label2
	li $v0, 4
	la $a0, $str5
	syscall
	lw $t3, _c
	li $v0, 1
	move $a0, $t3
	syscall
	li $v0, 4
	la $a0, $str6
	syscall
	lw $t4, _c
	li $t5, 2
	sub $t4, $t4, $t5
	li $t5, 1
	add $t4, $t4, $t5
	sw $t4, _c
	b $label1
$label2:
$label4:
$label6:
	li $v0, 4
	la $a0, $str7
	syscall
	li $v0, 4
	la $a0, $str8
	syscall

##################
 #Final: exit
	li $v0, 10
	syscall
