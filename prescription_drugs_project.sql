-- Q1: a) Which prescriber had the highest total number of claims (totaled over all drugs)? 
-- Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC;

-- b) Repeat the above, but this time report the nppes_provider_first_name,
-- nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
		INNER JOIN prescription using (npi)
GROUP BY prescriber.npi, nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description
ORDER BY total_claims DESC;


-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT  prescriber.specialty_description, SUM(total_claim_count)AS total_claims
FROM prescriber 
	 INNER JOIN prescription using(npi)
GROUP BY prescriber.specialty_description
ORDER BY total_claims DESC;

-- b. Which specialty had the most total number of claims for opioids?

SELECT DISTINCT prescriber.specialty_description, SUM(total_claim_count)AS total_claims
FROM prescriber 
	 INNER JOIN prescription USING(npi)
	 INNER JOIN drug USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY total_claims DESC;

-- c. **Challenge Question:** Are there any specialties that appear in 
--the prescriber table that have no associated prescriptions in the prescription table?

WITH new_tab AS (SELECT npi, specialty_description
FROM prescription 
	INNER JOIN prescriber USING(npi))

SELECT DISTINCT specialty_description
FROM prescriber
	WHERE NOT EXISTS(SELECT npi
					 FROM new_tab
					 WHERE prescriber.specialty_description = new_tab.specialty_description)
				 
-- d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
-- For each specialty, report the percentage of total claims by that specialty which are for opioids. 
-- Which specialties have a high percentage of opioids?

-- total claim count per_specality

WITH all_claims AS (SELECT specialty_description, SUM(total_claim_count) AS sum_of_all_total_claim_count
					FROM prescription 
						INNER JOIN prescriber USING(npi)
						INNER JOIN drug USING(drug_name)
					GROUP BY specialty_description),
-- 					ORDER BY sum_of_all_total_claim_count DESC),


opioid_claims AS (SELECT specialty_description, SUM(total_claim_count) AS sum_opioid_claims
						FROM prescription 
							INNER JOIN prescriber USING(npi)
							INNER JOIN drug USING(drug_name)
						WHERE opioid_drug_flag = 'Y'
						GROUP BY specialty_description)
-- 						ORDER BY sum_total_claim_count DESC)

SELECT specialty_description, sum_of_all_total_claim_count, COALESCE(sum_opioid_claims, 0) AS opioid_claim
FROM all_claims 
	FULL JOIN opioid_claims USING (specialty_description)
ORDER BY specialty_description
	

--Q3: a. Which drug (generic_name) had the highest total drug cost?

-- WITH total_sum_cost AS 

(SELECT generic_name, SUM(total_drug_cost) AS total_cost
FROM prescription
	INNER JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC);




-- b. Which drug (generic_name) has the hightest total cost per day?
-- **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name, ROUND(sum(total_drug_cost)/sum(total_day_supply),2) AS total_cost
FROM prescription
	INNER JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC;
				 
--Q4) a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid'
-- for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y',
-- and says 'neither' for all other drugs.

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or 
-- on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	 	 ELSE 'neither' END AS drug_type,
		  
		 SUM(total_drug_cost)::money AS drug_cost

FROM drug INNER JOIN prescription using(drug_name)
GROUP BY drug_type
ORDER BY drug_cost DESC;

--Q5) a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT cbsaname AS cbsa_tennessee
FROM cbsa 
	INNER JOIN fips_county USING(fipscounty)
WHERE state = 'TN'
GROUP BY cbsaname
ORDER BY cbsaname;

/*SELECT COUNT(CBSA) AS cbsa_tennessee
FROM CBSA FULL JOIN fips_county USING(fipscounty)
WHERE state = 'TN'
GROUP BY state;*/

SELECT *
FROM fips_county;

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, SUM(population) AS total_population
FROM cbsa 
	INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_population DESC;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name 
-- and population.
SELECT fips_county.county, population.population
FROM fips_county LEFT JOIN population USING(fipscounty)
		LEFT JOIN cbsa USING(fipscounty)			
WHERE cbsa.fipscounty IS NULL AND population.population IS NOT NULL
ORDER BY population DESC;



-- Q6)a.Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the 
-- total_claim_count.

WITH tcc AS (SELECT drug_name, total_claim_count
			FROM prescription
			--GROUP BY drug_name
			ORDER BY total_claim_count DESC)
			
SELECT drug_name, total_claim_count
	FROM tcc
WHERE total_claim_count >= 3000;


-- b.For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'yes'
		ELSE 'no' END AS drug_type_is_opioid
FROM prescription
INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC

-- c. Add another column to you answer from the previous part which gives the prescriber 
-- first and last name associated with each row.

SELECT nppes_provider_first_name AS provider_firstname,nppes_provider_last_org_name AS provider_lastname,drug_name, total_claim_count,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'yes'
		ELSE 'no' END AS drug_type_is_opioid
FROM prescription
	INNER JOIN drug USING(drug_name)
	INNER JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC


-- i had summed the total_claims_count;

/*WITH tcc AS (SELECT drug_name, SUM(total_claim_count) AS sum_total_claim_count,
			 	CASE WHEN opioid_drug_flag = 'Y' THEN 'yes'
				ELSE 'no' END AS drug_type_is_opioid
			FROM prescription
			 INNER JOIN drug USING(drug_name)
			GROUP BY drug_name, opioid_drug_flag
			ORDER BY sum_total_claim_count DESC)
			
SELECT drug_name, sum_total_claim_count, drug_type_is_opioid
	FROM tcc
	WHERE sum_total_claim_count >= 3000;*/
	
--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and 
-- the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
-- a. First, create a list of all npi/drug_name combinations for pain management specialists 
-- (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
-- where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. 
-- You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name, specialty_description
FROM prescriber 
	CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the
-- prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT npi, drug.drug_name, specialty_description, total_claim_count
FROM prescriber 
	CROSS JOIN drug
	LEFT JOIN prescription USING(npi, drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name, specialty_description, total_claim_count
ORDER BY total_claim_count;

--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
-- Hint - Google the COALESCE function.

SELECT npi, drug_name, specialty_description
FROM prescriber 
	CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the
-- prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT npi, drug.drug_name, specialty_description, 
		COALESCE(total_claim_count, 0)	
FROM prescriber 
	CROSS JOIN drug
	LEFT JOIN prescription USING(npi, drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name, specialty_description, total_claim_count
ORDER BY total_claim_count;



-- BONUS

-- Q1)How many npi numbers appear in the prescriber table but not in the prescription table?
-- This gives the npis that are not in prescription table
SELECT npi
FROM prescriber
WHERE npi NOT IN (SELECT DISTINCT npi
				  FROM prescription);
				 
SELECT COUNT(npi)AS count
FROM prescriber
	WHERE npi NOT IN (SELECT DISTINCT npi
				 	  FROM prescription);
-- with EXCEPT				 
SELECT npi
FROM prescriber

EXCEPT

SELECT npi
FROM prescription;

-- Q2 a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

WITH family_practice AS (SELECT generic_name, specialty_description, total_claim_count AS t_c_c
FROM prescription
	INNER JOIN drug USING(drug_name)
	INNER JOIN prescriber USING(npi)
WHERE specialty_description = 'Family Practice')


SELECT DISTINCT generic_name, specialty_description, SUM(t_c_c)
FROM family_practice
	GROUP BY generic_name, specialty_description
	ORDER BY SUM(t_c_c) DESC
LIMIT 5;



-- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

WITH card AS (SELECT generic_name, specialty_description, total_claim_count AS t_c_c
FROM prescription
	INNER JOIN drug USING(drug_name)
	INNER JOIN prescriber USING(npi)
WHERE specialty_description ILIKE '%Cardiology%')


SELECT DISTINCT generic_name, specialty_description, SUM(t_c_c)
FROM card
GROUP BY generic_name, specialty_description
ORDER BY SUM(t_c_c) DESC
LIMIT 5


/*SELECT generic_name, specialty_description, SUM(total_claim_count) AS t_c_c
FROM prescription
	INNER JOIN drug USING(drug_name)
	INNER JOIN prescriber USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name, specialty_description
ORDER BY t_c_c DESC
LIMIT 5*/

-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
-- Combine what you did for parts a and b into a single query to answer this question.

(WITH family_parctice AS(SELECT generic_name, specialty_description, total_claim_count AS t_c_c
			FROM prescription
				INNER JOIN drug USING(drug_name)
				INNER JOIN prescriber USING(npi)
			WHERE specialty_description = 'Family Practice')


SELECT DISTINCT generic_name, specialty_description, SUM(t_c_c)
FROM family_parctice
	GROUP BY generic_name, specialty_description
	ORDER BY SUM(t_c_c) DESC
LIMIT 5)

UNION ALL

(WITH card AS (SELECT generic_name, specialty_description, total_claim_count AS t_c_c
FROM prescription
	INNER JOIN drug USING(drug_name)
	INNER JOIN prescriber USING(npi)
WHERE specialty_description = 'Cardiology')


SELECT DISTINCT generic_name, specialty_description, SUM(t_c_c)
FROM card
	GROUP BY generic_name, specialty_description
	ORDER BY SUM(t_c_c) DESC
LIMIT 5);

--Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims 
-- (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
--b. Now, report the same for Memphis.
--c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

WITH combined AS((SELECT prescription.npi, nppes_provider_city, SUM(total_claim_count) AS total_claims
				FROM prescription
					JOIN prescriber USING(npi)
				WHERE nppes_provider_city = 'NASHVILLE'
				GROUP BY prescription.npi, nppes_provider_city
				ORDER BY total_claims DESC
				LIMIT 5)

UNION ALL

(SELECT prescription.npi, nppes_provider_city, SUM(total_claim_count) AS total_claims
FROM prescription
	JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY prescription.npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)

UNION ALL

(SELECT prescription.npi, nppes_provider_city, SUM(total_claim_count) AS total_claims
FROM prescription
	JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY prescription.npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)

UNION ALL

(SELECT prescription.npi, nppes_provider_city, SUM(total_claim_count) AS total_claims
FROM prescription
	JOIN prescriber USING(npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY prescription.npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5))

SELECT * 
FROM combined
ORDER BY total_claims DESC;

-- Q4- Find all counties which had an above-average number of overdose deaths. 
-- Report the county name and number of overdose deaths.

SELECT county, SUM(overdose_deaths) AS above_average_overdose_deaths
FROM fips_county
	INNER JOIN overdose_deaths ON fips_county.fipscounty::numeric = overdose_deaths.fipscounty
WHERE overdose_deaths >= (SELECT AVG(overdose_deaths) FROM overdose_deaths)
GROUP BY county
ORDER BY above_average_overdose_deaths DESC;
	

-- 5 a. Write a query that finds the total population of Tennessee.

-- checking if polpulation table has population for TN only

	
SELECT SUM( population) AS tot_tn_pop
FROM population
	INNER JOIN fips_county ON fips_county.fipscounty::text = population.fipscounty
WHERE state = 'TN'


--b.Build off of the query that you wrote in part a to write a query that returns for each
-- county that county's name, its population, and the percentage of the total population 
-- of Tennessee that is contained in that county.


SELECT county, population, (population/(SELECT SUM(population) AS t_p FROM population)/100) AS perct
FROM population
	INNER JOIN fips_county ON fips_county.fipscounty::text = population.fipscounty
ORDER BY population

/*SELECT population.fipscounty, SUM( population) AS tot_tn_pop
FROM population
	INNER JOIN fips_county ON fips_county.fipscounty::text = population.fipscounty
	WHERE state = 'TN'
	GROUP BY population.fipscounty

SELECT county, population.fipscounty, (population / 6597381*100 ) AS perct
FROM sum_pop
	INNER JOIN fips_county ON fips_county.fipscounty::text = sum_pop.fipscounty
	WHERE state = 'TN'
	GROUP BY county, population.fipscounty*/
