# FindAny Project Makefile

.PHONY: help build up down test clean lint format

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

build: ## Build Docker images
	docker-compose build

up: ## Start all services
	docker-compose up -d

down: ## Stop all services
	docker-compose down

test: ## Run tests locally
	cd backend && python -m pip install -r requirements.txt pytest pytest-cov flake8 black isort mypy && python -m flake8 app.py --count --select=E9,F63,F7,F82 --show-source --statistics && python -m pytest

clean: ## Clean up containers and volumes
	docker-compose down -v
	docker system prune -f

lint: ## Run linting
	cd backend && flake8 app.py

format: ## Format code
	cd backend && black app.py && isort app.py

logs: ## Show logs
	docker-compose logs -f

shell-backend: ## Open shell in backend container
	docker-compose exec backend bash

shell-db: ## Open shell in database container
	docker-compose exec mysql mysql -u findany_user -p findany
