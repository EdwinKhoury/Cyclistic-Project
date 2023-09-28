
--1) Create a table where the 12 tables (each representing one month of the year) are combined into 1 table

DROP TABLE IF exists #TripData
CREATE TABLE #TripData
(
ride_id nvarchar(255),
rideable_type nvarchar(255),
started_at datetime,
ended_at datetime,
start_station_name nvarchar(255),
end_station_name nvarchar(255),
member_casual nvarchar(255)
)

INSERT INTO #TripData
SELECT *
FROM CyclisticProject..July_22
UNION ALL

SELECT*
FROM CyclisticProject..August_22
UNION ALL

SELECT*
FROM CyclisticProject..September_22
UNION ALL

SELECT*
FROM CyclisticProject..October_22
UNION ALL

SELECT*
FROM CyclisticProject..November_22
UNION ALL

SELECT*
FROM CyclisticProject..December_22
UNION ALL

SELECT*
FROM CyclisticProject..January_23
UNION ALL

SELECT*
From CyclisticProject..February_23
UNION ALL

SELECT*
FROM CyclisticProject..March_23
UNION ALL

SELECT*
FROM CyclisticProject..April_23
UNION ALL

SELECT*
FROM CyclisticProject..May_23
UNION ALL

SELECT*
FROM CyclisticProject..June_23

 SELECT top 5 *
FROM #TripData
ORDER BY  started_at

----------------

--2) Substracting the number of non-NULL values from the total count of rows to determine the number of NULL values for each column

SELECT 
	COUNT(*) - COUNT(ride_id) AS ride_id,
	COUNT(*) - COUNT(rideable_type) AS rideable_type,
	COUNT(*) - COUNT(started_at) AS started_at,
	COUNT(*) - COUNT(ended_at) AS ended_at,
	COUNT(*) - COUNT(start_station_name) AS start_station_name,
	COUNT(*) - COUNT(end_station_name) AS end_station_name,
	COUNT(*) - COUNT(member_casual) AS member_casual
FROM #TripData
--There are NULL values in the start station name column and the end station name column.

----------------

--3) Substracting the number of distinct ride IDs from the total number of ride IDs to determine the number of duplicates 

SELECT COUNT(ride_id) - COUNT(DISTINCT ride_id) AS duplicate_rows
FROM #TripData
--There are 7 duplicate rows in the dataset.

----------------

--4) Check the type of bikes that are available and how many rides there are per type

SELECT DISTINCT rideable_type, COUNT(rideable_type) AS num_of_rides
FROM #TripData
GROUP BY rideable_type
ORDER BY num_of_rides
--The electric bikes are the most used with a total of 3,142,589 followed by the classic bikes with a total of 2,495,320.

----------------

--5) Divide the datetime column into date and time, and add the new columns in the original table

SELECT 
    CAST(Started_at AS date) AS Start_date,
    CAST(Started_at AS time) AS Start_time,
	CAST(Ended_at AS date) AS End_date,
    CAST(Ended_at AS time) AS End_time
FROM #TripData

ALTER TABLE  #TripData                       --add start date
ADD Start_date date

UPDATE #TripData
SET Start_date = CAST(Started_at AS date)


ALTER TABLE #TripData                       --add start time
ADD Start_time time

UPDATE #TripData
SET Start_time = CAST(Started_at AS time)


ALTER TABLE #TripData                      --add end date
ADD End_date date

UPDATE #TripData
SET End_date = CAST(Ended_at AS date)


ALTER TABLE #TripData                      --add end time
ADD End_time time

UPDATE #TripData
SET End_time = CAST(Ended_at AS time)


SELECT *
FROM #TripData
ORDER BY started_at

----------------

--6) Calculate the time difference 

SELECT started_at, ended_at,
CONVERT(varchar(19), DATEADD(second, DATEDIFF(second, started_at, ended_at), '19000101'), 120) AS time_difference
FROM #TripData
ORDER BY started_at

ALTER TABLE #TripData
ADD time_difference time

UPDATE #TripData
SET time_difference = CONVERT(varchar(19), DATEADD(second, DATEDIFF(second, started_at, ended_at), '19000101'), 120)

----------------

--7) Count the rides that are longer than a day 
SELECT COUNT(*) AS ride_greater_than_a_day
FROM #TripData
WHERE DATEDIFF(second, '00:00:00', CAST(time_difference AS time)) > 86400
--There are no rides that are longer than a day.

----------------

--8) Count the rides that are less than a minute
SELECT COUNT(*) AS ride_less_than_a_minute
FROM #TripData
WHERE DATEDIFF(second, '00:00:00', CAST(time_difference AS time)) < 60
--There are 149,266 rides that are shorter than a minute: these rides tend to falsifiy the results since they are 
--not considered as a ride but maybe a bike that was picked up and directly put back to place.

----------------

--9) Data cleaning

DROP TABLE IF exists #TripDataCleaned                                               --Create a new temp table for the cleaned data
CREATE TABLE #TripDataCleaned
(
ride_id nvarchar(255),
rideable_type nvarchar(255),
started_at datetime,
ended_at datetime,
ride_length time,
day_of_week nvarchar(255),
month nvarchar(255),
start_station_name nvarchar(255),
end_station_name nvarchar(255),
member_casual nvarchar(255),
)

INSERT INTO #TripDataCleaned                                                        --Insert in the table all the columns 
SELECT a.ride_id, a.rideable_type, a.started_at, a.ended_at, ride_length,
	 CASE DATEPART(weekday, started_at)                                             
		WHEN 1 THEN 'Sun'
		WHEN 2 THEN 'Mon'
		WHEN 3 THEN 'Tues'
		WHEN 4 THEN 'Wed'
		WHEN 5 THEN 'Thurs'
		WHEN 6 THEN 'Fri'
		WHEN 7 THEN 'Sat'
	END AS day_of_week,
	Case Month(started_at)
		WHEN 1 THEN 'Jan'
		WHEN 2 THEN 'Feb'
		WHEN 3 THEN 'Mar'
		WHEN 4 THEN 'Apr'
		WHEN 5 THEN 'May'
		WHEN 6 THEN 'Jun'
		WHEN 7 THEN 'Jul'
		WHEN 8 THEN 'Aug'
		WHEN 9 THEN 'Sep'
		WHEN 10 THEN 'Oct'
		WHEN 11 THEN 'Nov'
		WHEN 12 THEN 'Dec'
	END AS month,
	 a.start_station_name, a.end_station_name, a.member_casual

FROM #TripData AS a                                                                                  --Join table a and b on the ride IDs 
JOIN (
	SELECT ride_id, CONVERT(varchar(19), 
	DATEADD(second, DATEDIFF(second, started_at, ended_at), '19000101'), 120) AS ride_length         --Create table b with 2 different columns: ride ID and the ride length
	FROM #TripData
	) AS b
ON a.ride_id = b.ride_id
WHERE																					             --Filter out the station names with NULL values 
	start_station_name is not NULL 
	AND end_station_name is not NULL													             --and the rides that are less than a minute
	AND DATEPART(minute,CAST(ride_length AS time)) >1
	

SELECT * 
FROM #TripDataCleaned

----------------

 --10) Evaluate the type of bikes used as well as their respective number of rides depending on the rider

SELECT member_casual, rideable_type, COUNT(*) AS total_trips
FROM #TripDataCleaned
GROUP BY member_casual, rideable_type
ORDER BY total_trips 
--Casual riders have less trips (1,620,486) than member riders (2,614,235).
--This indicate that riders that are members go on rides more oftenly than casula riders and that might be because of the lower price for a single ride.

----------------

--11) Calculate the number of trips per month

SELECT month, COUNT(*) AS total_trips
FROM #TripDataCleaned
GROUP BY month 
ORDER BY total_trips
--December is the month with the least number of rides with a total of 129,606
--July is the month with the greatest number of rides with a total of 620,066
--Winter months usualy has less rides than summer months because of the weather.

----------------

--12) Calculate the number of trips per week

SELECT day_of_week, COUNT(*) AS total_trips
FROM #TripDataCleaned
GROUP BY day_of_week
ORDER BY total_trips
--Most of the trips are taken on Saturday with a total number of rides of 671,233
--On Sunday, only 540,437 trips are taken, which is the day with the least number of rides.

----------------

--13) Calculate the number of trips per hour

SELECT DATEPART(hour, started_at) AS hour_of_day, COUNT(*) AS total_trips
FROM #TripDataCleaned
GROUP BY DATEPART(hour, started_at)
ORDER BY total_trips
--Rush hour is at 5 PM.
--The least number of rides happens to be at 4 AM.

----------------

--14) Average ride length per hour

SELECT 
  DATEPART(hour, started_at) AS hour_of_day,
  AVG(
    CAST(DATEPART(hour, ride_length) * 60 AS int) + 
    CAST(DATEPART(minute, ride_length) AS int) + 
    CAST(DATEPART(second, ride_length) / 60 AS decimal(10, 2))
  ) AS average_duration_minutes
FROM #TripDataCleaned
GROUP BY DATEPART(hour, started_at)
ORDER BY average_duration_minutes
--At 2 PM, the rides tend to be the longest with an average ride of 18.6 minutes.
--At 5 AM, the rides tend to be the shortest with an average ride of 11 minutes.
----------------

--15) Average ride length per day

SELECT 
  day_of_week,
  AVG(
    CAST(DATEPART(hour, ride_length) * 60 AS int) + 
    CAST(DATEPART(minute, ride_length) AS int) + 
    CAST(DATEPART(second, ride_length) / 60 AS decimal(10, 2))
  ) AS average_duration_minutes
FROM #TripDataCleaned
GROUP BY day_of_week
ORDER BY average_duration_minutes
--On Saturdays, the rides are the longest with an average ride of 19.6 minutes.
--On Wednesdays, the rides are the shortest with an average ride of 14 minutes.
--It is worth noting that during the weekend, the rides are almost 4 minutes longer on average than weekdays.

----------------

--16) Average ride length per month

SELECT 
  month,
  AVG(
    CAST(DATEPART(hour, ride_length) * 60 AS int) + 
    CAST(DATEPART(minute, ride_length) AS int) + 
    CAST(DATEPART(second, ride_length) / 60 AS decimal(10, 2))
  ) AS average_duration_minutes
FROM #TripDataCleaned
GROUP BY month
ORDER BY average_duration_minutes
--In January, the rides are the shortest with an average of 10.9 minutes per ride.
--In July, the rides are the longest with an average of 19 minutes per ride.
--Summer rides are on average 8 minutes longer than those in winter. 

----------------

--17) Most busy starting station

SELECT start_station_name, COUNT (*) AS num_of_rides
FROM #TripDataCleaned
GROUP BY start_station_name
ORDER BY num_of_rides DESC
--Streeter Dr & Grand Ave is the station where most of the rides starts with 63,371 bikes undocked in total.
--Since it is the busiest, the company might consider adding more bikes to satisfy the demand.

----------------

--18) Most busy ending station

SELECT end_station_name, COUNT (*) AS num_of_rides
FROM #TripDataCleaned
GROUP BY end_station_name
ORDER BY num_of_rides DESC
--Streeter Dr & Grand Ave is also the station where most of the rides ends with 64,958 bikes docked in total.
--The  number of docked bikes is greater than the number of undocked bikes. 
--The company might consider adding docking station to accomodate for the high number of docking bikes.

----------------

--19) Most used trajectory: what is the pair of stations that is the most used 

SELECT  top 10 start_station_name , end_station_name , COUNT(*) AS num_of_rides
FROM #TripDataCleaned
GROUP BY start_station_name, end_station_name
ORDER BY num_of_rides DESC
--The most used trajectory by the riders is Streeter Dr & Grand Ave - Streeter Dr & Grand Ave with a total number of 9052 rides in total.
--This is clearly the busiest station for the company

