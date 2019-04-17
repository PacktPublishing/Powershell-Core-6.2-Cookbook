# The image our container is based on
FROM mcr.microsoft.com/powershell:6.2.0-nanoserver-1809

# Our image requires a port to be opened
EXPOSE 8080

# Copy the Polaris module
COPY ["Polaris/", "C:/Program Files/PowerShell/Modules/Polaris/"]

# Copy the script
COPY startpolaris.ps1 startpolaris.ps1

# We want to run something
CMD ["pwsh.exe", "-File", "./startpolaris.ps1"]
