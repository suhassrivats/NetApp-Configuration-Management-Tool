//==================================================================//
//                                                                  //
// $Id: $                                                           //
// PSSnapin.cs                                                      //
//                                                                  //
// Snap-in for installing ONTAP version cmdlet.                     //
// Copyright 2009 NetApp. All rights reserved. Specifications       //
// subject to change without notice.                                //
//                                                                  //
// This SDK sample code is provided AS IS, with no support or       //
// warranties of any kind, including but not limited to             //
// warranties of merchantability or fitness of any kind,            //
// expressed or implied.  This code is subject to the license       //
// agreement that accompanies the SDK.                              //
//                                                                  //
//                                                                  //
//==================================================================//

using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;
using System.ComponentModel;

namespace NetApp.ManageOntap.Configuration
{

    //This class is used to create a snap-in for ONTAP version cmdlet.
    [RunInstaller(true)]
    public class VersionSnapIn : PSSnapIn
    {
        // Name for the PowerShell snap-in.
        public override string Name
        {
            get
            {
                return "NetApp.ManageOntap.Version";
            }
        }

        // Vendor information for the PowerShell snap-in.
        public override string Vendor
        {
            get
            {
                return "NetApp";
            }
        }

        // Description of the PowerShell snap-in
        public override string Description
        {
            get
            {
                return "This is a PS snap-in which registers ONTAP version cmdlet";
            }
        }
    }
}
