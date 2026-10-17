-- Завдання 3. Аналіз Number_rabies
-- Для кожної пари Entity + Code: середнє, мінімум, максимум і сума.
-- Рядки без значення (NULL) агрегатні функції ігнорують; країни, у яких
-- немає жодного значення, відкидаємо, щоб вони не потрапили в топ
-- (у PostgreSQL NULL при DESC стоїть першим).

SET search_path TO pandemic;

SELECT
    e.id,
    e.entity,
    e.code,
    AVG(c.number_rabies) AS avg_rabies,
    MIN(c.number_rabies) AS min_rabies,
    MAX(c.number_rabies) AS max_rabies,
    SUM(c.number_rabies) AS sum_rabies
FROM infectious_cases_normalized c
JOIN entities e ON e.id = c.entity_id
WHERE c.number_rabies IS NOT NULL
GROUP BY e.id, e.entity, e.code
ORDER BY avg_rabies DESC
LIMIT 10;
