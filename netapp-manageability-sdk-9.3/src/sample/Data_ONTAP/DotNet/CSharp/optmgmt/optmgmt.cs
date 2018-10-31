//==========================================================================//
//                                                                          //
// $Id: $                                                                   //
// optmgmt.cs                                                               //
//                                                                          //
// ONTAPI API lists option information, get value of a specific             //
// option, and set value for a specific option.                             //
//                                                                          //
// This program demonstrates how to handle arrays                           //
//                                                                          //
// Copyright 2008 NetApp. All rights reserved. Specifications subject to    //
// change without notice.                                                   //
//                                                                          //
// This SDK sample code is provided AS IS, with no support or               //
// warranties of any kind, including but not limited to                     //
// warranties of merchantability or fitness of any kind,                    //
// expressed or implied.  This code is subject to the license               //
// agreement that accompanies the SDK.                                      //
//                                                                          //
//                                                                          //
// Usage:                                                                   // 
// optmgmt <filer> <user> <password> [<operation>] [<optionName>] [<value>] //
// <filer>  --  Name/IP address of the filer                                //
// <user>   --  User name                                                   //
// <password> -- Password                                                   //
// <operation> 	-- get/set                                                  //
// <optionName>	-- Name of the option on which get/set operation            // 
//          needs to be performed                                           //
//  <value>     -- This is required only for set operation.                 //
//  Provide the value that needs to be assigned for                         //
//  the option                                                              //   
//==========================================================================//

using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace optmgmt
{
    class OptMgmt
    {
        static void Main(string[] args)
        {
            NaElement xi;
            NaElement xo;
            NaServer s;
            String op;

            if (args.Length < 3)
            {
                Console.Out.Write("Usage : optmgmt <filername> " + "<username> <passwd> [operation(get/set)] " + "[<optionName>] [<value>]");
                Environment.Exit(1);
            }
            try
            {
                Console.WriteLine("|------------------------------------------------|");
                Console.WriteLine("| Program to Demo use of OPTIONS MANAGEMENT APIs |");
                Console.WriteLine("|------------------------------------------------|");
                //Initialize connection to server, and
                //request version 1.3 of the API set
                //	
                s = new NaServer(args[0], 1, 1);
                s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
                s.SetAdminUser(args[1], args[2]);

                //Invoke option list Info ONTAPI API
                if (args.Length > 3)
                {
                    op = args[3];

                    //
                    // Get value of a specific option
                    //
                    if (0 == String.Compare(op, "get"))
                    {
                        xi = new NaElement("options-get");
                        if (args.Length == 5)
                            xi.AddNewChild("name", args[4]);
                        else
                        {
                            Console.Error.WriteLine("Improper number of arguments. Correct and re-run.");
                            Environment.Exit(1);
                        }
                        
                        xo = s.InvokeElem(xi);
                        Console.Out.WriteLine("----------------------------");
                        Console.Out.Write("Option Value:");
                        Console.Out.WriteLine(xo.GetChildContent("value"));
                        Console.Out.Write("Cluster Constraint:");
                        Console.Out.WriteLine(xo.GetChildContent("cluster-constraint"));
                        Console.Out.WriteLine("----------------------------");
                    }
                    //
                    // Set value of a specific option
                    else if (0 == String.Compare(op, "set"))
                    {
                        xi = new NaElement("options-set");
                        if (args.Length == 6)
                        {
                            xi.AddNewChild("name", args[4]);
                            xi.AddNewChild("value", args[5]);
                        }
                        else
                        {
                            Console.Error.WriteLine("Improper number of arguments. Correct and re-run.");
                            Environment.Exit(1);
                        }
                        xo = s.InvokeElem(xi);
                        Console.Out.WriteLine("----------------------------");
                        if (xo.GetChildContent("message") != null)
                        {
                            Console.Out.Write("Message: ");
                            Console.Out.WriteLine(xo.GetChildContent("message"));
                        }
                        Console.Out.Write("Cluster Constraint: ");
                        Console.Out.WriteLine(xo.GetChildContent("cluster-constraint"));
                        Console.Out.WriteLine("----------------------------");
                    }
                    else
                    {
                        Console.Out.WriteLine("Invalid Operation");
                        Environment.Exit(1);
                    }
                    Environment.Exit(0);
                }
                //
                // List out all the options
                //
                else
                {
                    xi = new NaElement("options-list-info");

                    xo = s.InvokeElem(xi);
                    //
                    // Get the list of children from element(Here 
                    // 'xo') and iterate through each of the child 
                    // element to fetch their values
                    //
                    System.Collections.IList optionList = xo.GetChildByName("options").GetChildren();
                    System.Collections.IEnumerator optionIter = optionList.GetEnumerator();
                    while (optionIter.MoveNext())
                    {
                        NaElement optionInfo = (NaElement)optionIter.Current;
                        Console.Out.WriteLine("----------------------------");
                        Console.Out.Write("Option Name:");
                        Console.Out.WriteLine(optionInfo.GetChildContent("name"));
                        Console.Out.Write("Option Value:");
                        Console.Out.WriteLine(optionInfo.GetChildContent("value"));
                        Console.Out.Write("Cluster Constraint:");
                        Console.Out.WriteLine(optionInfo.GetChildContent("cluster-constraint"));
                    }
                }
            }
            catch (NaConnectionException e)
            {
                Console.Error.WriteLine("NaConnException: " + e.Message);
                Environment.Exit(1);
            }
            catch (NaException e)
            {
                Console.Error.WriteLine("NAEXCEPTION: " + e.Message);
                Environment.Exit(1);
            }
            catch (System.Exception e)
            {
                Console.Error.WriteLine(e.Message);
                Environment.Exit(1);
            }
        }
    }
}
