// ============================================================================
// TOP UNIFICADO  --  EL-3307 Diseno Logico, Proyecto corto I
// Tang Nano 9K (GW1NR-LV9QN88PC6/I5)
//
// UN SOLO bitstream sirve para las dos tarjetas. La entrada modo_i decide si
// esa tarjeta se comporta como TRANSMISOR o como RECEPTOR:
//
//   modo_i = 0  ->  TRANSMISOR  (jumper de J6-19 a GND)
//   modo_i = 1  ->  RECEPTOR    (sin jumper: el pull-up interno lo deja en 1)
//
// El valor por defecto (sin jumper) es RECEPTOR A PROPOSITO: en modo receptor
// las 8 lineas del enlace quedan en ALTA IMPEDANCIA, de modo que si alguien
// enciende las dos tarjetas sin configurar nada, ninguna de las dos maneja el
// bus y no hay contencion entre salidas.
//
// ---------------------------------------------------------------------------
// LO QUE VA EN LA FPGA
//   modo TRANSMISOR:  5.3 module_bin_a_7seg      (dentro de module_display_7seg)
//                     5.4 module_generador_error
//   modo RECEPTOR:    7.3 module_corrector
//                     7.4 module_display_7seg
//
// LO QUE VA ALAMBRADO CON 74HC86 EN LA PROTOBOARD (no esta aqui)
//   5.1 codificador Hamming (7,4) con paridad par
//   5.2 generador del octavo bit (paridad DED)
//   7.1 verificador de paridad total de los 8 bits recibidos
//   7.2 generador del sindrome
//
// ---------------------------------------------------------------------------
// CONVENCION DE BITS (indice del bus = posicion Hamming - 1)
//   pos 1 = p1   pos 2 = p2   pos 3 = d1   pos 4 = p4
//   pos 5 = d2   pos 6 = d3   pos 7 = d4   pos 8 = p0 (paridad DED)
//
// ---------------------------------------------------------------------------
// BUS FISICO COMPARTIDO (fis_i)
// Cada tarjeta se conecta a una protoboard distinta, asi que los mismos 8
// pines cambian de significado segun el modo:
//
//   pin            modo TRANSMISOR            modo RECEPTOR
//   ------------   ------------------------   --------------------------
//   fis_i[0]  38   pos 1 = p1   (de 5.1)      sindrome s1  (de 7.2)
//   fis_i[1]  37   pos 2 = p2   (de 5.1)      sindrome s2  (de 7.2)
//   fis_i[2]  36   pos 3 = d1   (de 5.1)      sindrome s4  (de 7.2)
//   fis_i[3]  39   pos 4 = p4   (de 5.1)      paridad total (de 7.1)
//   fis_i[4]  40   pos 5 = d2   (de 5.1)      -- sin usar --
//   fis_i[5]  35   pos 6 = d3   (de 5.1)      -- sin usar --
//   fis_i[6]  57   pos 7 = d4   (de 5.1)      -- sin usar --
//   fis_i[7]  63   pos 8 = p0   (de 5.2)      -- sin usar --
//
// Estos 8 pines son EXACTAMENTE los mismos que usaban transmisor.cst y
// receptor.cst por separado, asi que ninguna de las dos protoboards se
// vuelve a alambrar.
//
// ---------------------------------------------------------------------------
// SELECTORES DE ERROR (err1_n_i, err2_n_i) -- SOLO MODO TRANSMISOR
// Van en el banco de 1.8 V porque ya no caben pines de 3.3 V (ver el informe).
// Por eso NO se alambran como la figura 1 del enunciado (switch a Vdd con
// resistencia de pull-down): se alambran del pin DIRECTO A GND, aprovechando
// el pull-up interno de la FPGA.
//
//   switch abierto  -> el pull-up deja el pin en 1 -> bit invertido = 0
//   switch cerrado  -> el pin queda en 0           -> bit invertido = 1
//
// Con los tres switches abiertos el selector vale 000 = "no insertar error",
// que es justo el valor de reposo que uno quiere.
//
// PELIGRO: estos seis pines son de 1.8 V. NUNCA conectarlos a 3.3 V ni a la
// salida de un 74HC86; solo el switch contra GND.
//
// ---------------------------------------------------------------------------
// ESTILO: todo el diseno es COMBINACIONAL. No hay reloj, ni flip-flops, ni
// registros. Los multiplexores y decodificadores estan escritos con
// ecuaciones de Boole (assign con & | ~), sin case ni casez.
//
// La unica excepcion son las ocho primitivas bufif1 del enlace: la alta
// impedancia no es un valor booleano y no se puede expresar con & | ~. bufif1
// es una primitiva de compuerta de Verilog (no un constructo avanzado de
// SystemVerilog) y yosys la mapea directo a los IOBUF del chip.
// ============================================================================

module top_hamming (
    // ---- Seleccion de modo ----
    input  logic       modo_i,        // 0 = transmisor, 1 = receptor

    // ---- Bus compartido hacia la protoboard de 74HC86 (3.3 V) ----
    input  logic [7:0] fis_i,

    // ---- Selectores de posicion de error, activos en bajo (1.8 V) ----
    input  logic [2:0] err1_n_i,      // solo se usa en modo transmisor
    input  logic [2:0] err2_n_i,      // solo se usa en modo transmisor

    // ---- Boton S1 de la propia tarjeta, momentaneo y activo en bajo ----
    input  logic       btn_disp_n_i,  // presionado = 0 = mostrar el sindrome

    // ---- Enlace de 8 lineas entre las dos tarjetas (GND comun) ----
    inout  wire  [7:0] enlace_io,     // salida en modo TX, alta-Z en modo RX

    // ---- Dos displays de 7 segmentos en protoboard ----
    output logic [6:0] catodo_o,      // segmentos a..g compartidos, activo en bajo
    output logic [1:0] anodo_o,       // bases de los PNP, activo en bajo

    // ---- LEDs de la propia tarjeta (activos en bajo) ----
    output logic [3:0] led_o,
    output logic       led_ded_o
);

    // ------------------------------------------------------------------
    // Decodificacion del modo
    // ------------------------------------------------------------------
    logic modo_tx, modo_rx;
    assign modo_tx = ~modo_i;
    assign modo_rx =  modo_i;

    // ------------------------------------------------------------------
    // Selectores de error: los switches son activos en bajo, se invierten
    // para recuperar el numero de posicion (0 = sin error, 1..7 = posicion)
    // ------------------------------------------------------------------
    logic [2:0] err1, err2;
    assign err1[0] = ~err1_n_i[0];
    assign err1[1] = ~err1_n_i[1];
    assign err1[2] = ~err1_n_i[2];
    assign err2[0] = ~err2_n_i[0];
    assign err2[1] = ~err2_n_i[1];
    assign err2[2] = ~err2_n_i[2];

    // ==================================================================
    // CAMINO DE TRANSMISION  (activo cuando modo_i = 0)
    // ==================================================================

    // ---- 5.4 Generador de error --------------------------------------
    // fis_i[6:0] son las posiciones 1..7 que entrega el codificador fisico,
    // fis_i[7] es el octavo bit (paridad DED) que entrega el modulo 5.2.
    logic [7:1] pal_err;
    logic       ded_err;

    module_generador_error U_ERROR (
        .pal_cod_i  (fis_i[6:0]),   // [6:0] -> [7:1] por posicion de bit
        .ded_i      (fis_i[7]),
        .pos_err1_i (err1),
        .pos_err2_i (err2),
        .pal_err_o  (pal_err),
        .ded_o      (ded_err)
    );

    logic [7:0] tx_val;
    assign tx_val[6:0] = pal_err;    // posiciones 1..7 ya con el/los error(es)
    assign tx_val[7]   = ded_err;    // posicion 8 (DED) pasa sin modificar

    // ---- Buffers tri-state del enlace ---------------------------------
    // Manejan la linea solo en modo transmisor; en modo receptor quedan en
    // alta impedancia y la linea la sostienen las resistencias de pull-down
    // de la protoboard.
    bufif1 U_IO0 (enlace_io[0], tx_val[0], modo_tx);
    bufif1 U_IO1 (enlace_io[1], tx_val[1], modo_tx);
    bufif1 U_IO2 (enlace_io[2], tx_val[2], modo_tx);
    bufif1 U_IO3 (enlace_io[3], tx_val[3], modo_tx);
    bufif1 U_IO4 (enlace_io[4], tx_val[4], modo_tx);
    bufif1 U_IO5 (enlace_io[5], tx_val[5], modo_tx);
    bufif1 U_IO6 (enlace_io[6], tx_val[6], modo_tx);
    bufif1 U_IO7 (enlace_io[7], tx_val[7], modo_tx);

    // ==================================================================
    // CAMINO DE RECEPCION  (activo cuando modo_i = 1)
    // ==================================================================

    // ---- Palabra que llega por el enlace ------------------------------
    logic [7:0] rx;
    assign rx = enlace_io;

    // ---- Resultados de los bloques fisicos 7.1 y 7.2 ------------------
    logic [2:0] sind;
    logic       p_total;
    assign sind[0] = fis_i[0];       // s1
    assign sind[1] = fis_i[1];       // s2
    assign sind[2] = fis_i[2];       // s4
    assign p_total = fis_i[3];       // 1 = paridad impar = "mal"

    // ---- 7.3 Correccion SEC / deteccion DED ---------------------------
    logic [6:0] corr;
    logic [3:0] datos_corregidos;
    logic       ded;

    module_corrector U_CORR (
        .rx_ham_i  (rx[6:0]),
        .sind_i    (sind),
        .p_total_i (p_total),
        .corr_o    (corr),
        .datos_o   (datos_corregidos),
        .ded_o     (ded)
    );

    // ==================================================================
    // DESPLIEGUE EN LOS DOS 7 SEGMENTOS  (7.4, y 5.3 en modo transmisor)
    // ==================================================================

    // ---- Los 4 bits de datos estan en las posiciones 3, 5, 6 y 7 ------
    // En modo transmisor se toman del bus fisico: esas lineas SON los cables
    // de los switches de datos (en el codificador pasan directo, sin
    // compuerta), asi que el usuario ve la palabra que acaba de ingresar.
    logic [3:0] dato_tx;
    assign dato_tx[0] = fis_i[2];    // d1 = posicion 3
    assign dato_tx[1] = fis_i[4];    // d2 = posicion 5
    assign dato_tx[2] = fis_i[5];    // d3 = posicion 6
    assign dato_tx[3] = fis_i[6];    // d4 = posicion 7

    // En modo receptor se toman del enlace, SIN corregir, tal como pide el
    // enunciado ("los 7 segmentos desplegaran la palabra recibida").
    logic [3:0] dato_rx;
    assign dato_rx[0] = rx[2];       // d1 recibido
    assign dato_rx[1] = rx[4];       // d2 recibido
    assign dato_rx[2] = rx[5];       // d3 recibido
    assign dato_rx[3] = rx[6];       // d4 recibido

    // ---- MUX 2:1 de modo, como suma de productos ----------------------
    logic [3:0] palabra;
    assign palabra[0] = (modo_tx & dato_tx[0]) | (modo_rx & dato_rx[0]);
    assign palabra[1] = (modo_tx & dato_tx[1]) | (modo_rx & dato_rx[1]);
    assign palabra[2] = (modo_tx & dato_tx[2]) | (modo_rx & dato_rx[2]);
    assign palabra[3] = (modo_tx & dato_tx[3]) | (modo_rx & dato_rx[3]);

    // ---- Que display se enciende --------------------------------------
    // El sindrome solo tiene sentido en el receptor, asi que en modo
    // transmisor el boton no hace nada y siempre se ve la palabra.
    logic sel_sind;
    assign sel_sind = modo_rx & ~btn_disp_n_i;

    module_display_7seg U_DISP (
        .palabra_i  (palabra),
        .sind_i     (sind),
        .sel_sind_i (sel_sind),
        .catodo_o   (catodo_o),
        .anodo_o    (anodo_o)
    );

    // ==================================================================
    // LEDs DE LA TARJETA (activos en bajo)
    //   modo transmisor: la palabra de 4 bits que se esta enviando
    //   modo receptor  : la palabra de 4 bits ya CORREGIDA (SEC)
    //   led_ded_o      : solo en modo receptor, aviso de doble error (DED)
    // ==================================================================
    logic [3:0] led_dato;
    assign led_dato[0] = (modo_tx & dato_tx[0]) | (modo_rx & datos_corregidos[0]);
    assign led_dato[1] = (modo_tx & dato_tx[1]) | (modo_rx & datos_corregidos[1]);
    assign led_dato[2] = (modo_tx & dato_tx[2]) | (modo_rx & datos_corregidos[2]);
    assign led_dato[3] = (modo_tx & dato_tx[3]) | (modo_rx & datos_corregidos[3]);

    assign led_o[0] = ~led_dato[0];
    assign led_o[1] = ~led_dato[1];
    assign led_o[2] = ~led_dato[2];
    assign led_o[3] = ~led_dato[3];

    assign led_ded_o = ~(modo_rx & ded);

endmodule
