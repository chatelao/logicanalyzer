param (
    [Parameter(Mandatory=$true)]
    [string]$packageVersion
)

# Nombres de archivos a publicar
$projectNames = @("LogicAnalyzer", "TerminalCapture")
$mergedName = "all-in-one_$packageVersion"

# Crear la carpeta de paquetes si no existe
$packagesDir = Join-Path $PSScriptRoot "..\Packages"
if (-not (Test-Path $packagesDir)) {
    New-Item -ItemType Directory -Path $packagesDir
}

# Limpia las subcarpetas carpeta de paquetes
Get-ChildItem -Path $packagesDir -Directory | Remove-Item -Recurse -Force

# Crea la carpeta de mezcla si no existe
$mergedDir = Join-Path $PSScriptRoot "..\Merged"
if (-not (Test-Path $mergedDir)) {
    New-Item -ItemType Directory -Path $mergedDir
}

# Limpia la carpeta de mezcla
Get-ChildItem -Path $mergedDir -Directory | Remove-Item -Recurse -Force

foreach($projectName in $projectNames)
{
    # Publicar cada proyecto
    Write-Host "Publicando proyecto: $projectName"

    # Nombre del paquete
    $packageName = $projectName.ToLower() + "_" + $packageVersion

    # Ruta al archivo .csproj del proyecto que deseas publicar
    $projectPath = Join-Path $PSScriptRoot "$projectName\$projectName.csproj"

    # Leer la versión del framework desde el archivo .csproj
    [xml]$csproj = Get-Content $projectPath
    $targetFramework = $csproj.Project.PropertyGroup.TargetFramework

    # Ruta a la carpeta de publicación
    $publishDir = Join-Path $PSScriptRoot "$projectName\bin\Release\$targetFramework\publish"

    # Limpiar la carpeta de publicación
    if (Test-Path $publishDir) {
        Remove-Item -Recurse -Force $publishDir
    }

    # Compilar el proyecto
    dotnet build $projectPath -c Release

    # Obtener todos los perfiles de publicación
    $profiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "$projectName") -Recurse -Filter "*.pubxml" | Select-Object -ExpandProperty FullName

    # Publicar usando cada perfil
    foreach ($profile in $profiles) {
        $profileName = [System.IO.Path]::GetFileNameWithoutExtension($profile)
        Write-Host "Publicando perfil: $profileName"
        dotnet publish $projectPath -c Release -p:PublishProfile=$profileName
    }

    # Empaquetar los resultados
    $publishSubDirs = Get-ChildItem -Path $publishDir -Directory
    foreach ($subDir in $publishSubDirs) {
        $architecture = $subDir.Name
        $zipPath = "$packagesDir\$packageName-$architecture.zip"

        Write-Host "Copia de $subDir a $mergedDir\$architecture"

        # Copiar los archivos a la carpeta de mezcla
        Copy-Item -Recurse -Force $subDir.FullName $mergedDir

        Write-Host "Empaquetando $subDir en $zipPath"

        # Eliminar el archivo ZIP si ya existe
        if (Test-Path $zipPath) {
            Remove-Item -Force $zipPath
        }

        # Excluir los paquetes de Windows
        if ($architecture -notmatch "win") {
            bash -c "cd '$($subDir.FullName)' && chmod +x $projectName && zip -r '$zipPath' ."
        } else {
            Compress-Archive -Path "$($subDir.FullName)\*" -DestinationPath $zipPath
        }
    }

}

# Empaquetar los resultados en un solo archivo por arquitectura
$mergedSubDirs = Get-ChildItem -Path $mergedDir -Directory
foreach ($subDir in $mergedSubDirs) {
    $architecture = $subDir.Name
    $zipPath = "$packagesDir\$mergedName-$architecture.zip"

    Write-Host "Empaquetando $subDir.FullName en $zipPath"

    # Eliminar el archivo ZIP si ya existe
    if (Test-Path $zipPath) {
        Remove-Item -Force $zipPath
    }

    # Excluir los paquetes de Windows
    if ($architecture -notmatch "win") {
        bash -c "cd '$($subDir.FullName)' && chmod +x LogicAnalyzer TerminalCapture && zip -r '$zipPath' ."

    } else {
        Compress-Archive -Path "$($subDir.FullName)\*" -DestinationPath $zipPath
    }
}

# Limpiar carpeta de mezcla
Get-ChildItem -Path $mergedDir -Directory | Remove-Item -Recurse -Force