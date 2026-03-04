# Cholla IOP Operations Hub — SharePoint Deployment

A complete SharePoint Online Operations Hub for **Cholla Behavioral Health**, a single-facility behavioral health IOP clinic in Phoenix, AZ. This repo contains all provisioning scripts, KPI dashboards, Power BI artifacts, and deployment documentation.

## Site Details

| Parameter | Value |
|-----------|-------|
| **Tenant URL** | `https://chollabehavioralhealth.sharepoint.com` |
| **Site Alias** | `iop-hub-dev` |
| **Site URL** | `https://chollabehavioralhealth.sharepoint.com/sites/iop-hub-dev` |
| **Site Type** | Communication Site |
| **Admin** | `breinhart@chollabehavioralhealth.com` |
| **Brand Primary** | `#1a7a7a` (Cholla Teal) |

## Repository Structure

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
│   ├── Cholla-DAX-Measures.dax           # All DAX measures in one file
│   └── Cholla-DataModel.bim             # Tabular data model (BIM)
├── assets/
│   └── cholla-logo.png                   # Logo for site branding
├── kpi-embeds/                           # Standalone KPI dashboard HTML files
│   ├── Director-KPIs.html
│   ├── Clinical-KPIs.html
│   ├── Admissions-KPIs.html
│   ├── Marketing-KPIs.html
│   ├── BD-KPIs.html
│   ├── HR-KPIs.html
│   └── Admin-KPIs.html
└── README.md                             # This file
```

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| **PowerShell** | 7.x+ | [Install PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |
| **PnP.PowerShell** | Latest | `Install-Module -Name PnP.PowerShell -Scope CurrentUser` |
| **Power BI Desktop** | Latest | [Download](https://powerbi.microsoft.com/desktop/) |
| **GitHub Account** | — | For hosting KPI HTML files on GitHub Pages |

### Required Access

- **SharePoint Admin** or **Global Admin** on Cholla's M365 tenant
- Permissions to create Communication Sites and register tenant themes
- Power BI Pro license (for publishing reports)

---

## PART 4: DEPLOYMENT RUNBOOK

### Day 1: Provision Site & Structure (2–3 hours)

1. **Open PowerShell 7 terminal**

2. **Install PnP.PowerShell** (if not already installed):
   ```powershell
   Install-Module -Name PnP.PowerShell -Scope CurrentUser
   ```

3. **Review and confirm parameters** in `Deploy-ChollaHub.ps1`:
   ```powershell
   # These are the defaults — edit if your tenant differs
   $TenantUrl   = "https://chollabehavioralhealth.sharepoint.com"
   $SiteAlias   = "iop-hub-dev"
   $AdminEmail  = "breinhart@chollabehavioralhealth.com"
   ```

4. **Run the site provisioning script**:
   ```powershell
   .\scripts\Deploy-ChollaHub.ps1
   ```
   This creates:
   - Communication Site "Cholla IOP Operations Hub"
   - Cholla brand theme (primary `#1a7a7a`)
   - 8-link hub navigation
   - 7 document libraries with full folder trees and placeholder files
   - 18 SharePoint lists with all typed columns (including 3 Calculated fields)

   > The script is **idempotent** — safe to re-run without duplicating anything.

5. **Seed sample data**:
   ```powershell
   .\scripts\Seed-ListData.ps1
   ```
   Pre-populates all 18 lists with 121 rows of realistic sample data. Also idempotent.

6. **Deploy pages with web parts**:
   ```powershell
   .\scripts\Deploy-ChollaPages.ps1
   ```
   Creates all 8 SharePoint pages:
   - Home (landing page with Hero, Quick Links, and list summaries)
   - Director of Operations
   - Clinical Department
   - Admissions Department
   - Marketing Department
   - Business Development
   - Human Resources
   - Administration

7. **Verify**: Open `https://chollabehavioralhealth.sharepoint.com/sites/iop-hub-dev` in your browser and confirm all pages, lists, libraries, and navigation are present.

### Day 2: KPI Dashboards (2 hours)

1. **Host KPI HTML files on GitHub Pages** (or Azure Blob Storage with CORS):
   - Push the `kpi-embeds/` folder to a GitHub repo
   - Enable GitHub Pages in Settings → Pages → Source: main branch
   - Note the base URL (e.g., `https://yourorg.github.io/cholla-ops-hub/kpi-embeds/`)

2. **Update `embed-urls.json`** with real URLs:
   ```json
   {
     "director_kpi": "https://yourorg.github.io/cholla-ops-hub/kpi-embeds/Director-KPIs.html",
     "clinical_kpi": "https://yourorg.github.io/cholla-ops-hub/kpi-embeds/Clinical-KPIs.html"
   }
   ```

3. **Re-run page deployment** (or manually update Embed web part URLs):
   ```powershell
   .\scripts\Deploy-ChollaPages.ps1
   ```

4. **Test each page** — verify KPI dashboards render inside the Embed web parts.

### Day 3: Power BI (3–4 hours)

1. **Open Power BI Desktop**

2. **Connect to SharePoint Online lists**:
   - Get Data → SharePoint Online List
   - Enter site URL: `https://chollabehavioralhealth.sharepoint.com/sites/iop-hub-dev`
   - Select all 18 lists (or connect them one by one per the data model spec)

3. **Apply data model**:
   - Reference `powerbi/Cholla-PowerBI-Spec.md` for the full data model
   - Reference `powerbi/Cholla-DataModel.bim` for the tabular model structure
   - Create the DateTable calculated table
   - Set up 7 relationships as documented

4. **Add DAX measures**:
   - Copy measures from `powerbi/Cholla-DAX-Measures.dax`
   - 60+ measures across 9 categories: Census, Revenue, Admissions, Insurance, Compliance, Staff/HR, Clinical, Marketing, Billing

5. **Build 8 report pages** per spec:

   | Page | Key Visuals |
   |------|-------------|
   | Executive Overview | KPI cards (Census 47, Utilization 82%, Revenue $218K, Compliance 94%), revenue trend, referral source donut, discharge outcome gauge |
   | Clinical | Caseload count, note completion %, PHQ-9 improvement trend, group attendance heatmap, treatment plan compliance |
   | Admissions | Pipeline funnel, referrals by source bar, conversion rate KPI, insurance mix, time-to-admit |
   | Financial | Revenue MTD vs $250K target, revenue by payer stacked bar, clean claim rate gauge, denial trend, days in A/R |
   | Compliance | Audit timeline, open CAPs count, training compliance matrix, credential expiration heatmap |
   | HR / Workforce | Headcount (22), turnover rate (12%), license expiration timeline, training compliance by type |
   | Referral Network | Referrals by partner bar, conversion by partner, territory coverage, partner activity timeline |
   | Marketing | Spend by channel, CPL comparison, leads trend, CPA by channel, content calendar status |

6. **Apply Cholla theme**:
   - View → Themes → Browse for themes → select `theme/Cholla-Theme-PowerBI.json`

7. **Publish to Power BI Service**:
   - Publish → select workspace
   - Note the report embed URL for the Director page's Power BI web part

8. **Update Power BI web parts** on Director and other SharePoint pages with the published report URLs.

### Day 4: Polish & Handoff (2 hours)

1. **Upload real documents** to the 7 document libraries:
   - Replace placeholder `.txt` files with actual policies, procedures, and templates
   - Organize into existing folder structures

2. **Populate lists with actual Cholla data**:
   - Replace sample data with real census, staff, revenue, and compliance data
   - Delete or archive seed data rows

3. **Set permissions**:
   - Site Owners: Director of Operations, IT Admin
   - Site Members: Department leads and clinical staff
   - Site Visitors: Read-only stakeholders
   - Consider creating SharePoint groups per department for targeted page access

4. **Test navigation end-to-end**:
   - Verify all 8 nav links work
   - Confirm KPI dashboards load in Embed web parts
   - Check Power BI visuals refresh correctly
   - Test on mobile/tablet for responsive layout

5. **Walk Cholla team through the hub**:
   - Schedule a 30-minute walkthrough with key stakeholders
   - Cover: navigation, KPI dashboards, list data entry, document uploads
   - Document any customization requests for Phase 2

---

## What's Deployed

### 18 SharePoint Lists

| # | List | Purpose |
|---|------|---------|
| 1 | Daily Census Log | Daily patient census tracking (capacity 60) |
| 2 | Incident Reports | Safety and incident reporting |
| 3 | Staff Credential Tracker | License/certification tracking for 22 staff |
| 4 | Corrective Action Plans | AHCCCS/AZDHS compliance CAPs |
| 5 | Referral Partner Tracker | 8+ referral partners with conversion metrics |
| 6 | Marketing Campaigns | Campaign spend, leads, CPL, CPA by channel |
| 7 | Admissions Pipeline | Referral-to-admit funnel tracking |
| 8 | Insurance Verification Log | VOB and authorization tracking |
| 9 | Revenue Tracker | Monthly revenue by payer ($218K sample) |
| 10 | Compliance Audit Calendar | Scheduled and completed audits |
| 11 | Group Schedule | 10 weekly group therapy sessions |
| 12 | Attendance Log | Session-level attendance with PHQ-9/GAD-7 |
| 13 | Client Outcomes Tracker | Intake-to-discharge outcome measures |
| 14 | Treatment Plan Reviews | 30/60/90-day treatment plan compliance |
| 15 | UDS Tracking | Drug screening compliance log |
| 16 | BD Activity Log | Business development visit tracking |
| 17 | Gift Log | Compliance gift/meal tracking ($25 limit) |
| 18 | Payroll Tracker | Bi-weekly payroll with OT tracking |

### 7 Document Libraries

Director-Documents, Clinical-Documents, Admissions-Documents, Marketing-Documents, BD-Documents, HR-Documents, Admin-Documents — each with department-specific folder trees.

### 7 KPI Dashboards

Self-contained HTML files optimized for SharePoint Embed web parts. Each uses the Cholla brand palette and displays real-time-style KPI cards, tables, and charts.

---

## Total Level of Effort

| Phase | Time |
|-------|------|
| Day 1: Provision | 2–3 hours |
| Day 2: KPI Dashboards | 2 hours |
| Day 3: Power BI | 3–4 hours |
| Day 4: Polish & Handoff | 2 hours |
| **Total** | **~3–4 days** |

---

## Troubleshooting

### Script fails to connect
```powershell
# Ensure you're using PowerShell 7+
$PSVersionTable.PSVersion

# Re-authenticate
Connect-PnPOnline -Url "https://chollabehavioralhealth.sharepoint.com/sites/iop-hub-dev" -Interactive
```

### Theme doesn't apply
- Tenant themes require **SharePoint Admin** or **Global Admin** permissions
- Wait 5–10 minutes for theme propagation after registration

### Embed web parts show blank
- Ensure KPI HTML files are hosted on HTTPS
- Check that the hosting domain is not blocked by SharePoint's iframe policy
- For GitHub Pages: ensure the repo is public, or use Azure Blob with CORS headers

### Power BI web part shows "No report"
- Confirm the report is published to Power BI Service
- Verify the user has a Power BI Pro license
- Check that the report workspace is shared with site members

---

*Generated by Manage AI for Cholla Behavioral Health SharePoint IOP Operations Hub deployment.*
