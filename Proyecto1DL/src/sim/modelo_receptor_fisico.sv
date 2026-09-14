// ============================================================================
// MODELO ESTRUCTURAL DE LOS MÓDULOS FÍSICOS DEL RECEPTOR (7.1 y 7.2)
// SOLO PARA SIMULACIÓN -- no se sintetiza ni se carga en la FPGA.
//
// Instancia 15 primitivas "xor" de 2 entradas, una por cada compuerta física
// dentro de los cuatro 74HC86 de la protoboard del receptor, conectadas
// exactamente como en la tabla de alambrado de la guía.
//
// 7.1 - Verificador de paridad total (7 compuertas: U1 completo + U2.G1..G3)
//       p_total_o = XOR de los 8 bits recibidos.  1 = paridad impar = "mal".
//
// 7.2 - Generador del síndrome (8 compuertas: U2.G4, U3 completo, U4.G1..G3)
//       s1 = pos1 ^ pos3 ^ pos5 ^ pos7
//       s2 = pos2 ^ pos3 ^ pos6 ^ pos7
//       s4 = pos4 ^ pos5 ^ pos6 ^ pos7
//       sind_o = {s4, s2, s1}
//
// Nota de diseño: el nodo j = pos6 ^ pos7 se calcula UNA sola vez y se
// reutiliza en s2 y en s4; por eso alcanzan 15 compuertas y no 16, y queda
// una compuerta libre en U4.
//
// Índices: rx_i[0] = posición 1 ... rx_i[6] = posición 7, rx_i[7] = posición 8 (DED)
// ============================================================================

module modelo_receptor_fisico (
    input  logic [7:0] rx_i,
    output logic [2:0] sind_o,
    output logic       p_total_o
);

    wire r1, r2, r3, r4, r5, r6, r7, r8;
    assign r1 = rx_i[0];
    assign r2 = rx_i[1];
    assign r3 = rx_i[2];
    assign r4 = rx_i[3];
    assign r5 = rx_i[4];
    assign r6 = rx_i[5];
    assign r7 = rx_i[6];
    assign r8 = rx_i[7];

    wire a, b, c, d, e, f;          // nodos del verificador de paridad (7.1)
    wire g, h, i_n, j, k;           // nodos del generador de síndrome (7.2)
    wire s1, s2, s4;

    // ---- 7.1 : paridad total de los 8 bits ------------------------------
    xor U1_G1 (a, r1, r2);          // U1 pines 1,2 -> 3
    xor U1_G2 (b, r3, r4);          // U1 pines 4,5 -> 6
    xor U1_G3 (c, r5, r6);          // U1 pines 9,10 -> 8
    xor U1_G4 (d, r7, r8);          // U1 pines 12,13 -> 11
    xor U2_G1 (e, a, b);            // U2 pines 1,2 -> 3
    xor U2_G2 (f, c, d);            // U2 pines 4,5 -> 6
    xor U2_G3 (p_total_o, e, f);    // U2 pines 9,10 -> 8   => salida a la FPGA

    // ---- 7.2 : síndrome --------------------------------------------------
    xor U2_G4 (g,   r1, r3);        // U2 pines 12,13 -> 11
    xor U3_G1 (h,   r5, r7);        // U3 pines 1,2 -> 3
    xor U3_G2 (s1,  g,  h);         // U3 pines 4,5 -> 6     => salida a la FPGA
    xor U3_G3 (i_n, r2, r3);        // U3 pines 9,10 -> 8
    xor U3_G4 (j,   r6, r7);        // U3 pines 12,13 -> 11  (se reutiliza en s4)
    xor U4_G1 (s2,  i_n, j);        // U4 pines 1,2 -> 3     => salida a la FPGA
    xor U4_G2 (k,   r4, r5);        // U4 pines 4,5 -> 6
    xor U4_G3 (s4,  k,  j);         // U4 pines 9,10 -> 8    => salida a la FPGA
    // U4.G4 (pines 12,13 -> 11) queda libre

    assign sind_o[0] = s1;
    assign sind_o[1] = s2;
    assign sind_o[2] = s4;

endmodule
