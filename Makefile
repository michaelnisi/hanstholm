.PHONY: build test build-server test-server install-hooks

build:
	cd Core && swift build

test:
	cd Core && swift test

build-server:
	cd Server && swift build

test-server:
	cd Server && swift test

install-hooks:
	cp scripts/hooks/pre-commit .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
