/*
Coronavirus (COVID-19) Deaths
Data for this exploration is available at https://ourworldindata.org/covid-deaths 
Data has been confirmed to be open source and available for public use

Data processing involved Data Type Conversion, Windowing Functions, Temp Tables, Common Table expressions(With Clause), Views, Aggregate Functions

*/
------Data was loaded into Microst SQL Server Management Studio

Select *
From dbo.covid_deaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From dbo.covid_deaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country (in my own case Nigeria)

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From dbo.covid_deaths
Where lower(location) like '%nigeria%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From dbo.covid_deaths
--Where lower(location) like '%nigeria%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From dbo.covid_deaths
--Where lower(location) like '%nigeria%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.covid_deaths
--Where lower(location) like '%nigeria%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- CATEGORIZING BY CONTINENT

-- Showing contintents with the highest death toll per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.covid_deaths
--Where lower(location) like '%nigeria%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From dbo.covid_deaths
--Where lower(location) like '%nigeria%'
where continent is not null 
--Group By date
order by 1,2



-- Total Population compared against Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select a.continent, a.location, a.date, a.population, b.new_vaccinations
, SUM(CONVERT(bigint,(case when trim(b.new_vaccinations) is NULL then 0 else trim(b.new_vaccinations) end))) OVER (Partition by a.Location Order by a.location, a.Date) as vaccinated_people_accumulated
From dbo.covid_deaths a
Join dbo.covid_vaccinations b
    On a.location = b.location
    and a.date = b.date
where a.continent is not null 
order by 2,3


-- Using CTE and Windowing functions to perform Calculations

With C (Continent, Location, Date, Population, New_Vaccinations, vaccinated_people_accumulated)
as
(
Select a.continent, a.location, a.date, a.population, b.new_vaccinations
, SUM(CONVERT(bigint,(case when trim(b.new_vaccinations) is NULL then 0 else trim(b.new_vaccinations) end))) OVER (Partition by a.Location Order by a.location, a.Date) as vaccinated_people_accumulated
--, (vaccinated_people_accumulated/population)*100
From dbo.covid_deaths a
Join dbo.covid_vaccinations b
    On a.location = b.location
    and a.date = b.date
where a.continent is not null 
--order by 2,3
)
Select *, (vaccinated_people_accumulated/Population)*100
From C



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
vaccinated_people_accumulated numeric
)

Insert into #PercentPopulationVaccinated
Select a.continent, a.location, a.date, a.population, b.new_vaccinations
, SUM(CONVERT(bigint,(case when trim(b.new_vaccinations) is NULL then 0 else trim(b.new_vaccinations) end))) OVER (Partition by a.Location Order by a.location, a.Date) as vaccinated_people_accumulated
From dbo.covid_deaths a
Join dbo.covid_vaccinations b
    On a.location = b.location
    and a.date = b.date
--where a.continent is not null 
--order by 2,3

Select *, (vaccinated_people_accumulated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select a.continent, a.location, a.date, a.population, b.new_vaccinations
, SUM(CONVERT(bigint,(case when trim(b.new_vaccinations) is NULL then 0 else trim(b.new_vaccinations) end))) OVER (Partition by a.Location Order by a.location, a.Date) as vaccinated_people_accumulated
From dbo.covid_deaths a
Join dbo.covid_vaccinations b
    On a.location = b.location
    and a.date = b.date
where a.continent is not null 