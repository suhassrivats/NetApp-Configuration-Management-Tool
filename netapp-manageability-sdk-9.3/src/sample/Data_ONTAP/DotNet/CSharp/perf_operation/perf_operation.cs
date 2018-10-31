//=======================================================================//
//                                                                       //
// $ID$                                                                  //
//                                                                       //
// perf_operation.cs                                                     //
//                                                                       //
// Brief information of the contents                                     //
//                                                                       //
// Copyright 2008 NetApp. All rights reserved. Specifications subject to //
// change without notice.                                                //
//                                                                       //
// This SDK sample code is provided AS IS, with no support or            //
// warranties of any kind, including but not limited to                  //
// warranties of merchantability or fitness of any kind,                 //
// expressed or implied.  This code is subject to the license            //
// agreement that accompanies the SDK.                                   //
//                                                                       //
//  Sample for usage of following perf group API:                        //
//          perf-object-list-info                                        //
//          perf-object-counter-list-info                                //
//          perf-object-instance-list-info                               //
//          perf-object-get-instances-iter-*                             //
//                                                                       //
// Usage:                                                                //
// perf_operation <filer> <user> <password> <operation>                  //
//                                                                       //
// <filer>      -- Name/IP address of the filer                          //
// <user>       -- User name                                             //
// <password>   -- Password                                              //
// <operation>  --                                                       //
//      object-list - Get the list of perforance objects                 //
//                in the system                                          //
//      instance-list - Get the list of instances for a given            //
//                  performance object                                   //
//      counter-list - Get the list of counters available for a          //
//                 given performance object                              //
//      get-counter-values - get the values of the counters for          //
//                   all instance of a performance object                //
//=======================================================================//
using System;
using NetApp.Manage;

namespace perf_operation
{
    class PerfOperation
    {
        public static void  PrintUsage()
	    {
		    Console.Out.WriteLine("\nUsage : perf_operation <filer> <user> <passwd> <operation> \n");
		    Console.Out.Write("<filer>	-- ");
		    Console.Out.WriteLine("Name/IP address of the filer");
		    Console.Out.WriteLine("<user>	-- User Name");
		    Console.Out.WriteLine("<passwd>	-- Password");
		    Console.Out.WriteLine("<operation>	--");
		    Console.Out.WriteLine("\tobject-list - Get the list of perforance objects in the system");
		    Console.Out.WriteLine("\tinstance-list - Get the list of instances for a given performance object");
		    Console.Out.WriteLine("\tcounter-list - Get the list of counters available for a given performance object");
		    Console.Out.WriteLine("\tget-counter-values - get the values of the counters for all the instances of a performance object");
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
                Console.WriteLine("| Program to Demo use of Performance APIs |");
                Console.WriteLine("|-----------------------------------------|");
                /*
			    * Initialize connection to server, and
			    * request version 1.3 of the API set
			    */
		    	s = new NaServer(args[0], 1, 3);
			
			    /* Set connection style(HTTP)*/
			    s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
			    s.SetAdminUser(args[1], args[2]);
			    operation = args[3];
			
			    /* To invoke perf-object-list-info API
			    *  Usage: perf_operation <filer> <user> <password> object-list
			    *  
			    */
			    if (operation.Equals("object-list"))
			    {
				    xi = new NaElement("perf-object-list-info");
			    	xo = s.InvokeElem(xi);
				    System.Collections.IList objList = xo.GetChildByName("objects").GetChildren();
				    System.Collections.IEnumerator objIter = objList.GetEnumerator();
				
				    while (objIter.MoveNext())
				    {
					    NaElement objInfo = (NaElement) objIter.Current;
					    Console.Out.Write("Object Name = " + objInfo.GetChildContent("name") + "\t");
					    Console.Out.Write("privilege level = " + objInfo.GetChildContent("privilege-level") + "\n");
				    }
                    Console.Out.WriteLine("\n");
			    }
			    /* To invoke perf-object-instance-list-info API
			    *  Usage: perf_operation <filer> <user> <password> instance-list <objectname>
			    *  
			    */
			    else if (operation.Equals("instance-list"))
			    {
					if (args.Length < 5)
				    {
					    Console.Out.WriteLine("Usage:");
					    Console.Out.WriteLine("perf_operation <filer> <user> <password> <instance-list> <objectname>");
					    Environment.Exit(1);
				    }
				
				    xi = new NaElement("perf-object-instance-list-info");
				    xi.AddNewChild("objectname", args[4]);
				    xo = s.InvokeElem(xi);
				
				    System.Collections.IList instList = xo.GetChildByName("instances").GetChildren();
				    System.Collections.IEnumerator instIter = instList.GetEnumerator();
				
				    while (instIter.MoveNext())
				    {
					    NaElement instInfo = (NaElement) instIter.Current;
					    Console.Out.WriteLine("Instance Name = " + instInfo.GetChildContent("name"));
				    }
			    }
			    /* To invoke perf-object-counter-list-info API
			    *  Usage: perf_operation <filer> <user> <password> counter-list <objectname> 
			    *  
			    */
			    else if (operation.Equals("counter-list"))
			    {
					if (args.Length < 5)
				    {
					    Console.Out.WriteLine("Usage:");
					    Console.Out.WriteLine("perf_operation <filer> <user> <password> <counter-list> <objectname>");
					    Environment.Exit(1);
				    }
				
				    xi = new NaElement("perf-object-counter-list-info");
				    xi.AddNewChild("objectname", args[4]);
				    xo = s.InvokeElem(xi);
    				
				    System.Collections.IList counterList = xo.GetChildByName("counters").GetChildren();
				    System.Collections.IEnumerator counterIter = counterList.GetEnumerator();
    				
				    while (counterIter.MoveNext())
				    {
    					NaElement counterInfo = (NaElement) counterIter.Current;
					    Console.Out.Write("Counter Name = " + counterInfo.GetChildContent("name") + "\t\t\t\t");

                        if (counterInfo.GetChildContent("base-counter") != null)
					    {
                            Console.Out.Write("Base Counter = " + counterInfo.GetChildContent("base-counter") + "\t");
					    }
					    else
					    {
						    Console.Out.Write("Base Counter = none\t\t\t");
					    }

                        Console.Out.Write("Privilege Level = " + counterInfo.GetChildContent("privilege-level") + "\t\t");

                        if (counterInfo.GetChildContent("unit") != null)
					    {
                            Console.Out.Write("Unit = " + counterInfo.GetChildContent("unit") + "\t");
					    }
					    else
					    {
						    Console.Out.Write("Unit = none\t");
					    }
    					
					    Console.Out.Write("\n");
				    }
			    }
                /* To invoke perf-object-get-instances-iter-* API
                *  Usage: perf_operation <filer> <user> <password> 
                *                           <get-counter-values> <objectname> <counter1> <counter2> <counter3>......
                */
                else if (operation.Equals("get-counter-values"))
			    {
    				
				    int totalRecords = 0;
				    int maxRecords = 10;
				    int numRecords = 0;
				    String iterTag = null;
    				
				    if (args.Length < 5)
				    {
					    Console.Out.WriteLine("Usage:");
					    Console.Out.WriteLine("perf_operation <filer> <user> <password> " +
                                    "<get-counter-values> <objectname> [<counter1> <counter2> ...]");
					    Environment.Exit(1);
				    }
    				
				    xi = new NaElement("perf-object-get-instances-iter-start");
    				
				    xi.AddNewChild("objectname", args[4]);
    				
				    NaElement counters = new NaElement("counters");
    				
				    /*Now store rest of the counter names as child 
				    * element of counters
				    *	
				    * Here it has been hard coded as 5 because 
				    * first counter is specified at 6th position from 
				    * cmd prompt
				    */
				    int numCounter = 5;
    				
				    while (numCounter < (args.Length))
				    {
					    counters.AddNewChild("counter", args[numCounter]);
					    numCounter++;
				    }
    				
				    /* If no counters are specified then all the counters are fetched */
				    if (numCounter > 5)
				    {
					    xi.AddChildElement(counters);
				    }
    				
				    xo = s.InvokeElem(xi);
				    totalRecords = xo.GetChildIntValue("records", - 1);
				    iterTag = xo.GetChildContent("tag");
    				
				    do 
				    {
    					xi = new NaElement("perf-object-get-instances-iter-next");
					    xi.AddNewChild("tag", iterTag);
					    xi.AddNewChild("maximum", System.Convert.ToString(maxRecords));
					    xo = s.InvokeElem(xi);
					    numRecords = xo.GetChildIntValue("records", 0);
    					
					    if (numRecords != 0)
					    {
						    System.Collections.IList instList = xo.GetChildByName("instances").GetChildren();
						    System.Collections.IEnumerator instIter = instList.GetEnumerator();
    						
						    while (instIter.MoveNext())
						    {
    							
							    NaElement instData = (NaElement) instIter.Current;
							    Console.Out.WriteLine("Instance = " + instData.GetChildContent("name"));
							    System.Collections.IList counterList = instData.GetChildByName("counters").GetChildren();
							    System.Collections.IEnumerator counterIter = counterList.GetEnumerator();
							    while (counterIter.MoveNext())
							    {
    							    NaElement counterData = (NaElement) counterIter.Current;
								    Console.Out.Write("counter name = " + counterData.GetChildContent("name"));
								    Console.Out.Write("\t counter value = " + counterData.GetChildContent("value") + "\n");
								}
                                Console.Out.WriteLine("\n");
						    }
					    }
				    }
				    while (numRecords != 0);
    				
				    xi = new NaElement("perf-object-get-instances-iter-end");
				    xi.AddNewChild("tag", iterTag);
				    xo = s.InvokeElem(xi);
			    }
			    else
			    {
				    PrintUsage();
			    }
			    
		    }
		    catch (NaAuthException e)
		    {
			    Console.Error.WriteLine(e.Message + "Bad login/password");
		    }
            catch (NaApiFailedException e)
		    {
			    Console.Error.WriteLine("API failed (" + e.Message + ")");
		    }
		    catch (NaProtocolException e)
		    {
                Console.Error.WriteLine(e.Message);
		    }
		    catch (System.Exception e)
		    {
                Console.Error.WriteLine(e.Message);
		    }
	    }
    }
}
