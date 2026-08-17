# Indian Railways Delay Analytics

An end-to-end data analysis project exploring train delay patterns across the Indian Railways network — from database design and data cleaning in PostgreSQL, to business analysis in SQL, to an interactive dashboard in Excel.

## Project Overview

This project analyzes a dataset of Indian Railways train delays across 30 stations, 30 trains, and 45 routes, covering nearly 2,000 individual trip records with weather conditions attached. The goal was to identify delay patterns by season, weather, train type, station, and zone — and present the findings in a clean, interactive dashboard.

## Tech Stack

- **PostgreSQL** — database design, data cleaning, SQL analysis
- **pgAdmin** — query execution and data export
- **Microsoft Excel** — Pivot Tables, charts, interactive dashboard with slicers

## What's in this repo

| File | Description |
|---|---|
| `queries.sql` | Full schema, data cleaning steps, and 15 business-question SQL queries |
| `railway_data_with_pt.xlsx` | Excel workbook with raw data and 5 Pivot Tables |
| `dashboard.pdf` | Final dashboard export — 5 charts summarizing key findings |

## Database Design

5 relational tables with foreign key relationships:
- `stations` — station code, name, state, zone
- `trains` — train number, name, type
- `routes` — source/destination stations per train
- `weather` — daily weather condition per station
- `delays` — fact table linking trains, routes, stations, and weather to actual delay records

## Data Cleaning

- Standardized inconsistent `season` value casing (e.g., "SUMMER", "summer", "Summer" → "Summer")
- Filled missing `delay_minutes` values by calculating the difference between scheduled and actual time
- Identified and removed duplicate trip records

## Business Questions Answered (15 total)

Includes joins, aggregations, `CASE WHEN` pivots, subqueries, and CTEs covering:
- Highest average delay by route, station, state, and zone
- Delay trends by season, weather condition, and month
- Train-type performance comparison
- On-time percentage by zone
- Trains that underperform relative to their own train type's average (CTE-based)
- Each train's delay compared to the system-wide average (CTE + CROSS JOIN)

## Key Findings

- **Vijayawada Junction (BZA)** is the top bottleneck station, with an average delay of ~54 minutes
- **Monsoon season** sees the highest average delays (~48 min), with **August** as the peak month (~52 min)
- **Passenger trains** delay the most among all train types (~52 min avg), while **Rajdhani/Shatabdi** trains are the most punctual (~32 min avg)
- **South Central Railway** is the worst-performing zone (~52 min avg delay)
- **Storm conditions** cause the highest weather-related delays, notably at Vijayawada Junction (~100 min avg)

## Dashboard

The final dashboard (`dashboard.pdf`) includes 5 charts — Average Delay by Season, Train Type, Station, Zone, and Month — along with an interactive zone slicer, built in Excel using Pivot Tables and PivotCharts.

---

*Note: this dataset is synthetic and built for practice/portfolio purposes. Station and train names are based on real Indian Railways entities, but delay figures are not derived from official records.*
