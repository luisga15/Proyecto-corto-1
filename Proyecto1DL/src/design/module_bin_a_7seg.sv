// ============================================================================
// Modulo 5.3 - Codificacion binario a 7 segmentos (transmisor)
// EL-3307 Diseno Logico - Proyecto corto I
//
// Funcion: toma la palabra de 4 bits ingresada por el usuario (switches) y la
// decodifica a formato hexadecimal (0-F) para desplegarla en un display de
// 7 segmentos, de forma que el usuario pueda confirmar visualmente la palabra
// antes de que sea enviada al codificador Hamming (7,4).
//
// Convencion de entrada:
//   datos_i[3] = A (MSB) ... datos_i[0] = D (LSB)
//
// Convencion de salida: ACTIVA EN BAJO.
//   seg_o[0] = a   seg_o[1] = b   seg_o[2] = c   seg_o[3] = d
//   seg_o[4] = e   seg_o[5] = f   seg_o[6] = g
//   seg_o[i] = 0  -> segmento ENCENDIDO
//   seg_o[i] = 1  -> segmento APAGADO
//
// OJO: esta polaridad es la de este decodificador solo, porque asi se
// resolvieron los mapas de Karnaugh (se tomo como "1" el caso en que el
// segmento queda apagado). El proyecto usa displays de CATODO COMUN, que
// necesitan la polaridad contraria, asi que module_display_7seg invierte
// estas siete salidas una sola vez antes de mandarlas a los pines. Las
// ecuaciones de abajo NO cambian: quedan tal como estan en la bitacora.
//
// Las ecuaciones de cada segmento fueron obtenidas resolviendo el mapa de
// Karnaugh de 4 variables (A,B,C,D) para cada salida, tomando como "1" los
// casos en que el segmento debe permanecer APAGADO (logica activa en bajo).
// Verifiquelas usted mismo en su bitacora; puede usarlas como 4 de los
// ejemplos de simplificacion que pide la seccion 8 del enunciado.
// ============================================================================

module module_bin_a_7seg (
    input  logic [3:0] datos_i,
    output logic [6:0] seg_o
);

    // Entradas
    logic A, B, C, D;

    assign A = datos_i[3];
    assign B = datos_i[2];
    assign C = datos_i[1];
    assign D = datos_i[0];


    // Display de 7 segmentos de CATODO COMUN
    // 1 = segmento encendido
    // 0 = segmento apagado


    // seg_o[0] = a
    assign seg_o[0] = ~(
        (A & B & D & ~C) |
        (A & C & D & ~B) |
        (B & ~A & ~C & ~D) |
        (D & ~A & ~B & ~C)
    );


    // seg_o[1] = b
    assign seg_o[1] = ~(
        (A & C & D) |
        (A & B & ~D) |
        (B & C & ~D) |
        (B & D & ~A & ~C)
    );


    // seg_o[2] = c
    assign seg_o[2] = ~(
        (A & B & C) |
        (A & B & ~D) |
        (C & ~A & ~B & ~D)
    );


    // seg_o[3] = d
    assign seg_o[3] = ~(
        (B & C & D) |
        (A & C & ~B & ~D) |
        (B & ~A & ~C & ~D) |
        (D & ~A & ~B & ~C)
    );


    // seg_o[4] = e
    assign seg_o[4] = ~(
        (D & ~A) |
        (B & ~A & ~C) |
        (D & ~B & ~C)
    );


    // seg_o[5] = f
    assign seg_o[5] = ~(
        (C & D & ~A) |
        (C & ~A & ~B) |
        (D & ~A & ~B) |
        (A & B & D & ~C)
    );


    // seg_o[6] = g
    assign seg_o[6] = ~(
        (B & C & D & ~A) |
        (~A & ~B & ~C) |
        (A & B & ~C & ~D)
    );

endmodule
