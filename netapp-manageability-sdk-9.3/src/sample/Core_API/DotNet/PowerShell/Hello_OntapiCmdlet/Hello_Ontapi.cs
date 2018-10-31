//==================================================================//
//                                                                  //
// $Id: $                                                           //
// Hello_Ontapi.cs                                                  //
//                                                                  //
// This sample code demonstrates how to create a cmdlet to obtain   //
// the ONTAP version of a Filer.                                    //        
//                                                                  //
// Copyright 2009 NetApp. All rights reserved. Specifications       //
// subject to change without notice.                                //
//                                                                  //
// This SDK sample code is provided AS IS, with no support or       //
// warranties of any kind, including but not limited to             //
// warranties of merchantability or fitness of any kind,            //
// expressed or implied.  This code is subject to the license       //
// agreement that accompanies the SDK.                              //
//                                                                  //
// Usage: Get-Version -server <server> -user <user>                 //     
//      -passwd <password>                                          //
//                                                                  //
// Compile the project which will generate hello_ontapi.dll         //
// Perform the hello_ontapi.dll installation with .NET using        //
//    InstallUtil.exe command.                                      //
// Add the snapin to PowerShell using the command:                  //
//      add-pssnapin NetApp.ManageOntap.Version                     //
// To remove the snapin, do so with this command:                   //
//      remove-pssnapin NetApp.ManageOntap.Version                  //
//  To execute, issue this command:                                 //
//     Get-Version -server <server> -user <user> -passwd <password> //     
//                                                                  //
//==================================================================//

using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;
using System.ComponentModel;
using NetApp.Manage;

namespace NetApp.ManageOntap.CmdLets.Version
{
    // Get-Version Cmdlet - This cmdlet will list the 
    // ONTAP version on a Filer.
    [Cmdlet(VerbsCommon.Get, "Version")]
    public class Getversion : PSCmdlet
    {
        private string _server = null;
        private string _user = null;
        private string _passwd = null;

        [Parameter(
            Position = 0,
            HelpMessage = "Name of the Server")]
        public string Server
        {
            get { return _server; }
            set { _server = value; }
        }

        [Parameter(
            Position = 0,
            HelpMessage = "User Name")]
        public string User
        {
            get { return _user; }
            set { _user = value; }
        }

        [Parameter(
            Position = 0,
            HelpMessage = "Password")]
        public string Passwd
        {
            get { return _passwd; }
            set { _passwd = value; }
        }

        public String Usage
        {
            get { return "Usage: Get-Version -server <server> -user <user> -passwd <password>"; }
        }

        protected override void ProcessRecord()
        {
            if (_server == null || _user == null || _passwd == null)
            {
                WriteObject(Usage);
                return;
            }

            try
            {
                NaServer server = new NaServer(_server, 1, 0);
                server.SetAdminUser(User, Passwd);
                NaElement output = server.Invoke("system-get-version");
                String version = output.GetChildContent("version");
                WriteObject("Hello world!  DOT version of " + _server + " is: " + version);
            }
            catch (Exception e)
            {
                WriteObject(e.Message);
            }
        }
    }
}
