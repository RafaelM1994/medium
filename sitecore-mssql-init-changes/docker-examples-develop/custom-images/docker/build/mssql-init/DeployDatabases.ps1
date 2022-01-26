[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$ResourcesDirectory,

    [string]$SqlServer = "(local)",

    [string]$SqlAdminUser,

    [string]$SqlAdminPassword,

    [string]$DatabaseOwner,

    [switch]$EnableContainedDatabaseAuth,

    [switch]$SkipStartingServer,
    
    [string]$SqlElasticPoolName,

    [string]$DatabasesToDeploy
)

function Invoke-Sqlcmd {
    param(
        [string]$SqlDatabase,
        [string]$SqlServer,
        [string]$SqlAdminUser,
        [string]$SqlAdminPassword, 
        [string]$Query
    )

    $arguments = " -Q ""$Query"" -S '$SqlServer' "

    if($SqlAdminUser -and $SqlAdminPassword) {
        $arguments += " -U '$SqlAdminUser' -P '$SqlAdminPassword'"
    }
    if($SqlDatabase) {
        $arguments += " -d '$SqlDatabase'"
    }

    Invoke-Expression "sqlcmd $arguments"
}

function Add-SqlAzureConditionWrapper {
    param(
        [string]$SqlQuery
    )
    
    return "DECLARE @serverEdition nvarchar(256) = CONVERT(nvarchar(256),SERVERPROPERTY('edition'));
        IF @serverEdition <> 'SQL Azure'
        BEGIN
            $SqlQuery
        END;
        GO"
}

function New-DatabaseElasticPool {
    param(
        [string]$SqlElasticPoolName,
        [string]$SqlServer,
        [string]$SqlAdminUser,
        [string]$SqlAdminPassword,
        [string]$SqlDatabase
    )
    Write-Host "Start creating database '$SqlDatabase' with azure elastic pool '$SqlElasticPoolName'"
    $Query = "CREATE DATABASE [$SqlDatabase]
    ( SERVICE_OBJECTIVE = ELASTIC_POOL ( name = [$SqlElasticPoolName] ))"

    & sqlcmd -Q $Query -S "$SqlServer" -U "$SqlAdminUser" -P "$SqlAdminPassword"

    if($LASTEXITCODE -ne 0) {
        throw "sqlcmd exited with code $LASTEXITCODE while creating database $databaseName with elasic pool"
    }
}

if(-not $SkipStartingServer){
    Start-Service MSSQLSERVER;
}

Write-Host "Start publishing dacpacs"

if($EnableContainedDatabaseAuth) {
    $sqlcmd = Add-SqlAzureConditionWrapper -SqlQuery "DECLARE @containedAuthenticationEnabled int = CONVERT(int, (SELECT [value] FROM sys.configurations WHERE name = 'contained database authentication'));
    IF @containedAuthenticationEnabled = 0
    BEGIN
        EXEC sys.sp_configure N'contained database authentication', N'1'
        exec ('RECONFIGURE WITH OVERRIDE')
    END"

    Invoke-Sqlcmd -SqlServer:$SqlServer -SqlAdminUser:$SqlAdminUser -SqlAdminPassword:$SqlAdminPassword -Query $sqlcmd
    if($LASTEXITCODE -ne 0) {
        throw "sqlcmd exited with code $LASTEXITCODE"
    }
    Write-Verbose "Enabled contained databases"
}

$sqlPackageExePath = "C:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe"

$resourcesDirectories = @()

if ([string]::IsNullOrEmpty($DatabasesToDeploy)) {
    $resourcesDirectories = @($ResourcesDirectory)
    $resourcesDirectories += Get-ChildItem $ResourcesDirectory -Directory | Select-Object -ExpandProperty FullName
} else {
    $DatabasesToDeploy.Split(',') | ForEach-Object {
        $moduleDacpacsFolder = $_
        $modulesFolderPath = "$ResourcesDirectory\$moduleDacpacsFolder"
        
        if (Test-Path $modulesFolderPath -PathType Container) {
            Write-Information -MessageData "Adding dacpacs from $moduleDacpacsFolder to deploy" -InformationAction Continue
            $resourcesDirectories += $modulesFolderPath
        } else {
            Write-Warning "Folder with dacpacs for $moduleDacpacsFolder does not exist"
        }
    }
}

$resourcesDirectories | ForEach-Object {
    Get-ChildItem $_ -Filter *.dacpac | ForEach-Object {
        $dacpac = $_
        $sourceFile = $dacpac.FullName
        $databaseName = "DEV.$($dacpac.BaseName)"

        $ConnectionString = "Data Source=$SqlServer;database=$databaseName;User ID=$SqlAdminUser;Password=$SqlAdminPassword;"
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
        try{$sqlConnection.Open();}catch{}
        $state = $sqlConnection.State
        $sqlConnection.Close();

        if ($databaseName -like "*Azure" -or $databaseName -eq "Sitecore.Xdb.Collection.Database.Sql" `
            -or $databaseName -like "Sitecore.Xdb.Collection.Shard*" -or $state -eq "Open") {
            Write-Verbose "Skip $($databaseName) database"
            return
        }


        if ($SqlElasticPoolName -and -not $DatabasesToDeploy) {
            New-DatabaseElasticPool -SqlElasticPoolName $SqlElasticPoolName -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword -SqlDatabase $databaseName
        }

        $scriptDatabaseOptions = "True"
        if (![string]::IsNullOrEmpty($DatabasesToDeploy)) {
            $scriptDatabaseOptions = "False"
        }

        if($SqlAdminUser -and $SqlAdminPassword) {
            & $sqlPackageExePath /a:Publish /sf:$sourceFile /tsn:"$SqlServer" /tdn:$databaseName /tu:"$SqlAdminUser" /tp:"$SqlAdminPassword" /p:AllowIncompatiblePlatform=True /p:ScriptDatabaseOptions=$scriptDatabaseOptions
        } else {
            & $sqlPackageExePath /a:Publish /sf:$sourceFile /tsn:"$SqlServer" /tdn:$databaseName /p:AllowIncompatiblePlatform=True /p:ScriptDatabaseOptions=$scriptDatabaseOptions
        }

        if($LASTEXITCODE -ne 0) {
            throw "sqlpackage exited with code $LASTEXITCODE while deploying $sourceFile"
        }
        
        Write-Information -Message "Deployed $($databaseName) database" -InformationAction Continue        
        
        if (![string]::IsNullOrEmpty($DatabaseOwner) -and -not $DatabasesToDeploy) {
            $sqlcmd = Add-SqlAzureConditionWrapper -SqlQuery "EXEC sp_changedbowner '$DatabaseOwner'"
        
            Invoke-Sqlcmd -SqlServer:$SqlServer -SqlAdminUser:$SqlAdminUser -SqlAdminPassword:$SqlAdminPassword -SqlDatabase "$databaseName" -Query $sqlcmd
            
            if($LASTEXITCODE -ne 0) {
                throw "sqlcmd exited with code $LASTEXITCODE while changing owner of $databaseName"
            }
            Write-Verbose "$($databaseName) database owner is changed to $DatabaseOwner"
        }
    }
}

if(-not $SkipStartingServer){
    Stop-Service MSSQLSERVER;
}