# **# Fintech Customer Segmentation Project**



### \## Project Objective

##### The goal of this project is to perform \*\*customer segmentation\*\* for a fintech app using MySQL.  

##### The segmentation helps understand customer behavior, spending patterns, and engagement levels, which can drive targeted marketing and product strategies.



---



###### \## Dataset

Three CSV tables were used:



1\. \*\*stg\_customers\*\*

&nbsp;  - customer\_id, name, age, income, city, registration\_date



2\. \*\*stg\_transactions\*\*

&nbsp;  - txn\_id, customer\_id, txn\_date, amount, category



3\. \*\*stg\_activity\*\*

&nbsp;  - customer\_id, last\_login\_date



---



#### \## Major SQL Functions and Concepts Used

###### \- `CREATE TABLE`, `ALTER TABLE` → to create staging tables and define primary keys \& foreign keys

###### \- `LEFT JOIN` → to combine customer, transaction, and activity data

###### \- `COALESCE()` → handle NULL values (e.g., customers with no transactions)

###### \- Aggregate functions: `COUNT()`, `SUM()`, `AVG()`

###### \- `CASE` → to assign customers to segments

###### \- `CREATE VIEW` → to store segmentation query for reuse

###### \- `GROUP BY` → for analysis like total spend per segment

###### \- `ORDER BY` → to rank or sort customers



---



### \## Steps



###### 1\. Create Staging Tables

&nbsp;  - Created tables for customers, transactions, and activity.

&nbsp;  - Assigned primary keys and foreign keys for relational integrity.



###### 2\. Load Data

&nbsp;  - Loaded sample/fixed data into staging tables.



###### 3\. Aggregate Metrics

&nbsp;  - Created a `customer\_metrics` table combining:

&nbsp;    - Total transactions per customer

&nbsp;    - Total amount spent

&nbsp;    - Last login date

&nbsp;    - Registration date



###### 4\. Customer Segmentation

&nbsp;  - Assigned each customer to one of five segments using `CASE`:

&nbsp;    - \*\*New Customer\*\*: Registered within 30 days, < 2 transactions

&nbsp;    - \*\*Inactive Customer\*\*: Last login > 90 days

&nbsp;    - \*\*Power User\*\*: txn\_count > 20

&nbsp;    - \*\*High-Value Customer\*\*: total\_spent >= 10,000 AND txn\_count >= 5

&nbsp;    - \*\*Budget Customer\*\*: total\_spent between 1,000 and 5,000

&nbsp;    - \*\*Others\*\*: remaining customers

&nbsp;  - Created a view `customer\_segmentation` for reuse.



###### 5\. Analysis \& Insights

&nbsp;  - Count of customers per segment

&nbsp;  - Total and average spend per segment

&nbsp;  - List of top spenders (Power Users)

&nbsp;  - List of inactive customers with txn\_count > 0

&nbsp;  - Average age and income per segment



---



#### \## Analysis Results



###### \### Total \& Average Spend per Segment



| Segment             | Total Spent  | Avg Spent |

|---------------------|--------------|-----------|

| Power User          | 6,790,198.00 | 85,951.87 |

| Inactive Customer   | 533,399.00   | 11,595.63 |

| High-Value Customer | 129,361.00   | 21,560.17 |

| Others              | 0.00         | 0.00      |

| New Customer        | 0.00         | 0.00      |



---



###### \### Top 10 Power Users (Sample)



| customer\_id | name          | age | income    | registration\_date | last\_login\_date | txn\_count | total\_spent | segment     |

|-------------|---------------|-----|-----------|-----------------|----------------|-----------|-------------|------------|

| 18          | Ankita Goyal  | 32  | 39,065.00 | 2024-05-20      | 2025-09-13     | 46        | 248,421.00  | Power User |

| 14          | Ishita Varma  | 20  | 100,021.00| 2023-11-20      | 2025-09-12     | 46        | 225,623.00  | Power User |

| 17          | Arjun Sahu    | 21  | 32,239.00 | 2024-03-14      | 2025-09-11     | 50        | 225,234.00  | Power User |

| 28          | Priya Singh   | 28  | 52,059.00 | 2023-04-05      | 2025-09-13     | 46        | 222,055.00  | Power User |

| 3           | Aditya Bansal | 35  | 45,247.00 | 2023-01-28      | 2025-09-13     | 37        | 216,147.00  | Power User |

| 15          | Harsh Naidu   | 25  | 60,071.00 | 2024-12-23      | 2025-09-14     | 42        | 214,368.00  | Power User |

| 11          | Manish Lal    | 26  | 26,065.00 | 2023-08-03      | 2025-09-14     | 41        | 208,173.00  | Power User |

| 8           | Aditya Lal    | 36  | 119,615.00| 2024-07-19      | 2025-09-14     | 40        | 196,554.00  | Power User |

| 2           | Arjun Kapoor  | 28  | 81,395.00 | 2024-03-08      | 2025-09-12     | 39        | 191,884.00  | Power User |

| 4           | Abhishek Pandey | 42 | 124,987.00| 2025-08-30     | 2025-09-10     | 36        | 185,428.00  | Power User |



---



###### \### Inactive Customers with txn\_count > 0 (Sample)



| customer\_id | name         | last\_login\_date | txn\_count |

|-------------|--------------|----------------|-----------|

| 58          | Harsh Sharma | 2025-04-06     | 26        |

| 59          | Chetan Joshi | 2025-04-16     | 28        |

| 47          | Ananya Nair  | 2025-04-18     | 28        |

| 98          | Aditi Chopra | 2025-05-08     | 22        |

| 45          | Akash Verma  | 2025-05-14     | 23        |



---

###### 

###### \### Number of Customers per Segment



| Segment             | num\_customers |

|--------------------|---------------|

| Power User          | 79            |

| Others              | 65            |

| Inactive Customer   | 46            |

| High-Value Customer | 6             |

| New Customer        | 4             |



---



#### \## Conclusion

###### \- \*\*Power Users\*\* generate the most revenue and are highly engaged.  

###### \- \*\*Inactive Customers\*\* still have some transaction history — target for reactivation campaigns.  

###### \- \*\*High-Value Customers\*\* contribute significant spend relative to their number.  

###### \- \*\*New Customers\*\* and \*\*Others\*\* are smaller segments — can focus on onboarding and upselling strategies.  



---












