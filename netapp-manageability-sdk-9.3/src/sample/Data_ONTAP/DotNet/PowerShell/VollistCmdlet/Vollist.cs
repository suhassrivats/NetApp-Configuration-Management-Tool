//==================================================================//
//                                                                  //
// $Id: $                                                           //
// Vollist.cs                                                       //
//                                                                  //
// This sample code demonstrates how to create a cmdlet for         //
// listing NetApp volumes.                                          //
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
// Usage: Get-Volume -server <server> -user <user> -passwd          //    
//    <password> [-name <volume>]                                   //
//                                                                  //
// Compile the project which will generate vollist.dll.             //
// Perform the vollist.dll installation with .NET using             //
//    InstallUtil.exe command.                                      //
// Add the snapin to PowerShell using the command:                  //
//      add-pssnapin NetApp.ManageOntap.Volume                      //
// To remove the snapin, do so with this command:                   //
//      remove-pssnapin NetApp.ManageOntap.Volume                   //
//  To execute, issue this command:                                 //
//      Get-Volume -server <server> -user <user> -passwd            //
//          <password> [-name <volume>]                             //
//==================================================================//

using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;
using System.ComponentModel;
using NetApp.Manage;

namespace NetApp.ManageOntap.CmdLets.Volume
{
    // Get-Volume Cmdlet - This cmdlet will list the 
    // volumes on a Filer.
    [Cmdlet(VerbsCommon.Get, "Volume")]
    public class GetVolume : PSCmdlet
    {
        private string _server = null;
        private string _user = null;
        private string _passwd = null;
        private string _volume = null;

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

        [Parameter(
            Position = 0,
            HelpMessage = "Name of the volume")]
        public string Name
        {
            get { return _volume; }
            set { _volume = value; }
        }

        public String Usage
        {
            get { return "Usage: Get-Volume -server <server> -user <user> -passwd <password> [-name <volume>]"; }
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
                NaElement input = new NaElement("volume-list-info");
                server.SetAdminUser(User, Passwd);
                if (_volume != null)
                {
                    input.AddNewChild("volume", _volume);
                }
                NaElement output = server.InvokeElem(input);

                System.Collections.IList volList = output.
                    GetChildByName("volumes").GetChildren();
                System.Collections.IEnumerator volIter = volList.GetEnumerator();
                WriteObject("\n------------------------------------------------------------------------");
                WriteObject("Name \t type \t state \t size-total \t size-used \t size-available");
                WriteObject("------------------------------------------------------------------------");
                String vol = "";
                while (volIter.MoveNext())
                {
                    NaElement volInfo = (NaElement)volIter.Current;
                    vol = volInfo.GetChildContent("name") + "\t" + 
                        volInfo.GetChildContent("type") + "\t" + 
                        volInfo.GetChildContent("state") + "\t" + 
                        volInfo.GetChildContent("size-total") + "\t" + 
                        volInfo.GetChildContent("size-used") + "\t" + 
                        volInfo.GetChildContent("size-available");
                    WriteObject(vol);
                }
                WriteObject("------------------------------------------------------------------------\n");
            }
            catch (Exception e)
            {
                WriteObject(e.Message);
            }
        }
    }
}
