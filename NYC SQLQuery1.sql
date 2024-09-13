USE NYC_Collisions;
--Retrieving all Data of Collision
Select * from dbo.NYC_Collisionss;

--Monthly Collision Analysis: Analyzing the number of collisions per month to identify trends in accident frequency.

Select 
      YEAR(Date) as Years,
      MONTH(Date) as Months,
	  COUNT(Collision_ID) as Total_Collisions
From dbo.NYC_Collisionss
Group By YEAR(Date), MONTH(Date)
Order By YEAR(Date), MONTH(Date);

--Collision Hotspots by Borough: Identifying the boroughs with the highest number of collisions.

Select Borough, Count(Collision_ID) as Total_Collisions 
From dbo.NYC_Collisionss
Group By Borough
Order By Total_Collisions desc;

--Impact of Contributing Factors: Analyzing how various contributing factors (like speeding or distracted driving) 
--affect the number of injuries and fatalities.

Select 
       Contributing_Factor,
       COUNT(Collision_ID) as Total_Collisions,
	   SUM(Persons_Injured) as Total_Injuries,
	   Sum(Persons_Killed) as Total_Fatalities
From 
         dbo.NYC_Collisionss
Group By 
         Contributing_Factor
Order By 
         Total_Collisions;

--Pedestrian, Cyclist, and Motorist Safety Analysis: Analyze injuries and fatalities for pedestrians, cyclists, and motorists.

Select 
     Borough,
	 SUM(Pedestrians_Injured) as Pedestrians_Injured,
	 SUM(Pedestrians_Killed) as Pedestrians_Killed,
	 SUM(Cyclists_Injured) as Cyclists_Injured,	
	 SUM(Cyclists_Killed) as Cyclists_Killed,
	 SUM(Motorists_Injured)	as Motorists_Injured,
	 SUM(Motorists_Killed) as Motorists_Killed
From 
   dbo.NYC_Collisionss
Group By 
   Borough
Order By
   Pedestrians_Injured DESC, Cyclists_Injured DESC;

Alter table dbo.NYC_Collisionss
Alter Column Cyclists_Injured tinyint;

--Street-level Collision Frequency: Identify the streets with the most collisions.
 Select Top 10 Street_Name,
        COUNT(Collision_ID) as Total_Collisions
From dbo.NYC_Collisionss
Group by Street_Name
Order By Total_Collisions desc;

--Yearly Trend of Fatal Accidents by Borough (Using Window Functions):
-- This query calculates the total number of fatal accidents each year per borough, 
--and then calculates a cumulative running total of fatalities.

With Yearlyfatalities AS(
  Select Borough,
         YEAR(Date) as Year,
		 SUM(Persons_Killed) as Total_Fatalities
From dbo.NYC_Collisionss
Group By 
     Borough, YEAR(Date)
)
Select 
     Borough,
	 Year,
	 Total_Fatalities,
	 SUM(Total_Fatalities) OVER (Partition by Borough Order By Year) as Cumulative_Fatalities
From Yearlyfatalities
Order By Borough, Year ;

--Top Contributing Factors to Injuries Across All Boroughs (Using Aggregations and GROUPING SETS):
--This query shows the top contributing factors to injuries in each borough and provides a total for all boroughs combined

Select 
      COALESCE(Borough, 'All Borough') as Borough,
      Contributing_Factor,
	  SUM(Persons_Injured) as Total_Injuries
From  
      dbo.NYC_Collisionss
Group By 
      GROUPING SETS((Borough, Contributing_Factor),
	  (Contributing_Factor)

)
Order By Total_Injuries Desc;

--Accidents by Hour and Day of the Week (Using Pivot):
--This query calculates the number of collisions by hour and day of the week, and pivots the results to create a matrix.

SELECT [Hour], 
       [Sunday], [Monday], [Tuesday], [Wednesday], [Thursday], [Friday], [Saturday]
FROM (
    SELECT 
        DATEPART(HOUR, Time) AS [Hour], 
        CASE 
            WHEN DATENAME(WEEKDAY, Date) = 'Sunday' THEN 'Sunday'
            WHEN DATENAME(WEEKDAY, Date) = 'Monday' THEN 'Monday'
            WHEN DATENAME(WEEKDAY, Date) = 'Tuesday' THEN 'Tuesday'
            WHEN DATENAME(WEEKDAY, Date) = 'Wednesday' THEN 'Wednesday'
            WHEN DATENAME(WEEKDAY, Date) = 'Thursday' THEN 'Thursday'
            WHEN DATENAME(WEEKDAY, Date) = 'Friday' THEN 'Friday'
            WHEN DATENAME(WEEKDAY, Date) = 'Saturday' THEN 'Saturday'
        END AS DayOfWeek,
        COUNT(Collision_ID) AS Total_Collisions
    FROM dbo.NYC_Collisionss
    GROUP BY DATEPART(HOUR, Time), DATENAME(WEEKDAY, Date)
) AS SourceTable
PIVOT (
    SUM(Total_Collisions) 
    FOR DayOfWeek IN ([Sunday], [Monday], [Tuesday], [Wednesday], [Thursday], [Friday], [Saturday])
) AS PivotTable
ORDER BY 
    [Hour];

--Contribution of Each Vehicle Type to Accidents Involving Injuries (Using Window Functions):
--This query shows the percentage contribution of each vehicle type to accidents that resulted in injuries.

Use NYC_Collisions;

Select Vehicle_Type, 
       Count(Collision_ID) as Total_Collisions,
	   SUM(Persons_Injured) as Total_Injuries,
	   ROUND(Sum(Persons_Injured)*100.0/Sum(Sum(Persons_Injured)) OVER (), 2) as Injury_Percentage
From dbo.NYC_Collisionss
Where Persons_Injured >0
Group By Vehicle_Type
Order By Injury_Percentage DESC;

--Identifying Accident Trends by Borough (Using LAG for Comparative Analysis):
--This query shows the change in the number of accidents in each borough year-over-year.

With AccidentTrends AS(
Select Borough,
       YEAR(Date) as Year,
	   Count(Collision_ID) as Total_Collision
from dbo.NYC_Collisionss
Group By Borough, YEAR(Date)
)
Select Borough,
       Year,
	   Total_Collision,
	   Lag(Total_Collision, 1) Over (Partition By Borough Order By Year) as PreviousYear_Collisions,
	   Total_Collision - Lag(Total_Collision, 1) Over (Partition By Borough Order By Year) as Collision_Change
From AccidentTrends
Order By Borough, Year;






































