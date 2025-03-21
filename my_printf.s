;===============================================================================
; Globals
global MyPrintf
;===============================================================================

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
section .text
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

;===============================================================================
; Trampline for printf
MyPrintf:
    ;---------------------------------------------------------------------------
    ; Saving return address in R11
    pop r11 ;return address
    ;---------------------------------------------------------------------------
    ; Pushing arguements which may be used in printf to stack
    ; Stack will be used later as an array of arguments
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    ;---------------------------------------------------------------------------
    ; Copying format string address to RSI from RDI (it is always 1st parameter)
    mov rsi, rdi
    ;---------------------------------------------------------------------------
    ; Pushing registers that we need to save
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    ;---------------------------------------------------------------------------
    ; Address of first parameter in RBP (array pointer in printf)
    lea rbp, [rsp + 8 * 6]
    ;---------------------------------------------------------------------------
    ; Jumping to printf which uses (all arguements are in stack)
    jmp MyPrintf_cdecl
    ;---------------------------------------------------------------------------
    ; Address to printf end
    .trampline_back:
    ;---------------------------------------------------------------------------
    ; Resetting registers that we need to save from stack
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ;---------------------------------------------------------------------------
    ; Deleting arguments that we pushed
    add rsp, 8 * 5
    ;---------------------------------------------------------------------------
    ; Returning to caller
    jmp r11
;===============================================================================

;===============================================================================
; String length (0 is end)
; Expects:          R9  - string address
; Returns:          RCX - length of string
;-------------------------------------------------------------------------------
%macro Strlen 0
    ;---------------------------------------------------------------------------
    ; Saving RDI in stack
    push rdi
    ;---------------------------------------------------------------------------
    ; Copying string address to RDI
    mov rdi, r9
    ;---------------------------------------------------------------------------
    ; String terminating symbol in AL
    mov al, 0
    ;---------------------------------------------------------------------------
    ; Max number of bytes to read in RCX (-1 = MAX_UNSIGNED)
    mov rcx, -1
    ;---------------------------------------------------------------------------
    ; Running until current byte is zero
    repne scasb
    ;---------------------------------------------------------------------------
    ; Reversing RCX to get number of bytes
    not rcx
    ;---------------------------------------------------------------------------
    ; Resetting RDI from stack
    pop rdi
%endmacro
;===============================================================================

;===============================================================================
; Macro which moves arguements to needed registers and calls writing number
; Expects:          $1 - mask
;                   $2 - shift
;-------------------------------------------------------------------------------
%macro HandleBinPowerNum 2
    mov r9, [rbp]
    add rbp, 8
    ;---------------------------------------------------------------------------
    ; Mask to R10
    mov r10, %1
    ;---------------------------------------------------------------------------
    ; Shift in CL (deviding by 8 every time)
    mov cl, %2
    ;---------------------------------------------------------------------------
    ; Writing number to buffer
    call ToBinPow
    ;---------------------------------------------------------------------------
    ; Going to next symbol in printf main loop
    jmp .loop_start
%endmacro
;===============================================================================

;===============================================================================
; Function with formatted print. Supported specifiers are:
; |%c|x|
; |%b|x|
; |%x|x|
; |%o|x|
; |%%|x|
; |%d|x|
; |%s|x|
; Expects:          STACK[ 0 ]  - format string address
;                   STACK[...]  - arguments
; Returns:          None
;-------------------------------------------------------------------------------
MyPrintf_cdecl:
    ;---------------------------------------------------------------------------
    ; Setting RAX to zeros
    xor rax, rax
    ;---------------------------------------------------------------------------
    ; Saving buffer address to RDI
    mov rdi, Buffer
    ;---------------------------------------------------------------------------
    ; Main loop through characters
    ; WARNING: IT IS EXPECTED THAT ALL BYTES OF RAX EXCEPT THE LOWEST ARE ZEROS
    .loop_start:
        ;-----------------------------------------------------------------------
        ; Reading symbol
        lodsb
        ;-----------------------------------------------------------------------
        ; Checking if specifier
        cmp al, '%'
        je .specifier_handle
        ;-----------------------------------------------------------------------
        ; Checking if string ends
        test al, al
        jz .printf_end
        ;-----------------------------------------------------------------------
        ; Checking if end of buffer reached and writing symbol to buffer
        .add_symbol:
        cmp rdi, MaxPointer
        jl .skip_clear_buffer
        call ClearBuffer
        .skip_clear_buffer:
        stosb
        ;-----------------------------------------------------------------------
        jmp .loop_start
        ;-----------------------------------------------------------------------
        ; Writing specifier
        .specifier_handle:
            ;-------------------------------------------------------------------
            ; Reading specifying character
            lodsb
            ;-------------------------------------------------------------------
            ; Going to write if %%
            cmp al, '%'
            je .add_symbol
            ;-------------------------------------------------------------------
            ; Checking that in jump table bounds
            cmp al, 'b'
            jl .specifier_default
            cmp al, 'x'
            ja .specifier_default
            ;-------------------------------------------------------------------
            ; Subtracting to get index
            sub al, 'b'
            ;-------------------------------------------------------------------
            ; Jump table jump to the handler of specifier
            jmp [JmpTableSpecifiers + 8 * rax]
    ;---------------------------------------------------------------------------
    .printf_end:
    ;---------------------------------------------------------------------------
    ; Writing buffer to console
    call ClearBuffer
    ;---------------------------------------------------------------------------
    ; End of printf
    jmp MyPrintf.trampline_back
;===============================================================================
; This is printf section with specifiers switch handlers
;-------------------------------------------------------------------------------
; Default
;-------------------------------------------------------------------------------
    .specifier_default:
        ;-------------------------------------------------------------------
        ; Adding the symbol after % and the % to buffer
        mov ah, al
        add ah, 'b'
        mov al, '%'
        stosw
        ;-------------------------------------------------------------------
        ; Resetting RAX register to zero
        xor rax, rax
        ;-------------------------------------------------------------------
        ; Going to the next symbol in string (start of main printf loop)
        jmp .loop_start

;-------------------------------------------------------------------------------
; Charecter
;-------------------------------------------------------------------------------
    .specifier_character:
        ;-------------------------------------------------------------------
        ; Reading symbol to AL from stack
        mov rax, [rbp]
        add rbp, 8
        ;-------------------------------------------------------------------
        ; Going to adding symbol and checking the size in printf main loop
        jmp .add_symbol

;-------------------------------------------------------------------------------
; Binary number
;-------------------------------------------------------------------------------
    .specifier_binary:
        HandleBinPowerNum 0x1, 1

;-------------------------------------------------------------------------------
; Hexadecimal number
;-------------------------------------------------------------------------------
    .specifier_hexadecimal:
        HandleBinPowerNum 0xf, 4

;-------------------------------------------------------------------------------
; Octal number
;-------------------------------------------------------------------------------
    .specifier_octal:
        HandleBinPowerNum 0x7, 3

;-------------------------------------------------------------------------------
; Decimal number
;-------------------------------------------------------------------------------
    .specifier_decimal:
        ;-------------------------------------------------------------------
        ; Reading number to R9 from stack
        mov r9, [rbp]
        add rbp, 8
        ;-------------------------------------------------------------------
        ; Writing number in decimal form to buffer
        call ToDec
        ;-------------------------------------------------------------------
        ; Going to next symbol in printf main loop
        jmp .loop_start

;-------------------------------------------------------------------------------
; String
;-------------------------------------------------------------------------------
    .specifier_string:
        ;-------------------------------------------------------------------
        ; Reading string address to R9 from stack
        mov r9, [rbp]
        add rbp, 8
        ;-------------------------------------------------------------------
        ; Counting number of bytes in string
        Strlen
        ;-------------------------------------------------------------------
        ; Comparing it with max availeble address
        mov rax, rcx
        add rax, rdi
        cmp rax, MaxPointer
        jl .write_buffer
        ;-------------------------------------------------------------------
        ; Outputting string to console with syscall if we can't put it in
        ; buffer
        ;-------------------------------------------------------------------
            ; Clearing buffer
            call ClearBuffer
            ;---------------------------------------------------------------
            ; Saving RDI and RSI
            push rdi
            push rsi
            ;---------------------------------------------------------------
            ; RAX = write system call
            mov rax, 1
            ;---------------------------------------------------------------
            ; RDI = file stream
            mov rdi, 1
            ;---------------------------------------------------------------
            ; RSI = string pointer
            mov rsi, r9
            ;---------------------------------------------------------------
            ; RDX = number of bytes to print
            mov rdx, rcx
            ;---------------------------------------------------------------
            ; Calling writing of string
            push r11
            syscall
            pop r11
            ;---------------------------------------------------------------
            ; Resetting registers
            pop rsi
            pop rdi
        ;-------------------------------------------------------------------
        ; Going to next symbol in main printf loop
        xor rax, rax
        jmp .loop_start
        .write_buffer:
        ;-------------------------------------------------------------------
        ; Adding string to buffer
        ;-------------------------------------------------------------------
            ; Saving RSI
            push rsi
            ;---------------------------------------------------------------
            ; Copying string address to RSI
            mov rsi, r9
            ;---------------------------------------------------------------
            ; Copying string to printf buffer
            rep movsb
            ;---------------------------------------------------------------
            ; Resetting RSI
            pop rsi
        ;-------------------------------------------------------------------
        ; Going to next symbol in main printf loop
        xor rax, rax
        jmp .loop_start
;===============================================================================

;===============================================================================
; Writes decimal number to a buffer
; Expects:  R9 - number to write
; Returns:  None
;-------------------------------------------------------------------------------
ToDec:
    ;---------------------------------------------------------------------------
    ; Checking if number is negative
    test r9, r9
    ;---------------------------------------------------------------------------
    jns .sign_unset
        ;-----------------------------------------------------------------------
        ; Writing '-' to buffer
        mov al, '-'
        stosb
        ;-----------------------------------------------------------------------
        ; Reversing numbers sign
        not r9
        inc r9
        ;-----------------------------------------------------------------------
    .sign_unset:
    ;---------------------------------------------------------------------------
    ; Saving RSI and RDI in stack
    push rsi
    push rdi
    ;---------------------------------------------------------------------------
    ; End of number buffer in RDI
    lea rdi, [NumberBuffer + NumberBufferLen - 1]
    ;---------------------------------------------------------------------------
    ; DF flag is set to 1 to write backwards
    std
    ;---------------------------------------------------------------------------
    ; Counter in RBX
    xor rbx, rbx
    ;---------------------------------------------------------------------------
    ; Devider in ECX
    mov ecx, 10
    ;---------------------------------------------------------------------------
    .loop_start:
        ;-----------------------------------------------------------------------
        ; Copying lower 32 bits to EAX and higher to EDX to use div
        mov eax, r9d
        mov rdx, r9
        shr rdx, 32
        div ecx
        ;-----------------------------------------------------------------------
        ; Copying quotient to R9
        mov r9, rax
        ;-----------------------------------------------------------------------
        ; Writing digit to buffer. The digit is in RDX after div
        mov al, [Digits + rdx]
        stosb
        ;-----------------------------------------------------------------------
        ; Incrementing counter of written symbols
        inc rbx
        ;-----------------------------------------------------------------------
        ; Checking for zero in R9
        test r9, r9
        ;-----------------------------------------------------------------------
        jnz .loop_start
    ;---------------------------------------------------------------------------
    ; Setting DF flag to write forward with string commands
    cld
    ;---------------------------------------------------------------------------
    ; Address of last written symbol (higher digit) in RSI
    lea rsi, [rdi + 1]
    ;---------------------------------------------------------------------------
    ; Resetting RDI to current buffer position
    pop rdi
    ;---------------------------------------------------------------------------
    ; Counter in RCX
    mov rcx, rbx
    ;---------------------------------------------------------------------------
    ; Checking if clearing buffer needed
    add rbx, rdi
    cmp rbx, MaxPointer
    ;---------------------------------------------------------------------------
    ; Writing buffer to console
    jl .skip_clear_buffer
    call ClearBuffer
    .skip_clear_buffer:
    ;---------------------------------------------------------------------------
    ; Copying number buffer to main printf buffer
    rep movsb
    ;---------------------------------------------------------------------------
    ; Resetting RSI from stack
    pop rsi
    ;---------------------------------------------------------------------------
    ret
;===============================================================================


;===============================================================================
; Writes a power of two system number to a buffer
; Expects:  R9  - number
;           RDI - buffer current position
;           R10 - mask
;           CL - shift
; Returns:  None
;-------------------------------------------------------------------------------
ToBinPow:
    ;---------------------------------------------------------------------------
    ; Saving RSI and RDI in stack
    push rsi
    push rdi
    ;---------------------------------------------------------------------------
    ; End of number buffer in RDI
    lea rdi, [NumberBuffer + NumberBufferLen - 1]
    ;---------------------------------------------------------------------------
    ; Setting DF to 1 to write backwards
    std
    ;---------------------------------------------------------------------------
    ; Counter in RBX
    xor rbx, rbx
    ;---------------------------------------------------------------------------
    .loop_start:
        ;-----------------------------------------------------------------------
        ; Copying number to RAX
        mov rax, r9
        ;-----------------------------------------------------------------------
        ; Applying mask (getting devision reminder)
        and rax, r10
        ;-----------------------------------------------------------------------
        ; Writing digit to number buffer
        mov al, [Digits + rax]
        stosb
        ;-----------------------------------------------------------------------
        ; Deviding by the power of 2 which is located in CL
        shr r9, cl
        ;-----------------------------------------------------------------------
        ; Incrementing counter
        inc rbx
        ;-----------------------------------------------------------------------
        ; Checking R9 for zero
        test r9, r9
        ;-----------------------------------------------------------------------
        jnz .loop_start
    ;---------------------------------------------------------------------------
    ; Setting DF to 0 to write forward with string commands
    cld
    ;---------------------------------------------------------------------------
    ; Address of last written symbol in RSI
    lea rsi, [rdi + 1]
    ;---------------------------------------------------------------------------
    ; Resetting RDI from stack
    pop rdi
    ;---------------------------------------------------------------------------
    ; Number of digits in RCX
    mov rcx, rbx
    ;---------------------------------------------------------------------------
    ; Checking if there is enough place to number in buffer
    add rbx, rdi
    cmp rbx, MaxPointer
    ;---------------------------------------------------------------------------
    ; Writing buffer to console if needed
    jl .skip_clear_buffer
    call ClearBuffer
    .skip_clear_buffer:
    ;---------------------------------------------------------------------------
    ; Copying number buffer to main buffer
    rep movsb
    ;---------------------------------------------------------------------------
    ; Resetting RSI from stack
    pop rsi
    ;---------------------------------------------------------------------------
    ret
;===============================================================================

;===============================================================================
; Clearing buffer
;-------------------------------------------------------------------------------
ClearBuffer:
    ;---------------------------------------------------------------------------
    ; Saving RAX, RSI, RCX and R11 in stack
    push rax
    push rsi
    push rcx
    push r11
    ;---------------------------------------------------------------------------
    ; Length of output in RDX
    mov rdx, rdi
    sub rdx, Buffer
    ;---------------------------------------------------------------------------
    ; write system call in RAX
    mov rax, 1
    ;---------------------------------------------------------------------------
    ; Output file stream in RDI
    mov rdi, 1
    ;---------------------------------------------------------------------------
    ; Buffer start in RSI
    mov rsi, Buffer
    ;---------------------------------------------------------------------------
    ; Writing
    syscall
    ;---------------------------------------------------------------------------
    ; Resetting registers from stack
    pop r11
    pop rcx
    pop rsi
    pop rax
    ;---------------------------------------------------------------------------
    ; New value of RDI is buffer start
    mov rdi, Buffer
    ;---------------------------------------------------------------------------
    ret
;===============================================================================

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
section .rodata
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

;===============================================================================
; Jump table for printf specifiers
;-------------------------------------------------------------------------------
JmpTableSpecifiers:
                dq MyPrintf_cdecl.specifier_binary            ; b
                dq MyPrintf_cdecl.specifier_character         ; c
                dq MyPrintf_cdecl.specifier_decimal           ; d
                dq MyPrintf_cdecl.specifier_default           ; e
                dq MyPrintf_cdecl.specifier_default           ; f
                dq MyPrintf_cdecl.specifier_default           ; g
                dq MyPrintf_cdecl.specifier_default           ; h
                dq MyPrintf_cdecl.specifier_default           ; i
                dq MyPrintf_cdecl.specifier_default           ; j
                dq MyPrintf_cdecl.specifier_default           ; k
                dq MyPrintf_cdecl.specifier_default           ; l
                dq MyPrintf_cdecl.specifier_default           ; m
                dq MyPrintf_cdecl.specifier_default           ; n
                dq MyPrintf_cdecl.specifier_octal             ; o
                dq MyPrintf_cdecl.specifier_default           ; p
                dq MyPrintf_cdecl.specifier_default           ; q
                dq MyPrintf_cdecl.specifier_default           ; r
                dq MyPrintf_cdecl.specifier_string            ; s
                dq MyPrintf_cdecl.specifier_default           ; t
                dq MyPrintf_cdecl.specifier_default           ; u
                dq MyPrintf_cdecl.specifier_default           ; v
                dq MyPrintf_cdecl.specifier_default           ; w
                dq MyPrintf_cdecl.specifier_hexadecimal       ; x
;===============================================================================

;===============================================================================
; Array of digits used in numbers printing
;-------------------------------------------------------------------------------
Digits db "0123456789ABCDEF"
;===============================================================================

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
section .data
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

;===============================================================================
; Printf buffer
;-------------------------------------------------------------------------------
Buffer          db 5 dup(0)
MaxPointer      equ $
;===============================================================================

;===============================================================================
; Buffer to write numbers. Must be at leat 64 bytes long to store bin numbers
;-------------------------------------------------------------------------------
NumberBuffer:   db 64 dup(0)
NumberBufferLen equ $ - NumberBuffer
;===============================================================================

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
section .note.GNU-stack noalloc noexec nowrite progbits
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
