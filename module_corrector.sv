// ============================================================================
// Módulo 7.3 - Corrección de error sobre la palabra recibida (SEC / DED)
// EL-3307 Diseño Lógico - Proyecto corto I  --  va DENTRO de la FPGA
//
// Entradas que vienen de los dos bloques físicos anteriores (74HC86):
//   sind_i    : síndrome de 3 bits que genera el módulo 7.2
//               (valor 1..7 = posición del bit dañado; 0 = sin error detectado)
//   p_total_i : paridad total de los 8 bits recibidos, que genera el módulo 7.1
//               (1 = paridad impar = "mal"; 0 = paridad par = "bien")
//
// Tabla de decisión del algoritmo SEC-DED:
//   p_total = 0 y síndrome = 0  -> no hay error
//   p_total = 1 y síndrome != 0 -> UN error en la posición del síndrome: se corrige
//   p_total = 1 y síndrome = 0  -> el error cayó en el propio bit DED: los datos están bien
//   p_total = 0 y síndrome != 0 -> DOS errores: se detecta (DED) pero NO se puede corregir
//
// ============================================================================

module module_corrector (
    input  logic [6:0] rx_ham_i,    // palabra recibida, posiciones 1..7 (rx_ham_i[0] = posición 1)
    input  logic [2:0] sind_i,      // síndrome del módulo físico 7.2
    input  logic       p_total_i,   // paridad total del módulo físico 7.1
    output logic [6:0] corr_o,      // palabra corregida, posiciones 1..7
    output logic [3:0] datos_o,     // 4 bits de datos ya corregidos (d4 d3 d2 d1)
    output logic       ded_o        // 1 = doble error detectado (no corregible)
);

    // --- ¿El síndrome es distinto de cero? ---
    logic sind_nz;
    assign sind_nz = sind_i[0] | sind_i[1] | sind_i[2];

    // --- Decisiones ---
    logic corregir;
    assign corregir = p_total_i & sind_nz;      // un solo error -> corregible
    assign ded_o    = ~p_total_i & sind_nz;     // dos errores  -> sólo detectable

    // --- Decodificador uno-entre-siete del síndrome, habilitado por "corregir" ---
    logic [6:0] mask;   // mask[k-1] = 1 -> hay que invertir la posición k
    assign mask[0] = corregir & ~sind_i[2] & ~sind_i[1] &  sind_i[0];  // posición 1
    assign mask[1] = corregir & ~sind_i[2] &  sind_i[1] & ~sind_i[0];  // posición 2
    assign mask[2] = corregir & ~sind_i[2] &  sind_i[1] &  sind_i[0];  // posición 3
    assign mask[3] = corregir &  sind_i[2] & ~sind_i[1] & ~sind_i[0];  // posición 4
    assign mask[4] = corregir &  sind_i[2] & ~sind_i[1] &  sind_i[0];  // posición 5
    assign mask[5] = corregir &  sind_i[2] &  sind_i[1] & ~sind_i[0];  // posición 6
    assign mask[6] = corregir &  sind_i[2] &  sind_i[1] &  sind_i[0];  // posición 7

    // --- Corrección: se invierte únicamente el bit señalado ---
    assign corr_o = rx_ham_i ^ mask;

    // --- Extracción de los 4 bits de datos (posiciones 3, 5, 6 y 7) ---
    assign datos_o[0] = corr_o[2];   // d1 (posición 3)
    assign datos_o[1] = corr_o[4];   // d2 (posición 5)
    assign datos_o[2] = corr_o[5];   // d3 (posición 6)
    assign datos_o[3] = corr_o[6];   // d4 (posición 7)

endmodule
