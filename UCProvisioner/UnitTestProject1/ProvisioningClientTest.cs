using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using UCProvisioner;

namespace UCProvisionerTest
{
    [TestClass]
    public class ProvisioningClientTest
    {
        [TestMethod]
        public void TestUserName()
        {
            string testUserName = "testId";
            ProvisioningClient client = new ProvisioningClient(testUserName);
            Assert.AreEqual(testUserName, client.UserName, "UserName");

        }
    }
}
