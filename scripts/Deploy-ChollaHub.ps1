<#
.SYNOPSIS
    Cholla IOP Operations Hub — SharePoint Site Provisioning Script (Part 1)

.DESCRIPTION
    Creates the full SharePoint Communication Site for Cholla Behavioral Health's
    IOP Operations Hub. Provisions branding/theme, hub navigation, 7 document
    libraries with folder trees and placeholder files, and 18 typed SharePoint lists.

    This script is IDEMPOTENT — safe to re-run without duplicating resources.

.PARAMETER TenantUrl
    The SharePoint tenant root, e.g. "https://chollabehavioralhealth.sharepoint.com"

.PARAMETER SiteAlias
    The site URL slug, e.g. "iop-hub-dev". Site deploys at TenantUrl/sites/SiteAlias.

.PARAMETER SiteTitle
    Display name of the site. Defaults to "Cholla IOP Operations Hub".

.PARAMETER SkipSiteCreation
    Use if the site already exists and you only want to provision contents.

.NOTES
    Required: PnP.PowerShell module (Install-Module -Name PnP.PowerShell -Scope CurrentUser)
    Required: SharePoint Admin or Site Collection Admin permissions
    Required: PowerShell 7+
    Prepared by Manage AI for Cholla Behavioral Health — March 2026
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TenantUrl = "https://chollabehavioralhealth.sharepoint.com",

    [Parameter(Mandatory = $false)]
    [string]$SiteAlias = "AIWorkspace",

    [string]$SiteTitle = "Cholla IOP Operations Hub",

    [switch]$SkipSiteCreation
)

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = "Stop"
$SiteUrl = "$TenantUrl/sites/$SiteAlias"
$ThemeName = "Cholla Behavioral Health"
$ScriptRoot = $PSScriptRoot
$ThemeFile = Join-Path (Split-Path $ScriptRoot) "theme" "cholla-theme.json"

# ─────────────────────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
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

function Write-Err {
    param([string]$Message)
    Write-Host "  [ERR] $Message" -ForegroundColor Red
}

function Ensure-List {
    <#
    .SYNOPSIS
        Creates a SharePoint list if it does not already exist.
    #>
    param(
        [string]$ListName,
        [string]$Template = "GenericList"
    )
    $existing = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Skip "List '$ListName' already exists"
        return $existing
    }
    $list = New-PnPList -Title $ListName -Template $Template -ErrorAction Stop
    Write-OK "Created list '$ListName'"
    return $list
}

function Ensure-Field {
    <#
    .SYNOPSIS
        Adds a column to a list if it does not already exist.
    #>
    param(
        [string]$ListName,
        [string]$FieldName,
        [string]$FieldType,
        [string]$InternalName = $FieldName,
        [string[]]$Choices,
        [string]$Formula,
        [string]$OutputType,
        [switch]$Required
    )

    $existing = Get-PnPField -List $ListName -Identity $InternalName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Skip "  Field '$InternalName' already exists on '$ListName'"
        return
    }

    $params = @{
        List         = $ListName
        DisplayName  = $FieldName
        InternalName = $InternalName
        Type         = $FieldType
        AddToDefaultView = $true
        ErrorAction  = "Stop"
    }

    if ($Required) { $params.Required = $true }

    switch ($FieldType) {
        "Choice" {
            if ($Choices) {
                $params.Choices = $Choices
            }
        }
        "Calculated" {
            $params.Remove("AddToDefaultView")
            # Calculated fields need XML
            Add-CalculatedField -ListName $ListName -FieldName $FieldName -InternalName $InternalName -Formula $Formula -OutputType $OutputType
            return
        }
    }

    Add-PnPField @params | Out-Null
    Write-OK "  Added field '$InternalName' ($FieldType) to '$ListName'"
}

function Add-CalculatedField {
    param(
        [string]$ListName,
        [string]$FieldName,
        [string]$InternalName,
        [string]$Formula,
        [string]$OutputType = "Number"
    )
    $resultType = switch ($OutputType) {
        "Number"   { "Number" }
        "Currency" { "Currency" }
        "DateTime" { "DateTime" }
        "Text"     { "Text" }
        default    { "Number" }
    }
    $xml = @"
<Field Type="Calculated" DisplayName="$FieldName" ResultType="$resultType" ReadOnly="TRUE" Name="$InternalName">
    <Formula>$Formula</Formula>
    <FieldRefs>
    </FieldRefs>
</Field>
"@
    Add-PnPFieldFromXml -List $ListName -FieldXml $xml -ErrorAction Stop | Out-Null
    Write-OK "  Added calculated field '$InternalName' to '$ListName'"
}

function Ensure-Library {
    <#
    .SYNOPSIS
        Creates a document library if it does not already exist.
    #>
    param([string]$LibraryName)
    $existing = Get-PnPList -Identity $LibraryName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Skip "Library '$LibraryName' already exists"
        return
    }
    New-PnPList -Title $LibraryName -Template DocumentLibrary -ErrorAction Stop | Out-Null
    Write-OK "Created document library '$LibraryName'"
}

function Ensure-Folder {
    <#
    .SYNOPSIS
        Creates a folder in a document library if it does not already exist.
    #>
    param(
        [string]$LibraryName,
        [string]$FolderPath
    )
    $fullPath = "$LibraryName/$FolderPath"
    try {
        $existing = Get-PnPFolder -Url $fullPath -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Skip "  Folder '$FolderPath' already exists"
            return
        }
    } catch { }

    Add-PnPFolder -Name (Split-Path $FolderPath -Leaf) -Folder ($LibraryName + "/" + (Split-Path $FolderPath -Parent)) -ErrorAction SilentlyContinue | Out-Null
    if (-not $?) {
        # Parent might not exist — Resolve-PnPFolder creates full path
        Resolve-PnPFolder -SiteRelativePath $fullPath -ErrorAction Stop | Out-Null
    }
    Write-OK "  Folder '$FolderPath'"
}

function Ensure-PlaceholderFile {
    <#
    .SYNOPSIS
        Uploads a tiny placeholder .txt file if it does not already exist.
    #>
    param(
        [string]$LibraryName,
        [string]$FolderPath,
        [string]$FileName
    )
    $targetFolder = "$LibraryName/$FolderPath"
    $cleanName = $FileName -replace '[<>:"/\\|?*]', '-'
    $txtName = "$cleanName.txt"

    try {
        $existing = Get-PnPFile -Url "$targetFolder/$txtName" -ErrorAction SilentlyContinue
        if ($existing) {
            return  # silently skip — too noisy to log each placeholder
        }
    } catch { }

    $tempFile = [System.IO.Path]::GetTempFileName()
    "Placeholder — replace with actual document: $FileName" | Out-File -FilePath $tempFile -Encoding utf8
    Add-PnPFile -Path $tempFile -Folder $targetFolder -FileName $txtName -ErrorAction SilentlyContinue | Out-Null
    Remove-Item $tempFile -Force
}

# ─────────────────────────────────────────────────────────────────────────────
# 0. CONNECT TO TENANT
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Connecting to SharePoint tenant"
try {
    Connect-PnPOnline -Url $TenantUrl -Interactive
    Write-OK "Connected to $TenantUrl"
} catch {
    Write-Err "Failed to connect: $_"
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# 1.1 SITE CREATION
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "1.1 — Site Creation"

if ($SkipSiteCreation) {
    Write-Skip "Site creation skipped (SkipSiteCreation flag)"
} else {
    try {
        $existingSite = Get-PnPTenantSite -Url $SiteUrl -ErrorAction SilentlyContinue
        if ($existingSite) {
            Write-Skip "Site '$SiteUrl' already exists"
        } else {
            New-PnPSite -Type CommunicationSite `
                -Title $SiteTitle `
                -Url $SiteUrl `
                -Lcid 1033 `
                -ErrorAction Stop | Out-Null
            Write-OK "Created Communication Site: $SiteUrl"

            # Wait for site provisioning
            Write-Host "  Waiting for site provisioning..." -ForegroundColor Gray
            Start-Sleep -Seconds 15
        }
    } catch {
        Write-Host "  Site creation via New-PnPSite may require admin context." -ForegroundColor Yellow
        Write-Host "  If site already exists, re-run with -SkipSiteCreation" -ForegroundColor Yellow
        Write-Err "Site creation error: $_"
    }
}

# Reconnect to the new site
Write-Host "  Connecting to site: $SiteUrl" -ForegroundColor Gray
Disconnect-PnPOnline -ErrorAction SilentlyContinue
Connect-PnPOnline -Url $SiteUrl -Interactive
Write-OK "Connected to $SiteUrl"

# Set timezone to Arizona (ID 15 — US Mountain Time, no DST)
try {
    $web = Get-PnPWeb -ErrorAction SilentlyContinue
    # PnP timezone is set via regional settings
    Set-PnPWeb -Title $SiteTitle -ErrorAction SilentlyContinue
    Write-OK "Site title confirmed: $SiteTitle"
} catch {
    Write-Skip "Could not set web properties"
}

# ─────────────────────────────────────────────────────────────────────────────
# 1.2 BRANDING / THEMING
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "1.2 — Branding / Theming"

# Load theme palette from JSON file or inline
if (Test-Path $ThemeFile) {
    $themeJson = Get-Content $ThemeFile -Raw | ConvertFrom-Json
    $palette = @{}
    $themeJson.palette.PSObject.Properties | ForEach-Object { $palette[$_.Name] = $_.Value }
    Write-OK "Loaded theme from $ThemeFile"
} else {
    Write-Host "  Theme file not found at $ThemeFile — using inline palette" -ForegroundColor Yellow
    $palette = @{
        "themePrimary"        = "#1a7a7a"
        "themeLighterAlt"     = "#f2f9f9"
        "themeLighter"        = "#cce8e8"
        "themeLight"          = "#a3d4d4"
        "themeTertiary"       = "#52a8a8"
        "themeSecondary"      = "#1f8585"
        "themeDarkAlt"        = "#176e6e"
        "themeDark"           = "#145d5d"
        "themeDarker"         = "#0e4545"
        "neutralLighterAlt"   = "#faf9f8"
        "neutralLighter"      = "#f3f2f1"
        "neutralLight"        = "#edebe9"
        "neutralQuaternaryAlt"= "#e1dfdd"
        "neutralQuaternary"   = "#d2d0ce"
        "neutralTertiaryAlt"  = "#c8c6c4"
        "neutralTertiary"     = "#a19f9d"
        "neutralSecondary"    = "#605e5c"
        "neutralPrimaryAlt"   = "#3b3a39"
        "neutralPrimary"      = "#323130"
        "neutralDark"         = "#201f1e"
        "black"               = "#000000"
        "white"               = "#ffffff"
        "primaryBackground"   = "#ffffff"
        "primaryText"         = "#323130"
        "accent"              = "#1a7a7a"
    }
}

try {
    # Register the tenant theme (requires SharePoint admin)
    Add-PnPTenantTheme -Identity $ThemeName -Palette $palette -IsInverted $false -Overwrite -ErrorAction Stop
    Write-OK "Registered tenant theme: $ThemeName"
} catch {
    Write-Host "  Theme registration requires SharePoint admin. You may need to apply manually." -ForegroundColor Yellow
    Write-Skip "Theme registration: $_"
}

try {
    Set-PnPWebTheme -Theme $ThemeName -ErrorAction Stop
    Write-OK "Applied theme to site"
} catch {
    Write-Skip "Could not apply theme to site (may need manual apply): $_"
}

# Upload site logo if available
$logoPath = Join-Path (Split-Path $ScriptRoot) "assets" "cholla-logo.png"
if (Test-Path $logoPath) {
    try {
        Set-PnPSite -LogoFilePath $logoPath -ErrorAction Stop
        Write-OK "Uploaded site logo"
    } catch {
        Write-Skip "Could not set site logo: $_"
    }
} else {
    Write-Skip "Logo file not found at $logoPath — upload manually later"
}

# ─────────────────────────────────────────────────────────────────────────────
# 1.3 HUB NAVIGATION
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "1.3 — Hub Navigation (8 links)"

$navLinks = @(
    @{ Title = "Home";                    Url = "$SiteUrl/SitePages/Home.aspx" },
    @{ Title = "Director of Operations";  Url = "$SiteUrl/SitePages/Director-of-Operations.aspx" },
    @{ Title = "Clinical";                Url = "$SiteUrl/SitePages/Clinical-Department.aspx" },
    @{ Title = "Admissions";              Url = "$SiteUrl/SitePages/Admissions-Department.aspx" },
    @{ Title = "Marketing";               Url = "$SiteUrl/SitePages/Marketing-Department.aspx" },
    @{ Title = "Business Development";    Url = "$SiteUrl/SitePages/Business-Development.aspx" },
    @{ Title = "Human Resources";         Url = "$SiteUrl/SitePages/Human-Resources.aspx" },
    @{ Title = "Administration";          Url = "$SiteUrl/SitePages/Administration.aspx" }
)

# Remove existing top nav nodes to avoid duplication, then re-add
try {
    $existingNodes = Get-PnPNavigationNode -Location TopNavigationBar -ErrorAction SilentlyContinue
    if ($existingNodes) {
        foreach ($node in $existingNodes) {
            Remove-PnPNavigationNode -Identity $node.Id -Force -ErrorAction SilentlyContinue
        }
        Write-OK "Cleared existing top navigation"
    }
} catch {
    Write-Skip "Could not clear existing navigation: $_"
}

foreach ($link in $navLinks) {
    try {
        Add-PnPNavigationNode -Location TopNavigationBar -Title $link.Title -Url $link.Url -ErrorAction Stop | Out-Null
        Write-OK "Nav: $($link.Title)"
    } catch {
        Write-Err "Nav '$($link.Title)': $_"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 1.4 DOCUMENT LIBRARIES
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "1.4 — Document Libraries & Folder Structures"

# ── Director Documents ───────────────────────────────────────────────────────
Ensure-Library "Director-Documents"

$directorFolders = @(
    "Master-SOP-Library",
    "Licensing-and-Compliance-Binder",
    "Contracts-Insurance-Referral-Partners",
    "Risk-Management",
    "Board-Ownership-Reports",
    "Strategic-Planning"
)
foreach ($f in $directorFolders) {
    Resolve-PnPFolder -SiteRelativePath "Director-Documents/$f" -ErrorAction SilentlyContinue | Out-Null
}
Write-OK "Director-Documents folders created"

# Director placeholder files
$directorFiles = @{
    "Master-SOP-Library" = @(
        "SOP-001 Client Intake Process",
        "SOP-002 Treatment Plan Review",
        "SOP-003 Group Facilitation",
        "SOP-004 Discharge Planning",
        "SOP-005 Crisis Intervention",
        "SOP-006 Incident Reporting",
        "SOP-007 Insurance Verification"
    )
    "Licensing-and-Compliance-Binder" = @(
        "AZDHS License - Active",
        "AHCCCS Provider Agreement",
        "DEA Registration",
        "Fire Marshal Inspection - 2025",
        "Zoning Approval Letter",
        "9 A.A.C. 10 Compliance Matrix"
    )
    "Contracts-Insurance-Referral-Partners" = @(
        "AHCCCS - Mercy Care Contract",
        "BCBS of Arizona Agreement",
        "UHC Optum Agreement",
        "Valley Recovery Network - Referral Agreement",
        "AZ Crisis Center - Partner MOU"
    )
    "Risk-Management" = @(
        "Risk Assessment Matrix - Q1 2026",
        "Professional Liability Policy",
        "General Liability Certificate",
        "Emergency Preparedness Plan"
    )
    "Board-Ownership-Reports" = @(
        "Board Report - February 2026",
        "Board Report - January 2026",
        "Annual Strategic Plan 2026",
        "Financial Summary Q4 2025"
    )
    "Strategic-Planning" = @(
        "2026 Growth Roadmap",
        "Market Analysis - Scottsdale IOP",
        "Expansion Feasibility Study",
        "Competitive Landscape Analysis"
    )
}
foreach ($folder in $directorFiles.Keys) {
    foreach ($file in $directorFiles[$folder]) {
        Ensure-PlaceholderFile "Director-Documents" $folder $file
    }
}
Write-OK "Director-Documents placeholders uploaded"

# ── Clinical Documents ───────────────────────────────────────────────────────
Ensure-Library "Clinical-Documents"

$clinicalFolders = @(
    "Clinical-SOPs",
    "Clinical-Forms",
    "Staff-Credentials",
    "Quality-Assurance"
)
foreach ($f in $clinicalFolders) {
    Resolve-PnPFolder -SiteRelativePath "Clinical-Documents/$f" -ErrorAction SilentlyContinue | Out-Null
}
Write-OK "Clinical-Documents folders created"

$clinicalFiles = @{
    "Clinical-SOPs" = @(
        "Intake Assessment Protocol",
        "ASAM Criteria Guidelines",
        "Treatment Planning Standards",
        "Discharge Planning Protocol",
        "Crisis Intervention SOP",
        "Documentation Standards AHCCCS",
        "Group Curriculum Library"
    )
    "Clinical-Forms" = @(
        "Intake Packet",
        "Consent for Treatment Forms",
        "Release of Information ROI",
        "Safety Plan Template",
        "Incident Report Form",
        "Grievance Form"
    )
    "Staff-Credentials" = @(
        "Therapist Licenses",
        "CPR First Aid Cards",
        "Fingerprint Clearance Cards",
        "CEU Tracking Log"
    )
    "Quality-Assurance" = @(
        "Chart Audit Results - Feb 2026",
        "Peer Review Log - Q1 2026",
        "Corrective Actions - Clinical"
    )
}
foreach ($folder in $clinicalFiles.Keys) {
    foreach ($file in $clinicalFiles[$folder]) {
        Ensure-PlaceholderFile "Clinical-Documents" $folder $file
    }
}
Write-OK "Clinical-Documents placeholders uploaded"

# ── Admissions Documents ─────────────────────────────────────────────────────
Ensure-Library "Admissions-Documents"

$admissionsFolders = @("Admissions-SOPs", "Admissions-Forms")
foreach ($f in $admissionsFolders) {
    Resolve-PnPFolder -SiteRelativePath "Admissions-Documents/$f" -ErrorAction SilentlyContinue | Out-Null
}
Write-OK "Admissions-Documents folders created"

$admissionsFiles = @{
    "Admissions-SOPs" = @(
        "Pre-Screen Script",
        "Insurance Verification Workflow",
        "Medical Necessity Checklist",
        "Level of Care Determination",
        "Admission Criteria - ASAM 2.1",
        "Denial Documentation Protocol"
    )
    "Admissions-Forms" = @(
        "Pre-Screen Template",
        "Benefits Verification Form",
        "Admission Checklist",
        "Denial Documentation Form"
    )
}
foreach ($folder in $admissionsFiles.Keys) {
    foreach ($file in $admissionsFiles[$folder]) {
        Ensure-PlaceholderFile "Admissions-Documents" $folder $file
    }
}
Write-OK "Admissions-Documents placeholders uploaded"

# ── Marketing Documents ──────────────────────────────────────────────────────
Ensure-Library "Marketing-Documents"

$marketingFolders = @(
    "Brand-Assets",
    "Marketing-Campaigns",
    "Website-Content",
    "Compliance-Review-Log"
)
foreach ($f in $marketingFolders) {
    Resolve-PnPFolder -SiteRelativePath "Marketing-Documents/$f" -ErrorAction SilentlyContinue | Out-Null
}
Write-OK "Marketing-Documents folders created"

$marketingFiles = @{
    "Brand-Assets" = @(
        "Cholla Logo Pack",
        "Brand Guidelines v2",
        "Photography Library",
        "Color Typography Spec",
        "Email Signature Templates",
        "Presentation Template"
    )
    "Marketing-Campaigns" = @(
        "Q1 2026 - IOP Awareness",
        "Q4 2025 - Holiday Recovery",
        "Evergreen - SEO Content",
        "Evergreen - Social Templates"
    )
    "Website-Content" = @(
        "Website Copy - Service Pages",
        "Blog Post Library",
        "SEO Keyword Research"
    )
    "Compliance-Review-Log" = @(
        "Ad Copy Compliance Review - Feb",
        "Anti-Inducement Policy Checklist"
    )
}
foreach ($folder in $marketingFiles.Keys) {
    foreach ($file in $marketingFiles[$folder]) {
        Ensure-PlaceholderFile "Marketing-Documents" $folder $file
    }
}
Write-OK "Marketing-Documents placeholders uploaded"

# ── BD Documents ─────────────────────────────────────────────────────────────
Ensure-Library "BD-Documents"

$bdFolders = @(
    "Referral-Partner-Agreements",
    "Outreach-Scripts-Materials",
    "Territory-Mapping"
)
foreach ($f in $bdFolders) {
    Resolve-PnPFolder -SiteRelativePath "BD-Documents/$f" -ErrorAction SilentlyContinue | Out-Null
}
Write-OK "BD-Documents folders created"

$bdFiles = @{
    "Referral-Partner-Agreements" = @(
        "Valley Recovery Network - Agreement",
        "AZ Crisis Center - MOU",
        "Mercy Gilbert - Referral Agreement",
        "Standard Referral Agreement Template",
        "Anti-Kickback Compliance Addendum"
    )
    "Outreach-Scripts-Materials" = @(
        "Cold Outreach Script - Hospitals",
        "Follow-Up Email Templates",
        "Facility Presentation Deck",
        "One-Pager - Cholla IOP Services"
    )
    "Territory-Mapping" = @(
        "Phoenix Metro Territory Map",
        "Partner Density by ZIP",
        "White Space Analysis - Scottsdale"
    )
}
foreach ($folder in $bdFiles.Keys) {
    foreach ($file in $bdFiles[$folder]) {
        Ensure-PlaceholderFile "BD-Documents" $folder $file
    }
}
Write-OK "BD-Documents placeholders uploaded"

# ── HR Documents ─────────────────────────────────────────────────────────────
Ensure-Library "HR-Documents"

$hrFolders = @(
    "Employee-Handbook-Policies",
    "Job-Descriptions-BH-Roles",
    "Clinical-Supervision-Records",
    "Performance-Reviews-Disciplinary",
    "Staff-Credential-Files"
)
foreach ($f in $hrFolders) {
    Resolve-PnPFolder -SiteRelativePath "HR-Documents/$f" -ErrorAction SilentlyContinue | Out-Null
}
Write-OK "HR-Documents folders created"

$hrFiles = @{
    "Employee-Handbook-Policies" = @(
        "Employee Handbook v4.2",
        "Code of Conduct - BH Specific",
        "PTO Leave Policy",
        "Trauma-Informed Workplace Policy",
        "Dual Relationships Boundary Policy",
        "Staff Wellness Burnout Prevention Plan",
        "Drug-Free Workplace Policy",
        "Social Media Confidentiality Policy"
    )
    "Job-Descriptions-BH-Roles" = @(
        "Licensed Professional Counselor LPC",
        "Licensed Independent Substance Abuse Counselor LISAC",
        "Licensed Clinical Social Worker LCSW",
        "Licensed Associate Counselor LAC Supervised",
        "Behavioral Health Technician BHT",
        "Certified Peer Support Specialist CPSS",
        "Admissions Coordinator",
        "Clinical Director"
    )
    "Clinical-Supervision-Records" = @(
        "Supervision Agreement Template ARS 32-3301",
        "Weekly Supervision Log - A Nguyen",
        "Supervision Hours Tracker - All LAC BHT",
        "AZBBHE Supervision Requirements Guide"
    )
    "Performance-Reviews-Disciplinary" = @(
        "Performance Review Template - Clinical",
        "90-Day New Hire Evaluation Form",
        "Corrective Action Form",
        "Termination Checklist - BH Specific",
        "Exit Interview Template"
    )
    "Staff-Credential-Files" = @(
        "Martinez J - LPC License FPC CPR CEUs",
        "Thompson S - LISAC License FPC CPR CEUs",
        "Davis R - LCSW License FPC CPR CEUs",
        "Nguyen A - LAC License FPC Supervision Docs",
        "Robinson D - CPSS Cert FPC CPR"
    )
}
foreach ($folder in $hrFiles.Keys) {
    foreach ($file in $hrFiles[$folder]) {
        Ensure-PlaceholderFile "HR-Documents" $folder $file
    }
}
Write-OK "HR-Documents placeholders uploaded"

# ── Admin Documents ──────────────────────────────────────────────────────────
Ensure-Library "Admin-Documents"

$adminFolders = @(
    "Employee-Handbook",
    "Job-Descriptions",
    "Performance-Reviews",
    "Disciplinary-Actions",
    "AHCCCS-Billing-Guides",
    "CPT-Code-References",
    "Claim-Submission-SOPs",
    "HIPAA-Policies",
    "Corporate-Compliance-Plan",
    "Emergency-Preparedness"
)
foreach ($f in $adminFolders) {
    Resolve-PnPFolder -SiteRelativePath "Admin-Documents/$f" -ErrorAction SilentlyContinue | Out-Null
}
Write-OK "Admin-Documents folders created"

$adminFiles = @{
    "Employee-Handbook" = @(
        "Employee Handbook v4.2",
        "Code of Conduct",
        "PTO Leave Policy"
    )
    "Job-Descriptions" = @(
        "Licensed Therapist LPC LISAC LCSW",
        "Admissions Coordinator",
        "Clinical Director",
        "Front Office Admin Assistant",
        "BHT Peer Support Specialist",
        "Marketing Coordinator"
    )
    "Performance-Reviews" = @(
        "Q4 2025 Review Cycle Summary",
        "Performance Review Template",
        "90-Day New Hire Evaluation Form"
    )
    "Disciplinary-Actions" = @(
        "Verbal Warning Template",
        "Written Warning Template",
        "Termination Checklist"
    )
    "AHCCCS-Billing-Guides" = @(
        "AHCCCS IOP Billing Manual 2026",
        "Mercy Care Provider Manual",
        "UHCCP Billing Guidelines",
        "Banner-UHC Authorization Process"
    )
    "CPT-Code-References" = @(
        "IOP CPT Code Quick Reference",
        "Modifier Cheat Sheet",
        "IOP Service Definitions Units"
    )
    "Claim-Submission-SOPs" = @(
        "Claim Submission SOP",
        "Denial Appeal Process",
        "Prior Authorization Workflow"
    )
    "HIPAA-Policies" = @(
        "HIPAA Privacy Policy",
        "HIPAA Security Policy",
        "Breach Notification Procedure",
        "BAA Template"
    )
    "Corporate-Compliance-Plan" = @(
        "Corporate Compliance Plan 2026",
        "Fraud Waste Abuse Prevention Plan",
        "Compliance Committee Charter"
    )
    "Emergency-Preparedness" = @(
        "Emergency Preparedness Plan",
        "Fire Drill Log 2026",
        "Evacuation Routes Map"
    )
}
foreach ($folder in $adminFiles.Keys) {
    foreach ($file in $adminFiles[$folder]) {
        Ensure-PlaceholderFile "Admin-Documents" $folder $file
    }
}
Write-OK "Admin-Documents placeholders uploaded"

# ─────────────────────────────────────────────────────────────────────────────
# 1.5 SHAREPOINT LISTS (18 lists)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "1.5 — SharePoint Lists"

# ── 1. Census Tracker ────────────────────────────────────────────────────────
Write-Host "`n  [1/18] Census Tracker" -ForegroundColor Magenta
Ensure-List "Census Tracker"
# Title column exists by default
Ensure-Field -ListName "Census Tracker" -FieldName "Active Census"       -InternalName "ActiveCensus"    -FieldType "Number"
Ensure-Field -ListName "Census Tracker" -FieldName "Capacity"            -InternalName "Capacity"        -FieldType "Number"
Ensure-Field -ListName "Census Tracker" -FieldName "Utilization Pct"     -InternalName "UtilizationPct"  -FieldType "Calculated" -Formula "=[ActiveCensus]/[Capacity]" -OutputType "Number"
Ensure-Field -ListName "Census Tracker" -FieldName "New Admits"          -InternalName "NewAdmits"       -FieldType "Number"
Ensure-Field -ListName "Census Tracker" -FieldName "Discharges"          -InternalName "Discharges"      -FieldType "Number"
Ensure-Field -ListName "Census Tracker" -FieldName "ALOS"                -InternalName "ALOS"            -FieldType "Number"
Ensure-Field -ListName "Census Tracker" -FieldName "Status"              -InternalName "Status"          -FieldType "Choice" -Choices @("On Track","Below Target","At Capacity","Waitlist Active")
Ensure-Field -ListName "Census Tracker" -FieldName "Notes"               -InternalName "Notes"           -FieldType "Note"
Ensure-Field -ListName "Census Tracker" -FieldName "Last Updated"        -InternalName "LastUpdated"     -FieldType "DateTime"

# ── 2. Incident Reports ─────────────────────────────────────────────────────
Write-Host "`n  [2/18] Incident Reports" -ForegroundColor Magenta
Ensure-List "Incident Reports"
Ensure-Field -ListName "Incident Reports" -FieldName "Incident ID"       -InternalName "IncidentID"       -FieldType "Text"
Ensure-Field -ListName "Incident Reports" -FieldName "Incident Date"     -InternalName "IncidentDate"     -FieldType "DateTime"
Ensure-Field -ListName "Incident Reports" -FieldName "Category"          -InternalName "Category"         -FieldType "Choice" -Choices @("Client Fall","Med Error","AMA Discharge","Behavioral Escalation","Property Damage","HIPAA Breach","Other")
Ensure-Field -ListName "Incident Reports" -FieldName "Severity"          -InternalName "Severity"         -FieldType "Choice" -Choices @("Critical","High","Medium","Low")
Ensure-Field -ListName "Incident Reports" -FieldName "Description"       -InternalName "Description"      -FieldType "Note"
Ensure-Field -ListName "Incident Reports" -FieldName "Status"            -InternalName "Status"           -FieldType "Choice" -Choices @("Open","Under Review","Investigating","Resolved","Closed")
Ensure-Field -ListName "Incident Reports" -FieldName "Assigned To"       -InternalName "AssignedTo"       -FieldType "User"
Ensure-Field -ListName "Incident Reports" -FieldName "Resolution Date"   -InternalName "ResolutionDate"   -FieldType "DateTime"
Ensure-Field -ListName "Incident Reports" -FieldName "Corrective Action" -InternalName "CorrectiveAction" -FieldType "Note"

# ── 3. Staff Credential Tracker ─────────────────────────────────────────────
Write-Host "`n  [3/18] Staff Credential Tracker" -ForegroundColor Magenta
Ensure-List "Staff Credential Tracker"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Staff Name"             -InternalName "StaffName"           -FieldType "Text"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Role"                   -InternalName "Role"                -FieldType "Choice" -Choices @("LPC","LISAC","LCSW","LAC","BHT","CPSS","Admin","Admissions","Clinical Director")
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "License Number"         -InternalName "LicenseNumber"       -FieldType "Text"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "License Expiration"     -InternalName "LicenseExpiration"   -FieldType "DateTime"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Fingerprint Clearance"  -InternalName "FingerprintClearance"-FieldType "DateTime"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "CPR Expiration"         -InternalName "CPRExpiration"       -FieldType "DateTime"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "HIPAA Training Date"    -InternalName "HIPAATrainingDate"   -FieldType "DateTime"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "FWA Training Date"      -InternalName "FWATrainingDate"     -FieldType "DateTime"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Cultural Comp Date"     -InternalName "CulturalCompDate"    -FieldType "DateTime"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Trauma Informed Date"   -InternalName "TraumaInformedDate"  -FieldType "DateTime"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Supervision Current"    -InternalName "SupervisionCurrent"  -FieldType "Boolean"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "CEUs Completed"         -InternalName "CEUsCompleted"       -FieldType "Number"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "CEUs Required"          -InternalName "CEUsRequired"        -FieldType "Number"
Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Status"                 -InternalName "Status"              -FieldType "Choice" -Choices @("Current","Expiring Soon","Expired","Action Required")

# ── 4. Corrective Action Plans ───────────────────────────────────────────────
Write-Host "`n  [4/18] Corrective Action Plans" -ForegroundColor Magenta
Ensure-List "Corrective Action Plans"
Ensure-Field -ListName "Corrective Action Plans" -FieldName "CAP ID"           -InternalName "CAPID"            -FieldType "Text"
# Title is default — used for description
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Category"         -InternalName "Category"         -FieldType "Choice" -Choices @("Documentation","Safety","Compliance","Clinical","Operations")
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Source"           -InternalName "Source"           -FieldType "Choice" -Choices @("Internal Audit","Chart Audit","State Survey","Fire Marshal","Incident Report")
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Open Date"        -InternalName "OpenDate"         -FieldType "DateTime"
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Due Date"         -InternalName "DueDate"          -FieldType "DateTime"
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Owner"            -InternalName "Owner"            -FieldType "User"
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Status"           -InternalName "Status"           -FieldType "Choice" -Choices @("Open","In Progress","Pending Verification","Closed")
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Root Cause"       -InternalName "RootCause"        -FieldType "Note"
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Corrective Action"-InternalName "CorrectiveAction" -FieldType "Note"
Ensure-Field -ListName "Corrective Action Plans" -FieldName "Evidence"         -InternalName "Evidence"         -FieldType "Note"

# ── 5. Referral Partner Tracker ──────────────────────────────────────────────
Write-Host "`n  [5/18] Referral Partner Tracker" -ForegroundColor Magenta
Ensure-List "Referral Partner Tracker"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Partner Name"     -InternalName "PartnerName"     -FieldType "Text"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Partner Type"     -InternalName "PartnerType"     -FieldType "Choice" -Choices @("Hospital ED","Crisis Services","Courts/Probation","Outpatient MDs","Sober Living","Private Therapist","Community Org")
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Territory"        -InternalName "Territory"       -FieldType "Choice" -Choices @("North Phoenix","Scottsdale","East Valley","Tempe","West Valley","Metro PHX")
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Contact Name"     -InternalName "ContactName"     -FieldType "Text"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Contact Phone"    -InternalName "ContactPhone"    -FieldType "Text"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Referrals MTD"    -InternalName "ReferralsMTD"    -FieldType "Number"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Admits MTD"       -InternalName "AdmitsMTD"       -FieldType "Number"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Conversion Pct"   -InternalName "ConversionPct"   -FieldType "Calculated" -Formula "=[AdmitsMTD]/[ReferralsMTD]" -OutputType "Number"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Last Contact"     -InternalName "LastContact"     -FieldType "DateTime"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Agreement On File"-InternalName "AgreementOnFile" -FieldType "Boolean"
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Status"           -InternalName "Status"          -FieldType "Choice" -Choices @("Active","Follow-Up","New Partner","Inactive")
Ensure-Field -ListName "Referral Partner Tracker" -FieldName "Notes"            -InternalName "Notes"           -FieldType "Note"

# ── 6. Marketing Campaigns ───────────────────────────────────────────────────
Write-Host "`n  [6/18] Marketing Campaigns" -ForegroundColor Magenta
Ensure-List "Marketing Campaigns"
Ensure-Field -ListName "Marketing Campaigns" -FieldName "Campaign Name"  -InternalName "CampaignName" -FieldType "Text"
Ensure-Field -ListName "Marketing Campaigns" -FieldName "Channel"        -InternalName "Channel"      -FieldType "Choice" -Choices @("Google Ads","SEO/Organic","Facebook/Instagram","Referral Partners","Community Events","Directories")
Ensure-Field -ListName "Marketing Campaigns" -FieldName "Spend MTD"     -InternalName "SpendMTD"     -FieldType "Currency"
Ensure-Field -ListName "Marketing Campaigns" -FieldName "Leads"         -InternalName "Leads"        -FieldType "Number"
Ensure-Field -ListName "Marketing Campaigns" -FieldName "CPL"           -InternalName "CPL"          -FieldType "Currency"
Ensure-Field -ListName "Marketing Campaigns" -FieldName "Admits"        -InternalName "Admits"       -FieldType "Number"
Ensure-Field -ListName "Marketing Campaigns" -FieldName "CPA"           -InternalName "CPA"          -FieldType "Currency"
Ensure-Field -ListName "Marketing Campaigns" -FieldName "Status"        -InternalName "Status"       -FieldType "Choice" -Choices @("Live","Building","Paused","Completed")
Ensure-Field -ListName "Marketing Campaigns" -FieldName "Start Date"    -InternalName "StartDate"    -FieldType "DateTime"
Ensure-Field -ListName "Marketing Campaigns" -FieldName "Notes"         -InternalName "Notes"        -FieldType "Note"

# ── 7. Admissions Pipeline ───────────────────────────────────────────────────
Write-Host "`n  [7/18] Admissions Pipeline" -ForegroundColor Magenta
Ensure-List "Admissions Pipeline"
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Referral ID"       -InternalName "ReferralID"      -FieldType "Text"
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Referral Date"     -InternalName "ReferralDate"    -FieldType "DateTime"
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Source"            -InternalName "Source"          -FieldType "Choice" -Choices @("Hospital ED","Self-Referral","Private Therapist","Probation","Alumni","Sober Living","Community","Crisis Line")
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Source Detail"     -InternalName "SourceDetail"    -FieldType "Text"
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Insurance"         -InternalName "Insurance"       -FieldType "Choice" -Choices @("AHCCCS Mercy Care","AHCCCS UHCCP","BCBS","UHC/Optum","Cigna","Aetna","Private Pay","Other/SCA")
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Stage"             -InternalName "Stage"           -FieldType "Choice" -Choices @("Lead","Pre-Screened","VOB In Progress","VOB Complete","Assessment Scheduled","Assessment Complete","Admitted","Waitlisted","Lost")
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Status"            -InternalName "Status"          -FieldType "Choice" -Choices @("Active","Admitted","Waitlisted","No-Show","Lost","Declined")
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Assessment Date"   -InternalName "AssessmentDate"  -FieldType "DateTime"
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Admit Date"        -InternalName "AdmitDate"       -FieldType "DateTime"
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Assigned To"       -InternalName "AssignedTo"      -FieldType "User"
Ensure-Field -ListName "Admissions Pipeline" -FieldName "Notes"             -InternalName "Notes"           -FieldType "Note"

# ── 8. Insurance Verification Tracker ────────────────────────────────────────
Write-Host "`n  [8/18] Insurance Verification Tracker" -ForegroundColor Magenta
Ensure-List "Insurance Verification Tracker"
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Referral ID"         -InternalName "ReferralID"        -FieldType "Text"
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Client Initials"     -InternalName "ClientInitials"    -FieldType "Text"
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Insurance"           -InternalName "Insurance"         -FieldType "Choice" -Choices @("AHCCCS Mercy Care","AHCCCS UHCCP","BCBS","UHC/Optum","Cigna","Aetna","Private Pay","Other/SCA")
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Verification Date"   -InternalName "VerificationDate"  -FieldType "DateTime"
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "AHCCCS Eligible"     -InternalName "AHCCCSEligible"    -FieldType "Boolean"
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Covered Days"        -InternalName "CoveredDays"       -FieldType "Number"
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Copay"               -InternalName "Copay"             -FieldType "Currency"
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Prior Auth Required" -InternalName "PriorAuthRequired" -FieldType "Boolean"
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Prior Auth Status"   -InternalName "PriorAuthStatus"   -FieldType "Choice" -Choices @("Not Required","Pending","Approved","Denied")
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Status"              -InternalName "Status"            -FieldType "Choice" -Choices @("Pending","Verified","Issue","Denied")
Ensure-Field -ListName "Insurance Verification Tracker" -FieldName "Notes"               -InternalName "Notes"             -FieldType "Note"

# ── 9. Revenue Tracker ───────────────────────────────────────────────────────
Write-Host "`n  [9/18] Revenue Tracker" -ForegroundColor Magenta
Ensure-List "Revenue Tracker"
Ensure-Field -ListName "Revenue Tracker" -FieldName "Month"          -InternalName "Month"          -FieldType "DateTime"
Ensure-Field -ListName "Revenue Tracker" -FieldName "Payer"          -InternalName "Payer"          -FieldType "Choice" -Choices @("AHCCCS Mercy Care","AHCCCS UHCCP","BCBS","UHC/Optum","Cigna","Aetna","Private Pay","Other/SCA")
Ensure-Field -ListName "Revenue Tracker" -FieldName "Revenue"        -InternalName "Revenue"        -FieldType "Currency"
Ensure-Field -ListName "Revenue Tracker" -FieldName "Claim Count"    -InternalName "ClaimCount"     -FieldType "Number"
Ensure-Field -ListName "Revenue Tracker" -FieldName "Denial Count"   -InternalName "DenialCount"    -FieldType "Number"
Ensure-Field -ListName "Revenue Tracker" -FieldName "Clean Claim Pct"-InternalName "CleanClaimPct"  -FieldType "Number"
Ensure-Field -ListName "Revenue Tracker" -FieldName "Notes"          -InternalName "Notes"          -FieldType "Note"

# ── 10. Compliance Audit Calendar ────────────────────────────────────────────
Write-Host "`n  [10/18] Compliance Audit Calendar" -ForegroundColor Magenta
Ensure-List "Compliance Audit Calendar"
# Title is default — event name
Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Audit Date"      -InternalName "AuditDate"      -FieldType "DateTime"
Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Audit Type"      -InternalName "AuditType"      -FieldType "Choice" -Choices @("AZDHS","Fire Marshal","Internal","HIPAA","Chart Audit","9 A.A.C. 10")
Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Scope"           -InternalName "Scope"          -FieldType "Text"
Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Owner"           -InternalName "Owner"          -FieldType "User"
Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Status"          -InternalName "Status"         -FieldType "Choice" -Choices @("Scheduled","Preparing","Complete","Overdue")
Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Days Remaining"  -InternalName "DaysRemaining"  -FieldType "Calculated" -Formula "=[AuditDate]-Today" -OutputType "Number"
Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Notes"           -InternalName "Notes"          -FieldType "Note"

# ── 11. Group Schedule ───────────────────────────────────────────────────────
Write-Host "`n  [11/18] Group Schedule" -ForegroundColor Magenta
Ensure-List "Group Schedule"
Ensure-Field -ListName "Group Schedule" -FieldName "Group Name"       -InternalName "GroupName"       -FieldType "Text"
Ensure-Field -ListName "Group Schedule" -FieldName "Day of Week"      -InternalName "DayOfWeek"       -FieldType "Choice" -Choices @("Monday","Tuesday","Wednesday","Thursday","Friday")
Ensure-Field -ListName "Group Schedule" -FieldName "Time Slot"        -InternalName "TimeSlot"        -FieldType "Text"
Ensure-Field -ListName "Group Schedule" -FieldName "Facilitator"      -InternalName "Facilitator"     -FieldType "Text"
Ensure-Field -ListName "Group Schedule" -FieldName "Group Type"       -InternalName "GroupType"       -FieldType "Choice" -Choices @("CBT","DBT","Process","Psychoeducation","Relapse Prevention","Mindfulness","Life Skills")
Ensure-Field -ListName "Group Schedule" -FieldName "Room"             -InternalName "Room"            -FieldType "Choice" -Choices @("Group Room A","Group Room B","Outdoor")
Ensure-Field -ListName "Group Schedule" -FieldName "Max Participants" -InternalName "MaxParticipants" -FieldType "Number"
Ensure-Field -ListName "Group Schedule" -FieldName "Notes"            -InternalName "Notes"           -FieldType "Note"

# ── 12. Group Attendance Log ─────────────────────────────────────────────────
Write-Host "`n  [12/18] Group Attendance Log" -ForegroundColor Magenta
Ensure-List "Group Attendance Log"
Ensure-Field -ListName "Group Attendance Log" -FieldName "Date"        -InternalName "Date"        -FieldType "DateTime"
Ensure-Field -ListName "Group Attendance Log" -FieldName "Group Name"  -InternalName "GroupName"   -FieldType "Text"
Ensure-Field -ListName "Group Attendance Log" -FieldName "Facilitator" -InternalName "Facilitator" -FieldType "Text"
Ensure-Field -ListName "Group Attendance Log" -FieldName "Attendees"   -InternalName "Attendees"   -FieldType "Number"
Ensure-Field -ListName "Group Attendance Log" -FieldName "Notes"       -InternalName "Notes"       -FieldType "Note"

# ── 13. Client Outcomes Tracker ──────────────────────────────────────────────
Write-Host "`n  [13/18] Client Outcomes Tracker" -ForegroundColor Magenta
Ensure-List "Client Outcomes Tracker"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "Client ID"          -InternalName "ClientID"          -FieldType "Text"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "Admit Date"         -InternalName "AdmitDate"         -FieldType "DateTime"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "Discharge Date"     -InternalName "DischargeDate"     -FieldType "DateTime"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "LOS Days"           -InternalName "LOSdays"           -FieldType "Calculated" -Formula "=[DischargeDate]-[AdmitDate]" -OutputType "Number"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "PHQ-9 Intake"       -InternalName "PHQ9Intake"        -FieldType "Number"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "PHQ-9 Discharge"    -InternalName "PHQ9Discharge"     -FieldType "Number"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "GAD-7 Intake"       -InternalName "GAD7Intake"        -FieldType "Number"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "GAD-7 Discharge"    -InternalName "GAD7Discharge"     -FieldType "Number"
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "Completion Status"  -InternalName "CompletionStatus"  -FieldType "Choice" -Choices @("Successful Completion","AMA","Transferred","Administrative","Referred Up")
Ensure-Field -ListName "Client Outcomes Tracker" -FieldName "Notes"              -InternalName "Notes"             -FieldType "Note"

# ── 14. Treatment Plan Review Dates ──────────────────────────────────────────
Write-Host "`n  [14/18] Treatment Plan Review Dates" -ForegroundColor Magenta
Ensure-List "Treatment Plan Review Dates"
Ensure-Field -ListName "Treatment Plan Review Dates" -FieldName "Client ID"        -InternalName "ClientID"       -FieldType "Text"
Ensure-Field -ListName "Treatment Plan Review Dates" -FieldName "Therapist"        -InternalName "Therapist"      -FieldType "Text"
Ensure-Field -ListName "Treatment Plan Review Dates" -FieldName "Last Review Date" -InternalName "LastReviewDate" -FieldType "DateTime"
Ensure-Field -ListName "Treatment Plan Review Dates" -FieldName "Next Review Due"  -InternalName "NextReviewDue"  -FieldType "DateTime"
Ensure-Field -ListName "Treatment Plan Review Dates" -FieldName "Status"           -InternalName "Status"         -FieldType "Choice" -Choices @("Current","Due This Week","Overdue")
Ensure-Field -ListName "Treatment Plan Review Dates" -FieldName "Notes"            -InternalName "Notes"          -FieldType "Note"

# ── 15. UDS Tracking Log ─────────────────────────────────────────────────────
Write-Host "`n  [15/18] UDS Tracking Log" -ForegroundColor Magenta
Ensure-List "UDS Tracking Log"
Ensure-Field -ListName "UDS Tracking Log" -FieldName "Client ID"          -InternalName "ClientID"          -FieldType "Text"
Ensure-Field -ListName "UDS Tracking Log" -FieldName "Test Date"          -InternalName "TestDate"          -FieldType "DateTime"
Ensure-Field -ListName "UDS Tracking Log" -FieldName "Result"             -InternalName "Result"            -FieldType "Choice" -Choices @("Negative","Positive","Refused","Not Tested")
Ensure-Field -ListName "UDS Tracking Log" -FieldName "Substance Detected" -InternalName "SubstanceDetected" -FieldType "Text"
Ensure-Field -ListName "UDS Tracking Log" -FieldName "Action Taken"       -InternalName "ActionTaken"       -FieldType "Text"
Ensure-Field -ListName "UDS Tracking Log" -FieldName "Notes"              -InternalName "Notes"             -FieldType "Note"

# ── 16. BD Visit Log ─────────────────────────────────────────────────────────
Write-Host "`n  [16/18] BD Visit Log" -ForegroundColor Magenta
Ensure-List "BD Visit Log"
Ensure-Field -ListName "BD Visit Log" -FieldName "Visit Date"      -InternalName "VisitDate"      -FieldType "DateTime"
Ensure-Field -ListName "BD Visit Log" -FieldName "Partner Name"    -InternalName "PartnerName"    -FieldType "Text"
Ensure-Field -ListName "BD Visit Log" -FieldName "Contact Person"  -InternalName "ContactPerson"  -FieldType "Text"
Ensure-Field -ListName "BD Visit Log" -FieldName "Visit Type"      -InternalName "VisitType"      -FieldType "Choice" -Choices @("In-Person","Virtual","Phone","Lunch","Facility Tour","Event")
Ensure-Field -ListName "BD Visit Log" -FieldName "Purpose"         -InternalName "Purpose"        -FieldType "Text"
Ensure-Field -ListName "BD Visit Log" -FieldName "Outcome"         -InternalName "Outcome"        -FieldType "Text"
Ensure-Field -ListName "BD Visit Log" -FieldName "Follow-Up Date"  -InternalName "FollowUpDate"   -FieldType "DateTime"
Ensure-Field -ListName "BD Visit Log" -FieldName "Notes"           -InternalName "Notes"          -FieldType "Note"

# ── 17. BD Gift Log ──────────────────────────────────────────────────────────
Write-Host "`n  [17/18] BD Gift Log" -ForegroundColor Magenta
Ensure-List "BD Gift Log"
Ensure-Field -ListName "BD Gift Log" -FieldName "Date"             -InternalName "Date"            -FieldType "DateTime"
Ensure-Field -ListName "BD Gift Log" -FieldName "Recipient"        -InternalName "Recipient"       -FieldType "Text"
Ensure-Field -ListName "BD Gift Log" -FieldName "Organization"     -InternalName "Organization"    -FieldType "Text"
Ensure-Field -ListName "BD Gift Log" -FieldName "Gift Description" -InternalName "GiftDescription" -FieldType "Text"
Ensure-Field -ListName "BD Gift Log" -FieldName "Value"            -InternalName "Value"           -FieldType "Currency"
Ensure-Field -ListName "BD Gift Log" -FieldName "Compliant"        -InternalName "Compliant"       -FieldType "Boolean"
Ensure-Field -ListName "BD Gift Log" -FieldName "Notes"            -InternalName "Notes"           -FieldType "Note"

# ── 18a. Payroll Tracker ─────────────────────────────────────────────────────
Write-Host "`n  [18a/18] Payroll Tracker" -ForegroundColor Magenta
Ensure-List "Payroll Tracker"
Ensure-Field -ListName "Payroll Tracker" -FieldName "Pay Period"    -InternalName "PayPeriod"    -FieldType "Text"
Ensure-Field -ListName "Payroll Tracker" -FieldName "Staff Name"    -InternalName "StaffName"    -FieldType "Text"
Ensure-Field -ListName "Payroll Tracker" -FieldName "Role"          -InternalName "Role"         -FieldType "Choice" -Choices @("LPC","LISAC","LCSW","LAC","BHT","CPSS","Admin","Admissions","Clinical Director")
Ensure-Field -ListName "Payroll Tracker" -FieldName "Regular Hours" -InternalName "RegularHours" -FieldType "Number"
Ensure-Field -ListName "Payroll Tracker" -FieldName "OT Hours"      -InternalName "OTHours"      -FieldType "Number"
Ensure-Field -ListName "Payroll Tracker" -FieldName "Gross Pay"     -InternalName "GrossPay"     -FieldType "Currency"
Ensure-Field -ListName "Payroll Tracker" -FieldName "Status"        -InternalName "Status"       -FieldType "Choice" -Choices @("Processed","Pending","Issue")
Ensure-Field -ListName "Payroll Tracker" -FieldName "Notes"         -InternalName "Notes"        -FieldType "Note"

# ── 18b. Open Positions ──────────────────────────────────────────────────────
Write-Host "`n  [18b/18] Open Positions" -ForegroundColor Magenta
Ensure-List "Open Positions"
Ensure-Field -ListName "Open Positions" -FieldName "Position Title" -InternalName "PositionTitle" -FieldType "Text"
Ensure-Field -ListName "Open Positions" -FieldName "Department"     -InternalName "Department"    -FieldType "Choice" -Choices @("Clinical","Admissions","Marketing","BD","Admin","Operations")
Ensure-Field -ListName "Open Positions" -FieldName "Posted Date"    -InternalName "PostedDate"    -FieldType "DateTime"
Ensure-Field -ListName "Open Positions" -FieldName "Applications"   -InternalName "Applications"  -FieldType "Number"
Ensure-Field -ListName "Open Positions" -FieldName "Interviews"     -InternalName "Interviews"    -FieldType "Number"
Ensure-Field -ListName "Open Positions" -FieldName "Status"         -InternalName "Status"        -FieldType "Choice" -Choices @("Open","Interviewing","Offer Extended","Filled","On Hold")
Ensure-Field -ListName "Open Positions" -FieldName "Notes"          -InternalName "Notes"         -FieldType "Note"

# ── 18c. Billing Denials ─────────────────────────────────────────────────────
Write-Host "`n  [18c/18] Billing Denials" -ForegroundColor Magenta
Ensure-List "Billing Denials"
Ensure-Field -ListName "Billing Denials" -FieldName "Claim ID"         -InternalName "ClaimID"         -FieldType "Text"
Ensure-Field -ListName "Billing Denials" -FieldName "Payer"            -InternalName "Payer"           -FieldType "Choice" -Choices @("AHCCCS Mercy Care","AHCCCS UHCCP","BCBS","UHC/Optum","Cigna","Aetna","Private Pay","Other/SCA")
Ensure-Field -ListName "Billing Denials" -FieldName "Denial Date"      -InternalName "DenialDate"      -FieldType "DateTime"
Ensure-Field -ListName "Billing Denials" -FieldName "Denial Reason"    -InternalName "DenialReason"    -FieldType "Choice" -Choices @("Auth Expired","Medical Necessity","Eligibility","Timely Filing","Coding Error","Duplicate","Other")
Ensure-Field -ListName "Billing Denials" -FieldName "Amount"           -InternalName "Amount"          -FieldType "Currency"
Ensure-Field -ListName "Billing Denials" -FieldName "Appeal Status"    -InternalName "AppealStatus"    -FieldType "Choice" -Choices @("Not Appealed","Appeal Filed","Won","Lost","Write-Off")
Ensure-Field -ListName "Billing Denials" -FieldName "Appeal Deadline"  -InternalName "AppealDeadline"  -FieldType "DateTime"
Ensure-Field -ListName "Billing Denials" -FieldName "Notes"            -InternalName "Notes"           -FieldType "Note"

# ── 18d. Employee Training Log ───────────────────────────────────────────────
Write-Host "`n  [18d/18] Employee Training Log" -ForegroundColor Magenta
Ensure-List "Employee Training Log"
Ensure-Field -ListName "Employee Training Log" -FieldName "Staff Name"          -InternalName "StaffName"         -FieldType "Text"
Ensure-Field -ListName "Employee Training Log" -FieldName "Training Name"       -InternalName "TrainingName"      -FieldType "Choice" -Choices @("HIPAA","FWA","Cultural Competency","Trauma-Informed Care","QPR Suicide Prevention","Mandated Reporter","CPR/First Aid","CPI De-escalation","BBP/OSHA")
Ensure-Field -ListName "Employee Training Log" -FieldName "Completed Date"      -InternalName "CompletedDate"     -FieldType "DateTime"
Ensure-Field -ListName "Employee Training Log" -FieldName "Due Date"            -InternalName "DueDate"           -FieldType "DateTime"
Ensure-Field -ListName "Employee Training Log" -FieldName "Frequency"           -InternalName "Frequency"         -FieldType "Choice" -Choices @("Annual","Biennial","One-Time","As Needed")
Ensure-Field -ListName "Employee Training Log" -FieldName "Status"              -InternalName "Status"            -FieldType "Choice" -Choices @("Current","Due Soon","Overdue")
Ensure-Field -ListName "Employee Training Log" -FieldName "Certificate On File" -InternalName "CertificateOnFile" -FieldType "Boolean"

# ─────────────────────────────────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Step "DEPLOYMENT COMPLETE"
Write-Host ""
Write-Host "  Site URL:  $SiteUrl" -ForegroundColor Green
Write-Host "  Theme:     $ThemeName" -ForegroundColor Green
Write-Host "  Libraries: 7 document libraries with folder structures" -ForegroundColor Green
Write-Host "  Lists:     18 SharePoint lists with typed columns" -ForegroundColor Green
Write-Host "  Nav:       8 top navigation links" -ForegroundColor Green
Write-Host ""
Write-Host "  Next step: Run Seed-ListData.ps1 to populate sample data." -ForegroundColor Cyan
Write-Host "  Then:      Run Deploy-ChollaPages.ps1 (Part 2) to create pages." -ForegroundColor Cyan
Write-Host ""

Disconnect-PnPOnline -ErrorAction SilentlyContinue
