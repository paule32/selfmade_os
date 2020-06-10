	.text
	jmp RealMode

	.globl	k_clear_screen
k_clear_screen:
.LFB0:
	movl	$753664, %eax
.L2:
	movb	$32, (%eax)
	movb	$7, 1(%eax)
	addl	$2, %eax
	cmpl	$757664, %eax
	jne	.L2
	rep ret
.LFE0:
	.globl	k_printf
k_printf:
.LFB1:
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	16(%esp), %ecx
	movl	20(%esp), %esi
	movzbl	(%ecx), %eax
	leal	(%esi,%esi,4), %edx
	sall	$5, %edx
	testb	%al, %al
	jne	.L9
	jmp	.L6
.L7:
	movb	%al, 753664(%edx)
	movb	$7, 753665(%edx)
	addl	$2, %edx
	movzbl	1(%ecx), %eax
	movl	%ebx, %ecx
	testb	%al, %al
	je	.L6
.L9:
	cmpb	$47, %al
	leal	1(%ecx), %ebx
	jne	.L7
	movzbl	1(%ecx), %eax
	cmpb	$110, %al
	je	.L8
	leal	2(%ecx), %edi
	movl	%ebx, %ecx
	movl	%edi, %ebx
	jmp	.L7
.L8:
	movzbl	2(%ecx), %eax
	addl	$1, %esi
	leal	2(%ecx), %edi
	leal	(%esi,%esi,4), %edx
	sall	$5, %edx
	testb	%al, %al
	je	.L6
	leal	3(%ecx), %ebx
	movl	%edi, %ecx
	jmp	.L7
.L6:
	popl	%ebx
	movl	$1, %eax
	popl	%esi
	popl	%edi
	ret
.LFE1:
	.globl	outportb
outportb:
.LFB2:
	movl	4(%esp), %edx
	movl	8(%esp), %eax
	outb %al,%dx
	ret
.LFE2:
	.globl	update_cursor
update_cursor:
.LFB3:
	pushl	%esi
	pushl	%ebx
	movl	$980, %esi
	movl	12(%esp), %ecx
	movl	$15, %eax
	movl	%esi, %edx
	leal	(%ecx,%ecx,4), %ecx
	sall	$4, %ecx
	addw	16(%esp), %cx
	outb %al,%dx
	movl	$981, %ebx
	movl	%ecx, %eax
	movl	%ebx, %edx
	outb %al,%dx
	movl	$14, %eax
	movl	%esi, %edx
	outb %al,%dx
	movl	%ecx, %eax
	movl	%ebx, %edx
	shrw	$8, %ax
	outb %al,%dx
	popl	%ebx
	popl	%esi
	ret
.LFE3:
	.data
.LC0:
	.string	"Welcome to MyOS."
.LC1:
	.string	"The C kernel has been loaded."
	.text
	.globl	RealEntry
RealEntry:
.LFB4:
	pushl	%edi
	pushl	%esi
	movl	$753664, %eax
	pushl	%ebx
.L22:
	movb	$32, (%eax)
	movb	$7, 1(%eax)
	addl	$2, %eax
	cmpl	$757664, %eax
	jne	.L22
	movl	$101, %edx
	movl	$87, %ebx
	xorl	%eax, %eax
	xorl	%esi, %esi
	movl	$.LC0, %ecx
.L23:
	movb	%bl, 753664(%eax)
	movb	$7, 753665(%eax)
	addl	$2, %eax
	testb	%dl, %dl
	je	.L35
	cmpb	$47, %dl
	je	.L41
	movl	%edx, %ebx
	addl	$1, %ecx
	movzbl	1(%ecx), %edx
	jmp	.L23
.L41:
	movzbl	2(%ecx), %ebx
	movzbl	3(%ecx), %edx
	cmpb	$110, %bl
	je	.L25
	addl	$2, %ecx
	jmp	.L23
.L25:
	addl	$1, %esi
	leal	3(%ecx), %edi
	leal	(%esi,%esi,4), %eax
	sall	$5, %eax
	testb	%dl, %dl
	je	.L35
	movl	%edx, %ebx
	movzbl	4(%ecx), %edx
	movl	%edi, %ecx
	jmp	.L23
.L35:
	movl	$104, %edx
	movl	$84, %ebx
	movl	$320, %eax
	movl	$2, %esi
	movl	$.LC1, %ecx
.L33:
	movb	%bl, 753664(%eax)
	movb	$7, 753665(%eax)
	addl	$2, %eax
	testb	%dl, %dl
	je	.L32
	cmpb	$47, %dl
	je	.L29
	movl	%edx, %ebx
	addl	$1, %ecx
	movzbl	1(%ecx), %edx
	jmp	.L33
.L29:
	movzbl	2(%ecx), %ebx
	movzbl	3(%ecx), %edx
	cmpb	$110, %bl
	je	.L31
	addl	$2, %ecx
	jmp	.L33
.L31:
	addl	$1, %esi
	leal	3(%ecx), %edi
	leal	(%esi,%esi,4), %eax
	sall	$5, %eax
	testb	%dl, %dl
	je	.L32
	movl	%edx, %ebx
	movzbl	4(%ecx), %edx
	movl	%edi, %ecx
	jmp	.L33
.L32:
	movl	$980, %ebx
	movl	$15, %eax
	movl	%ebx, %edx
	outb %al,%dx
	movl	$981, %ecx
	movl	$-16, %eax
	movl	%ecx, %edx
	outb %al,%dx
	movl	$14, %eax
	movl	%ebx, %edx
	outb %al,%dx
	xorl	%eax, %eax
	movl	%ecx, %edx
	outb %al,%dx
	xorl	%eax, %eax
	popl	%ebx
	popl	%esi
	popl	%edi
	ret
.LFE4:
