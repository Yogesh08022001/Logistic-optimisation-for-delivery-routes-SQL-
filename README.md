# 🚚 Logistics Optimization for Delivery Routes – Flipkart

A SQL-driven analytics project to analyze delivery delays, optimize routes, and enhance shipment efficiency across Flipkart's logistics network (Ekart Logistics).

---

## 📌 Project Overview

Flipkart delivers millions of orders daily across metros, Tier-2, and Tier-3 cities. During peak seasons, delivery delays and route inefficiencies significantly impact customer satisfaction and operational costs.

This project uses SQL to extract insights from logistics data and answer key business questions around:
- Root causes of delivery delays
- Route optimization opportunities
- Warehouse and agent performance

---

## 🗂️ Dataset

Five relational tables were used:

| Table | Description |
|---|---|
| `Orders` | Order-level details: warehouse, route, agent, delivery dates, status, order value |
| `Routes` | Route details: start/end locations, distance, travel time, traffic delay |
| `Warehouses` | Warehouse info: city, processing capacity, average processing time |
| `Delivery_Agents` | Agent performance: speed, on-time delivery %, years of experience |
| `Shipment_Tracking` | Tracking checkpoints: timestamps, delay reasons, delay minutes |

---

## 🛠️ Tools Used

- **MySQL** – All queries written and executed in MySQL Workbench
- **SQL Concepts** – Aggregations, Window Functions, CTEs, Subqueries, JOINs, CASE WHEN, DATE functions

---

## 📋 Tasks Performed

### Task 1: Data Cleaning & Preparation
- Checked for duplicate `Order_ID` records → None found
- Checked for NULL `Traffic_Delay_Min` values → None found
- Converted all date columns to `YYYY-MM-DD` format using `DATE_FORMAT()`
- Flagged records where `Actual_Delivery_Date < Order_Date` → No anomalies found

### Task 2: Delivery Delay Analysis
- Calculated delivery delay in days using `DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)`
- Identified Top 10 most delayed orders/routes
- Used `RANK() OVER (PARTITION BY Warehouse_ID ...)` to rank orders by delay within each warehouse

### Task 3: Route Optimization Insights
- Calculated per-route: average delivery time, average traffic delay, distance-to-time efficiency ratio (`Distance_KM / Average_Travel_Time_Min`)
- Identified 3 routes with worst efficiency ratio: **RT_13, RT_14, RT_03**
- Found all routes with >20% delayed shipments
- Recommended **RT_02, RT_14, RT_15** for priority optimization

### Task 4: Warehouse Performance
- Top 3 warehouses by processing time: **WH_10 (117 min), WH_09 (110 min), WH_01 (101 min)**
- Computed total vs. delayed shipments per warehouse
- Used CTEs to identify bottleneck warehouses (processing time > global average of 79.4 min)
- Ranked warehouses by on-time delivery % — **WH_09 leads at 83.72%**

### Task 5: Delivery Agent Performance
- Ranked agents per route by on-time delivery % using `RANK() OVER (PARTITION BY Route_ID ...)`
- Identified agents with on-time % < 80% for performance review
- Compared average speed: Top 5 agents avg **44.08 KMPH** vs Bottom 5 at **46.14 KMPH**
- Suggested strategies: targeted training, workload rebalancing, real-time navigation tools

### Task 6: Shipment Tracking Analytics
- Retrieved last checkpoint and timestamp per order using `MAX(Checkpoint_Time)` with a self-join
- Most common delay reasons: **Traffic (387), Weather (192), Technical Issue (107)**
- Identified orders with more than 2 delayed checkpoints using `HAVING COUNT(delay_minutes) > 2`

### Task 7: Advanced KPI Reporting
- **Avg Delivery Delay by Region**: Ahmedabad (0.61 days) → Hyderabad (0.38 days)
- **On-Time Delivery %**: RT_03 leads at 85%, RT_13 lowest at 45.45%
- **Avg Traffic Delay per Route**: calculated and ranked using `AVG(Traffic_Delay_Min)`

---

## 📊 Key KPIs

| Metric | Value |
|---|---|
| Average Delivery Time | 4.51 days |
| Average Efficiency Score | 634.35 |
| Average Traffic Delay | 46.85 min |
| Best Warehouse (On-Time %) | WH_09 — 83.72% |
| Worst Route (On-Time %) | RT_13 — 45.45% |
| Top Delay Reason | Traffic (387 occurrences) |

---

## 💡 Key Insights

- Routes **RT_02, RT_14, and RT_15** consistently appear as high-delay, low-efficiency routes needing immediate optimization
- **WH_10, WH_09, and WH_01** have above-average processing times, creating dispatch bottlenecks
- Traffic congestion accounts for the majority of shipment checkpoint delays (56% of all delay events)
- Bottom 5 agents surprisingly have slightly higher average speed than top 5, suggesting speed alone doesn't determine performance — route familiarity and time management matter more
- **Ahmedabad** routes experience the highest average delivery delays regionally

---

## 📁 Repository Structure

```
flipkart-logistics-sql/
│
├── flipkart_project.sql       # All SQL queries (Tasks 1–7)
├── README.md                  # Project documentation
└── presentation/
    └── Logistics_Optimization_Flipkart.pdf   # PPT exported as PDF
```

---

## 🚀 How to Run

1. Create a MySQL database:
   ```sql
   CREATE DATABASE flipkart_project;
   USE flipkart_project;
   ```
2. Import the five dataset tables (Orders, Routes, Warehouses, Delivery_Agents, Shipment_Tracking)
3. Open `flipkart_project.sql` in MySQL Workbench
4. Execute queries task by task

---

## 👤 Author

**Yogesh Kadam** — Logistics Optimization for Delivery Routes (Flipkart)

---

## 📄 License

This project was created as part of an Internshala training program. For educational use only.
