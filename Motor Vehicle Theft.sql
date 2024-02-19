--What day of the week are vehicles most often and least often stolen?

SELECT DATENAME(dw, sv.date_stolen) AS DayofWeek, count(*) as stolen_vehicle_count
FROM dbo.stolen_vehicles sv
WHERE sv.date_stolen IS NOT NULL
group by DATENAME(dw, sv.date_stolen)
ORDER BY stolen_vehicle_count DESC;



--What types of vehicles are most often and least often stolen? Does this vary by region?
WITH StolenVehicleCounts AS (
    SELECT 
        SV.VEHICLE_TYPE AS VEHICLETYPE,
        L.REGION,
        COUNT(*) AS stolen_vehicle_count,
        ROW_NUMBER() OVER (PARTITION BY L.REGION ORDER BY COUNT(*) DESC) AS RowNum,
        ROW_NUMBER() OVER (PARTITION BY L.REGION ORDER BY COUNT(*) ASC) AS ReverseRowNum
    FROM 
        DBO.STOLEN_VEHICLES AS SV
    JOIN 
        DBO.LOCATIONS AS L ON L.LOCATION_ID = SV.LOCATION_ID
    WHERE 
        SV.VEHICLE_TYPE IS NOT NULL
    GROUP BY 
        SV.VEHICLE_TYPE, L.REGION
)
SELECT REGION,
    CASE 
        WHEN RowNum = 1 THEN 'Most'
        WHEN ReverseRowNum = 1 THEN 'Least'
        ELSE 'Other'
    END AS MostOrLeast,
    VEHICLETYPE,
    stolen_vehicle_count
FROM 
    StolenVehicleCounts
WHERE 
    RowNum = 1 OR ReverseRowNum = 1
    order by 3;

--	 What is the average age of the vehicles that are stolen? Does this vary based on the vehicle type?

WITH STOLENDATE AS
(SELECT DATEPART(YEAR,DATE_STOLEN) AS STOLEN_YEAR, MODEL_YEAR,vehicle_type
FROM DBO.STOLEN_VEHICLES)
SELECT sd.Vehicle_Type,
avg(sd.stolen_year-sd.model_year) as "AverageAge(Years)"
FROM STOLENDATE SD
WHERE SD.VEHICLE_TYPE IS NOT NULL
group by sd.vehicle_type
order by 2;

--Which regions have the most and least number of stolen vehicles? What are the characteristics of the regions?

with regionwise as 
(SELECT l.region as region, round(avg(l.population),2) as population, round(avg(density),2) as density,
count(*) as No_stolen_vehicles,
ROW_NUMBER() over (order by count(*) desc) as rank,
ROW_NUMBER() over (order by count(*)) as revrank
from dbo.stolen_vehicles sv
inner join locations l
on l.location_id = sv.location_id
group by l.region)
select region, population, density, no_stolen_vehicles
from regionwise
where rank =1 or revrank=1
order by 4;



SELECT vehicle_type, count(*) as stolen_vehicle_count
FROM dbo.stolen_vehicles
group by vehicle_type
order by