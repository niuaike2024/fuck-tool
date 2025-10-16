<#
FUCK命令行工具 - 自动修正输错的命令

功能：当你输入了错误的命令后，输入'fuck'将尝试修正并执行正确的命令

使用方法：
1. 保存此脚本为fuck.ps1
2. 打开PowerShell，运行命令：Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
3. 将脚本路径添加到系统环境变量中，或者创建别名
#>

function Fuck-Command {
    # 获取上一条命令
    $lastCommand = Get-History -Count 1
    
    if (-not $lastCommand) {
        Write-Host "没有找到上一条命令记录。" -ForegroundColor Yellow
        return
    }
    
    $command = $lastCommand.CommandLine
    
    # 如果上一条命令就是fuck，则获取再上一条
    if ($command -eq 'fuck') {
        $lastCommand = Get-History -Count 2 | Select-Object -Last 1
        if (-not $lastCommand) {
            Write-Host "没有找到可修正的命令。" -ForegroundColor Yellow
            return
        }
        $command = $lastCommand.CommandLine
    }
    
    Write-Host "正在尝试修正命令: $command" -ForegroundColor Cyan
    
    # 常见命令修正规则
    $fixedCommand = $command
    
    # 修正常见拼写错误
    $fixedCommand = $fixedCommand -replace 'ls','Get-ChildItem' -replace 'dir','Get-ChildItem'
    $fixedCommand = $fixedCommand -replace 'cd','Set-Location'
    $fixedCommand = $fixedCommand -replace 'clear','Clear-Host'
    $fixedCommand = $fixedCommand -replace 'cat','Get-Content'
    $fixedCommand = $fixedCommand -replace 'echo','Write-Output'
    $fixedCommand = $fixedCommand -replace 'mkdir','New-Item -ItemType Directory'
    $fixedCommand = $fixedCommand -replace 'rmdir','Remove-Item -Recurse -Force'
    $fixedCommand = $fixedCommand -replace 'rm','Remove-Item'
    $fixedCommand = $fixedCommand -replace 'cp','Copy-Item'
    $fixedCommand = $fixedCommand -replace 'mv','Move-Item'
    
    # 检查是否需要管理员权限
    if ($command -match 'access denied|拒绝访问') {
        Write-Host "检测到权限错误，尝试以管理员身份运行..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-Command &{$fixedCommand}" -Verb RunAs
        return
    }
    
    # 如果命令没有变化，尝试其他修正
    if ($fixedCommand -eq $command) {
        # 检查命令是否存在
        $commandName = ($command -split ' ')[0]
        $commandExists = Get-Command $commandName -ErrorAction SilentlyContinue
        
        if (-not $commandExists) {
            # 尝试找出相似的命令
            $similarCommands = Get-Command | Where-Object {$_.Name -like "*$commandName*"} | Select-Object -First 5
            
            if ($similarCommands) {
                Write-Host "找不到命令 '$commandName'，以下是相似的命令：" -ForegroundColor Yellow
                $similarCommands | Format-Table -AutoSize Name, CommandType
                
                Write-Host "`n请选择要执行的命令编号 (1-$($similarCommands.Count))，或按Enter退出: " -NoNewline
                $choice = Read-Host
                
                if ($choice -match '^[1-9]$' -and [int]$choice -le $similarCommands.Count) {
                    $selectedCommand = $similarCommands[[int]$choice - 1].Name
                    $fixedCommand = $command -replace "^$commandName", $selectedCommand
                } else {
                    return
                }
            } else {
                Write-Host "找不到命令 '$commandName'，也没有找到相似的命令。" -ForegroundColor Red
                return
            }
        }
    }
    
    # 显示将要执行的修正后的命令
    Write-Host "`n修正后的命令: $fixedCommand" -ForegroundColor Green
    Write-Host "执行该命令？(y/N): " -NoNewline
    $confirm = Read-Host
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        # 执行修正后的命令
        Invoke-Expression $fixedCommand
    } else {
        Write-Host "命令已取消。" -ForegroundColor Yellow
    }
}

# 如果直接运行脚本，则执行函数
if ($MyInvocation.InvocationName -ne '.') {
    Fuck-Command
}