// ============================================================================
// Modulo 7.4 - Despliegue en los dos displays de 7 segmentos
// EL-3307 Diseno Logico - Proyecto corto I  --  va DENTRO de la FPGA
//
// Los dos displays comparten los mismos 7 catodos (a..g). La entrada
// sel_sind_i decide, al mismo tiempo, QUE se decodifica y CUAL de los dos
// transistores PNP se enciende:
//
//   sel_sind_i = 0 -> se enciende el display 0 y muestra la PALABRA
//                     (en el transmisor: la palabra ingresada;
//                      en el receptor: la palabra recibida SIN corregir)
//   sel_sind_i = 1 -> se enciende el display 1 y muestra la POSICION DEL BIT
//                     ERRONEO (el sindrome), en hexadecimal; vale 0 si la
//                     palabra llego sin error
//
// En el top, sel_sind_i se genera con el boton S1 de la propia tarjeta
// (momentaneo, activo en bajo): mientras se mantiene presionado se ve el
// sindrome, y al soltarlo se vuelve a ver la palabra. Como todo el diseno es
// combinacional no hay forma de enclavarlo con un flip-flop, pero tampoco
// hace falta: el sindrome no cambia mientras la palabra de entrada no cambie.
//
// Los transistores son PNP con el emisor a 3.3 V: la base se maneja por un
// pin de la FPGA a traves de una resistencia y el transistor CONDUCE cuando
// ese pin esta en BAJO. Por eso anodo_o es activo en bajo. Nunca se encienden
// los dos a la vez, porque anodo_o[1] es siempre el complemento de anodo_o[0].
//
// Todo el multiplexado esta escrito con ecuaciones de Boole.
// ============================================================================

module module_display_7seg (
    input  logic [3:0] palabra_i,    // palabra de 4 bits a desplegar
    input  logic [2:0] sind_i,       // sindrome = posicion del bit erroneo
    input  logic       sel_sind_i,   // 1 = mostrar el sindrome
    output logic [6:0] catodo_o,     // segmentos compartidos, activo en bajo
    output logic [1:0] anodo_o       // control de los PNP, activo en bajo
);

    // --- MUX 2:1 de 4 bits, escrito como suma de productos ---
    logic [3:0] nibble;
    assign nibble[0] = (~sel_sind_i & palabra_i[0]) | (sel_sind_i & sind_i[0]);
    assign nibble[1] = (~sel_sind_i & palabra_i[1]) | (sel_sind_i & sind_i[1]);
    assign nibble[2] = (~sel_sind_i & palabra_i[2]) | (sel_sind_i & sind_i[2]);
    assign nibble[3] = (~sel_sind_i & palabra_i[3]);  // el sindrome solo usa 3 bits

    // --- Decodificador hexadecimal a 7 segmentos (modulo 5.3) ---
    module_bin_a_7seg U_DECO (
        .datos_i (nibble),
        .seg_o   (catodo_o)
    );

    // --- Seleccion del display (PNP: 0 = encendido) ---
    assign anodo_o[0] =  sel_sind_i;   // display 0 encendido cuando sel_sind_i = 0
    assign anodo_o[1] = ~sel_sind_i;   // display 1 encendido cuando sel_sind_i = 1

endmodule
