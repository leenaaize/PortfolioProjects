/*
Covid 19 Data Exploration

Skills used, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4



-- Select Data that we are going to start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'nigeria' 
AND continent IS NOT NULL
ORDER BY 1,2


--Looking at Total Cases vs Population
--Shows what percentage of population got infected with Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_poulation_infected
FROM PortfolioProject..CovidDeaths
--WHERE location = 'nigeria'
ORDER BY 1,2


--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)) *100 AS percent_poulation_infected
FROM PortfolioProject..CovidDeaths
--WHERE location = 'nigeria'
GROUP BY location, population
ORDER BY percent_poulation_infected DESC


--Looking at Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS int))  AS total_death_count
FROM PortfolioProject..CovidDeaths
--WHERE location = 'nigeria'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC



--BREAKING THINGS DOWN BY CONTINENT

--Showing ContinentS with Highest Death Count per Population

SELECT continent, SUM(latest_deaths) AS total_death_count
FROM (
    SELECT continent, location, MAX(CAST(total_deaths AS INT)) AS latest_deaths
    FROM PortfolioProject..CovidDeaths
    WHERE continent IS NOT NULL
    GROUP BY continent, location
) AS sub
GROUP BY continent
ORDER BY total_death_count DESC;


--SELECT continent, MAX(CAST(total_deaths AS int))  AS total_death_count
--FROM PortfolioProject..CovidDeaths
----WHERE location = 'nigeria'
--WHERE continent IS NOT NULL
--GROUP BY continent
--ORDER BY total_death_count DESC



--GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
--WHERE location = 'nigeria' 
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



--Looking at Total Population vs Vaccinations
--Shows the percentage of population that has received at least one covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(int,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinations_running_total
       --, (vaccinations_running_total/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
     ON dea.location = vac.location
     AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Using CTE to perform calculations on Partition By in previous query

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Vaccinations_Running_Total) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,SUM(CONVERT(int,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinations_running_total
--, (vaccinations_running_total/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
     ON dea.location = vac.location
     AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (Vaccinations_Running_Total/Population)*100
FROM PopVsVac



---Using Temp Table to perform calculation on Partition By in previous query 

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Vaccinations_Running_Total numeric 
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,SUM(CONVERT(int,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinations_running_total
--, (vaccinations_running_total/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
     ON dea.location = vac.location
     AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (Vaccinations_Running_Total/Population)*100
FROM #PercentPopulationVaccinated



--Creating View to Store Data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,SUM(CONVERT(int,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccinations_running_total
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
     ON dea.location = vac.location
     AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
