//===============================================================//
//                                                               //
// $ID$                                                          //
//                                                               //
// vfiler.cs                                                     //
//                                                               //
// Copyright (c) 2009 NetApp, Inc. All rights reserved.          //
// Specifications subject to change without notice.              //
//                                                               //
// Sample code to demonstrate how to manage vFiler units         //
// on a DFM server                                               //
// you can create and delete vFiler units, create,list and       //
// delete vFiler Templates                                       //
//                                                               //
// This Sample code is supported from DataFabric Manager 3.7.1   //
// onwards.                                                      //
// However few of the functionalities of the sample code may     //
// work on older versions of DataFabric Manager.                 //
//===============================================================//

using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace NetApp.ManageabilitySDK.Samples.Basic.Vfiler
{
	class Vfiler
	{
		private static NaServer server;
		private static String[] Args;


		static void Usage()
		{
			Console.WriteLine("" +
	"Usage:\n" +
	"vfiler <dfmserver> <user> <password> delete <name>\n" +
	"\n" +
	"vfiler <dfmserver> <user> <password> create <name> <rpool>"
	+ " <ip> [ <tname> ]\n" +
	"\n" +
	"vfiler <dfmserver> <user> <password> template-list [ <tname> ]\n" +
	"\n" +
	"vfiler <dfmserver> <user> <password> template-delete <tname>\n" +
	"\n" +
	"vfiler <dfmserver> <user> <password> template-create <a-tname>\n" +
	"[ -a <cauth> -d <cdomain> ] [ -s <csecurity> ]\n" +
	"\n" +
	"<dfmserver> -- Name/IP Address of the DFM server\n" +
	"<user>      -- DFM server User name\n" +
	"<password>  -- DFM server User Password\n" +
	"<rpool>     -- Resource pool in which vFiler is to be created\n" +
	"<ip>        -- ip address of the new vFiler\n" +
	"<name>      -- name of the new vFiler to be created\n" +
	"<tname>     -- Existing Template name\n" +
	"<a-tname>   -- Template to be created\n" +
	"<cauth>     -- CIFS authentication mode Possible values: "
	+ "\"active_directory\",\n" +
	"               \"workgroup\". Default value: \"workgroup\"\n" +
	"<cdomain>   -- Active Directory domain .This field is applicable"
	+ " only when\n" +
	"               cifs-auth-type is set to \"active-directory\"\n" +
	"<csecurity> -- The security style Possible values: \"ntfs\","
	+ " \"multiprotocol\"\n" +
	"               Default value is: \"multiprotocol\"");

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

			// checking for valid number of parameters for the respective 
			// operations
			if ((dfmop.Equals("delete") && arglen != 5) 
				|| (dfmop.Equals("create") && arglen < 7) 
				|| (dfmop.Equals("template-list") && arglen < 4) 
				|| (dfmop.Equals("template-delete") && arglen != 5)
				|| (dfmop.Equals("template-create") && arglen < 5))
					Usage();

			// checking if the operation selected is valid
			if ((!dfmop.Equals("list")) && (!dfmop.Equals("create"))
			&& (!dfmop.Equals("delete")) && (!dfmop.Equals("template-list")) 
			&& (!dfmop.Equals("template-create")) 
			&& (!dfmop.Equals("template-delete")))
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
				else if (dfmop.Equals("delete"))
					Delete();
				else if (dfmop.Equals("template-list"))
					TemplateList();
				else if (dfmop.Equals("template-create"))
					TemplateCreate();
				else if (dfmop.Equals("template-delete"))
					TemplateDelete();
				else Usage();
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
			String templateName = null;

			// Getting the vfiler name, resource pool name and ip
			String vfilerName = Args[4];
			String poolName = Args[5];
			String ip = Args[6];

			if (Args.Length > 7)
				templateName = Args[7];

			try
			{
				// creating the input for api execution
				// creating a vfiler-create element and adding child elements
				NaElement input = new NaElement("vfiler-create");
				input.AddNewChild("ip-address", ip);
				input.AddNewChild("name", vfilerName);
				input.AddNewChild("resource-name-or-id", poolName);
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nvFiler unit creation "
				+ Result(output.GetAttr("status")));
				Console.WriteLine("\nvFiler unit created on Storage System : "
				+ output.GetChildContent("filer-name") + "\nRoot Volume : "
				+ output.GetChildContent("root-volume-name"));

				if (templateName != null)
					setup(vfilerName, templateName);

			}
			catch (Exception e)
			{
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
		}

		static void setup(String vName, String tName)
		{
			try
			{
				// creating the input for api execution
				// creating a vfiler-create element and adding child elements
				NaElement input = new NaElement("vfiler-setup");
				input.AddNewChild("vfiler-name-or-id", vName);
				input.AddNewChild("vfiler-template-name-or-id", tName);
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nvFiler unit setup with template "
				+ tName + " " + Result(output.GetAttr("status")));

			}
			catch (Exception e)
			{
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
		}

		static void Delete()
		{
			String vfilerName = Args[4];

			try
			{
				// invoking the api && printing the xml ouput
				NaElement input = new NaElement("vfiler-destroy");
				input.AddNewChild("vfiler-name-or-id", vfilerName);
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nvFiler unit deletion "
				+ Result(output.GetAttr("status")));

			}
			catch (Exception e)
			{
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
		}

		static void TemplateCreate()
		{
			String cifsAuth = null;
			String cifsDomain = null;
			String cifsSecurity = null;

			// Getting the template name
			String templateName = Args[4];

			// parsing optional parameters
			int i = 5;
			while (i < Args.Length)
			{
				if (Args[i].Equals("-a"))
				{
					cifsAuth = Args[++i]; ++i;
				}
				else if (Args[i].Equals("-d"))
				{
					cifsDomain = Args[++i]; ++i;
				}
				else if (Args[i].Equals("-s"))
				{
					cifsSecurity = Args[++i]; ++i;
				}
				else
				{
					Usage();
				}
			}

			try
			{
				// creating the input for api execution
				// creating a vfiler-template-create element and adding
				// child elements
				NaElement input = new NaElement("vfiler-template-create");
				NaElement temp = new NaElement("vfiler-template");
				NaElement template = new NaElement("vfiler-template-info");
				template.AddNewChild("vfiler-template-name", templateName);
				if (cifsAuth != null)
					template.AddNewChild("cifs-auth-type", cifsAuth);
				if (cifsDomain != null)
					template.AddNewChild("cifs-domain", cifsDomain);
				if (cifsSecurity != null)
					template.AddNewChild("cifs-security-style", cifsSecurity);
				temp.AddChildElement(template);
				input.AddChildElement(temp);

				// invoking the api && printing the xml ouput
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nvFiler template creation "
				+ Result(output.GetAttr("status")));
			}
			catch (Exception e)
			{
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
		}

		static void TemplateList()
		{
			String templateName = null;

			try
			{
				// creating a template lsit start element
				NaElement input = 
				new NaElement("vfiler-template-list-info-iter-start");
				if (Args.Length > 4)
				{
					templateName = Args[4];
					input.
					AddNewChild("vfiler-template-name-or-id", templateName);
				}

				// invoke the api && capturing the records && tag values
				NaElement output = server.InvokeElem(input);

				// Extracting the record && tag values && printing them
				String records = output.GetChildContent("records");

				if(records.Equals("0"))
					Console.WriteLine("\nNo templates to display");

				String tag = output.GetChildContent("tag");


				// Extracting records one at a time
				input = new NaElement("vfiler-template-list-info-iter-next");
				input.AddNewChild("maximum", records);
				input.AddNewChild("tag", tag);
				NaElement record = server.InvokeElem(input);

				// Navigating to the vfiler templates child element
				NaElement stat = record.GetChildByName("vfiler-templates");

				// Navigating to the vfiler-info child element
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
					// extracting the template name and printing it
					value = info.GetChildContent("vfiler-template-name");
					Console.WriteLine("Template Name : " + value);

					value = info.GetChildContent("vfiler-template-id");
					Console.WriteLine("Template Id : " + value);

					value = info.GetChildContent("vfiler-template-description");
					Console.Write("Template Description : ");
					if (value != null)
						Console.Write(value);

					Console.WriteLine("\n----------------------------------"
					+ "--------------");

					// printing detials if only one template is selected 
					if (templateName != null)
					{

						value = info.GetChildContent("cifs-auth-type");
						Console.WriteLine("\nCIFS Authhentication     : "
						+ value);

						value = info.GetChildContent("cifs-domain");
						Console.Write("CIFS Domain              : ");
						if (value != null)
							Console.Write(value);

						value = info.GetChildContent("cifs-security-style");
						Console.WriteLine("\nCIFS Security Style      : "
						+ value);

						value = info.GetChildContent("dns-domain");
						Console.Write("DNS Domain               : ");
						if (value != null)
							Console.Write(value);

						value = info.GetChildContent("nis-domain");
						Console.Write("\nNIS Domain               : ");
						if (value != null)
							Console.WriteLine(value);
					}
				}

				// invoking the iter-end zapi
				input = new NaElement("vfiler-template-list-info-iter-end");
				input.AddNewChild("tag", tag);
				server.InvokeElem(input);

			}
			catch (Exception e)
			{
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
		}

		static void TemplateDelete()
		{
			String templateName = Args[4];

			try
			{
				// invoking the api && printing the xml ouput
				NaElement input = new NaElement("vfiler-template-delete");
				input.AddNewChild("vfiler-template-name-or-id", templateName);
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nTemplate deletion "
				+ Result(output.GetAttr("status")));

			}
			catch (Exception e)
			{
				Console.Error.WriteLine(e.Message);
				Environment.Exit(1);
			}
		}
	}
}
