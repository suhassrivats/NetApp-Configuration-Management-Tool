//===============================================================//
// $ID$                                                          //
//                                                               //
// rbac.cs                                                       //
//                                                               //
// Copyright (c) 2009 NetApp, Inc. All rights reserved.          //
// Specifications subject to change without notice.              //
//                                                               //
// Sample code to demonstrate how to manage  a                   //
// Role Based Access Control (RBAC). Using this sample code,     //
// you can create, delete and list roles, operations, etc.       //
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

namespace NetApp.ManageabilitySDK.Samples.Basic.Rbac
{
	class Rbac
	{
		private static NaServer server;
		private static String[] Args;

		static void Main(String[] args)
		{
			// check for the valid no. of arguments
			if (args.Length < 4)
				Usage();

			String operation = null;
			server = null;

			try
			{
				// create the server context for DFM Server
				server = new NaServer(args[0], 1, 0);
				server.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
				server.ServerType = NaServer.SERVER_TYPE.DFM;
				server.SetAdminUser(args[1], args[2]);

				Args = args;
				operation = args[3];

				// Check for the given input operation and call
				//appropriate function.
				if (operation.Equals("operation-list"))
					OperationList();
				else if (operation.Equals("operation-add"))
					OperationAdd();
				else if (operation.Equals("operation-delete"))
					OperationDelete();
				else if (operation.Equals("role-add"))
					RoleAdd();
				else if (operation.Equals("role-delete"))
					RoleDelete();
				else if (operation.Equals("role-list"))
					RoleList();
				else if (operation.Equals("role-capability-add"))
					RoleCapabilityAdd();
				else if (operation.Equals("role-capability-delete"))
					RoleCapabilityDelete();
				else if (operation.Equals("admin-role-add"))
					AdminRoleAdd();
				else if (operation.Equals("admin-role-delete"))
					AdminRoleDelete();
				else if (operation.Equals("admin-role-list"))
					RoleAdminList();
				else if (operation.Equals("admin-list"))
					AdminList();
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

		// This function will list the roles assigned to an existing
		// administrator.
		static void RoleAdminList()
		{
			if (Args.Length < 5)
			{
				Usage();
			}
			String adminNameID = Args[4];
			String roleID = null;
			String roleName = null;


			try
			{
				//invoke the rbac-role-admin-info-list api and capture the ouput
				NaElement input = new NaElement("rbac-role-admin-info-list");
				input.AddNewChild("admin-name-or-id", adminNameID);
				input.AddNewChild("follow-role-inheritance", "TRUE");

				NaElement output = server.InvokeElem(input);

				Console.WriteLine(
				"----------------------------------------------------");
				String adminNameID2 = 
				output.GetChildContent("admin-name-or-id");
				Console.WriteLine("\nadmin name-id         :" + adminNameID);

				// get the list of roles which is contained in role-list element
				System.Collections.IList roleList = null;

				if (output.GetChildByName("role-list") != null)
					roleList = output.GetChildByName("role-list").GetChildren();
				if (roleList == null)
					return;
				System.Collections.IEnumerator roleIter = 
				roleList.GetEnumerator();
				// Iterate through each role record
				while (roleIter.MoveNext())
				{
					NaElement role = (NaElement)roleIter.Current;
					roleID = role.GetChildContent("rbac-role-id");
					roleName = role.GetChildContent("rbac-role-name");
					Console.WriteLine("\nrole name             : " + roleName);
					Console.WriteLine("role id               : " + roleID);
				}
				Console.WriteLine(
				"----------------------------------------------------");
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

		// This function will list all the administrators and their attributes.
		static void AdminList()
		{
			String adminNameID = "";

			try
			{
				// create the rbac-admin-list-info-iter-start API request
				NaElement input = 
				new NaElement("rbac-admin-list-info-iter-start");
				if (Args.Length == 5)
				{
					adminNameID = Args[4];
					input.AddNewChild("admin-name-or-id", adminNameID);
				}

				// invoke the api and capture the records and tag values for
				// rbac-admin-list-info-iter-next
				NaElement output = server.InvokeElem(input);

				String records = output.GetChildContent("records");
				String tag = output.GetChildContent("tag");

				// invoke the rbac-admin-list-info-iter-next api to return the
				// list of admins
				input = new NaElement("rbac-admin-list-info-iter-next");
				input.AddNewChild("maximum", records);
				input.AddNewChild("tag", tag);

				output = server.InvokeElem(input);


				System.Collections.IList adminList = null;
				// capture the list of admins which is contained in admins 
				// element
				if (output.GetChildByName("admins") != null)
					adminList = output.GetChildByName("admins").GetChildren();
				System.Collections.IEnumerator adminIter = 
				adminList.GetEnumerator();
				Console.WriteLine(
				"----------------------------------------------------");
				// Iterate through each admin record
				while (adminIter.MoveNext())
				{
					NaElement admin = (NaElement)adminIter.Current;
					String id = admin.GetChildContent("admin-id");
					String name = admin.GetChildContent("admin-name");
					Console.WriteLine("\nadmin name             : " + name);
					Console.WriteLine("admin id               : " + id);
					String email = admin.GetChildContent("email-address");
					if (email != null)
						Console.WriteLine("email address          : " + email);
				}
				Console.WriteLine(
				"----------------------------------------------------");
				input = new NaElement("rbac-admin-list-info-iter-end");
				input.AddNewChild("tag", tag);
				output = server.InvokeElem(input);
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

		//This function will remove a role from an administrator
		static void AdminRoleDelete()
		{

			if (Args.Length < 6)
			{
				Usage();
			}

			String adminNameID = Args[4];
			String rolenameID =  Args[5];

			try
			{
				// create the input rbac-admin-role-remove API request
				NaElement input = new NaElement("rbac-admin-role-remove");
				input.AddNewChild("admin-name-or-id", adminNameID);
				//check for the role name or delete all roles
				input.AddNewChild("role-name-or-id", rolenameID);
				// invoke the API request
				NaElement output = server.InvokeElem(input);
				Console.WriteLine("admin role(s) deleted successfully! ");
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

		//This function will assign an existing role to an existing 
		// administrator.
		static void AdminRoleAdd()
		{
			if (Args.Length < 6)
			{
				Usage();
			}

			String adminnameID = Args[4];
			String rolenameID = Args[5];
			String newAdminName = null;
			String newAdminID = null;
			try
			{
				// create the input rbac-admin-role-add API request
				NaElement input = new NaElement("rbac-admin-role-add");
				input.AddNewChild("admin-name-or-id", adminnameID);
				input.AddNewChild("role-name-or-id", rolenameID);

				// invoke the API request
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("admin role added successfully! ");
				NaElement newAdminNameID =
				output.GetChildByName("admin-name-or-id").
				GetChildByName("rbac-admin-name-or-id");
				newAdminName = newAdminNameID.GetChildContent("admin-name");
				newAdminID = newAdminNameID.GetChildContent("admin-id");
				Console.WriteLine("new admin name                    :" +
				newAdminName);
				Console.WriteLine("new admin id                      :" +
				newAdminID);
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

		//This function will remove one or more capabilities from an existing 
		// role.
		static void RoleCapabilityDelete()
		{

			if (Args.Length < 8)
			{
				Usage();
			}

			String roleNameID = Args[4];

			try
			{
				// create the input rbac-role-capability-remove API request
				NaElement input = new NaElement("rbac-role-capability-remove");
				input.AddNewChild("role-name-or-id", roleNameID);

				String rolenameID = Args[4];
				String operation = Args[5];
				String resourceType = Args[6];
				String resourceName = Args[7];
				// check for the resource type and frame the nested API 
				// request
				if (!resourceType.Equals("dataset") &&
				  !resourceType.Equals("filer"))
				{
					Console.WriteLine("Invalid resource type");
					System.Environment.Exit(2);
				}
				input.AddNewChild("operation", operation);
				NaElement resource = new NaElement("resource");
				NaElement resourceID = new NaElement("resource-identifier");
				input.AddChildElement(resource);
				resource.AddChildElement(resourceID);
				if (resourceType.Equals("dataset"))
				{
					NaElement dataset = new NaElement("dataset");
					NaElement datasetResource = 
					new NaElement("dataset-resource");
					datasetResource.
					AddNewChild("dataset-name", resourceName);
					dataset.AddChildElement(datasetResource);
					resourceID.AddChildElement(dataset);
				}
				else if (resourceType.Equals("filer"))
				{
					NaElement filer = new NaElement("filer");
					NaElement filerResource = 
					new NaElement("filer-resource");
					filerResource.AddNewChild("filer-name", resourceName);
					filer.AddChildElement(filerResource);
					resourceID.AddChildElement(filer);
				}
				// invoke the API
				NaElement output = server.InvokeElem(input);
				Console.WriteLine("capability removed successfully! \n");
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

		//This function will add a capability to a role.
		static void RoleCapabilityAdd()
		{

			if (Args.Length < 8)
			{
				Usage();
			}

			String rolenameID = Args[4];
			String operation = Args[5];
			String resourceType = Args[6];
			String resourceName = Args[7];

			// check for the proper resource type
			if (!resourceType.Equals("dataset") 
			&& !resourceType.Equals("filer"))
			{
				Console.Error.WriteLine("Invalid resource type");
				System.Environment.Exit(2);
			}

			try
			{
				// create the input rbac-role-capability-add API request
				NaElement input = new NaElement("rbac-role-capability-add");
				input.AddNewChild("operation", operation);
				input.AddNewChild("role-name-or-id", rolenameID);

				NaElement resource = new NaElement("resource");
				NaElement resourceID = new NaElement("resource-identifier");
				input.AddChildElement(resource);
				resource.AddChildElement(resourceID);
				// check for the resource type and frame the request
				if (resourceType.Equals("dataset"))
				{
					NaElement dataset = new NaElement("dataset");
					NaElement datasetResource = 
					new NaElement("dataset-resource");
					datasetResource.AddNewChild("dataset-name", resourceName);
					dataset.AddChildElement(datasetResource);
					resourceID.AddChildElement(dataset);
				}
				else if (resourceType.Equals("filer"))
				{
					NaElement filer = new NaElement("filer");
					NaElement filerResource = new NaElement("filer-resource");
					filerResource.AddNewChild("filer-name", resourceName);
					filer.AddChildElement(filerResource);
					resourceID.AddChildElement(filer);
				}

				// invoke the API
				NaElement output = server.InvokeElem(input);
				Console.WriteLine("capability added successfully! ");
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

		//This function will add a new role to the RBAC system
		static void RoleAdd()
		{

			if (Args.Length != 6)
			{
				Usage();
			}
			String role = Args[4];
			String description = Args[5];

			try
			{
				// create the input API request for role-add
				NaElement input = new NaElement("rbac-role-add");
				input.AddNewChild("role-name", role);
				input.AddNewChild("description", description);
				// invoke the api request and get the new role id
				NaElement output = server.InvokeElem(input);
				Console.WriteLine("new role-id: " +
				output.GetChildContent("role-id"));
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
			Console.WriteLine("role added successfully!");
		}

		// This function will delete an existing role from the RBAC system
		static void RoleDelete()
		{

			if (Args.Length < 5)
			{
				Usage();
			}
			String role = Args[4];
			try
			{
				// create the API request to delete role
				NaElement input = new NaElement("rbac-role-delete");
				input.AddNewChild("role-name-or-id", role);

				// invoke the API
				NaElement output = server.InvokeElem(input);
				Console.WriteLine("\nrole deleted successfully!");
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

		//This function will list the operations, capabilities
		// and inherited roles that one or more roles have.
		static void RoleList()
		{
			String role = null;
			String roleID = null;
			String roleName = null;
			String description = null;
			String inhRoleID = null;
			String inhRoleName = null;
			String operationName = null;
			String operationDesc = null;
			String operationSyn = null;
			String resourceType = null;

			if (Args.Length == 5)
				role = Args[4];

			try
			{
				// create the input rbac-role-info-list API request
				NaElement input = new NaElement("rbac-role-info-list");

				if (role != null)
					input.AddNewChild("role-name-or-id", role);

				// invoke the API and capture the role attributes
				NaElement output = server.InvokeElem(input);

				// get the list of role attributes which is contained under
				// role-attributes element
				System.Collections.IList attrList =
				output.GetChildByName("role-attributes").GetChildren();
				System.Collections.IEnumerator attrIter = 
				attrList.GetEnumerator();

				//iterate through each role attribute
				while (attrIter.MoveNext())
				{
					NaElement attribute = (NaElement)attrIter.Current;
					Console.WriteLine(
					"----------------------------------------------------");
					NaElement rolenameID =
					attribute.GetChildByName("role-name-and-id").
					GetChildByName("rbac-role-resource");
					roleID = rolenameID.GetChildContent("rbac-role-id");
					roleName = rolenameID.GetChildContent("rbac-role-name");
					description = attribute.GetChildContent("description");
					Console.WriteLine("role name                         : " +
					roleName);
					Console.WriteLine("role id                           : " +
					roleID);
					Console.WriteLine("role description                  : " +
					description + "\n");

					// iterate through the inherited roles
					System.Collections.IList inheritedList =
					attribute.GetChildByName("inherited-roles").GetChildren();
					System.Collections.IEnumerator inheritedIter = 
					inheritedList.GetEnumerator();

					while (inheritedIter.MoveNext())
					{
						NaElement inheritedRole =
						(NaElement)inheritedIter.Current;
						Console.WriteLine("inherited role details:\n");
						inhRoleID =
						inheritedRole.GetChildContent("rbac-role-id");
						inhRoleName =
						inheritedRole.GetChildContent("rbac-role-name");
						Console.WriteLine
						("inherited role name                : " + inhRoleName);
						Console.WriteLine
						("inherited role id                  : " + inhRoleID);
					}

					Console.WriteLine("operation details:\n");
					System.Collections.IList capList =
					attribute.GetChildByName("capabilities").GetChildren();

					System.Collections.IEnumerator capIter = 
					capList.GetEnumerator();
					// iterate through the role capabilities
					while (capIter.MoveNext())
					{
						NaElement capability = (NaElement)capIter.Current;
						NaElement operation = capability.
						GetChildByName("operation").
							GetChildByName("rbac-operation");
						operationName = operation.
						GetChildContent("operation-name");
						NaElement operationNameDetails =
						operation.GetChildByName("operation-name-details").
							GetChildByName("rbac-operation-name-details");
						operationDesc = operationNameDetails.
							GetChildContent("operation-description");
						operationSyn = operationNameDetails.
							GetChildContent("operation-synopsis");
						resourceType = operationNameDetails.
							GetChildContent("resource-type");

						Console.WriteLine("operation name                    :"
						+ operationName);
						Console.WriteLine("operation description             :"
						+ operationDesc);
						Console.WriteLine("operation synopsis                :"
						+ operationSyn);
						Console.WriteLine("resource type                     :"
						+ resourceType + "\n");
					}
				}
				Console.WriteLine(
				"----------------------------------------------------");
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

		//This funcion will add a new operation to the RBAC system.
		static void OperationAdd()
		{
			if (Args.Length < 8)
			{
				Usage();
			}
			String name = Args[4];
			String desc = Args[5];
			String synopsis = Args[6];
			String type = Args[7];

			try
			{
				// construct the input rbac-operation-add API request
				NaElement input = new NaElement("rbac-operation-add");
				NaElement operation = new NaElement("operation");
				NaElement rbacOperation = new NaElement("rbac-operation");
				rbacOperation.AddNewChild("operation-name", name);
				NaElement operationNameDetails =
				new NaElement("operation-name-details");
				NaElement rbacOperationNameDetails =
				new NaElement("rbac-operation-name-details");
				rbacOperationNameDetails.
				AddNewChild("operation-description", desc);
				rbacOperationNameDetails.
				AddNewChild("operation-synopsis", synopsis);
				rbacOperationNameDetails.AddNewChild("resource-type", type);
				input.AddChildElement(operation);
				operation.AddChildElement(rbacOperation);
				rbacOperation.AddChildElement(operationNameDetails);
				operationNameDetails.AddChildElement(rbacOperationNameDetails);

				// invoke the API request
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("Operation added successfully!");
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

		// This function will delete an existing operation.
		static void OperationDelete()
		{
			if (Args.Length < 5)
			{
				Usage();
			}
			String name = Args[4];

			try
			{
				// create the input rbac-operation-delete API request
				NaElement input = new NaElement("rbac-operation-delete");
				input.AddNewChild("operation", name);
				// invoke the API request
				NaElement output = server.InvokeElem(input);
				Console.WriteLine("\nOperation deleted successfully!");
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

		// This function will list about an existing operation or
		// all operations in the system.
		static void OperationList()
		{
			String operation = null;
			String name = null;
			String desc = null;
			String type = null;
			String synopsis = null;

			if (Args.Length == 5)
				operation = Args[4];

			try
			{
				// create the input API request
				NaElement input = new NaElement("rbac-operation-info-list");

				if (operation != null)
					input.AddNewChild("operation", operation);

				// now invoke the api request and get the operations list
				NaElement output = server.InvokeElem(input);

				System.Collections.IList oprList =
				output.GetChildByName("operation-list").GetChildren();
				System.Collections.IEnumerator oprIter = 
				oprList.GetEnumerator();

				// iterate through each operation
				Console.WriteLine(
				"\n----------------------------------------------------");
				while (oprIter.MoveNext())
				{
					NaElement opr = (NaElement)oprIter.Current;
					name = opr.GetChildContent("operation-name");
					Console.WriteLine("\nName             :" + name);
					System.Collections.IList nameDetailList =
					opr.GetChildByName("operation-name-details").GetChildren();
					System.Collections.IEnumerator detailIter = 
					nameDetailList.GetEnumerator();
					while (detailIter.MoveNext())
					{
						NaElement detail = (NaElement)detailIter.Current;
						desc = detail.GetChildContent("operation-description");
						type = detail.GetChildContent("resource-type");
						synopsis = detail.GetChildContent("operation-synopsis");
						Console.WriteLine("Description      : " + desc);
						Console.WriteLine("Synopsis         : " + synopsis);
						Console.WriteLine("Resource type    : " + type);
					}
				}
				Console.WriteLine(
				"----------------------------------------------------");
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

		// This function will print the usage string of the sample code.
		static void Usage()
		{
			Console.WriteLine("\nUsage: \n rbac <dfm-server> <user> " + 
				"<password> operation-add  <oper> <oper-desc> <syp> <res-ype>");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"operation-list [<oper>]");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"operation-delete <oper>");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"role-add <role> <role-desc>");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"role-list [<role>]");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"role-delete <role>");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"role-capability-add <role> <oper> <res-type> <res-name> ");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"role-capability-delete <role> <oper> <res-type> <res-name>");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"admin-list [<admin>]");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"admin-role-add <admin> <role>");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"admin-role-list <admin>");
			Console.WriteLine(" rbac <dfm-server> <user> <password> " + 
				"admin-role-delete <admin> <role>\n");
			Console.WriteLine(" <dfm-server>      -- Name/IP Address " + 
				"of the DFM Server ");
			Console.WriteLine(" <user>            -- DFM Server user name");
			Console.WriteLine(" <password>        -- DFM Server password ");
			Console.WriteLine(" <oper>            -- Name of the operation." +				
                " For example: \"DFM.SRM.Read\"");
			Console.WriteLine(" <oper-desc>       -- operation description");
			Console.WriteLine(" <role>            -- role name or id");
			Console.WriteLine(" <role-desc>       - role description");
			Console.WriteLine(" <syp>             -- operation synopsis");
			Console.WriteLine(" <res-type>        -- resource type");
			Console.WriteLine(" <res-name>        -- name of the resource");
			Console.WriteLine(" <admin>           -- admin name or id");
			Console.WriteLine(" Possible resource types are: dataset, filer\n");
			Environment.Exit(1);
		}
	}
}
