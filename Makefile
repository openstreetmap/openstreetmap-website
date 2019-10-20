docker-build:
	docker-compose build

docker-up:
	docker-compose up -d

docker-db-migrate:
	docker-compose run --rm web rake db:migrate

FORCE: touch config/settings.local.yml