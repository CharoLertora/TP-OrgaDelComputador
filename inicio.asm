global main

%macro mPuts 0
    sub     rsp,8
    call    puts
    add     rsp,8
%endmacro

%macro mGets 0
    sub     rsp,8
    call    gets
    add     rsp,8
%endmacro

extern puts
extern gets

section .data
    tablero     db  -1, -1,  1,  1,  1, -1, -1
                db  -1, -1,  1,  1,  1, -1, -1
                db   1,  1,  1,  1,  1,  1,  1
                db   1,  2,  2,  2,  2,  2,  1
                db   1,  2,  2,  3,  2,  2,  1
                db  -1, -1,  2,  2,  2, -1, -1
                db  -1, -1,  2,  2,  2, -1, -1

    mensaje_tablero  db "Estado actual del tablero:", 10, 0
    salto_linea      db 10, 0        
    simbolo_fuera    db ".", 0
    simbolo_oca      db 'O', 0
    simbolo_zorro    db 'X', 0
    simbolo_vacio    db ' ', 0
    simbolo_separador db '|'.0
    longfila         db 7

    mensaje_mover_zorro db "Mueva el zorro con w: arriba /a: izquierda /s: abajo /d: derecha /e: arriba-derecha /q: arriba-izquierda /z: abajo-izquierda /x: abajo-derecha ", 0
    mensaje_mov_invalido db "Movimiento invalido, intente nuevamente"

section .bss
    buffer resb 350  ; Suficiente espacio para el tablero con saltos de línea
    input_zorro resb 10

section .text
main:
    mov rdi, mensaje_tablero
    mPuts
    call construir_tablero
    call imprimir_tablero
    
loop_juego:
    call pedir_movimiento_zorro
    call mover_zorro
    call construir_tablero
    call imprimir_tablero
    jmp loop_juego

    ret

construir_tablero:
    mov rbx, 1  ; i que será la fila, iniciada en 1 y no aumenta hasta no terminar las 7 columnas
    mov r10, 1  ; j que será la columna
    mov rdi, buffer  ; Apuntar al inicio del buffer

imprimir_siguiente:   
    mov rax, rbx
    dec rax
    imul rax, rax, 7   ; (i-1) * longfila
    mov rdx, r10
    dec rdx
    add rax, rdx       ; (i-1) * longfila + (j-1) ya que la long del elemento es de 1 no hace falta multiplicarlo
    mov rsi, tablero
    add rsi, rax       ; rsi apunta a la posición actual en el tablero

    cmp byte [rsi], -1           
    je  imprimir_fuera                
    cmp byte [rsi], 2           
    je  imprimir_vacio              
    cmp byte [rsi], 1         
    je  imprimir_oca
    cmp byte [rsi], 3
    je  imprimir_zorro

imprimir_fuera:
    mov al, [simbolo_separador]
    stosb
    mov al, [simbolo_fuera]
    stosb
    mov al, [simbolo_separador]
    stosb
    jmp continuar_construyendo

imprimir_oca:
    mov al, [simbolo_separador]
    stosb
    mov al, [simbolo_oca]
    stosb
    mov al, [simbolo_separador]
    stosb
    jmp continuar_construyendo

imprimir_zorro:
    mov al, [simbolo_separador]
    stosb
    mov al, [simbolo_zorro]
    stosb
    mov al, [simbolo_separador]
    stosb
    jmp continuar_construyendo

imprimir_vacio:
    mov al, [simbolo_separador]
    stosb
    mov al, [simbolo_vacio]
    stosb
    mov al, [simbolo_separador]
    stosb
    jmp continuar_construyendo

continuar_construyendo:
    inc r10 ; Incrementar en uno para tener la siguiente columna
    cmp r10, 8    ; Si no llegué a la columna 7, construyo el siguiente elemento de la misma fila              
    jl imprimir_siguiente       

    ; Añadir un salto de línea al final de la fila
    mov al, [salto_linea]
    stosb
    mov r10, 1
    inc rbx     ; Incremento en uno la fila (siguiente fila)
    cmp rbx, 8  ; Si llegué a la fila 7, termino la construcción
    je fin_construir

    jmp imprimir_siguiente

fin_construir:
    ret

imprimir_tablero:
    mov rdi, buffer
    mPuts
    ret
    
pedir_movimiento_zorro:
    mov rdi, mensaje_mover_zorro
    mPuts
    mov rdi, input_zorro
    mGets
    ret

mover_zorro:
    mov rsi, tablero
    mov rcx, 49

buscar_zorro:
    lodsb
    cmp al, 3
    je encontrado_zorro
    loop buscar_zorro
    ret

encontrado_zorro:
    mov rbx, rsi
    dec rbx

    mov rdi, input_zorro
    mov al, [rdi]
    cmp al, 'w'
    je mover_arriba
    cmp al, 's'
    je mover_abajo
    cmp al, 'a'
    je mover_izquierda
    cmp al, 'd'
    je mover_derecha
    cmp al, 'e'
    je mover_arriba_derecha
    cmp al, 'q'
    je mover_arriba_izquierda
    cmp al, 'z'
    je mover_abajo_izquierda
    cmp al, 'x'
    je mover_abajo_derecha
    ret

mover_arriba:
    sub rbx, 7
    jmp validar_movimiento_zorro

mover_abajo:
    add rbx, 7
    jmp validar_movimiento_zorro

mover_izquierda:
    dec rbx
    jmp validar_movimiento_zorro

mover_derecha:
    inc rbx
    jmp validar_movimiento_zorro

mover_arriba_derecha:
    sub rbx, 6
    jmp validar_movimiento_zorro

mover_arriba_izquierda:
    sub rbx, 8
    jmp validar_movimiento_zorro

mover_abajo_izquierda:
    add rbx, 6
    jmp validar_movimiento_zorro

mover_abajo_derecha:
    add rbx, 8
    jmp validar_movimiento_zorro

validar_movimiento_zorro:
    cmp byte [rbx], 2
    jne movimiento_invalido
    mov byte [rsi - 1], 2
    mov byte [rbx], 3
    ret

movimiento_invalido:
    mov rdi, mensaje_mov_invalido
    mPuts
    ret
