Import-Module posh-git
# $GitPromptSettings.EnableFileStatus = $false # 取消注释则是不需要更详细的 Git 信息

function prompt {

    $colors = @{
        ps_prefix     = "Green"
        path_parent   = "DarkGray"
        path_current  = "Cyan"
        git           = "Yellow"
        success       = "Green"
        error         = "Red"
        admin         = "Magenta"
        prompt_symbol = "White"
    }

    Write-Host "PS " -NoNewline -ForegroundColor $colors.ps_prefix

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) { Write-Host "[Admin] " -NoNewline -ForegroundColor $colors.admin }

    $displayPath = $pwd.ProviderPath.Replace($HOME, "~")
    $separator = [System.IO.Path]::DirectorySeparatorChar

    $parentPath = Split-Path $displayPath -Parent
    $currentDir = Split-Path $displayPath -Leaf

    if ($parentPath -and $parentPath -ne $displayPath) {
        $normalizedParent = $parentPath.TrimEnd($separator)

        Write-Host $normalizedParent -NoNewline -ForegroundColor $colors.path_parent
        Write-Host "$separator$currentDir" -NoNewline -ForegroundColor $colors.path_current
    }
    else {
        Write-Host $displayPath -NoNewline -ForegroundColor $colors.path_current
    }

    $gitStatus = Write-VcsStatus
    if ($gitStatus) { Write-Host "$($gitStatus)" -NoNewline -ForegroundColor $colors.git }
    Write-Host " >" -NoNewline -ForegroundColor $colors.prompt_symbol
    return " "
}
