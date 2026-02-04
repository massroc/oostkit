# Productive Tools Monorepo - Makefile
# Convenience commands for development

.PHONY: help up down logs clean

# Default target
help:
	@echo "Productive Tools Monorepo"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "General commands:"
	@echo "  up        - Start all apps"
	@echo "  down      - Stop all apps"
	@echo "  logs      - Follow logs for all apps"
	@echo "  clean     - Remove Docker volumes (careful!)"
	@echo ""
	@echo "Productive Workgroups:"
	@echo "  pw-up     - Start productive_workgroups"
	@echo "  pw-test   - Run tests"
	@echo "  pw-tdd    - Start TDD mode"
	@echo "  pw-shell  - Open IEx shell"
	@echo ""
	@echo "For more commands, see apps/*/scripts/dev.sh"

# General commands
up:
	docker compose up

down:
	docker compose down

logs:
	docker compose logs -f

clean:
	@echo "This will remove all Docker volumes. Are you sure? [y/N]"
	@read -r response; if [ "$$response" = "y" ]; then docker compose down -v; fi

# Productive Workgroups commands
pw-up:
	cd apps/productive_workgroups && docker compose up

pw-test:
	cd apps/productive_workgroups && docker compose --profile test run --rm pw_test

pw-tdd:
	cd apps/productive_workgroups && docker compose --profile tdd run --rm pw_test_watch

pw-shell:
	cd apps/productive_workgroups && docker compose exec pw_app iex -S mix
