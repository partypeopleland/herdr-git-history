# Loaded by the user's PowerShell profile. Herdr supplies HC_TERMINAL_ID.
if ($env:HC_TERMINAL_ID -and -not $global:__herdr_git_history_prompt_installed) {
    $global:__herdr_git_history_prompt_installed = $true
    $global:__herdr_git_history_original_prompt = $function:prompt

    function global:prompt {
        $previousExitCode = $global:LASTEXITCODE
        $promptText = & $global:__herdr_git_history_original_prompt
        $current = Get-Location

        if ($current.Provider.Name -eq 'FileSystem') {
            $path = $current.ProviderPath
            if ($path -ne $global:__herdr_git_history_last_cwd) {
                $null = & hc label $env:HC_TERMINAL_ID "workspace.cwd=$path" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $global:__herdr_git_history_last_cwd = $path
                }
            }
        }

        $global:LASTEXITCODE = $previousExitCode
        $promptText
    }
}
