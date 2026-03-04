# Cholla Behavioral Health — SharePoint IOP Operations Hub
## Complete Deployment Package for Claude Code

> **Project:** Cholla Behavioral Health IOP Operations Hub
> **Client:** Cholla Behavioral Health — Phoenix/Scottsdale, AZ
> **Prepared by:** Manage AI (brian@manageai.io)
> **Date:** March 2026

---

## HOW TO USE THIS DOCUMENT

This is a Claude Code prompt. Open a terminal, run `claude`, paste or reference this file, and Claude Code will generate three deliverables:

1. **PnP PowerShell provisioning script** — creates the entire SharePoint site, pages, lists, document libraries, navigation, and theming
2. **PnP page templates with web parts pre-placed** — deploys all 8 pages with document library, list, Power BI, and embed web parts already wired up
3. **Power BI data model specification** — table schemas, relationships, DAX measures, and sample data for a connected dashboard

---

## BRANDING

- **Primary color:** `#1a7a7a` (teal)
- **Dark variants:** `#0d5f5f`, `#0a4e4e`
- **Avatar/accent:** `#0e5c5c`
- **App rail:** `#1b1b1b` (dark)
- **Suite bar gradient:** `linear-gradient(135deg, #1a7a7a 0%, #0d5f5f 60%, #0a4e4e 100%)`
- **Background:** `#f5f5f5`
- **Text:** `#323130`
- **Logo:** Cholla Behavioral Health logo (base64 embedded in mockups, also available as `cholla-logo.png` in assets)
- **Organization type:** IOP (Intensive Outpatient Program) behavioral health clinic — single facility, not multi-site residential

---

## PART 1: PnP POWERSHELL PROVISIONING SCRIPT

### Instructions for Claude Code

Generate a single PowerShell script called `Deploy-ChollaHub.ps1` that uses PnP PowerShell (PnP.PowerShell module) to provision the entire SharePoint site. The script should be idempotent (safe to re-run). Include error handling and progress output.

### Prerequisites Block

```
# Required: PnP.PowerShell module
# Install-Module -Name PnP.PowerShell -Scope CurrentUser
# Required: SharePoint Admin or Site Collection Admin permissions
# Required: PowerShell 7+
```

### Connection

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$TenantUrl,       # e.g., "https://cholla.sharepoint.com"
    [Parameter(Mandatory=$true)]
    [string]$SiteAlias,       # e.g., "iop-hub-dev"
    [string]$SiteTitle = "Cholla IOP Operations Hub",
    [switch]$SkipSiteCreation  # if site already exists
)

Connect-PnPOnline -Url $TenantUrl -Interactive
```

### 1.1 Site Creation

- Create a Communication Site (not Team Site — better for dashboards)
- Site name: "Cholla IOP Operations Hub"
- Site alias: parameterized (default `iop-hub-dev` for sandbox)
- Template: `STS#3` (Communication Site)
- Locale: 1033 (English US)
- Time zone: 15 (Arizona — no DST)

### 1.2 Branding / Theming

Apply a custom theme matching Cholla brand:

```json
{
    "name": "Cholla Behavioral Health",
    "isInverted": false,
    "palette": {
        "themePrimary": "#1a7a7a",
        "themeLighterAlt": "#f2f9f9",
        "themeLighter": "#cce8e8",
        "themeLight": "#a3d4d4",
        "themeTertiary": "#52a8a8",
        "themeSecondary": "#1f8585",
        "themeDarkAlt": "#176e6e",
        "themeDark": "#145d5d",
        "themeDarker": "#0e4545",
        "neutralLighterAlt": "#faf9f8",
        "neutralLighter": "#f3f2f1",
        "neutralLight": "#edebe9",
        "neutralQuaternaryAlt": "#e1dfdd",
        "neutralQuaternary": "#d2d0ce",
        "neutralTertiaryAlt": "#c8c6c4",
        "neutralTertiary": "#a19f9d",
        "neutralSecondary": "#605e5c",
        "neutralPrimaryAlt": "#3b3a39",
        "neutralPrimary": "#323130",
        "neutralDark": "#201f1e",
        "black": "#000000",
        "white": "#ffffff",
        "primaryBackground": "#ffffff",
        "primaryText": "#323130",
        "accent": "#1a7a7a"
    }
}
```

Upload the Cholla logo (from `./assets/cholla-logo.png`) as the site logo.

### 1.3 Hub Navigation

Create top navigation with 8 links. The nav labels and target pages:

| Order | Label | Target Page |
|-------|-------|-------------|
| 1 | Home | SitePages/Home.aspx |
| 2 | Director of Operations | SitePages/Director-of-Operations.aspx |
| 3 | Clinical | SitePages/Clinical-Department.aspx |
| 4 | Admissions | SitePages/Admissions-Department.aspx |
| 5 | Marketing | SitePages/Marketing-Department.aspx |
| 6 | Business Development | SitePages/Business-Development.aspx |
| 7 | Human Resources | SitePages/Human-Resources.aspx |
| 8 | Administration | SitePages/Administration.aspx |

### 1.4 Document Libraries

Create these document libraries with folder structures. Each library maps to a department page.

#### Director Documents (Director of Operations page)
```
Director-Documents/
├── Master-SOP-Library/
│   ├── (placeholder: SOP-001 Client Intake Process.docx)
│   ├── (placeholder: SOP-002 Treatment Plan Review.docx)
│   ├── (placeholder: SOP-003 Group Facilitation.docx)
│   ├── (placeholder: SOP-004 Discharge Planning.docx)
│   ├── (placeholder: SOP-005 Crisis Intervention.docx)
│   ├── (placeholder: SOP-006 Incident Reporting.docx)
│   └── (placeholder: SOP-007 Insurance Verification.docx)
├── Licensing-and-Compliance-Binder/
│   ├── (placeholder: AZDHS License – Active.pdf)
│   ├── (placeholder: AHCCCS Provider Agreement.pdf)
│   ├── (placeholder: DEA Registration.pdf)
│   ├── (placeholder: Fire Marshal Inspection – 2025.pdf)
│   ├── (placeholder: Zoning Approval Letter.pdf)
│   └── (placeholder: 9 A.A.C. 10 Compliance Matrix.xlsx)
├── Contracts-Insurance-Referral-Partners/
│   ├── (placeholder: AHCCCS – Mercy Care Contract.pdf)
│   ├── (placeholder: BCBS of Arizona Agreement.pdf)
│   ├── (placeholder: UHC Optum Agreement.pdf)
│   ├── (placeholder: Valley Recovery Network – Referral Agreement.pdf)
│   └── (placeholder: AZ Crisis Center – Partner MOU.pdf)
├── Risk-Management/
│   ├── (placeholder: Risk Assessment Matrix – Q1 2026.xlsx)
│   ├── (placeholder: Professional Liability Policy.pdf)
│   ├── (placeholder: General Liability Certificate.pdf)
│   └── (placeholder: Emergency Preparedness Plan.docx)
├── Board-Ownership-Reports/
│   ├── (placeholder: Board Report – February 2026.pptx)
│   ├── (placeholder: Board Report – January 2026.pptx)
│   ├── (placeholder: Annual Strategic Plan 2026.docx)
│   └── (placeholder: Financial Summary Q4 2025.xlsx)
└── Strategic-Planning/
    ├── (placeholder: 2026 Growth Roadmap.docx)
    ├── (placeholder: Market Analysis – Scottsdale IOP.xlsx)
    ├── (placeholder: Expansion Feasibility Study.docx)
    └── (placeholder: Competitive Landscape Analysis.pptx)
```

#### Clinical Documents
```
Clinical-Documents/
├── Clinical-SOPs/
│   ├── (placeholder: Intake Assessment Protocol.docx)
│   ├── (placeholder: ASAM Criteria Guidelines.docx)
│   ├── (placeholder: Treatment Planning Standards.docx)
│   ├── (placeholder: Discharge Planning Protocol.docx)
│   ├── (placeholder: Crisis Intervention SOP.docx)
│   ├── (placeholder: Documentation Standards AHCCCS.docx)
│   └── (placeholder: Group Curriculum Library)
├── Clinical-Forms/
│   ├── (placeholder: Intake Packet.pdf)
│   ├── (placeholder: Consent for Treatment Forms.pdf)
│   ├── (placeholder: Release of Information ROI.pdf)
│   ├── (placeholder: Safety Plan Template.docx)
│   ├── (placeholder: Incident Report Form.docx)
│   └── (placeholder: Grievance Form.docx)
├── Staff-Credentials/
│   ├── (placeholder: Therapist Licenses)
│   ├── (placeholder: CPR First Aid Cards)
│   ├── (placeholder: Fingerprint Clearance Cards)
│   └── (placeholder: CEU Tracking Log.xlsx)
└── Quality-Assurance/
    ├── (placeholder: Chart Audit Results – Feb 2026.xlsx)
    ├── (placeholder: Peer Review Log – Q1 2026.docx)
    └── (placeholder: Corrective Actions – Clinical.docx)
```

#### Admissions Documents
```
Admissions-Documents/
├── Admissions-SOPs/
│   ├── (placeholder: Pre-Screen Script.docx)
│   ├── (placeholder: Insurance Verification Workflow.docx)
│   ├── (placeholder: Medical Necessity Checklist.docx)
│   ├── (placeholder: Level of Care Determination.docx)
│   ├── (placeholder: Admission Criteria – ASAM 2.1.docx)
│   └── (placeholder: Denial Documentation Protocol.docx)
└── Admissions-Forms/
    ├── (placeholder: Pre-Screen Template.docx)
    ├── (placeholder: Benefits Verification Form.xlsx)
    ├── (placeholder: Admission Checklist.docx)
    └── (placeholder: Denial Documentation Form.docx)
```

#### Marketing Documents
```
Marketing-Documents/
├── Brand-Assets/
│   ├── (placeholder: Cholla Logo Pack.zip)
│   ├── (placeholder: Brand Guidelines v2.pdf)
│   ├── (placeholder: Photography Library)
│   ├── (placeholder: Color Typography Spec.pdf)
│   ├── (placeholder: Email Signature Templates.html)
│   └── (placeholder: Presentation Template.pptx)
├── Marketing-Campaigns/
│   ├── (placeholder: Q1 2026 – IOP Awareness)
│   ├── (placeholder: Q4 2025 – Holiday Recovery)
│   ├── (placeholder: Evergreen – SEO Content)
│   └── (placeholder: Evergreen – Social Templates)
├── Website-Content/
│   ├── (placeholder: Website Copy – Service Pages.docx)
│   ├── (placeholder: Blog Post Library.xlsx)
│   └── (placeholder: SEO Keyword Research.xlsx)
└── Compliance-Review-Log/
    ├── (placeholder: Ad Copy Compliance Review – Feb.docx)
    └── (placeholder: Anti-Inducement Policy Checklist.docx)
```

#### BD Documents
```
BD-Documents/
├── Referral-Partner-Agreements/
│   ├── (placeholder: Valley Recovery Network – Agreement.pdf)
│   ├── (placeholder: AZ Crisis Center – MOU.pdf)
│   ├── (placeholder: Mercy Gilbert – Referral Agreement.pdf)
│   ├── (placeholder: Standard Referral Agreement Template.docx)
│   └── (placeholder: Anti-Kickback Compliance Addendum.docx)
├── Outreach-Scripts-Materials/
│   ├── (placeholder: Cold Outreach Script – Hospitals.docx)
│   ├── (placeholder: Follow-Up Email Templates.docx)
│   ├── (placeholder: Facility Presentation Deck.pptx)
│   └── (placeholder: One-Pager – Cholla IOP Services.pdf)
└── Territory-Mapping/
    ├── (placeholder: Phoenix Metro Territory Map.pdf)
    ├── (placeholder: Partner Density by ZIP.xlsx)
    └── (placeholder: White Space Analysis – Scottsdale.xlsx)
```

#### HR Documents
```
HR-Documents/
├── Employee-Handbook-Policies/
│   ├── (placeholder: Employee Handbook v4.2.pdf)
│   ├── (placeholder: Code of Conduct – BH Specific.pdf)
│   ├── (placeholder: PTO Leave Policy.pdf)
│   ├── (placeholder: Trauma-Informed Workplace Policy.pdf)
│   ├── (placeholder: Dual Relationships Boundary Policy.pdf)
│   ├── (placeholder: Staff Wellness Burnout Prevention Plan.pdf)
│   ├── (placeholder: Drug-Free Workplace Policy.pdf)
│   └── (placeholder: Social Media Confidentiality Policy.pdf)
├── Job-Descriptions-BH-Roles/
│   ├── (placeholder: Licensed Professional Counselor LPC.docx)
│   ├── (placeholder: Licensed Independent Substance Abuse Counselor LISAC.docx)
│   ├── (placeholder: Licensed Clinical Social Worker LCSW.docx)
│   ├── (placeholder: Licensed Associate Counselor LAC Supervised.docx)
│   ├── (placeholder: Behavioral Health Technician BHT.docx)
│   ├── (placeholder: Certified Peer Support Specialist CPSS.docx)
│   ├── (placeholder: Admissions Coordinator.docx)
│   └── (placeholder: Clinical Director.docx)
├── Clinical-Supervision-Records/
│   ├── (placeholder: Supervision Agreement Template ARS 32-3301.docx)
│   ├── (placeholder: Weekly Supervision Log – A Nguyen.xlsx)
│   ├── (placeholder: Supervision Hours Tracker – All LAC BHT.xlsx)
│   └── (placeholder: AZBBHE Supervision Requirements Guide.pdf)
├── Performance-Reviews-Disciplinary/
│   ├── (placeholder: Performance Review Template – Clinical.docx)
│   ├── (placeholder: 90-Day New Hire Evaluation Form.docx)
│   ├── (placeholder: Corrective Action Form.docx)
│   ├── (placeholder: Termination Checklist – BH Specific.docx)
│   └── (placeholder: Exit Interview Template.docx)
└── Staff-Credential-Files/
    ├── (placeholder: Martinez J – LPC License FPC CPR CEUs)
    ├── (placeholder: Thompson S – LISAC License FPC CPR CEUs)
    ├── (placeholder: Davis R – LCSW License FPC CPR CEUs)
    ├── (placeholder: Nguyen A – LAC License FPC Supervision Docs)
    └── (placeholder: Robinson D – CPSS Cert FPC CPR)
```

#### Administration Documents
```
Admin-Documents/
├── Employee-Handbook/
│   ├── (placeholder: Employee Handbook v4.2.pdf)
│   ├── (placeholder: Code of Conduct.pdf)
│   └── (placeholder: PTO Leave Policy.pdf)
├── Job-Descriptions/
│   ├── (placeholder: Licensed Therapist LPC LISAC LCSW.docx)
│   ├── (placeholder: Admissions Coordinator.docx)
│   ├── (placeholder: Clinical Director.docx)
│   ├── (placeholder: Front Office Admin Assistant.docx)
│   ├── (placeholder: BHT Peer Support Specialist.docx)
│   └── (placeholder: Marketing Coordinator.docx)
├── Performance-Reviews/
│   ├── (placeholder: Q4 2025 Review Cycle Summary.xlsx)
│   ├── (placeholder: Performance Review Template.docx)
│   └── (placeholder: 90-Day New Hire Evaluation Form.docx)
├── Disciplinary-Actions/
│   ├── (placeholder: Verbal Warning Template.docx)
│   ├── (placeholder: Written Warning Template.docx)
│   └── (placeholder: Termination Checklist.docx)
├── AHCCCS-Billing-Guides/
│   ├── (placeholder: AHCCCS IOP Billing Manual 2026.pdf)
│   ├── (placeholder: Mercy Care Provider Manual.pdf)
│   ├── (placeholder: UHCCP Billing Guidelines.pdf)
│   └── (placeholder: Banner-UHC Authorization Process.pdf)
├── CPT-Code-References/
│   ├── (placeholder: IOP CPT Code Quick Reference.xlsx)
│   ├── (placeholder: Modifier Cheat Sheet.docx)
│   └── (placeholder: IOP Service Definitions Units.docx)
├── Claim-Submission-SOPs/
│   ├── (placeholder: Claim Submission SOP.docx)
│   ├── (placeholder: Denial Appeal Process.docx)
│   └── (placeholder: Prior Authorization Workflow.docx)
├── HIPAA-Policies/
│   ├── (placeholder: HIPAA Privacy Policy.pdf)
│   ├── (placeholder: HIPAA Security Policy.pdf)
│   ├── (placeholder: Breach Notification Procedure.docx)
│   └── (placeholder: BAA Template.docx)
├── Corporate-Compliance-Plan/
│   ├── (placeholder: Corporate Compliance Plan 2026.pdf)
│   ├── (placeholder: Fraud Waste Abuse Prevention Plan.pdf)
│   └── (placeholder: Compliance Committee Charter.docx)
└── Emergency-Preparedness/
    ├── (placeholder: Emergency Preparedness Plan.pdf)
    ├── (placeholder: Fire Drill Log 2026.xlsx)
    └── (placeholder: Evacuation Routes Map.pdf)
```

For placeholder files: create a tiny .txt file in each location named with the placeholder name so the folder structure is visible. The client will replace with real docs later.

### 1.5 SharePoint Lists

Create these SharePoint lists with typed columns. Claude Code should generate the `Add-PnPList` and `Add-PnPField` commands for each.

#### List: Census Tracker
Used by: Home, Director, Clinical, Admissions pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| Title | Text | Default — used for date stamp or label |
| ActiveCensus | Number | Current IOP client count |
| Capacity | Number | Max slots (60) |
| UtilizationPct | Calculated | =ActiveCensus/Capacity |
| NewAdmits | Number | Admits this week |
| Discharges | Number | Discharges this week |
| ALOS | Number | Avg length of stay in days |
| Status | Choice | On Track, Below Target, At Capacity, Waitlist Active |
| Notes | Multi-line text | |
| LastUpdated | DateTime | |

**Seed data (1 row — current snapshot):**
March 2026, 47, 60, -, 12, 8, 42, On Track

#### List: Incident Reports
Used by: Home, Director, Clinical pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| IncidentID | Text | Format: IR-2026-XXX |
| IncidentDate | DateTime | |
| Category | Choice | Client Fall, Med Error, AMA Discharge, Behavioral Escalation, Property Damage, HIPAA Breach, Other |
| Severity | Choice | Critical, High, Medium, Low |
| Description | Multi-line text | |
| Status | Choice | Open, Under Review, Investigating, Resolved, Closed |
| AssignedTo | Person | |
| ResolutionDate | DateTime | |
| CorrectiveAction | Multi-line text | |

**Seed data (4 rows):**
IR-2026-012, Mar 1, Behavioral Escalation, Medium, Under Review
IR-2026-011, Feb 27, Med Error, High, Investigating
IR-2026-010, Feb 22, AMA Discharge, Low, Resolved
IR-2026-009, Feb 18, Client Fall, Low, Closed

#### List: Staff Credential Tracker
Used by: Home, Director, HR pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| StaffName | Text | |
| Role | Choice | LPC, LISAC, LCSW, LAC, BHT, CPSS, Admin, Admissions, Clinical Director |
| LicenseNumber | Text | |
| LicenseExpiration | DateTime | |
| FingerprintClearance | DateTime | FPC Level 1 expiration |
| CPRExpiration | DateTime | |
| HIPAATrainingDate | DateTime | |
| FWATrainingDate | DateTime | |
| CulturalCompDate | DateTime | |
| TraumaInformedDate | DateTime | |
| SupervisionCurrent | Yes/No | Only for LAC/BHT/CPSS |
| CEUsCompleted | Number | Current cycle |
| CEUsRequired | Number | Required per cycle |
| Status | Choice | Current, Expiring Soon, Expired, Action Required |

**Seed data (8 rows):** Generate representative staff including:
- J. Martinez (LPC, license expiring soon)
- S. Thompson (LISAC, current)
- R. Davis (LCSW, current)
- A. Nguyen (LAC, supervision required, logs overdue)
- D. Robinson (CPSS, current)
- K. Patel (BHT, CPR expiring)
- M. Reyes (Clinical Director, current)
- L. Chen (Admissions Coordinator, HIPAA due)

#### List: Corrective Action Plans (CAPs)
Used by: Home, Director pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| CAPID | Text | Format: CAP-2026-XXX |
| Title | Text | Description |
| Category | Choice | Documentation, Safety, Compliance, Clinical, Operations |
| Source | Choice | Internal Audit, Chart Audit, State Survey, Fire Marshal, Incident Report |
| OpenDate | DateTime | |
| DueDate | DateTime | |
| Owner | Person | |
| Status | Choice | Open, In Progress, Pending Verification, Closed |
| RootCause | Multi-line text | |
| CorrectiveAction | Multi-line text | |
| Evidence | Multi-line text | |

**Seed data (2 rows):**
CAP-2026-003, Documentation deficiency – treatment plans, Documentation, Chart Audit, Feb 10, Mar 15, Clinical Lead, In Progress
CAP-2026-002, Fire drill frequency gap, Safety, Fire Marshal, Jan 20, Feb 28, Operations, Pending Verification

#### List: Referral Partner Tracker
Used by: Home, Director, BD, Admissions pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| PartnerName | Text | |
| PartnerType | Choice | Hospital ED, Crisis Services, Courts/Probation, Outpatient MDs, Sober Living, Private Therapist, Community Org |
| Territory | Choice | North Phoenix, Scottsdale, East Valley, Tempe, West Valley, Metro PHX |
| ContactName | Text | |
| ContactPhone | Text | |
| ReferralsMTD | Number | |
| AdmitsMTD | Number | |
| ConversionPct | Calculated | =AdmitsMTD/ReferralsMTD |
| LastContact | DateTime | |
| AgreementOnFile | Yes/No | |
| Status | Choice | Active, Follow-Up, New Partner, Inactive |
| Notes | Multi-line text | |

**Seed data (8 rows):**
Valley Recovery Network, Sober Living, Scottsdale, 12 refs, 8 admits, Active
AZ Crisis Center, Crisis Services, Metro PHX, 8 refs, 5 admits, Active
Mercy Gilbert Medical, Hospital ED, East Valley, 6 refs, 4 admits, Active
Banner Thunderbird, Hospital ED, North Phoenix, 5 refs, 3 admits, Active
Maricopa Probation, Courts/Probation, Metro PHX, 4 refs, 2 admits, Active
Phoenix Counseling Group, Private Therapist, Scottsdale, 3 refs, 2 admits, Active
St. Luke's BH, Outpatient MDs, Tempe, 3 refs, 1 admit, Follow-Up
Oxford House AZ, Sober Living, East Valley, 2 refs, 1 admit, New Partner

#### List: Marketing Campaigns
Used by: Home, Marketing pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| CampaignName | Text | |
| Channel | Choice | Google Ads, SEO/Organic, Facebook/Instagram, Referral Partners, Community Events, Directories |
| SpendMTD | Currency | |
| Leads | Number | |
| CPL | Currency | |
| Admits | Number | |
| CPA | Currency | |
| Status | Choice | Live, Building, Paused, Completed |
| StartDate | DateTime | |
| Notes | Multi-line text | |

**Seed data (6 rows):**
IOP Awareness – Google, Google Ads, $2800, 18, $156, 4, $700, Live
SEO Content Program, SEO/Organic, $500, 12, $42, 3, $167, Live
Social – Recovery Stories, Facebook/Instagram, $1200, 8, $150, 2, $600, Live
Partner Referral Program, Referral Partners, $200, 23, $9, 8, $25, Live
Community Outreach, Community Events, $300, 5, $60, 1, $300, Live
LegitScript Directory, Directories, $0, 2, $0, 0, -, Live

#### List: Admissions Pipeline (Referral Log)
Used by: Admissions page

| Column | Type | Values/Notes |
|--------|------|-------------|
| ReferralID | Text | Format: REF-XXXX |
| ReferralDate | DateTime | |
| Source | Choice | Hospital ED, Self-Referral, Private Therapist, Probation, Alumni, Sober Living, Community, Crisis Line |
| SourceDetail | Text | Specific partner name |
| Insurance | Choice | AHCCCS Mercy Care, AHCCCS UHCCP, BCBS, UHC/Optum, Cigna, Aetna, Private Pay, Other/SCA |
| Stage | Choice | Lead, Pre-Screened, VOB In Progress, VOB Complete, Assessment Scheduled, Assessment Complete, Admitted, Waitlisted, Lost |
| Status | Choice | Active, Admitted, Waitlisted, No-Show, Lost, Declined |
| AssessmentDate | DateTime | |
| AdmitDate | DateTime | |
| AssignedTo | Person | |
| Notes | Multi-line text | |

**Seed data (6 rows):** Generate a mix of stages — 2 admitted, 1 assessment scheduled, 1 VOB in progress, 1 pre-screened, 1 lost.

#### List: Insurance Verification Tracker
Used by: Admissions page

| Column | Type | Values/Notes |
|--------|------|-------------|
| ReferralID | Text | Links to Admissions Pipeline |
| ClientInitials | Text | |
| Insurance | Choice | (same as Admissions Pipeline) |
| VerificationDate | DateTime | |
| AHCCCSEligible | Yes/No | |
| CoveredDays | Number | |
| Copay | Currency | |
| PriorAuthRequired | Yes/No | |
| PriorAuthStatus | Choice | Not Required, Pending, Approved, Denied |
| Status | Choice | Pending, Verified, Issue, Denied |
| Notes | Multi-line text | |

**Seed data (5 rows):** Mix of verified, pending, and one with an issue.

#### List: Revenue Tracker
Used by: Home, Director, Administration pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| Month | DateTime | |
| Payer | Choice | AHCCCS Mercy Care, AHCCCS UHCCP, BCBS, UHC/Optum, Cigna, Aetna, Private Pay, Other/SCA |
| Revenue | Currency | |
| ClaimCount | Number | |
| DenialCount | Number | |
| CleanClaimPct | Number (%) | |
| Notes | Multi-line text | |

**Seed data (Feb 2026 — 8 rows, one per payer):**
Total revenue MTD: $218K. Target: $250K. 87% pacing. Generate realistic payer mix with AHCCCS as largest portion.

#### List: Compliance Audit Calendar
Used by: Director, Administration pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| Title | Text | Event name |
| AuditDate | DateTime | |
| AuditType | Choice | AZDHS, Fire Marshal, Internal, HIPAA, Chart Audit, 9 A.A.C. 10 |
| Scope | Text | |
| Owner | Person | |
| Status | Choice | Scheduled, Preparing, Complete, Overdue |
| DaysRemaining | Calculated | =AuditDate-Today() |
| Notes | Multi-line text | |

**Seed data (5 rows):**
Fire Drill, Mar 10, Internal, Facility-wide, Operations, Scheduled
Chart Audit – Q1, Mar 20, Chart Audit, 15 random charts, Clinical Lead, Scheduled
AHCCCS Provider Review, Apr 15, AZDHS, Full facility, Compliance, Preparing
Fire Marshal Inspection, Apr 30, Fire Marshal, Facility, Operations, Scheduled
HIPAA Risk Assessment, May 1, HIPAA, Organization, Compliance, Scheduled

#### List: Group Schedule
Used by: Clinical page

| Column | Type | Values/Notes |
|--------|------|-------------|
| GroupName | Text | |
| DayOfWeek | Choice | Monday, Tuesday, Wednesday, Thursday, Friday |
| TimeSlot | Text | e.g., "9:00 AM – 10:30 AM" |
| Facilitator | Person or Text | |
| GroupType | Choice | CBT, DBT, Process, Psychoeducation, Relapse Prevention, Mindfulness, Life Skills |
| Room | Choice | Group Room A, Group Room B, Outdoor |
| MaxParticipants | Number | |
| Notes | Multi-line text | |

**Seed data (10 rows):** Generate Mon-Fri schedule with 2 groups per day covering CBT, DBT, Process, Relapse Prevention, etc.

#### List: Group Attendance Log
Used by: Clinical page

| Column | Type | Values/Notes |
|--------|------|-------------|
| Date | DateTime | |
| GroupName | Text | |
| Facilitator | Text | |
| Attendees | Number | Count |
| Notes | Multi-line text | |

#### List: Client Outcomes Tracker
Used by: Clinical page

| Column | Type | Values/Notes |
|--------|------|-------------|
| ClientID | Text | De-identified |
| AdmitDate | DateTime | |
| DischargeDate | DateTime | |
| LOSdays | Calculated | =DischargeDate-AdmitDate |
| PHQ9Intake | Number | |
| PHQ9Discharge | Number | |
| GAD7Intake | Number | |
| GAD7Discharge | Number | |
| CompletionStatus | Choice | Successful Completion, AMA, Transferred, Administrative, Referred Up |
| Notes | Multi-line text | |

#### List: Treatment Plan Review Dates
Used by: Clinical page

| Column | Type | Values/Notes |
|--------|------|-------------|
| ClientID | Text | |
| Therapist | Person or Text | |
| LastReviewDate | DateTime | |
| NextReviewDue | DateTime | |
| Status | Choice | Current, Due This Week, Overdue |
| Notes | Multi-line text | |

#### List: UDS Tracking Log
Used by: Clinical page

| Column | Type | Values/Notes |
|--------|------|-------------|
| ClientID | Text | |
| TestDate | DateTime | |
| Result | Choice | Negative, Positive, Refused, Not Tested |
| SubstanceDetected | Text | If positive |
| ActionTaken | Text | |
| Notes | Multi-line text | |

#### List: BD Visit Log
Used by: BD page

| Column | Type | Values/Notes |
|--------|------|-------------|
| VisitDate | DateTime | |
| PartnerName | Text | |
| ContactPerson | Text | |
| VisitType | Choice | In-Person, Virtual, Phone, Lunch, Facility Tour, Event |
| Purpose | Text | |
| Outcome | Text | |
| FollowUpDate | DateTime | |
| Notes | Multi-line text | |

#### List: BD Gift Log (Anti-Kickback)
Used by: BD page

| Column | Type | Values/Notes |
|--------|------|-------------|
| Date | DateTime | |
| Recipient | Text | |
| Organization | Text | |
| GiftDescription | Text | |
| Value | Currency | |
| Compliant | Yes/No | Must be < $25 per AKS guidelines |
| Notes | Multi-line text | |

#### List: Payroll Tracker
Used by: HR, Administration pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| PayPeriod | Text | |
| StaffName | Text | |
| Role | Choice | (same role list) |
| RegularHours | Number | |
| OTHours | Number | |
| GrossPay | Currency | |
| Status | Choice | Processed, Pending, Issue |
| Notes | Multi-line text | |

#### List: Open Positions
Used by: HR page

| Column | Type | Values/Notes |
|--------|------|-------------|
| PositionTitle | Text | |
| Department | Choice | Clinical, Admissions, Marketing, BD, Admin, Operations |
| PostedDate | DateTime | |
| Applications | Number | |
| Interviews | Number | |
| Status | Choice | Open, Interviewing, Offer Extended, Filled, On Hold |
| Notes | Multi-line text | |

**Seed data (2 rows):**
Licensed Therapist (LISAC), Clinical, Feb 15, 12, 3, Interviewing
BHT – Part Time, Clinical, Mar 1, 5, 0, Open

#### List: Billing Denials
Used by: Administration page

| Column | Type | Values/Notes |
|--------|------|-------------|
| ClaimID | Text | |
| Payer | Choice | (same payer list) |
| DenialDate | DateTime | |
| DenialReason | Choice | Auth Expired, Medical Necessity, Eligibility, Timely Filing, Coding Error, Duplicate, Other |
| Amount | Currency | |
| AppealStatus | Choice | Not Appealed, Appeal Filed, Won, Lost, Write-Off |
| AppealDeadline | DateTime | |
| Notes | Multi-line text | |

**Seed data (6 rows):** Generate realistic mix of denials — auth expired, coding errors, eligibility issues.

#### List: Employee Training Log
Used by: Administration page

| Column | Type | Values/Notes |
|--------|------|-------------|
| StaffName | Text | |
| TrainingName | Choice | HIPAA, FWA, Cultural Competency, Trauma-Informed Care, QPR Suicide Prevention, Mandated Reporter, CPR/First Aid, CPI De-escalation, BBP/OSHA |
| CompletedDate | DateTime | |
| DueDate | DateTime | |
| Frequency | Choice | Annual, Biennial, One-Time, As Needed |
| Status | Choice | Current, Due Soon, Overdue |
| CertificateOnFile | Yes/No | |

---

## PART 2: PAGE TEMPLATES WITH WEB PARTS

### Instructions for Claude Code

Generate a PnP PowerShell script called `Deploy-ChollaPages.ps1` that creates all 8 SharePoint pages using `Add-PnPPage` and adds web parts using `Add-PnPPageWebPart`.

### Web Part Reference

| Web Part | Internal Name / ID |
|----------|-------------------|
| Document Library | `DocumentLibrary` — property: `libraryId` |
| List | `List` — property: `listId` |
| Power BI | `544dd15b-cf3c-441b-96da-004d5a8cea1d` — property: `reportUrl` |
| Embed | `490d7c76-1824-45b2-9de3-676421c997fa` — property: `embedCode` or `websiteUrl` |
| Text / Markdown | `Text` — property: `innerHTML` |
| Quick Links | `QuickLinks` |
| Hero | `Hero` |

### Page Definitions

#### Home Page (Home.aspx)
- Hero web part with Cholla branding
- Quick Links → links to all 7 department pages
- Text web part with welcome message
- List web part → Census Tracker (snapshot view)
- List web part → Incident Reports (recent, filtered Open/Under Review)
- List web part → Staff Credential Tracker (expiring view)
- List web part → Referral Partner Tracker (summary)
- List web part → Marketing Campaigns (active)
- List web part → Revenue Tracker (MTD)

#### Director of Operations (Director-of-Operations.aspx)
- **Section 1:** Embed web part → iframe to hosted Director KPI dashboard HTML
- **Section 2:** Power BI web part → `{POWER_BI_REPORT_URL}` placeholder
- **Section 3:** Document Library web part → Director-Documents
- **Section 4 (Two columns):**
  - Left: List web part → Incident Reports
  - Right: List web part → Compliance Audit Calendar
- **Section 5 (Two columns):**
  - Left: List web part → Staff Credential Tracker
  - Right: List web part → Corrective Action Plans
- **Section 6:** List web part → Referral Partner Tracker
- **Section 7:** Embed web part → Meeting Hub HTML section

#### Clinical Department (Clinical-Department.aspx)
- **Section 1:** Embed web part → iframe to hosted Clinical KPI dashboard HTML
- **Section 2:** List web part → Group Schedule (weekly view)
- **Section 3:** Document Library web part → Clinical-Documents
- **Section 4 (Two columns):**
  - Left: List web part → Group Attendance Log
  - Right: List web part → Client Outcomes Tracker
- **Section 5 (Two columns):**
  - Left: List web part → Treatment Plan Review Dates
  - Right: List web part → UDS Tracking Log

#### Admissions Department (Admissions-Department.aspx)
- **Section 1:** Embed web part → iframe to hosted Admissions KPI + Pipeline HTML
- **Section 2:** List web part → Admissions Pipeline (Referral Log)
- **Section 3:** List web part → Insurance Verification Tracker
- **Section 4:** Document Library web part → Admissions-Documents

#### Marketing Department (Marketing-Department.aspx)
- **Section 1:** Embed web part → iframe to hosted Marketing KPI dashboard HTML
- **Section 2:** List web part → Marketing Campaigns
- **Section 3:** Document Library web part → Marketing-Documents

#### Business Development (Business-Development.aspx)
- **Section 1:** Embed web part → iframe to hosted BD KPI dashboard HTML
- **Section 2:** List web part → Referral Partner Tracker
- **Section 3:** Document Library web part → BD-Documents
- **Section 4 (Two columns):**
  - Left: List web part → BD Visit Log
  - Right: List web part → BD Gift Log (Anti-Kickback)

#### Human Resources (Human-Resources.aspx)
- **Section 1:** Embed web part → iframe to hosted HR KPI dashboard HTML
- **Section 2:** List web part → Staff Credential Tracker
- **Section 3:** Document Library web part → HR-Documents
- **Section 4 (Two columns):**
  - Left: List web part → Open Positions
  - Right: List web part → Payroll Tracker
- **Section 5:** Embed web part → BH Training Matrix HTML

#### Administration (Administration.aspx)
- **Section 1:** Embed web part → iframe to hosted Admin KPI dashboard HTML (tabbed HR/Billing/Compliance)
- **Section 2 (Two columns):**
  - Left: List web part → Payroll Tracker
  - Right: List web part → Billing Denials
- **Section 3:** List web part → Compliance Audit Calendar
- **Section 4:** Document Library web part → Admin-Documents
- **Section 5:** List web part → Employee Training Log

### Embed URLs

```json
{
    "director_dashboard": "https://{GITHUB_PAGES_URL}/Cholla_Director_KPIs.html",
    "clinical_dashboard": "https://{GITHUB_PAGES_URL}/Cholla_Clinical_KPIs.html",
    "admissions_dashboard": "https://{GITHUB_PAGES_URL}/Cholla_Admissions_KPIs.html",
    "marketing_dashboard": "https://{GITHUB_PAGES_URL}/Cholla_Marketing_KPIs.html",
    "bd_dashboard": "https://{GITHUB_PAGES_URL}/Cholla_BD_KPIs.html",
    "hr_dashboard": "https://{GITHUB_PAGES_URL}/Cholla_HR_KPIs.html",
    "admin_dashboard": "https://{GITHUB_PAGES_URL}/Cholla_Admin_KPIs.html"
}
```

Also generate a script `Extract-KPI-Sections.sh` that takes each full mockup HTML file and extracts ONLY the KPI dashboard + custom visualization sections (not the SharePoint chrome, nav, doc libraries, or lists — those will be native), outputting slim HTML files suitable for iframe embedding.

---

## PART 3: POWER BI DATA MODEL SPECIFICATION

### Instructions for Claude Code

Generate a Power BI data model specification file (`Cholla-PowerBI-Spec.md`) and a Power BI theme JSON.

### 3.1 Data Sources

Connect to SharePoint lists created in Part 1. Connection method: SharePoint Online List connector.

**SharePoint Site URL:** `https://{TENANT}.sharepoint.com/sites/{SITE_ALIAS}`

**Lists to connect:**
1. Census Tracker
2. Incident Reports
3. Staff Credential Tracker
4. Corrective Action Plans
5. Referral Partner Tracker
6. Marketing Campaigns
7. Admissions Pipeline
8. Insurance Verification Tracker
9. Revenue Tracker
10. Compliance Audit Calendar
11. Group Schedule
12. Client Outcomes Tracker
13. Billing Denials
14. Employee Training Log

### 3.2 Calculated Tables

#### Date Table
```dax
DateTable =
ADDCOLUMNS(
    CALENDAR(DATE(2025,1,1), DATE(2026,12,31)),
    "Year", YEAR([Date]),
    "Month", MONTH([Date]),
    "MonthName", FORMAT([Date], "MMMM"),
    "Quarter", "Q" & CEILING(MONTH([Date])/3, 1),
    "WeekNum", WEEKNUM([Date]),
    "DayOfWeek", WEEKDAY([Date]),
    "IsCurrentMonth", IF(MONTH([Date]) = MONTH(TODAY()) && YEAR([Date]) = YEAR(TODAY()), TRUE, FALSE)
)
```

### 3.3 Key DAX Measures

```dax
// ===== CENSUS =====
Active Census = SUM(CensusTracker[ActiveCensus])
Slot Capacity = 60
Utilization Rate = DIVIDE([Active Census], [Slot Capacity], 0)

// ===== REVENUE =====
Revenue MTD = CALCULATE(SUM(RevenueTracker[Revenue]), DateTable[IsCurrentMonth] = TRUE)
Revenue Target = 250000
Revenue Pacing = DIVIDE([Revenue MTD], [Revenue Target], 0)
Clean Claim Rate = DIVIDE(
    SUM(RevenueTracker[ClaimCount]) - SUM(RevenueTracker[DenialCount]),
    SUM(RevenueTracker[ClaimCount]), 0
)

// ===== ADMISSIONS =====
Referrals MTD = CALCULATE(COUNTROWS(AdmissionsPipeline), DateTable[IsCurrentMonth] = TRUE)
Admits MTD = CALCULATE(COUNTROWS(AdmissionsPipeline), AdmissionsPipeline[Status] = "Admitted", DateTable[IsCurrentMonth] = TRUE)
Conversion Rate = DIVIDE([Admits MTD], [Referrals MTD], 0)

// ===== COMPLIANCE =====
Compliance Score = 94  // From last audit
Open CAPs = CALCULATE(COUNTROWS(CorrectiveActionPlans), CorrectiveActionPlans[Status] IN {"Open", "In Progress"})
Overdue Audits = CALCULATE(COUNTROWS(ComplianceAuditCalendar), ComplianceAuditCalendar[Status] = "Overdue")

// ===== STAFF / HR =====
Total Staff = COUNTROWS(StaffCredentialTracker)
Credentials Expiring 30d = CALCULATE(
    COUNTROWS(StaffCredentialTracker),
    StaffCredentialTracker[LicenseExpiration] <= TODAY() + 30,
    StaffCredentialTracker[LicenseExpiration] >= TODAY()
)
Credential Compliance Rate = DIVIDE(
    CALCULATE(COUNTROWS(StaffCredentialTracker), StaffCredentialTracker[Status] = "Current"),
    [Total Staff], 0
)

// ===== CLINICAL =====
Note Completion Rate = 0.91  // 91% from KPI
Treatment Plan Compliance = 0.88  // 88%
Discharge Success Rate = DIVIDE(
    CALCULATE(COUNTROWS(ClientOutcomesTracker), ClientOutcomesTracker[CompletionStatus] = "Successful Completion"),
    COUNTROWS(ClientOutcomesTracker), 0
)
Avg PHQ9 Improvement = AVERAGEX(
    ClientOutcomesTracker,
    ClientOutcomesTracker[PHQ9Intake] - ClientOutcomesTracker[PHQ9Discharge]
)

// ===== REFERRAL PARTNERS =====
Active Partners = CALCULATE(COUNTROWS(ReferralPartnerTracker), ReferralPartnerTracker[Status] = "Active")
Partner Conversion Rate = DIVIDE(
    SUM(ReferralPartnerTracker[AdmitsMTD]),
    SUM(ReferralPartnerTracker[ReferralsMTD]), 0
)

// ===== MARKETING =====
Total Marketing Spend = SUM(MarketingCampaigns[SpendMTD])
Total Leads = SUM(MarketingCampaigns[Leads])
Blended CPL = DIVIDE([Total Marketing Spend], [Total Leads], 0)
Total Marketing Admits = SUM(MarketingCampaigns[Admits])
Blended CPA = DIVIDE([Total Marketing Spend], [Total Marketing Admits], 0)
```

### 3.4 Report Pages

| Page | Key Visuals |
|------|-------------|
| **Executive Overview** | KPI cards (Census 47, Utilization 82%, Revenue $218K, Compliance 94%), revenue trend, referral source donut, discharge outcome gauge |
| **Clinical** | Caseload count, note completion %, PHQ-9 improvement trend, group attendance heatmap, treatment plan compliance |
| **Admissions** | Pipeline funnel, referrals by source bar, conversion rate KPI, insurance mix, time-to-admit |
| **Financial** | Revenue MTD vs $250K target, revenue by payer stacked bar, clean claim rate gauge, denial trend, days in A/R |
| **Compliance** | Audit timeline, open CAPs count, training compliance matrix, credential expiration heatmap |
| **HR / Workforce** | Headcount (22), turnover rate (12%), license expiration timeline, training compliance by type |
| **Referral Network** | Referrals by partner bar, conversion by partner, territory coverage, partner activity timeline |
| **Marketing** | Spend by channel, CPL comparison, leads trend, CPA by channel, content calendar status |

### 3.5 Theme File

Generate `Cholla-Theme-PowerBI.json`:

```json
{
    "name": "Cholla Behavioral Health",
    "dataColors": [
        "#1a7a7a", "#0d5f5f", "#3aa8a8", "#107c10",
        "#d83b01", "#52a8a8", "#986f0b", "#605e5c"
    ],
    "background": "#ffffff",
    "foreground": "#323130",
    "tableAccent": "#1a7a7a",
    "visualStyles": {
        "*": {
            "*": {
                "title": [{
                    "fontFamily": "Segoe UI",
                    "fontSize": 12,
                    "color": {"solid": {"color": "#2b2b2b"}}
                }]
            }
        }
    }
}
```

---

## PART 4: DEPLOYMENT RUNBOOK

### Step-by-Step

#### Day 1: Provision (2-3 hours)

1. Open PowerShell 7 terminal
2. Run `Install-Module -Name PnP.PowerShell -Scope CurrentUser` (if not installed)
3. Edit `Deploy-ChollaHub.ps1` — set `$TenantUrl` and `$SiteAlias`
4. Run `.\Deploy-ChollaHub.ps1` — creates site, theme, lists, doc libraries
5. Run `.\Deploy-ChollaPages.ps1` — creates 8 pages with web parts
6. Verify: open site URL in browser

#### Day 2: KPI Dashboards (2 hours)

1. Host the 7 KPI-only HTML files on GitHub Pages (or Azure Blob with CORS)
2. Update `embed-urls.json` with real URLs
3. Re-run page deployment or manually paste URLs into Embed web parts
4. Test each page

#### Day 3: Power BI (3-4 hours)

1. Open Power BI Desktop
2. Connect to SharePoint Online lists
3. Apply data model and DAX measures
4. Build report pages per spec
5. Apply Cholla theme
6. Publish to Power BI Service
7. Update Power BI web parts on Director and other pages

#### Day 4: Polish & Handoff (2 hours)

1. Upload real documents to libraries
2. Populate lists with actual Cholla data
3. Set permissions
4. Test navigation end-to-end
5. Walk Cholla team through the hub

### Total LOE: ~3-4 days
### Required Access: SharePoint Admin or Global Admin on Cholla's M365 tenant
### Required Tools: PowerShell 7, PnP.PowerShell module, Power BI Desktop, GitHub account

---

## FILES THIS PROMPT SHOULD GENERATE

```
cholla-ops-hub/
├── scripts/
│   ├── Deploy-ChollaHub.ps1              # Site, theme, lists, doc libraries
│   ├── Deploy-ChollaPages.ps1            # Pages with web parts
│   ├── Seed-ListData.ps1                 # Pre-populate lists with sample data
│   ├── Extract-KPI-Sections.sh           # Strip KPI dashboards from full HTML
│   └── embed-urls.json                   # URL mapping for embed web parts
├── theme/
│   ├── cholla-theme.json                 # SharePoint theme
│   └── Cholla-Theme-PowerBI.json         # Power BI theme
├── powerbi/
│   ├── Cholla-PowerBI-Spec.md            # Full data model documentation
│   └── Cholla-DAX-Measures.dax           # All DAX measures in one file
├── assets/
│   └── cholla-logo.png                   # Logo for site branding
├── kpi-embeds/                           # Extracted KPI-only HTML files
│   ├── Director-KPIs.html
│   ├── Clinical-KPIs.html
│   ├── Admissions-KPIs.html
│   ├── Marketing-KPIs.html
│   ├── BD-KPIs.html
│   ├── HR-KPIs.html
│   └── Admin-KPIs.html
└── README.md                             # Setup instructions
```

---

*Generated by Manage AI for Cholla Behavioral Health SharePoint IOP Operations Hub deployment.*
