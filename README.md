# Fintech Customer Segmentation Project

## Project Objective

The goal of this project is to perform **customer segmentation for a fintech application using MySQL**.

The project initially uses a **rule-based segmentation approach** based on transaction activity, spending, registration, and login behavior. It is then extended using **RFM (Recency, Frequency, Monetary) analysis** to provide a more behavior-driven view of customer value and engagement.

The analysis helps identify high-value, loyal, at-risk, inactive, and emerging customer groups that can support targeted retention, reactivation, and customer engagement strategies.

---

## Dataset

Three CSV tables were used:

### 1. `stg_customers`

Contains customer demographic and registration information:

* `customer_id`
* `name`
* `age`
* `income`
* `city`
* `registration_date`

### 2. `stg_transactions`

Contains customer transaction information:

* `txn_id`
* `customer_id`
* `txn_date`
* `amount`
* `category`

### 3. `stg_activity`

Contains customer login activity:

* `customer_id`
* `last_login_date`

---

## Major SQL Functions and Concepts Used

* `CREATE DATABASE`, `CREATE TABLE` → database and staging table creation
* `ALTER TABLE` → primary key and foreign key constraints
* `LEFT JOIN` → combining customer, transaction, and activity data
* `COALESCE()` → handling customers with no transactions
* `COUNT()`, `SUM()`, `AVG()`, `MAX()` → aggregation and customer-level metrics
* `CASE` → rule-based customer segmentation
* `CREATE VIEW` → reusable segmentation queries
* `GROUP BY` → segment-level analysis
* `ORDER BY` → ranking and sorting
* `DATEDIFF()` → calculating transaction recency
* `NTILE()` → assigning customers into RFM score groups
* Window functions → calculating RFM scores
* `CONCAT()` → creating combined RFM codes
* Common Table Expressions (`WITH`) → transaction-level aggregation

---

# Project Workflow

## 1. Create Staging Tables

Created staging tables for customers, transactions, and activity.

Primary keys and foreign keys were added to maintain relational integrity between the tables.

---

## 2. Load and Validate Data

Loaded the three CSV datasets into MySQL staging tables.

Basic validation was performed using:

* Row counts
* Duplicate customer ID checks
* Minimum and maximum dates
* Age and income ranges
* Transaction amount statistics

---

## 3. Create Customer-Level Metrics

Created the `customer_metrics` table by aggregating transaction data at the customer level and joining it with customer and activity information.

The table contains:

* Customer demographics
* Registration date
* Last login date
* Transaction count
* Total amount spent
* **Last transaction date**

The addition of `last_txn_date` was important for the later RFM analysis because RFM recency should be based on the customer's **last transaction**, rather than their last login.

---

# Part 1 — Rule-Based Customer Segmentation

## 4. Customer Segmentation

A rule-based segmentation model was initially created using a `CASE` statement.

The segments were defined as:

* **New Customer** → Registered within 30 days and fewer than 2 transactions
* **Inactive Customer** → Last login was more than 90 days ago
* **Power User** → More than 20 transactions
* **High-Value Customer** → Total spending ≥ 10,000 and at least 5 transactions
* **Budget Customer** → Total spending between 1,000 and 5,000
* **Others** → Remaining customers

The segmentation was stored in the `customer_segmentation` view for reuse.

> **Note:** The original segmentation is rule-based and conditions are evaluated from top to bottom. Therefore, a customer qualifying for multiple categories is assigned to the first matching segment.

---

## 5. Rule-Based Analysis

The initial analysis included:

* Number of customers per segment
* Total and average spending per segment
* Average age and income per segment
* Top customers by spending
* Inactive customers with transaction history

### Initial Segmentation Results

The original analysis identified **Power Users as the dominant high-activity segment**, with substantial transaction volume and spending.

The initial model also highlighted customers who had transaction history but had become inactive according to the login-based activity rule.

### Example: Top Power Users

| Customer ID | Name          | Age |  Income | Registration Date | Last Login | Txn Count | Total Spent |
| ----------: | ------------- | --: | ------: | ----------------- | ---------- | --------: | ----------: |
|          18 | Ankita Goyal  |  32 |  39,065 | 2024-05-20        | 2025-09-13 |        46 |     248,421 |
|          14 | Ishita Varma  |  20 | 100,021 | 2023-11-20        | 2025-09-12 |        46 |     225,623 |
|          17 | Arjun Sahu    |  21 |  32,239 | 2024-03-14        | 2025-09-11 |        50 |     225,234 |
|          28 | Priya Singh   |  28 |  52,059 | 2023-04-05        | 2025-09-13 |        46 |     222,055 |
|           3 | Aditya Bansal |  35 |  45,247 | 2023-01-28        | 2025-09-13 |        37 |     216,147 |

---

# Part 2 — RFM Segmentation Extension

## 6. Why RFM?

The original segmentation primarily relied on rules such as transaction count and last login.

This creates an important limitation:

> A customer can have a high historical transaction count but may not have transacted recently.

For example, a customer with 30+ transactions could still be classified as a **Power User**, even if their most recent transaction was several weeks ago.

To address this limitation, the project was extended using **RFM analysis**.

RFM evaluates customers using three dimensions:

| Metric        | Meaning                                    | Interpretation             |
| ------------- | ------------------------------------------ | -------------------------- |
| **Recency**   | Days since the customer's last transaction | Lower number = more recent |
| **Frequency** | Number of transactions                     | Higher = more active       |
| **Monetary**  | Total transaction value                    | Higher = more valuable     |

---

## 7. RFM Reference Date

Because the dataset is historical, the RFM calculation does **not** use the current system date.

Instead, recency is calculated relative to the **latest transaction date available in the dataset**.

This prevents the age of the dataset from artificially making all customers appear inactive.

The calculation is:

```sql
DATEDIFF(
    (SELECT MAX(txn_date) FROM stg_transactions),
    last_txn_date
)
```

Therefore:

* `0 days` = customer transacted on the final date in the dataset
* `10 days` = customer's last transaction was 10 days before the dataset ended
* `50 days` = customer's last transaction was 50 days before the dataset ended

---

## 8. RFM Scoring

Customers were divided into five groups for each RFM dimension using `NTILE(5)`.

### Recency Score

Customers with more recent transactions receive higher scores:

* **5** → Most recent
* **1** → Least recent

### Frequency Score

Customers with more transactions receive higher scores:

* **5** → Highest frequency
* **1** → Lowest frequency

### Monetary Score

Customers with higher total spending receive higher scores:

* **5** → Highest spending
* **1** → Lowest spending

The three scores are combined into an RFM code.

For example:

```text
555 → Very recent + highly frequent + high spending
```

---

## 9. RFM Segment Definitions

The RFM scores were converted into business-oriented customer segments:

| RFM Segment         | Definition                                                 |
| ------------------- | ---------------------------------------------------------- |
| **Champions**       | High Recency + High Frequency + High Monetary              |
| **Loyal Customers** | Good Recency + Good Frequency                              |
| **New/Promising**   | Recent customers with relatively low frequency             |
| **At Risk**         | Low Recency but relatively high historical frequency       |
| **Lost/Churned**    | Low Recency + Low Frequency + Low Monetary                 |
| **Needs Attention** | Customers falling outside the stronger segment definitions |

---

# 10. RFM Analysis Results

The RFM model produced the following distribution:

| RFM Segment     | Customers | Avg. Recency (Days) | Avg. Frequency | Avg. Monetary | Total Revenue |
| --------------- | --------: | ------------------: | -------------: | ------------: | ------------: |
| Loyal Customers |        24 |                 9.1 |           32.6 |    ₹96,263.13 |    ₹23,10,315 |
| Champions       |        16 |                 6.4 |           39.9 |  ₹1,38,165.75 |    ₹22,10,652 |
| At Risk         |        20 |                31.7 |           35.0 |    ₹87,217.70 |    ₹17,44,354 |
| Lost/Churned    |        16 |                50.6 |           21.7 |    ₹26,172.56 |     ₹4,18,761 |
| Needs Attention |        12 |                22.7 |           22.1 |    ₹32,147.75 |     ₹3,85,773 |
| New/Promising   |        12 |                 5.7 |           22.3 |    ₹31,925.50 |     ₹3,83,103 |

### Key observations

**Champions** are the strongest customer group, with the highest average frequency at **39.9 transactions** and the highest average monetary value at approximately **₹1.38 lakh**.

**Loyal Customers** represent the largest segment with **24 customers** and contribute approximately **₹23.10 lakh** in total revenue.

**At Risk customers are particularly important.** They have an average frequency of **35 transactions** and average spending of approximately **₹87,218**, but their average recency is **31.7 days**. This indicates that many historically valuable customers have not transacted recently.

**Lost/Churned customers** have the weakest overall profile, with the highest average recency of **50.6 days**, lower frequency, and substantially lower monetary value.

---

# 11. Comparing Rule-Based Segmentation with RFM

The most useful extension of the project was comparing the original segmentation with RFM.

The original model classified customers primarily using transaction count and other fixed rules.

RFM considers **when the customer last transacted**, along with transaction frequency and monetary value.

### Example: Power Users Identified as At Risk

The comparison identified customers who were classified as **Power Users** under the original model but were classified as **At Risk** or **Needs Attention** under RFM.

Examples include:

| Customer       | Old Segment | RFM Segment     | Recency | Frequency |  Monetary |
| -------------- | ----------- | --------------- | ------: | --------: | --------: |
| Deepika Rao    | Power User  | At Risk         | 60 days |        27 |   ₹38,154 |
| Raj Sinha      | Power User  | At Risk         | 54 days |        31 |   ₹39,079 |
| Pallavi Thakur | Power User  | At Risk         | 49 days |        28 |   ₹51,554 |
| Nisha Yadav    | Power User  | Needs Attention | 48 days |        21 |   ₹39,172 |
| Pallavi Singh  | Power User  | At Risk         | 44 days |        46 | ₹1,17,741 |

### Key Insight

This demonstrates a limitation of the original rule-based model:

> **High historical transaction frequency does not necessarily mean that a customer is currently active.**

RFM identifies customers who were historically active but whose transaction recency has deteriorated, allowing them to be targeted for retention or reactivation before they become fully inactive.

---

# 12. Business Recommendations

### Champions

Focus on retention and loyalty.

Potential strategies include:

* Premium benefits
* Loyalty rewards
* Early access to new financial products
* Personalized offers

### Loyal Customers

Encourage continued engagement and movement toward the Champions segment through:

* Cross-selling
* Personalized product recommendations
* Loyalty programs

### At Risk

This is the most important retention segment.

Customers have demonstrated significant historical value but have not transacted recently.

Potential actions:

* Re-engagement campaigns
* Personalized offers
* Transaction incentives
* Reminders about relevant fintech products

### Lost/Churned

Focus on selective win-back strategies rather than aggressive spending.

Potential actions:

* Targeted reactivation offers
* Feedback surveys
* Product or service improvement campaigns

### New/Promising

Focus on onboarding and increasing transaction frequency.

Potential actions:

* First/second transaction incentives
* Product education
* Personalized onboarding journeys

---

# 13. Project Conclusion

The project demonstrates two complementary approaches to fintech customer segmentation.

The **initial rule-based model** provides a simple and interpretable way to classify customers based on predefined business rules.

The **RFM extension** provides a more dynamic view by combining:

**Recency + Frequency + Monetary Value**

The comparison shows why recency is particularly important. Several customers identified as **Power Users** under the original model were classified as **At Risk** or **Needs Attention** by RFM because their most recent transactions were relatively old.

Therefore, RFM provides a stronger basis for **customer retention, reactivation, and targeted engagement**, while the original rule-based model remains useful as a simple and transparent baseline.

---

## Project Structure

```text
Fintech Customer Segmentation Project
│
├── Raw CSV Data
│   ├── Customers
│   ├── Transactions
│   └── Activity
│
├── MySQL Data Preparation
│   ├── Staging Tables
│   ├── Data Validation
│   └── Customer Metrics
│
├── Rule-Based Segmentation
│   ├── Customer Segmentation View
│   ├── Segment Analysis
│   └── Customer Profiling
│
├── RFM Extension
│   ├── Transaction-Based Recency
│   ├── RFM Scores
│   ├── RFM Segments
│   └── Old vs RFM Comparison
│
└── Business Insights
    ├── Customer Value
    ├── Retention Opportunities
    ├── At-Risk Customers
    └── Reactivation Opportunities
```

## Skills Demonstrated

**MySQL | SQL | Data Cleaning | Data Validation | Joins | CTEs | Window Functions | RFM Analysis | Customer Segmentation | Business Analytics | Customer Retention Analysis**
