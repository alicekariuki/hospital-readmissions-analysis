/* =====================================================================
   Readmission driver analysis (SQL Server / T-SQL)
   Run after 01_readmission_logic.sql
   ===================================================================== */

/* 1. Overall rate */
SELECT COUNT(*) AS index_stays,
       SUM(readmit_30) AS readmissions,
       ROUND(100.0 * SUM(readmit_30) / COUNT(*), 1) AS readmit_rate_pct
FROM vw_readmissions;

/* 2. By condition group (minimum volume 50) */
SELECT condition_group,
       COUNT(*) AS index_stays,
       ROUND(100.0 * SUM(readmit_30) / COUNT(*), 1) AS readmit_rate_pct
FROM vw_readmissions
GROUP BY condition_group
HAVING COUNT(*) >= 50
ORDER BY readmit_rate_pct DESC;

/* 3. By discharge disposition */
SELECT discharge_disposition,
       COUNT(*) AS index_stays,
       ROUND(100.0 * SUM(readmit_30) / COUNT(*), 1) AS readmit_rate_pct
FROM vw_readmissions
GROUP BY discharge_disposition
ORDER BY readmit_rate_pct DESC;

/* 4. PCP follow-up within 7 days */
SELECT pcp_visit_within_7_days,
       COUNT(*) AS index_stays,
       ROUND(100.0 * SUM(readmit_30) / COUNT(*), 1) AS readmit_rate_pct
FROM vw_readmissions
GROUP BY pcp_visit_within_7_days;

/* 5. Prior admissions in the last 12 months */
SELECT prior_admits_band,
       COUNT(*) AS index_stays,
       ROUND(100.0 * SUM(readmit_30) / COUNT(*), 1) AS readmit_rate_pct
FROM vw_readmissions
GROUP BY prior_admits_band
ORDER BY prior_admits_band;

/* 6. By payer */
SELECT payer,
       COUNT(*) AS index_stays,
       ROUND(100.0 * SUM(readmit_30) / COUNT(*), 1) AS readmit_rate_pct
FROM vw_readmissions
GROUP BY payer
ORDER BY readmit_rate_pct DESC;

/* 7. By hospital */
SELECT hospital_name,
       COUNT(*) AS index_stays,
       ROUND(100.0 * SUM(readmit_30) / COUNT(*), 1) AS readmit_rate_pct
FROM vw_readmissions
GROUP BY hospital_name
ORDER BY readmit_rate_pct DESC;

/* 8. Timing: how soon after discharge do readmissions happen? */
SELECT CASE WHEN days_to_readmit <= 7  THEN '1) 1-7 days'
            WHEN days_to_readmit <= 14 THEN '2) 8-14 days'
            ELSE '3) 15-30 days' END AS readmit_window,
       COUNT(*) AS readmissions,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_readmissions
FROM vw_readmissions
WHERE readmit_30 = 1
GROUP BY CASE WHEN days_to_readmit <= 7  THEN '1) 1-7 days'
              WHEN days_to_readmit <= 14 THEN '2) 8-14 days'
              ELSE '3) 15-30 days' END
ORDER BY readmit_window;
