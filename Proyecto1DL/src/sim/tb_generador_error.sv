`timescale 1ns/1ps
module tb_generador_error;

    logic [7:1] pal_cod_i;
    logic        ded_i;
    logic [2:0]  pos_err1_i, pos_err2_i;
    logic [7:1] pal_err_o;
    logic        ded_o;

    module_generador_error DUT (
        .pal_cod_i (pal_cod_i),
        .ded_i      (ded_i),
        .pos_err1_i (pos_err1_i),
        .pos_err2_i (pos_err2_i),
        .pal_err_o  (pal_err_o),
        .ded_o       (ded_o)
    );

    integer errores;

    task check(input [7:1] esperado_pal, input esperado_ded, input string caso);
        begin
            #5;
            if (pal_err_o !== esperado_pal || ded_o !== esperado_ded) begin
                errores = errores + 1;
                $display("FALLO [%s]: pal_err_o=%b ded_o=%b  (esperado pal=%b ded=%b)",
                          caso, pal_err_o, ded_o, esperado_pal, esperado_ded);
            end else begin
                $display("OK    [%s]: pal_err_o=%b ded_o=%b", caso, pal_err_o, ded_o);
            end
        end
    endtask

    initial begin
        errores = 0;
        $display("=== TB module_generador_error ===");

        pal_cod_i = 7'b1010101; ded_i = 1'b0;

        // Caso 1: sin error (000, 000) -> pasa igual
        pos_err1_i = 3'b000; pos_err2_i = 3'b000;
        check(7'b1010101, 1'b0, "sin_error");

        // Caso 2: un solo error en posicion 3
        pos_err1_i = 3'b011; pos_err2_i = 3'b000;
        check(7'b1010101 ^ 7'b0000100, 1'b0, "error_pos3");

        // Caso 3: dos errores, posiciones 1 y 7
        pos_err1_i = 3'b001; pos_err2_i = 3'b111;
        check(7'b1010101 ^ 7'b1000001, 1'b0, "error_pos1_y_7");

        // Caso 4: dos selectores apuntan a la MISMA posicion -> se cancelan
        pos_err1_i = 3'b101; pos_err2_i = 3'b101;
        check(7'b1010101, 1'b0, "errores_iguales_se_cancelan");

        // Caso 5: ded_i debe pasar sin cambio (1) mientras hay error en pal
        ded_i = 1'b1;
        pos_err1_i = 3'b010; pos_err2_i = 3'b000;
        check(7'b1010101 ^ 7'b0000010, 1'b1, "ded_pasa_sin_cambio");

        if (errores == 0)
            $display("*** TODAS LAS PRUEBAS PASARON ***");
        else
            $display("*** %0d PRUEBA(S) FALLARON ***", errores);
        $finish;
    end

endmodule
