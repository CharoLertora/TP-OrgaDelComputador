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

%macro mPrintF 0
    sub     rsp,8
    call    printf
    add     rsp,8
%endmacro

extern puts
extern gets
extern sscanf
extern printf

section .data
    tablero     db  -1, -1,  1,  1,  1, -1, -1
                db  -1, -1,  1,  1,  1, -1, -1
                db   1,  1,  1,  1,  1,  1,  1
                db   1,  2,  2,  2,  2,  2,  1
                db   1,  2,  2,  3,  1,  2,  1
                db  -1, -1,  2,  2,  2, -1, -1
                db  -1, -1,  2,  2,  2, -1, -1

    salto_linea                 db 10, 0        
    simbolo_fuera_tablero       db ".", 0
    simbolo_oca                 db 'O', 0    ; symbolo por default para ocas
    simbolo_zorro               db 'X', 0    ; symbolo por default para el zorro
    simbolo_espacio_vacio       db ' ', 0
    simbolo_separador           db '|', 0
    mensaje_mover_oca           db "Ingrese la fila y columna de la oca a mover (ejemplo: 3 3). Presione f para salir de la partida: ", 0
    mensaje_mover_oca_direccion db "Mueva la oca con w: arriba /a: izquierda /s: abajo /d: derecha. Presione f para salir de la partida: ", 0
    formatInputFilCol           db "%hhu %hhu", 0                               ; Formato para leer enteros de 1 byte
    msjErrorInput               db "Los datos ingresados son inválidos. Intente nuevamente.", 0
    mensaje_mover_zorro         db "Mueva el zorro con w: arriba /a: izquierda /s: abajo /d: derecha /e: arriba-derecha /q: arriba-izquierda /z: abajo-izquierda /x: abajo-derecha. Presione f para salir de la partida: ", 0
    mensaje_mov_invalido        db "Movimiento invalido, intente nuevamente", 0
    mensaje_ingresar_j1         db "Ingrese el nombre del jugador 1 (zorro): ", 0
    mensaje_ingresar_j2         db "Ingrese el nombre del jugador 2 (ocas): ", 0
    mensaje_ingresar_simbolo_zorro db "Ingrese el simbolo para el zorro (presione Enter para usar 'X'): ", 0
    mensaje_ingresar_simbolo_oca db "Ingrese el simbolo para las ocas (presione Enter para usar 'O'): ", 0
    mensaje_ganador             db "El ganador es: %s ", 0
    mensaje_fin_juego           db "El juego ha sido abandonado.", 0
    mensaje_ocas_eliminadas     db "Ocas eliminadas: %lli", 0
    cantidad_ocas_eliminadas    dq 0

section .bss
    buffer          resb 350  ; Suficiente espacio para el tablero con saltos de línea
    input_oca       resb 10
    fila            resb 1
    columna         resb 1
    inputValido     resb 1
    posicion_oca    resq 1
    input_zorro     resb 10
    nombre_jugador1 resb 50
    nombre_jugador2 resb 50
    turno           resb 1
    comio_oca       resb 1

section .text
main:
    sub     rsp,8
    call    ingresar_nombres_y_simbolos_jugadores  ;llamo a la subrutina para ingresar nombres y simbolos
    add     rsp,8
    sub     rsp,8
    call    construir_tablero       ;llamo a la subrutina para construir el tablero inicial
    add     rsp,8
    sub     rsp,8
    call    imprimir_tablero        ;llamo a la subrutina para imprimir el tablero
    add     rsp,8

loop_juego:
    mov     al, [turno]     ; veo de quien es el turno
    cmp     al, 1
    je turno_zorro          ; si es el turno del zorro, voy a la etiqueta turno_zorro
    cmp     al, 2
    je turno_ocas           ; si es el turno de las ocas, voy a la etiqueta turno_ocas

turno_zorro:
    sub     rsp,8
    call    pedir_movimiento_zorro  ;llamo a la subrutina para pedir movimiento del zorro
    add     rsp,8
    cmp     byte [input_zorro], 'f' ; Verificar si se desea abandonar la partida
    je      fin_juego
    sub     rsp,8
    call    mover_zorro              ;llamo a la subrutina para mover al zorro
    add     rsp,8
    cmp     byte [inputValido], 'R'  ;comparo si el movimiento del zorro fue inválido
    je      turno_zorro              ;si fue inválido, vuelvo a pedir movimiento del zorro
    cmp     byte [comio_oca], 1      ; Si comió una oca, no cambiar de turno
    je      continuar_juego
    mov     byte [turno], 2          ;si fue válido y no comió oca, cambio el turno a las ocas
    jmp     continuar_juego          ;voy a la etiqueta continuar_juego

turno_ocas:
    sub     rsp,8
    call    pedir_movimiento_oca     ;llamo a la subrutina para pedir movimiento de la oca
    add     rsp,8
    cmp     byte [input_oca], 'f'    ; Verificar si se desea abandonar la partida
    je      fin_juego
    sub     rsp,8
    call    mover_oca                ;llamo a la subrutina para mover la oca
    add     rsp,8
    cmp     byte [inputValido], 'R'  ;comparo si el movimiento de la oca fue inválido
    je      turno_ocas               ;si fue inválido, vuelvo a pedir movimiento de la oca
    mov     byte [turno], 1          ;si fue válido, cambio el turno al zorro

continuar_juego:
    sub     rsp,8
    call    construir_tablero       ;reconstruyo el tablero después de cada turno
    add     rsp,8
    sub     rsp,8
    call    imprimir_tablero        ;imprimo el tablero después de cada turno
    add     rsp,8
    jmp     loop_juego              ;vuelvo al inicio del bucle del juego

    ret

ingresar_nombres_y_simbolos_jugadores:
    mov     rdi, mensaje_ingresar_j1   
    mPuts
    mov     rdi, nombre_jugador1              ; guardo el nombre de cada jugador
    mGets
    mov     rdi, mensaje_ingresar_j2
    mPuts
    mov     rdi, nombre_jugador2
    mGets
    mov     rdi, mensaje_ingresar_simbolo_zorro
    mPuts
    mov     rdi, simbolo_zorro
    mov     rsi, simbolo_zorro
    mGets
    cmp     byte [simbolo_zorro], 0   ; verifico si se presiono enter
    jne     skip_default_zorro        ; si no es enter, se utiliza el del usuario que se guardo en simbolo_zorro
    mov     byte [simbolo_zorro], 'X' ; se asigna el símbolo por defecto para el zorro, pisando en caso de enter
skip_default_zorro:
    mov     rdi, mensaje_ingresar_simbolo_oca
    mPuts
    mov     rdi, simbolo_oca
    mov     rsi, simbolo_oca
    mGets
    cmp     byte [simbolo_oca], 0     ; verifico si se presiono enter
    jne     skip_default_oca          ; si no es enter, se utiliza el del usuario que se guardo en simbolo_oca
    mov     byte [simbolo_oca], 'O'   ; se asigna el símbolo por defecto para las ocas, pisando en caso de enter

skip_default_oca:
    mov byte [turno], 1  ; Comienza el turno del zorro
    ret

construir_tablero:
    mov     rbx, 1            ; i que será la fila, iniciada en 1 y no aumenta hasta no terminar las 7 columnas
    mov     r10, 1            ; j que será la columna
    mov     rdi, buffer       ; Apuntar al inicio del buffer

imprimir_siguiente_caracter:   
    mov     rax, rbx
    dec     rax
    imul    rax, rax, 7       ; (i-1) * longfila
    mov     rdx, r10
    dec     rdx
    add     rax, rdx          ; (i-1) * longfila + (j-1)
    mov     rsi, tablero
    add     rsi, rax          ; rsi apunta a la posición actual en el tablero

    cmp     byte [rsi], -1      ;segun el numero en tablero imprimo un caracter distinto
    je      imprimir_fuera_tablero                
    cmp     byte [rsi], 2           
    je      imprimir_espacio_vacio              
    cmp     byte [rsi], 1         
    je      imprimir_oca
    cmp     byte [rsi], 3
    je      imprimir_zorro

imprimir_fuera_tablero:
    mov     al, [simbolo_separador]
    stosb
    mov     al, [simbolo_fuera_tablero]
    stosb
    mov     al, [simbolo_separador]
    stosb
    jmp     continuar_construyendo_tablero

imprimir_oca:
    mov     al, [simbolo_separador]
    stosb
    mov     al, [simbolo_oca]
    stosb
    mov     al, [simbolo_separador]
    stosb
    jmp     continuar_construyendo_tablero

imprimir_zorro:
    mov     al, [simbolo_separador]
    stosb
    mov     al, [simbolo_zorro]
    stosb
    mov     al, [simbolo_separador]
    stosb
    jmp     continuar_construyendo_tablero

imprimir_espacio_vacio:
    mov     al, [simbolo_separador]
    stosb
    mov     al, [simbolo_espacio_vacio]
    stosb
    mov     al, [simbolo_separador]
    stosb
    jmp     continuar_construyendo_tablero

continuar_construyendo_tablero:
    inc     r10                ; Incrementar en uno para tener la siguiente columna
    cmp     r10, 8             ; Si no llegué a la columna 7, construyo el siguiente elemento de la misma fila              
    jl      imprimir_siguiente_caracter       

    ; Añadir un salto de línea al final de la fila
    mov     al, [salto_linea]
    stosb
    mov     r10, 1
    inc     rbx                ; Incremento en uno la fila (siguiente fila)
    cmp     rbx, 8             ; Si llegué a la fila 7, termino la construcción
    je      fin_construir_tablero

    jmp     imprimir_siguiente_caracter

fin_construir_tablero:
    ret

imprimir_tablero:
    mov     rdi, buffer
    mPuts
    mov rdi, mensaje_ocas_eliminadas
    mov rsi, [cantidad_ocas_eliminadas]
    mPrintF
    mov rdi, salto_linea
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
    je zorro_encontrado
    loop buscar_zorro
    ret

zorro_encontrado:
    mov rbx, rsi   ; Mueve el valor del registro rsi (posición actual del zorro) a rbx
    dec rbx         ; Decrementa rbx en 1 para apuntar correctamente a la posición actual del zorro

    mov rdi, input_zorro
    mov al, [rdi]
    cmp al, 'w'
    je mover_zorro_arriba
    cmp al, 's'
    je mover_zorro_abajo
    cmp al, 'a'
    je mover_zorro_izquierda
    cmp al, 'd'
    je mover_zorro_derecha
    cmp al, 'e'
    je mover_zorro_arriba_derecha
    cmp al, 'q'
    je mover_zorro_arriba_izquierda
    cmp al, 'z'
    je mover_zorro_abajo_izquierda
    cmp al, 'x'
    je mover_zorro_abajo_derecha
    mov rdi, msjErrorInput
    mPuts
    jmp turno_zorro
    ret

mover_zorro_arriba:
    sub rbx, 7                  ; resto 7 a rbx para mover al zorro una fila hacia arriba
    mov rdi, -7                 ; la dirección del desplazamiento es -7
    jmp validar_movimiento_zorro 

mover_zorro_abajo:
    add rbx, 7                  ; sumo 7 a rbx para mover al zorro una fila hacia abajo
    mov rdi, 7                  ; la dirección del desplazamiento es 7
    jmp validar_movimiento_zorro

mover_zorro_izquierda:
    dec rbx                     ; resto 1 a rbx para mover al zorro una columna a la izquierda
    mov rdi, -1                 ; la dirección del desplazamiento es -1
    jmp validar_movimiento_zorro

mover_zorro_derecha:
    inc rbx                     ; sumo 1 a rbx para mover al zorro una columna a la derecha
    mov rdi, 1                  ; la dirección del desplazamiento es 1
    jmp validar_movimiento_zorro

mover_zorro_arriba_derecha:
    sub rbx, 6                  ; resto 6 a rbx para mover al zorro en diagonal arriba derecha
    mov rdi, -6                 ; la dirección del desplazamiento es -6
    jmp validar_movimiento_zorro

mover_zorro_arriba_izquierda:
    sub rbx, 8                  ; resto 8 a rbx para mover al zorro en diagonal arriba izquierda
    mov rdi, -8                 ; la dirección del desplazamiento es -8
    jmp validar_movimiento_zorro

mover_zorro_abajo_izquierda:
    add rbx, 6                  ; sumo 6 a rbx para mover al zorro en diagonal abajo izquierda
    mov rdi, 6                  ; la dirección del desplazamiento es 6
    jmp validar_movimiento_zorro

mover_zorro_abajo_derecha:
    add rbx, 8                  ; sumo 8 a rbx para mover al zorro en diagonal abajo derecha
    mov rdi, 8                  ; la dirección del desplazamiento es 8
    jmp validar_movimiento_zorro

validar_movimiento_zorro:
    cmp byte [rbx], 2           ; Comparar destino con una posición vacía (2)
    jne verificar_si_oca       ; Si no está vacía, verificar si se puede comer una oca
    mov byte [rsi - 1], 2       ; Actualizar la posición anterior del zorro con 2 (vacío)
    mov byte [rbx], 3           ; Colocar al zorro en la nueva posición
    mov byte [comio_oca], 0     ; Indicar que no comió oca
    mov byte [inputValido], 'S' ; Indicar que el movimiento fue válido
    ret

verificar_si_oca:
    cmp byte [rbx], 1           ; Comparar destino con una oca (1)
    jne movimiento_invalido_zorro ; Si no es una oca, el movimiento es inválido
    jmp validar_comer_oca       ; Ir a validar si se puede comer la oca

validar_comer_oca:
    ; Verificar si hay una oca en la posición intermedia
    ; RDI contiene la dirección del desplazamiento en mover_zorro_*
    mov rax, rbx
    add rax, rdi
    cmp byte [rax], 2           ; Verificar si la posición de salto está vacía
    jne movimiento_invalido_zorro
    ; Mover el zorro a la posición de salto
    mov byte [rsi - 1], 2       ; Actualizar la posición anterior del zorro con 2 (vacío)
    mov byte [rax], 3           ; Colocar el zorro en la nueva posición de salto
    ; Borrar la oca que fue comida
    sub rax, rdi
    mov byte [rax], 2
    add qword [cantidad_ocas_eliminadas], 1 ;aumento en uno la cantidad de ocas eliminadas
    cmp qword [cantidad_ocas_eliminadas], 12  ;si gana el zorro
    je ganador_zorro
    mov byte [inputValido], 'S' ; Indicar que el movimiento fue válido
    mov byte [comio_oca], 1     ; Indicar que el zorro comió una oca
    ; Reconstruir e imprimir el tablero para reflejar el estado actual
    sub     rsp,8
    call    construir_tablero
    add     rsp,8
    sub     rsp,8
    call    imprimir_tablero
    add     rsp,8
    jmp turno_zorro             ; Continuar el turno del zorro

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
    cmp byte [input_oca], 'f'    ; Verificar si se desea abandonar la partida
    je fin_juego
    ; Validar las coordenadas de la oca
    sub rsp,8
    call validar_coordenadas_oca
    add rsp,8
    cmp byte [inputValido], 'S'
    je pedir_direccion_oca

    mov rdi, msjErrorInput
    mPuts
    sub rsp,8
    call pedir_movimiento_oca
    add rsp,8
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
    cmp al, 's'
    je mover_oca_abajo
    cmp al, 'a'
    je mover_oca_izquierda
    cmp al, 'd'
    je mover_oca_derecha
    mov rdi, msjErrorInput
    mPuts
    jmp turno_ocas
    ret

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
    mov rdi, mensaje_mov_invalido
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

ganador_zorro:
    ; Imprimir el mensaje del ganador y finalizar el juego
    mov rdi, mensaje_ganador
    mov rsi, nombre_jugador1
    mPrintF
    jmp fin_juego

fin_juego:
    mov     rdi, mensaje_fin_juego  ; Imprimir el mensaje de fin del juego
    mPuts
    mov     eax, 60                 ; syscall: exit
    xor     edi, edi                ; status: 0
    syscall

