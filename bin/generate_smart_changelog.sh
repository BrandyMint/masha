#!/bin/bash

# Скрипт для генерации умного changelog на основе git коммитов
# Использование: bin/generate_smart_changelog.sh [tag]

set -euo pipefail

# Получаем версию из аргумента или из git
CURRENT_TAG="${1:-$(git describe --tags --abbrev=0)}"
PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")

# Получаем коммиты
if [ -n "$PREVIOUS_TAG" ]; then
    COMMITS_FILE=$(mktemp)
    git log "$PREVIOUS_TAG..HEAD" --pretty=format:"%s|%an|%ad" --date=short --no-merges > "$COMMITS_FILE"
else
    COMMITS_FILE=$(mktemp)
    git log --max-count=50 --pretty=format:"%s|%an|%ad" --date=short --no-merges > "$COMMITS_FILE"
fi

# Анализируем и группируем коммиты
FEATURES=$(mktemp)
FIXES=$(mktemp)
IMPROVEMENTS=$(mktemp)
OTHER=$(mktemp)

while IFS='|' read -r subject author date; do
    # Очищаем тему от технических префиксов
    clean_subject=$(echo "$subject" | sed -E 's/^(feat|fix|refactor|chore|test|docs|style|lint|bump)(\([^)]*\))?:\s*//')

    case "$subject" in
        *feat*|*Add*|*Новый*|*Добавлен*|*Feature*|*New*)
            echo "✨ $clean_subject" >> "$FEATURES"
            ;;
        *fix*|*Fix*|*Исправлен*|*Исправить*|*Bug*|*Issue*)
            echo "🐛 $clean_subject" >> "$FIXES"
            ;;
        *refactor*|*Улучш*|*Оптимиз*|*Refactor*|*Improve*)
            echo "🔧 $clean_subject" >> "$IMPROVEMENTS"
            ;;
        *)
            echo "📝 $clean_subject" >> "$OTHER"
            ;;
    esac
done < "$COMMITS_FILE"

# Генерируем changelog в переменную для сохранения
if [ -n "$PREVIOUS_TAG" ]; then
    CHANGELOG_SECTION="### 🎯 Основные изменения с версии $PREVIOUS_TAG"
else
    CHANGELOG_SECTION="### 🎯 Первые изменения проекта"
fi

CHANGELOG_CONTENT="## Что нового в $CURRENT_TAG\n\n$CHANGELOG_SECTION\n\n"

# Добавляем контент в переменную
if [ -s "$FEATURES" ]; then
    CHANGELOG_CONTENT+="#### ✨ Новый функционал\n"
    sort -u "$FEATURES" | head -5 >> "$FEATURES.sorted"
    CHANGELOG_CONTENT+=$(cat "$FEATURES.sorted")
    CHANGELOG_CONTENT+="\n"
fi

if [ -s "$FIXES" ]; then
    CHANGELOG_CONTENT+="#### 🐛 Исправления\n"
    sort -u "$FIXES" | head -5 >> "$FIXES.sorted"
    CHANGELOG_CONTENT+=$(cat "$FIXES.sorted")
    CHANGELOG_CONTENT+="\n"
fi

if [ -s "$IMPROVEMENTS" ]; then
    CHANGELOG_CONTENT+="#### 🔧 Улучшения\n"
    sort -u "$IMPROVEMENTS" | head -3 >> "$IMPROVEMENTS.sorted"
    CHANGELOG_CONTENT+=$(cat "$IMPROVEMENTS.sorted")
    CHANGELOG_CONTENT+="\n"
fi

# Добавляем статистику
TOTAL_COMMITS=$(wc -l < "$COMMITS_FILE")
FEATURE_COUNT=$(wc -l < "$FEATURES" 2>/dev/null || echo "0")
FIX_COUNT=$(wc -l < "$FIXES" 2>/dev/null || echo "0")

if [ "$TOTAL_COMMITS" -gt 10 ]; then
    CHANGELOG_CONTENT+="### 📊 Статистика релиза\n\n"
    CHANGELOG_CONTENT+="- **Всего изменений:** $TOTAL_COMMITS коммитов\n"
    if [ "$FEATURE_COUNT" -gt 0 ]; then
        CHANGELOG_CONTENT+="- **Новых возможностей:** $FEATURE_COUNT\n"
    fi
    if [ "$FIX_COUNT" -gt 0 ]; then
        CHANGELOG_CONTENT+="- **Исправлений:** $FIX_COUNT\n"
    fi
    CHANGELOG_CONTENT+="\n"
fi

CHANGELOG_CONTENT+="---\n🤖 *Changelog сгенерирован автоматически для MashTime Bot*\n"

# Выводим на экран
printf '%b\n' "$CHANGELOG_CONTENT"

# Сохраняем changelog в файл
CHANGELOG_FILE="CHANGELOG.md"
{
    printf "# Changelog\n\nИстория релизов MashTime Bot\n\n---\n\n"
    printf '%b\n\n' "$CHANGELOG_CONTENT"

    # Если файл уже существует, добавляем старые записи
    if [ -f "$CHANGELOG_FILE" ]; then
        # Пропускаем заголовок и разделитель из существующего файла
        tail -n +6 "$CHANGELOG_FILE"
    fi

} > "${CHANGELOG_FILE}.new"

# Заменяем старый файл новым
mv "${CHANGELOG_FILE}.new" "$CHANGELOG_FILE"

echo "✅ Changelog сохранен в $CHANGELOG_FILE"
echo ""

# Очищаем временные файлы
rm -f "$COMMITS_FILE" "$FEATURES" "$FIXES" "$IMPROVEMENTS" "$OTHER"
rm -f "$FEATURES.sorted" "$FIXES.sorted" "$IMPROVEMENTS.sorted"