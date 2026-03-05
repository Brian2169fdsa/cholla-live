<#
.SYNOPSIS
    Cholla IOP Operations Hub — Seed List Data Script

.DESCRIPTION
    Pre-populates all 18 SharePoint lists with representative sample data from the
    Cholla Behavioral Health IOP Operations Hub spec. Run AFTER Deploy-ChollaHub.ps1.

    This script is IDEMPOTENT — checks for existing items before inserting.
    Uses the Title or a unique ID field to detect duplicates.

.PARAMETER SiteUrl
    Full URL of the deployed hub site.

.NOTES
    Required: PnP.PowerShell module
    Required: Site must already be provisioned via Deploy-ChollaHub.ps1
    Prepared by Manage AI for Cholla Behavioral Health — March 2026
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://chollabehavioralhealth.sharepoint.com/sites/AIWorkspace"
)

$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

function Write-Step {
    param([string]$Message)
    Write-Host "`n━━━ $Message ━━━" -ForegroundColor Cyan
}

function Write-OK {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "  [SKIP] $Message" -ForegroundColor Yellow
}

function Add-ListItemSafe {
    <#
    .SYNOPSIS
        Adds a list item if a matching item doesn't already exist.
        Uses $CheckField/$CheckValue to detect duplicates.
    #>
    param(
        [string]$ListName,
        [hashtable]$Values,
        [string]$CheckField = "Title",
        [string]$CheckValue
    )
    if (-not $CheckValue) {
        $CheckValue = $Values["Title"]
    }
    if ($CheckValue) {
        $existing = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='$CheckField'/><Value Type='Text'>$CheckValue</Value></Eq></Where></Query></View>" -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Skip "  '$CheckValue' already exists in '$ListName'"
            return
        }
    }
    Add-PnPListItem -List $ListName -Values $Values -ErrorAction Stop | Out-Null
    $label = if ($CheckValue) { $CheckValue } else { ($Values.Values | Select-Object -First 1) }
    Write-OK "  Added: $label"
}

# ─────────────────────────────────────────────────────────────────────────────
# CONNECT
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Connecting to $SiteUrl"
Connect-PnPOnline -Url $SiteUrl -Interactive
Write-OK "Connected"

# ─────────────────────────────────────────────────────────────────────────────
# 1. CENSUS TRACKER (1 row)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "1/18 — Census Tracker"
Add-ListItemSafe -ListName "Census Tracker" -Values @{
    Title         = "March 2026"
    ActiveCensus  = 47
    Capacity      = 60
    NewAdmits     = 12
    Discharges    = 8
    ALOS          = 42
    Status        = "On Track"
    Notes         = "Census trending upward. Approaching 80% utilization target."
    LastUpdated   = "2026-03-03"
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. INCIDENT REPORTS (4 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "2/18 — Incident Reports"
Add-ListItemSafe -ListName "Incident Reports" -CheckField "IncidentID" -CheckValue "IR-2026-012" -Values @{
    Title            = "Behavioral Escalation — Group Room A"
    IncidentID       = "IR-2026-012"
    IncidentDate     = "2026-03-01"
    Category         = "Behavioral Escalation"
    Severity         = "Medium"
    Description      = "Client became verbally aggressive during morning CBT group. De-escalation protocol followed. Client stabilized within 20 minutes. No physical contact."
    Status           = "Under Review"
}
Add-ListItemSafe -ListName "Incident Reports" -CheckField "IncidentID" -CheckValue "IR-2026-011" -Values @{
    Title            = "Medication Error — Wrong Dosage Documented"
    IncidentID       = "IR-2026-011"
    IncidentDate     = "2026-02-27"
    Category         = "Med Error"
    Severity         = "High"
    Description      = "Nursing staff documented incorrect medication dosage in the EHR for client C-2026-031. Discovered during chart audit. Client received correct dose — documentation error only."
    Status           = "Investigating"
    CorrectiveAction = "Chart correction submitted. Additional EHR documentation training scheduled for nursing staff."
}
Add-ListItemSafe -ListName "Incident Reports" -CheckField "IncidentID" -CheckValue "IR-2026-010" -Values @{
    Title            = "AMA Discharge — Client Left Program"
    IncidentID       = "IR-2026-010"
    IncidentDate     = "2026-02-22"
    Category         = "AMA Discharge"
    Severity         = "Low"
    Description      = "Client C-2026-028 voluntarily left the IOP program against medical advice on day 14 of treatment. Safety plan provided. Referrals given to outpatient providers."
    Status           = "Resolved"
    ResolutionDate   = "2026-02-24"
    CorrectiveAction = "Follow-up call completed. Client connected with outpatient therapist."
}
Add-ListItemSafe -ListName "Incident Reports" -CheckField "IncidentID" -CheckValue "IR-2026-009" -Values @{
    Title            = "Client Fall — Parking Lot"
    IncidentID       = "IR-2026-009"
    IncidentDate     = "2026-02-18"
    Category         = "Client Fall"
    Severity         = "Low"
    Description      = "Client tripped on uneven pavement in parking lot upon arrival. Minor scrape on knee. First aid administered on-site. Client declined further medical evaluation."
    Status           = "Closed"
    ResolutionDate   = "2026-02-20"
    CorrectiveAction = "Maintenance notified. Pavement repair request submitted to property management."
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. STAFF CREDENTIAL TRACKER (8 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "3/18 — Staff Credential Tracker"
Add-ListItemSafe -ListName "Staff Credential Tracker" -CheckField "StaffName" -CheckValue "J. Martinez" -Values @{
    Title                = "J. Martinez"
    StaffName            = "J. Martinez"
    Role                 = "LPC"
    LicenseNumber        = "LPC-12345"
    LicenseExpiration    = "2026-04-15"
    FingerprintClearance = "2027-06-01"
    CPRExpiration        = "2027-01-15"
    HIPAATrainingDate    = "2025-11-01"
    FWATrainingDate      = "2025-11-01"
    CulturalCompDate     = "2025-09-15"
    TraumaInformedDate   = "2025-10-01"
    SupervisionCurrent   = $false
    CEUsCompleted        = 28
    CEUsRequired         = 40
    Status               = "Expiring Soon"
}
Add-ListItemSafe -ListName "Staff Credential Tracker" -CheckField "StaffName" -CheckValue "S. Thompson" -Values @{
    Title                = "S. Thompson"
    StaffName            = "S. Thompson"
    Role                 = "LISAC"
    LicenseNumber        = "LISAC-67890"
    LicenseExpiration    = "2027-08-30"
    FingerprintClearance = "2027-03-15"
    CPRExpiration        = "2026-12-01"
    HIPAATrainingDate    = "2025-11-01"
    FWATrainingDate      = "2025-11-01"
    CulturalCompDate     = "2025-09-15"
    TraumaInformedDate   = "2025-10-01"
    SupervisionCurrent   = $false
    CEUsCompleted        = 40
    CEUsRequired         = 40
    Status               = "Current"
}
Add-ListItemSafe -ListName "Staff Credential Tracker" -CheckField "StaffName" -CheckValue "R. Davis" -Values @{
    Title                = "R. Davis"
    StaffName            = "R. Davis"
    Role                 = "LCSW"
    LicenseNumber        = "LCSW-24680"
    LicenseExpiration    = "2027-05-20"
    FingerprintClearance = "2027-08-01"
    CPRExpiration        = "2027-02-28"
    HIPAATrainingDate    = "2025-11-01"
    FWATrainingDate      = "2025-11-01"
    CulturalCompDate     = "2025-09-15"
    TraumaInformedDate   = "2025-10-01"
    SupervisionCurrent   = $false
    CEUsCompleted        = 35
    CEUsRequired         = 40
    Status               = "Current"
}
Add-ListItemSafe -ListName "Staff Credential Tracker" -CheckField "StaffName" -CheckValue "A. Nguyen" -Values @{
    Title                = "A. Nguyen"
    StaffName            = "A. Nguyen"
    Role                 = "LAC"
    LicenseNumber        = "LAC-13579"
    LicenseExpiration    = "2027-01-10"
    FingerprintClearance = "2027-04-01"
    CPRExpiration        = "2026-09-30"
    HIPAATrainingDate    = "2025-11-01"
    FWATrainingDate      = "2025-11-01"
    CulturalCompDate     = "2025-09-15"
    TraumaInformedDate   = "2025-10-01"
    SupervisionCurrent   = $false
    CEUsCompleted        = 12
    CEUsRequired         = 24
    Status               = "Action Required"
}
Add-ListItemSafe -ListName "Staff Credential Tracker" -CheckField "StaffName" -CheckValue "D. Robinson" -Values @{
    Title                = "D. Robinson"
    StaffName            = "D. Robinson"
    Role                 = "CPSS"
    LicenseNumber        = "CPSS-99887"
    LicenseExpiration    = "2027-09-15"
    FingerprintClearance = "2027-07-01"
    CPRExpiration        = "2026-11-30"
    HIPAATrainingDate    = "2025-11-01"
    FWATrainingDate      = "2025-11-01"
    CulturalCompDate     = "2025-09-15"
    TraumaInformedDate   = "2025-10-01"
    SupervisionCurrent   = $true
    CEUsCompleted        = 20
    CEUsRequired         = 20
    Status               = "Current"
}
Add-ListItemSafe -ListName "Staff Credential Tracker" -CheckField "StaffName" -CheckValue "K. Patel" -Values @{
    Title                = "K. Patel"
    StaffName            = "K. Patel"
    Role                 = "BHT"
    LicenseNumber        = "BHT-55443"
    LicenseExpiration    = "2027-12-01"
    FingerprintClearance = "2027-05-01"
    CPRExpiration        = "2026-03-31"
    HIPAATrainingDate    = "2025-11-01"
    FWATrainingDate      = "2025-11-01"
    CulturalCompDate     = "2025-09-15"
    TraumaInformedDate   = "2025-10-01"
    SupervisionCurrent   = $true
    CEUsCompleted        = 10
    CEUsRequired         = 20
    Status               = "Expiring Soon"
}
Add-ListItemSafe -ListName "Staff Credential Tracker" -CheckField "StaffName" -CheckValue "M. Reyes" -Values @{
    Title                = "M. Reyes"
    StaffName            = "M. Reyes"
    Role                 = "Clinical Director"
    LicenseNumber        = "LPC-11223"
    LicenseExpiration    = "2028-02-28"
    FingerprintClearance = "2027-10-01"
    CPRExpiration        = "2027-04-15"
    HIPAATrainingDate    = "2025-11-01"
    FWATrainingDate      = "2025-11-01"
    CulturalCompDate     = "2025-09-15"
    TraumaInformedDate   = "2025-10-01"
    SupervisionCurrent   = $false
    CEUsCompleted        = 40
    CEUsRequired         = 40
    Status               = "Current"
}
Add-ListItemSafe -ListName "Staff Credential Tracker" -CheckField "StaffName" -CheckValue "L. Chen" -Values @{
    Title                = "L. Chen"
    StaffName            = "L. Chen"
    Role                 = "Admissions"
    LicenseNumber        = "N/A"
    LicenseExpiration    = "2099-12-31"
    FingerprintClearance = "2027-06-15"
    CPRExpiration        = "2026-08-01"
    HIPAATrainingDate    = "2025-04-01"
    FWATrainingDate      = "2025-11-01"
    CulturalCompDate     = "2025-09-15"
    TraumaInformedDate   = "2025-10-01"
    SupervisionCurrent   = $false
    CEUsCompleted        = 0
    CEUsRequired         = 0
    Status               = "Action Required"
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. CORRECTIVE ACTION PLANS (2 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "4/18 — Corrective Action Plans"
Add-ListItemSafe -ListName "Corrective Action Plans" -CheckField "CAPID" -CheckValue "CAP-2026-003" -Values @{
    Title            = "Documentation deficiency - treatment plans"
    CAPID            = "CAP-2026-003"
    Category         = "Documentation"
    Source           = "Chart Audit"
    OpenDate         = "2026-02-10"
    DueDate          = "2026-03-15"
    Status           = "In Progress"
    RootCause        = "3 of 15 charts reviewed showed treatment plans not updated within the required 30-day review window. Staff reported high caseloads as contributing factor."
    CorrectiveAction = "1) Implemented treatment plan review reminder in EHR. 2) Reduced caseload for affected therapists. 3) Scheduled re-audit for March 15."
}
Add-ListItemSafe -ListName "Corrective Action Plans" -CheckField "CAPID" -CheckValue "CAP-2026-002" -Values @{
    Title            = "Fire drill frequency gap"
    CAPID            = "CAP-2026-002"
    Category         = "Safety"
    Source           = "Fire Marshal"
    OpenDate         = "2026-01-20"
    DueDate          = "2026-02-28"
    Status           = "Pending Verification"
    RootCause        = "Fire drills were conducted quarterly instead of monthly as required by facility license. Calendar oversight — drills were scheduled but not executed in November and December 2025."
    CorrectiveAction = "1) Fire drill calendar updated with monthly schedule. 2) Operations lead assigned as accountable party. 3) Completed make-up drills in January and February. 4) Awaiting Fire Marshal verification."
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. REFERRAL PARTNER TRACKER (8 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "5/18 — Referral Partner Tracker"
Add-ListItemSafe -ListName "Referral Partner Tracker" -CheckField "PartnerName" -CheckValue "Valley Recovery Network" -Values @{
    Title          = "Valley Recovery Network"
    PartnerName    = "Valley Recovery Network"
    PartnerType    = "Sober Living"
    Territory      = "Scottsdale"
    ContactName    = "Sarah Mitchell"
    ContactPhone   = "(480) 555-0142"
    ReferralsMTD   = 12
    AdmitsMTD      = 8
    LastContact    = "2026-02-28"
    AgreementOnFile= $true
    Status         = "Active"
    Notes          = "Strongest referral partner. Bi-weekly check-in calls. Agreement renewed Jan 2026."
}
Add-ListItemSafe -ListName "Referral Partner Tracker" -CheckField "PartnerName" -CheckValue "AZ Crisis Center" -Values @{
    Title          = "AZ Crisis Center"
    PartnerName    = "AZ Crisis Center"
    PartnerType    = "Crisis Services"
    Territory      = "Metro PHX"
    ContactName    = "Carlos Mendez"
    ContactPhone   = "(602) 555-0198"
    ReferralsMTD   = 8
    AdmitsMTD      = 5
    LastContact    = "2026-03-01"
    AgreementOnFile= $true
    Status         = "Active"
    Notes          = "Strong pipeline for crisis step-down to IOP. MOU in place."
}
Add-ListItemSafe -ListName "Referral Partner Tracker" -CheckField "PartnerName" -CheckValue "Mercy Gilbert Medical" -Values @{
    Title          = "Mercy Gilbert Medical"
    PartnerName    = "Mercy Gilbert Medical"
    PartnerType    = "Hospital ED"
    Territory      = "East Valley"
    ContactName    = "Dr. Lisa Park"
    ContactPhone   = "(480) 555-0267"
    ReferralsMTD   = 6
    AdmitsMTD      = 4
    LastContact    = "2026-02-25"
    AgreementOnFile= $true
    Status         = "Active"
    Notes          = "ED social workers familiar with our intake process. Monthly lunch-and-learn scheduled."
}
Add-ListItemSafe -ListName "Referral Partner Tracker" -CheckField "PartnerName" -CheckValue "Banner Thunderbird" -Values @{
    Title          = "Banner Thunderbird"
    PartnerName    = "Banner Thunderbird"
    PartnerType    = "Hospital ED"
    Territory      = "North Phoenix"
    ContactName    = "James Rivera"
    ContactPhone   = "(602) 555-0334"
    ReferralsMTD   = 5
    AdmitsMTD      = 3
    LastContact    = "2026-02-20"
    AgreementOnFile= $true
    Status         = "Active"
    Notes          = "Growing relationship. Facility tour completed Feb 2026."
}
Add-ListItemSafe -ListName "Referral Partner Tracker" -CheckField "PartnerName" -CheckValue "Maricopa Probation" -Values @{
    Title          = "Maricopa Probation"
    PartnerName    = "Maricopa Probation"
    PartnerType    = "Courts/Probation"
    Territory      = "Metro PHX"
    ContactName    = "Officer T. Washington"
    ContactPhone   = "(602) 555-0445"
    ReferralsMTD   = 4
    AdmitsMTD      = 2
    LastContact    = "2026-02-15"
    AgreementOnFile= $true
    Status         = "Active"
    Notes          = "Court-ordered IOP referrals. Progress reports sent bi-weekly."
}
Add-ListItemSafe -ListName "Referral Partner Tracker" -CheckField "PartnerName" -CheckValue "Phoenix Counseling Group" -Values @{
    Title          = "Phoenix Counseling Group"
    PartnerName    = "Phoenix Counseling Group"
    PartnerType    = "Private Therapist"
    Territory      = "Scottsdale"
    ContactName    = "Dr. Amy Goldstein"
    ContactPhone   = "(480) 555-0556"
    ReferralsMTD   = 3
    AdmitsMTD      = 2
    LastContact    = "2026-02-22"
    AgreementOnFile= $true
    Status         = "Active"
    Notes          = "Refers clients needing higher level of care than outpatient."
}
Add-ListItemSafe -ListName "Referral Partner Tracker" -CheckField "PartnerName" -CheckValue "St. Luke's BH" -Values @{
    Title          = "St. Luke's BH"
    PartnerName    = "St. Luke's BH"
    PartnerType    = "Outpatient MDs"
    Territory      = "Tempe"
    ContactName    = "Dr. R. Patel"
    ContactPhone   = "(480) 555-0667"
    ReferralsMTD   = 3
    AdmitsMTD      = 1
    LastContact    = "2026-02-10"
    AgreementOnFile= $true
    Status         = "Follow-Up"
    Notes          = "Low conversion — scheduling follow-up to discuss referral criteria alignment."
}
Add-ListItemSafe -ListName "Referral Partner Tracker" -CheckField "PartnerName" -CheckValue "Oxford House AZ" -Values @{
    Title          = "Oxford House AZ"
    PartnerName    = "Oxford House AZ"
    PartnerType    = "Sober Living"
    Territory      = "East Valley"
    ContactName    = "Mike Torres"
    ContactPhone   = "(480) 555-0778"
    ReferralsMTD   = 2
    AdmitsMTD      = 1
    LastContact    = "2026-03-02"
    AgreementOnFile= $false
    Status         = "New Partner"
    Notes          = "New partnership. Agreement draft in review. Facility tour scheduled March 8."
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. MARKETING CAMPAIGNS (6 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "6/18 — Marketing Campaigns"
Add-ListItemSafe -ListName "Marketing Campaigns" -CheckField "CampaignName" -CheckValue "IOP Awareness - Google" -Values @{
    Title        = "IOP Awareness - Google"
    CampaignName = "IOP Awareness - Google"
    Channel      = "Google Ads"
    SpendMTD     = 2800
    Leads        = 18
    CPL          = 156
    Admits       = 4
    CPA          = 700
    Status       = "Live"
    StartDate    = "2026-01-15"
    Notes        = "Targeting Phoenix metro. Keywords: IOP near me, intensive outpatient Phoenix, behavioral health IOP AZ."
}
Add-ListItemSafe -ListName "Marketing Campaigns" -CheckField "CampaignName" -CheckValue "SEO Content Program" -Values @{
    Title        = "SEO Content Program"
    CampaignName = "SEO Content Program"
    Channel      = "SEO/Organic"
    SpendMTD     = 500
    Leads        = 12
    CPL          = 42
    Admits       = 3
    CPA          = 167
    Status       = "Live"
    StartDate    = "2025-10-01"
    Notes        = "Blog posts, service pages, local SEO. Strongest ROI channel."
}
Add-ListItemSafe -ListName "Marketing Campaigns" -CheckField "CampaignName" -CheckValue "Social - Recovery Stories" -Values @{
    Title        = "Social - Recovery Stories"
    CampaignName = "Social - Recovery Stories"
    Channel      = "Facebook/Instagram"
    SpendMTD     = 1200
    Leads        = 8
    CPL          = 150
    Admits       = 2
    CPA          = 600
    Status       = "Live"
    StartDate    = "2026-02-01"
    Notes        = "De-identified recovery stories with client consent. Strong engagement metrics."
}
Add-ListItemSafe -ListName "Marketing Campaigns" -CheckField "CampaignName" -CheckValue "Partner Referral Program" -Values @{
    Title        = "Partner Referral Program"
    CampaignName = "Partner Referral Program"
    Channel      = "Referral Partners"
    SpendMTD     = 200
    Leads        = 23
    CPL          = 9
    Admits       = 8
    CPA          = 25
    Status       = "Live"
    StartDate    = "2025-06-01"
    Notes        = "Highest volume and best conversion. Costs are collateral/materials only."
}
Add-ListItemSafe -ListName "Marketing Campaigns" -CheckField "CampaignName" -CheckValue "Community Outreach" -Values @{
    Title        = "Community Outreach"
    CampaignName = "Community Outreach"
    Channel      = "Community Events"
    SpendMTD     = 300
    Leads        = 5
    CPL          = 60
    Admits       = 1
    CPA          = 300
    Status       = "Live"
    StartDate    = "2026-01-01"
    Notes        = "NAMI events, community health fairs, church group presentations."
}
Add-ListItemSafe -ListName "Marketing Campaigns" -CheckField "CampaignName" -CheckValue "LegitScript Directory" -Values @{
    Title        = "LegitScript Directory"
    CampaignName = "LegitScript Directory"
    Channel      = "Directories"
    SpendMTD     = 0
    Leads        = 2
    CPL          = 0
    Admits       = 0
    CPA          = 0
    Status       = "Live"
    StartDate    = "2025-08-01"
    Notes        = "LegitScript certification active. Directory listing generates modest organic leads."
}

# ─────────────────────────────────────────────────────────────────────────────
# 7. ADMISSIONS PIPELINE (6 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "7/18 — Admissions Pipeline"
Add-ListItemSafe -ListName "Admissions Pipeline" -CheckField "ReferralID" -CheckValue "REF-2026-048" -Values @{
    Title          = "REF-2026-048"
    ReferralID     = "REF-2026-048"
    ReferralDate   = "2026-02-20"
    Source         = "Hospital ED"
    SourceDetail   = "Mercy Gilbert Medical"
    Insurance      = "AHCCCS Mercy Care"
    Stage          = "Admitted"
    Status         = "Admitted"
    AssessmentDate = "2026-02-22"
    AdmitDate      = "2026-02-24"
    Notes          = "ED discharge referral. Smooth intake process."
}
Add-ListItemSafe -ListName "Admissions Pipeline" -CheckField "ReferralID" -CheckValue "REF-2026-051" -Values @{
    Title          = "REF-2026-051"
    ReferralID     = "REF-2026-051"
    ReferralDate   = "2026-02-25"
    Source         = "Sober Living"
    SourceDetail   = "Valley Recovery Network"
    Insurance      = "AHCCCS UHCCP"
    Stage          = "Admitted"
    Status         = "Admitted"
    AssessmentDate = "2026-02-26"
    AdmitDate      = "2026-02-28"
    Notes          = "Step-up from sober living. Strong motivation."
}
Add-ListItemSafe -ListName "Admissions Pipeline" -CheckField "ReferralID" -CheckValue "REF-2026-055" -Values @{
    Title          = "REF-2026-055"
    ReferralID     = "REF-2026-055"
    ReferralDate   = "2026-03-01"
    Source         = "Self-Referral"
    SourceDetail   = "Website form"
    Insurance      = "BCBS"
    Stage          = "Assessment Scheduled"
    Status         = "Active"
    AssessmentDate = "2026-03-05"
    Notes          = "Assessment scheduled for Wednesday. VOB completed — authorized 30 days."
}
Add-ListItemSafe -ListName "Admissions Pipeline" -CheckField "ReferralID" -CheckValue "REF-2026-056" -Values @{
    Title          = "REF-2026-056"
    ReferralID     = "REF-2026-056"
    ReferralDate   = "2026-03-02"
    Source         = "Crisis Line"
    SourceDetail   = "AZ Crisis Center"
    Insurance      = "AHCCCS Mercy Care"
    Stage          = "VOB In Progress"
    Status         = "Active"
    Notes          = "Crisis step-down. Benefits verification in progress with Mercy Care."
}
Add-ListItemSafe -ListName "Admissions Pipeline" -CheckField "ReferralID" -CheckValue "REF-2026-057" -Values @{
    Title          = "REF-2026-057"
    ReferralID     = "REF-2026-057"
    ReferralDate   = "2026-03-03"
    Source         = "Private Therapist"
    SourceDetail   = "Phoenix Counseling Group"
    Insurance      = "UHC/Optum"
    Stage          = "Pre-Screened"
    Status         = "Active"
    Notes          = "Pre-screen complete. Client presents with co-occurring anxiety and SUD. Moving to VOB."
}
Add-ListItemSafe -ListName "Admissions Pipeline" -CheckField "ReferralID" -CheckValue "REF-2026-049" -Values @{
    Title          = "REF-2026-049"
    ReferralID     = "REF-2026-049"
    ReferralDate   = "2026-02-21"
    Source         = "Probation"
    SourceDetail   = "Maricopa Probation"
    Insurance      = "AHCCCS UHCCP"
    Stage          = "Lost"
    Status         = "Lost"
    Notes          = "Client no-showed twice for assessment. Probation officer notified. Case closed."
}

# ─────────────────────────────────────────────────────────────────────────────
# 8. INSURANCE VERIFICATION TRACKER (5 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "8/18 — Insurance Verification Tracker"
Add-ListItemSafe -ListName "Insurance Verification Tracker" -CheckField "ReferralID" -CheckValue "REF-2026-055" -Values @{
    Title              = "REF-2026-055 — M.K."
    ReferralID         = "REF-2026-055"
    ClientInitials     = "M.K."
    Insurance          = "BCBS"
    VerificationDate   = "2026-03-01"
    AHCCCSEligible     = $false
    CoveredDays        = 30
    Copay              = 25
    PriorAuthRequired  = $false
    PriorAuthStatus    = "Not Required"
    Status             = "Verified"
    Notes              = "BCBS PPO. 30 days IOP authorized. $25 copay per session."
}
Add-ListItemSafe -ListName "Insurance Verification Tracker" -CheckField "ReferralID" -CheckValue "REF-2026-056" -Values @{
    Title              = "REF-2026-056 — T.R."
    ReferralID         = "REF-2026-056"
    ClientInitials     = "T.R."
    Insurance          = "AHCCCS Mercy Care"
    VerificationDate   = "2026-03-02"
    AHCCCSEligible     = $true
    CoveredDays        = 0
    Copay              = 0
    PriorAuthRequired  = $true
    PriorAuthStatus    = "Pending"
    Status             = "Pending"
    Notes              = "AHCCCS eligible. Prior auth submitted to Mercy Care — awaiting response."
}
Add-ListItemSafe -ListName "Insurance Verification Tracker" -CheckField "ReferralID" -CheckValue "REF-2026-057" -Values @{
    Title              = "REF-2026-057 — J.L."
    ReferralID         = "REF-2026-057"
    ClientInitials     = "J.L."
    Insurance          = "UHC/Optum"
    VerificationDate   = "2026-03-03"
    AHCCCSEligible     = $false
    CoveredDays        = 0
    Copay              = 0
    PriorAuthRequired  = $true
    PriorAuthStatus    = "Pending"
    Status             = "Pending"
    Notes              = "VOB in progress. Waiting on Optum response for IOP authorization."
}
Add-ListItemSafe -ListName "Insurance Verification Tracker" -CheckField "ReferralID" -CheckValue "REF-2026-048" -Values @{
    Title              = "REF-2026-048 — A.B."
    ReferralID         = "REF-2026-048"
    ClientInitials     = "A.B."
    Insurance          = "AHCCCS Mercy Care"
    VerificationDate   = "2026-02-20"
    AHCCCSEligible     = $true
    CoveredDays        = 60
    Copay              = 0
    PriorAuthRequired  = $true
    PriorAuthStatus    = "Approved"
    Status             = "Verified"
    Notes              = "Mercy Care auth approved for 60 days IOP. No copay — AHCCCS."
}
Add-ListItemSafe -ListName "Insurance Verification Tracker" -CheckField "ReferralID" -CheckValue "REF-2026-049" -Values @{
    Title              = "REF-2026-049 — C.W."
    ReferralID         = "REF-2026-049"
    ClientInitials     = "C.W."
    Insurance          = "AHCCCS UHCCP"
    VerificationDate   = "2026-02-21"
    AHCCCSEligible     = $true
    CoveredDays        = 0
    Copay              = 0
    PriorAuthRequired  = $true
    PriorAuthStatus    = "Denied"
    Status             = "Issue"
    Notes              = "UHCCP denied prior auth — member not enrolled in BH plan. Eligibility issue flagged."
}

# ─────────────────────────────────────────────────────────────────────────────
# 9. REVENUE TRACKER (8 rows — Feb 2026, one per payer)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "9/18 — Revenue Tracker"
# Total: $218K MTD. Target $250K. 87% pacing.
Add-ListItemSafe -ListName "Revenue Tracker" -Values @{
    Title         = "Feb 2026 — AHCCCS Mercy Care"
    Month         = "2026-02-01"
    Payer         = "AHCCCS Mercy Care"
    Revenue       = 78500
    ClaimCount    = 142
    DenialCount   = 6
    CleanClaimPct = 96
    Notes         = "Largest payer. 6 denials — 3 auth expired, 2 eligibility, 1 coding."
}
Add-ListItemSafe -ListName "Revenue Tracker" -Values @{
    Title         = "Feb 2026 — AHCCCS UHCCP"
    Month         = "2026-02-01"
    Payer         = "AHCCCS UHCCP"
    Revenue       = 52000
    ClaimCount    = 98
    DenialCount   = 4
    CleanClaimPct = 96
    Notes         = "Second largest AHCCCS plan. Clean claim rate holding steady."
}
Add-ListItemSafe -ListName "Revenue Tracker" -Values @{
    Title         = "Feb 2026 — BCBS"
    Month         = "2026-02-01"
    Payer         = "BCBS"
    Revenue       = 34000
    ClaimCount    = 45
    DenialCount   = 2
    CleanClaimPct = 96
    Notes         = "Commercial payer. Higher reimbursement rate per visit."
}
Add-ListItemSafe -ListName "Revenue Tracker" -Values @{
    Title         = "Feb 2026 — UHC/Optum"
    Month         = "2026-02-01"
    Payer         = "UHC/Optum"
    Revenue       = 28000
    ClaimCount    = 38
    DenialCount   = 3
    CleanClaimPct = 92
    Notes         = "Some prior auth delays. Working with Optum liaison."
}
Add-ListItemSafe -ListName "Revenue Tracker" -Values @{
    Title         = "Feb 2026 — Cigna"
    Month         = "2026-02-01"
    Payer         = "Cigna"
    Revenue       = 12500
    ClaimCount    = 18
    DenialCount   = 1
    CleanClaimPct = 94
    Notes         = "Smaller volume. Good clean claim rate."
}
Add-ListItemSafe -ListName "Revenue Tracker" -Values @{
    Title         = "Feb 2026 — Aetna"
    Month         = "2026-02-01"
    Payer         = "Aetna"
    Revenue       = 8000
    ClaimCount    = 12
    DenialCount   = 0
    CleanClaimPct = 100
    Notes         = "Low volume but zero denials."
}
Add-ListItemSafe -ListName "Revenue Tracker" -Values @{
    Title         = "Feb 2026 — Private Pay"
    Month         = "2026-02-01"
    Payer         = "Private Pay"
    Revenue       = 3500
    ClaimCount    = 5
    DenialCount   = 0
    CleanClaimPct = 100
    Notes         = "Self-pay sliding scale clients."
}
Add-ListItemSafe -ListName "Revenue Tracker" -Values @{
    Title         = "Feb 2026 — Other/SCA"
    Month         = "2026-02-01"
    Payer         = "Other/SCA"
    Revenue       = 1500
    ClaimCount    = 3
    DenialCount   = 0
    CleanClaimPct = 100
    Notes         = "State contract / SCA funded slots."
}

# ─────────────────────────────────────────────────────────────────────────────
# 10. COMPLIANCE AUDIT CALENDAR (5 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "10/18 — Compliance Audit Calendar"
Add-ListItemSafe -ListName "Compliance Audit Calendar" -Values @{
    Title     = "Fire Drill"
    AuditDate = "2026-03-10"
    AuditType = "Internal"
    Scope     = "Facility-wide evacuation drill"
    Status    = "Scheduled"
    Notes     = "Monthly fire drill per licensing requirement."
}
Add-ListItemSafe -ListName "Compliance Audit Calendar" -Values @{
    Title     = "Chart Audit - Q1"
    AuditDate = "2026-03-20"
    AuditType = "Chart Audit"
    Scope     = "15 random charts — documentation compliance review"
    Status    = "Scheduled"
    Notes     = "Quarterly chart audit. Focus areas: treatment plan timeliness, progress note quality."
}
Add-ListItemSafe -ListName "Compliance Audit Calendar" -Values @{
    Title     = "AHCCCS Provider Review"
    AuditDate = "2026-04-15"
    AuditType = "AZDHS"
    Scope     = "Full facility review — clinical, operations, billing"
    Status    = "Preparing"
    Notes     = "Annual AHCCCS provider review. Prep checklist started. Mock audit scheduled March 25."
}
Add-ListItemSafe -ListName "Compliance Audit Calendar" -Values @{
    Title     = "Fire Marshal Inspection"
    AuditDate = "2026-04-30"
    AuditType = "Fire Marshal"
    Scope     = "Facility fire safety compliance"
    Status    = "Scheduled"
    Notes     = "Annual inspection. Prior CAP on drill frequency resolved."
}
Add-ListItemSafe -ListName "Compliance Audit Calendar" -Values @{
    Title     = "HIPAA Risk Assessment"
    AuditDate = "2026-05-01"
    AuditType = "HIPAA"
    Scope     = "Organization-wide HIPAA security risk assessment"
    Status    = "Scheduled"
    Notes     = "Annual requirement. Vendor assessment tool selected."
}

# ─────────────────────────────────────────────────────────────────────────────
# 11. GROUP SCHEDULE (10 rows — Mon-Fri, 2 per day)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "11/18 — Group Schedule"
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "CBT Skills Group" -Values @{
    Title           = "CBT Skills Group"
    GroupName       = "CBT Skills Group"
    DayOfWeek       = "Monday"
    TimeSlot        = "9:00 AM - 10:30 AM"
    Facilitator     = "J. Martinez"
    GroupType       = "CBT"
    Room            = "Group Room A"
    MaxParticipants = 12
    Notes           = "Core CBT curriculum. Cognitive distortions, behavioral activation."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "Relapse Prevention Workshop" -Values @{
    Title           = "Relapse Prevention Workshop"
    GroupName       = "Relapse Prevention Workshop"
    DayOfWeek       = "Monday"
    TimeSlot        = "1:00 PM - 2:30 PM"
    Facilitator     = "S. Thompson"
    GroupType       = "Relapse Prevention"
    Room            = "Group Room B"
    MaxParticipants = 12
    Notes           = "Triggers, coping strategies, relapse warning signs."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "DBT Distress Tolerance" -Values @{
    Title           = "DBT Distress Tolerance"
    GroupName       = "DBT Distress Tolerance"
    DayOfWeek       = "Tuesday"
    TimeSlot        = "9:00 AM - 10:30 AM"
    Facilitator     = "R. Davis"
    GroupType       = "DBT"
    Room            = "Group Room A"
    MaxParticipants = 12
    Notes           = "TIPP skills, radical acceptance, distraction techniques."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "Process Group" -Values @{
    Title           = "Process Group"
    GroupName       = "Process Group"
    DayOfWeek       = "Tuesday"
    TimeSlot        = "1:00 PM - 2:30 PM"
    Facilitator     = "J. Martinez"
    GroupType       = "Process"
    Room            = "Group Room A"
    MaxParticipants = 10
    Notes           = "Open process group. Interpersonal skills, peer support."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "Psychoeducation - Mental Health" -Values @{
    Title           = "Psychoeducation - Mental Health"
    GroupName       = "Psychoeducation - Mental Health"
    DayOfWeek       = "Wednesday"
    TimeSlot        = "9:00 AM - 10:30 AM"
    Facilitator     = "M. Reyes"
    GroupType       = "Psychoeducation"
    Room            = "Group Room A"
    MaxParticipants = 15
    Notes           = "Understanding diagnoses, medication education, self-advocacy."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "Mindfulness and Meditation" -Values @{
    Title           = "Mindfulness and Meditation"
    GroupName       = "Mindfulness and Meditation"
    DayOfWeek       = "Wednesday"
    TimeSlot        = "1:00 PM - 2:00 PM"
    Facilitator     = "D. Robinson"
    GroupType       = "Mindfulness"
    Room            = "Outdoor"
    MaxParticipants = 15
    Notes           = "Guided meditation, body scan, mindful breathing. Weather permitting — outdoor."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "CBT for Anxiety" -Values @{
    Title           = "CBT for Anxiety"
    GroupName       = "CBT for Anxiety"
    DayOfWeek       = "Thursday"
    TimeSlot        = "9:00 AM - 10:30 AM"
    Facilitator     = "R. Davis"
    GroupType       = "CBT"
    Room            = "Group Room B"
    MaxParticipants = 12
    Notes           = "Exposure hierarchy, worry management, safety behavior reduction."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "Life Skills and Recovery Planning" -Values @{
    Title           = "Life Skills and Recovery Planning"
    GroupName       = "Life Skills and Recovery Planning"
    DayOfWeek       = "Thursday"
    TimeSlot        = "1:00 PM - 2:30 PM"
    Facilitator     = "D. Robinson"
    GroupType       = "Life Skills"
    Room            = "Group Room A"
    MaxParticipants = 12
    Notes           = "Budgeting, job readiness, housing resources, recovery capital."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "DBT Emotion Regulation" -Values @{
    Title           = "DBT Emotion Regulation"
    GroupName       = "DBT Emotion Regulation"
    DayOfWeek       = "Friday"
    TimeSlot        = "9:00 AM - 10:30 AM"
    Facilitator     = "S. Thompson"
    GroupType       = "DBT"
    Room            = "Group Room A"
    MaxParticipants = 12
    Notes           = "ABC PLEASE, opposite action, emotion identification."
}
Add-ListItemSafe -ListName "Group Schedule" -CheckField "GroupName" -CheckValue "Relapse Prevention - Wrap Up" -Values @{
    Title           = "Relapse Prevention - Wrap Up"
    GroupName       = "Relapse Prevention - Wrap Up"
    DayOfWeek       = "Friday"
    TimeSlot        = "1:00 PM - 2:30 PM"
    Facilitator     = "A. Nguyen"
    GroupType       = "Relapse Prevention"
    Room            = "Group Room B"
    MaxParticipants = 12
    Notes           = "Weekly wrap-up. Review week's learnings, weekend safety planning."
}

# ─────────────────────────────────────────────────────────────────────────────
# 12. GROUP ATTENDANCE LOG (sample — 5 recent entries)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "12/18 — Group Attendance Log"
Add-ListItemSafe -ListName "Group Attendance Log" -Values @{
    Title       = "2026-03-03 CBT Skills Group"
    Date        = "2026-03-03"
    GroupName   = "CBT Skills Group"
    Facilitator = "J. Martinez"
    Attendees   = 10
    Notes       = "Good participation. Covered cognitive restructuring worksheet."
}
Add-ListItemSafe -ListName "Group Attendance Log" -Values @{
    Title       = "2026-03-03 Relapse Prevention Workshop"
    Date        = "2026-03-03"
    GroupName   = "Relapse Prevention Workshop"
    Facilitator = "S. Thompson"
    Attendees   = 8
    Notes       = "2 clients absent — followed up with case managers."
}
Add-ListItemSafe -ListName "Group Attendance Log" -Values @{
    Title       = "2026-02-28 DBT Emotion Regulation"
    Date        = "2026-02-28"
    GroupName   = "DBT Emotion Regulation"
    Facilitator = "S. Thompson"
    Attendees   = 11
    Notes       = "Strong group. Opposite action exercise well received."
}
Add-ListItemSafe -ListName "Group Attendance Log" -Values @{
    Title       = "2026-02-28 Relapse Prevention - Wrap Up"
    Date        = "2026-02-28"
    GroupName   = "Relapse Prevention - Wrap Up"
    Facilitator = "A. Nguyen"
    Attendees   = 9
    Notes       = "Weekend safety plans reviewed for all attendees."
}
Add-ListItemSafe -ListName "Group Attendance Log" -Values @{
    Title       = "2026-02-27 Psychoeducation - Mental Health"
    Date        = "2026-02-27"
    GroupName   = "Psychoeducation - Mental Health"
    Facilitator = "M. Reyes"
    Attendees   = 12
    Notes       = "Topic: Understanding PTSD. Guest speaker from AZ Vets."
}

# ─────────────────────────────────────────────────────────────────────────────
# 13. CLIENT OUTCOMES TRACKER (6 rows — mix of statuses)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "13/18 — Client Outcomes Tracker"
Add-ListItemSafe -ListName "Client Outcomes Tracker" -CheckField "ClientID" -CheckValue "C-2026-001" -Values @{
    Title            = "C-2026-001"
    ClientID         = "C-2026-001"
    AdmitDate        = "2025-12-15"
    DischargeDate    = "2026-02-10"
    PHQ9Intake       = 18
    PHQ9Discharge    = 8
    GAD7Intake       = 15
    GAD7Discharge    = 6
    CompletionStatus = "Successful Completion"
    Notes            = "Significant improvement. Stepped down to outpatient therapy."
}
Add-ListItemSafe -ListName "Client Outcomes Tracker" -CheckField "ClientID" -CheckValue "C-2026-005" -Values @{
    Title            = "C-2026-005"
    ClientID         = "C-2026-005"
    AdmitDate        = "2026-01-06"
    DischargeDate    = "2026-02-28"
    PHQ9Intake       = 22
    PHQ9Discharge    = 12
    GAD7Intake       = 19
    GAD7Discharge    = 10
    CompletionStatus = "Successful Completion"
    Notes            = "Good progress. Continuing outpatient with Dr. Goldstein."
}
Add-ListItemSafe -ListName "Client Outcomes Tracker" -CheckField "ClientID" -CheckValue "C-2026-008" -Values @{
    Title            = "C-2026-008"
    ClientID         = "C-2026-008"
    AdmitDate        = "2026-01-13"
    DischargeDate    = "2026-02-22"
    PHQ9Intake       = 16
    PHQ9Discharge    = 16
    GAD7Intake       = 12
    GAD7Discharge    = 12
    CompletionStatus = "AMA"
    Notes            = "Left AMA day 40. Minimal engagement in groups. Safety plan provided."
}
Add-ListItemSafe -ListName "Client Outcomes Tracker" -CheckField "ClientID" -CheckValue "C-2026-012" -Values @{
    Title            = "C-2026-012"
    ClientID         = "C-2026-012"
    AdmitDate        = "2026-01-20"
    DischargeDate    = "2026-02-05"
    PHQ9Intake       = 24
    PHQ9Discharge    = 24
    GAD7Intake       = 20
    GAD7Discharge    = 20
    CompletionStatus = "Referred Up"
    Notes            = "Symptoms beyond IOP level. Referred to residential treatment."
}
Add-ListItemSafe -ListName "Client Outcomes Tracker" -CheckField "ClientID" -CheckValue "C-2026-015" -Values @{
    Title            = "C-2026-015"
    ClientID         = "C-2026-015"
    AdmitDate        = "2026-02-03"
    DischargeDate    = "2026-02-17"
    PHQ9Intake       = 14
    PHQ9Discharge    = 14
    GAD7Intake       = 11
    GAD7Discharge    = 11
    CompletionStatus = "Administrative"
    Notes            = "Insurance auth expired. Transition planned to outpatient while re-auth pursued."
}
Add-ListItemSafe -ListName "Client Outcomes Tracker" -CheckField "ClientID" -CheckValue "C-2026-018" -Values @{
    Title            = "C-2026-018"
    ClientID         = "C-2026-018"
    AdmitDate        = "2026-02-10"
    DischargeDate    = "2026-03-03"
    PHQ9Intake       = 20
    PHQ9Discharge    = 10
    GAD7Intake       = 17
    GAD7Discharge    = 8
    CompletionStatus = "Successful Completion"
    Notes            = "Excellent engagement. Participated in peer support. Connected with alumni group."
}

# ─────────────────────────────────────────────────────────────────────────────
# 14. TREATMENT PLAN REVIEW DATES (6 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "14/18 — Treatment Plan Review Dates"
Add-ListItemSafe -ListName "Treatment Plan Review Dates" -CheckField "ClientID" -CheckValue "C-2026-020" -Values @{
    Title          = "C-2026-020"
    ClientID       = "C-2026-020"
    Therapist      = "J. Martinez"
    LastReviewDate = "2026-02-24"
    NextReviewDue  = "2026-03-24"
    Status         = "Current"
    Notes          = "Goals updated. Client progressing well."
}
Add-ListItemSafe -ListName "Treatment Plan Review Dates" -CheckField "ClientID" -CheckValue "C-2026-022" -Values @{
    Title          = "C-2026-022"
    ClientID       = "C-2026-022"
    Therapist      = "R. Davis"
    LastReviewDate = "2026-02-20"
    NextReviewDue  = "2026-03-20"
    Status         = "Current"
    Notes          = "On track for step-down to outpatient."
}
Add-ListItemSafe -ListName "Treatment Plan Review Dates" -CheckField "ClientID" -CheckValue "C-2026-025" -Values @{
    Title          = "C-2026-025"
    ClientID       = "C-2026-025"
    Therapist      = "S. Thompson"
    LastReviewDate = "2026-02-10"
    NextReviewDue  = "2026-03-10"
    Status         = "Due This Week"
    Notes          = "Review due March 10. Needs updated substance use goals."
}
Add-ListItemSafe -ListName "Treatment Plan Review Dates" -CheckField "ClientID" -CheckValue "C-2026-027" -Values @{
    Title          = "C-2026-027"
    ClientID       = "C-2026-027"
    Therapist      = "A. Nguyen"
    LastReviewDate = "2026-01-28"
    NextReviewDue  = "2026-02-28"
    Status         = "Overdue"
    Notes          = "OVERDUE — review was due Feb 28. Therapist on PTO last week. Prioritize."
}
Add-ListItemSafe -ListName "Treatment Plan Review Dates" -CheckField "ClientID" -CheckValue "C-2026-030" -Values @{
    Title          = "C-2026-030"
    ClientID       = "C-2026-030"
    Therapist      = "J. Martinez"
    LastReviewDate = "2026-02-28"
    NextReviewDue  = "2026-03-28"
    Status         = "Current"
}
Add-ListItemSafe -ListName "Treatment Plan Review Dates" -CheckField "ClientID" -CheckValue "C-2026-033" -Values @{
    Title          = "C-2026-033"
    ClientID       = "C-2026-033"
    Therapist      = "R. Davis"
    LastReviewDate = "2026-02-05"
    NextReviewDue  = "2026-03-05"
    Status         = "Due This Week"
    Notes          = "Review due March 5. Client showing good progress — may adjust frequency."
}

# ─────────────────────────────────────────────────────────────────────────────
# 15. UDS TRACKING LOG (6 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "15/18 — UDS Tracking Log"
Add-ListItemSafe -ListName "UDS Tracking Log" -Values @{
    Title             = "C-2026-020 — 2026-03-03"
    ClientID          = "C-2026-020"
    TestDate          = "2026-03-03"
    Result            = "Negative"
    SubstanceDetected = ""
    ActionTaken       = "None — negative result."
    Notes             = "Random screen per protocol."
}
Add-ListItemSafe -ListName "UDS Tracking Log" -Values @{
    Title             = "C-2026-022 — 2026-03-03"
    ClientID          = "C-2026-022"
    TestDate          = "2026-03-03"
    Result            = "Negative"
    SubstanceDetected = ""
    ActionTaken       = "None — negative result."
}
Add-ListItemSafe -ListName "UDS Tracking Log" -Values @{
    Title             = "C-2026-025 — 2026-02-28"
    ClientID          = "C-2026-025"
    TestDate          = "2026-02-28"
    Result            = "Positive"
    SubstanceDetected = "THC"
    ActionTaken       = "Clinical discussion with client. Treatment plan updated. No discharge — continued treatment."
    Notes             = "Client disclosed cannabis use. Harm reduction approach per clinical team."
}
Add-ListItemSafe -ListName "UDS Tracking Log" -Values @{
    Title             = "C-2026-027 — 2026-02-28"
    ClientID          = "C-2026-027"
    TestDate          = "2026-02-28"
    Result            = "Refused"
    SubstanceDetected = ""
    ActionTaken       = "Documented refusal. Discussed with clinical team. Client re-engaged next session."
    Notes             = "First refusal. No pattern. Continue monitoring."
}
Add-ListItemSafe -ListName "UDS Tracking Log" -Values @{
    Title             = "C-2026-030 — 2026-03-01"
    ClientID          = "C-2026-030"
    TestDate          = "2026-03-01"
    Result            = "Negative"
    SubstanceDetected = ""
    ActionTaken       = "None — negative result."
}
Add-ListItemSafe -ListName "UDS Tracking Log" -Values @{
    Title             = "C-2026-033 — 2026-03-01"
    ClientID          = "C-2026-033"
    TestDate          = "2026-03-01"
    Result            = "Negative"
    SubstanceDetected = ""
    ActionTaken       = "None — negative result."
    Notes             = "Consistent negative screens since admission."
}

# ─────────────────────────────────────────────────────────────────────────────
# 16. BD VISIT LOG (5 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "16/18 — BD Visit Log"
Add-ListItemSafe -ListName "BD Visit Log" -Values @{
    Title         = "Valley Recovery Network — Feb 28"
    VisitDate     = "2026-02-28"
    PartnerName   = "Valley Recovery Network"
    ContactPerson = "Sarah Mitchell"
    VisitType     = "In-Person"
    Purpose       = "Monthly relationship check-in. Reviewed referral outcomes."
    Outcome       = "Agreement to increase referral volume. New residents oriented to Cholla."
    FollowUpDate  = "2026-03-15"
    Notes         = "Brought updated brochures and outcome data."
}
Add-ListItemSafe -ListName "BD Visit Log" -Values @{
    Title         = "Banner Thunderbird — Feb 20"
    VisitDate     = "2026-02-20"
    PartnerName   = "Banner Thunderbird"
    ContactPerson = "James Rivera"
    VisitType     = "Facility Tour"
    Purpose       = "Facility tour for ED social work team."
    Outcome       = "3 social workers toured facility. Very positive feedback. Expect increased referrals."
    FollowUpDate  = "2026-03-10"
    Notes         = "Provided tour, lunch, and Q&A with clinical team."
}
Add-ListItemSafe -ListName "BD Visit Log" -Values @{
    Title         = "Maricopa Probation — Feb 15"
    VisitDate     = "2026-02-15"
    PartnerName   = "Maricopa Probation"
    ContactPerson = "Officer T. Washington"
    VisitType     = "Virtual"
    Purpose       = "Review client progress reports format and frequency."
    Outcome       = "Agreed on bi-weekly report template. Probation satisfied with compliance data."
    FollowUpDate  = "2026-03-01"
}
Add-ListItemSafe -ListName "BD Visit Log" -Values @{
    Title         = "Oxford House AZ — Mar 2"
    VisitDate     = "2026-03-02"
    PartnerName   = "Oxford House AZ"
    ContactPerson = "Mike Torres"
    VisitType     = "Phone"
    Purpose       = "Initial outreach. Discuss partnership opportunity."
    Outcome       = "Strong interest. Facility tour scheduled for March 8. Agreement draft sent."
    FollowUpDate  = "2026-03-08"
    Notes         = "New partner development. High potential for dual-diagnosis referrals."
}
Add-ListItemSafe -ListName "BD Visit Log" -Values @{
    Title         = "NAMI Phoenix — Feb 25"
    VisitDate     = "2026-02-25"
    PartnerName   = "NAMI Phoenix"
    ContactPerson = "Linda Reeves"
    VisitType     = "Event"
    Purpose       = "NAMI community education event. Cholla booth and presentation."
    Outcome       = "3 warm leads generated. Distributed 50 brochures. Good brand visibility."
    FollowUpDate  = "2026-03-15"
    Notes         = "Next NAMI event March 22. Reserve booth."
}

# ─────────────────────────────────────────────────────────────────────────────
# 17. BD GIFT LOG (4 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "17/18 — BD Gift Log"
Add-ListItemSafe -ListName "BD Gift Log" -Values @{
    Title           = "Valley Recovery Network — Feb 28"
    Date            = "2026-02-28"
    Recipient       = "Sarah Mitchell"
    Organization    = "Valley Recovery Network"
    GiftDescription = "Coffee and pastries for staff meeting"
    Value           = 18.50
    Compliant       = $true
    Notes           = "Under $25 AKS limit. Refreshments for relationship meeting."
}
Add-ListItemSafe -ListName "BD Gift Log" -Values @{
    Title           = "Banner Thunderbird — Feb 20"
    Date            = "2026-02-20"
    Recipient       = "ED Social Work Team"
    Organization    = "Banner Thunderbird"
    GiftDescription = "Catered lunch for facility tour group (6 attendees)"
    Value           = 22.00
    Compliant       = $true
    Notes           = "Per-person cost $22. Under $25 AKS limit. Lunch during tour."
}
Add-ListItemSafe -ListName "BD Gift Log" -Values @{
    Title           = "NAMI Phoenix — Feb 25"
    Date            = "2026-02-25"
    Recipient       = "General public (event)"
    Organization    = "NAMI Phoenix"
    GiftDescription = "Branded pens and stress balls for community event"
    Value           = 2.50
    Compliant       = $true
    Notes           = "Promotional items per unit cost. Community education event."
}
Add-ListItemSafe -ListName "BD Gift Log" -Values @{
    Title           = "Phoenix Counseling Group — Feb 22"
    Date            = "2026-02-22"
    Recipient       = "Dr. Amy Goldstein"
    Organization    = "Phoenix Counseling Group"
    GiftDescription = "Thank-you card with $10 Starbucks gift card"
    Value           = 10.00
    Compliant       = $true
    Notes           = "Appreciation for consistent referrals. Under AKS limit."
}

# ─────────────────────────────────────────────────────────────────────────────
# 18a. PAYROLL TRACKER (8 rows — latest pay period)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "18a/18 — Payroll Tracker"
$payrollStaff = @(
    @{ Name="J. Martinez"; Role="LPC"; Reg=80; OT=0; Pay=4615 },
    @{ Name="S. Thompson"; Role="LISAC"; Reg=80; OT=4; Pay=4200 },
    @{ Name="R. Davis"; Role="LCSW"; Reg=80; OT=0; Pay=4808 },
    @{ Name="A. Nguyen"; Role="LAC"; Reg=80; OT=0; Pay=3077 },
    @{ Name="D. Robinson"; Role="CPSS"; Reg=80; OT=0; Pay=2308 },
    @{ Name="K. Patel"; Role="BHT"; Reg=80; OT=2; Pay=1962 },
    @{ Name="M. Reyes"; Role="Clinical Director"; Reg=80; OT=6; Pay=5769 },
    @{ Name="L. Chen"; Role="Admissions"; Reg=80; OT=0; Pay=2692 }
)
foreach ($s in $payrollStaff) {
    Add-ListItemSafe -ListName "Payroll Tracker" -CheckField "StaffName" -CheckValue $s.Name -Values @{
        Title        = "Feb 16-28 2026 — $($s.Name)"
        PayPeriod    = "Feb 16-28, 2026"
        StaffName    = $s.Name
        Role         = $s.Role
        RegularHours = $s.Reg
        OTHours      = $s.OT
        GrossPay     = $s.Pay
        Status       = "Processed"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 18b. OPEN POSITIONS (2 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "18b/18 — Open Positions"
Add-ListItemSafe -ListName "Open Positions" -CheckField "PositionTitle" -CheckValue "Licensed Therapist (LISAC)" -Values @{
    Title         = "Licensed Therapist (LISAC)"
    PositionTitle = "Licensed Therapist (LISAC)"
    Department    = "Clinical"
    PostedDate    = "2026-02-15"
    Applications  = 12
    Interviews    = 3
    Status        = "Interviewing"
    Notes         = "3 candidates interviewed. Second round scheduled for 2 finalists."
}
Add-ListItemSafe -ListName "Open Positions" -CheckField "PositionTitle" -CheckValue "BHT - Part Time" -Values @{
    Title         = "BHT - Part Time"
    PositionTitle = "BHT - Part Time"
    Department    = "Clinical"
    PostedDate    = "2026-03-01"
    Applications  = 5
    Interviews    = 0
    Status        = "Open"
    Notes         = "Part-time BHT for afternoon groups. Posted to Indeed and AZ BH job boards."
}

# ─────────────────────────────────────────────────────────────────────────────
# 18c. BILLING DENIALS (6 rows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "18c/18 — Billing Denials"
Add-ListItemSafe -ListName "Billing Denials" -CheckField "ClaimID" -CheckValue "CLM-2026-1142" -Values @{
    Title          = "CLM-2026-1142"
    ClaimID        = "CLM-2026-1142"
    Payer          = "AHCCCS Mercy Care"
    DenialDate     = "2026-02-25"
    DenialReason   = "Auth Expired"
    Amount         = 1250
    AppealStatus   = "Appeal Filed"
    AppealDeadline = "2026-03-25"
    Notes          = "Prior auth expired day before service. Re-auth was in progress. Appeal filed with supporting documentation."
}
Add-ListItemSafe -ListName "Billing Denials" -CheckField "ClaimID" -CheckValue "CLM-2026-1098" -Values @{
    Title          = "CLM-2026-1098"
    ClaimID        = "CLM-2026-1098"
    Payer          = "UHC/Optum"
    DenialDate     = "2026-02-20"
    DenialReason   = "Coding Error"
    Amount         = 875
    AppealStatus   = "Won"
    AppealDeadline = "2026-03-20"
    Notes          = "Incorrect modifier on H0015. Corrected and resubmitted. Paid on appeal."
}
Add-ListItemSafe -ListName "Billing Denials" -CheckField "ClaimID" -CheckValue "CLM-2026-1076" -Values @{
    Title          = "CLM-2026-1076"
    ClaimID        = "CLM-2026-1076"
    Payer          = "AHCCCS UHCCP"
    DenialDate     = "2026-02-18"
    DenialReason   = "Eligibility"
    Amount         = 2100
    AppealStatus   = "Appeal Filed"
    AppealDeadline = "2026-03-18"
    Notes          = "Member eligibility lapsed mid-treatment. Working with client to re-enroll."
}
Add-ListItemSafe -ListName "Billing Denials" -CheckField "ClaimID" -CheckValue "CLM-2026-1055" -Values @{
    Title          = "CLM-2026-1055"
    ClaimID        = "CLM-2026-1055"
    Payer          = "AHCCCS Mercy Care"
    DenialDate     = "2026-02-12"
    DenialReason   = "Auth Expired"
    Amount         = 1500
    AppealStatus   = "Lost"
    AppealDeadline = "2026-03-12"
    Notes          = "Auth expired — no extension requested. Appeal denied. Write-off pending."
}
Add-ListItemSafe -ListName "Billing Denials" -CheckField "ClaimID" -CheckValue "CLM-2026-1033" -Values @{
    Title          = "CLM-2026-1033"
    ClaimID        = "CLM-2026-1033"
    Payer          = "BCBS"
    DenialDate     = "2026-02-08"
    DenialReason   = "Medical Necessity"
    Amount         = 1800
    AppealStatus   = "Appeal Filed"
    AppealDeadline = "2026-04-08"
    Notes          = "BCBS denied claiming insufficient documentation of medical necessity. Peer-to-peer review requested."
}
Add-ListItemSafe -ListName "Billing Denials" -CheckField "ClaimID" -CheckValue "CLM-2026-1010" -Values @{
    Title          = "CLM-2026-1010"
    ClaimID        = "CLM-2026-1010"
    Payer          = "Cigna"
    DenialDate     = "2026-02-05"
    DenialReason   = "Duplicate"
    Amount         = 625
    AppealStatus   = "Write-Off"
    AppealDeadline = "2026-03-05"
    Notes          = "Duplicate submission — original claim already paid. Write-off appropriate."
}

# ─────────────────────────────────────────────────────────────────────────────
# 18d. EMPLOYEE TRAINING LOG (sample — 10 rows across staff)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "18d/18 — Employee Training Log"
$trainingEntries = @(
    @{ Staff="J. Martinez"; Training="HIPAA";                  Completed="2025-11-01"; Due="2026-11-01"; Freq="Annual";   Status="Current";   Cert=$true },
    @{ Staff="J. Martinez"; Training="Trauma-Informed Care";   Completed="2025-10-01"; Due="2026-10-01"; Freq="Annual";   Status="Current";   Cert=$true },
    @{ Staff="S. Thompson"; Training="HIPAA";                  Completed="2025-11-01"; Due="2026-11-01"; Freq="Annual";   Status="Current";   Cert=$true },
    @{ Staff="S. Thompson"; Training="CPR/First Aid";          Completed="2025-06-15"; Due="2027-06-15"; Freq="Biennial"; Status="Current";   Cert=$true },
    @{ Staff="A. Nguyen";   Training="HIPAA";                  Completed="2025-11-01"; Due="2026-11-01"; Freq="Annual";   Status="Current";   Cert=$true },
    @{ Staff="A. Nguyen";   Training="CPI De-escalation";      Completed="2025-03-01"; Due="2026-03-01"; Freq="Annual";   Status="Overdue";   Cert=$false },
    @{ Staff="K. Patel";    Training="CPR/First Aid";          Completed="2024-03-31"; Due="2026-03-31"; Freq="Biennial"; Status="Due Soon";  Cert=$true },
    @{ Staff="K. Patel";    Training="QPR Suicide Prevention"; Completed="2025-09-01"; Due="2026-09-01"; Freq="Annual";   Status="Current";   Cert=$true },
    @{ Staff="L. Chen";     Training="HIPAA";                  Completed="2025-04-01"; Due="2026-04-01"; Freq="Annual";   Status="Due Soon";  Cert=$true },
    @{ Staff="L. Chen";     Training="FWA";                    Completed="2025-11-01"; Due="2026-11-01"; Freq="Annual";   Status="Current";   Cert=$true }
)
foreach ($t in $trainingEntries) {
    $label = "$($t.Staff) — $($t.Training)"
    Add-ListItemSafe -ListName "Employee Training Log" -Values @{
        Title             = $label
        StaffName         = $t.Staff
        TrainingName      = $t.Training
        CompletedDate     = $t.Completed
        DueDate           = $t.Due
        Frequency         = $t.Freq
        Status            = $t.Status
        CertificateOnFile = $t.Cert
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Step "SEED DATA COMPLETE"
Write-Host ""
Write-Host "  Census Tracker:            1 row"  -ForegroundColor Green
Write-Host "  Incident Reports:          4 rows" -ForegroundColor Green
Write-Host "  Staff Credential Tracker:  8 rows" -ForegroundColor Green
Write-Host "  Corrective Action Plans:   2 rows" -ForegroundColor Green
Write-Host "  Referral Partner Tracker:  8 rows" -ForegroundColor Green
Write-Host "  Marketing Campaigns:       6 rows" -ForegroundColor Green
Write-Host "  Admissions Pipeline:       6 rows" -ForegroundColor Green
Write-Host "  Insurance Verification:    5 rows" -ForegroundColor Green
Write-Host "  Revenue Tracker:           8 rows" -ForegroundColor Green
Write-Host "  Compliance Audit Calendar: 5 rows" -ForegroundColor Green
Write-Host "  Group Schedule:           10 rows" -ForegroundColor Green
Write-Host "  Group Attendance Log:      5 rows" -ForegroundColor Green
Write-Host "  Client Outcomes Tracker:   6 rows" -ForegroundColor Green
Write-Host "  Treatment Plan Reviews:    6 rows" -ForegroundColor Green
Write-Host "  UDS Tracking Log:          6 rows" -ForegroundColor Green
Write-Host "  BD Visit Log:              5 rows" -ForegroundColor Green
Write-Host "  BD Gift Log:               4 rows" -ForegroundColor Green
Write-Host "  Payroll Tracker:           8 rows" -ForegroundColor Green
Write-Host "  Open Positions:            2 rows" -ForegroundColor Green
Write-Host "  Billing Denials:           6 rows" -ForegroundColor Green
Write-Host "  Employee Training Log:    10 rows" -ForegroundColor Green
Write-Host ""
Write-Host "  TOTAL:                   121 rows" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next step: Run Deploy-ChollaPages.ps1 (Part 2) to create pages with web parts." -ForegroundColor Cyan
Write-Host ""

Disconnect-PnPOnline -ErrorAction SilentlyContinue
