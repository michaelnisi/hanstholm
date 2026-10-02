.PHONY: build test install-hooks

build:
	cd Core && swift build

test:
	cd Core && swift test

install-hooks:
	cp scripts/hooks/pre-commit .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
