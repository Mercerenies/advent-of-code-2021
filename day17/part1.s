
;; NOTE: Unless otherwise specified, all functions here follow the
;; System V AMD64 ABI calling convention.
;;
;; https://en.wikipedia.org/wiki/X86_calling_conventions

BITS 64

GLOBAL main
EXTERN fopen, fclose, fscanf, printf

section .data

filename: db "input.txt", 0
filemode: db "r", 0
template_string: db "target area: x=%ld..%ld, y=%ld..%ld", 0
output_str:  db "%ld", 10, 0

x1: dq 0
x2: dq 0
y1: dq 0
y2: dq 0

section .text

main:
  push rbp
  mov rbp, rsp

  ;; [rbp - 8] file pointer
  sub rsp, 16

  ;; Open the file and put it on the stack
  mov rdi, filename
  mov rsi, filemode
  call fopen
  mov [rbp - 8], rax

  ;; Read the file
  mov rdi, rax
  mov rsi, template_string
  mov rdx, x1
  mov rcx, x2
  mov r8, y1
  mov r9, y2
  call fscanf

  ;; Close the file
  mov rdi, [rbp - 8]
  call fclose

  ;; Test
  call run_all

  mov rdi, output_str
  mov rsi, rax
  call printf

  add rsp, 16

  pop rbp
  ret

;; Takes: Nothing; returns maximum height we can achieve
run_all:
  push rbp
  mov rbp, rsp

  push rbx ; Best result
  push r12 ; Start XVelocity
  push r13 ; Start YVelocity

  sub rsp, 8

  mov rbx, -9999

  mov r12, 1
_run_all_xloop:
  mov r13, [y1]
_run_all_yloop:

  mov rdi, r12
  mov rsi, r13
  call run

  cmp rbx, rax
  jg _not_best
  mov rbx, rax

_not_best:
  add r13, 1
  mov rax, [y1]
  mov rcx, -1
  mul rcx
  cmp r13, rax
  jle _run_all_yloop

  add r12, 1
  cmp r12, [x2]
  jle _run_all_xloop

  mov rax, rbx

  add rsp, 8

  pop r13
  pop r12
  pop rbx

  pop rbp
  ret

;; Takes: velocity X, velocity Y; returns maximum height
;; if we land in the target area, or -9999 (sentinel value)
;; if not.
run:
  push rbp
  mov rbp, rsp

  push rbx ; Max Y
  push r12 ; X
  push r13 ; Y

  sub rsp, 8

  mov rax, -9999 ; Default return value

  mov r12, 0
  mov r13, 0
  mov rbx, 0

_run_loop:

  ;; Move X, Y
  add r12, rdi
  add r13, rsi

  ;; Set max Y
  cmp rbx, r13
  jg _no_max_y
  mov rbx, r13

_no_max_y:

  ;; Calculate drag
  cmp rdi, 0
  je _no_drag
  sub rdi, 1
_no_drag:

  ;; Calculate gravity
  sub rsi, 1

  ;; Determine if we've overshot
  cmp r12, [x2]
  jg _run_end
  cmp r13, [y1]
  jl _run_end

  ;; Determine if we're in the box
  cmp r12, [x1]
  jl _run_loop
  cmp r13, [y2]
  jg _run_loop

  mov rax, rbx
_run_end:

  add rsp, 8

  pop r13
  pop r12
  pop rbx

  pop rbp
  ret
