-- ============================================
-- Indian Railways Delay Analytics
-- Schema: Tables + Relationships
-- ============================================
 
DROP TABLE IF EXISTS delays;
DROP TABLE IF EXISTS weather;
DROP TABLE IF EXISTS routes;
DROP TABLE IF EXISTS trains;
DROP TABLE IF EXISTS stations;
 
-- ---------- STATIONS ----------
CREATE TABLE stations (
    station_id     SERIAL PRIMARY KEY,
    station_code   VARCHAR(10) UNIQUE NOT NULL,
    station_name   VARCHAR(100) NOT NULL,
    state          VARCHAR(50) NOT NULL,
    zone           VARCHAR(50) NOT NULL
);
 
-- ---------- TRAINS ----------
CREATE TABLE trains (
    train_id       SERIAL PRIMARY KEY,
    train_number   VARCHAR(10) UNIQUE NOT NULL,
    train_name     VARCHAR(100) NOT NULL,
    train_type     VARCHAR(20) NOT NULL  -- Rajdhani / Shatabdi / Express / Superfast / Passenger
);
 
-- ---------- WEATHER ----------
CREATE TABLE weather (
    weather_id      SERIAL PRIMARY KEY,
    station_id      INT NOT NULL REFERENCES stations(station_id),
    weather_date    DATE NOT NULL,
    condition       VARCHAR(20) NOT NULL,  -- Clear / Rain / Fog / Storm
    temperature_c   INT NOT NULL,
    UNIQUE (station_id, weather_date)      -- one weather record per station per day
);
 
-- ---------- ROUTES ----------
CREATE TABLE routes (
    route_id           SERIAL PRIMARY KEY,
    train_id           INT NOT NULL REFERENCES trains(train_id),
    source_station_id  INT NOT NULL REFERENCES stations(station_id),
    dest_station_id    INT NOT NULL REFERENCES stations(station_id),
    distance_km        INT NOT NULL
);
 
-- ---------- DELAYS (fact table) ----------
CREATE TABLE delays (
    delay_id        SERIAL PRIMARY KEY,
    train_id        INT NOT NULL REFERENCES trains(train_id),
    route_id        INT NOT NULL REFERENCES routes(route_id),
    station_id      INT NOT NULL REFERENCES stations(station_id),
    weather_id      INT REFERENCES weather(weather_id),  -- nullable: not every trip may match a logged weather record
    travel_date     DATE NOT NULL,
    scheduled_time  TIME NOT NULL,
    actual_time     TIME NOT NULL,
    delay_minutes   INT,  -- nullable on purpose: real-world logs sometimes miss this value
    month           VARCHAR(15) NOT NULL,
    season          VARCHAR(15) NOT NULL  -- Summer / Monsoon / Winter
);


/* EXPLORATERY DATA ANALYSIS - EDA */

--Total no.of rows
SELECT COUNT(*) FROM delays;

--Top 20 delays
SELECT * FROM delays LIMIT 20;

--Write a query that shows all the distinct seasons - Showed 9 so we need to clean
SELECT DISTINCT season FROM delays; 

--Count how many rows fall into each of those 9 messy variations above?
SELECT season, COUNT(*) AS no_of_rows_seasons FROM delays GROUP BY season ORDER BY no_of_rows_seasons DESC;


--Make all values to proper case
UPDATE delays
SET season = INITCAP(season);

--Write a query that shows all the distinct seasons
SELECT DISTINCT season FROM delays;


--Count how many rows have a NULL in that column
SELECT * FROM delays WHERE 
delay_id IS NULL
OR
train_id IS NULL
OR 
route_id IS NULL
OR
station_id IS NULL
OR
weather_id IS NULL
OR
travel_date IS NULL
OR
scheduled_time IS NULL
OR
actual_time IS NULL
OR
delay_minutes IS NULL
OR
month IS NULL
OR
season IS NULL;

--Update the NULLs by calculating the delay
UPDATE delays
SET delay_minutes = ROUND(EXTRACT(EPOCH FROM (actual_time - scheduled_time)) / 60) WHERE delay_minutes IS NULL;

--Find duplicate values
SELECT train_id, station_id, weather_id, travel_date, scheduled_time, actual_time, delay_minutes, month, season,COUNT(*) AS how_many_times 
FROM delays GROUP BY train_id, station_id, weather_id, travel_date, scheduled_time, actual_time, delay_minutes, month, season 
HAVING COUNT(*) > 1;


--Which delay_id we plan to keep for each group.
SELECT MIN(delay_id) AS keep_id, train_id, station_id, weather_id, travel_date, scheduled_time, actual_time, delay_minutes, month, season
FROM delays
GROUP BY train_id, station_id,weather_id, travel_date, scheduled_time, actual_time, delay_minutes, month, season
HAVING COUNT(*) > 1;

/*Deleting the duplicates - "Group all the trips that look exactly the same together. For every group, just give me the smallest ID number in that group."*/
DELETE FROM delays WHERE delay_id NOT IN (
   SELECT MIN(delay_id) FROM delays
   GROUP BY train_id, station_id, weather_id,travel_date, scheduled_time, actual_time, delay_minutes, month, season
);

SELECT COUNT(*) FROM delays;




/* BUSINESS QUESTIONS */

-- ============================================
-- Indian Railways Delay Analytics
-- Business Questions 1-15
-- ============================================

-- 1) Which routes have the highest average delay (top 10)?
SELECT r.route_id, s1.station_name AS source, s2.station_name AS destination,
       ROUND(AVG(d.delay_minutes),0) AS avg_delay
FROM routes r
JOIN delays d ON r.route_id = d.route_id
JOIN stations s1 ON r.source_station_id = s1.station_id
JOIN stations s2 ON r.dest_station_id = s2.station_id
GROUP BY r.route_id, s1.station_name, s2.station_name
ORDER BY avg_delay DESC
LIMIT 10;

-- 2) How does average delay change across the seasons?
SELECT season, ROUND(AVG(delay_minutes),0) AS avg_delay
FROM delays
GROUP BY season
ORDER BY avg_delay DESC;

-- 3) Find which stations are the "bottleneck" stations?
SELECT s.station_name, ROUND(AVG(delay_minutes),0) AS avg_delay
FROM stations s
JOIN delays d ON s.station_id = d.station_id
GROUP BY s.station_name
ORDER BY avg_delay DESC;

-- 4) Find average delay grouped by state
SELECT s.state, ROUND(AVG(delay_minutes),0) AS avg_delay
FROM stations s
JOIN delays d ON s.station_id = d.station_id
GROUP BY s.state
ORDER BY avg_delay DESC;

-- 5) Which Train Type Delays Most?
SELECT t.train_type, ROUND(AVG(d.delay_minutes),0) AS avg_delay
FROM trains t
JOIN delays d ON t.train_id = d.train_id
GROUP BY t.train_type
ORDER BY avg_delay DESC;

-- 6) Out of all the trips in that zone, what percent were on time? (on-time = delay <= 10 min)
SELECT s.zone,
       ROUND(AVG(CASE WHEN delay_minutes <= 10 THEN 1 ELSE 0 END) * 100, 1) AS pct_on_time
FROM stations s
JOIN delays d ON s.station_id = d.station_id
GROUP BY s.zone
ORDER BY pct_on_time DESC;

-- 7) What % of trips through Central Railway are Passenger-type trains?
SELECT ROUND(AVG(CASE WHEN t.train_type = 'Passenger' THEN 1 ELSE 0 END) * 100,1) AS pct_trip
FROM trains t
JOIN delays d ON t.train_id = d.train_id
JOIN stations s ON s.station_id = d.station_id
WHERE s.zone = 'Central Railway';

-- 8) What are the top 10 Most Punctual Trains?
SELECT t.train_name, t.train_number, t.train_type, ROUND(AVG(d.delay_minutes),0) AS avg_delay
FROM trains t
JOIN delays d ON t.train_id = d.train_id
GROUP BY t.train_name, t.train_number, t.train_type
ORDER BY avg_delay
LIMIT 10;

-- 9) Does weather actually affect train delays?
SELECT w.condition, ROUND(AVG(d.delay_minutes),0) AS avg_delay
FROM weather w
JOIN delays d ON w.weather_id = d.weather_id
GROUP BY w.condition
ORDER BY avg_delay DESC;

-- 10) Which stations get hit worst specifically by bad weather (Storm or Rain)?
SELECT s.station_name, ROUND(AVG(d.delay_minutes),0) AS avg_delay
FROM stations s
JOIN delays d ON s.station_id = d.station_id
JOIN weather w ON w.weather_id = d.weather_id
WHERE w.condition IN ('Storm','Rain')
GROUP BY s.station_name
ORDER BY avg_delay DESC;

-- 11) How does each train's own average delay compare to the overall system-wide average delay?
WITH o_average_delay AS (
    SELECT t.train_name, ROUND(AVG(d.delay_minutes),0) AS own_avg_delay
    FROM trains t
    JOIN delays d ON t.train_id = d.train_id
    GROUP BY t.train_name
),
ov_avg_delay AS (
    SELECT ROUND(AVG(delay_minutes),0) AS overall_avg_delay
    FROM delays
)
SELECT oad.train_name, oad.own_avg_delay, ovad.overall_avg_delay
FROM o_average_delay oad
CROSS JOIN ov_avg_delay ovad;

-- 12) Which (station, weather condition) combos cause the worst delays? (top 5)
SELECT s.station_name, w.condition, ROUND(AVG(delay_minutes),0) AS avg_delay
FROM stations s
JOIN delays d ON s.station_id = d.station_id
JOIN weather w ON w.weather_id = d.weather_id
GROUP BY s.station_name, w.condition
ORDER BY avg_delay DESC
LIMIT 5;

-- 13) Which season gets hit worst by bad weather (Storm or Fog)?
SELECT d.season, ROUND(AVG(d.delay_minutes),0) AS avg_delay
FROM delays d
JOIN weather w ON d.weather_id = w.weather_id
WHERE w.condition IN ('Storm','Fog')
GROUP BY d.season
ORDER BY avg_delay DESC;


-- 14) Which trains delay more than the average for their own train type?
WITH type_avg_delay AS (
    SELECT t.train_type, ROUND(AVG(d.delay_minutes),0) AS avg_delay
    FROM trains t
    JOIN delays d ON t.train_id = d.train_id
    GROUP BY t.train_type
),
own_avg_delay AS (
    SELECT t.train_name, t.train_type, ROUND(AVG(d.delay_minutes),0) AS delay_avg
    FROM trains t
    JOIN delays d ON t.train_id = d.train_id
    GROUP BY t.train_name, t.train_type
)
SELECT tad.train_type, tad.avg_delay, oad.train_name, oad.delay_avg
FROM type_avg_delay tad
JOIN own_avg_delay oad ON tad.train_type = oad.train_type
WHERE oad.delay_avg > tad.avg_delay;

-- 15) For each zone, what % of trips happened on Clear days vs Rain days?
SELECT s.zone,
       ROUND(AVG(CASE WHEN w.condition = 'Clear' THEN 1 ELSE 0 END) * 100, 1) AS pct_clear,
       ROUND(AVG(CASE WHEN w.condition = 'Rain' THEN 1 ELSE 0 END) * 100, 1) AS pct_rain
FROM stations s
JOIN delays d ON s.station_id = d.station_id
JOIN weather w ON w.weather_id = d.weather_id
GROUP BY s.zone
ORDER BY pct_clear DESC;


