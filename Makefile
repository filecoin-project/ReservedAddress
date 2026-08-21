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

Deployer.abi.json: out/IDeployer.sol/IDeployer.json
	jq .abi $< > $@

abi: Deployer.abi.json

out/IDeployer.sol/IDeployer.json: src/interfaces/IDeployer.sol
	forge build $<

define ASM_ARTIFACT
build: out/$(1).evm/$(1).json
out/$(1).evm/$(1).json: src/$(1).evm lib/evm/bin/evm
	mkdir -p out/$(1).evm
ifneq (,$(findstring constructor,$(1)))
	jq -n --arg b "0x$$$$(lib/evm/bin/evm $$<)" '{ bytecode: { object: $$$$b } }' > $$@
else
	jq -n --arg b "0x$$$$(lib/evm/bin/evm -c $$<)" --arg d "0x$$$$(lib/evm/bin/evm $$<)" '{ bytecode: { object: $$$$b }, deployedBytecode: { object: $$$$d } }' > $$@
endif
endef

ASM_SOURCE=$(wildcard src/*.evm)
$(foreach name, $(ASM_SOURCE:src/%.evm=%), $(eval $(call ASM_ARTIFACT,$(name))))
