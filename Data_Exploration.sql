 
/* Q1. What is the percentage of people who died from Covid-19?
   Total Cases vs. Total Deaths */

SELECT 
	SUM(new_cases) AS Total_Cases, 
	SUM(new_deaths) AS Total_Deaths,
	ROUND(SUM(new_deaths)/SUM(new_cases) * 100,2) AS Overall_Case_Fatality_Rate
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL 



/* Q2. What is the percentage of people who died from Covid-19 across different countries?
	   Total Cases vs. Total Deaths - Case Fatality Rate */

SELECT 
	location AS Country,
	COALESCE(SUM(new_cases),0) AS Total_Cases, 
	COALESCE(SUM(new_deaths),0) AS Total_Deaths,
	ROUND(COALESCE(SUM(new_deaths)/ NULLIF(SUM(new_cases),0),0) * 100,2) AS Case_Fatality_Rate
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY Case_Fatality_Rate DESC



/* Q3. What is the percentage of people who contracted Covid-19 across different countries?
	   Total Cases vs. Population  */

SELECT 
	location AS Country, 
	population, 
	COALESCE(SUM(new_cases),0) AS Total_Cases, 
	ROUND(COALESCE(SUM((new_cases/population)),0) * 100,2) AS PercentPopulationInfected
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC 


--# Total Deaths vs. Population 

SELECT 
	location AS Country, 
	population,
	COALESCE(SUM(new_deaths),0) AS Total_Deaths, 
	ROUND(COALESCE(SUM((new_deaths/population)),0) * 100,2) AS Mortality_Rate
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Mortality_Rate DESC



/* Q4. Show Countries with the highest deaths count
	   Showing top 10 Countries with Highest Death count */

SELECT TOP (10) 
	location AS Country, 
	SUM(new_deaths) AS Total_Deaths
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL  
GROUP BY location
ORDER BY Total_Deaths DESC 



/* Q5. What is the Total cases and death count recorded across Continents?
	   Showing continents with the Highest Death count */

SELECT 
	location AS Continent, 
	SUM(new_cases) AS Total_Cases,
	SUM(new_deaths) AS Total_Deaths
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NULL 
	AND location IN ('Europe','Africa','South America','North America','Asia','Oceania')
GROUP BY location
ORDER BY Total_Cases DESC

-- This second query produces the same result as the first.

SELECT 
	continent AS Country, 
	SUM(new_deaths) AS TotalDeathCount
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC



/* Q6. How has the death count trended over time?
	   Showing Death count by year */

SELECT
	YEAR(date) AS Year, 
	SUM(new_deaths) AS Total_Deaths
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL 
GROUP BY YEAR(date) 
ORDER BY Total_Deaths DESC



/* Q7. Show Mortality and Case Fatality Rates trend by Year and Month  */

SELECT 
	YEAR(date) AS Year,
		CASE 
		WHEN  MONTH(date) = 1 THEN 'Jan' WHEN  MONTH(date) = 2 THEN 'Feb' 
		WHEN  MONTH(date) = 3 THEN 'Mar' WHEN  MONTH(date) = 4 THEN 'Apr'  
		WHEN  MONTH(date) = 5 THEN 'May' WHEN  MONTH(date) = 6 THEN 'Jun'
		WHEN  MONTH(date) = 7 THEN 'Jul' WHEN  MONTH(date) = 8 THEN 'Aug' 
		WHEN  MONTH(date) = 9 THEN 'Sep' WHEN  MONTH(date) = 10 THEN 'Oct'  
		WHEN  MONTH(date) = 11 THEN 'Nov'WHEN  MONTH(date) = 12 THEN 'Dec'
		END AS Month,
	SUM(new_cases) AS Total_Cases,
	SUM(new_deaths) AS Total_Deaths,
	ROUND(COALESCE(SUM((new_deaths/population)),0) * 100,4) AS Mortality_Rate,
	ROUND(COALESCE(SUM(new_deaths)/ NULLIF(SUM(new_cases),0),0) * 100,4) AS Case_Fatality_Rate
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL 
GROUP BY YEAR(date), MONTH(date)
ORDER BY Year, MONTH(date)



/* Q8. Show dates of first recorded cases and the number of cases recorded   */

SELECT 
	location,
	MIN(date) AS Date,
	MIN(new_cases) AS Number_Cases_Recorded
FROM Portfolio_Project.[dbo].Covid_Deaths
WHERE continent IS NOT NULL 
	AND new_cases IS NOT NULL 
	AND new_cases != 0
GROUP BY location 
ORDER BY location



/* Q9. How many people have been vaccinated out of the total population ?
	   Vaccination vs. Population*/

SELECT 
	cd.continent AS Continent,
	cd.location AS Country, 
	cd.date AS Date, 
	cd.population AS Population, 
	COALESCE(cv.new_vaccinations,0) AS Daily_Vaccinations,
	COALESCE(SUM(cv.new_vaccinations) 
			OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date),0) AS Rolling_Count_Vaccinated
FROM Portfolio_Project..Covid_Deaths AS cd
	JOIN Portfolio_Project.[dbo].Covid_Vaccinations AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date
WHERE cd.continent IS NOT NULL 
ORDER BY 2,3


-- Showing the percentage of the population that have been vaccinated 
-- USING CTE

WITH popvaccinated (Continent, Country, Date, Population, Daily_Vaccinations, Rolling_Count_Vaccinated)
AS (
SELECT 
	cd.continent AS Continent,
	cd.location AS Country, 
	cd.date AS Date, 
	cd.population AS Population, 
	COALESCE(cv.new_vaccinations,0) AS Daily_Vaccinations,
	COALESCE(SUM(cv.new_vaccinations) 
			OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date),0) AS Rolling_Count_Vaccinated
FROM Portfolio_Project..Covid_Deaths AS cd
	JOIN Portfolio_Project..Covid_Vaccinations AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date
WHERE cd.continent IS NOT NULL 
)

SELECT *, (Rolling_Count_Vaccinated/Population) * 100 AS PercentPopulationVaccinated
FROM popvaccinated


-- Creating temporary table to store the results of the above query

DROP TABLE  IF EXISTS PeopleVaccinated
CREATE TABLE PeopleVaccinated (
	Continent nvarchar(255),
	Country nvarchar(255),
	Date date,
	Population numeric,
	Daily_Vaccinations numeric,
	Rolling_Count_Vaccinated numeric
)

INSERT INTO PeopleVaccinated
SELECT 
	cd.continent AS Continent,
	cd.location AS Country, 
	cd.date AS Date, 
	cd.population AS Population, 
	COALESCE(cv.new_vaccinations,0) AS Daily_Vaccinations,
	COALESCE(SUM(cv.new_vaccinations) 
			OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date),0) AS Rolling_Count_Vaccinated
FROM Portfolio_Project..Covid_Deaths AS cd
	JOIN Portfolio_Project..Covid_Vaccinations AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date
WHERE cd.continent IS NOT NULL 

SELECT *
FROM PeopleVaccinated



/* Q10. How many people have been vaccinated across different continents out of the total population ? */

SELECT 
	cd.continent AS Continent,
	SUM(cv.new_vaccinations) AS Vaccinations
FROM Portfolio_Project..Covid_Deaths AS cd
	 JOIN Portfolio_Project..Covid_Vaccinations AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date
WHERE cd.continent IS NOT NULL 
GROUP BY cd.continent
ORDER BY Vaccinations DESC



/* Q11. How many cases and deaths has Nigera had so far? Show the Mortality, Case fatality rate,
		and vaccinations administered. */

SELECT 
	YEAR(cd.date) AS Year,
	SUM(cd.new_cases) AS Total_Cases,
	SUM(new_deaths) AS Total_Deaths,
	ROUND((SUM(new_deaths)/SUM(cd.new_cases))*100,4) AS Case_Fatality_Rate,
	COALESCE(SUM(cv.new_vaccinations),0) AS Vaccinations
FROM Portfolio_Project..Covid_Deaths AS cd
	 JOIN Portfolio_Project..Covid_Vaccinations AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
	AND cd.location = 'Nigeria'
GROUP BY YEAR(cd.date), cd.population

