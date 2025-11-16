# Git Hooks

Эта директория содержит шаблоны git hooks для проекта Masha.

## Установка

Для установки hooks выполните:

```bash
./.githooks/install
```

Или используйте Makefile:

```bash
make install-hooks
```

## Доступные Hooks

### pre-commit

Автоматически запускает RuboCop auto-correction на staged Ruby файлах перед коммитом.

**Возможности:**
- ✅ Автоматически исправляет style нарушения
- ✅ Добавляет исправленные файлы обратно в staging
- ✅ Блокирует коммит если остались неисправимые нарушения
- ✅ Работает только с staged файлами (не затрагивает unstaged изменения)

**Как пропустить hook:**

```bash
# Через переменную окружения
SKIP_RUBOCOP=1 git commit -m "message"

# Или через флаг git
git commit --no-verify -m "message"
```

## Разработка

### Добавление нового hook

1. Создайте файл в `.githooks/` с именем hook (например, `pre-push`)
2. Сделайте файл исполняемым: `chmod +x .githooks/pre-push`
3. Запустите `.githooks/install` для установки

### Тестирование hook

Для тестирования pre-commit hook:

```bash
# Создайте тестовый файл с style нарушениями
echo "def  test; end" > test.rb

# Добавьте в staging
git add test.rb

# Попробуйте закоммитить
git commit -m "Test commit"

# Hook должен автоматически исправить двойной пробел
```

## Troubleshooting

### Hook не запускается

Проверьте что hook установлен и исполняемый:

```bash
ls -la .git/hooks/pre-commit
```

Если файл отсутствует, запустите установку:

```bash
./.githooks/install
```

### RuboCop не найден

Убедитесь что bundle установлен:

```bash
bundle install
```

### Слишком медленная работа

Для больших коммитов можно временно отключить hook:

```bash
SKIP_RUBOCOP=1 git commit -m "Large refactoring"
```
