ICARUS = iverilog
VVP = vvp

spi_mem.o:	../src/common.sv peripheral_for_sim.sv spi_mem_sim.sv ../src/spi_memory_controller.sv
			$(ICARUS) -g2012 -o spi_mem.o $^
spi_mem:	spi_mem.o
			$(VVP) spi_mem.o

top_sim.o:	../src/common.sv peripheral_for_sim.sv top_sim.sv ../src/project.sv ../src/spi_memory_controller.sv \
			../src/tiny_mcu.sv ../src/sequencer.sv ../src/instruction_register.sv ../src/alu.sv ../src/status_register.sv \
			../src/program_counter.sv ../src/instruction_decoder.sv ../src/reg_file.sv ../src/mcu_peripheral.sv
			$(ICARUS) -g2012 -o top_sim.o $^
top_sim:	top_sim.o
			$(VVP) top_sim.o

alu_sim.o: ../src/common.sv alu_sim.sv ../src/alu.sv
			$(ICARUS) -g2012 -o alu_sim.o $^
alu_sim:	alu_sim.o
			$(VVP) alu_sim.o

peri_sim.o: ../src/common.sv peri_sim.sv ../src/mcu_peripheral.sv
			$(ICARUS) -g2012 -o peri_sim.o $^
peri_sim:	peri_sim.o
			$(VVP) peri_sim.o