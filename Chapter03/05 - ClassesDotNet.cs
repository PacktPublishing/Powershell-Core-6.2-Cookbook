using System.Collections.Generic;
//using System.DirectoryServices.ActiveDirectory;

namespace com.contoso
{
    public enum DeviceType
    {
        Mobile,
        Desktop,
        Server
    }
    public class Device
    {
        public string AssetTag { get; set; }
        public DeviceType DeviceType { get; set; }

        public Device(string assetTag, DeviceType deviceType = DeviceType.Server)
        {
            AssetTag = assetTag;
            DeviceType = deviceType;
        }

        public void UpdateFromCmdb()
        {
            // This method should connect to a CMDB to update the device info.
            // On the base class, only the device type would be updated
        }

        public static Device ImportFromCmdb()
        {
            // This static method could be used to import a device by its asset tag
            return new Device("aabbcc");
        }
    }

    public class Desktop : Device
    {
        public string MainUser { get; set; }
        public List<string> AdditionalUsers { get; set; }

        public Desktop(string assetTag, string mainUser, DeviceType deviceType = DeviceType.Desktop) : base(assetTag, deviceType)
        {
            AdditionalUsers = new List<string>();
            MainUser = mainUser;
        }

        public void AddUser(string userName)
        {
            AdditionalUsers.Add(userName);
        }
    }

    public class Server : Device
    {
        public string Location { get; set; }
        public string DomainName { get; set; }
        public bool IsDomainJoined
        {
            get { return GetDomainJoinStatus(); }
            private set { }
        }

        public Server (string assetTag, string location, string domainName, DeviceType deviceType = DeviceType.Server) : base(assetTag, deviceType)
        {
            Location = location;
            DomainName = domainName;
        }

        private bool GetDomainJoinStatus()
        {
            if (string.IsNullOrEmpty(DomainName)) return false;

            try
            {
                // With the ActiveDirectory libraries present, you could check for the domain 
                //var currentDomain = Domain.GetComputerDomain();
                //return currentDomain.Name.Equals(DomainName);
            }
            catch // ActiveDirectoryObjectNotFoundException aexc
            {
                // DO some error handling here
                return false;
            }

            return true;
        }
    }
}
