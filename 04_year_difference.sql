-- Завдання 4. Колонка різниці в роках (вбудовані функції)

SET search_path TO pandemic;

SELECT
    e.entity,
    c.year,
    MAKE_DATE(c.year, 1, 1)                                         AS start_of_year,
    CURRENT_DATE                                                    AS today,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAKE_DATE(c.year, 1, 1)))::INT AS years_diff
FROM infectious_cases_normalized c
JOIN entities e ON e.id = c.entity_id
ORDER BY e.entity, c.year
LIMIT 20;
