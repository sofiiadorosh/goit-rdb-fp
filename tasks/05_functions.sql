-- Завдання 5. Власні функції

SET search_path TO pandemic;

-- 5.1 Різниця в роках між поточною датою та 1 січня заданого року
--     1996 -> 1996-01-01 -> кількість повних років до CURRENT_DATE
CREATE OR REPLACE FUNCTION years_since(p_year INT)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
    SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAKE_DATE(p_year, 1, 1)))::INT;
$$;

-- Перевірка на одному значенні
SELECT 1996 AS year, years_since(1996) AS years_diff;

-- Використання в запиті
SELECT
    e.entity,
    c.year,
    MAKE_DATE(c.year, 1, 1) AS start_of_year,
    CURRENT_DATE            AS today,
    years_since(c.year)     AS years_diff
FROM infectious_cases_normalized c
JOIN entities e ON e.id = c.entity_id
ORDER BY e.entity, c.year
LIMIT 20;

-- 5.2 Середня кількість захворювань за період
--     p_cases   — кількість захворювань за рік
--     p_divisor — кількість періодів у році (12 / 4 / 2)
CREATE OR REPLACE FUNCTION avg_cases_per_period(p_cases NUMERIC, p_divisor NUMERIC)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_divisor IS NULL OR p_divisor = 0 THEN
        RAISE EXCEPTION 'Divisor must be a non-zero number';
    END IF;
    RETURN p_cases / p_divisor;
END;
$$;

-- Використання в запиті: беремо лише записи, де Number_rabies — число.
-- Фільтруємо по вихідній текстовій колонці регулярним виразом,
-- тому порожні та нечислові значення відкидаються.
SELECT
    entity,
    code,
    year,
    number_rabies::NUMERIC                                    AS rabies_per_year,
    ROUND(avg_cases_per_period(number_rabies::NUMERIC, 12), 4) AS rabies_per_month,
    ROUND(avg_cases_per_period(number_rabies::NUMERIC, 4), 4)  AS rabies_per_quarter,
    ROUND(avg_cases_per_period(number_rabies::NUMERIC, 2), 4)  AS rabies_per_half_year
FROM infectious_cases
WHERE number_rabies ~ '^-?[0-9]+(\.[0-9]+)?$'
ORDER BY entity, year
LIMIT 20;
