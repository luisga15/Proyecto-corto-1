// ============================================================================
// MODELO DE VERIFICACION -- SOLO PARA SIMULACION (no sintetizar / no es la
// implementacion final de 5.1 y 5.2, que deben ir alambrados con 74HCXX).
//
// Sirve para que usted verifique en el simulador, ANTES de soldar/alambrar
// nada en la protoboard, que las ecuaciones de paridad que va a implementar
// con compuertas XOR (74HC86) son correctas para la convencion de bits que
// se explica en la guia.
//
// Convencion (posiciones 1..7, dato d1..d4 = datos_i[0]..datos_i[3]):
//   pos1=p1  pos2=p2  pos3=d1  pos4=p4  pos5=d2  pos6=d3  pos7=d4
//   p1 = d1 xor d2 xor d4      (cubre posiciones 1,3,5,7)
//   p2 = d1 xor d3 xor d4      (cubre posiciones 2,3,6,7)
//   p4 = d2 xor d3 xor d4      (cubre posiciones 4,5,6,7)
//   p0 (DED, "octavo bit") = d1 xor d2 xor d3   (forma simplificada;
//        equivale a la paridad par de los 7 bits pos1..pos7)
// ============================================================================

module modelo_hamming_verificacion (
    input  logic [3:0] datos_i,     // datos_i[0]=d1 datos_i[1]=d2 datos_i[2]=d3 datos_i[3]=d4
    output logic [7:1] pal_cod_o,   // 7 bits Hamming (7,4)
    output logic        ded_o        // 8vo bit, paridad DED
);
    logic d1, d2, d3, d4;
    assign d1 = datos_i[0];
    assign d2 = datos_i[1];
    assign d3 = datos_i[2];
    assign d4 = datos_i[3];

    assign pal_cod_o[1] = d1 ^ d2 ^ d4;        // p1
    assign pal_cod_o[2] = d1 ^ d3 ^ d4;        // p2
    assign pal_cod_o[3] = d1;                   // d1
    assign pal_cod_o[4] = d2 ^ d3 ^ d4;        // p4
    assign pal_cod_o[5] = d2;                   // d2
    assign pal_cod_o[6] = d3;                   // d3
    assign pal_cod_o[7] = d4;                   // d4

    assign ded_o = d1 ^ d2 ^ d3;                // p0 (forma simplificada)

endmodule
