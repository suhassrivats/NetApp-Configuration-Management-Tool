//==================================================================//
//                                                                  //
// $Id: $                                                           //
// vollist.c                                                        //
//                                                                  //
// ONTAPI API lists volume information                              //
//                                                                  //
// This program demonstrates how to handle arrays                   //
//                                                                  //
// Copyright 2005 NetApp. All rights reserved. Specifications       //
// subject to change without notice.                                //
//                                                                  //
// This SDK sample code is provided AS IS, with no support or       //
// warranties of any kind, including but not limited to             //
// warranties of merchantability or fitness of any kind,            //
// expressed or implied.  This code is subject to the license       //
// agreement that accompanies the SDK.                              //
//                                                                  //
//                                                                  //
// Usage: vollist  <filer> <user> <password> [volume]               //
//==================================================================//
using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace vollist
{
    class VolList
    {
        static void Main(string[] args)
        {
            NaElement xi;
		    NaElement xo;
		    NaServer  s;
		
		    if ( args.Length < 3 ) {
			    Console.WriteLine("Usage : vollist <filername> <username> <passwd> [<volume>]");
                System.Environment.Exit(1);
		    }

            String Server = args[0], user = args[1], pwd = args[2];
		    
            try {
                
                Console.WriteLine("|--------------------------------------------------------|");
                Console.WriteLine("| Program to Demo use of Volume APIs to list Volume info |");
                Console.WriteLine("|--------------------------------------------------------|");
                
			    //Initialize connection to server, and
			    //request version 1.3 of the API set
			    //	
			    s = new NaServer(Server,1,3);
			    s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
			    s.SetAdminUser(user, pwd);

                //Create Vol list Info ONTAPI API
                xi = new NaElement("volume-list-info");
			    if(args.Length==4){
                    String volume_name = args[3];
				    xi.AddNewChild("volume",volume_name);
			    }

                //Invoke Vol list Info ONTAPI API
		    	xo = s.InvokeElem(xi);
			    //
			    //Get the list of children from element(Here 'xo') and iterate 
			    //through each of the child element to fetch their values
			    //	
                System.Collections.IList volList = xo.GetChildByName("volumes").GetChildren();
                System.Collections.IEnumerator volIter = volList.GetEnumerator();
			    while(volIter.MoveNext()){
				    NaElement volInfo=(NaElement)volIter.Current;
				    Console.WriteLine("---------------------------------");
				    Console.Write("Volume Name\t\t: ");
				    Console.WriteLine(volInfo.GetChildContent("name"));
                    Console.Write("Volume State\t\t: ");
				    Console.WriteLine(volInfo.GetChildContent("state"));
                    Console.Write("Disk Count\t\t: ");
				    Console.WriteLine(volInfo.GetChildIntValue("disk-count",-1));
                    Console.Write("Total Files\t\t: ");
				    Console.WriteLine(volInfo.GetChildIntValue("files-total",-1));
                    Console.Write("No of files used\t: ");
				    Console.WriteLine(volInfo.GetChildIntValue("files-used",-1));
                    Console.WriteLine("---------------------------------");
    			}
	    	}
		    catch (Exception e) {
                Console.Error.WriteLine(e.Message);  
		    }
	    }
    }
}
