#Makefile con todo el flujo de trabajo para GOWIN. Utilizando Yosys, nextpnr, iverilog, gtkwave y openFPGALoader
#
#EL-3307 Diseno Logico - Proyecto corto I
#
#Un solo bitstream sirve para las dos tarjetas: el pin modo_i (J6-22) decide
#si esa tarjeta se comporta como transmisor (jumper a J6-23, que es GND) o
#como receptor (sin jumper).
#
#Uso:
#  make            -> sintetiza, hace pnr, genera el bitstream y lo carga
#  make synth      -> solo la sintesis
#  make test       -> corre el testbench principal (tb_sistema_completo)
#  make test-all   -> corre TODOS los testbenches, uno por uno
#  make load       -> carga el bitstream en la SRAM (se pierde al desconectar)
#  make load-flash -> lo graba en la flash, queda permanente
#  make all-flash  -> todo el flujo, grabando en la flash
#  make detect     -> comprueba que openFPGALoader vea la tarjeta
#  make wv         -> abre la forma de onda en GTKWave
#  make clean      -> borra los productos intermedios
#
#OJO al cargar: conecte por USB SOLO la tarjeta que va a programar, o use la
#opcion --index de openFPGALoader para escoger cual de las dos programa.

#FPGA a utilizar... Esto no se debe modificar para efectos del curso.
BOARD  = tangnano9k
FAMILY = GW1N-9C
DEVICE = GW1NR-LV9QN88PC6/I5

#Nombre del proyecto... Aca ponen el nombre que deseen.
PROYECT = Proyecto1DL

#Fuentes de diseno
SOURCES := $(wildcard ../design/*.v ../design/*.sv) #Todas las fuentes .v o .sv que estan en design
#Si quieren indicarlas una a una, pueden hacerlo como en este ejemplo:
#SOURCES = ../design/top_hamming.sv ../design/module_generador_error.sv

#Modelos de los bloques que van alambrados con 74HC86 en la protoboard.
#SOLO SIRVEN PARA SIMULAR: nunca entran a la sintesis.
SIM_MODELS = ../sim/module_hamming74_estructural.sv \
             ../sim/modelo_hamming_verificacion.sv \
             ../sim/modelo_receptor_fisico.sv

#Fuente de simulacion
#aca va el testbench que quieran simular
TESTBENCH = ../sim/tb_sistema_completo.sv

# Constraints para el proyecto
#aca va el archivo de constraints del proyecto
CONSTRAINTS = ../constr/proyecto.cst

#el top se indica sin la extension .v, esto hace referencia al nombre que le pusieron al modulo y no al archivo en si.
TOP_DESIGN = top_hamming
TOP_TB     = tb_sistema_completo

#nombre del vcd que va a generar el tb
VCD_FILE = sistema_completo_tb.vcd

#Icarus Verilog: -g2005-sv es el estandar que pide el curso. No subir a -g2012:
#la version 13.0-devel del oss-cad-suite falla con una asercion.
IVFLAGS = -g2005-sv

#Lista de todos los testbenches del proyecto (nombre del modulo = nombre del archivo)
TESTBENCHES = tb_bin_a_7seg \
              tb_generador_error \
              tb_corrector \
              tb_hamming74_estructural \
              tb_modelo_hamming_verificacion \
              tb_sistema_completo


all: synth pnr bitstream load

#Igual que "make all" pero grabando en la flash en vez de la SRAM.
all-flash: synth pnr bitstream load-flash

# Synthesis
synth: ${SOURCES}
	@echo "Ejecutando la sintesis..."
	@yosys -p "read_verilog -sv ${SOURCES}; synth_gowin -top ${TOP_DESIGN} -json ${PROYECT}.json" > synthesis_${BOARD}.log 2>&1
	@echo "COMPLETADO"

# Place and Route
pnr: ${PROYECT}.json
	@echo "Ejecutando el pnr..."
	@nextpnr-gowin --json ${PROYECT}.json --write ${PROYECT}_pnr.json --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${CONSTRAINTS} > pnr_${BOARD}.log 2>&1
	@echo "COMPLETADO"

# Generar el Bitstream
bitstream: ${PROYECT}_pnr.json
	@echo "Generando ${PROYECT}_${BOARD}.fs"
	@gowin_pack -d ${FAMILY} -o ${PROYECT}_${BOARD}.fs ${PROYECT}_pnr.json
	@echo "COMPLETADO"

#Generar vcd con icarus verilog
test: ${SOURCES} ${TESTBENCH}
	@iverilog ${IVFLAGS} -o ${PROYECT}_test.o -s ${TOP_TB} ${TESTBENCH} ${SOURCES} ${SIM_MODELS}
	@vvp ${PROYECT}_test.o

#Correr todos los testbenches, uno tras otro.
#Se hace con una regla de patron y no con un bucle de shell, para que
#funcione igual en Linux, en macOS y en Windows (donde make usa cmd.exe y no
#entiende la sintaxis "for ... do ... done").
test-all: $(addprefix run-,${TESTBENCHES})
	@echo Todos los testbenches corrieron.

run-%:
	@echo ==================================================================
	@echo  $*
	@echo ==================================================================
	@iverilog ${IVFLAGS} -o $*.o -s $* ../sim/$*.sv ${SOURCES} ${SIM_MODELS}
	@vvp $*.o

#Visualizar los diagramas de tiempo con GTKWave
#(primero hay que correr "make test" para que exista el .vcd)
wv:
	gtkwave ${VCD_FILE}

# Cargar el bitstream en la SRAM de la FPGA.
# Es lo rapido para probar, pero se PIERDE al desconectar la tarjeta.
load: ${PROYECT}_${BOARD}.fs
	openFPGALoader -b ${BOARD} ${PROYECT}_${BOARD}.fs

# Cargar el bitstream en la FLASH de la tarjeta.
# Tarda mas, pero queda grabado: la tarjeta arranca con el diseno aunque la
# desconecte. Use esto para la presentacion.
load-flash: ${PROYECT}_${BOARD}.fs
	openFPGALoader -b ${BOARD} -f ${PROYECT}_${BOARD}.fs

# Listar lo que openFPGALoader ve conectado. Para diagnosticar cuando
# "make load" dice que no encuentra el cable.
detect:
	openFPGALoader --detect

#El guion inicial hace que make ignore el error si "rm" no existe (Windows).
clean:
	-@rm -f *.o *.json *.fs *.vcd *.log
	@echo Limpio.

.PHONY: all all-flash load load-flash detect wv test test-all clean
.INTERMEDIATE: ${PROYECT}_pnr.json ${PROYECT}.json
