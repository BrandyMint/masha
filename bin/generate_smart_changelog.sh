#!/bin/bash

# Скрипт для генерации умного changelog на основе git коммитов
# Использование: bin/generate_smart_changelog.sh [tag]

set -euo pipefail

# Получаем версию из аргумента или из git
CURRENT_TAG="${1:-$(git describe --tags --abbrev=0)}"
PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")

echo "## Что нового в $CURRENT_TAG"
echo ""

# Получаем коммиты
if [ -n "$PREVIOUS_TAG" ]; then
    COMMITS_FILE=$(mktemp)
    git log "$PREVIOUS_TAG..HEAD" --pretty=format:"%s|%an|%ad" --date=short --no-merges > "$COMMITS_FILE"
    echo "### 🎯 Основные изменения с версии $PREVIOUS_TAG"
    echo ""
else
    COMMITS_FILE=$(mktemp)
    git log --max-count=50 --pretty=format:"%s|%an|%ad" --date=short --no-merges > "$COMMITS_FILE"
    echo "### 🎯 Первые изменения проекта"
    echo ""
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

# Выводим результаты
if [ -s "$FEATURES" ]; then
    echo "#### ✨ Новый функционал"
    sort -u "$FEATURES" | head -5
    echo ""
fi

if [ -s "$FIXES" ]; then
    echo "#### 🐛 Исправления"
    sort -u "$FIXES" | head -5
    echo ""
fi

if [ -s "$IMPROVEMENTS" ]; then
    echo "#### 🔧 Улучшения"
    sort -u "$IMPROVEMENTS" | head -3
    echo ""
fi

# Статистика
TOTAL_COMMITS=$(wc -l < "$COMMITS_FILE")
FEATURE_COUNT=$(wc -l < "$FEATURES" 2>/dev/null || echo "0")
FIX_COUNT=$(wc -l < "$FIXES" 2>/dev/null || echo "0")

if [ "$TOTAL_COMMITS" -gt 10 ]; then
    echo "### 📊 Статистика релиза"
    echo ""
    echo "- **Всего изменений:** $TOTAL_COMMITS коммитов"
    if [ "$FEATURE_COUNT" -gt 0 ]; then
        echo "- **Новых возможностей:** $FEATURE_COUNT"
    fi
    if [ "$FIX_COUNT" -gt 0 ]; then
        echo "- **Исправлений:** $FIX_COUNT"
    fi
    echo ""
fi

echo "---"
echo "🤖 *Changelog сгенерирован автоматически для MashTime Bot*"
echo ""

# Очищаем временные файлы
rm -f "$COMMITS_FILE" "$FEATURES" "$FIXES" "$IMPROVEMENTS" "$OTHER"