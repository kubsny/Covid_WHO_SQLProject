-- Covid vaccines data ordered by location, date

SELECT *
FROM SQLProject..Covid_vaccines
ORDER BY 3,4

-- Covid deaths data ordered by location, date

SELECT *
FROM SQLProject..Covid_deaths
ORDER BY 3,4

-- Total cases and total deaths in Poland

SELECT location, date, total_cases, total_deaths
FROM SQLProject..Covid_deaths
WHERE location = 'Poland'
ORDER BY location, date

-- Looking at total cases vs total death + death per cases% in Poland

SELECT DISTINCT location, date, total_cases, total_deaths, 
	CASE
		WHEN total_cases = 0 THEN 0 
        ELSE (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 
	END AS death_percentage
FROM SQLProject..Covid_deaths
WHERE location = 'Poland'
ORDER BY location, date

-- Looking at total cases vs population + population % infected in all reported countries

SELECT location, date, total_cases, population, 
	CASE 
        WHEN total_cases = 0 THEN 0 
        ELSE (CONVERT(float, total_cases) / NULLIF(population, 0)) * 100 
	END AS population_precentage
FROM SQLProject..Covid_deaths
WHERE location NOT IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania', 'European Union')
ORDER BY location, date

-- Looking at total cases vs population + % of population infected grouped by location

SELECT location, MAX(population) AS population, SUM(new_cases) AS infections, (SUM(new_cases)/MAX(population))*100  AS precentage_of_population_infected
FROM SQLProject..Covid_deaths
--WHERE location = 'Poland'
GROUP BY location
ORDER BY precentage_of_population_infected DESC


-- Looking at highiest Death Rate + % of population no longer with us

SELECT location, MAX(population) AS population, SUM(new_deaths) AS deaths, (SUM(new_deaths)/MAX(population))*100 AS Death_rate
FROM SQLProject..Covid_deaths
GROUP BY location
ORDER BY Death_rate DESC

-- Show countries with Highiest Death Count

SELECT location, MAX(population) AS population, SUM(new_deaths) AS deaths
FROM SQLProject..Covid_deaths
WHERE continent is not null
GROUP BY location
ORDER BY deaths DESC

--Show continents with Highiest Death Count (population right when specified location/ not via continent column + removed High income as location)

SELECT location, MAX(population) AS population, SUM(new_deaths) AS Reported_deaths, (SUM(new_deaths)/MAX(population))*100 AS precentage_of_population
FROM SQLProject..Covid_deaths
WHERE location IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania')
GROUP BY location
ORDER BY precentage_of_population DESC

--Show World cases, % of population infected and deaths + % of population dead

SELECT MAX(population) as world_population, SUM(new_cases) As reported_cases, (SUM(new_cases)/MAX(population))*100 AS cases_precentage, SUM(new_deaths) AS reported_deaths, (SUM(new_deaths)/MAX(population))*100 AS death_precentage
FROM SQLProject..Covid_deaths
WHERE location = 'World'
GROUP BY location


--Show total cases + total deaths

SELECT SUM(new_cases) AS reported_covid_cases, SUM(new_deaths) AS Reported_deaths, 
    CASE 
       WHEN SUM(new_cases) = 0 THEN 0  -- If total new cases is zero, set death rate to 0
       ELSE (SUM(new_deaths) * 100.0 / NULLIF(SUM(new_cases), 0))  -- Calculate death rate
	END AS Death_rate
FROM SQLProject..Covid_deaths
WHERE location IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania')


--Looking at total population vs roll_people infected vs roll_people dead vs people vaccinated


SELECT 
dea.location, dea.date, dea.population, SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS ppl_infected, 
SUM(new_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) ppl_dead, vac.new_people_vaccinated_smoothed, SUM(CONVERT(float, vac.new_people_vaccinated_smoothed)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vacc
FROM SQLProject..Covid_deaths dea
JOIN SQLProject..Covid_vaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.location NOT IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania') 
Where dea.location = 'Poland' --choose country/continent to display
GROUP BY dea.location, dea.date, dea.population, dea.new_cases, new_deaths, vac.new_people_vaccinated_smoothed, vac.total_vaccinations
ORDER BY 1,2



--USE CTE

WITH popvsvac (location, date, population, ppl_infected, ppl_dead, new_people_vaccinated_smoothed, rolling_vacc)
AS
(
SELECT 
dea.location, dea.date, dea.population, SUM(dea.new_cases) AS ppl_infected, SUM(new_deaths) AS ppl_dead, vac.new_people_vaccinated_smoothed, 
SUM(CONVERT(float, vac.new_people_vaccinated_smoothed)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vacc
FROM SQLProject..Covid_deaths dea
JOIN SQLProject..Covid_vaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.location NOT IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania') 
WHERE dea.location = 'Poland' --choose country to display
GROUP BY dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed, vac.total_vaccinations
--ORDER BY 1,2
)
SELECT *, (rolling_vacc/population)*100 AS prec_popvaccinated
FROM popvsvac


-- TEMP TABLE (people infected/people  dead + precentage pre population for both)


DROP TABLE IF exists #PrecentPopulationInfectedandDead
CREATE TABLE #PrecentPopulationInfectedandDead
(
location nvarchar(255),
date datetime,
population numeric,
ppl_infected numeric,
ppl_dead numeric,
)
INSERT INTO #PrecentPopulationInfectedandDead
SELECT 
dea.location, dea.date, dea.population, SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS ppl_infected, 
SUM(new_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) ppl_dead
FROM SQLProject..Covid_deaths dea
JOIN SQLProject..Covid_vaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.location NOT IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania') 
--Where dea.location = 'Poland' --choose country/continent to display
GROUP BY dea.location, dea.date, dea.population, dea.new_cases, new_deaths
ORDER BY location, date 

SELECT *, (ppl_infected/population)*100 AS prec_popinfected, (ppl_dead/population)*100 AS prec_popdead
FROM #PrecentPopulationInfectedandDead



-- Views to store data for later visualization 

-- view for infected, dead, vaccinated

DROP VIEW IF exists peopleinfected_dead_vacc
USE SQLProject
GO
CREATE VIEW peopleinfected_dead_vacc as 
SELECT 
dea.location, dea.date, dea.population, SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS ppl_infected, SUM(new_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) ppl_dead, vac.new_people_vaccinated_smoothed, 
SUM(CONVERT(float, vac.new_people_vaccinated_smoothed)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vacc
FROM SQLProject..Covid_deaths dea
JOIN SQLProject..Covid_vaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.location NOT IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania') 
--WHERE dea.location = 'Poland' --choose country to display
GROUP BY dea.location, dea.date, dea.population, dea.new_cases, dea.new_deaths, vac.new_people_vaccinated_smoothed


SELECT * 
FROM peopleinfected_dead_vacc



-- view for new vaccinations, all vaccinations and precentage of population vaccinated (with CTE)

DROP VIEW IF exists vaccinationsview
USE SQLProject
GO
CREATE VIEW vaccinationsview as 
WITH popvsvac (location, date, population, new_people_vaccinated_smoothed, rolling_vacc)
AS
(
SELECT 
dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed, 
SUM(CONVERT(float, vac.new_people_vaccinated_smoothed)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vacc
FROM SQLProject..Covid_deaths dea
JOIN SQLProject..Covid_vaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.location NOT IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania') 
--WHERE dea.location = 'Poland' --choose country to display
GROUP BY dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed, vac.total_vaccinations
--ORDER BY 1,2
)
SELECT *, (rolling_vacc/population)*100 AS prec_popvaccinated
FROM popvsvac


SELECT * 
FROM vaccinationsview


-- view - continents, reported deaths and % of population dead

DROP VIEW IF exists continentsdeads
USE SQLProject
GO
CREATE VIEW continentsdeads AS
SELECT location, MAX(population) AS population, SUM(new_deaths) AS Reported_deaths, (SUM(new_deaths)/MAX(population))*100 AS precentage_of_population
FROM SQLProject..Covid_deaths
WHERE location IN ('Asia', 'Africa', 'Europe', 'South America', 'North America', 'Oceania')
GROUP BY location


SELECT * 
FROM continentsdeads
ORDER BY precentage_of_population DESC


-- View for countries with most deaths


DROP VIEW IF exists countriesdeaths
USE SQLProject
GO
CREATE VIEW countriesdeaths AS
SELECT location, MAX(population) AS population, SUM(new_deaths) AS deaths
FROM SQLProject..Covid_deaths
WHERE continent is not null
GROUP BY location


SELECT * 
FROM countriesdeaths
ORDER BY deaths DESC


