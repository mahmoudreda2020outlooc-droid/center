$Endpoint = "https://fra.cloud.appwrite.io/v1"
$ProjectID = "69662d2200214465b1d3"
$DatabaseID = "MainDatabase" 
$APIKey = "standard_fa9eb14506d4d0792498385393220a1f90f5f4749a0772c06f1c7e51fc48a4e90eb07260afc70482f616955038649a3b3ae0f3bbdc08dec5090bb8057fb51b672b1d3767ca9349af5817c238dff09a61a669b164562829bdb896d9b94222c902d810bf17b6c2b288af3ac16a624d51d4e0634b09f7e01685cbd844b5651e7aab"

$Headers = @{
    "Content-Type"       = "application/json"
    "X-Appwrite-Project" = $ProjectID
    "X-Appwrite-Key"     = $APIKey
}

function Log-Message($msg, $color = "White") {
    Write-Host "[*] $msg" -ForegroundColor $color
}

function Ensure-Collection($dbId, $collId, $name) {
    Log-Message "Ensuring collection: $name ($collId)..." "Cyan"
    try {
        $coll = Invoke-RestMethod -Uri "$Endpoint/databases/$dbId/collections/$collId" -Method Get -Headers $Headers
        Log-Message "Collection exists. Updating permissions..." "Yellow"
        $body = @{ name = $name; permissions = @('create("any")', 'read("any")', 'update("any")', 'delete("any")') } | ConvertTo-Json
        Invoke-RestMethod -Uri "$Endpoint/databases/$dbId/collections/$collId" -Method Put -Headers $Headers -Body $body
    }
    catch {
        Log-Message "Creating collection $collId..." "Magenta"
        $body = @{ collectionId = $collId; name = $name; permissions = @('create("any")', 'read("any")', 'update("any")', 'delete("any")'); documentSecurity = $false } | ConvertTo-Json
        Invoke-RestMethod -Uri "$Endpoint/databases/$dbId/collections" -Method Post -Headers $Headers -Body $body
    }
}

function Ensure-Attribute($dbId, $collId, $attr) {
    $key = $attr.key
    $type = $attr.type
    Log-Message "  - Attribute: $key ($type)" "Gray"
    try {
        $body = $attr | ConvertTo-Json
        Invoke-RestMethod -Uri "$Endpoint/databases/$dbId/collections/$collId/attributes/$type" -Method Post -Headers $Headers -Body $body
    }
    catch {
        if ($_.Exception.Message -match "409") { }
        else { Log-Message "    ! Error: $($_.Exception.Message)" "Red" }
    }
}

try {
    Log-Message "Starting Appwrite Backend Initialization..." "Green"
    $dbs = Invoke-RestMethod -Uri "$Endpoint/databases" -Method Get -Headers $Headers
    $db = $dbs.databases | Where-Object { $_.'$id' -eq $DatabaseID }
    if (-not $db) { $DatabaseID = $dbs.databases[0].'$id' }
    Log-Message "Using Database: $DatabaseID" "Green"

    # 1. Security Logs
    Ensure-Collection $DatabaseID "security_logs" "Security Logs"
    $logAttrs = @(
        @{ key = "userId"; type = "string"; size = 100; required = $true }
        @{ key = "action"; type = "string"; size = 255; required = $true }
        @{ key = "details"; type = "string"; size = 1000; required = $false }
        @{ key = "timestamp"; type = "string"; size = 100; required = $true }
        @{ key = "ip"; type = "string"; size = 50; required = $false }
    )
    foreach ($a in $logAttrs) { Ensure-Attribute $DatabaseID "security_logs" $a }

    # 2. Users
    Ensure-Collection $DatabaseID "users" "Users"
    $userAttrs = @(
        @{ key = "id"; type = "string"; size = 50; required = $true }
        @{ key = "firstName"; type = "string"; size = 100; required = $false }
        @{ key = "lastName"; type = "string"; size = 100; required = $false }
        @{ key = "email"; type = "string"; size = 255; required = $false }
        @{ key = "username"; type = "string"; size = 100; required = $true }
        @{ key = "password"; type = "string"; size = 100; required = $true }
        @{ key = "passwordHash"; type = "string"; size = 255; required = $false }
        @{ key = "createdAt"; type = "string"; size = 100; required = $false }
        @{ key = "creationDate"; type = "string"; size = 100; required = $false }
        @{ key = "isSuspended"; type = "boolean"; required = $false; default = $false }
        @{ key = "isActive"; type = "boolean"; required = $false; default = $true }
        @{ key = "deviceId"; type = "string"; size = 255; required = $false }
        @{ key = "avatar"; type = "string"; size = 1000; required = $false }
        @{ key = "role"; type = "string"; size = 50; required = $false; default = "student" }
    )
    foreach ($a in $userAttrs) { Ensure-Attribute $DatabaseID "users" $a }

    # 3. Materials
    Ensure-Collection $DatabaseID "materials" "Materials"
    $matAttrs = @(
        @{ key = "id"; type = "string"; size = 50; required = $true }
        @{ key = "subjectId"; type = "string"; size = 50; required = $true }
        @{ key = "subjectDisplay"; type = "string"; size = 100; required = $true }
        @{ key = "sectionId"; type = "string"; size = 50; required = $true }
        @{ key = "sectionDisplay"; type = "string"; size = 100; required = $true }
        @{ key = "title"; type = "string"; size = 255; required = $true }
        @{ key = "desc"; type = "string"; size = 1000; required = $false }
        @{ key = "url"; type = "string"; size = 500; required = $true }
        @{ key = "isBlob"; type = "boolean"; required = $false; default = $false }
        @{ key = "size"; type = "integer"; required = $false; min = 0 }
        @{ key = "date"; type = "string"; size = 100; required = $false }
    )
    foreach ($a in $matAttrs) { Ensure-Attribute $DatabaseID "materials" $a }

    Log-Message "Appwrite setup completed successfully!" "Green"
}
catch {
    Log-Message "Critical Error: $_" "Red"
}
