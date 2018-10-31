//======================================================================//
//                                                                      //
// $ID$                                                                 //
//                                                                      //
// nfs.cs                                                               //
//                                                                      //
// Brief information of the contents                                    //
//                                                                      //
// Copyright 2008 NetApp. All rights reserved. Specifications subject   //
// to change without notice.                                            //
//                                                                      //
// This SDK sample code is provided AS IS, with no support or           //
// warranties of any kind, including but not limited to                 //
// warranties of merchantability or fitness of any kind,                //
// expressed or implied.  This code is subject to the license           //
// agreement that accompanies the SDK.                                  //
//                                                                      //
// Sample for usage of following nfs group API:                         //
//                      nfs-enable                                      //
//                      nfs-disable                                     //
//                      nfs-status                                      //
//                      nfs-exportfs-list-rules                         //
//                                                                      //
// Usage:                                                               //
// nfs <filer> <user> <password> <operation>                            //
//                                                                      //
// <filer>      -- Name/IP address of the filer                         //
// <user>       -- User name                                            //
// <password>   -- Password                                             //
// <operation>  --                                                      //
//                 enable                                               //
//                 disable                                              //
//                 status                                               //
//                 list                                                 //
//======================================================================//

using System; 
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace nfs
{
    class Nfs
    {
        public static void PrintUsage()
        {
            Console.Out.WriteLine("\nUsage : nfs <filer> <user> <passwd> <operation> \n");
            Console.Out.Write("<filer>	-- ");
            Console.Out.WriteLine("Name/IP address of the filer");
            Console.Out.WriteLine("<user>	-- User Name");
            Console.Out.WriteLine("<passwd>	-- Password");
            Console.Out.WriteLine("<operation>	--");
            Console.Out.WriteLine("\tenable - To enable NFS Service");
            Console.Out.WriteLine("\tdisable - To disable NFS Service");
            Console.Out.WriteLine("\tstatus - To print the status of NFS Service");
            Console.Out.WriteLine("\tlist - To list the NFS export rules");
            Environment.Exit(1);
        }

        static void Main(string[] args)
        {
            NaElement xi;
		    NaElement xo;
		    NaServer s;
		    String operation;
		        		
		    if (args.Length < 4)
		    {
			    PrintUsage();
		    }
		    try
		    {
                Console.WriteLine("|-----------------------------------------|");
                Console.WriteLine("| Program to demo use of NFS related APIs |");
                Console.WriteLine("|-----------------------------------------|\n");
                /*
			    * Initialize connection to server, and
			    * request version 1.3 of the API set
			    */
			    s = new NaServer(args[0], 1, 3);
    			
			    /* Set connection style(HTTP)*/
			    s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
			    s.SetAdminUser(args[1], args[2]);
			    operation = args[3];
    			
			    /* To invoke nfs-enable API
			    *  Usage: nfs <filer> <user> <password> enable
			    *
			    */
			    if (operation.Equals("enable"))
			    {
    				
				    xi = new NaElement("nfs-enable");
				    xo = s.InvokeElem(xi);
				    Console.Out.WriteLine("enabled successfully!");
			    }
			    /* To invoke nfs-enable API
			    *  Usage: nfs <filer> <user> <password> disable
			    *
			    */
			    else if (operation.Equals("disable"))
			    {
    				
				    xi = new NaElement("nfs-disable");
				    xo = s.InvokeElem(xi);
				    Console.Out.WriteLine("disabled successfully!");
			    }
			    /* To invoke nfs-status API
			    *  Usage: nfs <filer> <user> <password> status
			    *
			    */
			    else if (operation.Equals("status"))
			    {
    				
				    xi = new NaElement("nfs-status");
				    xo = s.InvokeElem(xi);
				    String enabled = xo.GetChildContent("is-enabled");
				    if (String.Compare(enabled, "true") == 0)
				    {
					    Console.Out.WriteLine("NFS Server is enabled");
				    }
				    else
				    {
					    Console.Out.WriteLine("NFS Server is disabled");
				    }
			    }
			    /* To invoke nfs-exportfs-list-rules API
			    *  Usage: nfs <filer> <user> <password> list
			    *
			    */
			    else if (operation.Equals("list"))
			    {
    				
				    xi = new NaElement("nfs-exportfs-list-rules");
				    xo = s.InvokeElem(xi);
    				
				    System.Collections.IList retList = xo.GetChildByName("rules").GetChildren();
                    System.Console.WriteLine(xo.ToPrettyString(""));
                    Environment.Exit(0);
				    System.Collections.IEnumerator retIter = retList.GetEnumerator();
    				
				    while (retIter.MoveNext())
				    {
    					
					    NaElement retInfo = (NaElement) retIter.Current;
					    String pathName = retInfo.GetChildContent("pathname");
					    String rwList = "rw=";
					    String roList = "ro=";
					    String rootList = "root=";
    					
    					
					    if (retInfo.GetChildByName("read-only") != null)
					    {
						    NaElement ruleElem = retInfo.GetChildByName("read-only");
						    System.Collections.IList hosts = ruleElem.GetChildren();
						    System.Collections.IEnumerator hostIter = hosts.GetEnumerator();
						    while (hostIter.MoveNext())
						    {
    							
							    NaElement hostInfo = (NaElement) hostIter.Current;
							    if (hostInfo.GetChildContent("all-hosts") != null)
							    {
								    String allHost = hostInfo.GetChildContent("all-hosts");
								    if (String.Compare(allHost, "true") == 0)
								    {
									    roList = roList + "all-hosts";
									    break;
								    }
							    }
							    else if (hostInfo.GetChildContent("name") != null)
							    {
								    roList = roList + hostInfo.GetChildContent("name") + ":";
							    }
						    }
					    }
					    if (retInfo.GetChildByName("read-write") != null)
					    {
						    NaElement ruleElem = retInfo.GetChildByName("read-write");
						    System.Collections.IList hosts = ruleElem.GetChildren();
						    System.Collections.IEnumerator hostIter = hosts.GetEnumerator();
						    while (hostIter.MoveNext())
						    {
    							
							    NaElement hostInfo = (NaElement) hostIter.Current;
							    if (hostInfo.GetChildContent("all-hosts") != null)
							    {
								    String allHost = hostInfo.GetChildContent("all-hosts");
								    if (String.Compare(allHost, "true") == 0)
								    {
									    rwList = rwList + "all-hosts";
									    break;
								    }
							    }
							    else if (hostInfo.GetChildContent("name") != null)
							    {
								    rwList = rwList + hostInfo.GetChildContent("name") + ":";
							    }
						    }
					    }
					    if (retInfo.GetChildByName("root") != null)
					    {
						    NaElement ruleElem = retInfo.GetChildByName("root");
						    System.Collections.IList hosts = ruleElem.GetChildren();
						    System.Collections.IEnumerator hostIter = hosts.GetEnumerator();
						    while (hostIter.MoveNext())
						    {
    							
							    NaElement hostInfo = (NaElement) hostIter.Current;
							    if (hostInfo.GetChildContent("all-hosts") != null)
							    {
								    String allHost = hostInfo.GetChildContent("all-hosts");
								    if (String.Compare(allHost, "true") == 0)
								    {
									    rootList = rootList + "all-hosts";
									    break;
								    }
							    }
							    else if (hostInfo.GetChildContent("name") != null)
							    {
								    rootList = rootList + hostInfo.GetChildContent("name") + ":";
							    }
						    }
					    }

					    if (String.Compare(roList, "ro=") != 0)
					    {
						    pathName = pathName + ", \t" + roList;
					    }
					    if (String.Compare(rwList, "rw=") != 0)
					    {
                            pathName = pathName + ", \t" + rwList;
					    }
					    if (String.Compare(rootList, "root=") != 0)
					    {
                            pathName = pathName + ", \t" + rootList;
					    }
    					
					    Console.Out.WriteLine(pathName);
				    }
			    }
			    else
			    {
				    PrintUsage();
			    }
		    }
		    catch (NaAuthException e)
		    {
			    Console.Error.WriteLine("Bad login/password" + e.Message);
		    }
		    catch (NaApiFailedException e)
		    {
			    Console.Error.WriteLine("API failed (" + e.Message + ")");
		    }
	        catch (NaProtocolException e)
		    {
			    Console.Error.WriteLine(e.StackTrace);
		    }
		    catch (System.Exception e)
		    {
			   Console.Error.WriteLine(e.Message);
		    }
        }
    }
}
