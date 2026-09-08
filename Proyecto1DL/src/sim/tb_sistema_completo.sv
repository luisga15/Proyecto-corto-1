`timescale 1ns/1ps
// ============================================================================
// TESTBENCH DEL SISTEMA COMPLETO
//   switches -> [5.1/5.2 físico] -> [FPGA transmisor] -> enlace de 8 líneas
//            -> [7.1/7.2 físico] -> [FPGA receptor] -> LEDs y 7 segmentos
//
// Recorre las 16 palabras de datos posibles y, para cada una:
//   - sin error            : los LEDs deben mostrar la palabra original y DED apagado
//   - 1 error en pos 1..7  : el receptor debe CORREGIR y el síndrome debe apuntar
//                            exactamente a la posición dañada
//   - 2 errores distintos  : el receptor debe ENCENDER el aviso de doble error
// Además comprueba el multiplexado de los dos displays de 7 segmentos.
// ============================================================================
module tb_sistema_completo;

    logic [3:0] datos;
    logic [2:0] err1, err2;
    logic       disp_mode;

    // ---- Transmisor: codificador físico (5.1 + 5.2) ----
    logic [7:1] pal_cod;
    logic       ded_fis;
    modelo_hamming_verificacion U_TX_FIS (
        .datos_i   (datos),
        .pal_cod_o (pal_cod),
        .ded_o     (ded_fis)
    );

    // ---- Transmisor: FPGA (5.3 + 5.4) ----
    logic [7:0] enlace;
    logic [6:0] catodo_tx;
    top_transmisor U_TX_FPGA (
        .ham_i    (pal_cod),
        .ded_i    (ded_fis),
        .err1_i   (err1),
        .err2_i   (err2),
        .tx_o     (enlace),
        .catodo_o (catodo_tx)
    );

    // ---- Receptor: circuitos físicos (7.1 + 7.2) ----
    logic [2:0] sind;
    logic       p_total;
    modelo_receptor_fisico U_RX_FIS (
        .rx_i      (enlace),
        .sind_o    (sind),
        .p_total_o (p_total)
    );

    // ---- Receptor: FPGA (7.3 + 7.4) ----
    logic [6:0] catodo_rx;
    logic [1:0] anodo_rx;
    logic [3:0] led;
    logic       led_ded;
    top_receptor U_RX_FPGA (
        .rx_i        (enlace),
        .sind_i      (sind),
        .p_total_i   (p_total),
        .disp_mode_i (disp_mode),
        .catodo_o    (catodo_rx),
        .anodo_o     (anodo_rx),
        .led_o       (led),
        .led_ded_o   (led_ded)
    );

    // ---- Decodificadores de referencia para comprobar los 7 segmentos ----
    logic [3:0] ref_nibble;
    logic [6:0] ref_seg;
    module_bin_a_7seg U_REF (.datos_i(ref_nibble), .seg_o(ref_seg));

    logic [6:0] ref_seg_tx;
    module_bin_a_7seg U_REF_TX (.datos_i(datos), .seg_o(ref_seg_tx));

    // Los LEDs son activos en bajo: la palabra corregida es ~led
    wire [3:0] palabra_corregida = ~led;
    wire       hay_ded           = ~led_ded;

    integer d, k1, k2, fallos;

    task automatic revisa(input string caso,
                          input [3:0] esperado_dato,
                          input       esperado_ded,
                          input [2:0] esperado_sind);
        begin
            #2;
            if (palabra_corregida !== esperado_dato) begin
                fallos = fallos + 1;
                $display("FALLO [%s]: LEDs=%b esperado=%b", caso, palabra_corregida, esperado_dato);
            end
            if (hay_ded !== esperado_ded) begin
                fallos = fallos + 1;
                $display("FALLO [%s]: LED de doble error=%b esperado=%b", caso, hay_ded, esperado_ded);
            end
            if (sind !== esperado_sind) begin
                fallos = fallos + 1;
                $display("FALLO [%s]: sindrome=%b esperado=%b", caso, sind, esperado_sind);
            end
        end
    endtask

    initial begin
        fallos    = 0;
        disp_mode = 1'b0;
        $display("=== TB del sistema completo (transmisor + receptor) ===");
        $dumpfile("sistema_completo_tb.vcd");
        $dumpvars(0, tb_sistema_completo);

        for (d = 0; d < 16; d = d + 1) begin
            datos = d[3:0];

            // ---------- sin error ----------
            err1 = 3'b000; err2 = 3'b000;
            revisa($sformatf("dato=%0h sin error", d), d[3:0], 1'b0, 3'b000);

            // el display del transmisor siempre muestra la palabra ingresada
            if (catodo_tx !== ref_seg_tx) begin
                fallos = fallos + 1;
                $display("FALLO [7seg transmisor, dato=%0h]: catodo=%b esperado=%b",
                          d, catodo_tx, ref_seg_tx);
            end

            // ---------- un error en cada posición 1..7 ----------
            for (k1 = 1; k1 <= 7; k1 = k1 + 1) begin
                err1 = k1[2:0]; err2 = 3'b000;
                // la palabra corregida debe volver a ser la original, sin aviso de DED,
                // y el síndrome debe valer exactamente la posición dañada
                revisa($sformatf("dato=%0h error en pos %0d", d, k1), d[3:0], 1'b0, k1[2:0]);
            end

            // ---------- dos errores en posiciones distintas ----------
            for (k1 = 1; k1 <= 7; k1 = k1 + 1) begin
                for (k2 = k1 + 1; k2 <= 7; k2 = k2 + 1) begin
                    err1 = k1[2:0]; err2 = k2[2:0];
                    #2;
                    if (hay_ded !== 1'b1) begin
                        fallos = fallos + 1;
                        $display("FALLO [dato=%0h errores en %0d y %0d]: no se detectó el doble error", d, k1, k2);
                    end
                end
            end
        end

        // ---------- comprobación del multiplexado de los 7 segmentos ----------
        datos = 4'hB; err1 = 3'd5; err2 = 3'b000;   // un error en la posición 5
        #2;
        // display 0: palabra recibida SIN corregir
        disp_mode = 1'b0; #2;
        ref_nibble = {enlace[6], enlace[5], enlace[4], enlace[2]};
        #2;
        if (anodo_rx !== 2'b10 || catodo_rx !== ref_seg) begin
            fallos = fallos + 1;
            $display("FALLO [display 0]: anodo=%b catodo=%b (esperado anodo=10 catodo=%b)",
                      anodo_rx, catodo_rx, ref_seg);
        end else begin
            $display("OK [display 0]: muestra la palabra recibida sin corregir, anodo=%b", anodo_rx);
        end
        // display 1: síndrome
        disp_mode = 1'b1; #2;
        ref_nibble = {1'b0, sind};
        #2;
        if (anodo_rx !== 2'b01 || catodo_rx !== ref_seg) begin
            fallos = fallos + 1;
            $display("FALLO [display 1]: anodo=%b catodo=%b (esperado anodo=01 catodo=%b)",
                      anodo_rx, catodo_rx, ref_seg);
        end else begin
            $display("OK [display 1]: muestra el síndrome (%0d), anodo=%b", sind, anodo_rx);
        end

        if (fallos == 0)
            $display("*** SISTEMA COMPLETO OK: 16 palabras x (sin error + 7 SEC + 21 DED) sin fallos ***");
        else
            $display("*** %0d FALLO(S) ***", fallos);
        $finish;
    end

endmodule
