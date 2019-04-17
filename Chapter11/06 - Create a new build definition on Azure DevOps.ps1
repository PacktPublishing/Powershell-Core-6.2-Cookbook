throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# To automate the creation of a build pipeline, you can use PowerShell as well
# This process is a bit more involved though.

# With an access token, you can get started
$accessTokenString = ''

# We are crafting an authorization header that bears your token
$tokenString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f '', $accessTokenString)))
$authHeader = ("Basic {0}" -f $tokenString)

$baseuri = 'https://dev.azure.com/<YOURUSERNAME!>'
$headers = @{ Authorization = $authHeader }

# To create a build definition, you need a project first. If you have not done so already
# refer to the previous recipe.
$project = Invoke-RestMethod -Method Get -Uri "$baseuri/_apis/projects/PowerShellCookBook?api-version=5.0" -UseBasicParsing -Headers $headers

# For a build to make sense, your project should provide some tangible result. These results
# are usually artifacts like MOF files for DSC, nupkg files, ...

# Clone your projects repo
$repo = (Invoke-RestMethod -Method Get -Uri "$baseuri/PowerShellCookBook/_apis/git/repositories?api-version=5.0" -UseBasicParsing -Headers $headers).value
git clone $repo.remoteurl BookRepo
cd ./BookRepo

# Let's create a very simple build process consisting of one test suite and one artifact generator
$tests = {
    Describe 'A test suite' {
        It 'Should have meaningful tests' {
            42 | Should -Be 42
        }

        It 'should cover all code paths but not add unnecessary tests' {
            {throw "whyyy"} | Should -Throw -Because 'Some tests actually test the worst case as well'
        }

        It 'Might have failing tests' {
            0 | Should -Be 1
        }
    }
}
$tests.Invoke()

New-Item -ItemType Directory -Path ./Tests/Unit -Force
$tests.ToString() | Set-Content .\Tests\Unit\simpletest.tests.ps1

# Now, Invoke-Pester can also be ran with your directory as the base
Invoke-Pester -Script .\Tests

# Next, we could have a simple configuration that is getting created
$artifactGenerator = {
    configuration PipelineConfig
    {
        File foo
        {
            DestinationPath = 'C:\foo'
            Type            = 'File'
            Contents        = 'Greetings from the Pipeline!'
        }
    }
}
$artifactGenerator.ToString() | Set-Content Config.ps1

# A build script could be used to react to the test results, regardless of the pipeline
$buildscript = {
    Install-PackageProvider -Name NuGet -Force
    $null = mkdir -Path C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet -Force
    $null = Invoke-WebRequest -Uri 'https://nuget.org/nuget.exe' -OutFile C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet\nuget.exe -ErrorAction Stop

    Install-Module -Name PackageManagement -RequiredVersion 1.1.7.0 -Force -WarningAction SilentlyContinue -SkipPublisherCheck
    Install-Module -Name PowerShellGet -RequiredVersion 1.6.0 -Force -WarningAction SilentlyContinue -SkipPublisherCheck
    Install-Module Pester -Force -SkipPublisherCheck -WarningAction SilentlyContinue
    $results = Invoke-Pester .\Tests -PassThru -OutputFile TestResults.xml -OutputFormat NUnitXml

    if ($results.FailedCount -gt 0)
    {
        Write-Verbose 'Some or all tests have failed. Review the results.'
        return
    }

    . .\Config.ps1
    PipelineConfig -OutputPath .\BuildOutput
}
$buildscript.ToString() | Set-Content Build.ps1

# Commit your changes
git add .
git commit -m "added test and build script"
git push

<#
The build is very simple
1. Execute Build.ps1
2. Publish test results
3. Publish build artifacts

We do have to get the GUID of possible build steps first, though.
#>

$buildStepResult = Invoke-RestMethod -Method Get -Uri "$baseuri/_apis/distributedtask/tasks" -Headers $headers -UseBasicParsing
$buildSteps = ($buildStepResult | ConvertFrom-Json -AsHashtable).value

# One build definition consists of multiple build steps. Use Where-Object to find what we need
$groupedSteps = $buildSteps | Where-Object {
    $_.friendlyName -in 'PowerShell', 'Publish Test Results', 'Publish Build Artifacts' -and `
        $_.visibility -contains 'build' -and $_.runsOn -contains 'Agent'     
} | Group-Object friendlyName -AsHashTable

# Using ID and Inputs of your steps, generate the build definition
$groupedSteps.PowerShell[0].id
$groupedSteps.PowerShell[0].inputs.name

$groupedSteps.'Publish Test Results'[0].id
$groupedSteps.'Publish Test Results'[0].inputs.name

$groupedSteps.'Publish Build Artifacts'[0].id
$groupedSteps.'Publish Build Artifacts'[0].inputs.name

# To use these steps, we can create a build definition
$buildDefinition = @{
    name       = 'CI Build'
    type       = "build"
    quality    = "definition"
    queue      = @{ }
    process    = @{
        phases = @(
            @{
                name      = 'Phase 1'
                condition = 'succeeded()'
                steps     = @(
                    # Add your steps here!
                    @{
                        enabled         = $true
                        continueOnError = $false
                        alwaysRun       = $false
                        displayName     = 'Execute build script' # e.g. $($step.instanceNameFormat) or $($step.friendlyName)
                        task            = @{
                            id          = $groupedSteps.PowerShell[0].id
                            versionSpec = '*'
                        }
                        inputs          = @{
                            filePath = '.\Build.ps1'
                            pwsh     = $true
                        }
                    }
                    @{
                        enabled         = $true
                        continueOnError = $false
                        alwaysRun       = $false
                        displayName     = 'Publish test results' # e.g. $($step.instanceNameFormat) or $($step.friendlyName)
                        task            = @{
                            id          = $groupedSteps.'Publish Test Results'[0].id
                            versionSpec = '*'
                        }
                        inputs          = @{ 
                            testResultsFiles = '*TestResults.xml'
                            testResultFormat = 'NUnit'
                        }
                    }
                    @{
                        enabled         = $true
                        continueOnError = $false
                        alwaysRun       = $false
                        displayName     = 'Publish artifacts' # e.g. $($step.instanceNameFormat) or $($step.friendlyName)
                        task            = @{
                            id          = $groupedSteps.'Publish Build Artifacts'[0].id
                            versionSpec = '*'
                        }
                        inputs          = @{ 
                            PathtoPublish = './BuildOutput'
                            ArtifactName  = 'MOFs'
                            ArtifactType  = 'Container'
                        }
                    }
                )
            }
        )
    }
    repository = @{
        id            = $repo.id
        type          = "TfsGit"
        name          = $repo.name
        defaultBranch = "refs/heads/master"
        url           = $repo.remoteUrl
        clean         = $false
    }
    triggers   = @{
        branchFilters                = "refs/heads/master"
        maxConcurrentBuildsPerBranch = 1
        pollingInterval              = 0
        triggerType                  = 2
    }
    options    = @(
        @{
            enabled    = $true
            definition = @{
                id = (New-Guid).Guid
            }
            inputs     = @{
                parallel    = $false
                multipliers = '["config","platform"]'
            }
        }
    )
    variables  = @{
        forceClean = @{
            value         = $false
            allowOverride = $true
        }
        config     = @{
            value         = "debug, release"
            allowOverride = $true
        }
        platform   = @{
            value         = "any cpu"
            allowOverride = $true
        }
    }
} | ConvertTo-Json -Depth 42

Invoke-RestMethod -Method Post -Uri "$baseuri/PowerShellCookBook/_apis/build/definitions?api-version=5.0" -Body $buildDefinition -ContentType application/json -Headers $headers

# to trigger an automatic build, all you need to do is push a new commit.
# e.g. Correct the test case
(Get-Content .\Tests\Unit\simpletest.tests.ps1) -replace '0 \| Should -Be 1', '0 | Should -Be 0' | Set-Content .\Tests\Unit\simpletest.tests.ps1
git add .
git commit -m "Tests are OK now!"
git push
