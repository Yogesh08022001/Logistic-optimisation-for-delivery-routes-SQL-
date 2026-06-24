-- Created flipcard_project as database and using as current database
CREATE  DATABASE flipkart_project;

-- TASK 1:  Data Cleaning & Preparation
-- 1.1 Identify and delete duplicate Order_ID records. 
SELECT Order_ID, COUNT(*) AS cnt
FROM orders
GROUP BY Order_ID
HAVING COUNT(*) > 1;

-- No duplicate order_id found

-- 1.2  Replace null Traffic_Delay_Min with the average delay for that route.
SELECT *
FROM Routes
WHERE Traffic_Delay_Min IS NULL;
-- no null values found in Traffic_Delay_Min, so no need of replacement

-- 1.3 Convert all date columns into YYYY-MM-DD format using SQL functions.
UPDATE Orders
SET Order_Date = DATE_FORMAT(Order_Date, '%Y-%m-%d'),
    Expected_Delivery_Date = DATE_FORMAT(Expected_Delivery_Date, '%Y-%m-%d'),
    Actual_Delivery_Date = DATE_FORMAT(Actual_Delivery_Date, '%Y-%m-%d');
    
    SELECT Order_Date, Expected_Delivery_Date, Actual_Delivery_Date FROM orders;

--  1.4 Ensure that no Actual_Delivery_Date is before Order_Date (flag such records). 
SELECT Order_ID, Order_Date, Actual_Delivery_Date,
'Delivery before order date' AS Flag
FROM Orders
WHERE Actual_Delivery_Date < Order_Date;

-- TASK 2: Delivery Delay Analysis
-- 2.1 Calculate delivery delay (in days) for each order 
SELECT order_id, order_date, actual_delivery_date, expected_delivery_date, 
DATEDIFF( actual_delivery_date, expected_delivery_date)  AS delay_days FROM orders ;


-- 2.2 Find Top 10 delayed routes based on average delay days. 
SELECT order_id, route_id, 
(DATEDIFF( actual_delivery_date, expected_delivery_date)) AS delay_days FROM orders
WHERE DATEDIFF( actual_delivery_date, expected_delivery_date) !=0 
ORDER BY delay_days DESC LIMIT 10;

-- 2.3 Use window functions to rank all orders by delay within each warehouse.
SELECT
    Order_ID,
    Warehouse_ID,
    Order_Date,
    Expected_Delivery_Date,
    Actual_Delivery_Date,
    DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delivery_Delay_Days,
    RANK() OVER (
        PARTITION BY Warehouse_ID
        ORDER BY DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) DESC
    ) AS Delay_Rank_In_Warehouse
FROM Orders;

-- TASK 3:  Route Optimization Insights 
-- 3.1.1 Average delivery time (in days).
 SELECT Route_id, 
 AVG(DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date))AS avg_delivery_time_days FROM orders
 GROUP BY route_id ORDER BY avg_delivery_time_days DESC;
 
 -- 3.1.2 Average traffic delay.
SELECT 
    Route_id, AVG(Traffic_delay_min) AS avg_traffic_delay_min
FROM
    routes
GROUP BY Route_id
ORDER BY avg_Traffic_delay_min DESC;
 
 --  3.1.3 Distance-to-time efficiency ratio: Distance_KM / Average_Travel_Time_Min.
 SELECT 
    route_id,
    (Distance_KM / Average_Travel_Time_min) AS Distance_to_time_efficency_ratio
FROM
    routes;
 
 -- 3.2 Identify 3 routes with the worst efficiency ratio.
 SELECT route_id, 
 (Distance_km / Average_travel_time_min) AS Efficiency_ratio
 FROM routes
 ORDER BY Efficiency_ratio limit 3;
 
 -- 3.3 Find routes with >20% delayed shipments. 
SELECT 
    Route_ID,
    COUNT(*) AS Total_Orders,
    SUM(
        CASE 
            WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 
            ELSE 0 
        END
    ) AS Delayed_Orders,
    100.0 * SUM(
        CASE 
            WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 
            ELSE 0 
        END
    ) / COUNT(*) AS Delay_Percent
FROM Orders
GROUP BY Route_ID
HAVING 1.0 * SUM(
        CASE 
            WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 
            ELSE 0 
        END
    ) / COUNT(*) > 0.20;   -- > 20% delayed;
    
    -- TASK 3.4
    SELECT * FROM routes;
    
    
    
    
-- TASK 4.1 Find the top 3 warehouses with the highest average processing time
SELECT 
    Warehouse_ID,
    AVG(Average_Processing_Time_Min) AS Avg_Processing_Time
FROM warehouses
GROUP BY Warehouse_ID
ORDER BY Avg_Processing_Time DESC
LIMIT 3;

-- TASK 4.2 Calculate total vs. delayed shipments for each warehouse.
SELECT warehouse_id, COUNT(*), 
SUM( CASE 
     WHEN Expected_Delivery_Date < Actual_Delivery_Date THEN 1 
     ELSE 0
     END ) AS delayed_shipments FROM orders
GROUP BY warehouse_ID
ORDER BY warehouse_id ;

-- TASK 4.3 Use CTEs to find bottleneck warehouses where processing time > global average.
WITH Global_Avg AS (
    SELECT 
        Avg(Average_Processing_Time_Min) AS Global_Processing_Avg
    FROM warehouses
),
Warehouse_Stats AS (
    SELECT
        Warehouse_ID,
        AVG(Average_Processing_Time_Min) AS Avg_Processing_Time
    FROM warehouses
    GROUP BY Warehouse_ID
)
SELECT
    w.Warehouse_ID,
    w.Avg_Processing_Time,
    Global_Avg.Global_Processing_Avg
FROM Warehouse_Stats w, Global_Avg
CROSS JOIN Global_Avg g
WHERE w.Avg_Processing_Time > g.Global_Processing_Avg      -- bottlenecks
ORDER BY w.Avg_Processing_Time DESC;

-- TASK 4.4 Rank warehouses based on on-time delivery percentage.
SELECT
    Warehouse_ID,
    COUNT(*) AS Total_Shipments,
    SUM(
        CASE 
            WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 
            ELSE 0 
        END
    ) AS On_Time_Shipments,
    ROUND(
        100.0 * SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 END)
        / COUNT(*), 2
    ) AS On_Time_Percentage
FROM Orders
GROUP BY Warehouse_ID
ORDER BY On_Time_Percentage DESC;   -- best-performing warehouse first

-- TASK 5  Delivery Agent Performance
-- TASK 5.1 Rank agents (per route) by on-time delivery percentage
SELECT
    Route_ID,
    Agent_ID,
    On_Time_Delivery_Percentage,
    RANK() OVER (
        PARTITION BY Route_ID
        ORDER BY On_Time_Delivery_Percentage DESC
    ) AS Rank_In_Route
FROM delivery_agents
ORDER BY Route_ID, Rank_In_Route;

-- TASK 5.2 Find agents with on-time % < 80%.
SELECT 
    Agent_ID, On_time_Delivery_percentage
FROM
    delivery_agents
WHERE
    On_time_Delivery_percentage < 80;

-- TASK 5.3 Compare average speed of top 5 vs bottom 5 agents using subqueries.
SELECT
    -- Average speed of top 5 agents by on-time %
    (
        SELECT AVG(Avg_Speed_KMPH)
        FROM (
            SELECT Avg_Speed_KMPH
            FROM delivery_agents
            ORDER BY On_Time_Delivery_Percentage DESC
            LIMIT 5
        ) AS Top5
    ) AS Top5_Avg_Speed,
    
    -- Average speed of bottom 5 agents by on-time %
    (
        SELECT AVG(Avg_Speed_KMPH)
        FROM (
            SELECT Avg_Speed_KMPH
            FROM delivery_agents
            ORDER BY On_Time_Delivery_Percentage ASC
            LIMIT 5
        ) AS Bottom5
    ) AS Bottom5_Avg_Speed;
    
    -- TASK 5.4  Suggest training or workload balancing strategies for low performers





-- TASK 6 Shipment Tracking Analytics
-- TASK 6.1 For each order, list the last checkpoint and time
SELECT 
    st.order_id,
    st.Tracking_ID,
    st.checkpoint_time,
    st.checkpoint
FROM
    Shipment_tracking AS st
JOIN
    (
        SELECT 
            order_id,
            MAX(checkpoint_time) AS last_time
        FROM Shipment_tracking
        GROUP BY order_id
    ) AS lastpoint
ON st.order_id = lastpoint.order_id
AND st.checkpoint_time = lastpoint.last_time
ORDER BY st.order_id;

-- TASK 6.2 Find the most common delay reasons (excluding None).
SELECT 
    Delay_Reason, COUNT(Order_id)
FROM
    Shipment_tracking
WHERE
    Delay_Reason NOT IN ('None')
GROUP BY Delay_Reason
ORDER BY COUNT(Order_id) DESC;

-- TASK 6.3 Identify orders with >2 delayed checkpoints
SELECT 
    order_id, COUNT(Delay_Minutes) AS delayed_checkpoint_count
FROM
    Shipment_tracking
WHERE
    delay_minutes > 0
GROUP BY order_id
HAVING COUNT(delay_minutes) > 2;


-- TASK 7 Advanced KPI Reporting
-- TASK 7.1 Average Delivery Delay per Region (Start_Location).
SELECT 
    r.Start_Location,
    AVG(DATEDIFF(o.actual_delivery_date, o.expected_delivery_date)) AS avg_delay_days
FROM Orders AS o
JOIN Routes AS r
    ON o.route_id = r.route_id
WHERE o.actual_delivery_date IS NOT NULL
GROUP BY r.Start_Location
ORDER BY avg_delay_days DESC;

-- TASK 7.2 On-Time Delivery % = (Total On-Time Deliveries / Total Deliveries) * 100
SELECT ROUTE_ID, 
    SUM(CASE 
            WHEN o.actual_delivery_date <= o.expected_delivery_date THEN 1 
            ELSE 0 
        END) / COUNT(*) * 100 AS on_time_delivery_percentage
FROM Orders AS o
GROUP BY ROUTE_ID
ORDER BY on_time_delivery_percentage DESC;

-- TASK 7.3 Average Traffic Delay per Route.
 SELECT Route_id, AVG(Traffic_delay_min) AS avg_traffic_delay_min
 FROM routes GROUP BY Route_id
 ORDER BY avg_Traffic_delay_min DESC;
