using System;

namespace Stuff
{
    internal class ServiceRunner : System.ServiceProcess.ServiceBase
    {
        protected static void Startup(string[] args, ServiceRunner instance, bool interactiveWait)
        {
            if (instance == null)
                throw new ArgumentNullException("instance");

            if (Environment.UserInteractive)
            {
                instance.OnStart(args);
                if (interactiveWait)
                {
                    Console.WriteLine("Press any key to stop service");
                    Console.ReadKey();
                }
                instance.OnStop();
            }
            else
                Run(instance);
        }
    }

    internal class MyService : ServiceRunner
    {
        public MyService()
        {
            ServiceName = "JustALittleDummy";
        }

        private static void Main(string[] args)
        {
            Startup(args, new MyService(), true);
        }

        protected override void OnStart(string[] args)
        {
            base.OnStart(args);
        }


        protected override void OnStop()
        {
            base.OnStop();
        }
    }
}