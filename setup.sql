Create database fraud_analysis;
use fraud_analysis;
drop  table if exists transactions;
create table transactions ( 
transaction_id int,
amount int,
transaction_hour int,
merchant_category varchar(50),
foreign_transaction int,
location_mismatch int,
device_trust_score int,
velocity_last_24h int,
cardholder_age int,
is_fraud int
);