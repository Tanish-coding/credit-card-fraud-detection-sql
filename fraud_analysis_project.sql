-- Phase 1 - Data setup & validation
select *
from fraud_analysis.transactions limit 100 ;

select Count(*) AS total_rows
from fraud_analysis.transactions;

select
 Count(*) AS total_rows,
 count(Distinct transaction_id) as unique_transactions
 from fraud_analysis.transactions;
 
 select *
 from fraud_analysis.transactions
 where transaction_id is null
  or amount is null
  or transaction_hour is null
  or merchant_category is null
  or foreign_transaction is null
  or location_mismatch is null
  or device_trust_score is null
  or velocity_last_24h is null
  or cardholder_age is null
  or is_fraud is null;
  
  select 
  min(amount) as min_amount,
  max(amount) as max_amount,
  max(device_trust_score) as min_trust,
  max(device_trust_score) as max_trust
  from fraud_analysis.transactions;
  
-- Phase 2 - Exploratory Data Analysis
  
  select merchant_category,count(*) as total_transactions
  from fraud_analysis.transactions
  group by (merchant_category);
  
  select merchant_category,count(*) as fraud_transactions
  from fraud_analysis.transactions
  where is_fraud=1
  group by (merchant_category) ;
  
  select (sum(is_fraud) * 100 / count(*)) as fraud_percentage
  from fraud_analysis.transactions;
  
  select transaction_hour,count(*) as total_transactions
  from fraud_analysis.transactions
  group by transaction_hour
  order by transaction_hour;
  
  -- phase 3 - Fraud overview & CASE Analysis
  
  select foreign_transaction,count(*) as total_transactions,
  sum(is_fraud) as fraud_transaction ,
  (sum(is_fraud)*100/count(*)) as fraud_rate 
  from fraud_analysis.transactions
  group by (foreign_transaction)
  order by(foreign_transaction);
  
  select merchant_category,
  count(*) as total_transactions,
  sum(is_fraud) as fraud_transaction,
  round((sum(is_fraud)*100.0/count(*)),2) as fraud_rate 
  from fraud_analysis.transactions
  group by(merchant_category)
  order by fraud_rate desc;

  select count(*) as total_transactions,
		sum(is_fraud) as fraud_transaction,
        count(*)-sum(is_fraud) as non_fraud_transactions
from fraud_analysis.transactions;

select transaction_hour, sum(is_fraud) as fraud_transaction
from fraud_analysis.transactions
group by  transaction_hour
order by fraud_transaction desc;

select transaction_hour, sum(is_fraud) as fraud_transaction
from fraud_analysis.transactions
group by  transaction_hour
order by fraud_transaction desc
limit 1 ;

select location_mismatch,
count(*) as total_transactions,
sum(is_fraud) as fraud_transaction,
round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from fraud_analysis.transactions
group by location_mismatch;

select
case 
     when device_trust_score<40 then 'low_trust'
     when device_trust_score between 40 and 70 then 'medium_trust'
	when device_trust_score>70 then 'high_trust'
end as bucket,
count(*) as total_transactions,
sum(is_fraud) as fraud_transaction,
round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from fraud_analysis.transactions
group by bucket
order by fraud_rate desc;

select 
       count(*) as total_transactions,
       sum(is_fraud) as fraud_transaction,
       round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate,
       case
           when velocity_last_24h<5 then "low_velocity"
           when velocity_last_24h between 5 and 10 then "medium_velocity"
           else "high_velocity"
       end as bucket
       from fraud_analysis.transactions
       group by bucket
       order by fraud_rate desc;

select 
case
    when cardholder_age<25 then "young"
    when cardholder_age between 25 and 50 then "adult"
	when cardholder_age>50 then "senior"        
end as bucket,
count(*) as total_transactions,
       sum(is_fraud) as fraud_transaction,
       round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from fraud_analysis.transactions
group by bucket
order by fraud_rate desc;

select
case
    when foreign_transaction=1 and location_mismatch=1 then "high risk"
    else "normal risk"
end as bucket,
count(*) as total_transactions,
       sum(is_fraud) as fraud_transaction,
       round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from fraud_analysis.transactions
group by bucket
order by fraud_rate desc;

select 
case
    when amount<200 then "low_amount"
    when amount between 200 and 500 then "medium_amount"
    when amount>500 then "high_transaction"
end as bucket,
count(*) as total_transactions,
       sum(is_fraud) as fraud_transaction,
       round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from fraud_analysis.transactions
group by bucket
order by fraud_rate;

-- Phase 4 - Fraud Pattern Analysis

SELECT merchant_category,
COUNT(*) AS total_transactions,
SUM(is_fraud) AS fraud_transactions,
ROUND((SUM(is_fraud) * 100.0 / COUNT(*)),2) AS fraud_rate,
AVG(amount) AS avg_amount
FROM transactions
WHERE
foreign_transaction = 1
AND location_mismatch = 1
AND device_trust_score < 40
AND velocity_last_24h > 0
GROUP BY merchant_category
ORDER BY fraud_rate DESC;

SELECT merchant_category,transaction_hour,COUNT(*) AS total_transactions,SUM(is_fraud) AS fraud_transactions,
ROUND(
    (SUM(is_fraud) * 100.0 / COUNT(*)),2) AS fraud_rate
FROM transactions
GROUP BY
merchant_category,transaction_hour
ORDER BY fraud_rate DESC;
     
WITH customer_risk AS (
    SELECT transactions.customer_id,customers.customer_name,customers.city,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND((SUM(is_fraud) * 100.0 / COUNT(*)),2) AS fraud_rate,
	ROUND(SUM(amount),2) AS total_amount
FROM transactions
INNER JOIN customers
    ON transactions.customer_id = customers.customer_id
GROUP BY
    transactions.customer_id,customers.customer_name,customers.city
)
SELECT
customer_name,city,fraud_transactions,fraud_rate,total_amount,
RANK() OVER(
    ORDER BY fraud_transactions DESC
) AS fraud_rank
FROM customer_risk;
                 
WITH fraud_investigation AS (
SELECT
transactions.transaction_id,customers.customer_name,customers.city,amount,transaction_hour,merchant_category,
foreign_transaction,location_mismatch,device_trust_score,velocity_last_24h,is_fraud,
CASE
WHEN foreign_transaction = 1
AND location_mismatch = 1
AND device_trust_score < 40
AND velocity_last_24h > 10 THEN 'high_risk'
WHEN foreign_transaction = 1
OR device_trust_score < 40
OR velocity_last_24h > 10 THEN 'medium_risk'
ELSE 'low_risk'
END AS risk_level
FROM transactions
INNER JOIN customers
ON transactions.customer_id = customers.customer_id
)
SELECT
customer_name,city,merchant_category,amount,transaction_hour,risk_level,is_fraud,
RANK() OVER(ORDER BY amount DESC) AS amount_rank
FROM fraud_investigation
ORDER BY amount_rank;

-- Phase 5 - Risk Segmentation

select
case 
 when foreign_transaction=1 and location_mismatch=1 and device_trust_score < 40 then "high_risk"
 when foreign_transaction=1 or velocity_last_24h>10 or device_trust_score < 40 then "medium_risk"
 else "low_risk"
end as risk_level,
count(*) as total_transactions
from transactions
group by risk_level;

select
case 
 when foreign_transaction=1 and location_mismatch=1 and device_trust_score < 40 then "high_risk"
 when foreign_transaction=1 or velocity_last_24h>10 or device_trust_score < 40 then "medium_risk"
 else "low_risk"
end as risk_level,
count(*) as total_transactions,
sum(is_fraud) as fraud_transaction,
       round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from transactions
group by risk_level
order by fraud_rate desc;

select merchant_category,
count(*) as high_risk_transactions,
       avg(amount) as avg_amount
from transactions
 where foreign_transaction=1 and location_mismatch=1 and device_trust_score < 40
group by merchant_category 
order by high_risk_transactions desc;

select merchant_category,
case
 when foreign_transaction=1 and location_mismatch=1 and device_trust_score < 40 then "high_risk"
 when foreign_transaction=1 or velocity_last_24h>10 or device_trust_score < 40 then "medium_risk"
 else "low_risk"
end as risk_level,
count(*) as total_transactions
from transactions
group by merchant_category,risk_level
order by merchant_category,total_transactions desc;

select transaction_hour,
count(*) as total_transactions,
sum(is_fraud) as fraud_transaction,
round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from transactions
group by transaction_hour
order by fraud_rate desc;

-- Phase 6 - Advanced SQL Analytics

with fraud_transaction as (
select *
from transactions
where is_fraud = 1
)
select
merchant_category,
count(*) as fraud_count
from fraud_transaction
group by merchant_category
order by fraud_count desc;

select transaction_id,amount,merchant_category,is_fraud
from transactions
where amount> (
      select avg(amount)
      from transactions
                       )
order by amount desc;                     

with category_fraud as (
	 select merchant_category,
     sum(is_fraud) as fraud_count
     from transactions
     group by merchant_category
     )
     select 
     merchant_category,
     fraud_count,
     rank() over(
                 order by fraud_count desc
                 ) as fraud_rank
                 from category_fraud;
               
with hourly_fraud as (
     select 
     transaction_hour,
     sum(is_fraud) as fraud_transaction,
      round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
	  from transactions
      group by transaction_hour
      )
select
transaction_hour,fraud_transaction,fraud_rate,
dense_rank() over(
                  order by fraud_rate desc )
                  as risky_rank
from hourly_fraud;

with customer_transaction as
     ( select
	customer_id,transaction_id,amount,
    row_number () over (
				partition by customer_id
                order by amount desc
                ) as row_num
     from transactions)
     select 
     customer_id,transaction_id,amount,row_num
     from customer_transaction
     where row_num = 1;
     
     WITH customer_risk AS (
    SELECT
    customers.customer_name,customers.city,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND((SUM(is_fraud) * 100.0 / COUNT(*)),2) AS fraud_rate,
    ROUND(SUM(amount),2) AS total_amount
    FROM transactions
    INNER JOIN customers
    ON transactions.customer_id = customers.customer_id
    GROUP BY transactions.customer_id, customers.customer_name, customers.city
    )
SELECT customer_name,city,fraud_transactions,fraud_rate,total_amount,
RANK() OVER(ORDER BY fraud_transactions DESC) AS fraud_rank
FROM customer_risk;

-- Phase 7 — JOIN Operations & Customer Analysis
select *
from fraud_analysis.customers;

select 
transaction_id,amount,customer_name,city,is_fraud
from transactions
inner join customers
on transactions.customer_id = customers.customer_id;

select city,
	   count(*) as total_transactions,
       sum(is_fraud) as fraud_transaction,
       round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from transactions
inner join customers
on  transactions.customer_id = customers.customer_id
group by city
order by city asc;

select account_type,
count(*) as total_transactions,
       sum(is_fraud) as fraud_transaction,
       round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from transactions
inner join customers
on  transactions.customer_id = customers.customer_id
group by account_type;

select customer_name,city,
       count(*) as total_transactions,
       sum(is_fraud) as fraud_transaction,
       round((sum(is_fraud) * 100.0/count(*)),2)as fraud_rate
from transactions
inner join customers
on  transactions.customer_id = customers.customer_id
group by customer_name,city
order by fraud_transaction desc,fraud_rate desc
limit 5;

select customer_name,city,
count(transactions.transaction_id) as total_transactions
from  customers
left join transactions
on  transactions.customer_id = customers.customer_id
group by customer_name,city
order by total_transactions asc;



                 
     
