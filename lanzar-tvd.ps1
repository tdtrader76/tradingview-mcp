# Lanza TradingView Desktop (Microsoft Store) con CDP habilitado en puerto 9222
# USO: powershell -ExecutionPolicy Bypass -File lanzar-tvd.ps1 [-Port 9222] [-KillExisting]

param(
    [int]$Port = 9222,
    [switch]$KillExisting
)

if ($KillExisting) {
    Get-Process -Name "TradingView" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 800
}

# El cast COM debe hacerse en C# (no en PowerShell) para que QueryInterface funcione
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class TvdLauncher {
    [ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IApplicationActivationManager {
        int ActivateApplication([MarshalAs(UnmanagedType.LPWStr)] string aumid,
                                [MarshalAs(UnmanagedType.LPWStr)] string arguments,
                                int options, out uint pid);
        int ActivateForFile([MarshalAs(UnmanagedType.LPWStr)] string aumid,
                            IntPtr items, [MarshalAs(UnmanagedType.LPWStr)] string verb,
                            out uint pid);
        int ActivateForProtocol([MarshalAs(UnmanagedType.LPWStr)] string aumid,
                                IntPtr uris, out uint pid);
    }

    [ComImport, Guid("45BA127D-10A8-46EA-8AB7-56EA9078943C"), ClassInterface(ClassInterfaceType.None)]
    private class ApplicationActivationManager {}

    public static uint Launch(string aumid, string arguments) {
        var mgr = (IApplicationActivationManager)(new ApplicationActivationManager());
        uint pid = 0;
        int hr = mgr.ActivateApplication(aumid, arguments, 0, out pid);
        if (hr != 0) Marshal.ThrowExceptionForHR(hr);
        return pid;
    }
}
"@ -ErrorAction Stop

$aumid = "TradingView.Desktop_n534cwy3pjxzj!TradingView.Desktop"
$procId = [TvdLauncher]::Launch($aumid, "--remote-debugging-port=$Port")
Write-Host "OK  TradingView lanzado. PID=$procId  CDP=ws://127.0.0.1:$Port"
