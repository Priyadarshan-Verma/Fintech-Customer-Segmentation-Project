CREATE DATABASE IF NOT EXISTS fintech_seg;
USE fintech_seg;

-- customers
CREATE TABLE stg_customers (
  customer_id INT,
  name VARCHAR(100),
  age INT,
  income DECIMAL(10,2),
  city VARCHAR(50),
  registration_date DATE
);

-- transactions
CREATE TABLE stg_transactions (
  txn_id INT,
  customer_id INT,
  txn_date DATE,
  amount DECIMAL(10,2),
  category VARCHAR(50)
);


-- activity
CREATE TABLE stg_activity (
  customer_id INT,
  last_login_date DATE
);
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE stg_transactions;
TRUNCATE TABLE customers;

-- Row counts
SELECT 'customers', COUNT(*) FROM stg_customers;
SELECT 'transactions', COUNT(*) FROM stg_transactions;
SELECT 'activity', COUNT(*) FROM stg_activity;

-- Find duplicate customer IDs
SELECT customer_id, COUNT(*) AS cnt
FROM stg_customers
GROUP BY customer_id
HAVING cnt > 1;

-- Validating Date Columns

SELECT MIN(registration_date) AS min_reg_date,
       MAX(registration_date) AS max_reg_date
FROM stg_customers;

SELECT MIN(txn_date) AS min_txn_date,
       MAX(txn_date) AS max_txn_date
FROM stg_transactions;

SELECT MIN(last_login_date), MAX(last_login_date)
FROM stg_activity;


-- Validating Numeric Columns
-- Age
SELECT MIN(age) AS min_age, MAX(age) AS max_age
FROM stg_customers;

-- Income
SELECT MIN(income) AS min_income, MAX(income) AS max_income
FROM stg_customers;

-- Transaction Amounts
SELECT MIN(amount) AS min_amt, MAX(amount) AS max_amt, AVG(amount) AS avg_amt
FROM stg_transactions;

-- Add primary key to customers
ALTER TABLE stg_customers
ADD PRIMARY KEY (customer_id);

-- Add primary key to transactions (txn_id is unique)
ALTER TABLE stg_transactions
ADD PRIMARY KEY (txn_id);

-- Add foreign key from transactions to customers
ALTER TABLE stg_transactions
ADD CONSTRAINT fk_txn_customer
FOREIGN KEY (customer_id)
REFERENCES stg_customers(customer_id);

-- Add primary key to activity table (each customer has 1 record)
ALTER TABLE stg_activity
ADD PRIMARY KEY (customer_id);

-- Add foreign key from activity to customers
ALTER TABLE stg_activity
ADD CONSTRAINT fk_activity_customer
FOREIGN KEY (customer_id)
REFERENCES stg_customers(customer_id);

-- Creating table cusomer_metrics by joining all three tables 
CREATE TABLE customer_metrics AS
WITH txn_summary AS (
    SELECT 
        customer_id,
        COUNT(*) AS txn_count,
        SUM(amount) AS total_spent
    FROM stg_transactions
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.name,
    c.age,
    c.income,
    c.registration_date,
    a.last_login_date,
    COALESCE(ts.txn_count, 0) AS txn_count,
    COALESCE(ts.total_spent, 0) AS total_spent
FROM stg_customers c
LEFT JOIN txn_summary ts ON c.customer_id = ts.customer_id
LEFT JOIN stg_activity a ON c.customer_id = a.customer_id;


-- Creating VIEW cusomer_segementation with clearly defined segments 
CREATE OR REPLACE VIEW customer_segmentation AS
SELECT
    customer_id,
    name,
    age,
    income,
    registration_date,
    last_login_date,
    txn_count,
    total_spent,
    CASE
        WHEN registration_date >= (
            SELECT MAX(registration_date) - INTERVAL 30 DAY
            FROM stg_customers
        )
        AND txn_count < 2
            THEN 'New Customer'

        WHEN last_login_date < (
            SELECT MAX(last_login_date) - INTERVAL 90 DAY
            FROM stg_activity
        )
            THEN 'Inactive Customer'

        WHEN txn_count > 20
            THEN 'Power User'

        WHEN total_spent >= 10000 AND txn_count >= 5
            THEN 'High-Value Customer'

        WHEN total_spent BETWEEN 1000 AND 5000
            THEN 'Budget Customer'

        ELSE 'Others'
    END AS segment
FROM customer_metrics;

-- Count of Customers in Each Segment
SELECT segment, COUNT(*) AS num_customers
FROM customer_segmentation
GROUP BY segment
ORDER BY num_customers DESC;

-- Total and Average Spend per Segment
SELECT 
    segment,
    SUM(total_spent) AS total_spent_segment,
    AVG(total_spent) AS avg_spent_segment
FROM customer_segmentation
GROUP BY segment
ORDER BY total_spent_segment DESC;

-- Average Age & Income per Segment
SELECT 
    segment,
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(income), 2) AS avg_income
FROM customer_segmentation
GROUP BY segment;


-- Top 10 Customers by Spend
SELECT *
FROM customer_segmentation
ORDER BY total_spent DESC
LIMIT 10;

-- Inactive Customers List (with atleast one transaction)
SELECT customer_id, 
       name, 
       last_login_date, 
       txn_count
FROM customer_segmentation
WHERE segment = 'Inactive Customer'
  AND txn_count > 0
ORDER BY last_login_date;

SELECT 
    segment,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_segmentation),
        2
    ) AS percentage
FROM customer_segmentation
GROUP BY segment
ORDER BY customer_count DESC;

DROP TABLE IF EXISTS customer_metrics;

CREATE TABLE customer_metrics AS
WITH txn_summary AS (
    SELECT 
        customer_id,
        COUNT(*) AS txn_count,
        SUM(amount) AS total_spent,
        MAX(txn_date) AS last_txn_date
    FROM stg_transactions
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.name,
    c.age,
    c.income,
    c.registration_date,
    a.last_login_date,
    ts.last_txn_date,
    COALESCE(ts.txn_count, 0) AS txn_count,
    COALESCE(ts.total_spent, 0) AS total_spent
FROM stg_customers c
LEFT JOIN txn_summary ts 
    ON c.customer_id = ts.customer_id
LEFT JOIN stg_activity a 
    ON c.customer_id = a.customer_id;
    
    DROP TABLE IF EXISTS customer_rfm;

CREATE TABLE customer_rfm AS
SELECT
    customer_id,
    name,
    DATEDIFF(
        (SELECT MAX(txn_date) FROM stg_transactions),
        last_txn_date
    ) AS recency_days,
    txn_count AS frequency,
    total_spent AS monetary,
    NTILE(5) OVER (
        ORDER BY DATEDIFF(
            (SELECT MAX(txn_date) FROM stg_transactions),
            last_txn_date
        ) DESC
    ) AS r_score,
    NTILE(5) OVER (ORDER BY txn_count ASC) AS f_score,
    NTILE(5) OVER (ORDER BY total_spent ASC) AS m_score
FROM customer_metrics
WHERE last_txn_date IS NOT NULL;

SELECT 
    customer_id,
    name,
    last_txn_date,
    txn_count,
    total_spent
FROM customer_metrics
LIMIT 10;


DROP TABLE IF EXISTS customer_rfm_final;

CREATE TABLE customer_rfm_final AS
SELECT
    customer_id,
    name,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_code,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 
            THEN 'Champions'

        WHEN r_score >= 3 AND f_score >= 3 
            THEN 'Loyal Customers'

        WHEN r_score >= 4 AND f_score <= 2 
            THEN 'New/Promising'

        WHEN r_score <= 2 AND f_score >= 3 
            THEN 'At Risk'

        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 
            THEN 'Lost/Churned'

        ELSE 'Needs Attention'
    END AS rfm_segment
FROM customer_rfm;

SELECT 
    rfm_segment,
    COUNT(*) AS customer_count
FROM customer_rfm_final
GROUP BY rfm_segment
ORDER BY customer_count DESC;

SELECT *
FROM customer_rfm_final
ORDER BY r_score DESC, f_score DESC, m_score DESC
LIMIT 20;

CREATE OR REPLACE VIEW rfm_segmentation AS
SELECT *
FROM customer_rfm_final;

SELECT *
FROM rfm_segmentation
LIMIT 20;

SELECT 
    cs.customer_id,
    cs.name,
    cs.segment AS old_segment,
    r.rfm_segment AS new_segment,
    r.recency_days,
    r.frequency,
    r.monetary
FROM customer_segmentation cs
JOIN rfm_segmentation r 
    ON cs.customer_id = r.customer_id
ORDER BY cs.segment, r.rfm_segment;


SELECT 
    cs.customer_id,
    cs.name,
    cs.segment AS old_segment,
    r.rfm_segment AS new_segment,
    r.recency_days,
    r.frequency,
    r.monetary
FROM customer_segmentation cs
JOIN rfm_segmentation r 
    ON cs.customer_id = r.customer_id
WHERE cs.segment = 'Power User'
  AND r.rfm_segment IN ('At Risk', 'Needs Attention')
ORDER BY r.recency_days DESC;

SELECT 
    cs.segment AS old_segment,
    r.rfm_segment AS new_segment,
    COUNT(*) AS customer_count
FROM customer_segmentation cs
JOIN rfm_segmentation r 
    ON cs.customer_id = r.customer_id
GROUP BY cs.segment, r.rfm_segment
ORDER BY customer_count DESC;


SELECT
    rfm_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_revenue
FROM rfm_segmentation
GROUP BY rfm_segment
ORDER BY total_revenue DESC;

SELECT 
    cs.segment AS old_segment,
    r.rfm_segment AS new_segment,
    COUNT(*) AS customer_count
FROM customer_segmentation cs
JOIN rfm_segmentation r 
    ON cs.customer_id = r.customer_id
GROUP BY cs.segment, r.rfm_segment
ORDER BY cs.segment, customer_count DESC;