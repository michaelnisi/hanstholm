.PHONY: build test server-build server-test install-hooks

build:
	cd Core && swift build

test:
	cd Core && swift test

server-build:
	cd Server && swift build

server-test:
	cd Server && swift test

install-hooks:
	cp scripts/hooks/pre-commit .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
