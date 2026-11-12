"""
Generate synthetic hospital discharge data for the 30-day readmissions project.
All data is fictional. Uses only the Python standard library.

Usage:  python scripts/generate_synthetic_data.py [--seed 42] [--patients 8000]
"""
import argparse
import csv
import random
from datetime import date, timedelta
from pathlib import Path

YEAR = 2025
CONDITIONS = [  # (condition group, ICD-10 example, weight, base readmit risk, mean LOS)
    ("Heart failure", "I50.9", 14, 0.20, 5),
    ("COPD", "J44.1", 10, 0.18, 4),
    ("Pneumonia", "J18.9", 13, 0.15, 5),
    ("Acute myocardial infarction", "I21.4", 6, 0.15, 4),
    ("Sepsis", "A41.9", 9, 0.17, 7),
    ("Diabetes with complications", "E11.65", 8, 0.16, 4),
    ("Chronic kidney disease", "N18.4", 6, 0.19, 5),
    ("Elective hip/knee replacement", "Z96.651", 9, 0.0, 3),
    ("Cellulitis", "L03.115", 9, 0.10, 4),
    ("Urinary tract infection", "N39.0", 10, 0.11, 3),
    ("Stroke", "I63.9", 6, 0.13, 6),
]
PAYERS = {"Medicare": (0.45, 0.03), "Medicaid": (0.25, 0.04), "Commercial": (0.25, -0.03),
          "Self-pay": (0.05, 0.02)}
DISPOSITIONS = [  # (disposition, weight, risk adj, counts as index?)
    ("Home/self-care", 55, 0.00, True), ("Home health", 20, 0.02, True),
    ("Skilled nursing facility", 15, 0.04, True), ("Left against medical advice", 3, 0.08, False),
    ("Transfer to acute facility", 3, 0.0, False), ("Expired", 2, 0.0, False),
    ("Hospice", 2, 0.0, False),
]
HOSPITALS = [("H01", "Cedar Valley Medical Center", -0.01), ("H02", "Westbrook General Hospital", 0.03),
             ("H03", "St. Aurelia Community Hospital", 0.0)]


def rand_date(a, b):
    return a + timedelta(days=random.randint(0, (b - a).days))


def main(out: Path, n: int, seed: int):
    random.seed(seed)
    out.mkdir(parents=True, exist_ok=True)
    patients, encounters = [], []
    enc_n = 0
    payer_names = list(PAYERS)
    for i in range(1, n + 1):
        payer = random.choices(payer_names, [PAYERS[p][0] for p in payer_names])[0]
        age = random.randint(65, 95) if payer == "Medicare" else random.randint(18, 64)
        pid = f"PT{i:06d}"
        comorb = min(6, max(0, int(random.gauss(2 + (age - 50) / 25, 1.3))))
        patients.append({"patient_id": pid, "age": age, "sex": random.choice("FM"),
                         "payer": payer, "comorbidity_count": comorb})
        if random.random() > 0.35:
            continue  # most patients have no admission this year
        risk_base = 0.0
        d = rand_date(date(YEAR, 1, 1), date(YEAR, 3, 31))
        prior = 0
        while d < date(YEAR, 12, 31):
            cond, icd, _, crisk, mlos = random.choices(CONDITIONS, [c[2] for c in CONDITIONS])[0]
            hosp_id, hosp_name, hrisk = random.choice(HOSPITALS)
            los = max(1, int(random.gauss(mlos, 2)))
            disch = d + timedelta(days=los)
            disp, _, drisk, _ = random.choices(DISPOSITIONS, [x[1] for x in DISPOSITIONS])[0]
            pcp7 = random.random() < (0.45 if payer != "Self-pay" else 0.2)
            planned = cond == "Elective hip/knee replacement" or random.random() < 0.03
            enc_n += 1
            encounters.append({
                "encounter_id": f"E{enc_n:07d}", "patient_id": pid, "hospital_id": hosp_id,
                "hospital_name": hosp_name, "admit_date": d.isoformat(),
                "discharge_date": disch.isoformat(), "condition_group": cond,
                "principal_dx_code": icd, "admission_type": "Elective" if planned else "Emergency",
                "discharge_disposition": disp, "pcp_visit_within_7_days": "Y" if pcp7 else "N",
            })
            if disp in ("Expired", "Hospice"):
                break
            risk = (crisk - 0.06 + PAYERS[payer][1] + drisk + hrisk + 0.012 * comorb
                    + 0.04 * min(prior, 3) + risk_base - (0.05 if pcp7 else 0))
            risk = min(max(risk, 0.01), 0.75)
            prior += 1
            if random.random() < risk:
                d = disch + timedelta(days=random.randint(2, 30))
            else:
                d = disch + timedelta(days=random.randint(45, 400))
    for name, rows in (("patients.csv", patients), ("encounters.csv", encounters)):
        with open(out / name, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0]))
            w.writeheader()
            w.writerows(rows)
        print(f"  {name:<16} {len(rows):>6,} rows")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(Path(__file__).resolve().parent.parent / "data"))
    ap.add_argument("--patients", type=int, default=8000)
    ap.add_argument("--seed", type=int, default=42)
    a = ap.parse_args()
    main(Path(a.out), a.patients, a.seed)
