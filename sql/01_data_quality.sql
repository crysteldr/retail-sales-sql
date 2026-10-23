-- Data quality checks: Online Retail II
-- Table: raw_transactions
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Q1: What date range does the data cover? 
-- Result: 2009-12-01 07:45 to 2011-12-09 12:50
SELECT MIN(invoice_date) AS first_date,
    MAX(invoice_date) AS last_date
FROM raw_transactions;

-- Q2: How many rows have no customer_id? 
-- Result: 243,007 (22.8%)
SELECT COUNT(*) AS total_rows,
    COUNT(*) - COUNT(customer_id) AS null_customer_rows,
    ROUND(100.0 * (COUNT(*) - COUNT(customer_id)) / COUNT(*), 1) AS pct_null
FROM raw_transactions;

-- Q3: Which invoices start with a letter, and what do they mean?
-- Result: A = 6 rows, C = 19,494 rows or 1.83% 
-- Meaning: A = adjustments of bad debt, C = cancellations -> both excluded from sales.
SELECT LEFT(invoice, 1) AS invoice_first_char,
    COUNT(*) AS invoice_rows,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_transactions), 3) AS pct_of_all_rows
FROM raw_transactions
WHERE NOT regexp_matches(invoice, '^[0-9]')
GROUP BY LEFT(invoice, 1)
ORDER BY invoice_first_char;

-- Q4: How many rows have quantity <= 0 or price <= 0?
-- Result: Quantity <= 0 = 22,950 rows, Price <= 0 = 6,207 rows
-- Meaning: 3,457 non-C rows = inventory adjustments; 5 price < 0 rows = A rows. Keep quantity > 0 and price > 0 for sales analysis.

-- For quantity <= 0:
SELECT COUNT(*) AS qty_le_zero
FROM raw_transactions
WHERE quantity <= 0; 

-- For quantity <= 0, but non-C: 
SELECT COUNT(*) AS qty_le_zero_not_c
FROM raw_transactions
WHERE quantity <= 0 AND invoice NOT LIKE 'C%';

-- For price <= 0:
SELECT COUNT(*) AS price_le_zero
FROM raw_transactions
WHERE price <= 0;

-- For price < 0:
SELECT COUNT(*) AS price_lt_zero
FROM raw_transactions
WHERE price < 0;

-- For price = 0:
SELECT COUNT(*) AS price_eq_zero
FROM raw_transactions
WHERE price = 0;

-- Q5: How many rows are exact duplicates?
-- Result: 34,335 rows (3.22%)
WITH counts AS (
    SELECT
        (SELECT COUNT(*) FROM raw_transactions) AS total_rows,
        (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw_transactions) AS t) AS unique_rows
)
SELECT total_rows,
    unique_rows,
    total_rows - unique_rows AS duplicate_rows,
    ROUND(100.0 * (total_rows - unique_rows) / total_rows, 2) AS pct_duplicate
FROM counts;

-- To see actual duplicate invoices:
SELECT invoice, stock_code, description, quantity, invoice_date, price, customer_id, country,
        COUNT(*) AS times_seen
FROM raw_transactions
GROUP BY ALL
HAVING COUNT(*) > 1
ORDER BY times_seen DESC
LIMIT 10;

-- Q6: Which stock codes aren't real products?
-- Result: 62 codes don't start with 5 digits; 26 are not products (5,913 rows, 0.55%)
-- Meaning: postage, fees, discounts, manual entries, adjustments, vouchers, tests -> excluded
SELECT stock_code,
    COUNT(*) AS stock_code_count,
    ANY_VALUE(description) AS example_description,
        CASE
            WHEN stock_code IN ('POST', 'DOT', 'AMAZONFEE', 'M', 'D', 'S', 'BANK CHARGES', 'B', 'CRUK', 'm', 'GIFT', 'C2', 'C3') THEN 'not product'
            WHEN stock_code LIKE 'gift_%' THEN 'not product'
            WHEN stock_code LIKE 'TEST%' THEN 'not product'
            WHEN stock_code LIKE 'ADJUST%' THEN 'not product'
            ELSE 'product'
        END AS category
FROM raw_transactions
WHERE NOT regexp_matches(stock_code, '^[0-9]{5}')
GROUP BY stock_code
ORDER BY category DESC, stock_code_count DESC;


-- Count codes, rows, and % per category: 
WITH codes AS (
    SELECT stock_code,
        COUNT(*) AS stock_code_count,
        ANY_VALUE(description) AS example_description,
            CASE
                WHEN stock_code IN ('POST', 'DOT', 'AMAZONFEE', 'M', 'D', 'S', 'BANK CHARGES', 'B', 'CRUK', 'm', 'GIFT', 'C2', 'C3') THEN 'not product'
                WHEN stock_code LIKE 'gift_%' THEN 'not product'
                WHEN stock_code LIKE 'TEST%' THEN 'not product'
                WHEN stock_code LIKE 'ADJUST%' THEN 'not product'
                ELSE 'product'
            END AS category
    FROM raw_transactions
    WHERE NOT regexp_matches(stock_code, '^[0-9]{5}')
    GROUP BY stock_code
)
SELECT category,
    COUNT(*) AS num_codes,
    SUM(stock_code_count) AS num_rows,
    ROUND(100.0 * SUM(stock_code_count) / (SELECT COUNT(*) FROM raw_transactions), 2) AS pct_of_all_rows
FROM codes
GROUP BY category;

-- Q7: Is customer_id stored correctly? 
-- Result: Stored as DOUBLE (e.g. 13085.0) -> convert to VARCHAR (via integer) in data cleaning.
DESCRIBE raw_transactions;