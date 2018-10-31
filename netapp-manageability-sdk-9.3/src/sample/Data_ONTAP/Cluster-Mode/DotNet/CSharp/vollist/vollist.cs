//============================================================//
//                                                            //
//                                                            //
// vollist.cs                                                 //
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

namespace VolList
{
    class VolList
    {
        static NaServer server;
        static String [] args;

        public static void PrintUsageAndExit()
        {
            Console.WriteLine("\nUsage: \n");
            Console.WriteLine("vollist <cluster/vserver> <user> <passwd> [-v <vserver-name>]");
            Console.WriteLine("<cluster>             -- IP address of the cluster");
            Console.WriteLine("<vserver>             -- IP address of the vserver");
            Console.WriteLine("<user>                -- User name");
            Console.WriteLine("<passwd>              -- Password");
            Console.WriteLine("<vserver-name>        -- Name of the vserver \n");
            Console.WriteLine("Note: ");
            Console.WriteLine(" -v switch is required when you want to tunnel the command to a vserver using cluster interface");
            Environment.Exit(-1);
        }

        public static void ListVolumes() 
        {
            NaElement xi, xo;
            String tag = "";
            String vserverName, volName, aggrName, volType, volState, size, availSize;

            while (tag != null) {
                if (args.Length > 3) {
                    if (args.Length < 5 || !args[3].Equals("-v")) {
                        PrintUsageAndExit();
                    }
                    server.Vserver = args[4];
                }
                xi = new NaElement("volume-get-iter");
                if (!tag.Equals("")) {
                    xi.AddNewChild("tag", tag);
                }
                xo = server.InvokeElem(xi);
                if (xo.GetChildIntValue("num-records", 0) == 0) {
                    Console.WriteLine("No volume(s) information available\n");
                    return;
                }
                tag = xo.GetChildContent("next-tag");
                List <NaElement> volList = xo.GetChildByName("attributes-list").GetChildren();
                Console.WriteLine("----------------------------------------------------");
                foreach (NaElement volInfo in volList) {
                    vserverName = volName = aggrName = volType = volState = size = availSize = "";
                    NaElement volIdAttrs = volInfo.GetChildByName("volume-id-attributes");
                    if (volIdAttrs != null)
                    {
                        vserverName = volIdAttrs.GetChildContent("owning-vserver-name");
                        volName = volIdAttrs.GetChildContent("name");
                        aggrName = volIdAttrs.GetChildContent("containing-aggregate-name");
                        volType = volIdAttrs.GetChildContent("type");
                    }
                    Console.WriteLine("Vserver Name            : " + (vserverName != null ? vserverName : ""));
                    Console.WriteLine("Volume Name             : " + (volName != null ? volName : ""));
                    Console.WriteLine("Aggregate Name          : " + (aggrName != null ? aggrName : ""));
                    Console.WriteLine("Volume type             : " + (volType != null ? volType : ""));
                    NaElement volStateAttrs = volInfo.GetChildByName("volume-state-attributes");
                    if (volStateAttrs != null)
                    {
                        volState = volStateAttrs.GetChildContent("state");
                    }
                    Console.WriteLine("Volume state            : " + (volState != null ? volState : ""));
                    NaElement volSizeAttrs = volInfo.GetChildByName("volume-space-attributes");
                    if (volSizeAttrs != null)
                    {
                        size = volSizeAttrs.GetChildContent("size");
                        availSize = volSizeAttrs.GetChildContent("size-available");
                    }
                    Console.WriteLine("Size (bytes)            : " + (size != null ? size : ""));
                    Console.WriteLine("Available Size (bytes)  : " + (availSize != null ? availSize : ""));
                    Console.WriteLine("----------------------------------------------------");
                }
            }
        }

        public static void Main(String[] vargs)
        {
            args = vargs;
            int index = 0;

            if (args.Length < 3)
            {
                PrintUsageAndExit();
            }
            try
            {
                server = new NaServer(args[index++], 1, 15);
                server.SetAdminUser(args[index++], args[index++]);
                ListVolumes();
            }
            catch (NaException e)
            {
                //Print the error message
                Console.Error.WriteLine(e.Message);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
            }
        }
    }
}
