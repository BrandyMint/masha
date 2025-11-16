SEMVER_BIN=./bin/semver
SEMVER=`${SEMVER_BIN}`

# Default target
release: patch-release

server:
	./bin/rails s -p 3014 -b 192.168.88.10

lint:
	./bin/rubocop -a
	# Дааа!
	./bin/rubocop --auto-gen-config
	git add .
	git commit -m lint

# Процесс релиза:
# 1. generate-changelog: генерирует CHANGELOG.md на основе изменений между тегами
# 2. bump-patch-with-changelog: увеличивает версию и коммитит её вместе с CHANGELOG.md
# 3. push-version: создает тег, пушит изменения и создает GitHub релиз

patch-release-and-deploy: patch-release watch deploy sleep infra-watch

set_commands:
	MASHA_BOT_TOKEN=${MASHA_PRODUCTION_BOT_TOKEN} ./bin/rake telegram:bot:set_commands 

minor:
	@${SEMVER_BIN} inc minor

patch:
	@${SEMVER_BIN} inc patch

bump-patch: patch
bump-minor: minor

patch-release: generate-changelog bump-patch-with-changelog
minor-release: bump-minor-with-changelog

# Генерирует changelog (без коммита)
generate-changelog:
	@echo "📝 Генерация changelog для версии ${SEMVER}..."
	@./bin/generate_smart_changelog.sh ${SEMVER}

# Увеличивает версию и коммитит её вместе с CHANGELOG
bump-patch-with-changelog: patch commit-version-and-changelog push-version
bump-minor-with-changelog: minor commit-version-and-changelog push-version

# Коммитит версию и CHANGELOG вместе
commit-version-and-changelog:
	@echo "Increment version to ${SEMVER}"
	@git add .semver CHANGELOG.md
	@git commit -m "${SEMVER}"

# Пушит версию и создает тег
push-version:
	@echo "🏷️ Создание тега ${SEMVER}..."
	@git tag ${SEMVER}
	@echo "📤 Пуш изменений и тега..."
	@git push
	@git push origin ${SEMVER}
	@echo "🚀 Создание релиза на GitHub..."
	@./bin/generate_smart_changelog.sh ${SEMVER} | head -n -1 | gh release create ${SEMVER} --title "Release ${SEMVER}" --notes-file -
	@echo "✅ Релиз ${SEMVER} успешно создан!"

.PHONY: test
test:
	./bin/rails db:test:prepare
	bundle exec rspec

security:
	bundle exec brakeman --skip-files bin/generate_changelog.rb,bin/generate_claude_changelog.rb

up:
	./bin/dev

clean:
	rm -fr tmp/postgres_data/
	dropuser -h localhost -U postgres 

create_user:
	createuser -h localhost -U postgres -s

deps:
	brew install terminal-notifier
	brew install oven-sh/bun/bun
	bundle install

watch:
	@${GH} run watch ${LATEST_RUN_ID}

infra-watch:
	@${INFRA_GH} run watch ${LATEST_INFRA_RUN_ID}

infra-view:
	@${INFRA_GH} run view ${LATEST_INFRA_RUN_ID} --log-failed

list:
	@${INFRA_GH} run list --workflow=${WORKFLOW} -L 3 -e workflow_dispatch

production-psql:
	psql ${PRODUCTION_DATABASE_URI}

# Changelog цели
changelog:
	@./bin/generate_smart_changelog.sh

changelog-preview:
	@echo "Предпросмотр changelog для текущих изменений:"
	@echo "=========================================="
	@./bin/generate_smart_changelog.sh HEAD

test-changelog:
	@echo "Тестирование генерации changelog..."
	@./bin/generate_smart_changelog.sh v0.6.30
	@echo "=========================================="
	@echo "Chelog успешно сгенерирован!"

# Быстрый предпросмотр changelog для текущей версии без сохранения
preview-release:
	@echo "Предпросмотр релиза для текущей версии (${SEMVER}):"
	@echo "=========================================="
	@./bin/generate_smart_changelog.sh ${SEMVER} | head -n -1

