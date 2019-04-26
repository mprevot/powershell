$systemdll = "
KERNEL32.dll
SHELL32.dll
MSVCP140D.dll
WS2_32.dll
VCRUNTIME140D.dll
ucrtbased.dll
MSVCP140.dll
VCRUNTIME140.dll
api-ms-win-crt-runtime-l1-1-0.dll
api-ms-win-crt-heap-l1-1-0.dll
api-ms-win-crt-math-l1-1-0.dll
api-ms-win-crt-stdio-l1-1-0.dll
api-ms-win-crt-string-l1-1-0.dll
api-ms-win-crt-convert-l1-1-0.dll
api-ms-win-crt-environment-l1-1-0.dll
api-ms-win-crt-time-l1-1-0.dll
api-ms-win-crt-filesystem-l1-1-0.dll
api-ms-win-crt-locale-l1-1-0.dll
"

$alldlls = get-childitem -recurse *dll

function Except($a, $b) {
	return $a | Where-Object { -not ($b -contains $_) }
}

function ToObjects($list) {
	return $list.Split("`n|`r") | Where-Object { ![string]::IsNullOrEmpty($_) }
}

function GetDependents($rootdll) {
	return dumpbin.exe /dependents /nologo $rootdll `
	| Where-Object { $_ -like '*.dll' -and $_.startswith(' ') } `
	| ForEach-Object { $_.trim() }
}

function GetDir($path) {
	$pathObject = Get-Item -path $path | Select-Object -index 0
	return  ($pathObject.FullName -split ($pathObject.Name))[0]
}

function GetPath($list) {
	$pathlist = @()
	foreach ($item in $list) {
		$pathlist += $alldlls | Where-Object { $_.Name -eq $item } | ForEach-Object { ($_.FullName -split ($_.Name))[0] }
	}
	return ($pathlist | Get-Unique) -join ";"
}

function PrintDependentsAndPath($pathToRootDll, $tag) {
	Write-Host "$tag dll:" -ForegroundColor Yellow
	$result = Except (ToObjects (GetDependents $pathToRootDll)) (ToObjects $systemdll)
	$result
	Write-Host "$tag path:" -ForegroundColor Yellow
	(GetDir $pathToRootDll) + ";" + (GetPath $result)
}


PrintDependentsAndPath "C:\lib\oiio\bin\OpenImageIO.dll" debug
""
PrintDependentsAndPath "C:\lib\oiio-release\bin\OpenImageIO.dll" release
""
