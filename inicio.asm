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
extern fopen
extern fgets
extern printf
extern fputs
extern fclose


section .data
    tablero     db  0, 0, 1, 1, 1, 0, 0
                db  0, 0, 1, 1, 1, 0, 0
                db  1, 1, 1, 1, 1, 1, 1
                db  1, 2, 2, 2, 2, 2, 1
                db  1, 2, 2, 3, 2, 2, 1
                db  0, 0, 2, 2, 2, 0, 0
                db  0, 0, 2, 2, 2, 0, 0

    salto_linea                 db 10, 0        
    simbolo_fuera_tablero       db ".", 0
    simbolo_oca                 db 'O', 0    ; symbolo por default para ocas
    simbolo_zorro               db 'X', 0    ; symbolo por default para el zorro
    simbolo_espacio_vacio       db ' ', 0
    simbolo_separador           db '|', 0
    mensaje_mover_oca           db "Ingrese la fila y columna de la oca a mover (ejemplo: 3 3). Presione f para salir de la partida: ", 0
    mensaje_mover_oca_direccion db "Mueva la oca con a: izquierda /s: abajo /d: derecha. Presione f para salir de la partida: ", 0
    formatInputFilCol           db "%hhu %hhu", 0                               ; Formato para leer enteros de 1 byte
    mensaje_error_input         db "Los datos ingresados son inválidos. Intente nuevamente.", 0
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

    
    ;Variables de archivo
    archivoTablero              db      "tablero.txt",0
    modoAperturaRead            db      "r",0   ; Abro y leo un archivo de texto
    modoAperturaWrite           db      "w",0
    archivoEstadisticas         db      "estadisticas.txt",0

    msgErrorAp                  db      "Lo sentimos, no se pudo abrir el archivo.",10,0
    msgErrorLectura             db      "No se encontró una partida guardada, se iniciará una nueva.",10,0
    msgLeido                    db      "Leído con éxito.",10,0
    msgErrorConvirt             db      "Error convirtiendo el numero",10,0
    msgErrorEscritura           db      "Error escribiendo el archivo",10,0
    msgPartidaGuardada          db      "Se ha encontrado una partida guardada, desea continuarla? (si/no)",10,0
    msgGuardarPartida           db      "Estás saliendo del juego, querés guardar tu partida? (si/no)",10,0
    respuestaSi                 db      "si",0
    registro          times 51  db      " "
    tableroStr        times 51  db      " "
    
    estadisticas      times 0   db      ''
        turnoGuardado           db      " "
        cantOcasEliminadas      db      " "
        

    CANT_FIL_COL        equ     7
    DESPLAZ_LIMITE      equ     48
    TURNO_ZORRO         equ     1
    TURNO_OCAS          equ     2


section .bss
    buffer          resb 350  ; Suficiente espacio para el tablero con saltos de línea
    input_oca       resb 10
    fila            resb 1
    columna         resb 1
    input_valido    resb 1
    posicion_oca    resq 1
    input_zorro     resb 10
    nombre_jugador1 resb 50
    nombre_jugador2 resb 50
    turno           resb 1
    comio_oca       resb 1

    ;Variables de archivo
    handleArchTablero           resq  1
    handleArchEstadisticas      resq  1
    numero                      resb  1
    posicionVect                resb  1
    posicionMatFil              resb  1
    posicionMatCol              resb  1
    respuestaPartidaGuardada    resb  4

section .text
main:
    mov     byte[turno], TURNO_ZORRO
    mov     rdi, archivoTablero
    call    abrirLecturaArchivoTablero
    cmp     rax, 0
    jle     errorApertura
        
    call    leerArchivoTablero  
    cmp     rax, 0
    jle     errorLeyendoArchivo

    mov     rdi, msgPartidaGuardada
    mPuts
    mov     rdi, respuestaPartidaGuardada
    mGets
    mov     rcx, 2
    lea     rsi, [respuestaSi]
    lea     rdi, [respuestaPartidaGuardada]
    repe    cmpsb
    jne     continuar_jugando
    call    copiarRegistroATablero
    call    cerrarArchivoTablero

    mov     rdi, archivoEstadisticas
    call    abrirLecturaArchivoEstadisticas
    cmp     rax, 0
    jle     errorApertura

    call    leerArchivoEstadisticas
    cmp     rax, 0
    jle     errorLeyendoArchivo
    call    cargarEstadisticas
    call    cerrarArchivoEstadisticas

continuar_jugando:
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
    call    verificar_movimientos_zorro  ; Verifico si el zorro tiene movimientos disponibles
    add     rsp,8
    cmp     byte [input_valido], 'N'  ; Si no tiene movimientos válidos, las ocas ganan
    je      ganador_ocas
    sub     rsp,8
    call    pedir_movimiento_zorro  ;llamo a la subrutina para pedir movimiento del zorro
    add     rsp,8
    cmp     byte [input_zorro], 'f' ; Verificar si se desea abandonar la partida
    je      guardar_partida
    sub     rsp,8
    call    mover_zorro              ;llamo a la subrutina para mover al zorro
    add     rsp,8
    cmp     byte [input_valido], 'R'  ;comparo si el movimiento del zorro fue inválido
    je      turno_zorro              ;si fue inválido, vuelvo a pedir movimiento del zorro
    cmp     byte [comio_oca], TURNO_ZORRO      ; Si comió una oca, no cambiar de turno
    je      continuar_juego
    mov     byte [turno], TURNO_OCAS          ;si fue válido y no comió oca, cambio el turno a las ocas
    jmp     continuar_juego          ;voy a la etiqueta continuar_juego

turno_ocas:
    sub     rsp,8
    call    pedir_movimiento_oca     ;llamo a la subrutina para pedir movimiento de la oca
    add     rsp,8
    cmp     byte [input_oca], 'f'    ; Verificar si se desea abandonar la partida
    je      guardar_partida
    sub     rsp,8
    call    mover_oca                ;llamo a la subrutina para mover la oca
    add     rsp,8
    cmp     byte [input_valido], 'R'  ;comparo si el movimiento de la oca fue inválido
    je      turno_ocas               ;si fue inválido, vuelvo a pedir movimiento de la oca
    mov     byte [turno], TURNO_ZORRO          ;si fue válido, cambio el turno al zorro

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
    jne     construir_tablero          ; si no es enter, se utiliza el del usuario que se guardo en simbolo_oca
    mov     byte [simbolo_oca], 'O'   ; se asigna el símbolo por defecto para las ocas, pisando en caso de enter

;skip_default_oca:
;    mov byte [turno], TURNO_ZORRO  ; Comienza el turno del zorro
;    ret

construir_tablero:
    mov     rbx, 1            ; i que será la fila, iniciada en 1 y no aumenta hasta no terminar las 7 columnas
    mov     r10, 1            ; j que será la columna
    mov     rdi, buffer       ; Apuntar al inicio del buffer

imprimir_siguiente_caracter:   
    mov     rax, rbx           ;i
    dec     rax
    imul    rax, rax, 7       ; (i-1) * longfila
    mov     rdx, r10          ;j
    dec     rdx
    add     rax, rdx          ; (i-1) * longfila + (j-1)
    mov     rsi, tablero
    add     rsi, rax          ; rsi apunta a la posición actual en el tablero

    cmp     byte [rsi], 0      ;segun el numero en tablero imprimo un caracter distinto
    je      imprimir_fuera_tablero                
    cmp     byte [rsi], 2           
    je      imprimir_espacio_vacio              
    cmp     byte [rsi], 1         
    je      imprimir_oca
    cmp     byte [rsi], 3
    je      imprimir_zorro

imprimir_fuera_tablero:
    mov     al, [simbolo_separador]
    stosb                               ;almaceno e incremento el rdi
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
    lodsb       ;apunto al siguiente y lo cargo en al
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
    mov rdi, mensaje_error_input
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
    mov byte [input_valido], 'S' ; Indicar que el movimiento fue válido
    ret

verificar_si_oca:
    cmp byte [rbx], 1           ; Comparar destino con una oca (1)
    jne movimiento_invalido_zorro ; Si no es una oca, el movimiento es inválido
    jmp validar_comer_oca       ; Ir a validar si se puede comer la oca

validar_comer_oca:
    ; Verificar si hay una oca en la posición intermedia
    ; RDI contiene la dirección del desplazamiento
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
    mov byte [input_valido], 'S' ; Indicar que el movimiento fue válido
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
    mov byte [input_valido], 'R'
    mov rdi, mensaje_mov_invalido
    mPuts
    ret

verificar_movimientos_zorro:
    mov rsi, tablero
    mov rcx, 49

buscar_zorro_verificacion_mov:
    lodsb
    cmp al, 3
    je zorro_encontrado_verificar
    loop buscar_zorro_verificacion_mov
    ret

zorro_encontrado_verificar:
    mov rbx, rsi   ; Mueve el valor del registro rsi (posición actual del zorro) a rbx
    dec rbx         ; Decrementa rbx en 1 para apuntar correctamente a la posición actual del zorro

    ; Verificar todas las direcciones alrededor del zorro (cercanas)
    mov rdi, rbx
    sub rdi, 7
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    add rdi, 7
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    dec rdi
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    inc rdi
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    sub rdi, 6
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    sub rdi, 8
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    add rdi, 6
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    add rdi, 8
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    ; Verificar las posiciones más alejadas (dos espacios en cada dirección)
    mov rdi, rbx
    sub rdi, 14  ; dos espacios hacia arriba-izquierda
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    sub rdi, 12  ; dos espacios hacia arriba-derecha
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    add rdi, 12  ; dos espacios hacia abajo-izquierda
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    add rdi, 14  ; dos espacios hacia abajo-derecha
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    sub rdi, 14  ; dos espacios hacia arriba
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    mov rdi, rbx
    add rdi, 14  ; dos espacios hacia abajo
    call verificar_casillero
    cmp byte [input_valido], 'S'
    je movimiento_valido

    ; Si no hay movimientos válidos
    mov byte [input_valido], 'N'
    ret

verificar_casillero:
    cmp byte [rdi], 2  ; Verificar si el casillero es vacío (2)
    je movimiento_valido
    ret

movimiento_valido:
    mov byte [input_valido], 'S'
    ret

pedir_movimiento_oca:
    mov rdi, mensaje_mover_oca
    mPuts
    mov rdi, input_oca
    mGets
    cmp byte [input_oca], 'f'    ; Verificar si se desea abandonar la partida
    je guardar_partida
    ; Validar las coordenadas de la oca
    sub rsp,8
    call validar_coordenadas_oca
    add rsp,8
    cmp byte [input_valido], 'S'
    je pedir_direccion_oca

    mov rdi, mensaje_error_input
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
    mov rdi, mensaje_error_input
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
    mov byte [input_valido], 'S' ; Indicar que el movimiento fue válido
    ret

movimiento_invalido_oca:
    mov byte [input_valido], 'R'
    mov rdi, mensaje_mov_invalido
    mPuts
    ret

validar_coordenadas_oca:
    mov byte [input_valido], 'N'
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
    movzx ax, byte [fila]   ;cargo en ax la fila
    sub ax, 1               ;para indexar en 0 
    imul ax, 7              ;desplazamiento en fila
    movzx dx, byte [columna]    ;cargo en dx la columna
    sub dx, 1   
    add ax, dx              ;desplazamiento total
    mov rbx, rax    
    add rbx, tablero          ;posicion en el tablero

    ; Verificar si hay una oca en la posición ingresada
    cmp byte [rbx], 1
    jne coordenadas_invalidas

    mov byte [input_valido], 'S'
    mov [posicion_oca], rbx    ; Guardar la posición de la oca
    ret

coordenadas_invalidas:
    mov rdi, mensaje_error_input
    mPuts
    ret

errorApertura:
    mov   rdi, msgErrorAp
    mPuts
    jmp   fin_juego

errorLeyendoArchivo:
    mov   rdi, msgErrorLectura
    mPuts
    jmp   continuar_jugando

errorEscritura:
    mov   rdi, msgErrorEscritura
    mPuts
    jmp   fin_juego

guardar_partida:
    mov     rdi, archivoTablero
    call    abrirEscrituraArchivoTablero

    mov     rdi, msgGuardarPartida
    mPuts
    mov     rdi, respuestaPartidaGuardada
    mGets
    mov     rcx, 2
    lea     rsi, [respuestaSi]
    lea     rdi, [respuestaPartidaGuardada]
    repe    cmpsb
    jne     noGuardarPartida

    call    convertirTableroAStr
    call    escribirArchivoTablero
    cmp     rax, 0
    jle     errorEscritura
    call    cerrarArchivoTablero

    mov     rdi, archivoEstadisticas
    call    abrirEscrituraArchivoEstadisticas
    call    convertirEstadisticasAStr
    call    escribirArchivoEstadisticas
    cmp     rax, 0
    jle     errorEscritura
    call    cerrarArchivoEstadisticas

    jmp     fin_juego
ganador_zorro:
    ; Imprimir el mensaje del ganador y finalizar el juego
    mov rdi, mensaje_ganador
    mov rsi, nombre_jugador1
    mPrintF
    jmp fin_juego

ganador_ocas:
    ; Imprimir el mensaje del ganador (ocas) y finalizar el juego
    mov rdi, mensaje_ganador
    mov rsi, nombre_jugador2
    mPrintF
    jmp fin_juego

noGuardarPartida:
    call    cerrarArchivoTablero
    ;Hago esto para que el contenido del archivo se elimine por completo
    mov     rdi, archivoEstadisticas
    call    abrirEscrituraArchivoEstadisticas
    call    cerrarArchivoEstadisticas
fin_juego:

    mov     rdi, mensaje_fin_juego  ; Imprimir el mensaje de fin del juego
    mPuts
    mov     eax, 60                 ; syscall: exit
    xor     edi, edi                ; status: 0
    syscall
ret



;---------  RUTINAS INTERNAS -----------
abrirLecturaArchivoTablero:
  
    mov   rsi, modoAperturaRead
    call  fopen

    mov   qword[handleArchTablero],rax
ret

abrirLecturaArchivoEstadisticas:
  
    mov   rsi, modoAperturaRead
    call  fopen

    mov   qword[handleArchEstadisticas],rax
ret

abrirEscrituraArchivoTablero:
  
    mov   rsi, modoAperturaWrite
    call  fopen

    mov   qword[handleArchTablero],rax
ret


abrirEscrituraArchivoEstadisticas:
  
    mov   rsi, modoAperturaWrite
    call  fopen

    mov   qword[handleArchEstadisticas],rax
ret

leerArchivoTablero:

    mov   rdi, registro
    mov   rsi, 51
    mov   rdx, [handleArchTablero]
    call  fgets

ret

leerArchivoEstadisticas:
    mov     rdi, estadisticas
    mov     rsi, 3
    mov     rdx, [handleArchEstadisticas]
    call    fgets

escribirArchivoTablero:

    mov   rdi, tableroStr
    mov   rsi, [handleArchTablero]
    call  fputs
ret

escribirArchivoEstadisticas:
    mov   rdi, estadisticas
    mov   rsi, [handleArchEstadisticas]
    call  fputs
ret

cerrarArchivoTablero:

    mov   rdi, [handleArchTablero]
    call  fclose
ret

cerrarArchivoEstadisticas:

    mov   rdi, [handleArchEstadisticas]
    call  fclose
ret

;---------------------------------
copiarRegistroATablero:

    mov   byte[posicionVect], 0
    mov   byte[posicionMatFil], 1
    mov   byte[posicionMatCol], 1

recorroReg:

    cmp   byte[posicionVect], 49
    jge    finalizoCopia

    mov   al, byte[posicionVect]
    cbw
    cwde
    cdqe
    mov   cl,[registro+rax]
    sub   cl, '0'
    mov   [numero], cl

    ; Agrego el nro a la matriz
    
    mov   al, byte[posicionMatFil] 
    cbw
    cwde
    cdqe
    dec   rax
    imul  rax, CANT_FIL_COL

    mov   rcx, rax

    mov   al, byte[posicionMatCol]
    cbw
    cwde
    cdqe
    dec   rax
    
    add   rcx, rax      ; Desplazamiento en matriz

    mov   al, byte[numero]
    mov   [tablero+rcx], al

avanzarColumna:
    inc   byte[posicionMatCol]
    cmp   byte[posicionMatCol], CANT_FIL_COL
    jg    avanzarFila
    jmp   sigoEnVector

avanzarFila:
    mov   byte[posicionMatCol], 1
    inc   byte[posicionMatFil]
    cmp   byte[posicionMatFil], CANT_FIL_COL
    jg    finalizoCopia

sigoEnVector:
    add   byte[posicionVect], 1
    jmp   recorroReg

finalizoCopia:
ret



convertirTableroAStr:
    mov   byte[posicionMatFil], 1
    mov   byte[posicionMatCol], 1

continuoCopiaStr:
    mov   al, byte[posicionMatFil] 
    cbw
    cwde
    cdqe
    dec   rax
    imul  rax, CANT_FIL_COL

    mov   rcx, rax

    mov   al, byte[posicionMatCol]
    cbw
    cwde
    cdqe
    dec   rax
    
    add   rcx, rax      ; Desplazamiento en matriz
    cmp   rcx, DESPLAZ_LIMITE
    jg    finalizoCopiaStr

    mov   al, [tablero+rcx]
    add   al, 48
    cbw
    cwde
    cdqe
    mov   [tableroStr+rcx], rax

avanzarColumnaStr:
    inc   byte[posicionMatCol]
    cmp   byte[posicionMatCol], CANT_FIL_COL
    jg    avanzarFilaStr
    jmp   continuoCopiaStr

avanzarFilaStr:
    mov   byte[posicionMatCol], 1
    inc   byte[posicionMatFil]
    cmp   byte[posicionMatFil], CANT_FIL_COL
    jg    finalizoCopiaStr
    jmp   continuoCopiaStr
    
finalizoCopiaStr:
    mov   byte[tableroStr+49], 10 ;Agrego un salto de línea al final del archivo
ret



cargarEstadisticas:
    mov     rcx, [turnoGuardado]
    sub     rcx, 48
    mov     [turno], rcx

    mov     rcx, [cantOcasEliminadas]
    sub     rcx, 48
    mov     [cantidad_ocas_eliminadas], rcx
ret

convertirEstadisticasAStr:
    mov     rcx, [turno]
    add     rcx, 48
    mov     [turnoGuardado], rcx

    mov     rcx, [cantidad_ocas_eliminadas]
    add     rcx, 48
    mov     [cantOcasEliminadas], rcx

    mov     byte[estadisticas+2], 10

ret
