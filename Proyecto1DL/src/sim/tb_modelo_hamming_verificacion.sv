`timescale 1ns/1ps
// Verificacion exhaustiva (16 palabras x 0/1/2 errores) de que las ecuaciones
// de 5.1 (Hamming (7,4)) y 5.2 (paridad DED) permiten corregir 1 error y
// detectar 2 errores, usando ademas el modulo 5.4 para insertar los errores.
module tb_modelo_hamming_verificacion;

    logic [3:0] datos_i;
    logic [7:1] pal_cod, pal_err;
    logic        ded, ded_err;
    logic [2:0]  pos_err1, pos_err2;

    modelo_hamming_verificacion CODIF (.datos_i(datos_i), .pal_cod_o(pal_cod), .ded_o(ded));
    module_generador_error       ERRGEN (.pal_cod_i(pal_cod), .ded_i(ded),
                                          .pos_err1_i(pos_err1), .pos_err2_i(pos_err2),
                                          .pal_err_o(pal_err), .ded_o(ded_err));

    logic s1, s2, s4;
    logic [2:0] sindrome;
    logic paridad_total; // incluye el bit ded

    integer d, k1, k2, fallos;

    initial begin
        fallos = 0;
        $display("=== Verificacion exhaustiva Hamming(7,4)+DED ===");

        for (d = 0; d < 16; d = d + 1) begin
            datos_i = d[3:0];

            // --- Caso sin error ---
            pos_err1 = 3'b000; pos_err2 = 3'b000;
            #1;
            s1 = pal_err[1] ^ pal_err[3] ^ pal_err[5] ^ pal_err[7];
            s2 = pal_err[2] ^ pal_err[3] ^ pal_err[6] ^ pal_err[7];
            s4 = pal_err[4] ^ pal_err[5] ^ pal_err[6] ^ pal_err[7];
            sindrome = {s4, s2, s1};
            paridad_total = pal_err[1]^pal_err[2]^pal_err[3]^pal_err[4]^pal_err[5]^pal_err[6]^pal_err[7]^ded_err;
            if (sindrome !== 3'b000 || paridad_total !== 1'b0) begin
                fallos = fallos + 1;
                $display("FALLO (sin error) dato=%0d sindrome=%b paridad=%b", d, sindrome, paridad_total);
            end

            // --- Un solo error en cada posicion 1..7 ---
            for (k1 = 1; k1 <= 7; k1 = k1 + 1) begin
                pos_err1 = k1[2:0]; pos_err2 = 3'b000;
                #1;
                s1 = pal_err[1] ^ pal_err[3] ^ pal_err[5] ^ pal_err[7];
                s2 = pal_err[2] ^ pal_err[3] ^ pal_err[6] ^ pal_err[7];
                s4 = pal_err[4] ^ pal_err[5] ^ pal_err[6] ^ pal_err[7];
                sindrome = {s4, s2, s1};
                paridad_total = pal_err[1]^pal_err[2]^pal_err[3]^pal_err[4]^pal_err[5]^pal_err[6]^pal_err[7]^ded_err;
                if (sindrome !== k1[2:0] || paridad_total !== 1'b1) begin
                    fallos = fallos + 1;
                    $display("FALLO (1 error pos %0d) dato=%0d sindrome=%b(esp %0d) paridad=%b(esp 1)",
                              k1, d, sindrome, k1, paridad_total);
                end
            end

            // --- Dos errores en posiciones distintas: debe detectarse (DED) ---
            for (k1 = 1; k1 <= 7; k1 = k1 + 1) begin
                for (k2 = 1; k2 <= 7; k2 = k2 + 1) begin
                    if (k1 != k2) begin
                        pos_err1 = k1[2:0]; pos_err2 = k2[2:0];
                        #1;
                        s1 = pal_err[1] ^ pal_err[3] ^ pal_err[5] ^ pal_err[7];
                        s2 = pal_err[2] ^ pal_err[3] ^ pal_err[6] ^ pal_err[7];
                        s4 = pal_err[4] ^ pal_err[5] ^ pal_err[6] ^ pal_err[7];
                        sindrome = {s4, s2, s1};
                        paridad_total = pal_err[1]^pal_err[2]^pal_err[3]^pal_err[4]^pal_err[5]^pal_err[6]^pal_err[7]^ded_err;
                        // DED: dos errores -> sindrome != 0 pero paridad_total == 0 (evento detectable, NO corregible)
                        if (!(sindrome !== 3'b000 && paridad_total === 1'b0)) begin
                            fallos = fallos + 1;
                            $display("FALLO (2 errores pos %0d,%0d) dato=%0d sindrome=%b paridad=%b",
                                      k1, k2, d, sindrome, paridad_total);
                        end
                    end
                end
            end
        end

        if (fallos == 0)
            $display("*** OK: SEC funciona para 1 error y DED detecta 2 errores en los 16x(1+7+42) casos ***");
        else
            $display("*** %0d FALLOS ***", fallos);
        $finish;
    end
endmodule
