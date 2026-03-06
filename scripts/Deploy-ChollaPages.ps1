<#
.SYNOPSIS
    Cholla IOP Operations Hub — Page Deployment Script (Part 2)

.DESCRIPTION
    Creates all 8 SharePoint modern pages with web parts pre-placed for the
    Cholla Behavioral Health IOP Operations Hub. Run AFTER Deploy-ChollaHub.ps1
    and Seed-ListData.ps1.

    Pages: Home, Director of Operations, Clinical, Admissions, Marketing,
           Business Development, Human Resources, Administration.

    Each page gets Document Library, List, Embed, Power BI, Hero, Quick Links,
    and Text web parts wired to the correct data sources.

.PARAMETER SiteUrl
    Full URL of the deployed hub site.

.PARAMETER EmbedUrlsFile
    Path to embed-urls.json containing KPI dashboard URLs.

.NOTES
    Required: PnP.PowerShell module
    Required: Site provisioned via Deploy-ChollaHub.ps1
    Prepared by Manage AI for Cholla Behavioral Health — March 2026
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://chollabehavioralhealth.sharepoint.com/sites/AIWorkspace",

    [Parameter(Mandatory = $false)]
    [string]$EmbedUrlsFile = ""
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

# ── Load embed URLs ──────────────────────────────────────────────────────────
$defaultEmbedFile = Join-Path $PSScriptRoot "embed-urls.json"
if (-not $EmbedUrlsFile -and (Test-Path $defaultEmbedFile)) {
    $EmbedUrlsFile = $defaultEmbedFile
}
if ($EmbedUrlsFile -and (Test-Path $EmbedUrlsFile)) {
    $embedUrls = Get-Content $EmbedUrlsFile -Raw | ConvertFrom-Json
    Write-Host "  Loaded embed URLs from $EmbedUrlsFile" -ForegroundColor Gray
} else {
    # Placeholders — user replaces after hosting KPI HTML files
    $embedUrls = @{
        director_dashboard   = "https://GITHUB_PAGES_URL/Director-KPIs.html"
        clinical_dashboard   = "https://GITHUB_PAGES_URL/Clinical-KPIs.html"
        admissions_dashboard = "https://GITHUB_PAGES_URL/Admissions-KPIs.html"
        marketing_dashboard  = "https://GITHUB_PAGES_URL/Marketing-KPIs.html"
        bd_dashboard         = "https://GITHUB_PAGES_URL/BD-KPIs.html"
        hr_dashboard         = "https://GITHUB_PAGES_URL/HR-KPIs.html"
        admin_dashboard      = "https://GITHUB_PAGES_URL/Admin-KPIs.html"
        meeting_hub          = "https://GITHUB_PAGES_URL/Meeting-Hub.html"
        training_matrix      = "https://GITHUB_PAGES_URL/Training-Matrix.html"
    }
    Write-Host "  Using placeholder embed URLs — update embed-urls.json later" -ForegroundColor Yellow
}

# ─────────────────────────────────────────────────────────────────────────────
# CONNECT
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Connecting to $SiteUrl"
Connect-PnPOnline -Url $SiteUrl -DeviceLogin -ClientId "dd94791a-e96b-4b44-82ae-ec7de1c3a458" -Tenant "chollabehavioralhealth.onmicrosoft.com"
Write-OK "Connected"

# ─────────────────────────────────────────────────────────────────────────────
# RESOLVE LIST/LIBRARY IDs
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Resolving list and library IDs"

function Get-ListId {
    param([string]$ListName)
    $list = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
    if ($list) {
        Write-OK "  $ListName → $($list.Id)"
        return $list.Id.ToString()
    } else {
        Write-Host "  [WARN] List '$ListName' not found — use placeholder" -ForegroundColor Yellow
        return "00000000-0000-0000-0000-000000000000"
    }
}

$listIds = @{
    CensusTracker              = Get-ListId "Census Tracker"
    IncidentReports            = Get-ListId "Incident Reports"
    StaffCredentialTracker     = Get-ListId "Staff Credential Tracker"
    CorrectiveActionPlans      = Get-ListId "Corrective Action Plans"
    ReferralPartnerTracker     = Get-ListId "Referral Partner Tracker"
    MarketingCampaigns         = Get-ListId "Marketing Campaigns"
    AdmissionsPipeline         = Get-ListId "Admissions Pipeline"
    InsuranceVerification      = Get-ListId "Insurance Verification Tracker"
    RevenueTracker             = Get-ListId "Revenue Tracker"
    ComplianceAuditCalendar    = Get-ListId "Compliance Audit Calendar"
    GroupSchedule              = Get-ListId "Group Schedule"
    GroupAttendanceLog         = Get-ListId "Group Attendance Log"
    ClientOutcomesTracker      = Get-ListId "Client Outcomes Tracker"
    TreatmentPlanReviewDates   = Get-ListId "Treatment Plan Review Dates"
    UDSTrackingLog             = Get-ListId "UDS Tracking Log"
    BDVisitLog                 = Get-ListId "BD Visit Log"
    BDGiftLog                  = Get-ListId "BD Gift Log"
    PayrollTracker             = Get-ListId "Payroll Tracker"
    OpenPositions              = Get-ListId "Open Positions"
    BillingDenials             = Get-ListId "Billing Denials"
    EmployeeTrainingLog        = Get-ListId "Employee Training Log"
    DirectorDocuments          = Get-ListId "Director-Documents"
    ClinicalDocuments          = Get-ListId "Clinical-Documents"
    AdmissionsDocuments        = Get-ListId "Admissions-Documents"
    MarketingDocuments         = Get-ListId "Marketing-Documents"
    BDDocuments                = Get-ListId "BD-Documents"
    HRDocuments                = Get-ListId "HR-Documents"
    AdminDocuments             = Get-ListId "Admin-Documents"
}

# ─────────────────────────────────────────────────────────────────────────────
# WEB PART JSON BUILDERS
# ─────────────────────────────────────────────────────────────────────────────

function Get-ListWebPartJson {
    param([string]$ListId, [string]$ListTitle)
    return @"
{
    "dataVersion": "1.0",
    "serverProcessedContent": {
        "htmlStrings": {},
        "searchablePlainTexts": {},
        "imageSources": {},
        "links": {}
    },
    "properties": {
        "selectedListId": "$ListId",
        "listTitle": "$ListTitle",
        "webRelativeListUrl": "",
        "webpartHeightKey": 4
    }
}
"@
}

function Get-DocLibWebPartJson {
    param([string]$LibraryId, [string]$LibraryTitle)
    return @"
{
    "dataVersion": "1.0",
    "serverProcessedContent": {
        "htmlStrings": {},
        "searchablePlainTexts": {},
        "imageSources": {},
        "links": {}
    },
    "properties": {
        "selectedListId": "$LibraryId",
        "listTitle": "$LibraryTitle",
        "webRelativeListUrl": ""
    }
}
"@
}

function Get-EmbedWebPartJson {
    param([string]$EmbedUrl)
    return @"
{
    "dataVersion": "1.0",
    "serverProcessedContent": {
        "htmlStrings": {},
        "searchablePlainTexts": {},
        "imageSources": {},
        "links": {
            "websiteUrl": "$EmbedUrl"
        }
    },
    "properties": {
        "websiteUrl": "$EmbedUrl",
        "embedCode": "<iframe src='$EmbedUrl' width='100%' height='600' frameborder='0'></iframe>"
    }
}
"@
}

function Get-PowerBIWebPartJson {
    param([string]$ReportUrl = "{POWER_BI_REPORT_URL}")
    return @"
{
    "dataVersion": "1.0",
    "serverProcessedContent": {
        "htmlStrings": {},
        "searchablePlainTexts": {},
        "imageSources": {},
        "links": {}
    },
    "properties": {
        "reportUrl": "$ReportUrl"
    }
}
"@
}

function Get-TextWebPartJson {
    param([string]$HtmlContent)
    $escaped = $HtmlContent -replace '"', '\"' -replace "`n", "" -replace "`r", ""
    return @"
{
    "dataVersion": "1.0",
    "serverProcessedContent": {
        "htmlStrings": {
            "innerHTML": "$escaped"
        },
        "searchablePlainTexts": {},
        "imageSources": {},
        "links": {}
    },
    "properties": {}
}
"@
}

function Get-HeroWebPartJson {
    return @"
{
    "dataVersion": "1.0",
    "serverProcessedContent": {
        "htmlStrings": {},
        "searchablePlainTexts": {},
        "imageSources": {},
        "links": {}
    },
    "properties": {
        "heroLayoutThreshold": 640,
        "carouselLayoutMaxWidth": 639,
        "layoutCategory": 1,
        "layout": 1,
        "content": {
            "title": "Cholla IOP Operations Hub",
            "subTitle": "Cholla Behavioral Health — Intensive Outpatient Program",
            "actions": []
        }
    }
}
"@
}

function Get-QuickLinksWebPartJson {
    param([array]$Links)
    $items = @()
    $idx = 1
    foreach ($link in $Links) {
        $items += @"
{
    "sourceItem": {
        "itemType": 2,
        "fileExtension": "",
        "progId": ""
    },
    "thumbnailType": 2,
    "id": $idx,
    "description": "",
    "altText": "",
    "rawPreviewImageMinCanvasWidth": 32767,
    "title": "$($link.Title)",
    "url": "$($link.Url)",
    "imageUrl": ""
}
"@
        $idx++
    }
    $itemsJson = $items -join ","
    return @"
{
    "dataVersion": "1.0",
    "serverProcessedContent": {
        "htmlStrings": {},
        "searchablePlainTexts": {},
        "imageSources": {},
        "links": {}
    },
    "properties": {
        "items": [$itemsJson],
        "isMigrated": true,
        "layoutId": "CompactCard",
        "shouldShowThumbnail": true,
        "hideWebPartWhenEmpty": true,
        "dataProviderId": "QuickLinks"
    }
}
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# PAGE CREATION HELPER
# ─────────────────────────────────────────────────────────────────────────────

function Ensure-Page {
    param(
        [string]$PageName,
        [string]$Title,
        [string]$LayoutType = "Article"
    )
    $existing = Get-PnPPage -Identity $PageName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Skip "Page '$PageName' exists — removing to rebuild"
        Remove-PnPPage -Identity $PageName -Force -ErrorAction SilentlyContinue
    }
    Add-PnPPage -Name $PageName -Title $Title -LayoutType $LayoutType -ErrorAction Stop | Out-Null
    Write-OK "Created page: $PageName"
}

function Add-WebPartToPage {
    param(
        [string]$PageName,
        [string]$WebPartId,
        [string]$WebPartProperties,
        [int]$Section = 1,
        [int]$Column = 1,
        [int]$Order = 1
    )
    try {
        Add-PnPPageWebPart -Page $PageName `
            -DefaultWebPartType $WebPartId `
            -WebPartProperties ($WebPartProperties | ConvertFrom-Json | ConvertTo-Json -Compress) `
            -Section $Section -Column $Column -Order $Order `
            -ErrorAction Stop | Out-Null
    } catch {
        # Some web parts need the component ID approach
        try {
            Add-PnPPageWebPart -Page $PageName `
                -Component $WebPartId `
                -WebPartProperties ($WebPartProperties | ConvertFrom-Json | ConvertTo-Json -Compress) `
                -Section $Section -Column $Column -Order $Order `
                -ErrorAction Stop | Out-Null
        } catch {
            Write-Host "    [WARN] Could not add web part ($WebPartId) to section $Section col $Column : $_" -ForegroundColor Yellow
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 1: HOME
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Page 1/8 — Home"
Ensure-Page -PageName "Home" -Title "Cholla IOP Operations Hub"

# Section 1: Hero
Add-PnPPageSection -Page "Home" -SectionTemplate OneColumn -Order 1
Add-WebPartToPage -PageName "Home" -WebPartId "Hero" `
    -WebPartProperties (Get-HeroWebPartJson) -Section 1 -Column 1 -Order 1

# Section 2: Quick Links to all departments
Add-PnPPageSection -Page "Home" -SectionTemplate OneColumn -Order 2
$quickLinks = @(
    @{ Title = "Director of Operations"; Url = "$SiteUrl/SitePages/Director-of-Operations.aspx" },
    @{ Title = "Clinical";               Url = "$SiteUrl/SitePages/Clinical-Department.aspx" },
    @{ Title = "Admissions";             Url = "$SiteUrl/SitePages/Admissions-Department.aspx" },
    @{ Title = "Marketing";              Url = "$SiteUrl/SitePages/Marketing-Department.aspx" },
    @{ Title = "Business Development";   Url = "$SiteUrl/SitePages/Business-Development.aspx" },
    @{ Title = "Human Resources";        Url = "$SiteUrl/SitePages/Human-Resources.aspx" },
    @{ Title = "Administration";         Url = "$SiteUrl/SitePages/Administration.aspx" }
)
Add-WebPartToPage -PageName "Home" -WebPartId "QuickLinks" `
    -WebPartProperties (Get-QuickLinksWebPartJson -Links $quickLinks) -Section 2 -Column 1 -Order 1

# Section 3: Welcome text
Add-PnPPageSection -Page "Home" -SectionTemplate OneColumn -Order 3
$welcomeHtml = "<h2>Welcome to the Cholla IOP Operations Hub</h2><p>This hub centralizes all operational data for Cholla Behavioral Health's Intensive Outpatient Program. Use the navigation above or quick links to access department dashboards, documents, and key metrics.</p><p><strong>Key Metrics at a Glance</strong> — Census, compliance, revenue, referrals, and more are tracked in real-time below.</p>"
Add-WebPartToPage -PageName "Home" -WebPartId "Text" `
    -WebPartProperties (Get-TextWebPartJson -HtmlContent $welcomeHtml) -Section 3 -Column 1 -Order 1

# Section 4: Census Tracker
Add-PnPPageSection -Page "Home" -SectionTemplate OneColumn -Order 4
Add-WebPartToPage -PageName "Home" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.CensusTracker -ListTitle "Census Tracker") `
    -Section 4 -Column 1 -Order 1

# Section 5: Two columns — Incidents + Staff Credentials
Add-PnPPageSection -Page "Home" -SectionTemplate TwoColumn -Order 5
Add-WebPartToPage -PageName "Home" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.IncidentReports -ListTitle "Incident Reports") `
    -Section 5 -Column 1 -Order 1
Add-WebPartToPage -PageName "Home" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.StaffCredentialTracker -ListTitle "Staff Credential Tracker") `
    -Section 5 -Column 2 -Order 1

# Section 6: Two columns — Referral Partners + Marketing
Add-PnPPageSection -Page "Home" -SectionTemplate TwoColumn -Order 6
Add-WebPartToPage -PageName "Home" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.ReferralPartnerTracker -ListTitle "Referral Partner Tracker") `
    -Section 6 -Column 1 -Order 1
Add-WebPartToPage -PageName "Home" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.MarketingCampaigns -ListTitle "Marketing Campaigns") `
    -Section 6 -Column 2 -Order 1

# Section 7: Revenue Tracker
Add-PnPPageSection -Page "Home" -SectionTemplate OneColumn -Order 7
Add-WebPartToPage -PageName "Home" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.RevenueTracker -ListTitle "Revenue Tracker") `
    -Section 7 -Column 1 -Order 1

Set-PnPPage -Identity "Home" -Publish -ErrorAction SilentlyContinue
Write-OK "Home page published"

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 2: DIRECTOR OF OPERATIONS
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Page 2/8 — Director of Operations"
Ensure-Page -PageName "Director-of-Operations" -Title "Director of Operations"

# Section 1: KPI Dashboard embed
Add-PnPPageSection -Page "Director-of-Operations" -SectionTemplate OneColumn -Order 1
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.director_dashboard) `
    -Section 1 -Column 1 -Order 1

# Section 2: Power BI
Add-PnPPageSection -Page "Director-of-Operations" -SectionTemplate OneColumn -Order 2
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "544dd15b-cf3c-441b-96da-004d5a8cea1d" `
    -WebPartProperties (Get-PowerBIWebPartJson) -Section 2 -Column 1 -Order 1

# Section 3: Director Documents
Add-PnPPageSection -Page "Director-of-Operations" -SectionTemplate OneColumn -Order 3
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "DocumentLibrary" `
    -WebPartProperties (Get-DocLibWebPartJson -LibraryId $listIds.DirectorDocuments -LibraryTitle "Director-Documents") `
    -Section 3 -Column 1 -Order 1

# Section 4: Two columns — Incidents + Compliance Audit
Add-PnPPageSection -Page "Director-of-Operations" -SectionTemplate TwoColumn -Order 4
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.IncidentReports -ListTitle "Incident Reports") `
    -Section 4 -Column 1 -Order 1
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.ComplianceAuditCalendar -ListTitle "Compliance Audit Calendar") `
    -Section 4 -Column 2 -Order 1

# Section 5: Two columns — Staff Credentials + CAPs
Add-PnPPageSection -Page "Director-of-Operations" -SectionTemplate TwoColumn -Order 5
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.StaffCredentialTracker -ListTitle "Staff Credential Tracker") `
    -Section 5 -Column 1 -Order 1
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.CorrectiveActionPlans -ListTitle "Corrective Action Plans") `
    -Section 5 -Column 2 -Order 1

# Section 6: Referral Partner Tracker
Add-PnPPageSection -Page "Director-of-Operations" -SectionTemplate OneColumn -Order 6
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.ReferralPartnerTracker -ListTitle "Referral Partner Tracker") `
    -Section 6 -Column 1 -Order 1

# Section 7: Meeting Hub embed
Add-PnPPageSection -Page "Director-of-Operations" -SectionTemplate OneColumn -Order 7
Add-WebPartToPage -PageName "Director-of-Operations" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.meeting_hub) `
    -Section 7 -Column 1 -Order 1

Set-PnPPage -Identity "Director-of-Operations" -Publish -ErrorAction SilentlyContinue
Write-OK "Director of Operations page published"

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 3: CLINICAL DEPARTMENT
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Page 3/8 — Clinical Department"
Ensure-Page -PageName "Clinical-Department" -Title "Clinical Department"

# Section 1: KPI Dashboard embed
Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate OneColumn -Order 1
Add-WebPartToPage -PageName "Clinical-Department" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.clinical_dashboard) `
    -Section 1 -Column 1 -Order 1

# Section 2: Group Schedule
Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate OneColumn -Order 2
Add-WebPartToPage -PageName "Clinical-Department" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.GroupSchedule -ListTitle "Group Schedule") `
    -Section 2 -Column 1 -Order 1

# Section 3: Clinical Documents
Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate OneColumn -Order 3
Add-WebPartToPage -PageName "Clinical-Department" -WebPartId "DocumentLibrary" `
    -WebPartProperties (Get-DocLibWebPartJson -LibraryId $listIds.ClinicalDocuments -LibraryTitle "Clinical-Documents") `
    -Section 3 -Column 1 -Order 1

# Section 4: Two columns — Attendance + Outcomes
Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate TwoColumn -Order 4
Add-WebPartToPage -PageName "Clinical-Department" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.GroupAttendanceLog -ListTitle "Group Attendance Log") `
    -Section 4 -Column 1 -Order 1
Add-WebPartToPage -PageName "Clinical-Department" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.ClientOutcomesTracker -ListTitle "Client Outcomes Tracker") `
    -Section 4 -Column 2 -Order 1

# Section 5: Two columns — Treatment Plans + UDS
Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate TwoColumn -Order 5
Add-WebPartToPage -PageName "Clinical-Department" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.TreatmentPlanReviewDates -ListTitle "Treatment Plan Review Dates") `
    -Section 5 -Column 1 -Order 1
Add-WebPartToPage -PageName "Clinical-Department" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.UDSTrackingLog -ListTitle "UDS Tracking Log") `
    -Section 5 -Column 2 -Order 1

Set-PnPPage -Identity "Clinical-Department" -Publish -ErrorAction SilentlyContinue
Write-OK "Clinical Department page published"

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 4: ADMISSIONS DEPARTMENT
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Page 4/8 — Admissions Department"
Ensure-Page -PageName "Admissions-Department" -Title "Admissions Department"

# Section 1: KPI Dashboard embed
Add-PnPPageSection -Page "Admissions-Department" -SectionTemplate OneColumn -Order 1
Add-WebPartToPage -PageName "Admissions-Department" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.admissions_dashboard) `
    -Section 1 -Column 1 -Order 1

# Section 2: Admissions Pipeline
Add-PnPPageSection -Page "Admissions-Department" -SectionTemplate OneColumn -Order 2
Add-WebPartToPage -PageName "Admissions-Department" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.AdmissionsPipeline -ListTitle "Admissions Pipeline") `
    -Section 2 -Column 1 -Order 1

# Section 3: Insurance Verification
Add-PnPPageSection -Page "Admissions-Department" -SectionTemplate OneColumn -Order 3
Add-WebPartToPage -PageName "Admissions-Department" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.InsuranceVerification -ListTitle "Insurance Verification Tracker") `
    -Section 3 -Column 1 -Order 1

# Section 4: Admissions Documents
Add-PnPPageSection -Page "Admissions-Department" -SectionTemplate OneColumn -Order 4
Add-WebPartToPage -PageName "Admissions-Department" -WebPartId "DocumentLibrary" `
    -WebPartProperties (Get-DocLibWebPartJson -LibraryId $listIds.AdmissionsDocuments -LibraryTitle "Admissions-Documents") `
    -Section 4 -Column 1 -Order 1

Set-PnPPage -Identity "Admissions-Department" -Publish -ErrorAction SilentlyContinue
Write-OK "Admissions Department page published"

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 5: MARKETING DEPARTMENT
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Page 5/8 — Marketing Department"
Ensure-Page -PageName "Marketing-Department" -Title "Marketing Department"

# Section 1: KPI Dashboard embed
Add-PnPPageSection -Page "Marketing-Department" -SectionTemplate OneColumn -Order 1
Add-WebPartToPage -PageName "Marketing-Department" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.marketing_dashboard) `
    -Section 1 -Column 1 -Order 1

# Section 2: Marketing Campaigns
Add-PnPPageSection -Page "Marketing-Department" -SectionTemplate OneColumn -Order 2
Add-WebPartToPage -PageName "Marketing-Department" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.MarketingCampaigns -ListTitle "Marketing Campaigns") `
    -Section 2 -Column 1 -Order 1

# Section 3: Marketing Documents
Add-PnPPageSection -Page "Marketing-Department" -SectionTemplate OneColumn -Order 3
Add-WebPartToPage -PageName "Marketing-Department" -WebPartId "DocumentLibrary" `
    -WebPartProperties (Get-DocLibWebPartJson -LibraryId $listIds.MarketingDocuments -LibraryTitle "Marketing-Documents") `
    -Section 3 -Column 1 -Order 1

Set-PnPPage -Identity "Marketing-Department" -Publish -ErrorAction SilentlyContinue
Write-OK "Marketing Department page published"

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 6: BUSINESS DEVELOPMENT
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Page 6/8 — Business Development"
Ensure-Page -PageName "Business-Development" -Title "Business Development"

# Section 1: KPI Dashboard embed
Add-PnPPageSection -Page "Business-Development" -SectionTemplate OneColumn -Order 1
Add-WebPartToPage -PageName "Business-Development" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.bd_dashboard) `
    -Section 1 -Column 1 -Order 1

# Section 2: Referral Partner Tracker
Add-PnPPageSection -Page "Business-Development" -SectionTemplate OneColumn -Order 2
Add-WebPartToPage -PageName "Business-Development" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.ReferralPartnerTracker -ListTitle "Referral Partner Tracker") `
    -Section 2 -Column 1 -Order 1

# Section 3: BD Documents
Add-PnPPageSection -Page "Business-Development" -SectionTemplate OneColumn -Order 3
Add-WebPartToPage -PageName "Business-Development" -WebPartId "DocumentLibrary" `
    -WebPartProperties (Get-DocLibWebPartJson -LibraryId $listIds.BDDocuments -LibraryTitle "BD-Documents") `
    -Section 3 -Column 1 -Order 1

# Section 4: Two columns — Visit Log + Gift Log
Add-PnPPageSection -Page "Business-Development" -SectionTemplate TwoColumn -Order 4
Add-WebPartToPage -PageName "Business-Development" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.BDVisitLog -ListTitle "BD Visit Log") `
    -Section 4 -Column 1 -Order 1
Add-WebPartToPage -PageName "Business-Development" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.BDGiftLog -ListTitle "BD Gift Log") `
    -Section 4 -Column 2 -Order 1

Set-PnPPage -Identity "Business-Development" -Publish -ErrorAction SilentlyContinue
Write-OK "Business Development page published"

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 7: HUMAN RESOURCES
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Page 7/8 — Human Resources"
Ensure-Page -PageName "Human-Resources" -Title "Human Resources"

# Section 1: KPI Dashboard embed
Add-PnPPageSection -Page "Human-Resources" -SectionTemplate OneColumn -Order 1
Add-WebPartToPage -PageName "Human-Resources" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.hr_dashboard) `
    -Section 1 -Column 1 -Order 1

# Section 2: Staff Credential Tracker
Add-PnPPageSection -Page "Human-Resources" -SectionTemplate OneColumn -Order 2
Add-WebPartToPage -PageName "Human-Resources" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.StaffCredentialTracker -ListTitle "Staff Credential Tracker") `
    -Section 2 -Column 1 -Order 1

# Section 3: HR Documents
Add-PnPPageSection -Page "Human-Resources" -SectionTemplate OneColumn -Order 3
Add-WebPartToPage -PageName "Human-Resources" -WebPartId "DocumentLibrary" `
    -WebPartProperties (Get-DocLibWebPartJson -LibraryId $listIds.HRDocuments -LibraryTitle "HR-Documents") `
    -Section 3 -Column 1 -Order 1

# Section 4: Two columns — Open Positions + Payroll
Add-PnPPageSection -Page "Human-Resources" -SectionTemplate TwoColumn -Order 4
Add-WebPartToPage -PageName "Human-Resources" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.OpenPositions -ListTitle "Open Positions") `
    -Section 4 -Column 1 -Order 1
Add-WebPartToPage -PageName "Human-Resources" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.PayrollTracker -ListTitle "Payroll Tracker") `
    -Section 4 -Column 2 -Order 1

# Section 5: Training Matrix embed
Add-PnPPageSection -Page "Human-Resources" -SectionTemplate OneColumn -Order 5
Add-WebPartToPage -PageName "Human-Resources" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.training_matrix) `
    -Section 5 -Column 1 -Order 1

Set-PnPPage -Identity "Human-Resources" -Publish -ErrorAction SilentlyContinue
Write-OK "Human Resources page published"

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 8: ADMINISTRATION
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Page 8/8 — Administration"
Ensure-Page -PageName "Administration" -Title "Administration"

# Section 1: KPI Dashboard embed
Add-PnPPageSection -Page "Administration" -SectionTemplate OneColumn -Order 1
Add-WebPartToPage -PageName "Administration" -WebPartId "490d7c76-1824-45b2-9de3-676421c997fa" `
    -WebPartProperties (Get-EmbedWebPartJson -EmbedUrl $embedUrls.admin_dashboard) `
    -Section 1 -Column 1 -Order 1

# Section 2: Two columns — Payroll + Billing Denials
Add-PnPPageSection -Page "Administration" -SectionTemplate TwoColumn -Order 2
Add-WebPartToPage -PageName "Administration" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.PayrollTracker -ListTitle "Payroll Tracker") `
    -Section 2 -Column 1 -Order 1
Add-WebPartToPage -PageName "Administration" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.BillingDenials -ListTitle "Billing Denials") `
    -Section 2 -Column 2 -Order 1

# Section 3: Compliance Audit Calendar
Add-PnPPageSection -Page "Administration" -SectionTemplate OneColumn -Order 3
Add-WebPartToPage -PageName "Administration" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.ComplianceAuditCalendar -ListTitle "Compliance Audit Calendar") `
    -Section 3 -Column 1 -Order 1

# Section 4: Admin Documents
Add-PnPPageSection -Page "Administration" -SectionTemplate OneColumn -Order 4
Add-WebPartToPage -PageName "Administration" -WebPartId "DocumentLibrary" `
    -WebPartProperties (Get-DocLibWebPartJson -LibraryId $listIds.AdminDocuments -LibraryTitle "Admin-Documents") `
    -Section 4 -Column 1 -Order 1

# Section 5: Employee Training Log
Add-PnPPageSection -Page "Administration" -SectionTemplate OneColumn -Order 5
Add-WebPartToPage -PageName "Administration" -WebPartId "List" `
    -WebPartProperties (Get-ListWebPartJson -ListId $listIds.EmployeeTrainingLog -ListTitle "Employee Training Log") `
    -Section 5 -Column 1 -Order 1

Set-PnPPage -Identity "Administration" -Publish -ErrorAction SilentlyContinue
Write-OK "Administration page published"

# ─────────────────────────────────────────────────────────────────────────────
# SET HOME PAGE
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Setting Home.aspx as site home page"
try {
    Set-PnPHomePage -RootFolderRelativeUrl "SitePages/Home.aspx" -ErrorAction Stop
    Write-OK "Home page set as site landing page"
} catch {
    Write-Skip "Could not set home page: $_"
}

# ─────────────────────────────────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Step "PAGE DEPLOYMENT COMPLETE"
Write-Host ""
Write-Host "  Pages created:" -ForegroundColor Green
Write-Host "    1. Home.aspx                      — Hub landing page" -ForegroundColor Green
Write-Host "    2. Director-of-Operations.aspx     — KPI + docs + lists" -ForegroundColor Green
Write-Host "    3. Clinical-Department.aspx         — Groups + outcomes + docs" -ForegroundColor Green
Write-Host "    4. Admissions-Department.aspx       — Pipeline + VOB + docs" -ForegroundColor Green
Write-Host "    5. Marketing-Department.aspx        — Campaigns + docs" -ForegroundColor Green
Write-Host "    6. Business-Development.aspx        — Partners + visits + gifts" -ForegroundColor Green
Write-Host "    7. Human-Resources.aspx             — Credentials + HR + training" -ForegroundColor Green
Write-Host "    8. Administration.aspx              — Billing + compliance + training" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    1. Host KPI HTML files on GitHub Pages or Azure Blob" -ForegroundColor Cyan
Write-Host "    2. Update scripts/embed-urls.json with real URLs" -ForegroundColor Cyan
Write-Host "    3. Re-run this script or update Embed web parts manually" -ForegroundColor Cyan
Write-Host "    4. Connect Power BI report to Director page" -ForegroundColor Cyan
Write-Host ""

Disconnect-PnPOnline -ErrorAction SilentlyContinue
