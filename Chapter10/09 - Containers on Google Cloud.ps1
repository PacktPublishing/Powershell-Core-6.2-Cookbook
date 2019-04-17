throw 'Please execute this script as instructed in the recipe. Use the appropriate system (e.g. the lab domain controller, the lab file server, ...) where appropriate.'
return

# There are a couple of cmdlets to manage the GCloud Kubernetes Engine, GKE
Get-Command -Noun Gke*

# A cluster can be created with a specific node configuration for all cluster nodes
$nodeParameter = @{
    DiskSizeGb  = 10 
    MachineType = 'g1-small' 
    ImageType   = 'COS'
}
$nodeConfig = New-GkeNodeConfig @nodeParameter

# A Kubernets cluster also benefits from a node pool
$poolParameter = @{
    NodePoolName          = 'kube001pool'
    NodeConfig            = $nodeConfig
    MaximumNodesToScaleTo = 2
    MininumNodesToScaleTo = 1
    InitialNodeCount      = 1
    EnableAutoUpgrade     = $true
}
$nodePool = New-GkeNodePool @poolParameter

# Before being able to deploy a container, you will need create a new cluster
$clusterParameter = @{
    ClusterName = 'kube001' 
    Description = 'Kubernetes cluster DEV'
    NodePool    = $nodePool
    Region      = 'europe-west3'
    Zone        = 'europe-west3-a'
}

$cluster = Add-GkeCluster @clusterParameter

# To deploy an actual container into your new cluster, you will use kubectl (Part of Docker for Windows, for example)
# To install Docker, refer to Chapter 07, recipe 05 - Using Docker with Hyper-V containers

# Add kubectl if not done yet
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue))
{
    gcloud components install kubectl
}

# Now, store the credential information
gcloud container clusters get-credentials kube001

# With that done, deploy!
$project = Get-GcpProject -Name testproject
$imageName = 'eu.gcr.io/{0}/luckynumber:v1' -f $project.ProjectId
$clusterName = 'gke_{0}_{1}_{2}' -f $project.ProjectId, $cluster.Locations[0], $cluster.Name

kubectl.exe run numbergenerator --image $imageName --cluster $clusterName --port 8080

# Test it
Invoke-RestMethod -Uri http://$($cluster.Endpoint):8080/containerizedapi -Method Get