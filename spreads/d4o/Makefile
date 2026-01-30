export COMPILER ?= INTEL
export rebuild ?= 0
export run_tests ?= 0

all:
	@echo "Usage: make [COMPILER=[INTEL|INTELPROF|GNU|PGI]] [zeus|juno|ryzen|msi|blq|cassandra]"
	@echo "The default COMPILER=INTEL"
	@exit 1

juno zeus ryzen msi blq cassandra:
	./build.$@ $(COMPILER)
#$