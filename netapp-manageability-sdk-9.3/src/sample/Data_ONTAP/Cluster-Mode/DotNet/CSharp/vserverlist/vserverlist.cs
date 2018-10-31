//============================================================//
//                                                            //
//                                                            //
// vserverlist.cs                                             //
//                                                            //
// Sample code to list the volumes available in the cluster.  //
//                                                            //
// This sample code is supported from Cluster-Mode            //
// Data ONTAP 8.1 onwards.                                    //
//                                                            //
// Copyright 2011 NetApp, Inc. All rights reserved.           //
// Specifications subject to change without notice.           //
//                                                            //
//============================================================//

using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace VserverList
{
    class VserverList
    {
        static NaServer server;
        static String [] args;

        public static void PrintUsageAndExit() {
            Console.WriteLine("\nUsage: \n");
            Console.WriteLine("vserverlist <cluster/vserver> <user> <passwd> [-v <vserver-name>]");
            Console.WriteLine("<cluster>             -- IP address of the cluster");
            Console.WriteLine("<vserver>             -- IP address of the vserver");
            Console.WriteLine("<user>                -- User name");
            Console.WriteLine("<passwd>              -- Password");
            Console.WriteLine("<vserver-name>        -- Name of the vserver \n");
            Console.WriteLine("Note: ");
            Console.WriteLine(" -v switch is required when you want to tunnel the command to a vserver using cluster interface");
            Environment.Exit(-1);
        }

        public static void ListVservers()
        {
            NaElement xi, xo;
            String rootVol, rootVolAggr, secStyle, state;
            String tag = "";

            while (tag != null)
            {
                xi = new NaElement("vserver-get-iter");
                if (args.Length > 3)
                {
                    if (args.Length < 5 || !args[3].Equals("-v"))
                    {
                        PrintUsageAndExit();
                    }
                    server.Vserver = args[4];
                }
                if (!tag.Equals(""))
                {
                    xi.AddNewChild("tag", tag);
                }
                xo = server.InvokeElem(xi);
                if (xo.GetChildIntValue("num-records", 0) == 0)
                {
                    Console.WriteLine("No vserver(s) information available\n");
                    return;
                }
                tag = xo.GetChildContent("next-tag");
                List <NaElement> vserverList = xo.GetChildByName("attributes-list").GetChildren();
                Console.WriteLine("----------------------------------------------------");
                foreach (NaElement vserverInfo in vserverList)
                {
                    Console.WriteLine("Name                    : " + vserverInfo.GetChildContent("vserver-name"));
                    Console.WriteLine("Type                    : " + vserverInfo.GetChildContent("vserver-type"));
                    rootVolAggr = vserverInfo.GetChildContent("root-volume-aggregate");
                    rootVol = vserverInfo.GetChildContent("root-volume");
                    secStyle = vserverInfo.GetChildContent("root-volume-security-style");
                    state = vserverInfo.GetChildContent("state");
                    Console.WriteLine("Root volume aggregate   : " + (rootVolAggr != null ? rootVolAggr : ""));
                    Console.WriteLine("Root volume             : " + (rootVol != null ? rootVol : ""));
                    Console.WriteLine("Root volume sec style   : " + (secStyle != null ? secStyle : ""));
                    Console.WriteLine("UUID                    : " + vserverInfo.GetChildContent("uuid"));
                    Console.WriteLine("State                   : " + (state != null ? state : ""));
                    NaElement allowedProtocols = null;
                    Console.Write("Allowed protocols       : ");
                    if ((allowedProtocols = vserverInfo.GetChildByName("allowed-protocols")) != null)
                    {
                        List <NaElement> allowedProtocolsList = allowedProtocols.GetChildren();
                        foreach (NaElement protocol in allowedProtocolsList)
                        {
                            Console.Write(protocol.GetContent() + " ");
                        }
                    }
                    Console.Write("\nName server switch      : ");
                    NaElement nameServerSwitch = null;
                    if ((nameServerSwitch = vserverInfo.GetChildByName("name-server-switch")) != null)
                    {
                        List <NaElement> nsSwitchList = nameServerSwitch.GetChildren();
                        foreach (NaElement nsSwitch in  nsSwitchList)
                        {
                            Console.Write(nsSwitch.GetContent() + " ");
                        }
                    }
                    Console.WriteLine("\n----------------------------------------------------");
                }
            }
        }

        public static void Main(String[] vargs)
        {
            int index = 0;
            args = vargs;

            if (args.Length < 3)
            {
                PrintUsageAndExit();
            }
            try
            {
                server = new NaServer(args[index++], 1, 15);
                server.SetAdminUser(args[index++], args[index++]);
                ListVservers();
            }
            catch (NaException e)
            {
                Console.WriteLine(e.Message);
            }
            catch (Exception e) {
                Console.WriteLine(e.Message);
            }
        }
    }
}
