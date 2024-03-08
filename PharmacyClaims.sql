/* Making member_id as the primary key AS a natrual key */

ALTER TABLE final_project.dim_memberdetails
ADD PRIMARY KEY (member_id);

/* Making drug_ndc as the primary key AS a natrual key */

ALTER TABLE final_project.dim_drugdetails
ADD PRIMARY KEY (drug_ndc);

/* Adding a new column claim_id to become a surrogate key */

ALTER TABLE final_project.fact_pharmacyclaims
ADD COLUMN claim_id INT AUTO_INCREMENT,
ADD PRIMARY KEY (claim_id);

/* Making member_id as a foreign key in the fact table */

ALTER TABLE final_project.fact_pharmacyclaims
ADD FOREIGN KEY (member_id) REFERENCES dim_memberdetails(member_id) 
ON DELETE RESTRICT
ON UPDATE CASCADE;

/* Making drug_ndc as a foreign key in the fact table */

ALTER TABLE final_project.fact_pharmacyclaims
ADD FOREIGN KEY (drug_ndc) REFERENCES dim_drugdetails(drug_ndc)
ON DELETE RESTRICT
ON UPDATE CASCADE;

/* SQL query that identifies the number of prescriptions grouped by drug name */

SELECT 
	d.drug_name AS 'drug name',count(drug_name) AS 'number of prescriptions'
FROM final_project.fact_pharmacyclaims c
LEFT OUTER JOIN final_project.dim_drugdetails d
	USING(drug_ndc)
GROUP BY d.drug_name;

/* Write a SQL query that counts total prescriptions, counts unique (i.e. distinct) members, sums copay 
and sums insurancepaid for members grouped as either ‘age 65+’ or ’ < 65’. 

Use case statement logic */

SELECT 
    CASE 
        WHEN m.member_age < 65 THEN 'Age is less than 65'
        ELSE 'Age is over 65 '
    END AS 'Age Group',
    COUNT(c.member_id) AS 'Total Number of Prescriptions',
    count(DISTINCT(member_id)) AS 'Total Number of Patients',
    SUM(c.copay1 + c.copay2 + c.copay3) AS 'Total Copay',
    SUM(c.insurancepaid1 + c.insurancepaid2 + c.insurancepaid3) AS 'Total Insurance Paid'
FROM final_project.fact_pharmacyclaims c
LEFT OUTER JOIN final_project.dim_memberdetails m 
		USING(member_id)
GROUP BY 
    CASE 
        WHEN m.member_age < 65 THEN 'Age is less than 65'
        ELSE 'Age is over 65 '
    END;

/* Write a SQL query that identifies the amount paid by the insurance for the most recent prescription fill date. 
Use the format that we learned with SQL Window functions.
Your output should be a table with 
member_id, member_first_name, member_last_name, drug_name, fill_date (most recent),
and most recent insurance paid. */
-- -----------------
WITH UnpivotedClaims AS (
    SELECT 
        member_id, 
        drug_ndc, 
        STR_TO_DATE(fill_date1, '%m/%d/%Y') AS fill_date, 
        insurancepaid1 AS insurancepaid
    FROM 
        final_project.fact_pharmacyclaims
    WHERE 
        fill_date1 IS NOT NULL
    UNION ALL
    SELECT 
        member_id, 
        drug_ndc, 
        STR_TO_DATE(fill_date2, '%m/%d/%Y'), 
        insurancepaid2
    FROM 
        final_project.fact_pharmacyclaims
    WHERE 
        fill_date2 IS NOT NULL
    UNION ALL
    SELECT 
        member_id, 
        drug_ndc, 
        STR_TO_DATE(fill_date3, '%m/%d/%Y'), 
        insurancepaid3
    FROM 
        final_project.fact_pharmacyclaims
    WHERE 
        fill_date3 IS NOT NULL
),
RankedClaims AS (
    SELECT 
        uc.member_id, 
        uc.drug_ndc, 
        uc.fill_date, 
        uc.insurancepaid,
        ROW_NUMBER() OVER (PARTITION BY uc.member_id ORDER BY uc.fill_date DESC) AS rn
    FROM 
        UnpivotedClaims uc
)
SELECT 
    m.member_id,
    m.member_first_name,
    m.member_last_name,
    d.drug_name,
    rc.fill_date AS most_recent_fill_date,
    rc.insurancepaid AS most_recent_insurance_paid
FROM 
    RankedClaims rc
JOIN 
    final_project.dim_memberdetails m ON rc.member_id = m.member_id
JOIN 
    final_project.dim_drugdetails d ON rc.drug_ndc = d.drug_ndc
WHERE 
    rc.rn = 1;



















