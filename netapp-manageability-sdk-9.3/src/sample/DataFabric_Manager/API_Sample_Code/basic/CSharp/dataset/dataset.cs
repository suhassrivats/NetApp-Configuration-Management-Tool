//===============================================================//
//                                                               //
// $ID$                                                          //
//                                                               //
// dataset.cs                                                    //
//                                                               //
// Copyright (c) 2009 NetApp, Inc. All rights reserved.          //
// Specifications subject to change without notice.              //
//                                                               //
// Sample code to demonstrate how to manage dataset              //
// on a DFM server                                               //
// you can create,delete and list datasets                       //
// add,list,delete and provision members                         //
//                                                               //
// This Sample code is supported from DataFabric Manager 3.8     //
// onwards.                                                      //
// However few of the functionalities of the sample code may     //
// work on older versions of DataFabric Manager.                 //
//===============================================================//

using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using NetApp.Manage;

namespace NetApp.ManageabilitySDK.Samples.Basic.Dataset
{
	class Dataset
	{
		private static NaServer server;
		private static String[] Args;


		static void Usage(){
		Console.WriteLine("" +
"Usage:\n" +
"dataset <dfmserver> <user> <password> list [ <dataset name> ]\n" +
"\n" +
"dataset <dfmserver> <user> <password> delete <dataset name>\n" +
"\n" +
"dataset <dfmserver> <user> <password> create <dataset name>\n" +
"[ -v <prov-pol> ] [ -t <prot-pol> ] [ -r <rpool>]\n" +
"\n" +
"dataset <dfmserver> <user> <password> member-add <a-mem-dset> <member>\n" +
"\n" +
"dataset <dfmserver> <user> <password> member-list <mem-dset> [ <member> ]\n" +
"\n" +
"dataset <dfmserver> <user> <password> member-remove <mem-dset> <member>\n" +
"\n" +
"dataset <dfmserver> <user> <password> member-provision <p-mem-dset>"
+ " <member>\n" +
"<size> [ <snap-size> ]\n" +
"\n" +
"<operation>    -- create or delete or list\n" +
"\n" +
"<dfmserver>    -- Name/IP Address of the DFM server\n" +
"<user>         -- DFM server User name\n" +
"<password>     -- DFM server User Password\n" +
"<dataset name> -- dataset name\n" +
"<prov-pol>     -- name or id of an exisitng nas provisioning policy\n" +
"<prot-pol>     -- name or id of an exisitng protection policy\n" +
"<rpool>        -- name or id of an exisitng resourcepool\n" +
"<a-mem-dset>   -- dataset to which the member will be added\n" +
"<mem-dset>     -- dataset containing the member\n" +
"<p-mem-dset>   -- dataset with resourcepool and provisioning policy"
+ " attached\n" +
"<member>       -- name or Id of the member (volume/LUN or qtree)\n" +
"<size>         -- size of the member to be provisioned\n" +
"<snap-size>    -- maximum snapshot space required only for provisioning"
+ " using\n" +
"                  \"san\" provision policy" +
"<data-size>    -- Maximum storage space space for the dataset member"
+ " required\n" +
"                  only for provisioning using \"nas\" provision policy"
+ " with nfs\n" +
"\n" +
"Note : All size in bytes");
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

			// checking for valid number of parameters for the operations
			if ((dfmop.Equals("list") && arglen < 4) 
				|| (dfmop.Equals("delete") && arglen != 5) 
				|| (dfmop.Equals("create") && arglen < 5) 
				|| (dfmop.Equals("member-list") && arglen < 5)
				|| (dfmop.Equals("member-remove") && arglen != 6) 
				|| (dfmop.Equals("member-add") && arglen != 6) 
				|| (dfmop.Equals("member-provision") && arglen < 7))
					Usage();

			// checking if the operation selected is valid
			if ((!dfmop.Equals("list")) && (!dfmop.Equals("create"))
			&& (!dfmop.Equals("delete")) && (!dfmop.Equals("member-list")) &&
			(!dfmop.Equals("member-add")) && (!dfmop.Equals("member-remove"))
			&& (!dfmop.Equals("member-provision")))
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
				else if (dfmop.Equals("member-provision"))
					MemberProvision();
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
			String provPolName = null;
			String protPolName = null;
			String resourcePool = null;

			// Getting the dataset name
			String datasetName = Args[4];

			// parsing optional parameters
			int i=5;
			while( i < Args.Length) {
				if(Args[i].Equals("-v")) {
					provPolName = Args[++i]; ++i ;
				} else if(Args[i].Equals("-t")) {
					protPolName = Args[++i]; ++i ;
				} else if(Args[i].Equals("-r")) {
					resourcePool = Args[++i]; ++i ;
				} else {
					Usage();
				}
			}

			try {
				// creating the input for api execution
				// creating a dataset-create element and adding child elements
				NaElement input = new NaElement("dataset-create");
				input.AddNewChild("dataset-name",datasetName);
				if(provPolName != null)
					input.AddNewChild("provisioning-policy-name-or-id",
					provPolName);
				if(protPolName != null)
					input.AddNewChild("protection-policy-name-or-id",
					protPolName);

				// invoking the api && printing the xml ouput
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nDataset creation "
				+ Result(output.GetAttr("status")));

				if(resourcePool != null)
					addResourcePool(resourcePool);
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

		static void addResourcePool(String rPool)
		{
			NaElement input;
			NaElement output;

			try {
				// Setting the edit lock for adding resource pool
				input = new NaElement("dataset-edit-begin");
				input.AddNewChild("dataset-name-or-id",Args[4]);
				output = server.InvokeElem(input);

				// extracting the edit lock id
				String lockId = output.GetChildContent("edit-lock-id");

				try {
					// Invoking add resource pool element
					input = new NaElement("dataset-add-resourcepool");
					input.AddNewChild("edit-lock-id",lockId);
					input.AddNewChild("resourcepool-name-or-id",rPool);
					output = server.InvokeElem(input);

					input = new NaElement("dataset-edit-commit");
					input.AddNewChild("edit-lock-id",lockId);
					output = server.InvokeElem(input);
				}
				catch (Exception e) {
					Console.Error.WriteLine(e.Message);
					input = new NaElement("dataset-edit-rollback");
					input.AddNewChild("edit-lock-id",lockId);
					server.InvokeElem(input);
					Environment.Exit(1);
				}

				Console.WriteLine("\nResourcepool add "
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
			String datasetName = null;

			try {
				// creating a dataset list start element
				NaElement input = new NaElement("dataset-list-info-iter-start");
				if(Args.Length > 4) {
					datasetName = Args[4];
					input.AddNewChild("object-name-or-id",datasetName);
				}

				// Invoke the api && capturing the records && tag values
				NaElement output = server.InvokeElem(input);

				// Extracting the record && tag values && printing them
				String records = output.GetChildContent("records");

				if (records.Equals("0"))
					Console.WriteLine("\nNo datasets to display");

				String tag = output.GetChildContent("tag");



				// Extracting records one at a time
				input = new NaElement("dataset-list-info-iter-next");
				input.AddNewChild("maximum",records);
				input.AddNewChild("tag",tag);
				NaElement record = server.InvokeElem(input);

				// Navigating to the datasets child element
				NaElement stat = record.GetChildByName("datasets");

				// Navigating to the dataset-info child element
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

					// extracting the dataset name and printing it
					Console.WriteLine(
					"--------------------------------------------------------");
					value = info.GetChildContent("dataset-name");
					Console.WriteLine("Dataset Name : " + value);

					value = info.GetChildContent("dataset-id");
					Console.WriteLine("Dataset Id : " + value);

					value = info.GetChildContent("dataset-description");
					Console.WriteLine("Dataset Description : " + value);

					Console.WriteLine(
					"--------------------------------------------------------");

					// printing detials if only one dataset is selected
					if(datasetName != null)
					{


						value = info.GetChildContent("\ndataset-contact");
						Console.WriteLine("Dataset Contact          : "+ value);

						value = info.GetChildContent("provisioning-policy-id");
						Console.Write("Provisioning Policy Id   : ");
						if(value != null)
							 Console.Write(value);

						value = 
						info.GetChildContent("provisioning-policy-name");
						Console.Write("\nProvisioning Policy Name : ");
						if(value != null)
							Console.Write(value);

						value = info.GetChildContent("protection-policy-id");
						Console.Write("\nProtection Policy Id     : ");
						if(value != null)
							Console.Write(value);

						value = info.GetChildContent("protection-policy-name");
						Console.Write("\nProtection Policy Name   : ");
						if(value != null)
							Console.Write(value);

						value = info.GetChildContent("resourcepool-name");
						Console.Write("\nResource Pool Name       : ");
						if(value != null)
							Console.Write(value);

						NaElement status = 
						info.GetChildByName("dataset-status");

						value = status.GetChildContent("resource-status");
						Console.WriteLine("\nResource Status          : "
						+ value);

						value = status.GetChildContent("conformance-status");
						Console.WriteLine("Conformance Status       : "+ value);

						value = status.GetChildContent("performance-status");
						Console.WriteLine("Performance Status       : "+ value);

						value = status.GetChildContent("protection-status");
						Console.Write("Protection Status        : ");
						if(value != null)
							Console.Write(value);

						value = status.GetChildContent("space-status");
						Console.WriteLine("\nSpace Status             : "
						+ value);
					}
				}

				// invoking the iter-end zapi
				input = new NaElement("dataset-list-info-iter-end");
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

		static void Delete()
		{
			String datasetName = Args[4];

			try {
				// invoking the api && printing the xml ouput
				NaElement input = new NaElement("dataset-destroy");
				input.AddNewChild("dataset-name-or-id",datasetName);
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nDataset deletion "
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

		static void MemberAdd()
		{
			NaElement input;
			NaElement output;

			// Getting the dataset name and member name
			String datasetName = Args[4];
			String memberName = Args[5];

			try {
				// Setting the edit lock for adding member
				input = new NaElement("dataset-edit-begin");
				input.AddNewChild("dataset-name-or-id",Args[4]);
				output = server.InvokeElem(input);

				// extracting the edit lock id
				String lockId = output.GetChildContent("edit-lock-id");

				try {
				// creating the input for api execution
					// creating a dataset-add-member element and adding child 
					// elements
					input = new NaElement("dataset-add-member");
					input.AddNewChild("edit-lock-id",lockId);
					NaElement mem = new NaElement("dataset-member-parameters");
					NaElement param = new NaElement("dataset-member-parameter");
					param.AddNewChild("object-name-or-id",memberName);
					mem.AddChildElement(param);
					input.AddChildElement(mem);
					// invoking the api && printing the xml ouput
					output = server.InvokeElem(input);

					input = new NaElement("dataset-edit-commit");
					input.AddNewChild("edit-lock-id",lockId);
					output = server.InvokeElem(input);
				}
				catch (Exception e) {
					Console.Error.WriteLine(e.Message);
					input = new NaElement("dataset-edit-rollback");
					input.AddNewChild("edit-lock-id",lockId);
					server.InvokeElem(input);
					Environment.Exit(1);
				}

				Console.WriteLine("\nMember addition "
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

		static void MemberList()
		{
			String memberName = null;
			String datasetName = Args[4];

			try {
				// creating a dataset member list start element
				NaElement input = 
				new NaElement("dataset-member-list-info-iter-start");
				input.AddNewChild("dataset-name-or-id",datasetName);
				if(Args.Length > 5) {
					memberName = Args[5];
					input.AddNewChild("member-name-or-id",memberName);
				}
				input.AddNewChild("include-indirect","true");

				// Invoke the api && capturing the records && tag values
				NaElement output = server.InvokeElem(input);

				// Extracting the record && tag values && printing them
				String records = output.GetChildContent("records");

				if (records.Equals("0"))
					Console.WriteLine("\nNo members to display");

				String tag = output.GetChildContent("tag");


				// Extracting records one at a time
				input = new NaElement("dataset-member-list-info-iter-next");
				input.AddNewChild("maximum",records);
				input.AddNewChild("tag",tag);
				NaElement record = server.InvokeElem(input);

				// Navigating to the dataset-members child element
				NaElement stat = record.GetChildByName("dataset-members");

				// Navigating to the dataset-info child element
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

					String name = info.GetChildContent("member-name");
					String id = info.GetChildContent("member-id");

					if (!name.EndsWith("-"))
					{
						// extracting the member name and printing it
						Console.WriteLine(
						"----------------------------------------------------");

						Console.WriteLine("Member Name : " + name);
						Console.WriteLine("Member Id : " + id);
						Console.WriteLine(
						"----------------------------------------------------");

						// printing details if only one member is selected
						if (memberName != null)
						{

							value = info.GetChildContent("member-type");
							Console.WriteLine("\nMember Type            : "
							+ value);

							value = info.GetChildContent("member-status");
							Console.WriteLine("Member Status          : "
							+ value);

							value = info.GetChildContent("member-perf-status");
							Console.WriteLine("Member Perf Status     : "
							+ value);

							value = info.GetChildContent("storageset-id");
							Console.WriteLine("Storageset Id          : "
							+ value);

							value = info.GetChildContent("storageset-name");
							Console.WriteLine("Storageset Name        : "
							+ value);
							value = info.GetChildContent("dp-node-name");
							Console.WriteLine("Node Name              : " +
								value);
						}
					}
				}

				// invoking the iter-end zapi
				input = new NaElement("dataset-member-list-info-iter-end");
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

		static void MemberRemove()
		{
			String datasetName = Args[4];
			String memberName = Args[5];

			NaElement input;
			NaElement output;

			try {
				// Setting the edit lock for removing member
				input = new NaElement("dataset-edit-begin");
				input.AddNewChild("dataset-name-or-id",Args[4]);
				output = server.InvokeElem(input);

				// extracting the edit lock id
				String lockId = output.GetChildContent("edit-lock-id");

				try {

					// invoking the api && printing the xml ouput
					input = new NaElement("dataset-remove-member");
					input.AddNewChild("edit-lock-id",lockId);
					NaElement mem = new NaElement("dataset-member-parameters");
					NaElement param = new NaElement("dataset-member-parameter");
					param.AddNewChild("object-name-or-id",memberName);
					mem.AddChildElement(param);
					input.AddChildElement(mem);
					// invoking the api && printing the xml ouput
					output = server.InvokeElem(input);

					input = new NaElement("dataset-edit-commit");
					input.AddNewChild("edit-lock-id",lockId);
					output = server.InvokeElem(input);
				}
				catch (Exception e) {
					Console.Error.WriteLine(e.Message);
					input = new NaElement("dataset-edit-rollback");
					input.AddNewChild("edit-lock-id",lockId);
					server.InvokeElem(input);
					Environment.Exit(1);
				}

				Console.WriteLine("\nMember remove "
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

		static void MemberProvision()
		{
			String datasetName = Args[4];
			String memberName = Args[5];
			String size = Args[6];
			String maxSize = null;

			if(Args.Length > 7) maxSize = Args[7];

			NaElement input;
			NaElement output;
			NaElement finalOutput;
			String jobId;

			try {
				// Setting the edit lock for provisioning member
				input = new NaElement("dataset-edit-begin");
				input.AddNewChild("dataset-name-or-id",Args[4]);
				output = server.InvokeElem(input);

				// extracting the edit lock id
				String lockId = output.GetChildContent("edit-lock-id");

				try {

					// invoking the api && printing the xml ouput
					input = new NaElement("dataset-provision-member");
					input.AddNewChild("edit-lock-id",lockId);
					NaElement provMember = 
					new NaElement("provision-member-request-info");
					provMember.AddNewChild("name", memberName);
					provMember.AddNewChild("size", size);
					if(maxSize != null){
						// for san
						provMember.
						AddNewChild("maximum-snapshot-space",maxSize);
						// for nas with nfs
						provMember.AddNewChild("maximum-data-size",maxSize);
					}
					input.AddChildElement(provMember);

					// invoking the api && printing the xml ouput
					output = server.InvokeElem(input);

					input = new NaElement("dataset-edit-commit");
					input.AddNewChild("edit-lock-id",lockId);
					finalOutput = server.InvokeElem(input);
					jobId = (finalOutput.GetChildByName("job-ids")).
					GetChildByName("job-info").GetChildContent("job-id");
					// tracking the job
					TrackJob(jobId);
				}
				catch (Exception e)
				{
					Console.Error.WriteLine(e.Message);
					input = new NaElement("dataset-edit-rollback");
					input.AddNewChild("edit-lock-id",lockId);
					server.InvokeElem(input);
					Environment.Exit(1);
				}
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

		static void TrackJob(String jobId)
		{
			String jobStatus = "running";
			NaElement xi;
			NaElement xo;

			try {
				Console.WriteLine("Job ID\t\t: " + jobId);
				Console.Write("Job Status\t: " + jobStatus);
				//Continuously poll to see if the job completed
				while (jobStatus.Equals("queued") || jobStatus.Equals("running")
						|| jobStatus.Equals("aborting"))
				{
					xi = new NaElement("dp-job-list-iter-start");
					xi.AddNewChild("job-id", jobId);
					xo = server.InvokeElem(xi);

					xi = new NaElement("dp-job-list-iter-next");
					xi.AddNewChild("maximum", xo.GetChildContent("records"));
					xi.AddNewChild("tag", xo.GetChildContent("tag"));
					xo = server.InvokeElem(xi);

					NaElement dpJobs = xo.GetChildByName("jobs");
					NaElement dpJobInfo = dpJobs.GetChildByName("dp-job-info");
					jobStatus = dpJobInfo.GetChildContent("job-state");
					Thread.Sleep(3000); Console.Write(".");
					if (jobStatus.Equals("completed") 
					|| jobStatus.Equals("aborted"))
					{
						Console.WriteLine("\nOverall Status\t: "
						+ dpJobInfo.GetChildContent("job-overall-status"));
					}
				}

				//Display the job result - success/failure and provisioned 
				// member details
				xi = new NaElement("dp-job-progress-event-list-iter-start");
				xi.AddNewChild("job-id", jobId);
				xo = server.InvokeElem(xi);

				xi = new NaElement("dp-job-progress-event-list-iter-next");
				xi.AddNewChild("tag", xo.GetChildContent("tag"));
				xi.AddNewChild("maximum", xo.GetChildContent("records"));
				xo = server.InvokeElem(xi);


				NaElement progEvnts = xo.GetChildByName("progress-events");
				System.Collections.IList progEvntsInfo = 
				progEvnts.GetChildren();
				Console.Write("\nProvision Details:\n");
				Console.WriteLine("==========================================="
				+ "===============");
				System.Collections.IEnumerator progIter = 
				progEvntsInfo.GetEnumerator();

				while (progIter.MoveNext())
				{
					NaElement evnt = (NaElement)progIter.Current;
					if(evnt.GetChildContent("event-type") != null)
					{
						Console.Write(evnt.GetChildContent("event-type"));
					}
					Console.WriteLine("\t: "
					+ evnt.GetChildContent("event-message") + "\n");
				}
			} catch (Exception e) {
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
		}
	}
}
