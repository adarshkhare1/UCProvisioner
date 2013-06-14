using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace UCProvisioner
{   
    public class ProvisioningClient
    {
        private readonly string userName;

        /// <summary>
        /// 
        /// </summary>
        /// <param name="userId"></param>
        public ProvisioningClient(string userId)
        {
            userName = userId;
        }

        public string UserName
        {
            get
            {
                return userName;
            }
        }

    }
}
