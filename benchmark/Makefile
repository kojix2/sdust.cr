THREADS ?= 8

URL := https://jmorp.megabank.tohoku.ac.jp/datasets/tommo-jg3.0.0-20240618/files/JG3.0.0.fa
FA := data/JG3.0.0.fa

.PHONY: all help data build clean clean-data clean-build

all: data build

help:
	@echo "Usage: make [target] [THREADS=N]"
	@echo
	@echo "Targets:"
	@echo "  all          Download data and build binaries"
	@echo "  data         Download and index benchmark data"
	@echo "  build        Build original sdust and sdust.cr"
	@echo "  clean        Remove built benchmark binaries"
	@echo "  clean-build  Remove built benchmark binaries"
	@echo "  clean-data   Remove downloaded benchmark data"

data: $(FA).fai $(FA).gz.fai

build: bin/sdust-or bin/sdust-cr

$(FA):
	mkdir -p data
	wget -c "$(URL)" -O "$@"

$(FA).fai: $(FA)
	samtools faidx -@ "$(THREADS)" "$<"

$(FA).gz: $(FA)
	bgzip -@ "$(THREADS)" -k -f "$<"

$(FA).gz.fai: $(FA).gz
	samtools faidx -@ "$(THREADS)" "$<"

bin/sdust-or:
	mkdir -p bin
	$(MAKE) -C ../sdust CPPFLAGS=-D_POSIX_C_SOURCE=200809L
	cp ../sdust/sdust "$@"
	$(MAKE) -C ../sdust clean

bin/sdust-cr:
	mkdir -p bin
	cd .. && shards build --release
	cp ../bin/sdust "$@"

clean: clean-build

clean-build:
	rm -rf bin

clean-data:
	rm -rf data
