# PSScriptAnalyzer:disable PSUseDeclaredVarsMoreThanAssignments

function Get-RecommendedProfiles {
    param (
        [string]$Framerate,
        [string]$Resolution,
        [string]$Chroma,
        [string]$BitDepth,
        [string]$Preference
    )
    
    # Define supported frame rates
    $dnxhdFrameRates = @("23976", "24000", "25000", "29970", "30000", "50000", "60000")
    $dnxhrFrameRates = @("23976", "24000", "25000", "29970", "30000", "50000", "60000", "120000")

    # Define DNxHD and DNxHR profiles based on official Avid specifications
    $profiles = @(
        @{ Codec="DNxHD"; Profile="36";   Resolution=@("1280x720", "1920x1080"); FrameRate=$dnxhdFrameRates; ColorDepth="8-bit";  Chroma="4:2:2"; Preference="Space" },
        @{ Codec="DNxHD"; Profile="115";  Resolution=@("1280x720");              FrameRate=$dnxhdFrameRates; ColorDepth="8-bit";  Chroma="4:2:2"; Preference="Quality" },
        @{ Codec="DNxHD"; Profile="145";  Resolution=@("1280x720");              FrameRate=$dnxhdFrameRates; ColorDepth="8-bit";  Chroma="4:2:2"; Preference="Quality" },
        @{ Codec="DNxHD"; Profile="175";  Resolution=@("1920x1080");             FrameRate=$dnxhdFrameRates; ColorDepth="8-bit";  Chroma="4:2:2"; Preference="Quality" },
        @{ Codec="DNxHD"; Profile="220";  Resolution=@("1920x1080", "2048x1080"); FrameRate=$dnxhdFrameRates; ColorDepth="8-bit";  Chroma="4:2:2"; Preference="Quality" },
        @{ Codec="DNxHD"; Profile="220x"; Resolution=@("1920x1080", "2048x1080"); FrameRate=$dnxhdFrameRates; ColorDepth="10-bit"; Chroma="4:2:2"; Preference="Quality" },

        @{ Codec="DNxHR"; Profile="LB";   Resolution=@("1280x720", "1920x1080", "3840x2160", "4096x2160"); FrameRate=$dnxhrFrameRates; ColorDepth="8-bit";  Chroma="4:2:2"; Preference="Space" },
        @{ Codec="DNxHR"; Profile="SQ";   Resolution=@("1280x720", "1920x1080", "3840x2160", "4096x2160"); FrameRate=$dnxhrFrameRates; ColorDepth="8-bit";  Chroma="4:2:2"; Preference="Balanced" },
        @{ Codec="DNxHR"; Profile="HQ";   Resolution=@("1280x720", "1920x1080", "3840x2160", "4096x2160"); FrameRate=$dnxhrFrameRates; ColorDepth="8-bit";  Chroma="4:2:2"; Preference="Quality" },
        @{ Codec="DNxHR"; Profile="HQX";  Resolution=@("1280x720", "1920x1080", "3840x2160", "4096x2160"); FrameRate=$dnxhrFrameRates; ColorDepth="12-bit"; Chroma="4:2:2"; Preference="Quality" },
        @{ Codec="DNxHR"; Profile="444";  Resolution=@("1280x720", "1920x1080", "3840x2160", "4096x2160"); FrameRate=$dnxhrFrameRates; ColorDepth="12-bit"; Chroma="4:4:4"; Preference="Quality" }
    )
    
    # Filter profiles based on input parameters
    $matchingProfiles = $profiles | Where-Object {
        $_.Resolution -contains $Resolution -and `
        $_.Chroma -eq $Chroma -and `
        $_.ColorDepth -eq $BitDepth -and `
        $_.FrameRate -contains $Framerate -and `
        ($_.Preference -eq $Preference -or $_.Preference -eq "Balanced" -or $Preference -eq "Skip")
    }
    
    # If no exact match is found, try to find the closest match
    if ($matchingProfiles.Count -eq 0) {
        $matchingProfiles = $profiles | Where-Object {
            ($_.Resolution -contains $Resolution -or $_.Resolution -contains "1920x1080") -and `
            ($_.Chroma -eq $Chroma -or $_.Chroma -eq "4:2:2") -and `
            ($_.ColorDepth -eq $BitDepth -or $_.ColorDepth -eq "8-bit") -and `
            ($_.FrameRate -contains $Framerate -or $_.FrameRate -contains "30000") -and `
            ($_.Preference -eq $Preference -or $_.Preference -eq "Balanced" -or $Preference -eq "Skip")
        }
    }
    
    return $matchingProfiles
}

# Function to display a header in a clean format
function Write-Header ($header) {
    $line = ('-' * ($header.Length + 4))
    Write-Host $line -ForegroundColor Cyan
    Write-Host "| $header |" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
}

# Main Script Execution
Write-Header "DNxHD / DNxHR Profile Recommender"

$inputFramerate  = Read-Host "Enter framerate (e.g., 23976, 24000, 25000, 29970, 30000, 50000, 60000, 120000)"
$inputResolution = Read-Host "Enter resolution (e.g., 1280x720, 1920x1080, 2048x1080, 3840x2160, 4096x2160)"
$inputChroma     = Read-Host "Enter chroma subsampling (e.g., 4:2:2, 4:4:4, or 4:2:0)"
$inputBitDepth   = Read-Host "Enter bit depth (e.g., 8-bit, 10-bit, 12-bit)"
$inputPreference = Read-Host "Enter preference (Space, Quality, Balanced, or Skip)"

# Fallback for unsupported chroma: use 4:2:2 if 4:2:0 is provided.
if ($inputChroma -eq "4:2:0") {
    Write-Host "Chroma 4:2:0 is not supported by DNxHD/DNxHR. Using 4:2:2 as the fallback." -ForegroundColor Yellow
    $inputChroma = "4:2:2"
}

# Retrieve matching profiles
$results = Get-RecommendedProfiles -Framerate $inputFramerate -Resolution $inputResolution -Chroma $inputChroma -BitDepth $inputBitDepth -Preference $inputPreference

Write-Host ""
Write-Header "Recommendation Results"

if ($results.Count -eq 0) {
    Write-Host "No matching profiles found for:" -ForegroundColor Red
    Write-Host "  Resolution: $inputResolution" -ForegroundColor Red
    Write-Host "  Framerate:  $inputFramerate" -ForegroundColor Red
    Write-Host "  Chroma:     $inputChroma" -ForegroundColor Red
    Write-Host "  Bit Depth:  $inputBitDepth" -ForegroundColor Red
    Write-Host "  Preference: $inputPreference" -ForegroundColor Red
} else {
    Write-Host "Recommended Profiles:" -ForegroundColor Green
    foreach ($profile in $results) {
        Write-Host "------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Codec:          $($profile.Codec)" -ForegroundColor White
        Write-Host "Profile:        $($profile.Profile)" -ForegroundColor White
        Write-Host "Resolutions:    $($profile.Resolution -join ', ')" -ForegroundColor White
        Write-Host "Frame Rates:    $($profile.FrameRate -join ', ')" -ForegroundColor White
        Write-Host "Color Depth:    $($profile.ColorDepth)" -ForegroundColor White
        Write-Host "Chroma:         $($profile.Chroma)" -ForegroundColor White
        Write-Host "Preference:     $($profile.Preference)" -ForegroundColor White
    }
    Write-Host "------------------------------------------" -ForegroundColor DarkGray
}

Read-Host -Prompt "Press Enter to continue"