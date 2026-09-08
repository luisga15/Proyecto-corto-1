// ============================================================================
// MODELO ESTRUCTURAL DEL MODULO 5.1 -- SOLO PARA SIMULACION
// (no se sintetiza ni se carga en la FPGA; el modulo 5.1 real va alambrado
// con 2 circuitos integrados 74HC86 en la protoboard).
//
// Este archivo NO usa el operador "^" de SystemVerilog. En su lugar,
// instancia 6 primitivas "xor" de 2 entradas -- una por cada compuerta XOR
// fisica dentro de los dos 74HC86 -- conectadas exactamente como se van a
// alambrar en la protoboard. Es la forma mas fiel de simular en el
// computador el circuito de compuertas antes de soldar/alambrar nada.
//
// Entrada:  datos_i[3:0]  (datos_i[0]=d1 ... datos_i[3]=d4)
// Salida:   pal_cod_o[7:1] (7 bits, posiciones 1..7 de Hamming (7,4))
//
// Mapeo a chips reales (ver diagrama de alambrado en la guia):
//   U1 74HC86 #1 -> pines 1,2->3 (G1) | 4,5->6 (G2) | 9,10->8 (G3) | 12,13->11 (G4)
//   U2 74HC86 #2 -> pines 1,2->3 (G5) | 4,5->6 (G6)   (quedan libres 9,10->8 y 12,13->11 para el modulo 5.2)
// ============================================================================

module module_hamming74_estructural (
    input  logic [3:0] datos_i,
    output logic [7:1] pal_cod_o
);

    wire d1, d2, d3, d4;
    assign d1 = datos_i[0];
    assign d2 = datos_i[1];
    assign d3 = datos_i[2];
    assign d4 = datos_i[3];

    wire t1, t2, t3;   // nodos intermedios (salida de la 1ra compuerta de cada cascada)
    wire p1, p2, p4;

    // ---- U1 · 74HC86 #1 --------------------------------------------------
    xor U1_G1 (t1, d1, d2);   // pines 1,2 -> 3
    xor U1_G2 (p1, t1, d4);   // pines 4,5 -> 6      => p1 = d1 xor d2 xor d4
    xor U1_G3 (t2, d1, d3);   // pines 9,10 -> 8
    xor U1_G4 (p2, t2, d4);   // pines 12,13 -> 11   => p2 = d1 xor d3 xor d4

    // ---- U2 · 74HC86 #2 (solo 2 de las 4 compuertas) ----------------------
    xor U2_G1 (t3, d2, d3);   // pines 1,2 -> 3
    xor U2_G2 (p4, t3, d4);   // pines 4,5 -> 6      => p4 = d2 xor d3 xor d4

    // ---- Ensamble de la palabra de 7 bits (posiciones 1..7) ---------------
    assign pal_cod_o[1] = p1;
    assign pal_cod_o[2] = p2;
    assign pal_cod_o[3] = d1;   // pasa directo, sin compuerta
    assign pal_cod_o[4] = p4;
    assign pal_cod_o[5] = d2;   // pasa directo, sin compuerta
    assign pal_cod_o[6] = d3;   // pasa directo, sin compuerta
    assign pal_cod_o[7] = d4;   // pasa directo, sin compuerta

endmodule
