throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# The session configuration is responsible for linking accounts to JEA roles

$sessionConfigParameters = @{
    # You should set all JEA configs to RestrictedRemoteServer or even empty
    SessionType          = 'RestrictedRemoteServer'

    # You can use it to configure transcription
    TranscriptDirectory  = 'C:\PSTranscript'

    # Give your users their own directory to exchange data
    MountUserDrive       = $true
    UserDriveMaximumSize = 10MB

    # To run all commands with a virtual, administrative account (per user)
    # If necessary, use RunAsVirtualAccountGroups to restrict the account
    RunAsVirtualAccount  = $true

    # Define a proper language mode for this endpoint, restricting what your admins can do
    LanguageMode         = 'ConstrainedLanguage'

    # Most importantly, add your roles!
    RoleDefinitions      = @{
        # RoleCapability: The name of your role capability file without extension
        'contoso\Domain Admins' = @{RoleCapabilities = 'LocalServiceAdmin'}

        # Adding multiple groups might result in a merging of capabilities!
    }
}

# Create the session configuration file in a different location - it does not need special protection
# It may be a good idea to distribute it alongside your JEA roles to deploy the configuration comfortably
New-PSSessionConfigurationFile @sessionConfigParameters -Path .\MySessionConfig.pssc

# Review
psedit .\MySessionConfig.pssc

# Register!
Register-PSSessionConfiguration -Path .\MySessionConfig.pssc -Name SupportSession
