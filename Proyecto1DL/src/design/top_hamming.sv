// ============================================================================
// TOP DEL RECEPTOR  --  EL-3307 Proyecto corto I
// Tang Nano 9K #2 (GW1NR-LV9QN88PC6/I5)
//
// Contiene lo que va DENTRO de la FPGA del receptor:
//   7.3  module_corrector      -> corrección SEC / detección DED
//   7.4  module_display_7seg   -> despliegue en LEDs y en los dos 7 segmentos
//
// Lo que NO está aquí (va alambrado con 74HC86 en la protoboard):
//   7.1  verificador de paridad total de la palabra recibida  -> p_total_i
//   7.2  generador del síndrome de Hamming (7,4)              -> sind_i
//
// CONVENCIÓN DE BITS (índice del puerto = posición Hamming - 1):
//   rx_i[0] = posición 1 = p1        rx_i[4] = posición 5 = d2
//   rx_i[1] = posición 2 = p2        rx_i[5] = posición 6 = d3
//   rx_i[2] = posición 3 = d1        rx_i[6] = posición 7 = d4
//   rx_i[3] = posición 4 = p4        rx_i[7] = posición 8 = p0 (DED)
//
// Los LEDs de la tarjeta son ACTIVOS EN BAJO (ánodo a la fuente, cátodo al
// pin de la FPGA), por eso la palabra corregida se invierte antes de sacarla.
// ============================================================================

module top_receptor (
    // --- Enlace de 8 líneas desde la FPGA del transmisor (GND común) ---
    input  logic [7:0] rx_i,
    // --- Desde los circuitos físicos 74HC86 del receptor ---
    input  logic [2:0] sind_i,        // síndrome (módulo 7.2)
    input  logic       p_total_i,     // paridad total, 1 = impar (módulo 7.1)
    // --- Conmutador de selección de display ---
    input  logic       disp_mode_i,
    // --- Displays de 7 segmentos en protoboard ---
    output logic [6:0] catodo_o,      // segmentos a..g, activo en bajo
    output logic [1:0] anodo_o,       // transistores PNP, activo en bajo
    // --- LEDs de la propia tarjeta Tang Nano 9K (activos en bajo) ---
    output logic [3:0] led_o,         // palabra de 4 bits ya corregida
    output logic       led_ded_o      // encendido = doble error detectado
);

    // ------------------------------------------------------------------
    // 7.3 - Corrección del error
    // ------------------------------------------------------------------
    logic [6:0] corr;
    logic [3:0] datos_corregidos;
    logic       ded;

    module_corrector U_CORR (
        .rx_ham_i  (rx_i[6:0]),      // posiciones 1..7
        .sind_i    (sind_i),
        .p_total_i (p_total_i),
        .corr_o    (corr),
        .datos_o   (datos_corregidos),
        .ded_o     (ded)
    );

    // ------------------------------------------------------------------
    // 7.4 - Despliegue
    // El primer display muestra la palabra recibida SIN corregir, para poder
    // comparar a simple vista contra los LEDs, que muestran la corregida.
    // ------------------------------------------------------------------
    logic [3:0] datos_recibidos;
    assign datos_recibidos[0] = rx_i[2];   // d1 recibido (posición 3)
    assign datos_recibidos[1] = rx_i[4];   // d2 recibido (posición 5)
    assign datos_recibidos[2] = rx_i[5];   // d3 recibido (posición 6)
    assign datos_recibidos[3] = rx_i[6];   // d4 recibido (posición 7)

    module_display_7seg U_DISP (
        .dato_recibido_i (datos_recibidos),
        .sind_i          (sind_i),
        .disp_mode_i     (disp_mode_i),
        .catodo_o        (catodo_o),
        .anodo_o         (anodo_o)
    );

    // ------------------------------------------------------------------
    // LEDs de la tarjeta (activos en bajo)
    // ------------------------------------------------------------------
    assign led_o     = ~datos_corregidos;
    assign led_ded_o = ~ded;

    // rx_i[7] (bit DED recibido) llega al header para poder medirlo, pero la
    // lógica no lo necesita: su información ya viene condensada en p_total_i,
    // que calcula el circuito físico 7.1 sobre los 8 bits.

endmodule
