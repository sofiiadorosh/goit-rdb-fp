-- Завдання 2. Нормалізація таблиці infectious_cases до 3НФ
-- Проблема вихідної таблиці: пара (entity, code) повторюється в кожному
-- рядку, а code функціонально залежить від entity (транзитивна залежність).
-- Виносимо її в окрему таблицю entities, а в таблиці показників
-- посилаємося на неї через entity_id.

SET search_path TO pandemic;

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
