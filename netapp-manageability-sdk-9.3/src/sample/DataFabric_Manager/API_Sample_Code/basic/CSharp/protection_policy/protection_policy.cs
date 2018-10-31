//===============================================================//
//                                                               //
// $ID$                                                          //
//                                                               //
// protection_policy.cs                                          //
//                                                               //
// Copyright (c) 2009 NetApp, Inc. All rights reserved.          //
// Specifications subject to change without notice.              //
//                                                               //
// Sample code to demonstrate how to manage protection policy    //
// on a DFM server                                               //
// Create, delete and list protection policies                   //
//                                                               //
// This Sample code is supported from DataFabric Manager 3.6R2   //
// onwards.                                                      //
// However few of the functionalities of the sample code may     //
// work on older versions of DataFabric Manager.                 //
//===============================================================//

using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace NetApp.ManageabilitySDK.Samples.Basic.ProtectionPolicy
{
	class ProtectionPolicy
	{
		private static NaServer server;
		private static String[] Args;


		static void Usage()
		{
			Console.WriteLine("" +
	"Usage:\n" +
	"protection_policy <dfmserver> <user> <password> list [ <policy> ]\n" +
	"\n" +
	"protection_policy <dfmserver> <user> <password> delete <policy>\n" +
	"\n" +
	"protection_policy <dfmserver> <user> <password> create <policy> "
	+ "<pol-new>\n" +
	"\n" +
	"<operation> -- create or delete or list\n" +
	"\n" +
	"<dfmserver> -- Name/IP Address of the DFM server\n" +
	"<user>      -- DFM server User name\n" +
	"<password>  -- DFM server User Password\n" +
	"<policy>    -- Exisiting policy name\n" +
	"<pol-new>   -- Protection policy to be created" +
	"\n" +
	"\n" +
	"Note: In the create operation the a copy of protection policy"
	+ " will be made and\n" +
	"name changed from <pol-temp> to <pol-new>\n");
			Environment.Exit(1);
		}

		static void Main(String[] args)
		{

			Args = args;
			int arglen = Args.Length;
			// Checking for valid number of parameters
			if (arglen < 4)
				Usage();

			String dfmserver = Args[0];
			String dfmuser = Args[1];
			String dfmpw = Args[2];
			String dfmop = Args[3];

			// checking for valid number of parameters for the  operations
			if ((dfmop.Equals("list") && arglen < 4) 
				|| (dfmop.Equals("delete") && arglen != 5)
				|| (dfmop.Equals("create") && arglen != 6))
					Usage();

			// checking if the operation selected is valid
			if ((!dfmop.Equals("list")) && (!dfmop.Equals("create"))
			&& (!dfmop.Equals("delete")))
				Usage();

			try
			{
				//Initialize connection to server, and
				//request version 1.0 of the API set
				//
				// Creating a server object and setting appropriate attributes
				server = new NaServer(dfmserver, 1, 0);
				server.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
				server.ServerType = NaServer.SERVER_TYPE.DFM;
				server.SetAdminUser(dfmuser, dfmpw);

				// Calling the functions based on the operation selected
				if (dfmop.Equals("create"))
					Create();
				else if (dfmop.Equals("list"))
					List();
				else if (dfmop.Equals("delete"))
					Delete();
				else
					Usage();
			}
			catch (NaException e) {
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

		static String Result(String result)
		{
			// Checking for the string "passed" in the output
			String r = (result.Equals("passed"))
			? "Successful" : "UnSuccessful";
			return r;
		}

		static void Create()
		{
			String policyTemplate = Args[4];
			String policyName = Args[5];

			try
			{
				// Copy section
				// Making a copy of policy in the format copy of <policy name>
				NaElement input = new NaElement("dp-policy-copy");
				input.AddNewChild("template-dp-policy-name-or-id", 
				policyTemplate);
				input.AddNewChild("dp-policy-name", "copy of "
				+ policyTemplate);
				server.InvokeElem(input);

				// Modify section
				// creating edit section
				input = new NaElement("dp-policy-edit-begin");
				input.AddNewChild("dp-policy-name-or-id", "copy of "
				+ policyTemplate);
				NaElement output = server.InvokeElem(input);

				String lockId = output.GetChildContent("edit-lock-id");

				// modifying the policy name
				// creating a dp-policy-modify element and adding child elements
				input = new NaElement("dp-policy-modify");
				input.AddNewChild("edit-lock-id", lockId);

				// getting the policy content deailts of the original policy
				NaElement origPolicyContent = getPolicyContent();

				// Creating a new dp-policy-content elem and adding name, desc
				NaElement policyContent = new NaElement("dp-policy-content");
				policyContent.AddNewChild("name", policyName);
				policyContent.AddNewChild("description","Added by sample code");

				// appending the original connections and nodes children
				policyContent.AddChildElement(origPolicyContent.
				GetChildByName("dp-policy-connections"));
				policyContent.AddChildElement(origPolicyContent.
				GetChildByName("dp-policy-nodes"));

				// Attaching the new policy content child to modify element
				input.AddChildElement(policyContent);

				try
				{
					// invoking the api && printing the xml ouput
					output = server.InvokeElem(input);

					input = new NaElement("dp-policy-edit-commit");
					input.AddNewChild("edit-lock-id", lockId);
					output = server.InvokeElem(input);
				}
				catch (Exception e)
				{
					Console.Error.WriteLine(e.Message);
					input = new NaElement("dp-policy-edit-rollback");
					input.AddNewChild("edit-lock-id", lockId);
					server.InvokeElem(input);
					Environment.Exit(1);
				}

				Console.WriteLine("\nPolicy creation "
				+ Result(output.GetAttr("status")));
			}
			catch (NaException e) {
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

		static NaElement getPolicyContent()
		{
			NaElement policyContent = null;
			try
			{
				// creating a dp policy start element
				NaElement input = new NaElement("dp-policy-list-iter-start");
				input.AddNewChild("dp-policy-name-or-id", Args[4]);

				// invoke the api && capturing the records && tag values
				NaElement output = server.InvokeElem(input);

				// Extracting the record && tag values && printing them
				String tag = output.GetChildContent("tag");

				// Extracting records one at a time
				input = new NaElement("dp-policy-list-iter-next");
				input.AddNewChild("maximum", "1");
				input.AddNewChild("tag", tag);
				NaElement record = server.InvokeElem(input);

				// Navigating to the dp-policy-infos child element
				NaElement policyInfos = 
				record.GetChildByName("dp-policy-infos");

				// Navigating to the dp-policy-info child element
				NaElement policyInfo = 
				policyInfos.GetChildByName("dp-policy-info");

				// Navigating to the dp-policy-content child element
				policyContent = policyInfo.GetChildByName("dp-policy-content");

				// invoking the iter-end zapi
				input = new NaElement("dp-policy-list-iter-end");
				input.AddNewChild("tag", tag);

				server.InvokeElem(input);

			}
			catch (NaException e) {
				//Print the error message
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
			catch (Exception e)
			{
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
			// Returning the original policy content
			return (policyContent);
		}

		static void List()
		{
			String policyName = null;

			try
			{
				// creating a dp policy start element
				NaElement input = new NaElement("dp-policy-list-iter-start");
				if (Args.Length > 4)
				{
					policyName = Args[4];
					input.AddNewChild("dp-policy-name-or-id", policyName);
				}

				// invoke the api && capturing the records && tag values
				NaElement output = server.InvokeElem(input);


				// Extracting the record && tag values && printing them
				String records = output.GetChildContent("records");

				if (records.Equals("0"))
					Console.WriteLine("\nNo policies to display");

				String tag = output.GetChildContent("tag");



				// Extracting records one at a time
				input = new NaElement("dp-policy-list-iter-next");
				input.AddNewChild("maximum", records);
				input.AddNewChild("tag", tag);
				NaElement record = server.InvokeElem(input);

				// Navigating to the dp-policy-infos child element
				NaElement stat = record.GetChildByName("dp-policy-infos");

				// Navigating to the dp-policy-info child element
				System.Collections.IList infoList = null;

				if (stat != null)
					infoList = stat.GetChildren();
				if (infoList == null) return;


				System.Collections.IEnumerator infoIter = 
				infoList.GetEnumerator();

				// Iterating through each record
				while (infoIter.MoveNext())
				{
					String value;
					NaElement info = (NaElement)infoIter.Current;


					// extracting the policy name and printing it
					// Navigating to the dp-policy-content child element
					NaElement policyContent = 
					info.GetChildByName("dp-policy-content");

					// Removing non modifiable policies
					if (policyContent.GetChildContent("name").IndexOf("NM") < 0)
					{
						Console.WriteLine(
						"----------------------------------------------------");
						value = policyContent.GetChildContent("name");
						Console.WriteLine("Policy Name : " + value);


						value = info.GetChildContent("id");
						Console.WriteLine("Id : " + value);

						value = policyContent.GetChildContent("description");
						Console.WriteLine("Description : " + value);

						Console.WriteLine(
						"----------------------------------------------------");


						// printing detials if only one policy is selected for listing
						if (policyName != null)
						{

							// printing connection info
							NaElement dpc = policyContent.
							GetChildByName("dp-policy-connections");
							NaElement dpci = 
							dpc.GetChildByName("dp-policy-connection-info");

							value = dpci.GetChildContent("backup-schedule-name");
							Console.Write("\nBackup Schedule Name : ");
							if (value != null)
								Console.Write(value);

							value = dpci.GetChildContent("backup-schedule-id");
							Console.Write("\nBackup Schedule Id   : ");
							if (value != null)
								Console.WriteLine(value);

							value = dpci.GetChildContent("id");
							Console.WriteLine("Connection Id        : "+ value);

							value = dpci.GetChildContent("type");
							Console.WriteLine("Connection Type      : "+ value);

							value = 
							dpci.GetChildContent("lag-warning-threshold");
							Console.WriteLine("Lag Warning Threshold: "+ value);

							value = dpci.GetChildContent("lag-error-threshold");
							Console.WriteLine("Lag Error Threshold  : "+ value);

							value = dpci.GetChildContent("from-node-name");
							Console.WriteLine("From Node Name       : "+ value);

							value = dpci.GetChildContent("from-node-id");
							Console.WriteLine("From Node Id         : "+ value);

							value = dpci.GetChildContent("to-node-name");
							Console.WriteLine("To Node Name         : "+ value);

							value = dpci.GetChildContent("to-node-id");
							Console.WriteLine("To Node Id           : "+ value);
						}
					}
				}

				// invoking the iter-end zapi
				input = new NaElement("dp-policy-list-iter-end");
				input.AddNewChild("tag", tag);
				server.InvokeElem(input);

			}
			catch (NaException e) {
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

			try
			{
				NaElement input = new NaElement("dp-policy-edit-begin");
				input.AddNewChild("dp-policy-name-or-id", policyName);
				NaElement output = server.InvokeElem(input);

				String lockId = output.GetChildContent("edit-lock-id");

				// Deleting the policy name
				// creating a dp-policy-destroy element and adding edit-lock
				input = new NaElement("dp-policy-destroy");
				input.AddNewChild("edit-lock-id", lockId);
				output = server.InvokeElem(input);

				try
				{
					input = new NaElement("dp-policy-edit-commit");
					input.AddNewChild("edit-lock-id", lockId);
					output = server.InvokeElem(input);
				}
				catch (Exception e)
				{
					Console.Error.WriteLine(e.Message);
					input = new NaElement("dp-policy-edit-rollback");
					input.AddNewChild("edit-lock-id", lockId);
					server.InvokeElem(input);
					Environment.Exit(1);
				}

				Console.WriteLine("\nPolicy deletion "
				+ Result(output.GetAttr("status")));

			}
			catch (NaException e) {
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
	}
}
