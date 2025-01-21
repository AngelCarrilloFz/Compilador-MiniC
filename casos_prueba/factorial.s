#######################
# DATOS
	.data

_n:
	.word 0
_fact:
	.word 0
_i:
	.word 0
$str1:
	.asciiz"Introduce el número del que quieras conocer su factorial (numero < 0 para acabar ejecución): "
$str2:
	.asciiz"El factorial de "
$str3:
	.asciiz" es "
$str4:
	.asciiz"\n"
$str5:
	.asciiz"Introduce el número del que quieras conocer su factorial (numero < 0 para acabar ejecución): "

############################
# CÓDIGO
	.text
	.globl main
main:
	sw $zero, _n
	li $t0, 1
	sw $t0, _fact
	li $t0, 1
	sw $t0, _i
	li $v0, 4
	la $a0, $str1
	syscall
	li $v0, 5
	syscall
	sw $v0, _n
$label5:
	lw $t0, _n
	li $t1, 0
	sge $t0, $t0, $t1
	beqz $t0, $label6
	lw $t1, _n
	li $t2, 2
	slt $t1, $t1, $t2
	beqz $t1, $label3
	li $t2, 1
	sw $t2, _fact
	b $label4
$label3:
$label1:
	lw $t2, _i
	lw $t3, _n
	sle $t2, $t2, $t3
	beqz $t2, $label2
	lw $t3, _fact
	lw $t4, _i
	mul $t3, $t3, $t4
	sw $t3, _fact
	lw $t3, _i
	li $t4, 1
	add $t3, $t3, $t4
	sw $t3, _i
	b $label1
$label2:
$label4:
	li $v0, 4
	la $a0, $str2
	syscall
	lw $t1, _n
	li $v0, 1
	move $a0, $t1
	syscall
	li $v0, 4
	la $a0, $str3
	syscall
	lw $t2, _fact
	li $v0, 1
	move $a0, $t2
	syscall
	li $v0, 4
	la $a0, $str4
	syscall
	li $v0, 4
	la $a0, $str5
	syscall
	li $v0, 5
	syscall
	sw $v0, _n
	b $label5
$label6:

##################
 #Final: exit
	li $v0, 10
	syscall
