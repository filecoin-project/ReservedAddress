.PHONY: build clean test abi

build:
	forge build

clean:
	rm -rf out

test: build lib/evm/bin/evm
	make -C lib/evm check
	@for f in test/dio/*.json; do echo "\n$$f:"; lib/evm/bin/evm -w "$$f" || exit 1; done
	forge test

lib/evm/bin/evm: lib/evm/Makefile
	make -C lib/evm

# An ABI json is the .abi slice of the matching interface's forge artifact.
%.abi.json: src/interfaces/I%.sol
	forge build $<
	jq .abi out/I$*.sol/I$*.json > $@

define ASM_ARTIFACT
build: out/$(1).evm/$(1).json
# Attach an ABI when one is committed or derivable from src/interfaces/I$(1).sol.
ABI_$(1) := $$(or $$(wildcard $(1).abi.json),$$(patsubst src/interfaces/I%.sol,%.abi.json,$$(wildcard src/interfaces/I$(1).sol)))
abi: $$(ABI_$(1))
out/$(1).evm/$(1).json: src/$(1).evm lib/evm/bin/evm $$(ABI_$(1))
	mkdir -p out/$(1).evm
ifneq (,$(findstring constructor,$(1)))
	jq -n $$(if $$(ABI_$(1)),--slurpfile abi $$(ABI_$(1))) --arg b "0x$$$$(lib/evm/bin/evm $$<)" '{ bytecode: { object: $$$$b } }$$(if $$(ABI_$(1)), + { abi: $$$$abi[0] })' > $$@
else
	jq -n $$(if $$(ABI_$(1)),--slurpfile abi $$(ABI_$(1))) --arg b "0x$$$$(lib/evm/bin/evm -c $$<)" --arg d "0x$$$$(lib/evm/bin/evm $$<)" '{ bytecode: { object: $$$$b }, deployedBytecode: { object: $$$$d } }$$(if $$(ABI_$(1)), + { abi: $$$$abi[0] })' > $$@
endif
endef

ASM_SOURCE=$(wildcard src/*.evm)
$(foreach name, $(ASM_SOURCE:src/%.evm=%), $(eval $(call ASM_ARTIFACT,$(name))))
