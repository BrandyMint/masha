SEMVER_BIN=./bin/semver
SEMVER=`${SEMVER_BIN}`

# Default target
release: patch-release

# Процесс релиза:
# 1. bump-patch: увеличивает версию, коммитит .semver, пушит
# 2. changelog-and-commit: генерирует changelog, коммитит, создает тег, пушит, создает GitHub релиз 

patch-release-and-deploy: patch-release watch deploy sleep infra-watch

minor:
	@${SEMVER_BIN} inc minor

patch:
	@${SEMVER_BIN} inc patch

bump-patch: patch push-semver
bump-minor: minor push-semver

push-semver:
	@echo "Increment version to ${SEMVER}"
	@git add .semver
	@git commit -m ${SEMVER}
	@git push

patch-release: bump-patch changelog-and-commit
minor-release: bump-minor changelog-and-commit

# Генерирует changelog и коммитит изменения
changelog-and-commit:
	@echo "📝 Генерация changelog для версии ${SEMVER}..."
	@./bin/generate_smart_changelog.sh ${SEMVER}
	@git add CHANGELOG.md
	@git commit -m "📝 Add changelog for ${SEMVER}" || echo "Changelog уже был добавлен"
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
	./bin/rails db:test:prepare test test:system

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

