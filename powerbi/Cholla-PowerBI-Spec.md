# Cholla Behavioral Health — Power BI Data Model Specification

> **Project:** Cholla IOP Operations Hub
> **Data Source:** SharePoint Online Lists
> **Site URL:** `https://chollabehavioralhealth.sharepoint.com/sites/iop-hub-dev`
> **Prepared by:** Manage AI — March 2026

---

## 1. Data Sources

Connection method: **SharePoint Online List** connector in Power BI Desktop.

| # | SharePoint List | Power BI Table Name | Key Columns |
|---|----------------|--------------------|----|
| 1 | Census Tracker | CensusTracker | Title, ActiveCensus, Capacity, NewAdmits, Discharges, ALOS, Status |
| 2 | Incident Reports | IncidentReports | IncidentID, IncidentDate, Category, Severity, Status |
| 3 | Staff Credential Tracker | StaffCredentialTracker | StaffName, Role, LicenseExpiration, CPRExpiration, Status |
| 4 | Corrective Action Plans | CorrectiveActionPlans | CAPID, Category, Source, OpenDate, DueDate, Status |
| 5 | Referral Partner Tracker | ReferralPartnerTracker | PartnerName, PartnerType, Territory, ReferralsMTD, AdmitsMTD, Status |
| 6 | Marketing Campaigns | MarketingCampaigns | CampaignName, Channel, SpendMTD, Leads, CPL, Admits, CPA, Status |
| 7 | Admissions Pipeline | AdmissionsPipeline | ReferralID, ReferralDate, Source, Insurance, Stage, Status, AdmitDate |
| 8 | Insurance Verification Tracker | InsuranceVerification | ReferralID, Insurance, AHCCCSEligible, PriorAuthStatus, Status |
| 9 | Revenue Tracker | RevenueTracker | Month, Payer, Revenue, ClaimCount, DenialCount, CleanClaimPct |
| 10 | Compliance Audit Calendar | ComplianceAuditCalendar | Title, AuditDate, AuditType, Status |
| 11 | Group Schedule | GroupSchedule | GroupName, DayOfWeek, GroupType, Facilitator |
| 12 | Client Outcomes Tracker | ClientOutcomesTracker | ClientID, AdmitDate, DischargeDate, PHQ9Intake, PHQ9Discharge, GAD7Intake, GAD7Discharge, CompletionStatus |
| 13 | Billing Denials | BillingDenials | ClaimID, Payer, DenialDate, DenialReason, Amount, AppealStatus |
| 14 | Employee Training Log | EmployeeTrainingLog | StaffName, TrainingName, CompletedDate, DueDate, Status |
| 15 | Group Attendance Log | Group Attendance Log | Date, GroupName, Facilitator, Attendees |
| 16 | Treatment Plan Review Dates | Treatment Plan Review Dates | ClientID, Therapist, LastReviewDate, NextReviewDue, Status |
| 17 | UDS Tracking Log | UDS Tracking Log | ClientID, TestDate, Result, SubstanceDetected |
| 18 | Payroll Tracker | Payroll Tracker | PayPeriod, StaffName, Role, RegularHours, OTHours, GrossPay, Status |
| 19 | Open Positions | Open Positions | PositionTitle, Department, PostedDate, Applications, Status |

### Connection Steps

1. Open Power BI Desktop
2. Get Data → SharePoint Online List
3. Enter site URL: `https://chollabehavioralhealth.sharepoint.com/sites/iop-hub-dev`
4. Authenticate with organizational account (breinhart@chollabehavioralhealth.com)
5. Select all 19 lists above
6. For each list, remove internal SharePoint columns (ContentType, Path, etc.) in Power Query
7. Rename tables to the Power BI Table Names above

---

## 2. Calculated Tables

### DateTable

```dax
DateTable =
ADDCOLUMNS(
    CALENDAR(DATE(2025,1,1), DATE(2026,12,31)),
    "Year", YEAR([Date]),
    "Month", MONTH([Date]),
    "MonthName", FORMAT([Date], "MMMM"),
    "MonthShort", FORMAT([Date], "MMM"),
    "MonthYear", FORMAT([Date], "MMM YYYY"),
    "Quarter", "Q" & CEILING(MONTH([Date])/3, 1),
    "QuarterYear", "Q" & CEILING(MONTH([Date])/3, 1) & " " & YEAR([Date]),
    "WeekNum", WEEKNUM([Date]),
    "DayOfWeek", WEEKDAY([Date]),
    "DayName", FORMAT([Date], "dddd"),
    "IsCurrentMonth", IF(MONTH([Date]) = MONTH(TODAY()) && YEAR([Date]) = YEAR(TODAY()), TRUE, FALSE),
    "IsCurrentQuarter", IF(CEILING(MONTH([Date])/3,1) = CEILING(MONTH(TODAY())/3,1) && YEAR([Date]) = YEAR(TODAY()), TRUE, FALSE),
    "IsPreviousMonth", IF(MONTH([Date]) = MONTH(EDATE(TODAY(),-1)) && YEAR([Date]) = YEAR(EDATE(TODAY(),-1)), TRUE, FALSE),
    "MonthSort", YEAR([Date]) * 100 + MONTH([Date])
)
```

Mark as Date table with `[Date]` column.

---

## 3. Relationships

| From Table | From Column | To Table | To Column | Cardinality | Direction |
|-----------|------------|---------|----------|------------|-----------|
| DateTable | Date | RevenueTracker | Month | 1:M | Single |
| DateTable | Date | AdmissionsPipeline | ReferralDate | 1:M | Single |
| DateTable | Date | IncidentReports | IncidentDate | 1:M | Single |
| DateTable | Date | ComplianceAuditCalendar | AuditDate | 1:M | Single |
| DateTable | Date | BillingDenials | DenialDate | 1:M | Single |
| DateTable | Date | ClientOutcomesTracker | AdmitDate | 1:M | Single |
| AdmissionsPipeline | ReferralID | InsuranceVerification | ReferralID | 1:1 | Both |

**Notes:**
- Most lists use DateTable relationships for time intelligence
- AdmissionsPipeline ↔ InsuranceVerification links via ReferralID
- StaffCredentialTracker and EmployeeTrainingLog can be linked via StaffName (text match) if needed
- ReferralPartnerTracker is standalone — summarized data, not transactional

---

## 4. DAX Measures

All measures are defined in `Cholla-DAX-Measures.dax`. Key categories:

### 4.1 Census
| Measure | Formula |
|---------|---------|
| Active Census | `SUM(CensusTracker[ActiveCensus])` |
| Slot Capacity | `60` |
| Utilization Rate | `DIVIDE([Active Census], [Slot Capacity], 0)` |

### 4.2 Revenue
| Measure | Formula |
|---------|---------|
| Revenue MTD | Filtered by `DateTable[IsCurrentMonth]` |
| Revenue Target | `250000` |
| Revenue Pacing | `DIVIDE([Revenue MTD], [Revenue Target], 0)` |
| Clean Claim Rate | `(Claims - Denials) / Claims` |

### 4.3 Admissions
| Measure | Formula |
|---------|---------|
| Referrals MTD | Count of pipeline rows this month |
| Admits MTD | Filtered by Status = "Admitted" |
| Conversion Rate | `Admits / Referrals` |
| Avg Time to Admit | `DATEDIFF(ReferralDate, AdmitDate, DAY)` |

### 4.4 Compliance
| Measure | Formula |
|---------|---------|
| Compliance Score | `94` (from last audit) |
| Open CAPs | Count where Status IN {"Open","In Progress"} |
| Overdue Audits | Count where Status = "Overdue" |

### 4.5 Staff / HR
| Measure | Formula |
|---------|---------|
| Total Staff | `COUNTROWS(StaffCredentialTracker)` |
| Credential Compliance Rate | Current / Total |
| Credentials Expiring 30d | License within 30 days |

### 4.6 Clinical
| Measure | Formula |
|---------|---------|
| Note Completion Rate | `0.91` (static — future: connect to EHR) |
| Discharge Success Rate | Successful Completion / Total |
| Avg PHQ-9 Improvement | `AVERAGEX(Intake - Discharge)` |

### 4.7 Marketing
| Measure | Formula |
|---------|---------|
| Total Marketing Spend | `SUM(SpendMTD)` |
| Blended CPL | `Spend / Leads` |
| Blended CPA | `Spend / Admits` |

### 4.8 Billing Denials
| Measure | Formula |
|---------|---------|
| Total Denials Amount | `SUM(Amount)` |
| Appeal Win Rate | `Won / (Won + Lost)` |
| Amount at Risk | Sum where AppealStatus = "Appeal Filed" |

---

## 5. Report Pages

### 5.1 Executive Overview
| Visual | Type | Data |
|--------|------|------|
| Census KPI | Card | Active Census = 47 |
| Utilization KPI | Card/Gauge | 78% of 60 |
| Revenue MTD KPI | Card | $218K of $250K target |
| Compliance Score KPI | Card | 94% |
| Revenue by Payer | Stacked Bar | RevenueTracker grouped by Payer |
| Referral Source Donut | Donut | AdmissionsPipeline grouped by Source |
| Discharge Outcomes | Donut/Gauge | ClientOutcomesTracker by CompletionStatus |
| Open Incidents | Table | IncidentReports filtered Status <> Closed |

### 5.2 Clinical
| Visual | Type | Data |
|--------|------|------|
| Caseload KPI | Card | Active Census |
| Note Completion % | Gauge | 91% target 90% |
| PHQ-9 Improvement Trend | Line | ClientOutcomesTracker over time |
| Group Attendance Heatmap | Matrix | GroupAttendanceLog by Group × Week |
| Treatment Plan Compliance | Gauge | 88% target 95% |
| Tx Plan Review Status | Table | TreatmentPlanReviewDates sorted by Status |
| UDS Results | Donut | UDSTrackingLog by Result |

### 5.3 Admissions
| Visual | Type | Data |
|--------|------|------|
| Pipeline Funnel | Funnel | AdmissionsPipeline by Stage |
| Referrals by Source | Bar | AdmissionsPipeline grouped by Source |
| Conversion Rate KPI | Card | Admits / Referrals |
| Insurance Mix | Donut | AdmissionsPipeline by Insurance |
| Time-to-Admit | Card | Average days referral → admit |
| VOB Status | Stacked Bar | InsuranceVerification by Status |

### 5.4 Financial
| Visual | Type | Data |
|--------|------|------|
| Revenue MTD vs Target | Gauge | $218K / $250K |
| Revenue by Payer | Stacked Bar | RevenueTracker by Payer |
| Clean Claim Rate | Gauge | 96% target 95% |
| Denial Trend | Line | BillingDenials by DenialDate |
| Denial by Reason | Bar | BillingDenials by DenialReason |
| Appeal Status | Donut | BillingDenials by AppealStatus |

### 5.5 Compliance
| Visual | Type | Data |
|--------|------|------|
| Compliance Score | Card | 94% |
| Open CAPs | Card | Count |
| Audit Timeline | Gantt/Timeline | ComplianceAuditCalendar |
| Training Compliance Matrix | Matrix | EmployeeTrainingLog by Staff × Training |
| Credential Expiration Heatmap | Matrix | StaffCredentialTracker dates color-coded |

### 5.6 HR / Workforce
| Visual | Type | Data |
|--------|------|------|
| Headcount | Card | 22 |
| Turnover Rate | Card | 12% |
| Open Positions | Table | OpenPositions |
| License Expiration Timeline | Timeline | StaffCredentialTracker by LicenseExpiration |
| Training Compliance by Type | Stacked Bar | EmployeeTrainingLog by TrainingName and Status |
| Payroll Summary | Card | Total Gross Pay |

### 5.7 Referral Network
| Visual | Type | Data |
|--------|------|------|
| Referrals by Partner | Bar | ReferralPartnerTracker by PartnerName |
| Conversion by Partner | Bar | AdmitsMTD / ReferralsMTD |
| Territory Coverage | Map/Table | ReferralPartnerTracker by Territory |
| Partner Activity Timeline | Timeline | BD Visit Log by VisitDate |
| Partner Status | Donut | ReferralPartnerTracker by Status |

### 5.8 Marketing
| Visual | Type | Data |
|--------|------|------|
| Spend by Channel | Bar | MarketingCampaigns by Channel |
| CPL Comparison | Bar | MarketingCampaigns CPL by Channel |
| Leads Trend | Line | MarketingCampaigns over time |
| CPA by Channel | Bar | MarketingCampaigns CPA by Channel |
| Campaign Status | Table | MarketingCampaigns all columns |

---

## 6. Theme

Apply `Cholla-Theme-PowerBI.json` from the `theme/` directory.

Primary palette: `#1a7a7a`, `#0d5f5f`, `#3aa8a8`, `#107c10`, `#d83b01`, `#52a8a8`, `#986f0b`, `#605e5c`

---

## 7. Refresh Schedule

- **Recommended:** Daily refresh at 6:00 AM Arizona time (UTC-7, no DST)
- **Connection:** SharePoint Online List connector with organizational credentials
- **Gateway:** Not required for SharePoint Online — cloud-to-cloud
- **Publish to:** Power BI Service workspace for Cholla Behavioral Health

---

## 8. Security

- Row-Level Security (RLS) not required for initial deployment (single facility)
- Future: If multi-site, add RLS by facility/site
- Workspace access: Limit to Director, Clinical Director, Admin team
- Embed: Use "Publish to Web" or Power BI Embedded for SharePoint pages

---

*Generated by Manage AI for Cholla Behavioral Health IOP Operations Hub*
