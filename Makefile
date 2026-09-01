SHELL := /bin/bash

BASH ?= /bin/bash
SHELLCHECK ?= shellcheck

.DEFAULT_GOAL := check

.PHONY: check lint test

check: lint test

lint:
	$(BASH) -n bin/cx-sideload tests/test.sh
	$(SHELLCHECK) --rcfile .shellcheckrc --external-sources bin/cx-sideload tests/test.sh

test:
	$(BASH) tests/test.sh
