-- Compiler intrinsics and main function
return [[
format ELF64 executable 3
; start header
entry _start

parfast.stack: rq 256

macro parfast.core.push val {
  mov rax, val
  mov [r15], rax
  add r15, 8
}
macro parfast.core.drop dst {
  sub r15, 8
  mov rax, [r15]
  mov dst, rax
}
parfast.core.dup:
  push rbp
  mov rbp, rsp
  sub rbp, 16
  parfast.core.drop [rbp-8]
  parfast.core.push [rbp-8]
  parfast.core.push [rbp-8]
  leave
  ret
parfast.core.swap:
  push rbp
  mov rbp, rsp
  sub rbp, 16
  parfast.core.drop [rbp-8]
  parfast.core.drop [rbp-16]
  parfast.core.push [rbp-16]
  parfast.core.push [rbp-8]
  leave
  ret
parfast.core.add:
  push rbp
  mov rbp, rsp
  parfast.core.drop rbx
  parfast.core.drop rax
  add rax, rbx
  parfast.core.push rax
  leave
  ret
parfast.core.sub:
  push rbp
  mov rbp, rsp
  parfast.core.drop rbx
  parfast.core.drop rax
  sub rax, rbx
  parfast.core.push rax
  leave
  ret
parfast.core.mul:
  push rbp
  mov rbp, rsp
  parfast.core.drop rbx
  parfast.core.drop rax
  imul rax, rbx
  parfast.core.push rax
  leave
  ret
parfast.core.div:
  push rbp
  mov rbp, rsp
  parfast.core.push 1
  leave
  ret
_start:
  mov r14, parfast.stack
  call parfast.main
  mov rdi, rax
  mov rax, 60
  syscall
; end header
]]