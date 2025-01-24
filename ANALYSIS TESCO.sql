SELECT * FROM telco_churn_analysis.`copy of telco_customer_churn_services`;

#What are the key demographic that influencing churn?
SELECT d.`Gender`,count(d.Married) as NumberMarried, count(d.`Under 30`) as Under_30, count(d.`Senior Citizen`) as Senior_Citizen, avg(d.`Number of Dependents`) as NumberOfDependents
From telco_churn_analysis.`copy of telco_customer_churn_services` AS s
INNER JOIN telco_churn_analysis.`copy of telco_customer_churn_demographics - copy` AS d
ON s.`Customer ID` = d.`Customer ID`
INNER JOIN telco_churn_analysis.`copy of telco_customer_churn_status` AS stu
ON 	d.`Customer ID` = stu.`Customer ID`
WHERE stu.`Customer Status` = 'Churned' AND d.`Dependents` = 'Yes'
GROUP BY d.Gender;

#What are the key demographic that influencing churn?
SELECT d.`Gender`,count(d.Married) as NumberMarried, count(d.`Under 30`) as Under_30, count(d.`Senior Citizen`) as Senior_Citizen, avg(d.`Number of Dependents`) as NumberOfDependents
From telco_churn_analysis.`copy of telco_customer_churn_services` AS s
INNER JOIN telco_churn_analysis.`copy of telco_customer_churn_demographics - copy` AS d
ON s.`Customer ID` = d.`Customer ID`
INNER JOIN telco_churn_analysis.`copy of telco_customer_churn_status` AS stu
ON 	d.`Customer ID` = stu.`Customer ID`
WHERE stu.`Customer Status` <> 'Churned' AND d.`Dependents` = 'Yes'
GROUP BY d.Gender;

# What are the service-related factors influencing churn?
SELECT s.`Internet Service`, count(s.`Internet Service`) as internet,
count(s.`Multiple Lines`) as MultiplelineService,
count(s.`Phone Service`) as PhoneService
FROM telco_churn_analysis.`copy of telco_customer_churn_services` as s
LEFT JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as ch
ON s.`Customer ID` = ch.`Customer ID`
WHERE ch.`Customer Status` = 'Churned'
GROUP BY s.`Internet Service`;

# What are the service-related factors of existing clients?
SELECT s.`Internet Service`, count(s.`Internet Service`) as internet,
count(s.`Multiple Lines`) as MultiplelineService,
count(s.`Phone Service`) as PhoneService
FROM telco_churn_analysis.`copy of telco_customer_churn_services` as s
LEFT JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as ch
ON s.`Customer ID` = ch.`Customer ID`
WHERE ch.`Customer Status` <> 'Churned'
GROUP BY s.`Internet Service`;

# Which customer segments (contract type, gender, or age group) have the highest churn rates?
SELECT
s.`contract`, d.Gender,
  CASE 
    WHEN `Age` BETWEEN 19 AND 30 THEN '19-30'
    WHEN `Age` BETWEEN 31 AND 40 THEN '31-40'
    WHEN `Age` BETWEEN 41 AND 50 THEN '41-50'
    WHEN `Age` BETWEEN 51 AND 60 THEN '51-60'
    WHEN `Age` BETWEEN 61 AND 70 THEN '61-70'
    ELSE '71-80' 
  END AS `Age_Group`, 
  COUNT(*) AS `Total_Churn`
FROM telco_churn_analysis.`copy of telco_customer_churn_demographics - copy` as d
INNER JOIN telco_churn_analysis.`copy of telco_customer_churn_services` as s
USING(`Customer ID`)
INNER JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as c
USING(`Customer ID`)
WHERE c.`Customer Status` = 'Churned'
GROUP BY s.`Contract`,d.Gender, Age_Group
ORDER BY Total_Churn DESC;

# What is the relationship between churn and satisfaction scores?
SELECT `Customer Status`,
		MAX(`Satisfaction Score`) as Max_satisfactory, 
		MIN(`Satisfaction Score`) as Min_satisfactory,
        AVG(`Satisfaction Score`) as AVG_score
FROM telco_churn_analysis.`copy of telco_customer_churn_status`
GROUP BY `Customer Status`;

# How does internet service type (DSL, Fiber Optic, Cable) correlate with churn rates?
SELECT 
  (sum((x-x_mean) * (y - y_mean))/ count(*))/
  (SQRT(SUM(POW(x - x_mean, 2)) / COUNT(*)) * SQRT(SUM(POW(y - y_mean, 2)) / COUNT(*))) AS correlation
FROM(
    SELECT 
        `Churn Score` AS y,
        CASE 
            WHEN s.`Internet Type` = 'DSL' THEN 1
            WHEN s.`Internet Type` = 'Fiber Optic' THEN 2
            WHEN s.`Internet Type` = 'Cable' THEN 3
            ELSE NULL
        END AS x,
        AVG(c.`Churn Score`) OVER () AS y_mean,
        AVG(CASE 
            WHEN s.`Internet Type` = 'DSL' THEN 1
            WHEN s.`Internet Type` = 'Fiber Optic' THEN 2
            WHEN s.`Internet Type` = 'Cable' THEN 3
            ELSE NULL
        END) OVER () AS x_mean
	FROM telco_churn_analysis.`copy of telco_customer_churn_status` AS c
	INNER JOIN 
    telco_churn_analysis.`copy of telco_customer_churn_services` AS s
	USING (`Customer ID`)
	WHERE	c.`Customer Status`= 'Churned') subquery;

#Which Churn category reason made client churn?
SELECT `Churn Category`,`churn Reason`, count(*) as Churned
FROM telco_churn_analysis.`copy of telco_customer_churn_status`
WHERE `Customer Status` = 'Churned'
GROUP BY `Churn Category`, `Churn Reason`
ORDER BY Churned DESC
LIMIT 6;

# What is the impact of churn on monthly revenue and overall CLTV?
SELECT 
 CASE WHEN CLTV between 2000 AND 2500 THEN '2000-2500'
	  WHEN CLTV between 2501 AND 3000 THEN '2501-3000'
      WHEN CLTV between 3001 AND 3500 THEN '3001-3500'
      WHEN CLTV between 3501 AND 4000 THEN '3501-4000'
      WHEN CLTV between 4001 AND 4500 THEN '4001-4500'
      WHEN CLTV between 4501 AND 5000 THEN '4501-5000'
      WHEN CLTV between 5001 AND 5500 THEN '5001-5500'
      WHEN CLTV between 5501 AND 6000 THEN '5501-6000'
      WHEN CLTV between 6001 AND 6500 THEN '6001-6500'
      ELSE '6501-7000' END AS CLVT_Category,
	SUM(`Total Revenue`) AS LOSS
FROM telco_churn_analysis.`copy of telco_customer_churn_services`  
RIGHT JOIN telco_churn_analysis.`copy of telco_customer_churn_status`
USING (`Customer ID`)
WHERE `Customer Status` = 'Churned'
GROUP BY CLVT_category
ORDER BY LOSS DESC
;
# Are high-value customers (based on CLTV) more or less likely to churn compared to low-value customers?
SELECT 
 CASE WHEN CLTV between 2000 AND 2500 THEN '2000-2500'
	  WHEN CLTV between 2501 AND 3000 THEN '2501-3000'
      WHEN CLTV between 3001 AND 3500 THEN '3001-3500'
      WHEN CLTV between 3501 AND 4000 THEN '3501-4000'
      WHEN CLTV between 4001 AND 4500 THEN '4001-4500'
      WHEN CLTV between 4501 AND 5000 THEN '4501-5000'
      WHEN CLTV between 5001 AND 5500 THEN '5001-5500'
      WHEN CLTV between 5501 AND 6000 THEN '5501-6000'
      WHEN CLTV between 6001 AND 6500 THEN '6001-6500'
      ELSE '6501-7000' END AS CLVT_Category,
CASE 
        WHEN CLTV >= 5000 THEN 'High Value'
        WHEN CLTV BETWEEN 3000 AND 4999 THEN 'Moderate Value'
        ELSE 'Low Value' END AS Value_Tier,
	count(*) AS Churned
FROM telco_churn_analysis.`copy of telco_customer_churn_services`  
RIGHT JOIN telco_churn_analysis.`copy of telco_customer_churn_status`
USING (`Customer ID`)
WHERE `Customer Status` = 'Churned'
GROUP BY CLVT_category, Value_Tier
ORDER BY value_Tier, Churned DESC;

# Which offers (e.g., Offer A, Offer B) are most effective in reducing churn?
SELECT  c.`Customer Status`,s.`Offer`, count(*) as offer
FROM telco_churn_analysis.`copy of telco_customer_churn_services` as s
JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as c
using(`Customer ID`)
Group By c.`Customer Status`, Offer
ORDER BY offer DESC;

SELECT  c.`Customer Status`,s.`Offer`, count(*) as Total, `Churn Category`
FROM telco_churn_analysis.`copy of telco_customer_churn_services` as s
JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as c
using(`Customer ID`)
Where `Customer Status` = 'Churned'
Group By c.`Customer Status`, Offer,`Churn Category`
ORDER BY Total DESC;

SELECT  c.`Customer Status`,s.`Offer`, count(*) as Total
FROM telco_churn_analysis.`copy of telco_customer_churn_services` as s
JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as c
using(`Customer ID`)
Where `Customer Status` <> 'Churned'
Group By c.`Customer Status`, Offer
ORDER BY Total DESC
limit 5;   -- Offer A and B are the best offers less customers churned due to competition 

# How does tenure influence the likelihood of a customer churning?
SELECT  c.`Customer Status`,s.`Tenure in Months`, count(*) as Total
FROM telco_churn_analysis.`copy of telco_customer_churn_services` as s
JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as c
using(`Customer ID`)
Where `Customer Status` = 'Churned'
Group By c.`Customer Status`, `Tenure in Months`
ORDER BY Total DESC
limit 5;  -- the more you stayed in the company the lesser likely you client will churn. Thus we look for
		 -- retainability,

#How do churn reasons categorized as "Competitor" vary by location or service type?
SELECT  `Internet Type`, `Phone Service`, `Multiple Lines`, count(*) as Total
FROM telco_churn_analysis.`copy of telco_customer_churn_services` as s
JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as c
using(`Customer ID`)
Where `Customer Status` = 'Churned' AND c.`Churn Category` = 'Competitor'
Group By `Internet Type`,`Phone Service`,`Multiple Lines`
ORDER BY Total DESC;   

# What proportion of churn is due to pricing versus dissatisfaction?
SELECT c.`Churn Category`, count(c.`Churn Category`)/sum(count(c.`Churn Category`)) over() as  Proportion
FROM telco_churn_analysis.`copy of telco_customer_churn_services` as s
JOIN telco_churn_analysis.`copy of telco_customer_churn_status` as c
using(`Customer ID`)
Where `Customer Status` = 'Churned' AND c.`Churn Category` IN ('Price', 'dissatisfaction')
Group By c.`Churn Category`
ORDER BY Proportion DESC;  

# How accurately does the churn score predict actual churn behaviour?
SELECT 
    SUM(CASE WHEN  c.`Churn Label`= p.`churn_label`  THEN 1 ELSE 0 END) / COUNT(*) AS accuracy_score
FROM 
   telco_churn_analysis.`copy of telco_customer_churn_status` as c
   JOIN telco_churn_analysis.`tesco prediction` as p