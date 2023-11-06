select * from PortfolioProject..covidDeath
--where continent is not null
where location like 'lower%'
order by 3,4

--select * from PortfolioProject..covidVaccination
--order by 3,4

--select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..covidDeath
where continent is not null
order by 1, 2

--looking at total cases vs total death
--show likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (convert(float,total_deaths)/NULLIF(convert(float, total_cases), 0))*100 as DeathPercentage
from PortfolioProject..covidDeath
where location = 'indonesia' and continent is not null
order by 1, 2

--looking at total cases vs population
--shows what percentage of populaion got covid

select location, date, total_cases, population, (NULLIF(convert(float, total_cases), 0))/(convert(float, population))*100 as PercentagePopulationInfected
from PortfolioProject..covidDeath
where location = 'indonesia' and continent is not null
order by 1, 2

--looking at countries with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as PercentagePopulationInfected
from PortfolioProject..covidDeath
where continent is not null
group by location, population
order by PercentagePopulationInfected desc

--showing countries with death count per population

select location, population, max(convert(bigint,total_deaths)) as TotalDeathCount
from PortfolioProject..covidDeath
where continent is not null
group by location, population
order by TotalDeathCount desc

--break things down by the continent
--showing continent with highest death count per population

select location, population, max(convert(int,total_deaths)) as TotalDeathCount
from PortfolioProject..covidDeath
where continent is not null
group by location, population
order by TotalDeathCount desc

-- global numbers

select date, sum(new_cases) as TotalNewCases, sum(cast(new_deaths as bigint)) as TotalNewDeath, 
sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100 as DeathPercentage
from PortfolioProject..covidDeath
where continent is not null
group by date, New_Cases, new_deaths
order by 1, 2

--VACCINATION

select * from PortfolioProject..covidVaccination

--looking at total population vs vaccinatiton

select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location,
d.date) as rollingPeopleVaccinated
from PortfolioProject..covidDeath d join PortfolioProject..covidVaccination v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null --and v.new_vaccinations is not null
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
order by 2, 3

--menggunakan CTE = membuat tabel temporary

with PopVsVac (continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location,
d.date) as rollingPeopleVaccinated
from PortfolioProject..covidDeath d join PortfolioProject..covidVaccination v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null --and v.new_vaccinations is not null
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
)
select *, (rollingPeopleVaccinated/population)*100 
from PopVsVac

--TEMP TABLE
DROP TABLE if exists percentPopulationVaccinated --buat update table
create table percentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
)

insert into percentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location,
d.date) as rollingPeopleVaccinated
from PortfolioProject..covidDeath d join PortfolioProject..covidVaccination v
	on d.location = v.location
	and d.date = v.date
--where d.continent is not null --and v.new_vaccinations is not null
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
order by 2, 3

select *, (rollingPeopleVaccinated/population)*100 
from percentPopulationVaccinated

--creating view to store data for later visualization
--PercentPopulationVaccinated = PPV
create view PPV as
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location,
d.date) as rollingPeopleVaccinated
from PortfolioProject..covidDeath d join PortfolioProject..covidVaccination v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null --and v.new_vaccinations is not null
--group by d.continent, d.location, d.date, d.population, v.new_vaccinations
--order by 2, 3

select * from PPV