ICARUS = iverilog
VVP = vvp

spi_mem.o:	../src/common.sv spi_mem_sim.sv ../src/spi_memory_controller.sv
			$(ICARUS) -g2012 -o spi_mem.o $^
spi_mem:	spi_mem.o
			$(VVP) spi_mem.o
