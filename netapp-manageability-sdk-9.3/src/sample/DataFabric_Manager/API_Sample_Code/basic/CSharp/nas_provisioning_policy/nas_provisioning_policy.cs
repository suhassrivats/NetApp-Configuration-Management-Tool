//===============================================================//
//                                                               //
// $ID$                                                          //
//                                                               //
// nas_provisioning_policy.cs                                    //
//                                                               //
// Copyright (c) 2009 NetApp, Inc. All rights reserved.          //
// Specifications subject to change without notice.              //
//                                                               //
// Sample code to demonstrate how to manage provisioning policy  //
// on a DFM server                                               //
// you can create, delete and list nas provisioning policies     //
//                                                               //
// This Sample code is supported from DataFabric Manager 3.8     //
// onwards.                                                      //
// However few of the functionalities of the sample code may     //
// work on older versions of DataFabric Manager.                 //
//===============================================================//

using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace NetApp.ManageabilitySDK.Samples.Basic.NasProvisioningPolicy
{
	class NasProvisioningPolicy
	{
		private static NaServer server;
		private static String[] Args;


		static void Usage(){
			Console.WriteLine("" +
"Usage:\n"+
"nas_prov_policy <dfmserver> <user> <password> list [ <pol-name> ]\n" +
"\n" +
"nas_prov_policy <dfmserver> <user> <password> delete <pol-name>\n" +
"\n" +
"nas_prov_policy <dfmserver> <user> <password> create <pol-name> [ -d ]\n" +
"[ -c ] [ -s ] [ -r ] [ -S | -t ] [ -g <gquota> ] [ -u <uquota> ]\n" +
"\n" +
"<operation>     -- create or delete or list\n" +
"\n" +
"<dfmserver> -- Name/IP Address of the DFM server\n" +
"<user>      -- DFM server User name\n" +
"<password>  -- DFM server UserPassword\n" +
"<pol-name>  -- provisioning policy name\n" +
"[ -d ]      -- To enable dedupe \n" +
"[ -c ]      -- To enable resiliency against controller failure\n" +
"[ -s ]      -- To enable resiliency against sub-system failure\n" +
"[ -r ]      -- To disable snapshot reserve\n" +
"[ -S ]      -- To enable space on demand\n" +
"[ -t ]      -- To enable thin provisioning\n" +
"<gquota>    -- Default group quota setting in kb.  Range: [1..2^44-1]\n" +
"<uquota>    -- Default user quota setting in kb. Range: [1..2^44-1]\n" +
"\n" +
"Note : All options except provisioning policy name are optional and are\n" +
"required only by create operation");
			Environment.Exit(1);
		}

		static void Main(String[] args)
		{

			Args = args;
			int arglen = Args.Length;
			// Checking for valid number of parameters
			if(arglen < 4)
				Usage();

			String dfmserver = Args[0];
			String dfmuser = Args[1];
			String dfmpw = Args[2];
			String dfmop = Args[3];

			// checking for valid number of parameters for the operations
			if((dfmop.Equals("list") && arglen < 4) 
				|| (dfmop.Equals("delete") &&  arglen != 5) 
				|| (dfmop.Equals("create") &&  arglen < 5))
					Usage();

			// checking if the operation selected is valid
			if((!dfmop.Equals("list")) && (!dfmop.Equals("create"))
					&& (!dfmop.Equals("delete")))
				Usage();

				try {
					//Initialize connection to server, and
					//request version 1.0 of the API set
					//
					// Creating a server object and setting attributes
					server = new NaServer(dfmserver, 1, 0);
					server.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
					server.ServerType = NaServer.SERVER_TYPE.DFM;
					server.SetAdminUser(dfmuser, dfmpw);

					// Calling the functions based on the operation selected
					if(dfmop.Equals("create"))
						Create();
					else if(dfmop.Equals("list"))
						List();
					else if(dfmop.Equals("delete"))
						Delete();
					else
						Usage();
				}
				catch (NaException e)
				{
					//Print the error message
					Console.Error.WriteLine(e.Message);
					Environment.Exit(1);
				}
				catch (Exception e) {
					Console.Error.WriteLine(e.Message);
					Environment.Exit(1);
				}
			}

			static String Result(String result)
			{
				// Checking for the string "passed" in the output
				String r = (result.Equals("passed"))
				? "Successful" : "UnSuccessful";
				return r;
			}

			static void Create()
			{

				String groupQuota = null;
				String userQuota = null;
				bool dedupeEnable = false;
				bool controllerFailure = false;
				bool subsystemFailure = false;
				bool snapshotReserve = false;
				bool spaceOnDemand = false;
				bool thinProvision = false;

				// Getting the policy name
				String policyName = Args[4];

				// parsing optional parameters
				int i=5;
				while( i < Args.Length) {
					if(Args[i].Equals("-g")) {
						groupQuota = Args[++i]; ++i ;
					} else if(Args[i].Equals("-u")) {
						userQuota = Args[++i]; ++i ;
					} else if(Args[i].Equals("-d")) {
						dedupeEnable = true; ++i ;
					} else if(Args[i].Equals("-c")) {
						controllerFailure = true; ++i ;
					} else if(Args[i].Equals("-s")) {
						subsystemFailure = true  ; ++i ;
					} else if(Args[i].Equals("-r")) {
						snapshotReserve = true ; ++i ;
					} else if(Args[i].Equals("-S")) {
						spaceOnDemand = true ; ++i ;
					} else if(Args[i].Equals("-t")) {
						thinProvision = true ; ++i ;
					} else { Usage();
					}
				}

				try {
					// creating the input for api execution
					// creating a create element and adding child elements
					NaElement input = 
					new NaElement("provisioning-policy-create");
					NaElement policy = 
					new NaElement("provisioning-policy-info");
					policy.AddNewChild("provisioning-policy-name",policyName);
					policy.AddNewChild("provisioning-policy-type","nas");
					if(dedupeEnable) 
						policy.AddNewChild("dedupe-enabled","$dedupe_enable");

					// creating the storage reliability child and adding 
					// parameters if input
					if(controllerFailure || subsystemFailure) {
						NaElement storageRelilability = 
						new NaElement("storage-reliability");
						if(controllerFailure)
							storageRelilability.
							AddNewChild("controller-failure","true");
						if(subsystemFailure)
							storageRelilability.
							AddNewChild("sub-system-failure","true");

						// appending storage-reliability child to parent and 
						// then to policy info
						policy.AddChildElement(storageRelilability);
					}

					// creating the nas container settings child and 
					// adding parameters if input
					if (groupQuota != null || userQuota != null 
					|| snapshotReserve || spaceOnDemand || thinProvision) {
						NaElement nasContainerSettings = 
						new NaElement("nas-container-settings");
						if(groupQuota != null)
							nasContainerSettings.
							AddNewChild("default-group-quota",groupQuota);
						if(userQuota != null)
							nasContainerSettings.
							AddNewChild ("default-user-quota",userQuota);
						if(snapshotReserve)
							nasContainerSettings.
							AddNewChild("snapshot-reserve","false");
						if(spaceOnDemand)
							nasContainerSettings.
							AddNewChild ("space-on-demand","true");
						if(thinProvision)
							nasContainerSettings.
							AddNewChild("thin-provision","true");

						// adding nas-containter-settings child to policy info
						policy.AddChildElement(nasContainerSettings);
					}

					// Adding policy to parent element
					input.AddChildElement(policy);


					// invoking the api && printing the xml ouput
					NaElement output = server.InvokeElem(input);

					Console.WriteLine("\nPolicy creation "
					+ Result(output.GetAttr("status")));
				}
				catch (NaException e)
				{
					//Print the error message
					Console.Error.WriteLine(e.Message);
					Environment.Exit(1);
				}
				catch (Exception e) {
					Console.Error.WriteLine(e.Message);
					Environment.Exit(1);
				}
			}

			static void List()
			{
				String policyName = null;

				try {
					// creating a start element
					NaElement input = 
					new NaElement("provisioning-policy-list-iter-start");
					input.AddNewChild("provisioning-policy-type", "nas");
					if(Args.Length > 4) {
						policyName = Args[4];
						input.AddNewChild("provisioning-policy-name-or-id",
						policyName);
					}

					// invoke the api && capturing the records && tag values
					NaElement output = server.InvokeElem(input);



					// Extracting the record && tag values && printing them
					String records = output.GetChildContent("records");

					if (records.Equals("0"))
						Console.WriteLine("\nNo policies to display");

					String tag = output.GetChildContent("tag");


					// Extracting records one at a time
					input = new NaElement("provisioning-policy-list-iter-next");
					input.AddNewChild("maximum",records);
					input.AddNewChild("tag",tag);
					NaElement record = server.InvokeElem(input);

					// Navigating to the provisioning-policys child element
					NaElement stat = 
					record.GetChildByName("provisioning-policies");

					System.Collections.IList infoList = null;

					if(stat != null)
						infoList = stat.GetChildren();
					if(infoList == null) return;


					System.Collections.IEnumerator infoIter = 
					infoList.GetEnumerator();

					// Iterating through each record
					while (infoIter.MoveNext())
					{
						String value;
						NaElement info = (NaElement)infoIter.Current;

						NaElement nasContainerSettings = 
						info.GetChildByName("nas-container-settings");
						// Checking if the container is nas before printing 
						if (nasContainerSettings != null)
						{
							Console.WriteLine(
							"------------------------------------------------");
							 // extracting the policy name and printing it
							value = 
							info.GetChildContent("provisioning-policy-name");
							Console.WriteLine("Policy Name : " + value);

							value = 
							info.GetChildContent("provisioning-policy-id");
							Console.WriteLine("Policy Id : " + value);

							value = info.
							GetChildContent("provisioning-policy-description");
							Console.WriteLine("Policy Description : " + value);
							Console.WriteLine(
							"------------------------------------------------");

							// printing detials if only one policy is selected for listing
							if(policyName != null) {

								value = 
								info.GetChildContent("provisioning-policy-type");
								Console.WriteLine("Policy Type        : "
								+ value);


								value = info.GetChildContent("dedupe-enabled");
								Console.WriteLine("Dedupe Enabled     : "
								+ value);


							   NaElement storageRelilability = 
							   info.GetChildByName("storage-reliability");

								value = storageRelilability.
								GetChildContent("disk-failure");
								Console.WriteLine("Disk Failure       : "
								+ value);


								value = storageRelilability.
								GetChildContent("sub-system-failure");
								Console.WriteLine("Subsystem Failure  : "
								+ value);


								value = storageRelilability.
								GetChildContent("controller-failure");
								Console.WriteLine("Controller Failure : "
								+ value);


								value = nasContainerSettings.
								GetChildContent("default-user-quota");
								Console.Write("Default User Quota : ");
								if(value != null)
									Console.Write(value+ " kb");

								value = nasContainerSettings.
								GetChildContent("default-group-quota");
								Console.Write("\nDefault Group Quota: ");
								if(value != null)
									Console.Write(value+ " kb");

								value = nasContainerSettings.
								GetChildContent("snapshot-reserve");
								Console.Write("\nSnapshot Reserve   : ");
								if(value != null)
									Console.Write(value);

								value = nasContainerSettings.
								GetChildContent("space-on-demand");
								Console.Write("\nSpace On Demand    : ");
								if(value != null)
									Console.Write(value);

								value = nasContainerSettings.
								GetChildContent("thin-provision");
								Console.Write("\nThin Provision     : ");
								if(value != null)
									Console.WriteLine(value);

							}
						}
						if (nasContainerSettings == null && policyName != null)
						{
							Console.WriteLine("\nsan type of provisioning "
							+ "policy is not supported for listing");
						}
					}

					// invoking the iter-end zapi
					input = new NaElement("provisioning-policy-list-iter-end");
					input.AddNewChild("tag",tag);
					server.InvokeElem(input);

				}
				catch (NaException e)
				{
				//Print the error message
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
				}
				catch (Exception e)
				{
					Console.Error.WriteLine(e.Message);
					Environment.Exit(1);
				}
			}
		static void Delete()
		{
			String policyName = Args[4];

			try {
			// invoking the api && printing the xml ouput
				NaElement input = new NaElement("provisioning-policy-destroy");
				input.AddNewChild("provisioning-policy-name-or-id",policyName);
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nPolicy deletion "
				+ Result(output.GetAttr("status")));

			}
			catch (NaException e) {
				//Print the error message
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			} catch (Exception e) {
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
		}
	}
}