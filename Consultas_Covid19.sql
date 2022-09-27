# Alterando a data para o formato adequado utilizando o SQL_SAFE_UPDATES para habilitar a alteração dos dados.
# Transformo tudo em dia, mês, ano e depois fecho o SQL_SAFE_UPDATES por segurança.
SET SQL_SAFE_UPDATES = 0;

UPDATE cap07.covid_mortes 
SET date = str_to_date(date,'%d/%m/%y');

UPDATE cap07.covid_vacinacao 
SET date = str_to_date(date,'%d/%m/%y');

SET SQL_SAFE_UPDATES = 1;


## ANÁLISE EXPLORATÓRIA ##

# 1- Qual a média de mortos dos 5 primeiros países que apresentaram mais mortes por Covid-19 ? v
SELECT location,
       ROUND(AVG(total_deaths), 2) AS MediaMortos
FROM cap07.covid_mortes 
GROUP BY location
ORDER BY MediaMortos DESC;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 2- Qual data teve a maior proporção de mortes em relação ao total de casos no Brasil? v
SELECT date,
       location, 
       total_cases,
       total_deaths,
       ROUND(((total_deaths / total_cases) * 100), 2) AS PercentualMortes
FROM cap07.covid_mortes  
WHERE location = "Brazil" 
ORDER BY 5 DESC;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 3- Qual a proporção média entre o total de casos e a população das 5 primeiras localidades? v
SELECT location,
       ROUND(AVG((total_cases / population) * 100), 2) AS PercentualPopulacao
FROM cap07.covid_mortes  
GROUP BY location
ORDER BY PercentualPopulacao DESC;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 4- Considerando o maior valor do total de casos, quais os 3 países com a maior taxa de infecção em relação à população? v
# Usei NOT NULL porque em alguns casos, o continente não esta preenchido.
SELECT location, 
       MAX(CAST(total_cases AS UNSIGNED)) AS MaiorContagemInfec,
       ROUND((MAX(total_cases / population) * 100), 2) AS PercentualPopulacao
FROM cap07.covid_mortes 
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY PercentualPopulacao DESC;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 5- Quais os continentes com o maior número de mortes? v
SELECT continent, 
       MAX(CAST(total_deaths AS UNSIGNED)) as MaiorContagemMortes
FROM cap07.covid_mortes 
WHERE continent IS NOT NULL 
GROUP BY continent 
ORDER BY MaiorContagemMortes DESC;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 6- Qual o número de novos vacinados e a média móvel de novos vacinados ao longo do tempo por localidade ? Considerando apenas os dados da América do Sul.

OBS.: 
# A coluna date foi a única forma que eles encontraram na época para poder relacionar os dados das duas tabelas.
# Analisando os dados, como um exemplo tem a Argentina que se observar no resultado não teve vacinação em 2020, foi começa a ter la para 21-01-2021.
  A medida em que novos vacinados vão surgindo,vai incrementando a média movel (média ao longo do tempo).
# Observando os dados, em alguns casos não temos informações de novos vacinados. Os dados não são perfeitos porque as vezes não tinha informação. 
  O governo do Brasil em um determinado momento decidiu não divulgar os dados por questões políticas. Ai o Consórcio da Imprensa não quis ficar de forma irresponsável sem os dados e começou
  a coletar os dados e divulga-los na TV. Depois o Ministério da Saúde voltou e começou de novo a divulgar os dados. 
  E assim provavelmente aconteceu em outros países e por isso em certos momentos não apresenta dados.
# A média movel muda porque considera o número de ítens ao longo do tempo, se o número de novos vacinados não aumenta ela tende a cair (talvez não tivesse dados ou vacinas suficiente pras pessoas)
  mas se volta a vacinação ela volta a crescer.

SELECT mortos.continent,
       mortos.location,
       mortos.date,
       vacinados.new_vaccinations,
       AVG(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) as MediaMovelVacinados
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.continent = 'South America'
ORDER BY 2,3;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 7- Qual o número de novos vacinados e o total de novos vacinados ao longo do tempo por continente? Considerando apenas os dados da América do Sul.

OBS.:
# Analisando o resultado da Query, vemos que o total de vacinados vai se movendo ao longo do tempo e a medida em que novos dados de novos vacinados vão aparecendo, ele vai aumentando.

SELECT mortos.continent,
       mortos.date,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.continent ORDER BY mortos.date) as TotalVacinados
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.continent = 'South America'
ORDER BY 1,2;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 8- Qual o número de novos vacinados e o total de novos vacinados ao longo do tempo por continente? Considerando apenas os dados da América do Sul.

OBS.:
# Nível de granularidade maior filtrando por mês.

SELECT mortos.continent,
       DATE_FORMAT(mortos.date, "%M/%Y") AS MES,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.continent ORDER BY DATE_FORMAT(mortos.date, "%M/%Y")) as TotalVacinados
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.continent = 'South America'
ORDER BY 1,2;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 9- Qual o percentual da população com pelo menos 1 dose da vacina ao longo do tempo? Considerando apenas os dados do Brasil. 

OBS.:
# Analisando o resultado da Query vemos que o percentual da primeira dose era 0 no começo e a medida em que avança a vacinação o percentual vai aumentando ao longo do tempo porque as pessoas 
  vão tendo pelo menos 1 dose de vacinação.

WITH PopvsVac (continent,location, date, population, new_vaccinations, TotalMovelVacinacao) AS
(
SELECT mortos.continent,
       mortos.location,
       mortos.date,
       mortos.population,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) AS TotalMovelVacinacao
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados 
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.location = 'Brazil'
)
SELECT *, ROUND(((TotalMovelVacinacao / population) * 100), 2) AS Percentual_1_Dose FROM PopvsVac;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 10- Durante o mês de Maio/2021 o percentual de vacinados com pelo menos uma dose aumentou ou diminuiu no Brasil?

OBS.:
# Analisando o resultado da Query, vemos que o percentual da primeira dose no começo de Maio era 18,51% e no final foi de 26,12%.

WITH PopvsVac (continent, location, date, population, new_vaccinations, TotalMovelVacinacao) AS
(
SELECT mortos.continent,
       mortos.location,
       mortos.date,
       mortos.population,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) AS TotalMovelVacinacao
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados 
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.location = 'Brazil'
)
SELECT *, ROUND(((TotalMovelVacinacao / population) * 100), 2) AS Percentual_1_Dose 
FROM PopvsVac
WHERE DATE_FORMAT(date, "%M/%Y") = 'May/2021'
AND location = 'Brazil';