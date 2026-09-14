// ============================================================================
// Modulo 5.4 - Generador de error (transmisor)
// EL-3307 Diseno Logico - Proyecto corto I
//
// Funcion: recibe la palabra codificada (7 bits Hamming(7,4) + 1 bit de
// paridad DED = 8 bits en total) y dos selectores de 3 bits que indican,
// cada uno, la posicion (1 a 7) del bit al que se le desea insertar un
// error (invertirlo). Si un selector vale 0, ese canal no inserta error.
//
// pos_err1_i, pos_err2_i:
//   000 -> no se inserta error en ese canal
//   001..111 -> invierte el bit en la posicion 1..7 de pal_cod_i
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
