-- Cleaning rules for clean_sales (from 01_data_quality.sql):
-- 1. Keep only rows where quantity > 0 and price > 0.
-- 2. Exclude invoices starting with A and C.
-- 3. Exclude the 26 non-product stock codes.
-- 4. Remove exact duplicates, keeping one copy.
-- 5. Convert customer_id to VARCHAR via integer.
-- 6. Keep rows with NULL customer_id because these are guest checkouts where customer buys without creating an account. They still count toward revenue but they'll be excluded later in customer-level analysis (RFM, cohorts).
-- 7. Add a column revenue = quantity × price

CREATE OR REPLACE TABLE clean_sales AS
SELECT DISTINCT
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    price,
    CAST(CAST(customer_id AS BIGINT) AS VARCHAR) AS customer_id,
    country,
    ROUND(quantity * price, 2) AS revenue
FROM raw_transactions
WHERE quantity > 0 AND price > 0
  AND invoice NOT LIKE 'A%'
  AND invoice NOT LIKE 'C%'
  AND stock_code NOT IN ('POST', 'DOT', 'AMAZONFEE', 'M', 'D', 'S', 'BANK CHARGES', 'B', 'CRUK', 'm', 'GIFT', 'C2', 'C3')
  AND stock_code NOT LIKE 'gift_%'
  AND stock_code NOT LIKE 'TEST%' 
  AND stock_code NOT LIKE 'ADJUST%';
