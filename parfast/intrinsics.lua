-- compiler intrinsics
return [[
.section .bss
stack:
  .zero   2048
sp:
  .zero   4
.section .rodata
.LC0:
  .string "[Error]: Stack underflow."
.section .text
underflow:
  pushq   %rbp
  movq    %rsp, %rbp
  movl    $.LC0, %edi
  call    puts
  movl    $1, %edi
  call    exit
.LC1:
  .string "[Error]: Stack overflow."
overflow:
  pushq   %rbp
  movq    %rsp, %rbp
  movl    $.LC1, %edi
  call    puts
  movl    $1, %edi
  call    exit
  .globl parfast.core.push
parfast.core.push:
  pushq   %rbp
  movq    %rsp, %rbp
  subq    $16, %rsp
  movq    %rdi, -8(%rbp)
  movzwl  sp(%rip), %eax
  cmpw    $254, %ax
  jbe     .L4
  call    overflow
.L4:
  movl    sp(%rip), %eax
  cltq
  movq    -8(%rbp), %rdx
  movq    %rdx, stack(,%rax,8)
  movl    sp(%rip), %eax
  addl    $1, %eax
  movw    %ax, sp(%rip)
  nop
  leave
  ret
  .globl parfast.core.pop
parfast.core.pop:
  pushq   %rbp
  movq    %rsp, %rbp
  movl    sp(%rip), %eax
  testw   %ax, %ax
  jne     .L6
  call    underflow
.L6:
  movl    sp(%rip), %eax
  subl    $1, %eax
  movw    %ax, sp(%rip)
  movl    sp(%rip), %eax
  movzwl  %ax, %eax
  cltq
  movq    stack(,%rax,8), %rax
  popq    %rbp
  ret
  .globl parfast.core.dup
parfast.core.dup:
  pushq   %rbp
  movq    %rsp, %rbp
  subq    $16, %rsp
  call    parfast.core.pop
  movq    %rax, -8(%rbp)
  movq    -8(%rbp), %rax
  movq    %rax, %rdi
  call    parfast.core.push
  movq    -8(%rbp), %rax
  movq    %rax, %rdi
  call    parfast.core.push
  nop
  leave
  ret
  .globl parfast.core.rot
parfast.core.rot:
  pushq   %rbp
  movq    %rsp, %rbp
  subq    $32, %rsp
  call    parfast.core.pop
  movq    %rax, -8(%rbp)
  call    parfast.core.pop
  movq    %rax, -16(%rbp)
  call    parfast.core.pop
  movq    %rax, -24(%rbp)
  movq    -16(%rbp), %rax
  movq    %rax, %rdi
  call    parfast.core.push
  movq    -8(%rbp), %rax
  movq    %rax, %rdi
  call    parfast.core.push
  movq    -24(%rbp), %rax
  movq    %rax, %rdi
  call    parfast.core.push
  nop
  leave
  ret
  .globl parfast.core.swap
parfast.core.swap:
  pushq   %rbp
  movq    %rsp, %rbp
  subq    $16, %rsp
  call    parfast.core.pop
  movq    %rax, -8(%rbp)
  call    parfast.core.pop
  movq    %rax, -16(%rbp)
  movq    -8(%rbp), %rax
  movq    %rax, %rdi
  call    parfast.core.push
  movq    -16(%rbp), %rax
  movq    %rax, %rdi
  call    parfast.core.push
  nop
  leave
  ret
]]