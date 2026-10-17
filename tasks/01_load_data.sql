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
--   psql -d <db> -f tasks/01_load_data.sql
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
