using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace UCProvisioner
{
    class Program
    {
        static void Main(string[] args)
        {
            string s = Console.ReadLine();
            ProvisioningClient client = new ProvisioningClient(s);
            Console.WriteLine(client.UserName);
        }
    }
}
