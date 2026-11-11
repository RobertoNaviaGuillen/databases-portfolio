-- Round 7 curiosity: part_price is stored as TEXT in flat_jobpart (printf returns text).
--   sqlite3 module-05/normalize.db ".read module-05/harvest-price-text.sql"
.headers on
.mode column
SELECT typeof(part_price) AS flat_type,
       MIN(part_price) AS text_min, MAX(part_price) AS text_max,
       MIN(CAST(part_price AS REAL)) AS real_min, MAX(CAST(part_price AS REAL)) AS real_max
FROM flat_jobpart;
SELECT typeof(part_price) AS part_table_type FROM part LIMIT 1;
