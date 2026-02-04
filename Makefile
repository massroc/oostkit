# OOSTKit Monorepo - Makefile
# Convenience commands for development

.PHONY: help up down logs clean

# Default target
help:
	@echo "OOSTKit Monorepo"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "General commands:"
	@echo "  up        - Start all apps"
	@echo "  down      - Stop all apps"
	@echo "  logs      - Follow logs for all apps"
	@echo "  clean     - Remove Docker volumes (careful!)"
	@echo ""
	@echo "Workgroup Pulse:"
	@echo "  wp-up     - Start workgroup_pulse"
	@echo "  wp-test   - Run tests"
	@echo "  wp-tdd    - Start TDD mode"
	@echo "  wp-shell  - Open IEx shell"
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

# Workgroup Pulse commands
wp-up:
	cd apps/workgroup_pulse && docker compose up

wp-test:
	cd apps/workgroup_pulse && docker compose --profile test run --rm wp_test

wp-tdd:
	cd apps/workgroup_pulse && docker compose --profile tdd run --rm wp_test_watch

wp-shell:
	cd apps/workgroup_pulse && docker compose exec wp_app iex -S mix
