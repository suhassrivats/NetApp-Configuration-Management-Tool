//===============================================================//
//                                                               //
// $ID$                                                          //
//                                                               //
// dfm_schedule.cs                                               //
//                                                               //
// Copyright (c) 2009 NetApp, Inc. All rights reserved.          //
// Specifications subject to change without notice.              //
//                                                               //
// Sample code to demonstrate how to manage dfm schedule         //
// on a DFM server                                               //
// You can create, list and delete dfm schedules                 //
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

namespace NetApp.ManageabilitySDK.Samples.Basic.DfmSchedule
{
	class DfmSchedule
	{
		private static NaServer server;
		private static String[] Args;
		static void Usage()
		{
			Console.WriteLine("" +
"Usage:\n"+
"dfm_schedule <dfmserver> <user> <password> list [ <schedule> ]\n" +
"\n" +
"dfm_schedule <dfmserver> <user> <password> delete <schedule>\n" +
"\n" +
"dfm_schedule <dfmserver> <user> <password> create <schedule> daily\n" +
"[ -h <shour> -m <sminute> ]\n" +
"\n" +
"dfm_schedule <dfmserver> <user> <password> create <schedule> weekly\n" +
"[ -d <dweek>] [ -h <shour> -m <sminute> ]\n" +
"\n" +
"dfm_schedule <dfmserver> <user> <password> create <schedule> monthly\n" +
"{ [ -D <dmonth> ] | [ -d <dweek> -w <wmonth> ] } [ -h <shour> -m <sminute>]"
+ "\n" +
"\n" +
"<operation>     -- create or delete or list\n" +
"<schedule type> -- daily or weekly or monthly\n" +
"\n" +
"<dfmserver> -- Name/IP Address of the DFM server\n" +
"<user>      -- DFM server User name\n" +
"<password>  -- DFM server User Password\n" +
"<schedule>  -- Schedule name\n" +
"<dmonth>    -- Day of the month. Range: [1..31]\n" +
"<dweek>     -- Day of week for the schedule. Range: [0..6] (0 = \"Sun\")\n" +
"<shour>     -- Start hour of schedule. Range: [0..23]\n" +
"<sminute>   -- Start minute of schedule. Range: [0..59]\n" +
"<wmonth>    -- A value of 5 indicates the last week of the month. Range: "
+ "[1..5]\n" +
"\n" +
"Note : Either <dweek> and <wmonth> should to be set, or <dmonth>"
+ " should be set");
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
			//operations
			if ((dfmop.Equals("list") && arglen < 4) 
				|| (dfmop.Equals("delete") && arglen != 5) 
				|| (dfmop.Equals("create") && arglen < 6))
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
			String startHour = null;
			String startMinute = null;
			String dayOfWeek = null;
			String dayOfMonth = null;
			String weekOfMonth = null;
			// Getting the schedule name and type
			String dfmSchedule = Args[4];
			String scheduleType = Args[5];

			// Checking if the type selected is valid
			if((!scheduleType.Equals("daily")) 
			&& (!scheduleType.Equals("weekly"))
			&& (!scheduleType.Equals("monthly"))) Usage();

			// parsing optional parameters
			int i=6;
			while( i < Args.Length) {
				if(Args[i].Equals("-h")) {
					startHour = Args[++i]; ++i ;
				} else if(Args[i].Equals("-m")) {
					startMinute = Args[++i]; ++i ;
				} else if(Args[i].Equals("-d")) {
					dayOfWeek = Args[++i]; ++i ;
				} else if(Args[i].Equals("-D")) {
					dayOfMonth = Args[++i]; ++i ;
				} else if(Args[i].Equals("-w")) {
					weekOfMonth = Args[++i]; ++i ;
				} else {
					Usage();
				}

			}

			try {
				// creating the input for api execution
				// creating a dfm-schedule-create element and adding child elem
				NaElement input = new NaElement("dfm-schedule-create");
				NaElement schedule = new NaElement("schedule-content-info");
				schedule.AddNewChild("schedule-name",dfmSchedule);
				schedule.AddNewChild("schedule-type",scheduleType);
				schedule.AddNewChild("schedule-category","dfm_schedule");

				// creating a daily-list element
				if(scheduleType.Equals("daily") && (startHour != null 
				|| startMinute != null)) {
					NaElement daily = new NaElement("daily-list");
					NaElement dailyInfo = new NaElement("daily-info");
					if(startHour != null) dailyInfo.AddNewChild("start-hour",startHour);
					if(startMinute != null) dailyInfo.AddNewChild("start-minute",startMinute);
					daily.AddChildElement(dailyInfo);
					// appending daily list to schedule
					schedule.AddChildElement(daily);
				}


				// creating a weekly-list element
				if(scheduleType.Equals("weekly") &&
						(startHour != null || startMinute != null 
						|| dayOfWeek != null )) {
					NaElement weekly = new NaElement("weekly-list");
					NaElement weeklyInfo = new NaElement("weekly-info");
					if(startHour != null)
						weeklyInfo.AddNewChild("start-hour",startHour);
					if(startMinute != null)
						weeklyInfo.AddNewChild("start-minute",startMinute);
					if(dayOfWeek != null)
						weeklyInfo.AddNewChild("day-of-week",dayOfWeek);
					weekly.AddChildElement(weeklyInfo);
					// appending weekly list to schedule
					schedule.AddChildElement(weekly);
				}

				// creating 2 monthly-list element
				if(scheduleType.Equals("monthly") && (startHour != null 
				|| startMinute != null || dayOfWeek != null 
				|| dayOfMonth != null || weekOfMonth != null)) {
					NaElement monthly = new NaElement("monthly-list");
					NaElement monthlyInfo = new NaElement("monthly-info");
					if(startHour != null)
						monthlyInfo.AddNewChild("start-hour",startHour);
					if(startMinute != null)
						monthlyInfo.AddNewChild("start-minute",startMinute);
					if(dayOfMonth != null)
						monthlyInfo.AddNewChild("day-of-month",dayOfMonth);
					if(dayOfWeek != null)
						monthlyInfo.AddNewChild("day-of-week",dayOfWeek);
					if(weekOfMonth != null)
						monthlyInfo.AddNewChild("week-of-month",weekOfMonth);
					monthly.AddChildElement(monthlyInfo);
					// appending monthly list to schedule
					schedule.AddChildElement(monthly);
				}

				// appending schedule to main input
				input.AddChildElement(schedule);

				// invoking the api && printing the xml ouput
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nSchedule creation "
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
			String dfmSchedule = null;

			try {
				// creating a dfm schedule start element
				NaElement input = 
				new NaElement("dfm-schedule-list-info-iter-start");
				input.AddNewChild("schedule-category","dfm_schedule");
				if(Args.Length > 4) {
					dfmSchedule = Args[4];
					input.AddNewChild("schedule-name-or-id",dfmSchedule);
				}

				// invoke the api && capturing the records && tag values
				NaElement output = server.InvokeElem(input);


				// Extracting the record && tag values && printing them
				String records = output.GetChildContent("records");

				if (records.Equals("0"))
					Console.WriteLine("\nNo schedules to display");


				String tag = output.GetChildContent("tag");



				// Extracting records one at a time
				input = new NaElement("dfm-schedule-list-info-iter-next");
				input.AddNewChild("maximum",records);
				input.AddNewChild("tag",tag);
				NaElement record = server.InvokeElem(input);

				// Navigating to the schedule-content-list child element
				NaElement stat = record.GetChildByName("schedule-content-list");

				// Navigating to the schedule-info child element
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
					// extracting the schedule details && printing it
					Console.WriteLine(
					"----------------------------------------------------");
					Console.WriteLine("Schedule Name : "
					+ info.GetChildContent("schedule-name"));

					Console.WriteLine("Schedule Id          : " +
						   info.GetChildContent("schedule-id"));

					Console.WriteLine("Schedule Description : " +
						info.GetChildContent("schedule-description"));

					Console.WriteLine(
					"----------------------------------------------------");

					// printing details if only one schedule is selected
					if(dfmSchedule != null) {


						Console.WriteLine("\nSchedule Type        : " +
							info.GetChildContent("schedule-type"));

						Console.WriteLine("Schedule Category    : " +
							info.GetChildContent("schedule-category"));


						String type = info.GetChildContent("schedule-type");

						NaElement typeList = 
						info.GetChildByName(type + "-list");
						if (typeList != null)
						{
							NaElement typeInfo = 
							typeList.GetChildByName(type + "-info");

							if (type.Equals("daily"))
							{

								Console.WriteLine("Item Id              : " +
									typeInfo.GetChildContent("item-id"));

								value = typeInfo.GetChildContent("start-hour");
								Console.Write("Start Hour           : ");
								if (value != null)
									Console.Write(value);

								value = 
								typeInfo.GetChildContent("start-minute");
								Console.Write("\nStart Minute         : ");
								if (value != null)
									Console.WriteLine(value);

							}
							else if (type.Equals("weekly"))
							{
								Console.WriteLine("Item Id              : " +
									typeInfo.GetChildContent("item-id"));

								value = typeInfo.GetChildContent("start-hour");
								Console.Write("Start Hour           : ");
								if (value != null)
									Console.Write(value);

								value = 
								typeInfo.GetChildContent("start-minute");
								Console.Write("\nStart Minute         : ");
								if (value != null)
									Console.Write(value);

								value = typeInfo.GetChildContent("day-of-week");
								Console.Write("\nDay Of Week          : ");
								if (value != null)
									Console.WriteLine(value);

							}
							else if (type.Equals("monthly"))
							{

								Console.WriteLine("Item Id              : " +
									typeInfo.GetChildContent("item-id"));

								value = typeInfo.GetChildContent("start-hour");
								Console.Write("Start Hour           : ");
								if (value != null)
									Console.Write(value);

								value = 
								typeInfo.GetChildContent("start-minute");
								Console.Write("\nStart Minute         : ");
								if (value != null)
									Console.Write(value);

								value = typeInfo.GetChildContent("day-of-week");
								Console.Write("\nDay Of Week          : ");
								if (value != null)
									Console.Write(value);

								value = 
								typeInfo.GetChildContent("week-of-month");
								Console.Write("\nWeek Of Month        : ");
								if (value != null)
									Console.Write(value);

								value = 
								typeInfo.GetChildContent("day-of-month");
								Console.Write("\nDay Of Month         : ");
								if (value != null)
									Console.WriteLine(value);
							}
						}
					}
				}

			// invoking the iter-end zapi
			input = new NaElement("dfm-schedule-list-info-iter-end");
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
			String dfmSchedule = Args[4];

			try {
			 // invoking the api && printing the xml ouput
				NaElement input = new NaElement("dfm-schedule-destroy");
				input.AddNewChild("schedule-name-or-id",dfmSchedule);
				input.AddNewChild("schedule-category","dfm_schedule");
				NaElement output = server.InvokeElem(input);

				Console.WriteLine("\nSchedule deletion "
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
	}
}
