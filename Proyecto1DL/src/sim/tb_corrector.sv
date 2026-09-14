`timescale 1ns/1ps
// ============================================================================
// TB del modulo 7.3 (correccion SEC / deteccion DED)
//
// Este testbench faltaba: el modulo 7.3 es el que toma la decision del
// algoritmo SEC-DED y hasta ahora solo se probaba de forma indirecta, dentro
// del testbench del sistema completo.
//
// Recorre EXHAUSTIVAMENTE las 2048 combinaciones posibles de las entradas:
//   128 palabras recibidas (7 bits) x 8 sindromes x 2 valores de paridad
//
// y comprueba, para cada una, la tabla de decision del algoritmo:
//
//   p_total  sindrome   que debe pasar
//   -------  --------   ---------------------------------------------------
//      0        0       no hay error         -> no corrige, ded_o = 0
//      1       !=0      un error             -> invierte ese bit, ded_o = 0
//      1        0       el error cayo en el propio bit DED
//                       -> no toca la palabra, ded_o = 0
//      0       !=0      dos errores          -> no corrige, ded_o = 1
//
// Ademas verifica que datos_o siempre sea la extraccion de las posiciones
// 3, 5, 6 y 7 de la palabra ya corregida.
//
// Nota de estilo: no usa el tipo "string" ni $sformatf.
// ============================================================================
module tb_corrector;

    logic [6:0] rx_ham_i;
    logic [2:0] sind_i;
    logic       p_total_i;
    logic [6:0] corr_o;
    logic [3:0] datos_o;
    logic       ded_o;

    module_corrector DUT (
        .rx_ham_i  (rx_ham_i),
        .sind_i    (sind_i),
        .p_total_i (p_total_i),
        .corr_o    (corr_o),
        .datos_o   (datos_o),
        .ded_o     (ded_o)
    );

    integer w, s, p, fallos, casos;
    logic [6:0] esperado_corr;
    logic       esperado_ded;
    logic [3:0] esperado_datos;

    initial begin
        fallos = 0;
        casos  = 0;
        $display("=== TB module_corrector (7.3) : barrido exhaustivo 128 x 8 x 2 ===");
        $dumpfile("corrector_tb.vcd");
        $dumpvars(0, tb_corrector);

        for (w = 0; w < 128; w = w + 1) begin
            for (s = 0; s < 8; s = s + 1) begin
                for (p = 0; p < 2; p = p + 1) begin
                    rx_ham_i  = w[6:0];
                    sind_i    = s[2:0];
                    p_total_i = p[0];
                    #1;
                    casos = casos + 1;

                    // --- valores esperados segun la tabla de decision ---
                    esperado_corr = rx_ham_i;
                    esperado_ded  = 1'b0;

                    if (p_total_i === 1'b1 && s != 0) begin
                        // un solo error: se invierte el bit de la posicion s
                        esperado_corr[s-1] = ~esperado_corr[s-1];
                    end else if (p_total_i === 1'b0 && s != 0) begin
                        // dos errores: se detecta pero NO se corrige
                        esperado_ded = 1'b1;
                    end
                    // los otros dos casos (s == 0) dejan la palabra intacta

                    esperado_datos[0] = esperado_corr[2];   // d1 = posicion 3
                    esperado_datos[1] = esperado_corr[4];   // d2 = posicion 5
                    esperado_datos[2] = esperado_corr[5];   // d3 = posicion 6
                    esperado_datos[3] = esperado_corr[6];   // d4 = posicion 7

                    if (corr_o !== esperado_corr) begin
                        fallos = fallos + 1;
                        $display("FALLO palabra=%b sind=%0d p_total=%b : corr_o=%b esperado=%b",
                                  rx_ham_i, s, p_total_i, corr_o, esperado_corr);
                    end
                    if (ded_o !== esperado_ded) begin
                        fallos = fallos + 1;
                        $display("FALLO palabra=%b sind=%0d p_total=%b : ded_o=%b esperado=%b",
                                  rx_ham_i, s, p_total_i, ded_o, esperado_ded);
                    end
                    if (datos_o !== esperado_datos) begin
                        fallos = fallos + 1;
                        $display("FALLO palabra=%b sind=%0d p_total=%b : datos_o=%b esperado=%b",
                                  rx_ham_i, s, p_total_i, datos_o, esperado_datos);
                    end
                end
            end
        end

        $display("Casos probados: %0d", casos);
        if (fallos == 0)
            $display("*** TODAS LAS PRUEBAS PASARON ***");
        else
            $display("*** %0d PRUEBA(S) FALLARON ***", fallos);
        $finish;
    end

endmodule
