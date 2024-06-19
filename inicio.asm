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
extern sscanf

section .data
    tablero     db  -1, -1,  1,  1,  1, -1, -1
                db  -1, -1,  1,  1,  1, -1, -1
                db   1,  1,  1,  1,  1,  1,  1
                db   1,  2,  2,  2,  2,  2,  1
                db   1,  2,  2,  3,  2,  2,  1
                db  -1, -1,  2,  2,  2, -1, -1
                db  -1, -1,  2,  2,  2, -1, -1

    salto_linea         db 10, 0        
    simbolo_fuera       db ".", 0
    simbolo_oca         db 'O', 0
    simbolo_zorro       db 'X', 0
    simbolo_vacio       db ' ', 0
    simbolo_separador   db '|', 0
    longfila            db 7

    mensaje_mover_oca                   db "Ingrese la fila y columna de la oca a mover (ejemplo: 3 3): ", 0
    mensaje_mover_oca_direccion         db "Mueva la oca con w: arriba /a: izquierda /s: abajo /d: derecha ", 0
    mensaje_movimiento_invalido_oca     db "Movimiento invalido para la oca, intente nuevamente", 0
    formatInputFilCol                   db "%hhu %hhu", 0                               ; Formato para leer enteros de 1 byte
    msjErrorInput                       db "Los datos ingresados son inválidos. Intente nuevamente.", 0
    mensaje_mover_zorro                 db "Mueva el zorro con w: arriba /a: izquierda /s: abajo /d: derecha /e: arriba-derecha /q: arriba-izquierda /z: abajo-izquierda /x: abajo-derecha ", 0
    mensaje_mov_invalido                db "Movimiento invalido, intente nuevamente", 0
    mensaje_ingresar_j1                 db "Ingrese el nombre del jugador 1 (zorro): ", 0
    mensaje_ingresar_j2                 db "Ingrese el nombre del jugador 2 (ocas): ", 0
    mensaje_ganador                     db "El ganador es: ", 0
    
section .bss
    buffer          resb 350  ; Suficiente espacio para el tablero con saltos de línea
    input_oca       resb 10
    fila            resb 1
    columna         resb 1
    inputValido     resb 1
    posicion_oca    resq 1
    input_zorro     resb 10
    nombre_j1       resb 50
    nombre_j2       resb 50
    turno           resb 1

section .text
main:
    sub     rsp,8
    call    ingresar_nombres        ;llamo a la subrutina para ingresar nombres
    add     rsp,8
    sub     rsp,8
    call    construir_tablero
    add     rsp,8
    sub     rsp,8
    call    imprimir_tablero
    add     rsp,8

loop_juego:
    mov     al, [turno]     ; veo de quien es el turno
    cmp     al, 1
    je turno_zorro
    cmp     al, 2
    je turno_ocas

turno_zorro:
    sub     rsp,8
    call pedir_movimiento_zorro     
    add     rsp,8
    sub     rsp,8
    call mover_zorro
    add     rsp,8
    cmp     byte [inputValido], 'R'     
    je turno_zorro
    mov     byte [turno], 2
    jmp continuar_juego

turno_ocas:
    sub     rsp,8
    call pedir_movimiento_oca
    add     rsp,8
    sub     rsp,8
    call mover_oca
    add     rsp,8
    cmp byte [inputValido], 'R'
    je turno_ocas
    mov byte [turno], 1

continuar_juego:
    sub     rsp,8
    call construir_tablero
    add     rsp,8
    sub     rsp,8
    call imprimir_tablero
    add     rsp,8
    jmp loop_juego

    ret

ingresar_nombres:
    mov     rdi, mensaje_ingresar_j1   
    mPuts
    mov     rdi, nombre_j1              ; guardo el nombre de cada jugador
    mGets
    mov rdi, mensaje_ingresar_j2
    mPuts
    mov rdi, nombre_j2
    mGets

    mov byte [turno], 1  ; Comienza el turno del zorro
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
    add rax, rdx       ; (i-1) * longfila + (j-1)
    mov rsi, tablero
    add rsi, rax       ; rsi apunta a la posición actual en el tablero

    cmp byte [rsi], -1      ;segun el numero en tablero imprimo un caracter distinto
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
    mov rbx, rsi   ; Mueve el valor del registro rsi (posición actual del zorro) a rbx
    dec rbx         ; Decrementa rbx en 1 para apuntar correctamente a la posición actual del zorro

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
    sub rbx, 7                  ; resto 7 a rbx para mover al zorro una fila hacia arriba
    jmp validar_movimiento_zorro 

mover_abajo:
    add rbx, 7                  ; sumo 7 a rbx para mover al zorro una fila hacia abajo
    jmp validar_movimiento_zorro

mover_izquierda:
    dec rbx                     ; resto 1 a rbx para mover al zorro una columna a la izquierda
    jmp validar_movimiento_zorro

mover_derecha:
    inc rbx                     ; sumo 1 a rbx para mover al zorro una columna a la derecha
    jmp validar_movimiento_zorro

mover_arriba_derecha:
    sub rbx, 6                  ; resto 6 a rbx para mover al zorro en diagonal arriba derecha
    jmp validar_movimiento_zorro

mover_arriba_izquierda:
    sub rbx, 8                  ; resto 8 a rbx para mover al zorro en diagonal arriba izquierda
    jmp validar_movimiento_zorro

mover_abajo_izquierda:
    add rbx, 6                  ; sumo 6 a rbx para mover al zorro en diagonal abajo izquierda
    jmp validar_movimiento_zorro

mover_abajo_derecha:
    add rbx, 8                   ; sumo 8 a rbx para mover al zorro en diagonal abajo derecha
    jmp validar_movimiento_zorro

validar_movimiento_zorro:
    cmp byte [rbx], 2           ; Comparar destino con una posición vacía (2)
    jne movimiento_invalido_zorro         
    mov byte [rsi - 1], 2       ; Actualizar la posición anterior del zorro con 2 (vacío)
    mov byte [rbx], 3           ; Colocar al zorro en la nueva posición
    mov byte [inputValido], 'S' ; Indicar que el movimiento fue válido
    ret

movimiento_invalido_zorro:
    mov byte [inputValido], 'R'
    mov rdi, mensaje_mov_invalido
    mPuts
    ret

pedir_movimiento_oca:
    mov rdi, mensaje_mover_oca
    mPuts
    mov rdi, input_oca
    mGets

    ; Validar las coordenadas de la oca
    sub     rsp,8
    call validar_coordenadas_oca
    add     rsp,8
    cmp byte [inputValido], 'S'
    je pedir_direccion_oca

    mov rdi, msjErrorInput
    mPuts
    sub     rsp,8
    call pedir_movimiento_oca
    add     rsp,8
    ret

pedir_direccion_oca:
    mov rdi, mensaje_mover_oca_direccion
    mPuts
    mov rdi, input_oca
    mGets

    ret

mover_oca:
    mov rsi, tablero
    ; Calcular la posición en el tablero
    mov rbx, [posicion_oca]

    ; Leer la dirección de movimiento
    mov rdi, input_oca
    mov al, [rdi]
    cmp al, 'w'
    je mover_oca_arriba
    cmp al, 's'
    je mover_oca_abajo
    cmp al, 'a'
    je mover_oca_izquierda
    cmp al, 'd'
    je mover_oca_derecha
    ret

mover_oca_arriba:
    sub rbx, 7
    jmp validar_movimiento_oca

mover_oca_abajo:
    add rbx, 7
    jmp validar_movimiento_oca

mover_oca_izquierda:
    dec rbx
    jmp validar_movimiento_oca

mover_oca_derecha:
    inc rbx
    jmp validar_movimiento_oca

validar_movimiento_oca:
    cmp byte [rbx], 2
    jne movimiento_invalido_oca
    mov rsi, [posicion_oca]
    mov byte [rsi], 2          ; Actualizar la posición anterior de la oca con 2 (vacío)
    mov byte [rbx], 1          ; Colocar la oca en la nueva posición
    mov byte [inputValido], 'S' ; Indicar que el movimiento fue válido
    ret

movimiento_invalido_oca:
    mov byte [inputValido], 'R'
    mov rdi, mensaje_movimiento_invalido_oca
    mPuts
    ret

validar_coordenadas_oca:
    mov byte [inputValido], 'N'
    mov rdi, input_oca
    mov rsi, formatInputFilCol
    mov rdx, fila
    mov rcx, columna
    sub rsp,8
    call sscanf
    add rsp,8

    cmp rax, 2
    jl coordenadas_invalidas

    cmp byte [fila], 1
    jl coordenadas_invalidas
    cmp byte [fila], 7
    jg coordenadas_invalidas

    cmp byte [columna], 1
    jl coordenadas_invalidas
    cmp byte [columna], 7
    jg coordenadas_invalidas

    ; Calcular la posición en el tablero
    movzx ax, byte [fila]
    sub ax, 1
    imul ax, 7
    movzx dx, byte [columna]
    sub dx, 1
    add ax, dx
    mov rbx, rax
    add rbx, tablero

    ; Verificar si hay una oca en la posición ingresada
    cmp byte [rbx], 1
    jne coordenadas_invalidas

    mov byte [inputValido], 'S'
    mov [posicion_oca], rbx    ; Guardar la posición de la oca
    ret

coordenadas_invalidas:
    mov rdi, msjErrorInput
    mPuts
    ret