// ============================================================================
// MODELO ESTRUCTURAL DE LOS MODULOS 5.1 Y 5.2 -- SOLO PARA SIMULACION
// (no se sintetiza ni se carga en la FPGA; estos modulos van alambrados con
// 2 circuitos integrados 74HC86 en la protoboard del transmisor).
//
// Este archivo NO usa el operador "^" de SystemVerilog. En su lugar,
// instancia 7 primitivas "xor" de 2 entradas -- una por cada compuerta XOR
// fisica dentro de los dos 74HC86 -- conectadas exactamente como se van a
// alambrar en la protoboard. Es la forma mas fiel de simular en el
// computador el circuito de compuertas antes de alambrar nada.
//
// Entradas: datos_i[3:0]   (datos_i[0]=d1 ... datos_i[3]=d4)
// Salidas:  pal_cod_o[7:1] (7 bits, posiciones 1..7 de Hamming (7,4))
//           ded_o          (octavo bit, paridad DED de la palabra completa)
//
// Mapeo a chips reales (ver la guia de alambrado):
//   U1 74HC86 #1 -> 1,2->3 (G1) | 4,5->6 (G2) | 9,10->8 (G3) | 12,13->11 (G4)
//   U2 74HC86 #2 -> 1,2->3 (G1) | 4,5->6 (G2)          ... modulo 5.1
//                   12,13->11 (G4)                      ... modulo 5.2
//                   9,10->8 (G3) queda LIBRE de repuesto
//
// Nota de diseno: el nodo d1 xor d2 sirve para dos cosas a la vez, para p1
// (modulo 5.1) y para p0 (modulo 5.2), asi que se calcula UNA sola vez en
// U1.G1 y su salida se reparte a dos compuertas. Por eso alcanzan 7
// compuertas y no 8, y queda una libre en U2: si al probar en la protoboard
// una compuerta sale mala, se puede pasar el cableado a la de repuesto sin
// tener que meter un tercer chip.
// ============================================================================

module module_hamming74_estructural (
    input  logic [3:0] datos_i,
    output logic [7:1] pal_cod_o,
    output logic        ded_o
);

    wire d1, d2, d3, d4;
    assign d1 = datos_i[0];
    assign d2 = datos_i[1];
    assign d3 = datos_i[2];
    assign d4 = datos_i[3];

    wire t1, t2, t3;       // nodos intermedios (salida de la 1ra compuerta de cada cascada)
    wire p1, p2, p4, p0;

    // ---- MODULO 5.1 · codificador Hamming (7,4) con paridad par ----------
    // ---- U1 · 74HC86 #1 --------------------------------------------------
    xor U1_G1 (t1, d1, d2);   // pines 1,2 -> 3
    xor U1_G2 (p1, t1, d4);   // pines 4,5 -> 6      => p1 = d1 xor d2 xor d4
    xor U1_G3 (t2, d1, d3);   // pines 9,10 -> 8
    xor U1_G4 (p2, t2, d4);   // pines 12,13 -> 11   => p2 = d1 xor d3 xor d4

    // ---- U2 · 74HC86 #2, primera mitad -----------------------------------
    xor U2_G1 (t3, d2, d3);   // pines 1,2 -> 3
    xor U2_G2 (p4, t3, d4);   // pines 4,5 -> 6      => p4 = d2 xor d3 xor d4

    // ---- MODULO 5.2 · paridad DED (octavo bit) ---------------------------
    // p0 es la paridad par de las 7 posiciones de la palabra codificada.
    // Al sustituir p1, p2 y p4 por sus ecuaciones, d4 aparece 4 veces y se
    // cancela, y d1, d2 y d3 aparecen 3 veces cada uno. La expresion se
    // reduce entonces a p0 = d1 xor d2 xor d3.
    //
    // Y como t1 ya vale d1 xor d2, basta UNA compuerta mas: se reaprovecha la
    // salida de U1.G1 (pin 3 de U1), que ya iba a U1.G2, y se lleva tambien a
    // esta compuerta. En la protoboard es un cable del pin 3 de U1 al pin 12
    // de U2. La compuerta U2.G3 (pines 9,10 -> 8) queda libre de repuesto.
    // ---- U2 · 74HC86 #2, cuarta compuerta --------------------------------
    xor U2_G4 (p0, t1, d3);   // pines 12,13 -> 11   => p0 = d1 xor d2 xor d3

    // ---- Ensamble de la palabra de 7 bits (posiciones 1..7) ---------------
    assign pal_cod_o[1] = p1;
    assign pal_cod_o[2] = p2;
    assign pal_cod_o[3] = d1;   // pasa directo, sin compuerta
    assign pal_cod_o[4] = p4;
    assign pal_cod_o[5] = d2;   // pasa directo, sin compuerta
    assign pal_cod_o[6] = d3;   // pasa directo, sin compuerta
    assign pal_cod_o[7] = d4;   // pasa directo, sin compuerta

    assign ded_o = p0;          // octavo bit

endmodule
