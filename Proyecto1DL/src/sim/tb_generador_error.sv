`timescale 1ns/1ps
// ============================================================================
// TB del modulo 5.4 (generador de error)
//
// Nota de estilo: la version anterior de este testbench pasaba el nombre del
// caso como "input string caso". La version 13.0-devel de Icarus Verilog del
// oss-cad-suite falla con una asercion al compilar el tipo string, asi que
// ahora el caso se identifica con un numero entero y los valores se imprimen
// directamente. Tampoco se usa $sformatf por la misma razon.
// ============================================================================
module tb_generador_error;

    logic [7:1] pal_cod_i;
    logic        ded_i;
    logic [2:0]  pos_err1_i, pos_err2_i;
    logic [7:1] pal_err_o;
    logic        ded_o;

    module_generador_error DUT (
        .pal_cod_i  (pal_cod_i),
        .ded_i      (ded_i),
        .pos_err1_i (pos_err1_i),
        .pos_err2_i (pos_err2_i),
        .pal_err_o  (pal_err_o),
        .ded_o      (ded_o)
    );

    integer errores;

    task check(input integer caso, input [7:1] esperado_pal, input esperado_ded);
        begin
            #5;
            if (pal_err_o !== esperado_pal || ded_o !== esperado_ded) begin
                errores = errores + 1;
                $display("FALLO caso %0d (err1=%0d err2=%0d): pal_err_o=%b ded_o=%b  (esperado pal=%b ded=%b)",
                          caso, pos_err1_i, pos_err2_i, pal_err_o, ded_o, esperado_pal, esperado_ded);
            end else begin
                $display("OK    caso %0d (err1=%0d err2=%0d): pal_err_o=%b ded_o=%b",
                          caso, pos_err1_i, pos_err2_i, pal_err_o, ded_o);
            end
        end
    endtask

    integer k1, k2;
    logic [7:1] esperado;

    initial begin
        errores = 0;
        $display("=== TB module_generador_error ===");

        pal_cod_i = 7'b1010101; ded_i = 1'b0;

        // Caso 1: sin error (000, 000) -> pasa igual
        pos_err1_i = 3'b000; pos_err2_i = 3'b000;
        check(1, 7'b1010101, 1'b0);

        // Caso 2: un solo error en posicion 3
        pos_err1_i = 3'b011; pos_err2_i = 3'b000;
        check(2, 7'b1010101 ^ 7'b0000100, 1'b0);

        // Caso 3: dos errores, posiciones 1 y 7
        pos_err1_i = 3'b001; pos_err2_i = 3'b111;
        check(3, 7'b1010101 ^ 7'b1000001, 1'b0);

        // Caso 4: los dos selectores apuntan a la MISMA posicion.
        // Invertir dos veces el mismo bit lo deja como estaba: no hay error.
        // Es el comportamiento fisicamente correcto; para meter DOS errores
        // hay que escoger dos posiciones distintas.
        pos_err1_i = 3'b101; pos_err2_i = 3'b101;
        check(4, 7'b1010101, 1'b0);

        // Caso 5: ded_i debe pasar sin cambio (1) mientras hay error en pal
        ded_i = 1'b1;
        pos_err1_i = 3'b010; pos_err2_i = 3'b000;
        check(5, 7'b1010101 ^ 7'b0000010, 1'b1);

        // ------------------------------------------------------------------
        // Barrido exhaustivo: las 64 combinaciones de los dos selectores
        // ------------------------------------------------------------------
        $display("--- barrido exhaustivo de los 8x8 valores de los selectores ---");
        ded_i = 1'b0;
        for (k1 = 0; k1 <= 7; k1 = k1 + 1) begin
            for (k2 = 0; k2 <= 7; k2 = k2 + 1) begin
                pos_err1_i = k1[2:0];
                pos_err2_i = k2[2:0];
                #5;
                // Se aplican las dos inversiones tal cual: si los dos
                // selectores coinciden, el bit se invierte dos veces y queda
                // como estaba, que es justo lo que hace el XOR del modulo.
                esperado = pal_cod_i;
                if (k1 != 0) esperado[k1] = ~esperado[k1];
                if (k2 != 0) esperado[k2] = ~esperado[k2];
                if (pal_err_o !== esperado) begin
                    errores = errores + 1;
                    $display("FALLO barrido err1=%0d err2=%0d: pal_err_o=%b esperado=%b",
                              k1, k2, pal_err_o, esperado);
                end
            end
        end
        $display("--- barrido terminado (64 combinaciones) ---");

        if (errores == 0)
            $display("*** TODAS LAS PRUEBAS PASARON ***");
        else
            $display("*** %0d PRUEBA(S) FALLARON ***", errores);
        $finish;
    end

endmodule
