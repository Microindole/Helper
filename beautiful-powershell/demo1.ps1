Import-Module posh-git
# $GitPromptSettings.EnableFileStatus = $false

function prompt {
    $colors = @{
        ps_prefix     = "Green"
        path_parent   = "DarkGray" # 父路径使用暗灰色，使其"退后"
        path_current  = "Cyan"     # 当前目录使用亮青色，使其突出
        git           = "Yellow"
        success       = "Green"
        error         = "Red"
        admin         = "Magenta"
        prompt_symbol = "White"
    }

    # 显示 "PS" 前缀
    Write-Host "PS" -NoNewline -ForegroundColor $colors.ps_prefix

    # 如果是管理员权限，显示提示
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) { Write-Host "[Admin]" -NoNewline -ForegroundColor $colors.admin }

    # 显示分段着色的路径
    $fullPath = $pwd.ProviderPath.Replace($HOME, "~")
    
    # 获取父路径和当前目录名
    $parentPath = Split-Path -Path $fullPath -Parent
    $currentDir = Split-Path -Path $fullPath -Leaf
    $separator = [System.IO.Path]::DirectorySeparatorChar # 路径分隔符 '\'

    # 如果存在父路径，则先用暗色打印父路径
    if ($parentPath) {
        Write-Host " $parentPath" -NoNewline -ForegroundColor $colors.path_parent
    }
    
    # 接着用亮色打印分隔符和当前目录
    Write-Host "$separator$currentDir" -NoNewline -ForegroundColor $colors.path_current


    # 显示 Git 状态
    $gitStatus = Write-VcsStatus
    Write-Host $gitStatus -NoNewline -ForegroundColor $colors.git

    # 显示最终的提示符 '>'
    Write-Host " >" -NoNewline -ForegroundColor $colors.prompt_symbol

    # 返回一个空格，确保光标位置正确
    return " "
}