//============================================================//
//                                                            //
// $Id: //depot/prod/zephyr/belair/src/sample/DotNet/C%23/hello_ontapi/hello_ontapi.cs#1 $                                                       //
//                                                            //
// hello_ontapi.cs                                            //
//                                                            //
// Hello World for the ONTAPI APIs                            //
//                                                            //
// Copyright 2008 NetApp. All rights reserved. Specifications //
// subject to change without notice.                          // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
//                                                            //
// Usage: hello_ontapi <filer> <user> <password>              //
//                                                            //
//============================================================//

using System;
using System.Text;
using NetApp.Manage;

namespace hello_ontapi
{
    class HelloOntapi
    {
        static void Main(string[] args)
        {
            NaServer s;
            NaElement xi, xo;
       		if (args.Length < 3)
	    	{
		    	Console.Error.WriteLine("Usage: hello_ontapi  filer user passwd");
			    Environment.Exit(1);
		    }
            String Server = args[0];
            String User = args[1];
            String Pwd = args[2];
		    try
		    {
                Console.WriteLine("|---------------------------------------------------------------|");
                Console.WriteLine("| Program to Demo a simple API call to query Data ONTAP Version |");
                Console.WriteLine("|---------------------------------------------------------------|\n");
                //Initialize connection to server, and
			    //request version 1.3 of the API set
			    //	
			    s = new NaServer(Server, 1, 0);
                s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
                s.SetAdminUser(User, Pwd);
            	
			    //Invokes ONTAPI API to get the Data ONTAP 
			    //version number of a filer		
			    xi = new NaElement("system-get-version");
                xo = s.InvokeElem(xi);
                //Parse output
                String output = xo.GetChildContent("version");
                //Print output
                Console.Out.WriteLine("Hello! " + 
                    "Data ONTAP version of " + Server + " is \"" + output + "\"");
            }
            catch (NaException e)
            {
                //Print the error message
                Console.Error.WriteLine(e.Message);   
            }
		    catch (System.Exception e)
		    {
			    Console.Error.WriteLine(e.Message);
            }
	    }
    }
}
