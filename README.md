# Hospital Readmissions Analysis

**Which patients come back to the hospital within 30 days, and what can a care transitions team do about it?**

![SQL](https://img.shields.io/badge/SQL_Server-T--SQL-CC2927?logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-dashboard-F2C811?logo=powerbi&logoColor=black)
![Data](https://img.shields.io/badge/data-100%25_synthetic-lightgrey)

> 📸 *Add a dashboard screenshot here:* `![Dashboard](images/readmissions_dashboard.png)`

---

## Business problem

Unplanned readmissions are costly, often preventable, and penalized under the CMS Hospital Readmissions Reduction Program. A three-hospital system wants to know where readmission risk is concentrated so it can focus its care transitions resources.

## Key findings (synthetic data, 2025 discharges)

| Metric | Result |
|---|---|
| Index stays | **4,982** |
| Unplanned 30-day readmissions | **689** |
| 30-day readmission rate | **13.8%** |

- **A PCP visit within 7 days is linked to a lower rate:** 10.9% with a visit vs. 16.1% without, a 5-point gap.
- **Prior utilization is the strongest signal.** Patients with 2+ admissions in the prior 12 months readmit at **21.5%**, nearly double the rate for patients with none (11.0%).
- **Cardiopulmonary conditions lead:** AMI (17.1%), heart failure (16.9%), COPD (16.5%), and pneumonia (16.3%). Elective joint replacement is lowest at 3.9%.
- **Discharges to a skilled nursing facility** readmit at 17.1% vs. 12.6% for home/self-care.
- **More than half (56%) of readmissions happen 15–30 days out**, so outreach shouldn't stop after the first week.

**Recommendations**

1. Book a PCP or clinic follow-up within 7 days **before discharge** for every heart failure, COPD, AMI, and pneumonia patient.
2. Flag patients with 2+ prior admissions for a care-transitions nurse call at 48 hours and again at 2–3 weeks.
3. Review SNF handoffs at Westbrook General, which has the highest hospital-level rate (14.9%).

> Associations in this analysis are descriptive. A next step would be a risk-adjusted model, such as logistic regression or the LACE index.

## Method

| Component | Rule (simplified) |
|---|---|
| **Index stay** | Inpatient discharge Jan 1 – Dec 1; excludes deaths, hospice, AMA discharges, and transfers to another acute facility |
| **Readmission** | Unplanned (emergency) admission to any of the three hospitals 1–30 days after the index discharge |
| **Planned readmissions** | Elective admissions don't count as readmissions |
| **Chaining** | A readmission can also be its own index stay |

> This is a simplified version for portfolio purposes. It is not the CMS HRRP methodology, which is risk-adjusted and condition-specific.

## Repository structure

```
├── data/
│   ├── patients.csv, encounters.csv     ← synthetic source data
│   └── readmissions_output.csv          ← one row per index stay (Power BI fact table)
├── sql/
│   ├── 01_readmission_logic.sql         ← index stays, exclusions, readmission flag (view)
│   └── 02_driver_analysis.sql           ← rates by condition, disposition, payer, timing
└── scripts/
    └── generate_synthetic_data.py       ← rebuilds the dataset (standard library only)
```

## Skills demonstrated

- Readmission logic with self-joins and look-forward date windows
- Correlated subqueries for prior utilization, plus window functions for percent-of-total
- Segmenting rates to find actionable drivers
- Writing recommendations a care management team can act on

## About the data

All data is **synthetic**, and the hospital names are fictional. No real patient information is used.

---

**Alice Kariuki** · Healthcare Data Analyst | PMP | CSM · [LinkedIn](https://www.linkedin.com/in/alice-kariuki-195a843a6)
