-- Завдання 1. Завантаження даних

-- Створюємо схему та робимо її схемою за замовчуванням
CREATE SCHEMA IF NOT EXISTS pandemic;
SET search_path TO pandemic;

-- Таблиця для «сирих» даних з CSV.
-- Усі показники зберігаються як TEXT, щоб імпорт пройшов без втрат
-- (у файлі є порожні значення та дробові числа).
DROP TABLE IF EXISTS infectious_cases CASCADE;

CREATE TABLE infectious_cases (
    entity               TEXT,
    code                 TEXT,
    year                 INT,
    number_yaws          TEXT,
    polio_cases          TEXT,
    cases_guinea_worm    TEXT,
    number_rabies        TEXT,
    number_malaria       TEXT,
    number_hiv           TEXT,
    number_tuberculosis  TEXT,
    number_smallpox      TEXT,
    number_cholera_cases TEXT
);

-- Імпорт CSV. Запускати з кореня репозиторію:
--   psql -d <db> -f common.sql
-- FORCE_NOT_NULL зберігає порожні клітинки як '' (а не NULL),
-- тобто так само, як їх імпортує майстер імпорту DBeaver / pgAdmin.
\copy infectious_cases FROM 'data/infectious_cases.csv' WITH (FORMAT csv, HEADER true, FORCE_NOT_NULL (code, number_yaws, polio_cases, cases_guinea_worm, number_rabies, number_malaria, number_hiv, number_tuberculosis, number_smallpox, number_cholera_cases))

-- Перегляд структури та вмісту
SELECT COUNT(*) AS total_rows FROM infectious_cases;

SELECT *
FROM infectious_cases
LIMIT 10;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'pandemic'
  AND table_name = 'infectious_cases'
ORDER BY ordinal_position;


-- Завдання 2. Нормалізація таблиці infectious_cases до 3НФ
-- Проблема вихідної таблиці: пара (entity, code) повторюється в кожному
-- рядку, а code функціонально залежить від entity (транзитивна залежність).
-- Виносимо її в окрему таблицю entities, а в таблиці показників
-- посилаємося на неї через entity_id.

DROP TABLE IF EXISTS infectious_cases_normalized;
DROP TABLE IF EXISTS entities;

-- 1) Унікальні комбінації Entity + Code
CREATE TABLE entities (
    id     SERIAL PRIMARY KEY,
    entity TEXT NOT NULL,
    code   TEXT,                      -- NULL для регіонів без ISO-коду
    CONSTRAINT uq_entities UNIQUE (entity, code)
);

INSERT INTO entities (entity, code)
SELECT DISTINCT entity, NULLIF(code, '')
FROM infectious_cases
ORDER BY entity;

-- 2) Основні показники захворювань з посиланням на entities.id
--    Порожні рядки перетворюємо на NULL, значення — на NUMERIC.
CREATE TABLE infectious_cases_normalized (
    id                   SERIAL PRIMARY KEY,
    entity_id            INT NOT NULL REFERENCES entities (id),
    year                 INT NOT NULL,
    number_yaws          NUMERIC,
    polio_cases          NUMERIC,
    cases_guinea_worm    NUMERIC,
    number_rabies        NUMERIC,
    number_malaria       NUMERIC,
    number_hiv           NUMERIC,
    number_tuberculosis  NUMERIC,
    number_smallpox      NUMERIC,
    number_cholera_cases NUMERIC,
    CONSTRAINT uq_entity_year UNIQUE (entity_id, year)
);

INSERT INTO infectious_cases_normalized (
    entity_id, year,
    number_yaws, polio_cases, cases_guinea_worm, number_rabies,
    number_malaria, number_hiv, number_tuberculosis,
    number_smallpox, number_cholera_cases
)
SELECT
    e.id,
    ic.year,
    NULLIF(ic.number_yaws, '')::NUMERIC,
    NULLIF(ic.polio_cases, '')::NUMERIC,
    NULLIF(ic.cases_guinea_worm, '')::NUMERIC,
    NULLIF(ic.number_rabies, '')::NUMERIC,
    NULLIF(ic.number_malaria, '')::NUMERIC,
    NULLIF(ic.number_hiv, '')::NUMERIC,
    NULLIF(ic.number_tuberculosis, '')::NUMERIC,
    NULLIF(ic.number_smallpox, '')::NUMERIC,
    NULLIF(ic.number_cholera_cases, '')::NUMERIC
FROM infectious_cases ic
JOIN entities e
  ON e.entity = ic.entity
 AND e.code IS NOT DISTINCT FROM NULLIF(ic.code, '');

-- Перевірка
SELECT COUNT(*) AS entities_count FROM entities;
SELECT COUNT(*) AS cases_count    FROM infectious_cases_normalized;

SELECT * FROM entities LIMIT 10;
SELECT * FROM infectious_cases_normalized LIMIT 10;


-- Завдання 3. Аналіз Number_rabies
-- Для кожної пари Entity + Code: середнє, мінімум, максимум і сума.
-- Рядки без значення (NULL) агрегатні функції ігнорують; країни, у яких
-- немає жодного значення, відкидаємо, щоб вони не потрапили в топ
-- (у PostgreSQL NULL при DESC стоїть першим).

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


-- Завдання 4. Колонка різниці в роках (вбудовані функції)

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


-- Завдання 5. Власні функції

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
