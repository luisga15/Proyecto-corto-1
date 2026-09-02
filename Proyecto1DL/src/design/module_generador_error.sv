// ============================================================================
// Modulo 5.4 - Generador de error (transmisor)
// EL-3307 Diseno Logico - Proyecto corto I
//
// Funcion: recibe la palabra codificada (7 bits Hamming(7,4) + 1 bit de
// paridad DED = 8 bits en total) y dos selectores de 3 bits que indican,
// cada uno, la posicion (1 a 7) del bit al que se le desea insertar un
// error (invertirlo). Si un selector vale 0, ese canal no inserta error.
//
// *** CONVENCION USADA (ajustela si su profesor definio otra distribucion
//     de bits en clase; lo importante es que 5.1/5.2/5.4 usen la MISMA
//     numeracion de posiciones) ***
//   - Las posiciones 1..7 corresponden a los 7 bits que salen del modulo
//     5.1 (codificador Hamming (7,4)): pal_cod_i[1] = posicion 1 (p1) ...
//     pal_cod_i[7] = posicion 7 (d4).
//   - El bit de paridad DED (modulo 5.2, "octavo bit") entra como ded_i y
//     NO es un blanco valido de error con este selector de 3 bits, ya que
//     3 bits solo permiten codificar 8 valores y el valor 0 esta reservado
//     para "sin error" (0..7 -> "sin error" + posiciones 1..7). Si su
//     diseno requiere poder inyectar el error tambien en el octavo bit,
//     debe ampliar el selector a 4 bits; consulte con su profesor/asistente
//     cual es el comportamiento esperado en su grupo.
//
// pos_err1_i, pos_err2_i:
//   000 -> no se inserta error en ese canal
//   001..111 -> invierte el bit en la posicion 1..7 de pal_cod_i
//
// Si pos_err1_i y pos_err2_i seleccionan la MISMA posicion, los dos
// "errores" se cancelan entre si (invertir dos veces el mismo bit lo deja
// igual) -- por eso la mascara se combina con XOR y no con OR.
//
// Toda la logica se implementa con ecuaciones de Boole (sin case/casez),
// segun lo exigido en el enunciado.
// ============================================================================

module module_generador_error (
    input  logic [7:1] pal_cod_i,   // 7 bits Hamming(7,4), posiciones 1..7
    input  logic        ded_i,       // bit 8: paridad DED (pasa sin cambios)
    input  logic [2:0]  pos_err1_i,  // posicion del error 1 (0 = ninguno)
    input  logic [2:0]  pos_err2_i,  // posicion del error 2 (0 = ninguno)
    output logic [7:1] pal_err_o,
    output logic        ded_o
);

    logic [7:1] mask1, mask2, mask;

    // --- Decodificador uno-entre-siete del selector 1 (ecuaciones de Boole) ---
    assign mask1[1] = ~pos_err1_i[2] & ~pos_err1_i[1] &  pos_err1_i[0];
    assign mask1[2] = ~pos_err1_i[2] &  pos_err1_i[1] & ~pos_err1_i[0];
    assign mask1[3] = ~pos_err1_i[2] &  pos_err1_i[1] &  pos_err1_i[0];
    assign mask1[4] =  pos_err1_i[2] & ~pos_err1_i[1] & ~pos_err1_i[0];
    assign mask1[5] =  pos_err1_i[2] & ~pos_err1_i[1] &  pos_err1_i[0];
    assign mask1[6] =  pos_err1_i[2] &  pos_err1_i[1] & ~pos_err1_i[0];
    assign mask1[7] =  pos_err1_i[2] &  pos_err1_i[1] &  pos_err1_i[0];

    // --- Decodificador uno-entre-siete del selector 2 (ecuaciones de Boole) ---
    assign mask2[1] = ~pos_err2_i[2] & ~pos_err2_i[1] &  pos_err2_i[0];
    assign mask2[2] = ~pos_err2_i[2] &  pos_err2_i[1] & ~pos_err2_i[0];
    assign mask2[3] = ~pos_err2_i[2] &  pos_err2_i[1] &  pos_err2_i[0];
    assign mask2[4] =  pos_err2_i[2] & ~pos_err2_i[1] & ~pos_err2_i[0];
    assign mask2[5] =  pos_err2_i[2] & ~pos_err2_i[1] &  pos_err2_i[0];
    assign mask2[6] =  pos_err2_i[2] &  pos_err2_i[1] & ~pos_err2_i[0];
    assign mask2[7] =  pos_err2_i[2] &  pos_err2_i[1] &  pos_err2_i[0];

    // --- Combinacion de ambas mascaras e insercion del error ---
    assign mask       = mask1 ^ mask2;
    assign pal_err_o   = pal_cod_i ^ mask;
    assign ded_o        = ded_i;

endmodule
