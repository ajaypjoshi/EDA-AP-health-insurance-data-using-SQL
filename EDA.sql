select COUNT(Sno) from [dbo].[Andhra_Health_Data];
select * from dbo.Andhra_Health_Data;

--First of all we get informaion about data
EXEC sp_help 'Andhra_Health_Data';

--or there are other methods too
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Andhra_Health_Data';

--- First we will find whether there is null data or not

select * from dbo.Andhra_Health_Data where Sno is NULL
or AGE is null or SEX is null or CASTE_NAME is null or CATEGORY_CODE is null
or CATEGORY_NAME is null or SURGERY_CODE is null or SURGERY is null or SURGERY_DATE is null or VILLAGE is null
or MANDAL_NAME is null or DISTRICT_NAME is null or PREAUTH_DATE is null or PREAUTH_AMT is null or 
 CLAIM_DATE is null or CLAIM_AMOUNT is null or HOSP_NAME is null or HOSP_TYPE is null or HOSP_DISTRICT is null or
 SURGERY_DATE is null or DISCHARGE_DATE is null  or Mortality_Y_N is null or MORTALITY_DATE is null or SRC_REGISTRATION is null

 --- Now as per our observation there are no unwanted null values
 --- Let's clean data
 --- first find data where discharge date is null but death has not happened. (Because it is not possible) and delete data
 
 delete from Andhra_Health_Data 
 where DISCHARGE_DATE is null and Mortality_Y_N = '0'

 -- Now we will check is there any negative value in data or not
 select  * from Andhra_Health_Data
 where PREAUTH_AMT <0 or CLAIM_AMOUNT < 0 or AGE < 0 or Sno <0 

 -- so we did not found any negative value

 --- by selecting distinct values from whole table we can just screen is there any unwanted/garbage value present in table
select distinct
 Sno,
AGE,
SEX,
CASTE_NAME,
CATEGORY_CODE,
CATEGORY_NAME,
SURGERY_CODE,
SURGERY,
VILLAGE,
MANDAL_NAME,
DISTRICT_NAME,
PREAUTH_DATE,
PREAUTH_AMT,
CLAIM_DATE,
CLAIM_AMOUNT,
HOSP_NAME,
HOSP_TYPE,
HOSP_DISTRICT,
SURGERY_DATE,
DISCHARGE_DATE,
Mortality_Y_N,
MORTALITY_DATE,
SRC_REGISTRATION from Andhra_Health_Data

--- No garbage value is present

---Now till here we cleaned data. It's time to do EDA
--- Here is list of questions:
/*Q1. what is average and median age of  customers?
  Q2. Distribution of males and females.
  Q3. Count the no of claims as per caste and arrange in descending order
  Q4. count no. claims as per category
  Q5. Count no. of claims as per surgery
  Q6. Count no. of claims as per village, and district 
  Q7. In which year highest prauthorization amount issued
  Q8. Avg. and median peauthorization amount.
  Q9. Avg preauthorization as per district
  Q10. In which year highest claim amount issued
  Q11. Avg. and median claim amount.
  Q12. Avg claims as per district
  Q12. Count no. of peauthorization amount and claim amount issued per hospital and order desc.
  Q13. What is average days of difference between surgery date and discharge date. also find it by hospital.*/

--- Now let's find answers of thease questions.
   
--Q1. what is average and median age of  customers?

-- to calculate avg
select avg(age) as average_age from Andhra_Health_Data

--avg age is 44

---to calculate median
select distinct PERCENTILE_CONT(0.5) within group (order by age)  over()
as median
from Andhra_Health_Data

--median age is 47

-- Q2. Distribution of males and females.

select 
sum(case when sex ='Male' then 1 else 0 end) as total_male,
round(100*sum(case when sex ='Male' then 1 else 0 end)/count(*),0) as percentage_male,

sum(case when sex ='female' then 1 else 0 end) as total_female,
round(100*sum(case when sex ='female' then 1 else 0 end)/count(*),0) as percentage_female

from Andhra_Health_Data

--- so distribution of male and females are 54% and 37% respectively.

-- here I have to see table again and again so I will create procedure for convenience

CREATE PROCEDURE k
AS

SELECT *
FROM Andhra_Health_Data;
GO

--Q3. Count the no of claims as per caste and arrange in descending order

select caste_name, count(*) as total_claims from Andhra_Health_Data
group by CASTE_NAME order by COUNT(*) desc

--or we can also find by 

select DENSE_RANK() over( order by count(*) desc) as No,
caste_name,
COUNT(*) as total_claims
from Andhra_Health_Data
group by CASTE_NAME

-- category BC has highest no. of claims followed by OC and SC



 --Q4. count no. claims as per category

 select DENSE_RANK() over( order by count(*) desc) as No,
CATEGORY_NAME,category_code,
COUNT(*) as total_claims
from Andhra_Health_Data
group by CATEGORY_NAME,CATEGORY_CODE

/* from results NEPHROLOGY has highest no. of claims followed by MEDICAL ONCOLOGY and POLY TRAUMA whereas POLY TRAUMA
COCHLEAR IMPLANT SURGERY,INFECTIOUS DISEASES,PROSTHESES has lowest no. of claims resp.*/


--Q5. Count no. of claims as per surgery


 select DENSE_RANK() over( order by count(*) desc) as No,
SURGERY,SURGERY_CODE,
COUNT(*) as total_claims
from Andhra_Health_Data
group by SURGERY,SURGERY_CODE

/* from results we can derive that Maintenance Hemodialysis For Crf, Surgical Correction Of Longbone Fracture, 
Coronary Balloon Angioplasty with Drug eluting stent(00.45) has highest no. of claims where 
Aplasia / hypoplasia / post traumatic loss of thumb for reconstruction - conventional surgery,
Brachytherapy Interstitial I. Ldr Per Application,Chemotherapy for Colorectal Cancer with Capecitabine + bevacizumab (metastatic)
has lowest no. of claims*/

--  Q6. Count no. of claims as per village,mandal and district 

exec k

 select DENSE_RANK() over( order by count(*) desc) as No,
VILLAGE,
COUNT(*) as total_claims
from Andhra_Health_Data
group by VILLAGE

 select DENSE_RANK() over( order by count(*) desc) as No,
DISTRICT_NAME,
COUNT(*) as total_claims
from Andhra_Health_Data
group by DISTRICT_NAME

 select DENSE_RANK() over( order by count(*) desc) as No,
MANDAL_NAME,
COUNT(*) as total_claims
from Andhra_Health_Data
group by MANDAL_NAME

--from results we can see East Godavari district has highes claims

--Q7. In which year highest prauthorization amount issued
--Q8. Avg. and median peauthorization amount.
--Q9. Avg preauthorization as per district. 

exec k



select sum(preauth_amt) as total_amount, YEAR(preauth_date) as year from Andhra_Health_Data
group by YEAR(preauth_date)
order by total_amount desc

/*since total sum is large it is showing error. so we will alter table and convert  prauth_amount column to bigint data type which
can store big numbers and rerun query*/

ALTER TABLE Andhra_Health_Data ALTER COLUMN preauth_amt bigint;

--so we can see that total sum of claims is highest in 2017

--Now let's calculate avg. and median claim amount

--avg
select avg(preauth_amt) as total_amount, YEAR(preauth_date) as year from Andhra_Health_Data
group by YEAR(preauth_date)
order by total_amount desc

--median
select distinct(YEAR(preauth_date)), PERCENTILE_CONT(0.5) within group (order by preauth_amt)  over(partition by YEAR(preauth_date) )
as median
from Andhra_Health_Data
order by median desc

--from data we can see that median claim in 2014 was highest which is 40000 and avg. was highest in 2014 which is 60565.

select avg(preauth_amt) as avg_amount, DISTRICT_NAME as district from Andhra_Health_Data
group by DISTRICT_NAME
order by avg_amount desc

select distinct DISTRICT_NAME, PERCENTILE_CONT(0.5) within group (order by preauth_amt)  over(partition by YEAR(preauth_date) )
as median
from Andhra_Health_Data
order by median desc

  /*Q10. In which year highest claim amount issued
  Q11. Avg. and median claim amount.
  Q12. Avg claims as per district*/

  exec k

 select sum(CLAIM_AMOUNT) as total_claim_amount, YEAR(CLAIM_DATE) as district from Andhra_Health_Data
group by YEAR(CLAIM_DATE)
order by total_claim_amount desc

--as per data claim issued in 2017 is 13264418825.

ALTER TABLE Andhra_Health_Data ALTER COLUMN CLAIM_AMOUNT bigint;

select avg(CLAIM_AMOUNT) as avg_claim_amount, DISTRICT_NAME as district from Andhra_Health_Data
group by DISTRICT_NAME
order by avg_claim_amount desc

---highest avg claim issued by Guntur district


--Q12. Count total peauthorization amount and claim amount issued per hospital.
  exec k

with cte as
 (select avg(preauth_amt) as avg_preauthorization_amount, HOSP_NAME as hospital from Andhra_Health_Data
group by HOSP_NAME),

 cte2 as(select sum(CLAIM_AMOUNT) as total_claim_amount, HOSP_NAME as hospital from Andhra_Health_Data
group by HOSP_NAME)

select cte.avg_preauthorization_amount, cte2.*  from cte left join cte2 on cte.hospital=cte2.hospital

--Q13. What is average days of difference between surgery date and discharge date. also find it by hospital.

exec k

SELECT avg(DATEDIFF(day, preauth_date, claim_date)) AS difference_in_days, HOSP_NAME
FROM Andhra_Health_Data
group by HOSP_NAME
order by difference_in_days desc

/*from results District Hospital - Proddutur has highest avg days of discharge which is 486
whereas Modern Eye Hospital and Research Centre has lowest days 40*/



/* This is complete EDA of AP health data from my side. Please feel free to give any suggesion and modification in this code*/