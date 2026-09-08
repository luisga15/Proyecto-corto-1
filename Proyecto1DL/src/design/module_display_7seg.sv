// ============================================================================
// Módulo 7.4 - Despliegue en los dos displays de 7 segmentos del receptor
// EL-3307 Diseño Lógico - Proyecto corto I  --  va DENTRO de la FPGA
//
// Los dos displays comparten los mismos 7 cátodos (a..g). Un conmutador
// (disp_mode_i) decide cuál de los dos transistores PNP se enciende y, al
// mismo tiempo, qué dato se decodifica:
//
//   disp_mode_i = 0 (OFF) -> se enciende el display 0 y muestra la PALABRA
//                            RECIBIDA sin corregir, en hexadecimal
//   disp_mode_i = 1 (ON)  -> se enciende el display 1 y muestra la POSICIÓN
//                            DEL BIT ERRÓNEO (el síndrome), en hexadecimal;
//                            vale 0 si la palabra llegó sin error
//
// Los transistores son PNP con el emisor a 3.3 V: la base se maneja por un
// pin de la FPGA a través de una resistencia, y el transistor CONDUCE cuando
// ese pin está en BAJO. Por eso anodo_o es activo en bajo.
//
// Todo el multiplexado está escrito con ecuaciones de Boole.
// ============================================================================

module module_display_7seg (
    input  logic [3:0] dato_recibido_i,  // 4 bits de datos TAL COMO LLEGARON (sin corregir)
    input  logic [2:0] sind_i,           // síndrome = posición del bit erróneo
    input  logic       disp_mode_i,      // conmutador de selección de display
    output logic [6:0] catodo_o,         // segmentos compartidos, activo en bajo
    output logic [1:0] anodo_o           // control de los PNP, activo en bajo
);

    // --- MUX 2:1 de 4 bits, escrito como suma de productos ---
    logic [3:0] nibble;
    assign nibble[0] = (~disp_mode_i & dato_recibido_i[0]) | (disp_mode_i & sind_i[0]);
    assign nibble[1] = (~disp_mode_i & dato_recibido_i[1]) | (disp_mode_i & sind_i[1]);
    assign nibble[2] = (~disp_mode_i & dato_recibido_i[2]) | (disp_mode_i & sind_i[2]);
    assign nibble[3] = (~disp_mode_i & dato_recibido_i[3]);  // el síndrome sólo usa 3 bits

    // --- Decodificador hexadecimal a 7 segmentos (el mismo del módulo 5.3) ---
    module_bin_a_7seg U_DECO (
        .datos_i (nibble),
        .seg_o   (catodo_o)
    );

    // --- Selección del display (PNP: 0 = encendido) ---
    assign anodo_o[0] =  disp_mode_i;   // display 0 encendido cuando disp_mode_i = 0
    assign anodo_o[1] = ~disp_mode_i;   // display 1 encendido cuando disp_mode_i = 1

endmodule
