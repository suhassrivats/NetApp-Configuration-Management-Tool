//============================================================//
//                                                            //
//                                                            //
// vfiler_tunnel.cs                                           //
//                                                            //
// This sample code demonstrates how to execute ONTAPI APIs   //
// on a vfiler through the physical filer                     //
//                                                            //
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
//============================================================//
using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace vfiler_tunnel
{
    class VfilerTunnel
    {
        public static void usage()
        {
			Console.WriteLine("\nUsage:vfiler-tunnel {options} <vfiler-name> <filer> <user> "
					+ "<password> <ONTAPI-name> [key value] ...");
				Console.WriteLine("\nOptions:");
				Console.WriteLine("\n -s Use SSL\n");
	        	System.Environment.Exit(1);
	    }

        static void Main(string[] args)
        {
            NaElement xi;
		    NaElement xo;
		    NaServer  s;
		    int	  index;
		    String	  options;
		    int	  dos1=0;

		    if ( args.Length < 5 ) {
			    usage();
		    }

		    index=args[0].IndexOf('-');
		    if(index==0 && args[0][index]== '-'){
			    options=args[0].Substring(index+1);
			    if(options.Equals("s") && args.Length > 5){
				    dos1=1;
			    }else {
				    usage();
			    }
		    }

            Console.WriteLine("|------------------------------------|");
            Console.WriteLine("| Program to Demo VFILER Tunnel APIs |");
            Console.WriteLine("|------------------------------------|");

		    try {
			    if(dos1==1)
                {
				    //Initialize connection to server, and
				    //request version 1.7 of the API set for vfiler-tunneling
				    //
				    s = new NaServer(args[2],1,7);
                    s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
				    s.SetAdminUser(args[3], args[4]);
				    s.TransportType = NaServer.TRANSPORT_TYPE.HTTPS;
				    s.Port = 443;
				    s.ServerType = NaServer.SERVER_TYPE.FILER;
				    s.SetVfilerTunneling(args[1]);
                    
				    //Invoke any  ONTAPI API with arguments
				    //in (key,value) pair
				    //args[0]=option,args[1]=vfiler-name,args[2]=vfiler,
				    //args[3]=user,args[4] = passwd, args[5]=Ontapi API,
				    //args[6] onwards arguments in (key,value)
				    //pair
				    //
				    xi = new NaElement(args[5]);

				    try {
					    if(args.Length > 6){
						    for(int index1=6;index1<
							      args.Length;index1++){
					 		    xi.AddNewChild(
							      args[index1],
							      args[index1+1]);
							    index1++;
						    }
					    }
				    }
				    catch(IndexOutOfRangeException e) {
                        Console.Out.WriteLine("Mismatch in arguments passed "
					  	    + "(in (key,value) Pair) to Ontapi API" );
					    throw new NaApiFailedException(e.Message);
                    }
			    }
				else 
                {
				    //Initialize connection to server, and
				    //request version 1.7 of the API set for vfiler-tunneling
				    //
				    s = new NaServer(args[1],1,7);
				    s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
				    s.SetAdminUser(args[2], args[3]);
				    s.SetVfilerTunneling(args[0]);

				    //Invoke any  ONTAPI API with arguments
				    //in (key,value) pair
				    //args[0]=filer,args[1]=user,args[2]=passwd
				    //args[3]=Ontapi API,args[4] onward arguments
				    // in (key,value) pair
				    //
				    xi = new NaElement(args[4]);
				    try {
					    if(args.Length > 5){
						    for(int index2=5;index2<
							      args.Length;index2++){
					 		    xi.AddNewChild(
							      args[index2],
							      args[index2+1]);
							    index2++;
						    }
					    }
				    }
				    catch(IndexOutOfRangeException e) {
                        Console.Error.WriteLine("Mismatch in arguments passed "
                            + "(in (key,value) Pair) to Ontapi API");
					    throw new NaApiFailedException(e.Message);
				    }
				}
			    xo = s.InvokeElem(xi);
		 	    Console.WriteLine(xo.ToPrettyString(""));
		    }
		    catch(NaApiFailedException e) {
                Console.Error.WriteLine("API Failed Exception : " + e.Message);
			    System.Environment.Exit(1);
		    }
		    catch (Exception e) {
                Console.Error.WriteLine("Exception: " + e.Message);
			    System.Environment.Exit(1);
		    }
	    }
    }
}
