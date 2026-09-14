`timescale 1ns/1ps
// ============================================================================
// Verifica el modelo estructural de 5.1 y 5.2 (compuertas XOR discretas, como
// los 74HC86 fisicos) contra la tabla completa de las 16 palabras posibles.
//
// Ademas de comparar contra las ecuaciones de referencia, comprueba la
// propiedad que de verdad importa del octavo bit: que la paridad de los 8
// bits de la palabra transmitida siempre sea PAR.
//
// Nota de estilo: este testbench no usa el tipo "string" ni $sformatf, porque
// la version 13.0-devel de Icarus Verilog del oss-cad-suite falla con una
// asercion al compilarlos.
// ============================================================================
module tb_hamming74_estructural;

    logic [3:0] datos_i;
    logic [7:1] pal_cod_o;
    logic        ded_o;

    module_hamming74_estructural DUT (
        .datos_i   (datos_i),
        .pal_cod_o (pal_cod_o),
        .ded_o     (ded_o)
    );

    // Referencia de comportamiento para comparar
    function automatic [7:1] referencia(input [3:0] datos);
        logic d1,d2,d3,d4;
        begin
            d1 = datos[0]; d2 = datos[1]; d3 = datos[2]; d4 = datos[3];
            referencia[1] = d1 ^ d2 ^ d4;
            referencia[2] = d1 ^ d3 ^ d4;
            referencia[3] = d1;
            referencia[4] = d2 ^ d3 ^ d4;
            referencia[5] = d2;
            referencia[6] = d3;
            referencia[7] = d4;
        end
    endfunction

    logic esperado_ded;
    logic paridad_total;

    integer i, fallos;
    initial begin
        fallos = 0;
        $display("=== TB module_hamming74_estructural (5.1 + 5.2, compuertas discretas) ===");
        // dumpfile para poder verlo con GTKWave (make wv)
        $dumpfile("hamming74_estructural_tb.vcd");
        $dumpvars(0, tb_hamming74_estructural);

        for (i = 0; i < 16; i = i + 1) begin
            datos_i = i[3:0];
            #10;

            // El octavo bit debe ser la paridad par de las 7 posiciones
            esperado_ded = pal_cod_o[1] ^ pal_cod_o[2] ^ pal_cod_o[3] ^ pal_cod_o[4]
                         ^ pal_cod_o[5] ^ pal_cod_o[6] ^ pal_cod_o[7];

            // Y, por lo tanto, la paridad de los 8 bits debe dar 0
            paridad_total = esperado_ded ^ ded_o;

            if (pal_cod_o !== referencia(datos_i)) begin
                fallos = fallos + 1;
                $display("FALLO dato=%0d (0x%0h): pal_cod_o=%b esperado=%b",
                          i, i, pal_cod_o, referencia(datos_i));
            end else if (ded_o !== esperado_ded) begin
                fallos = fallos + 1;
                $display("FALLO dato=%0d (0x%0h): ded_o=%b esperado=%b",
                          i, i, ded_o, esperado_ded);
            end else if (paridad_total !== 1'b0) begin
                fallos = fallos + 1;
                $display("FALLO dato=%0d (0x%0h): la paridad de los 8 bits no es par", i, i);
            end else begin
                $display("OK    dato=%0d (0x%0h): pal_cod_o=%b ded=%b  (p1=%b p2=%b d1=%b p4=%b d2=%b d3=%b d4=%b)",
                          i, i, pal_cod_o, ded_o,
                          pal_cod_o[1], pal_cod_o[2], pal_cod_o[3], pal_cod_o[4],
                          pal_cod_o[5], pal_cod_o[6], pal_cod_o[7]);
            end
        end

        if (fallos == 0)
            $display("*** TODAS LAS PRUEBAS PASARON (16/16) ***");
        else
            $display("*** %0d PRUEBA(S) FALLARON ***", fallos);
        $finish;
    end
endmodule
