/* =====================================================================
   30-Day All-Cause Readmissions (SQL Server / T-SQL), simplified
   Tables: patients, encounters  (see /data)

   Index admission (denominator)
     - Inpatient discharge between Jan 1 and Dec 1 (so 30 days can be observed)
     - Discharged alive, not to hospice, not against medical advice,
       not transferred to another acute facility
   Readmission (numerator)
     - Any unplanned (Emergency) admission 1-30 days after the index discharge
     - Planned (Elective) readmissions do not count
   Each admission can serve as both a readmission and a new index stay.
   ===================================================================== */

CREATE VIEW vw_readmissions AS
WITH idx AS (
    SELECT
        e.encounter_id,
        e.patient_id,
        e.hospital_name,
        e.condition_group,
        e.admission_type,
        e.discharge_disposition,
        e.pcp_visit_within_7_days,
        e.admit_date,
        e.discharge_date,
        DATEDIFF(DAY, e.admit_date, e.discharge_date) AS length_of_stay,
        p.age,
        p.payer,
        p.comorbidity_count,
        /* prior admissions in the 12 months before this one */
        (SELECT COUNT(*)
         FROM encounters AS pr
         WHERE pr.patient_id = e.patient_id
           AND pr.admit_date <  e.admit_date
           AND pr.admit_date >= DATEADD(MONTH, -12, e.admit_date)) AS prior_admits_12mo
    FROM encounters AS e
    JOIN patients AS p
        ON p.patient_id = e.patient_id
    WHERE e.discharge_date BETWEEN '2025-01-01' AND '2025-12-01'
      AND e.discharge_disposition NOT IN ('Expired', 'Hospice',
                                          'Left against medical advice',
                                          'Transfer to acute facility')
),
readmit AS (
    SELECT
        i.encounter_id,
        MIN(r.admit_date) AS readmit_date
    FROM idx AS i
    JOIN encounters AS r
        ON  r.patient_id     = i.patient_id
        AND r.encounter_id  <> i.encounter_id
        AND r.admission_type = 'Emergency'
        AND r.admit_date     >  i.discharge_date
        AND r.admit_date    <= DATEADD(DAY, 30, i.discharge_date)
    GROUP BY i.encounter_id
)
SELECT
    i.*,
    CASE WHEN i.age >= 75 THEN '75+'
         WHEN i.age >= 65 THEN '65-74'
         WHEN i.age >= 45 THEN '45-64'
         ELSE '18-44' END                                  AS age_group,
    CASE WHEN i.prior_admits_12mo >= 2 THEN '2+'
         ELSE CAST(i.prior_admits_12mo AS VARCHAR(2)) END  AS prior_admits_band,
    r.readmit_date,
    DATEDIFF(DAY, i.discharge_date, r.readmit_date)       AS days_to_readmit,
    CASE WHEN r.readmit_date IS NOT NULL THEN 1 ELSE 0 END AS readmit_30
FROM idx AS i
LEFT JOIN readmit AS r
    ON r.encounter_id = i.encounter_id;
