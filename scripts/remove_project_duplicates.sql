-- SQL скрипт для удаления дубликатов Project.name в development базе
-- Оставляем только проекты с меньшим ID

-- Удаляем дубликаты "Work Project" (оставляем меньший id)
DELETE FROM projects
WHERE name = 'Work Project'
AND id NOT IN (
  SELECT MIN(id)
  FROM projects
  WHERE name = 'Work Project'
);

-- Удаляем дубликаты "Personal Project"
DELETE FROM projects
WHERE name = 'Personal Project'
AND id NOT IN (
  SELECT MIN(id)
  FROM projects
  WHERE name = 'Personal Project'
);

-- Удаляем дубликаты "Project 1"
DELETE FROM projects
WHERE name = 'Project 1'
AND id NOT IN (
  SELECT MIN(id)
  FROM projects
  WHERE name = 'Project 1'
);

-- Удаляем дубликаты "Project 2"
DELETE FROM projects
WHERE name = 'Project 2'
AND id NOT IN (
  SELECT MIN(id)
  FROM projects
  WHERE name = 'Project 2'
);

-- Удаляем дубликаты "Old Project"
DELETE FROM projects
WHERE name = 'Old Project'
AND id NOT IN (
  SELECT MIN(id)
  FROM projects
  WHERE name = 'Old Project'
);

-- Проверяем что дубликатов больше нет
SELECT
    name,
    COUNT(*) as count
FROM projects
WHERE name IN ('Work Project', 'Personal Project', 'Project 1', 'Project 2', 'Old Project')
GROUP BY name
ORDER BY name;
