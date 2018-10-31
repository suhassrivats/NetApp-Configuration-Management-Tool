//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// snapman.cs                                                 //
//                                                            //
// Application which uses ONTAPI APIs to get snapshot lists   //
// and schedules, and take, rename and delete snapshots.      //
//                                                            //
// Copyright 2008 NetApp. All rights reserved. Specifications //
// subject to change without notice.                          // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
//                                                            //
// See Usage() for command-line syntax                        //
//                                                            //
//============================================================//
using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace snapman
{
    class SnapMan
    {
        static void Usage(string[] args)
        {
           	Console.WriteLine( 
		        "Usage: snapman -g <filer> <user> <pw> <vol> \n" + 
		        "               -l <filer> <user> <pw> <vol> \n" + 
		        "               -c <filer> <user> <pw> <vol> <snapshotname> \n" + 
		        "               -r <filer> <user> <pw> <vol> <oldsnapshotname> <newname> \n" + 
		        "               -d <filer> <user> <pw> <vol> <snapshotname> \n\n");
    	    Console.WriteLine("E.g. snapman -l filer1 root 6a55w0r9 vol0 \n\n");
            Console.WriteLine(
		        "Use -g to get the snapshot schedule\n" + 
		        "    -l to list snapshot info \n" + 
		        "    -c to create a snapshot \n" + 
		        "    -r to rename one \n" + 
		        "    -d to delete one \n");

        	System.Environment.Exit(-1);
        }
        static void CreateSnapshot(String[] args)
        {
            NaServer s;
            string filer = args[1];
            string user = args[2];
            string pwd = args[3];
            string vol = args[4];
            string ssname = args[5];
            NaElement xi, xo;

            try
            {
                s = new NaServer(filer, 1, 0);
                s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
                s.TransportType = NaServer.TRANSPORT_TYPE.HTTP;
                s.SetAdminUser(user, pwd);

                xi = new NaElement("snapshot-create");
                if (args.Length == 6)
                {
                    xi.AddNewChild("volume", vol);
                    xi.AddNewChild("snapshot", ssname);
                }
                else
                {
                    Console.Error.WriteLine("Invalid number of arguments");
                    Usage(args);
                    System.Environment.Exit(-1);
                }

                xo = s.InvokeElem(xi);
                //
                // print it out
                //
                Console.WriteLine("Snapshot " + ssname + " created for volume " + vol + " on filer " + filer);
            }
            catch (NaException e)
            {
                Console.Error.WriteLine("ERROR: " + e.Message);
            }
        }


        static void DeleteSnapshot(String[] args)
        {
            try
            {
                NaServer s;
                string filer = args[1];
                string user = args[2];
                string pwd = args[3];
                string vol = args[4];
                string ssname = args[5];
                NaElement xi, xo;

                s = new NaServer(filer, 1, 0);
                s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
                s.TransportType = NaServer.TRANSPORT_TYPE.HTTP;
                s.SetAdminUser(user, pwd);

                xi = new NaElement("snapshot-delete");
                xi.AddNewChild("volume", vol);
                xi.AddNewChild("snapshot", ssname);

                xo = s.InvokeElem(xi);
                //
                // print it out
                //
                Console.WriteLine("Snapshot " + ssname + " deleted from volume " + vol + " on filer " + filer);
            }
            catch (IndexOutOfRangeException e)
            {
                Console.Error.WriteLine("Invalid number of arguments");
                Usage(args);
                Console.Error.WriteLine(e.Message);
                System.Environment.Exit(-1);
            }
            catch (NaException e)
            {
                Console.Error.WriteLine("ERROR: " + e.Message);
            }
        }


        static void RenameSnapshot(String[] args)
        {
            try
            {
                NaServer s;
                string filer = args[1];
                string user = args[2];
                string pwd = args[3];
                string vol = args[4];
                string ssnameOld = args[5];
                string ssnameNew = args[6];
                NaElement xi, xo;

                s = new NaServer(filer, 1, 0);
                s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
                s.TransportType = NaServer.TRANSPORT_TYPE.HTTP;
                s.SetAdminUser(user, pwd);

                xi = new NaElement("snapshot-rename");
                if (args.Length == 7)
                {
                    xi.AddNewChild("volume", vol);
                    xi.AddNewChild("current-name", ssnameOld);
                    xi.AddNewChild("new-name", ssnameNew);
                }
                else
                {
                    Console.Error.WriteLine("Invalid number of arguments");
                    Usage(args);
                    System.Environment.Exit(-1);
                }

                xo = s.InvokeElem(xi);
                //
                // print it out
                //
                Console.WriteLine("Snapshot " + ssnameOld + " renamed to " + 
                                        ssnameNew + " for volume " + vol + " on filer " + filer);
            }
            catch (IndexOutOfRangeException e)
            {
                Console.Error.WriteLine("ERROR:" + e.Message);
                Usage(args);
                System.Environment.Exit(-1);
            }
            catch (NaException e)
            {
                Console.Error.WriteLine("ERROR: " + e.Message);
            }
        }


        static void ListInfo(String[] args)
        {
            NaServer s;
            string filer = args[1];
            string user = args[2];
            string pwd = args[3];
            string vol = args[4];

            NaElement xi, xo;
            //
            // get the schedule
            //
            try
            {
                s = new NaServer(filer, 1, 0);
                s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
                s.TransportType = NaServer.TRANSPORT_TYPE.HTTP;
                s.SetAdminUser(user, pwd);

                xi = new NaElement("snapshot-list-info");
                xi.AddNewChild("volume", vol);
                xo = s.InvokeElem(xi);

                System.Collections.IList snapshots = xo.GetChildByName("snapshots").GetChildren();
                System.Collections.IEnumerator snapiter = snapshots.GetEnumerator();
                while (snapiter.MoveNext())
                {
                    NaElement snapshot = (NaElement)snapiter.Current;
                    Console.WriteLine("SNAPSHOT:");
                    int accesstime = snapshot.GetChildIntValue("access-time",0);
                    DateTime datetime = new DateTime(1970,1,1,0,0,0).AddSeconds(accesstime);
                    Console.WriteLine("   NAME \t\t= " + snapshot.GetChildContent("name"));
                    Console.WriteLine("   ACCESS TIME (GMT) \t= " + datetime);
                    Console.WriteLine("   BUSY \t\t= " + snapshot.GetChildContent("busy"));
                    Console.WriteLine("   TOTAL (of 1024B) \t= " + snapshot.GetChildContent("total"));
                    Console.WriteLine("   CUMULATIVE TOTAL (of 1024B) = " + snapshot.GetChildContent("cumulative-total"));
                    Console.WriteLine("   DEPENDENCY \t\t= " + snapshot.GetChildContent("dependency"));
                }
            }
            catch (NaAuthException e)
            {
                Console.Error.WriteLine("Authentication Error : " + e.Message);
            }
            catch (NaApiFailedException e)
            {
                Console.Error.WriteLine("API Failed : " + e.Message );
            }

        }


        static void GetSchedule(String[] args)
        {
            NaServer s;
            string filer = args[1];
            string user = args[2];
            string pwd = args[3];
            string vol = args[4];
            
            NaElement xi, xo;
            //
            // get the schedule
            //
            try
            {
                s = new NaServer(filer, 1, 0);
                s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
                s.TransportType = NaServer.TRANSPORT_TYPE.HTTP;
                s.SetAdminUser(user, pwd);

                xi = new NaElement("snapshot-get-schedule");
                if (args.Length == 5)
                {
                    xi.AddNewChild("volume", vol);
                }
                else 
                {
                    Console.Error.WriteLine("Invalid number of arguments");
                    Usage(args);
                    System.Environment.Exit(-1);
                }

                xo = s.InvokeElem(xi);
                //
                // print it out
                //
                Console.WriteLine("Snapshot schedule for volume "+ vol +  " on filer " + filer + ":");
                Console.WriteLine("-----------------------------------------------------------------");
                Console.WriteLine("Snapshots are taken on minutes [" + 
                            xo.GetChildIntValue("which-minutes", 0) + "] of each hour (" +
                            xo.GetChildContent("minutes") + " kept)" );
                Console.WriteLine("Snapshots are taken on hours [" +
                            xo.GetChildContent("which-hours") + "] of each day (" +
                            xo.GetChildContent("hours") + " kept)\n");
                Console.WriteLine(xo.GetChildContent("days") + " nightly snapshots are kept\n");
                Console.WriteLine(xo.GetChildContent("weeks") + " weekly snapshots are kept\n");
                Console.WriteLine("\n");
            }
            catch (NaException e)
            {
                Console.WriteLine("ERROR: " + e.Message);
            }
            
        }
        static void Main(string[] args)
        {
            if (args.Length < 5) 
		        Usage(args);

            Console.WriteLine("|--------------------------------------|");
            Console.WriteLine("| Program to Demo use of Snapshot APIs |");
            Console.WriteLine("|--------------------------------------|");
                
            switch (args[0]) {
                case "-g":
                    GetSchedule(args);
                    break;
                case "-c":
                    CreateSnapshot(args);
                    break;
                case "-r":
                    RenameSnapshot(args);
                    break;
                case "-d":
                    DeleteSnapshot(args);
                    break;
                case "-l":
                    ListInfo(args);
                    break;
                default:
                    Usage(args);
                    break;
            }

        }
    }
}
