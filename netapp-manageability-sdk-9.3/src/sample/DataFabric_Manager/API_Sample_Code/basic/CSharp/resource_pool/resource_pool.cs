//===============================================================//
//                                                               //
// $ID$                                                          //
//                                                               //
// resource_pool.cs                                              //
//                                                               //
// Copyright (C) 2009 NetApp, Inc. All rights reserved.          //
// Specifications subject to change without notice.              //
//                                                               //
// Sample code to demonstrate how to manage resource pool        //
// on a DFM server                                               //
// you can create,list and delete resource pools                 //
// add,list and remove members                                   //
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

namespace NetApp.ManageabilitySDK.Samples.Basic.ResourcePool
{
	class ResourcePool
	{
		private static NaServer server;
		private static String[] Args;


		static void Usage(){
			Console.WriteLine("" +
"Usage:\n" +
"resource_pool <dfmserver> <user> <password> list [ <rpool> ]\n" +
"\n" +
"resource_pool <dfmserver> <user> <password> delete <rpool>\n" +
"\n" +
"resource_pool <dfmserver> <user> <password> create <rpool>  [ -t <rtag> ]\n" +
"[-f <rp-full-thresh>] [-n <rp-nearly-full-thresh>]\n" +
"\n" +
"resource_pool <dfmserver> <user> <password> member-add <a-mem-rpool>\n" +
"<member> [ -m mem-rtag ]\n" +
"\n" +
"resource_pool <dfmserver> <user> <password> member-list <mem-rpool>\n" +
"[ <member> ]\n" +
"\n" +
"resource_pool <dfmserver> <user> <password> member-remove <mem-rpool>\n" +
"<member>\n" +
"\n" +
"\n" +
"<operation>             -- create or delete or list or member-add or\n" +
"                           member-list or member-remove\n" +
"\n" +
"<dfmserver>             -- Name/IP Address of the DFM server\n" +
"<user>                  -- DFM server User name\n" +
"<password>              -- DFM server User Password\n" +
"<rpool>                 -- Resource pool name\n" +
"<rtag>                  -- resource tag to be attached to a resourcepool\n" +
"<rp-full-thresh>        -- fullness threshold percentage to generate a\n" +
"                           \"resource pool full\" event.Range: [0..1000]\n" +
"<rp-nearly-full-thresh> -- fullness threshold percentage to generate a\n" +
"                           \"resource pool nearly full\" event.Range: "
+ "[0..1000]\n" +
"<a-mem-rpool>           -- resourcepool to which the member will be added\n" +
"<mem-rpool>             -- resourcepool containing the member\n" +
"<member>                -- name or Id of the member (host or aggregate)\n" +
"<mem-rtag>              -- resource tag to be attached to member\n");

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

			// checking for valid number of parameters for the respective operations
			if ((dfmop.Equals("list") && arglen < 4) 
				|| (dfmop.Equals("delete") && arglen != 5) 
				|| (dfmop.Equals("create") && arglen < 5) 
				|| (dfmop.Equals("member-list") && arglen < 5)
				|| (dfmop.Equals("member-remove") && arglen != 6) 
				|| (dfmop.Equals("member-add") && arglen < 6))
					Usage();

			// checking if the operation selected is valid
			if ((!dfmop.Equals("list")) && (!dfmop.Equals("create"))
			&& (!dfmop.Equals("delete")) && (!dfmop.Equals("member-list")) &&
			(!dfmop.Equals("member-add")) && (!dfmop.Equals("member-remove")))
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
				else if (dfmop.Equals("member-list"))
					MemberList();
				else if (dfmop.Equals("member-add"))
					MemberAdd();
				else if (dfmop.Equals("member-remove"))
					MemberRemove();
				else
					Usage();
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

		static String Result(String result)
		{
			// Checking for the string "passed" in the output
			String r = (result.Equals("passed"))
			? "Successful" : "UnSuccessful";
			return r;
		}

		static void Create()
		{
			String fullThresh = null;
			String nearlyFullThresh = null;
			String resourceTag = null;

			// Getting the pool name
			String poolName = Args[4];

			// parsing optional parameters
			int i=5;
			while( i < Args.Length) {
				if(Args[i].Equals("-t"))      {
					resourceTag = Args[++i]; ++i ;
				} else if(Args[i].Equals("-f")) {
					fullThresh = Args[++i]; ++i ;
				} else if(Args[i].Equals("-n")) {
					nearlyFullThresh = Args[++i]; ++i ;
				} else {
					Usage();
				}
			}

			try
			{
				// creating the input for api execution
				// creating a resourcepool-create element and adding child 
				// elements
				NaElement input = new NaElement("resourcepool-create");
				NaElement rpool = new NaElement("resourcepool");
				NaElement pool = new NaElement("resourcepool-info");
				pool.AddNewChild("resourcepool-name",poolName);
				if(resourceTag != null)
					pool.AddNewChild("resource-tag",resourceTag);
				if(fullThresh != null)
					pool.AddNewChild("resourcepool-full-threshold",fullThresh);
				if(nearlyFullThresh != null)
					pool.AddNewChild("resourcepool-nearly-full-threshold",
					nearlyFullThresh);

				rpool.AddChildElement(pool);
				input.AddChildElement(rpool);

				// invoking the api && printing the xml ouput
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nPool creation "
				+ Result(output.GetAttr("status")));
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

		static void List()
		{
			String poolName = null;

			try {
				// creating a resource pool start element
				NaElement input = 
				new NaElement("resourcepool-list-info-iter-start");
				if(Args.Length > 4) {
					poolName = Args[4];
					input.AddNewChild("object-name-or-id",poolName);
				}

				// invoke the api && capturing the records && tag values
				NaElement output = server.InvokeElem(input);


				// Extracting the record && tag values && printing them
				String records = output.GetChildContent("records");

				if (records.Equals("0"))
					Console.WriteLine("\nNo resourcepools to display");


				String tag = output.GetChildContent("tag");


				// Extracting records one at a time
				input = new NaElement("resourcepool-list-info-iter-next");
				input.AddNewChild("maximum",records);
				input.AddNewChild("tag",tag);
				NaElement record = server.InvokeElem(input);

				// Navigating to the resourcepools child element
				NaElement stat = record.GetChildByName("resourcepools");

				// Navigating to the schedule-info child element
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

					Console.WriteLine(
					"--------------------------------------------------------");
					// extracting the resource-pool name and printing it
					value = info.GetChildContent("resourcepool-name");
					Console.WriteLine("Resourcepool Name : " + value);

					value = info.GetChildContent("resourcepool-id");
					Console.WriteLine("Resourcepool Id : " + value);

					value = info.GetChildContent("resourcepool-description");
					Console.WriteLine("Resourcepool Description : " + value);

					Console.WriteLine(
					"--------------------------------------------------------");

					// printing detials if only one resource-pool is selected for listing
					if(poolName != null) {

						value = info.GetChildContent("\nresourcepool-status");
						Console.WriteLine("Resourcepool Status                "
						+ "      : " + value);

						value = 
						info.GetChildContent("resourcepool-perf-status");
						Console.WriteLine("Resourcepool Perf Status           "
						+ "      : " + value);

						value = info.GetChildContent("resource-tag");
						Console.Write("Resource Tag                           "
						+ "  : ");
						if(value != null)
							Console.Write(value);

						value = 
						info.GetChildContent("resourcepool-member-count");
						Console.WriteLine("\nResourcepool Member Count         "
						+ "       : " + value);

						value = 
						info.GetChildContent("resourcepool-full-threshold");
						Console.Write("Resourcepool Full Threshold            "
						+ "  : ");
						if(value != null)
							Console.Write(value + "%");

						value = info.
						GetChildContent("resourcepool-nearly-full-threshold");
						Console.Write("\nResourcepool Nearly Full Threshold    "
						+ "   : ");
						if(value != null)
							Console.Write(value + "%");

						value = info.GetChildContent("aggregate-nearly-"
						+ "overcommitted-threshold");
						Console.WriteLine("\nAggregate Nearly Overcommitted"
						+ " Threshold : " + value + "%");

						value = info.
						GetChildContent("aggregate-overcommitted-threshold");
						Console.WriteLine("Aggregate Overcommitted Threshold   "
						+ "     : " + value + "%");
					}
				}

				// invoking the iter-end zapi
				input = new NaElement("resourcepool-list-info-iter-end");
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
			String poolName = Args[4];

			try {
			 // invoking the api && printing the xml ouput
				NaElement input = new NaElement("resourcepool-destroy");
				input.AddNewChild("resourcepool-name-or-id",poolName);
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nPool deletion "
				+ Result(output.GetAttr("status")));

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

		static void MemberAdd()
		{
			String memberResourceTag = null;

			// Getting the resource pool and member name
			String poolName = Args[4];
			String memberName = Args[5];

			// parsing optional parameters
			int i=6;
			while( i < Args.Length) {
				if(Args[i].Equals("-m")) {
					memberResourceTag = Args[++i]; ++i ;
				} else {
					Usage();
				}
			}

			try {
				// creating the input for api execution
				// creating a resourcepool-add-member element and adding 
				// child elements
				NaElement input = new NaElement("resourcepool-add-member");
				input.AddNewChild("resourcepool-name-or-id",poolName);
				input.AddNewChild("member-name-or-id",memberName);
				if(memberResourceTag != null)
					input.AddNewChild("resource-tag",memberResourceTag);

				// invoking the api && printing the xml ouput
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nMember addition "
				+ Result(output.GetAttr("status")));
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

		static void MemberList() {
			String memberName = null;
			String poolName = Args[4];

			try {
				// creating a resourcepool member start element
				NaElement input = 
				new NaElement("resourcepool-member-list-info-iter-start");
				input.AddNewChild("resourcepool-name-or-id",poolName);
				if(Args.Length > 5) {
					memberName = Args[5];
					input.
					AddNewChild("resourcepool-member-name-or-id",memberName);
				}

				// invoke the api && capturing the records && tag values
				NaElement output = server.InvokeElem(input);


				// Extracting the record && tag values && printing them
				String records = output.GetChildContent("records");

				if (records.Equals("0"))
					Console.WriteLine("\nNo members to display");


				String tag = output.GetChildContent("tag");

				// Extracting records one at a time
				input = 
				new NaElement("resourcepool-member-list-info-iter-next");
				input.AddNewChild("maximum",records);
				input.AddNewChild("tag",tag);
				NaElement record = server.InvokeElem(input);

				// Navigating to the resourcepool-members child element
				NaElement stat = record.GetChildByName("resourcepool-members");

				// Navigating to the schedule-info child element
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

					// extracting the member name and printing it
					String name = info.GetChildContent("member-name");
					String id = info.GetChildContent("member-id");
					if(memberName == null || (memberName != null &&
						(name.Equals(memberName) || id.Equals(memberName)))) {
						Console.WriteLine(
						"----------------------------------------------------");
						Console.WriteLine("Member Name : " + name);
						Console.WriteLine("Member Id : " + id);
						Console.WriteLine(
						"----------------------------------------------------");
					} else {
						throw new NaException("Member " + memberName + " name not found");
					}

					// printing detials if only one member is selected for listing
					if(memberName != null && (name.Equals(memberName) 
					|| id.Equals(memberName))) {

						value = info.GetChildContent("member-type");
						Console.WriteLine("\nMember Type            : "+ value);

						value = info.GetChildContent("member-status");
						Console.WriteLine("Member Status          : " + value);

						value = info.GetChildContent("member-perf-status");
						Console.WriteLine("Member Perf Status     : " + value);

						value = info.GetChildContent("resource-tag");
						Console.Write("Resource Tag           : ");
						if(value != null)
							Console.Write(value);

						value = info.GetChildContent("member-count");
						Console.Write("\nMember Member Count    : ");
						if(value != null)
							Console.Write(value);

						value = info.GetChildContent("member-used-space");
						Console.WriteLine("\nMember Used Space      : "
						+ value + " bytes");

						value = info.GetChildContent("member-committed-space");
						Console.WriteLine("Member Committed Space : "
						+ value + " bytes");

						value = info.GetChildContent("member-size");
						Console.WriteLine("Member Size            : "
						+ value + " bytes");
					}
				}

				// invoking the iter-end zapi
				input = new NaElement("resourcepool-member-list-info-iter-end");
				input.AddNewChild("tag",tag);
				server.InvokeElem(input);

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

		static void MemberRemove() {
			String poolName = Args[4];
			String memberName = Args[5];

			try {
			 // invoking the api && printing the xml ouput
				NaElement input = new NaElement("resourcepool-remove-member");
				input.AddNewChild("resourcepool-name-or-id",poolName);
				input.AddNewChild("member-name-or-id",memberName);
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nMember deletion "
				+ Result(output.GetAttr("status")));

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
	}
}