// ============================================================================
// TOP DEL TRANSMISOR  --  EL-3307 Proyecto corto I
// Tang Nano 9K #1 (GW1NR-LV9QN88PC6/I5)
//
// Contiene lo que va DENTRO de la FPGA del transmisor:
//   5.3  module_bin_a_7seg      -> despliegue hexadecimal de la palabra ingresada
//   5.4  module_generador_error -> inserción controlada de 1 o 2 errores
//
// Lo que NO está aquí (va alambrado con 74HC86 en la protoboard):
//   5.1  codificador Hamming (7,4) con paridad par
//   5.2  generador de paridad DED (octavo bit)
//
// CONVENCIÓN DE BITS (índice del puerto = posición Hamming - 1):
//   ham_i[0] = posición 1 = p1        ham_i[4] = posición 5 = d2
//   ham_i[1] = posición 2 = p2        ham_i[5] = posición 6 = d3
//   ham_i[2] = posición 3 = d1        ham_i[6] = posición 7 = d4
//   ham_i[3] = posición 4 = p4        ded_i     = posición 8 = p0 (DED)
//
// Los 4 bits de datos NO necesitan pines propios: las posiciones 3, 5, 6 y 7
// que entran desde la protoboard SON físicamente los cables de los switches
// (en el codificador pasan directo, sin compuerta), así que el display de
// 7 segmentos se alimenta de esas mismas líneas.
// ============================================================================

module top_transmisor (
    // --- Desde la protoboard (74HC86, 3.3 V) ---
    input  logic [6:0] ham_i,        // palabra Hamming (7,4): posiciones 1..7
    input  logic       ded_i,        // posición 8: paridad DED
    // --- Switches de posición de error (3.3 V, con pull-down) ---
    input  logic [2:0] err1_i,       // 0 = sin error, 1..7 = posición a invertir
    input  logic [2:0] err2_i,       // 0 = sin error, 1..7 = posición a invertir
    // --- Hacia la FPGA del receptor (8 líneas + GND común) ---
    output logic [7:0] tx_o,         // tx_o[6:0] = posiciones 1..7, tx_o[7] = DED
    // --- Display de 7 segmentos (ánodo común, activo en bajo) ---
    output logic [6:0] catodo_o      // catodo_o[0]=a ... catodo_o[6]=g
);

    // ------------------------------------------------------------------
    // 5.4 - Generador de error
    // Los puertos internos usan numeración por posición [7:1]; la conexión
    // directa alinea ham_i[6]->posición 7 ... ham_i[0]->posición 1.
    // ------------------------------------------------------------------
    logic [7:1] pal_err;
    logic       ded_err;

    module_generador_error U_ERROR (
        .pal_cod_i  (ham_i),        // [6:0] -> [7:1] por posición de bit
        .ded_i      (ded_i),
        .pos_err1_i (err1_i),
        .pos_err2_i (err2_i),
        .pal_err_o  (pal_err),
        .ded_o      (ded_err)
    );

    assign tx_o[6:0] = pal_err;     // posiciones 1..7 ya con el/los error(es)
    assign tx_o[7]   = ded_err;     // posición 8 (DED) pasa sin modificar

    // ------------------------------------------------------------------
    // 5.3 - Codificación binario a 7 segmentos
    // Los 4 bits de datos están en las posiciones 3, 5, 6 y 7 de la palabra
    // codificada: d1 = pos 3, d2 = pos 5, d3 = pos 6, d4 = pos 7.
    // Se muestra la palabra TAL COMO LA INGRESÓ EL USUARIO (antes del error).
    // ------------------------------------------------------------------
    logic [3:0] dato_usuario;
    assign dato_usuario[0] = ham_i[2];   // d1 (posición 3)
    assign dato_usuario[1] = ham_i[4];   // d2 (posición 5)
    assign dato_usuario[2] = ham_i[5];   // d3 (posición 6)
    assign dato_usuario[3] = ham_i[6];   // d4 (posición 7) = bit más significativo

    module_bin_a_7seg U_7SEG (
        .datos_i (dato_usuario),
        .seg_o   (catodo_o)
    );

endmodule
