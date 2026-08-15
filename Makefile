.PHONY: build test

build:
	cd Core && swift build

test:
	cd Core && swift test
