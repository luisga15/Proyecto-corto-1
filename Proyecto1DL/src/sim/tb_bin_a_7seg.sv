`timescale 1ns/1ps
module tb_bin_a_7seg;

    logic [3:0] datos_i;
    logic [6:0] seg_o;

    module_bin_a_7seg DUT (.datos_i(datos_i), .seg_o(seg_o));

    // Tabla esperada (activa en bajo): a b c d e f g  ->  se compara bit a bit
    // 0..F en orden, segun la tabla estandar de 7 segmentos en hexadecimal
    logic [6:0] esperado [0:15];
    initial begin
        esperado[0]  = 7'b1000000; esperado[1]  = 7'b1111001;
        esperado[2]  = 7'b0100100; esperado[3]  = 7'b0110000;
        esperado[4]  = 7'b0011001; esperado[5]  = 7'b0010010;
        esperado[6]  = 7'b0000010; esperado[7]  = 7'b1111000;
        esperado[8]  = 7'b0000000; esperado[9]  = 7'b0010000;
        esperado[10] = 7'b0001000; esperado[11] = 7'b0000011;
        esperado[12] = 7'b1000110; esperado[13] = 7'b0100001;
        esperado[14] = 7'b0000110; esperado[15] = 7'b0001110;
    end

    integer i;
    integer errores;
    initial begin
        errores = 0;
        $display("=== TB module_bin_a_7seg ===");
        for (i = 0; i < 16; i = i + 1) begin
            datos_i = i[3:0];
            #5;
            if (seg_o !== esperado[i]) begin
                errores = errores + 1;
                $display("FALLO dato=%0d (0x%0h): seg_o=%b esperado=%b", i, i, seg_o, esperado[i]);
            end else begin
                $display("OK    dato=%0d (0x%0h): seg_o=%b", i, i, seg_o);
            end
        end
        if (errores == 0)
            $display("*** TODAS LAS PRUEBAS PASARON ***");
        else
            $display("*** %0d PRUEBA(S) FALLARON ***", errores);
        $finish;
    end

endmodule
