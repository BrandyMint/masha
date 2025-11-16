-- SQL скрипт для проверки дубликатов перед применением миграции AddUniqueIndexesForValidations
-- Запустить на production: psql $PRODUCTION_DATABASE_URI -f scripts/check_unique_duplicates.sql

\echo '=== Проверка дубликатов для уникальных индексов ==='
\echo ''

-- 1. Проверка Invite: email + project_id
\echo '1. Проверка Invite: дубликаты email + project_id'
SELECT
    email,
    project_id,
    COUNT(*) as count,
    array_agg(id) as invite_ids
FROM invites
WHERE email IS NOT NULL
GROUP BY email, project_id
HAVING COUNT(*) > 1
ORDER BY count DESC;

\echo ''

-- 2. Проверка Project.name
\echo '2. Проверка Project: дубликаты name'
SELECT
    name,
    COUNT(*) as count,
    array_agg(id) as project_ids
FROM projects
WHERE name IS NOT NULL
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY count DESC;

\echo ''

-- 3. Проверка User.nickname
\echo '3. Проверка User: дубликаты nickname'
SELECT
    nickname,
    COUNT(*) as count,
    array_agg(id) as user_ids
FROM users
WHERE nickname IS NOT NULL
GROUP BY nickname
HAVING COUNT(*) > 1
ORDER BY count DESC;

\echo ''

-- 4. Проверка User.pivotal_person_id
\echo '4. Проверка User: дубликаты pivotal_person_id'
SELECT
    pivotal_person_id,
    COUNT(*) as count,
    array_agg(id) as user_ids
FROM users
WHERE pivotal_person_id IS NOT NULL
GROUP BY pivotal_person_id
HAVING COUNT(*) > 1
ORDER BY count DESC;

\echo ''
\echo '=== Проверка завершена ==='
\echo 'Если есть строки выше - значит есть дубликаты!'
\echo 'Нужно решить как их обработать перед применением миграции.'
