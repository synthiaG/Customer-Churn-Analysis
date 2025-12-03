CREATE DATABASE Customer_Churn_DTB;
-- View Table
SELECT * FROM  customer_churn;
-- Create a Staging Table
CREATE TABLE  customer_churn_Staging AS
SELECT * FROM  customer_churn;
-- View Staging Table
SELECT * FROM  customer_churn_staging;

-- We need to Rename the Columns names in a Format that is acceptable with sql
ALTER TABLE customer_churn_staging
RENAME  COLUMN `Usage Frequency` TO Usage_Frequency;

ALTER TABLE customer_churn_staging
RENAME  COLUMN `Support Calls` TO Support_Calls;

ALTER TABLE customer_churn_staging
RENAME  COLUMN `Payment Delay` TO Payment_Delay;

ALTER TABLE customer_churn_staging
RENAME  COLUMN `Subscription Type` TO Subscription_Type;

ALTER TABLE customer_churn_staging
RENAME  COLUMN `Contract Length` TO Contract_Length ;

ALTER TABLE customer_churn_staging
RENAME  COLUMN `Total Spend` TO Total_Spend;

ALTER TABLE customer_churn_staging
RENAME  COLUMN `Last Interaction` TO Last_Interaction;

-- ADD COLUMN  AND UPFATE the distribution 
-- add_feature_columns


ALTER TABLE customer_churn_staging
ADD COLUMN Age_Distribution Varchar(20);

UPDATE customer_churn_staging 
SET Age_Distribution =CASE
WHEN Age <=29 then 'Young'
WHEN Age BETWEEN 30 AND 45 THEN 'Middle Age'
ELSE 'Old' 
END ;


ALTER TABLE customer_churn_staging
ADD COLUMN Tenure_Distribution varchar(20);

UPDATE customer_churn_staging 
SET Tenure_Distribution =CASE
WHEN Tenure BETWEEN 0 AND 6 then 'New_Customer'
WHEN Tenure BETWEEN 7 AND 12 THEN 'ShortTerm_Customer'
WHEN Tenure BETWEEN 13 AND 18 THEN 'MediumTerm_Customer'
WHEN Tenure BETWEEN 19 AND 24 THEN 'Longterm_Customer'
WHEN Tenure > 24 THEN 'Loyal_Customer'
END;

--
ALTER TABLE customer_churn_staging
ADD COLUMN Spend_Level varchar(20);
Update customer_churn_staging
set  Spend_Level =
 Case
When Total_Spend >900 then 'High'
when Total_Spend between 501 and 900  then 'Medium'
else 'Low'
End;


Alter table customer_churn_staging
add column Usage_Frequency_Distribution VARCHAR(20);


Update  customer_churn_staging
set Usage_Frequency_Distribution =
Case
when Usage_Frequency <=10 then 'Low_Frequency '
when Usage_Frequency between 11 and 20 then  'Mild_Frequency'
else 'High_Frequency'
End;

  alter table customer_churn_staging
add column Support_Calls_Distribution varchar(20);


 update customer_churn_staging
set Support_Calls_Distribution=
case 
when Support_Calls <=4 then  'Few_Support_Calls'
when Support_Calls between 5 and 7  then  'Medium_Support_Calls'
else 'High_Support_Calls'

end;

-- -- Demographic Analysis
-- Total Customer
SELECT COUNT(*) AS TotalCustomers 
FROM  customer_churn_staging;

-- What is the churn rate
WITH Churn_Rate as
(
SELECT Churn,COUNT(*) AS ChurnCount 
FROM  customer_churn_staging
GROUP BY Churn

),
TotalCustomer AS
(
SELECT COUNT(*) AS TotalCustomers 
FROM  customer_churn_staging
)
SELECT 
cr.Churn,
cr.ChurnCount,
Ct.TotalCustomers,
round((cr.ChurnCount *100)/Ct.TotalCustomers,2) AS ChurnRate
FROM Churn_Rate cr
CROSS JOIN TotalCustomer Ct;
  -- The Churn Rate is quite High almost 50%
  
  -- Analyze churn drivers
  
  -- Count customers by Age_Distribution AND Tenure_Distribution.

select Age_Distribution,Tenure_Distribution,
 count(*) as TotalCustomer
 from customer_churn_staging
 group by  Age_Distribution,Tenure_Distribution
order by Age_Distribution,TotalCustomer desc ;
  
  
  -- Gender Composition Rate
  With GenderPercent AS (
SELECT Gender, COUNT(*)  AS GenderCount 
FROM  customer_churn_staging
GROUP BY Gender),
TotalGender AS ( SELECT COUNT(*) AS TotalGenderCount
FROM customer_churn_staging)
SELECT GP.Gender,
GP.GenderCount,
GT.TotalGenderCount,
ROUND((GP.GenderCount*100)/GT.TotalGenderCount,2) as GenderComposition
FROM GenderPercent GP
CROSS JOIN TotalGender GT;
  -- Most Subscription Comes From Female with about 53%
  
  -- What is the distribution of contract types and churnRate
SELECT Contract_Length, 
count(*) as Distribution_ContractTypes,
SUM(Total_Spend) AS TotalRevenue,
round(avg(Total_Spend),2) as AverageSpend,
SUM(churn) as TotalChurn,
ROUND(SUM(churn)*100/count(*),2) AS ChurnRate
FROM  customer_churn_staging
GROUP BY Contract_Length
ORDER BY  ChurnRate DESC;

-- What is the average monthly charges for churned vs non-churned customers?
SELECT Churn,
AVG(Total_Spend) AS MonthlyAverageSpend
FROM  customer_churn_staging
WHERE Contract_Length = "Monthly"
GROUP BY Churn;

-- Count how many customers are in each Subscription_Type.
select Subscription_Type,
round(avg(Total_Spend),2) as AvgTotal_Revenue,
Count(*) TotalCustomers ,
Sum(Churn) as Churned,
round((sum(Churn)*100)/count(*) ,2) as Churn_Rate
from customer_churn_staging
group by Subscription_Type
order by Churn_Rate  desc;
 -- Almost blancing Standard @ 21502, Basic @ 21451 and Premium @ 21421
 -- Find the number of male vs female customers who churned.
select Gender,count(*) as ChurnCount,
Sum(Churn) as Churned,
round((sum(Churn)*100)/count(*) ,2) as Churn_Rate
from customer_churn_staging
group by Gender;

-- For each Subscription_Type, return:total customers,churned customers churn rate %
select Subscription_Type,
count(*) as ChurnCount,
Sum(Churn) as Churned,
round((sum(Churn)*100)/count(*) ,2) as Churn_Rate
from customer_churn_staging
group by Subscription_Type
order by Churn_Rate desc;

-- TENURE ANALYSIS
-- Churn rate  and Tenure_Distribution 
select 
Tenure_Distribution,
count(*) as Total_Customer,
sum(Churn) as Total_churned,
round((sum(Churn)*100)/count(*),2) as Churn_Rate
from customer_churn_staging
group by Tenure_Distribution
order by Churn_Rate desc;
 
-- Churn rate  and Age_Distribution
select 
Age_Distribution,
count(*) as Total_Tenure,
sum(Churn) as Total_churned,
round((sum(Churn)*100)/count(*),2) as Churn_Rate
from customer_churn_staging
group by Age_Distribution
order by Churn_Rate desc;

-- -- Churn rate  ,Age_Distribution and Gender

select 
Age_Distribution,Gender,
count(*) as Total_Tenure,
sum(Churn) as Total_churned,
round((sum(Churn)*100)/count(*),2) as Churn_Rate
from customer_churn_staging
group by Age_Distribution,Gender
order by Churn_Rate desc;

-- -- Churn rate  ,Tenure_Distribution and Gender
select 
Tenure_Distribution,Gender,
count(*) as Total_Tenure,
sum(Churn) as Total_churned,
round((sum(Churn)*100)/count(*),2) as Churn_Rate
from customer_churn_staging
group by Tenure_Distribution,Gender
order by Churn_Rate desc;

-- -- Churn rate   ,Tenure_Distribution and Age_Distribution
select 
Tenure_Distribution,Age_Distribution,
count(*) as Total_Tenure,
sum(Churn) as Total_churned,
round((sum(Churn)*100)/count(*),2) as Churn_Rate
from customer_churn_staging
group by Tenure_Distribution,Age_Distribution
order by Churn_Rate desc;

-- For each Spend_Level segment, calculate churn rate.

select Spend_Level,
count(*) as TotalCustomers,
sum(Churn) as Churned,
round(sum(Churn)*100/count(*) ,2) as ChurnRate
from customer_churn_staging
group by Spend_Level
order by  ChurnRate desc;
-- Low Spenders have high Churn rate above 52%


-- Show average Payment_Delay grouped by Tenure_Distribution
select 

Tenure_Distribution,
round(AVG(Payment_Delay),2) Average_PaymentDelay
from customer_churn_staging
group by Tenure_Distribution
order by Average_PaymentDelay desc;
--  lonterm @ 17.57,Medium 17.55, ShortTerm @16.72 ,New_Customer @ 16.34
 -- Longterm and Medium have the highest Average Payment Delay
 
 -- -- Show average Payment_Delay grouped by Age_Distribution
select 
Age_Distribution,
round(AVG(Payment_Delay),2) Average_PaymentDelay
from customer_churn_staging
group by Age_Distribution
order by Average_PaymentDelay desc;

 -- -- Show average Payment_Delay grouped by Gender
select 
Gender,
round(AVG(Payment_Delay),2) Average_PaymentDelay
from customer_churn_staging
group by Gender
order by Average_PaymentDelay desc;

-- -- Show average Payment_Delay grouped by Age_Distribution, Gender and Tenure_distribution
select 
count(*) as TotalCustomers,
sum(Churn) as Churned,
round(sum(Churn)*100/count(*) ,2) as ChurnRate,
Gender,Age_Distribution,Tenure_Distribution,
round(AVG(Payment_Delay),2) Average_PaymentDelay
from customer_churn_staging
group by Gender,Age_Distribution,Tenure_Distribution
order by Average_PaymentDelay desc;



-- Usage_Frequency and Churn_rate
select  Usage_Frequency_Distribution,
round(avg(Total_Spend),2) as AvgTotal_Revenue,
count(*) TotalCustomers,
sum(churn) as TotalChurned,
round(sum(churn)*100/count(*),2) as ChurnRate
from  customer_churn_staging
group by Usage_Frequency_Distribution
order by AvgTotal_Revenue desc;


select  Usage_Frequency_Distribution,Age_Distribution,
round(avg(Total_Spend),2) as AvgTotal_Revenue,
count(*) TotalCustomers,
sum(churn) as TotalChurned,
round(sum(churn)*100/count(*),2) as ChurnRate
from  customer_churn_staging
group by Usage_Frequency_Distribution,Age_Distribution
order by Age_Distribution, AvgTotal_Revenue desc;


select  Support_Calls_Distribution,
round(avg(Total_Spend),2) as AvgTotal_Revenue,
count(*) TotalCustomers,
sum(churn) as TotalChurned,
round(sum(churn)*100/count(*),2) as ChurnRate
from  customer_churn_staging
group by Support_Calls_Distribution
order by AvgTotal_Revenue desc;

-- Usage_Frequency_Distribution and Support_Calls_Distribution



select  Support_Calls_Distribution,Usage_Frequency_Distribution,
round(avg(Total_Spend),2) as AvgTotal_Revenue,
count(*) TotalCustomers,
sum(churn) as TotalChurned,
round(sum(churn)*100/count(*),2) as ChurnRate
from  customer_churn_staging
group by Support_Calls_Distribution,Usage_Frequency_Distribution
order by Support_Calls_Distribution,AvgTotal_Revenue desc;

