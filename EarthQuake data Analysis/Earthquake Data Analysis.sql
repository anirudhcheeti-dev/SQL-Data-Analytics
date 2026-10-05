select * from earthquake_data;
--Convert the time column into DATE and TIME fields using SQL date/time functions.
SELECT 
    "time",
    DATE("time") AS date_part,
    CAST("time" AS TIME) AS time_part
FROM 
    earthquake_data;
--Remove rows with null or missing values in critical columns: mag, latitude, longitude, depth.
--Viewing which rows will be affected 
SELECT * FROM earthquake_data
WHERE mag IS NULL
   OR latitude IS NULL
   OR longitude IS NULL
   OR depth IS NULL;

Delete from earthquake_data
WHERE mag IS NULL
   OR latitude IS NULL
   OR longitude IS NULL
   OR depth IS NULL;
--Standardize the place field: remove extra spaces and ensure consistent capitalization.
UPDATE earthquake_data
SET place = INITCAP(TRIM(place))
WHERE place IS NOT NULL;
--Validate numeric data types for mag, depth, latitude, and longitude.
-- Check for NULLs
SELECT COUNT(*) AS null_mag FROM earthquake_data WHERE mag IS NULL;
SELECT COUNT(*) AS null_lat FROM earthquake_data WHERE latitude IS NULL;
SELECT COUNT(*) AS null_lon FROM earthquake_data WHERE longitude IS NULL;
SELECT COUNT(*) AS null_depth FROM earthquake_data WHERE depth IS NULL;

-- Check for non-positive or abnormal values
SELECT * FROM earthquake_data WHERE mag < 0 OR mag > 10;
SELECT * FROM earthquake_data WHERE latitude < -90 OR latitude > 90;
SELECT * FROM earthquake_data WHERE longitude < -180 OR longitude > 180;
SELECT * FROM earthquake_data WHERE depth < 0;

--Earthquake Frequency And Magnitude Analysis
--Count the total number of earthquakes in the dataset.
SELECT 
    id,
    COUNT(*) AS count
FROM 
    earthquake_data
GROUP BY 
    id
HAVING 
    COUNT(*) > 1;
--As there are duplicate id
SELECT COUNT(*) FROM earthquake_data;

SELECT COUNT(DISTINCT id) FROM earthquake_data;

SELECT id, COUNT(*) 
FROM earthquake_data 
GROUP BY id 
HAVING COUNT(*) > 1;
--Find the Top 10 locations (using place) with the highest number of recorded events.
select 
    count(*) as Total_event_by_place,
	place
from earthquake_data
group by place
order by Total_event_by_place desc
limit 10;
--Count earthquakes by magnitude range. Minor (< 4.0), Light (4.0–5.9), Moderate (6.0–6.9), Strong (7.0–7.9) and Major (8.0+)
SELECT 
  CASE
    WHEN mag < 4.0 THEN 'Minor (<4.0)'
    WHEN mag >= 4.0 AND mag < 6.0 THEN 'Light (4.0–5.9)'
    WHEN mag >= 6.0 AND mag < 7.0 THEN 'Moderate (6.0–6.9)'
    WHEN mag >= 7.0 AND mag < 8.0 THEN 'Strong (7.0–7.9)'
    WHEN mag >= 8.0 THEN 'Major (8.0+)'
    ELSE 'Unknown'
  END AS magnitude_category,
  COUNT(*) AS earthquake_count
FROM earthquake_data
WHERE mag IS NOT NULL
GROUP BY magnitude_category
ORDER BY earthquake_count DESC;
--Average magnitude by year.
SELECT 
    EXTRACT(YEAR FROM time) AS year,
    AVG(mag) AS "Average magnitude by year"
FROM earthquake_data
WHERE mag IS NOT NULL
GROUP BY year
ORDER BY "Average magnitude by year" DESC;
--Temporal Analysis
--Count the number of earthquakes by month and year.
select 
    EXTRACT(YEAR FROM time) AS year,
    extract(month from time) as Month,
	count(*) as "Number of Earthquake"
from earthquake_data
group by year,month
ORDER BY year, month;
--Identify months with the highest number of significant earthquakes.
select 
    extract(month from time) as Month,
	count(*) as "Number of Earthquake"
from earthquake_data
group by month
ORDER BY "Number of Earthquake" desc;
--Trend: Number of earthquakes per year over time
SELECT 
    EXTRACT(YEAR FROM time) AS year,
    COUNT(*) AS earthquake_count
FROM earthquake_data
GROUP BY year
ORDER BY year;
--Geographic And Depth Analysis
--Average depth of earthquakes grouped by region or partial text from place.
SELECT 
    LEFT(place, POSITION(',' IN place) - 1) AS region,
    AVG(depth) AS average_depth
FROM earthquake_data
WHERE place IS NOT NULL AND POSITION(',' IN place) > 0
GROUP BY region
ORDER BY average_depth DESC;
--Count of Earthquakes by Depth Category
SELECT
    CASE 
        WHEN depth < 70 THEN 'Shallow (<70 km)'
        WHEN depth BETWEEN 70 AND 300 THEN 'Intermediate (70-300 km)'
        WHEN depth > 300 THEN 'Deep (>300 km)'
        ELSE 'Unknown'
    END AS depth_category,
    COUNT(*) AS count
FROM earthquake_data
WHERE depth IS NOT NULL
GROUP BY depth_category
ORDER BY count DESC;
--Top 5 Deepest Earthquakes
SELECT 
    place,
    mag,
    depth
FROM earthquake_data
WHERE depth IS NOT NULL
ORDER BY depth DESC
LIMIT 5;
--Advanced SQL Queries
--Window Function: Rank earthquakes by magnitude within each year.
SELECT 
    id,
    EXTRACT(YEAR FROM time) AS year,
    mag,
    place,
    RANK() OVER (PARTITION BY EXTRACT(YEAR FROM time) ORDER BY mag DESC) AS mag_rank
FROM earthquake_data
WHERE mag IS NOT NULL;
--Running Total: Create a query showing cumulative count of earthquakes over time.
SELECT 
    time::date AS date,
    COUNT(*) AS daily_quakes,
    SUM(COUNT(*)) OVER (ORDER BY time::date) AS cumulative_quakes
FROM earthquake_data
GROUP BY date
ORDER BY date;
--Boolean Flag: Add a column for “High Risk” earthquakes where mag > 7.0 AND depth < 70 km.
SELECT 
    *,
    CASE 
        WHEN mag > 7.0 AND depth < 70 THEN TRUE
        ELSE FALSE
    END AS high_risk
FROM earthquake_data;
--Find earthquakes with unusually large azimuthal gaps (gap > 180°).
SELECT 
    id,
    time,
    mag,
    gap,
    place
FROM earthquake_data
WHERE gap > 180;