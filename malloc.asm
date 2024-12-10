section .bss
    first_page resq 1

section .text
    global mymalloc
    global myfree


allocate_first_page:
    call allocate_new_page              ; Alloue une nouvelle page (4104 octets)
    test rax, rax                       ; Vérifie que l'allocation a réussi
    jz allocation_failed                ; Gère une erreur éventuelle (par exemple avec une exception)
    mov [rel first_page], rax           ; Enregistre l'adresse de la première page dans first_page
    jmp mymalloc
    
allocation_failed:
    ret

mymalloc:                               ; rdi handle size of data
    add rdi, 15                         ; Align the requested size to 16 bytes
    and rdi, byte 0xFFFFFFF0
    mov rax, [rel first_page]           ; Load first_page with RIP-relative addressing
    test rax, rax
    jz allocate_first_page
    

_malloc:
    mov rsi, rdi
    mov rdi, rax                        ; rdi has the page beginning pointer
    call find_new_free_block            ; Call function with RIP-relative addressing
    test rax, rax
    je _malloc_move_next_page           ; If no new free block is available in the page
    mov rdi, rax
    call create_new_block               ; Call function with RIP-relative addressing
    ret

_malloc_move_next_page:
    cmp [rdi], byte 0
    je _new_page
    mov rdi, [rdi]
    jmp _malloc

_new_page:
    mov r8, rdi                         ; r8 contains pointer to the metadata of the previous page
    push r8
    call allocate_new_page              ; Call the function
    pop r8
    mov [r8], rax
    jmp _malloc

myfree:    
    push rsi
    push r9                             ; rdi is the pointer to free
    test rdi, rdi                       ; Check if the pointer is NULL
    je _invalid_pointer
    mov rax, [rel first_page]           ; Load the address of the first page using RIP-relative
    test rax, rax                       ; Ensure the first page exists
    je _invalid_pointer


_free_check_if_pointer_is_good:
    mov rsi, rax
    add rsi, 8                          ; Start of the first block (skip page metadata)
    cmp rdi, rsi
    jl _free_move_to_next_page          ; Pointer is before this page
    lea rsi, [rsi + 4096 - 8]           ; End of the page
    cmp rdi, rsi
    jge _free_move_to_next_page         ; Pointer is after this page
  

    mov rsi, rdi
    sub rsi, byte 8                     ; Move to block metadata
    cmp byte [rsi], 1                   ; Check if already free
    je _invalid_pointer
    mov byte [rsi], 1                   ; Mark block as free

    mov rdi, rax                        ; rdi points to the current page
    call merge_blocks_in_page           ; Call function with RIP-relative addressing

    call _release_empty_page            ; Call function with RIP-relative addressing

    pop r9
    pop rsi
    ret

_free_move_to_next_page:
    mov rax, [rax]                      ; Move to the next page
    test rax, rax                       ; Check if end of the page list
    je _invalid_pointer                 ; Invalid pointer if no match found
    jmp _free_check_if_pointer_is_good

_invalid_pointer:
    pop r9
    pop rsi
    ret

_release_empty_page:
    push r9
    mov r9, rdi
    add r9, 8                           ; Start of the first block
    cmp [r9], byte 4096                 ; Check if the block spans the entire page (4096 - 8)
    jne _end_release_page
    add r9, 8                           ; Check the "is_free" flag
    cmp byte [r9], 1
    jne _end_release_page

    cmp rdi, [rel first_page]           ; Check if this is the first page
    je _change_first_page

    mov r9, [rel first_page]
_find_previous_page:
    cmp [r9], rdi                       ; Check if the next page is the current page
    je _change_page
    mov r9, [r9]
    jmp _find_previous_page

_change_page:
    push rsi
    mov rsi, [rdi]                      ; Get the next page pointer
    mov [r9], rsi                       ; Update the previous page to skip the current one
    pop rsi
    jmp _release_page

_change_first_page:
    mov r9, [rdi]                       ; Update the first page pointer
    push rsi
    mov rsi, [rel first_page]
    mov [rsi], r9

_release_page:
    mov rax, 11                         ; munmap syscall
    mov rdi, rdi                        ; Address of the page to release
    mov rsi, 4104                       ; Size of the page (metadata + page)
    syscall

_end_release_page:
    pop r9
    ret

allocate_new_page:                      ; always allocate 4096 bytes + pointer to next page (8 oct)
    push rdi
    mov rax, 9
    mov rdi, 0
    mov rsi, 4104                       ; size of page
    mov rdx, 3                          ; PROT_READ | PROT_WRITE
    mov r10, 0x22
    mov r8, -1
    xor r9, r9
    syscall
    mov [rax], byte 0
    mov rdi, rax                        ; put block metadata
    add rdi, byte 8
    mov qword [rdi], 4096               ; size = 4096
    add rdi, byte 8
    mov [rdi], byte 1                   ;is_free = 1
    pop rdi
    ret

find_new_free_block:                    ; rdi: pointer to current page, rsi: size of requested block
    add rdi, byte 8                     ; skip page metadata
    push rdi
    push rsi
    push r8
    push r9
    push r11
    lea r8, [rdi + 4096]                ; End of the page (page size: 4096 bytes)
    
_find_new_free_block:
    cmp r8, rdi                         ; Check if reached end of page
    je _not_found_new_free_block
    mov r9, [rdi]                       ; Load size of the current block
    test r9, r9                         ; Validate block size (avoid infinite loop)
    jz _not_found_new_free_block
    mov r11, r9
    sub r11, byte 16                    ; remove 16 bytes of
    cmp rsi, r11                        ; Compare requested size to block size
    jg _continue_search                 ; Continue if block is too small
    mov r11, rdi
    add r11, byte 8                     ; Move to "is_free" field
    cmp byte [r11], 0                   ; Check if the block is free
    je _continue_search                 ; Continue if not free

    mov rax, rdi                        ; Found a free block, return its address
    jmp _found_new_free_block

_continue_search:
    add rdi, r9                         ; Move to the next block
    add rdi, byte 16                    ; add metadata of the block
    jmp _find_new_free_block

_not_found_new_free_block:
    mov rax, 0                          ; No free block found, return 0
    pop r11
    pop r9
    pop r8
    pop rsi
    pop rdi
    ret

_found_new_free_block:
                                        ; Do not align again, assume rdi was aligned correctly
    pop r11
    pop r9
    pop r8
    pop rsi
    pop rdi
    ret


create_new_block:                       ; rdi: pointer to the free block, rsi: requested block size
    push rdi
    push rsi
    push r8
    mov r8, [rdi]                       ; Load the size in r8 of the current free block
    cmp r8, rsi
    jb _error_block_too_small           ; If the free block is too small, return an error
    mov [rdi], rsi                      ; Set the size of the allocated block
    add rdi, byte 8                     ; Move to the "is_free" field
    mov [rdi], byte 0                   ; Mark the block as allocated
    sub rdi, byte 8                     ; Go back to the start of the block

                                        ; Calculate remaining free space
    sub r8, rsi
    sub r8, byte 16
    cmp r8, byte 0                      ; Check if there’s enough space for a new free block
    jl _no_space_for_new_block

                                        ; Create metadata for the new free block
    add rdi, rsi
    add rdi, byte 16                    ; Move to the end of the allocated block
    mov [rdi], r8
    mov r8, rdi
    add r8, byte 8
    mov [r8], byte 1                    ; Mark the new block as free
    jmp _end_create_new_block

_no_space_for_new_block:
    add rdi, rsi                        ; Skip the current block

_end_create_new_block:
    sub rdi, rsi                        ; Go back to the allocated block’s metadata
    mov rax, rdi
    pop r8
    pop rsi
    pop rdi
    ret

_error_block_too_small:
    mov rax, 0                          ; Return 0 to indicate an error
    pop r8
    pop rsi
    pop rdi
    ret

merge_blocks_in_page:                   ; rdi is the page of the free
    push rdi
    add rdi, byte 8                     ; Skip metadata
    push rsi
    push r9
    push r10
    mov r10, rdi
    add r10, qword 4096                 ; End of the page

_merge_blocks_in_page:
    mov r9, rdi                         ; r9 is the last free block
    add r9, byte 8                      ; Move to the "is_free" field
    cmp [r9], byte 0                    ; Check if it’s free
    je _move_to_next_block
    mov rdi, r9
    add rdi, [rdi]
    cmp rdi, r10
    jge _merge_end
    mov rsi, rdi                        ; rsi is the current free block
    add rsi, byte 8                     ; Move to the "is_free" field
    cmp [rsi], byte 0                   ; Check if the next block is free
    je _move_to_next_block
    sub rsi, 8                          ; Go back to the size field
    mov rsi, [rsi]                      ; Get the size of the next block
    sub r9, 8                           ; Go to the size field of the previous block
    add [r9], rsi                       ; Merge the blocks
    add [r9], byte 16                   ; Add space for the metadata

_move_to_next_block:
    add rdi, [rdi]
    add rdi, byte 16                    ; add metadata
    cmp rdi, r10
    jge _merge_end
    jmp _merge_blocks_in_page

_merge_end:
    pop r10
    pop r9
    pop rsi
    pop rdi
    ret
