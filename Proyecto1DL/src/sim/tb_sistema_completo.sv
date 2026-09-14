`timescale 1ns/1ps
// ============================================================================
// TESTBENCH DEL SISTEMA COMPLETO  --  EL-3307 Proyecto corto I
//
// Ahora hay UN SOLO top (top_hamming) y un solo bitstream, asi que este
// testbench instancia DOS VECES el mismo modulo, igual que las dos tarjetas
// reales, y las conecta por el enlace de 8 lineas:
//
//   switches -> [5.1/5.2 con 74HC86] -> [TARJETA A, modo_i=0] ==enlace==>
//            -> [7.1/7.2 con 74HC86] -> [TARJETA B, modo_i=1] -> LEDs y 7seg
//
// El enlace se declara como "tri0" para modelar las resistencias de pull-down
// de la protoboard: si ninguna tarjeta lo maneja, la linea cae a 0. Eso es lo
// que permite comprobar que los buffers tri-state de verdad sueltan el bus en
// modo receptor.
//
// Recorre las 16 palabras de datos posibles y, para cada una:
//   - sin error            : los LEDs muestran la palabra original, DED apagado
//   - 1 error en pos 1..7  : el receptor CORRIGE y el sindrome apunta
//                            exactamente a la posicion danada
//   - 2 errores distintos  : el receptor enciende el aviso de doble error
// Ademas comprueba:
//   - el display del transmisor (modulo 5.3)
//   - el multiplexado de los dos displays del receptor con el boton S1
//   - que el boton no hace nada en modo transmisor
//   - que en modo receptor las 8 lineas quedan en alta impedancia
//
// Nota de estilo: no usa el tipo "string" ni $sformatf, porque la version
// 13.0-devel de Icarus Verilog del oss-cad-suite falla con una asercion al
// compilarlos. Los casos se identifican imprimiendo los valores numericos.
// ============================================================================
module tb_sistema_completo;

    // ---- Estimulos ----
    logic [3:0] datos;
    logic [2:0] err1_n, err2_n;      // selectores de error, ACTIVOS EN BAJO
    logic       btn_a_n, btn_b_n;    // boton S1 de cada tarjeta, activo en bajo
    logic       modo_a, modo_b;      // 0 = transmisor, 1 = receptor

    // ---- Enlace de 8 lineas con pull-down (resistencias de la protoboard) ----
    tri0 [7:0] enlace;

    // ======================================================================
    // TARJETA A  --  configurada como TRANSMISOR (modo_a = 0)
    // ======================================================================

    // Bloques fisicos 5.1 + 5.2, modelados compuerta por compuerta (74HC86)
    logic [7:1] pal_cod;
    logic       ded_fis;
    module_hamming74_estructural U_A_FIS (
        .datos_i   (datos),
        .pal_cod_o (pal_cod),
        .ded_o     (ded_fis)
    );

    // Bus fisico que entra a la tarjeta A
    logic [7:0] fis_a;
    assign fis_a[6:0] = pal_cod;     // posiciones 1..7
    assign fis_a[7]   = ded_fis;     // posicion 8

    logic [6:0] catodo_a;
    logic [1:0] anodo_a;
    logic [3:0] led_a;
    logic       led_ded_a;

    top_hamming U_A (
        .modo_i       (modo_a),
        .fis_i        (fis_a),
        .err1_n_i     (err1_n),
        .err2_n_i     (err2_n),
        .btn_disp_n_i (btn_a_n),
        .enlace_io    (enlace),
        .catodo_o     (catodo_a),
        .anodo_o      (anodo_a),
        .led_o        (led_a),
        .led_ded_o    (led_ded_a)
    );

    // ======================================================================
    // TARJETA B  --  configurada como RECEPTOR (modo_b = 1)
    // ======================================================================

    // Bloques fisicos 7.1 + 7.2, modelados compuerta por compuerta (74HC86)
    logic [2:0] sind;
    logic       p_total;
    modelo_receptor_fisico U_B_FIS (
        .rx_i      (enlace),
        .sind_o    (sind),
        .p_total_o (p_total)
    );

    // Bus fisico que entra a la tarjeta B
    logic [7:0] fis_b;
    assign fis_b[2:0] = sind;        // sindrome del modulo 7.2
    assign fis_b[3]   = p_total;     // paridad total del modulo 7.1
    assign fis_b[7:4] = 4'b0000;     // esos cuatro pines no se usan en receptor

    logic [6:0] catodo_b;
    logic [1:0] anodo_b;
    logic [3:0] led_b;
    logic       led_ded_b;

    top_hamming U_B (
        .modo_i       (modo_b),
        .fis_i        (fis_b),
        .err1_n_i     (3'b111),      // sin switches de error en el receptor
        .err2_n_i     (3'b111),
        .btn_disp_n_i (btn_b_n),
        .enlace_io    (enlace),
        .catodo_o     (catodo_b),
        .anodo_o      (anodo_b),
        .led_o        (led_b),
        .led_ded_o    (led_ded_b)
    );

    // ======================================================================
    // Decodificadores de referencia para comprobar los 7 segmentos
    // ======================================================================
    logic [3:0] ref_nibble;
    logic [6:0] ref_seg;
    module_bin_a_7seg U_REF (.datos_i(ref_nibble), .seg_o(ref_seg));

    logic [6:0] ref_seg_tx;
    module_bin_a_7seg U_REF_TX (.datos_i(datos), .seg_o(ref_seg_tx));

    // Los LEDs son activos en bajo
    wire [3:0] palabra_corregida = ~led_b;
    wire       hay_ded           = ~led_ded_b;
    wire [3:0] palabra_tx_leds   = ~led_a;

    integer d, k1, k2, fallos;

    // ----------------------------------------------------------------------
    // Comprueba el resultado del receptor para un caso dado.
    // dato_n, pos1 y pos2 solo sirven para poder identificar el caso si falla.
    // ----------------------------------------------------------------------
    task automatic revisa(input integer dato_n,
                          input integer pos1,
                          input integer pos2,
                          input [3:0]   esperado_dato,
                          input         esperado_ded,
                          input [2:0]   esperado_sind);
        begin
            #2;
            if (palabra_corregida !== esperado_dato) begin
                fallos = fallos + 1;
                $display("FALLO dato=%0h err1=%0d err2=%0d : LEDs=%b esperado=%b",
                          dato_n, pos1, pos2, palabra_corregida, esperado_dato);
            end
            if (hay_ded !== esperado_ded) begin
                fallos = fallos + 1;
                $display("FALLO dato=%0h err1=%0d err2=%0d : LED de doble error=%b esperado=%b",
                          dato_n, pos1, pos2, hay_ded, esperado_ded);
            end
            if (sind !== esperado_sind) begin
                fallos = fallos + 1;
                $display("FALLO dato=%0h err1=%0d err2=%0d : sindrome=%b esperado=%b",
                          dato_n, pos1, pos2, sind, esperado_sind);
            end
        end
    endtask

    initial begin
        fallos  = 0;
        modo_a  = 1'b0;      // tarjeta A = TRANSMISOR
        modo_b  = 1'b1;      // tarjeta B = RECEPTOR
        btn_a_n = 1'b1;      // boton suelto
        btn_b_n = 1'b1;      // boton suelto
        err1_n  = 3'b111;    // switches abiertos = sin error
        err2_n  = 3'b111;

        $display("=== TB del sistema completo (dos instancias de top_hamming) ===");
        $dumpfile("sistema_completo_tb.vcd");
        $dumpvars(0, tb_sistema_completo);

        for (d = 0; d < 16; d = d + 1) begin
            datos = d[3:0];

            // ---------- sin error ----------
            err1_n = 3'b111; err2_n = 3'b111;
            revisa(d, 0, 0, d[3:0], 1'b0, 3'b000);

            // el display del transmisor siempre muestra la palabra ingresada
            if (catodo_a !== ref_seg_tx) begin
                fallos = fallos + 1;
                $display("FALLO [7seg transmisor, dato=%0h]: catodo=%b esperado=%b",
                          d, catodo_a, ref_seg_tx);
            end
            // y sus LEDs tambien
            if (palabra_tx_leds !== d[3:0]) begin
                fallos = fallos + 1;
                $display("FALLO [LEDs transmisor, dato=%0h]: LEDs=%b esperado=%b",
                          d, palabra_tx_leds, d[3:0]);
            end
            // el aviso de DED nunca se enciende en el transmisor
            if (led_ded_a !== 1'b1) begin
                fallos = fallos + 1;
                $display("FALLO [dato=%0h]: el LED de DED del transmisor no esta apagado", d);
            end

            // ---------- un error en cada posicion 1..7 ----------
            for (k1 = 1; k1 <= 7; k1 = k1 + 1) begin
                err1_n = ~k1[2:0];   // los switches son activos en bajo
                err2_n = 3'b111;
                // la palabra corregida debe volver a ser la original, sin aviso
                // de DED, y el sindrome debe valer exactamente la posicion danada
                revisa(d, k1, 0, d[3:0], 1'b0, k1[2:0]);
            end

            // ---------- dos errores en posiciones distintas ----------
            for (k1 = 1; k1 <= 7; k1 = k1 + 1) begin
                for (k2 = k1 + 1; k2 <= 7; k2 = k2 + 1) begin
                    err1_n = ~k1[2:0];
                    err2_n = ~k2[2:0];
                    #2;
                    if (hay_ded !== 1'b1) begin
                        fallos = fallos + 1;
                        $display("FALLO [dato=%0h errores en %0d y %0d]: no se detecto el doble error",
                                  d, k1, k2);
                    end
                end
            end
        end

        // ==================================================================
        // Multiplexado de los dos displays del receptor con el boton S1
        // ==================================================================
        $display("--- prueba del multiplexado de los dos 7 segmentos ---");
        datos  = 4'hB;
        err1_n = ~3'd5;      // un error en la posicion 5
        err2_n = 3'b111;
        #2;

        // boton SUELTO -> display 0 -> palabra recibida SIN corregir
        btn_b_n = 1'b1; #2;
        ref_nibble = {enlace[6], enlace[5], enlace[4], enlace[2]};
        #2;
        if (anodo_b !== 2'b10 || catodo_b !== ref_seg) begin
            fallos = fallos + 1;
            $display("FALLO [display 0]: anodo=%b catodo=%b (esperado anodo=10 catodo=%b)",
                      anodo_b, catodo_b, ref_seg);
        end else begin
            $display("OK [display 0]: boton suelto -> palabra recibida sin corregir, anodo=%b", anodo_b);
        end

        // boton PRESIONADO -> display 1 -> sindrome
        btn_b_n = 1'b0; #2;
        ref_nibble = {1'b0, sind};
        #2;
        if (anodo_b !== 2'b01 || catodo_b !== ref_seg) begin
            fallos = fallos + 1;
            $display("FALLO [display 1]: anodo=%b catodo=%b (esperado anodo=01 catodo=%b)",
                      anodo_b, catodo_b, ref_seg);
        end else begin
            $display("OK [display 1]: boton presionado -> sindrome (%0d), anodo=%b", sind, anodo_b);
        end

        // nunca se encienden los dos displays a la vez
        if (anodo_b[0] === anodo_b[1]) begin
            fallos = fallos + 1;
            $display("FALLO: los dos anodos quedaron en el mismo nivel (%b)", anodo_b);
        end

        // el boton NO debe hacer nada en modo transmisor
        btn_a_n = 1'b0; #2;
        if (anodo_a !== 2'b10 || catodo_a !== ref_seg_tx) begin
            fallos = fallos + 1;
            $display("FALLO [boton en transmisor]: anodo=%b catodo=%b (esperado anodo=10 catodo=%b)",
                      anodo_a, catodo_a, ref_seg_tx);
        end else begin
            $display("OK [boton en transmisor]: no cambia nada, sigue mostrando la palabra");
        end
        btn_a_n = 1'b1;
        btn_b_n = 1'b1;

        // ==================================================================
        // Buffers tri-state: en modo receptor la tarjeta debe soltar el bus
        // ==================================================================
        $display("--- prueba de los buffers tri-state del enlace ---");
        datos  = 4'hF;
        err1_n = 3'b111;
        err2_n = 3'b111;
        #2;

        // con A en transmisor, el enlace lleva la palabra codificada
        if (enlace === 8'h00) begin
            fallos = fallos + 1;
            $display("FALLO: con la tarjeta A en modo transmisor el enlace quedo en 0");
        end else begin
            $display("OK [tri-state]: A en modo transmisor maneja el enlace = %b", enlace);
        end

        // ahora las DOS en modo receptor: nadie maneja el bus y los pull-down
        // de la protoboard lo deben llevar a 0
        modo_a = 1'b1;
        modo_b = 1'b1;
        #4;
        if (enlace !== 8'h00) begin
            fallos = fallos + 1;
            $display("FALLO: con las dos tarjetas en modo receptor el enlace vale %b, se esperaba 00000000 (alta impedancia + pull-down)",
                      enlace);
        end else begin
            $display("OK [tri-state]: las dos en modo receptor -> enlace en alta impedancia, los pull-down lo dejan en 00000000");
        end

        // volver a la configuracion normal
        modo_a = 1'b0;
        modo_b = 1'b1;
        #4;

        if (fallos == 0)
            $display("*** SISTEMA COMPLETO OK: 16 palabras x (sin error + 7 SEC + 21 DED) sin fallos ***");
        else
            $display("*** %0d FALLO(S) ***", fallos);
        $finish;
    end

endmodule
