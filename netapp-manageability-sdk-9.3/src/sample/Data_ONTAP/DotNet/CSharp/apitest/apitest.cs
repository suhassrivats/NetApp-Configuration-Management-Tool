//============================================================//
//                                                            //
//                                                            //
// apitest.cs                                                 //
//                                                            //
// Exploratory application for ONTAPI APIs                    //
// It lets you call any ONTAPI API with named arguments       //
//    (essentially a command-line version of the zexplore     //
//     utility)                                               //
//                                                            //
// Copyright 2002-2010 NetApp, Inc. All rights                //
// reserved. Specifications subject to change without notice. // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
// tab size = 4                                               //
//                                                            //
//============================================================//

using System;
using System.Collections.Generic;
using System.Text;
using NetApp.Manage;

namespace Netapp.Utility
{
    class ApiTest
    {
        private static void Usage()
        {
            Console.WriteLine("\nUsage:\n\t apitest [options] <host> <user> "
                + "<password> <ONTAPI-name> [<param-name> <arg> ...]\n");
            Console.WriteLine("Options:\n");
            Console.WriteLine("\t -t {type} \t Server type(type = filer, dfm, ocum, agent)\n");
            Console.WriteLine("\t -v {vfiler name | vserver name}  For vfiler-tunneling or vserver-tunneling \n");
            Console.WriteLine("\t -r \t Use RPC transport\n");
            Console.WriteLine("\t -n \t Use HTTP\n");
            Console.WriteLine("\t -p {port} \t Override port to use\n");
            Console.WriteLine("\t -c {timeout} \t Connection timeout value in seconds\n");
            Console.WriteLine("\t -o {originator_id} \t Pass Originator Id\n");
            Console.WriteLine("\t -C {cert-file}    Location of the client certificate file\n");
            Console.WriteLine("\t -P {cert-passwd}  Password to access the certificate file\n");
            Console.WriteLine("\t -T {cert-store-name} Client certificate store name. The default is 'My' store\n");
            Console.WriteLine("\t -L {cert-store-loc}  Client certificate store location. The default is 'CurrentUser'\n");
            Console.WriteLine("\t -N {cert-name} Subject name of the client certificate in the certificate store\n");
            Console.WriteLine("\t -S \t Enable server certificate verification\n");
            Console.WriteLine("\t -H \t Enable hostname verification\n");
            Console.WriteLine("\t -i \t API specified as XML input, on the command line\n");
            Console.WriteLine("\t -I \t API specified as XML input, on standard input\n");
            Console.WriteLine("\t -x \t Show the XML input and output\n");
            Console.WriteLine("\t -X \t Show the raw XML input and output\n");
            Console.WriteLine("\t -h \t Use Host equiv authentication mechanism\n");
            Console.WriteLine("\nNote:");
            Console.WriteLine("\n        Use server type 'dfm' (-t dfm) for OnCommand Unified Manager server version 5.2 or earlier.");
            Console.WriteLine("\n        Use server type 'ocum' (-t ocum) for OnCommand Unified Manager server version 6.0 or later.\n");
            Console.WriteLine("\n        By default username and password shall be used for client authentication.");
            Console.WriteLine("        Specify either -C, -P or -S, -L, -N options for using Certificate Based Authentication (CBA).");
            Console.WriteLine("\n        Server certificate and Hostname verification is disabled by default for CBA.");
            Console.WriteLine("\n        Do not provide username and password for -h, -r or CBA options.");
            Console.WriteLine("\n        The username or UID of the user administering the storage systems can be passed");
            Console.WriteLine("        to ONTAP as originator-id for audit logging.\n");
            Console.WriteLine("Examples:\n");
            Console.WriteLine("\t apitest sweetpea root tryme "
                + "system-get-version");
            Console.WriteLine("\n\t apitest amana root meat quota-report volume vol0\n");
            Console.WriteLine("\n\t apitest -t dfm -C clientcert.pfx -P mypasswd amana dfm-about\n");
            Console.WriteLine("\n\t apitest -t dfm -T My -L CurrentUser -N ram amana dfm-about\n");
            Environment.Exit(1);
        }

        private static void GetXMLInput(int inputXML,ref string[] args,ref int index)
        {
            String readXML = "";
            
            if (inputXML == 1)
            {
                if (args.Length == index + 1)
                {
                    Console.WriteLine("API not specified");
                    Usage();
                }
                for (int cnt = index + 1; cnt < args.Length; cnt++)
                {
                    readXML = readXML + args[cnt];
                }
            }
            else
            {
                String curLine = "";
                Console.WriteLine("Enter the input XML:\n");
                while ((curLine = Console.ReadLine()) != null)
                {
                    readXML += curLine;
                }
            }

            args = readXML.Split(new Char[] { ' ', '\n','\t','\r' });

            readXML = "";
            for (int cnt = 0; cnt < args.Length; cnt++)
            {
                if (!(args[cnt].Contains("\t") || args[cnt].Contains(" ")))
                {
                    readXML = readXML + args[cnt];
                }
            }
            args = readXML.Split(new Char[] { '\t', '\n' });
            index = -1;
        }

        static void Main(string[] args)
        {
            NaServer s;
            NaElement xi = null;
            NaElement xo;
            NaServer.TRANSPORT_TYPE transportType = NaServer.TRANSPORT_TYPE.HTTPS;
            NaServer.SERVER_TYPE serverType = NaServer.SERVER_TYPE.FILER;
            NaServer.AUTH_STYLE authStyle = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
            String vfiler = null;
            String originatorId = null;
            String type;
            int index = 0;
            int showXML = 0;
            int inputXML = 0;
            int port = -1;
            int timeOut = -1;
            Boolean status = true;
            Boolean useRPC = false;
            Boolean useHostsEquiv = false;
            Boolean useCBA = false;
            Boolean verifyServerCert = false;
            Boolean verifyHostname = false;
            String certFile = null;
            String certPasswd = null;
            NaServer.CERT_STORE_NAME storeName = NaServer.CERT_STORE_NAME.MY;
            NaServer.CERT_STORE_LOCATION storeLocation = NaServer.CERT_STORE_LOCATION.CURRENT_USER;
            String certName = null;

            if (args.Length < 3)
            {
                Usage();
            }
            index = 0;

            try
            {
                while (args[index].StartsWith("-"))
                {
                    switch (args[index][1])
                    {
                        case 't':
                            type = args[index + 1];
                            if (type.Equals("dfm"))
                            {
                                serverType = NaServer.SERVER_TYPE.DFM;
                            }
                            else if (type.Equals("ocum"))
                            {
                                serverType = NaServer.SERVER_TYPE.OCUM;
                                transportType = NaServer.TRANSPORT_TYPE.HTTPS;
                            }
                            else if (type.Equals("agent"))
                            {
                                serverType = NaServer.SERVER_TYPE.AGENT;
                            }
                            else if (type.Equals("filer"))
                            {
                                serverType = NaServer.SERVER_TYPE.FILER;
                            }
                            else
                            {
                                Console.WriteLine("\nERROR: Invalid Option for Server type.");
                                Usage();
                            }
                            index = index + 2;
                            break;
                        case 'v':
                            vfiler = args[index + 1];
                            index = index + 2;
                            break;
                        case 'r':
                            authStyle = NaServer.AUTH_STYLE.RPC;
                            useRPC = true;
                            index++;
                            break;
                        case 'n':
                            transportType = NaServer.TRANSPORT_TYPE.HTTP;
                            index++;
                            break;
                        case 'p':
                            status = Int32.TryParse(args[index + 1], out port);
                            if (status == false)
                            {
                                Console.WriteLine("\nERROR: Invalid port no.");
                                Usage();
                            }
                            index = index + 2;
                            break;
                        case 'i':
                            inputXML = 1;
                            index++;
                            break;
                        case 'I':
                            inputXML = 2;
                            index++;
                            break;
                        case 'x':
                            showXML = 1;
                            index++;
                            break;
                        case 'X':
                            showXML = 2;
                            index++;
                            break;
                        case 'h':
                            authStyle = NaServer.AUTH_STYLE.HOSTSEQUIV;
                            useHostsEquiv = true;
                            index++;
                            break;
                        case 'c':
                            status = Int32.TryParse(args[index + 1], out timeOut);
                            if (status == false || timeOut <= 0)
                            {
                                Console.WriteLine("\nERROR: Invalid timeout value.");
                                Usage();
                            }
                            index = index + 2;
                            break;
                        case 'o':
                            originatorId = args[index + 1];
                            index = index + 2;
                            break;
                        case 'C':
                            useCBA = true;
                            certFile = args[index + 1];
                            index =  index + 2;
                            break;
                        case 'P':
                            useCBA = true;
                            certPasswd = args[index + 1];
                            index = index + 2;
                           break;
                        case 'T':
                            String name = args[index + 1];
                            useCBA = true;
                            switch(name)
                            {
                                case "AuthRoot": 
                                    storeName = NaServer.CERT_STORE_NAME.AUTH_ROOT;
                                    break;
                                case "CertificateAuthority":
                                    storeName = NaServer.CERT_STORE_NAME.CERTIFICATE_AUTHORITY;
                                    break;
                                case "My":
                                    storeName = NaServer.CERT_STORE_NAME.MY;
                                    break;
                                case "Root":
                                    storeName = NaServer.CERT_STORE_NAME.ROOT;
                                    break;
                                case "TrustedPeople":
                                    storeName = NaServer.CERT_STORE_NAME.TRUSTED_PEOPLE;
                                    break;
                                default:
                                    Console.WriteLine("Invalid store name: " + name);
                                    Console.WriteLine("Valid store names are: ");
                                    Console.WriteLine("My - certificate store for personal certificates");
                                    Console.WriteLine("Root - certificate store for trusted root certificate authorities");
                                    Console.WriteLine("AuthRoot - certificate store for third-party certificate authorities");
                                    Console.WriteLine("CertificateAuthority - certificate store for intermediate certificate authorities");
                                    Console.WriteLine("TrustedPeople - certificate store for directly trusted people and resources\n");
                                    Usage();
                                    break;
                            }
                            index = index + 2;
                            break;
                        case 'L':
                            String location = args[index + 1];
                            useCBA = true;
                            switch (location)
                            {
                                case "CurrentUser":
                                    storeLocation = NaServer.CERT_STORE_LOCATION.CURRENT_USER;
                                    break;
                                case "LocalMachine":
                                    storeLocation = NaServer.CERT_STORE_LOCATION.LOCAL_MACHINE;
                                    break;
                                default:
                                    Console.WriteLine("Invalid store location: " + location);
                                    Console.WriteLine("Valid store locations are: ");
                                    Console.WriteLine("CurrentUser - certificate store used by the current user");
                                    Console.WriteLine("LocalMachine - certificate store assigned to the local machine");
                                    Usage();
                                    break;
                            }
                            index = index + 2;
                            break;
                        case 'N':
                            certName = args[index + 1];
                            useCBA = true;
                            index = index + 2;
                            break;
                        case 'S':
                            verifyServerCert = true;
                            index++;
                            break;
                        case 'H':
                            verifyHostname = true;
                            index++;
                            break;
                        default:
                            Console.WriteLine("\nERROR: Invalid Option.");
                            Usage();
                            break;
                    } //switch (args[index][1]) {
                } //while (args[index].StartsWith("-")){
            }
            catch (System.IndexOutOfRangeException)
            {
                Console.WriteLine("\nERROR: Invalid Arguments.");
                Usage();
            }
            if (authStyle == NaServer.AUTH_STYLE.LOGIN_PASSWORD &&
                            args.Length < 4)
            {
                Usage();
            }

            if (useHostsEquiv == true && useRPC == true)
            {
                Console.WriteLine("\nERROR: Invalid usage of authentication style. " +
                "Do not use -r option and -h option together.\n");
                System.Environment.Exit(1);
            }
			if (useRPC == true && timeOut != -1) {
				Console.WriteLine("\nERROR: Connection timeout value cannot be set for RPC authentication style.\n");
				Environment.Exit(1);
			}
            if (verifyHostname && !verifyServerCert)
            {
                Console.WriteLine("\nERROR: Hostname verification cannot be enabled when server certificate verification is disabled.\n");
                Environment.Exit(1);
            }
            if (useCBA)
            {
                transportType = NaServer.TRANSPORT_TYPE.HTTPS;
                authStyle = NaServer.AUTH_STYLE.CERTIFICATE;
            }
            else if (authStyle == NaServer.AUTH_STYLE.LOGIN_PASSWORD)
            {
                if (index == args.Length)
                {
                    Console.WriteLine("\nERROR: Host not specified.");
                    Usage();
                }
                if ((index + 1) == args.Length)
                {
                    Console.WriteLine("\nERROR: User not specified.");
                    Usage();
                }
                else if ((index + 2) == args.Length)
                {
                    Console.WriteLine("\nERROR: Password not specified.");
                    Usage();
                }
            }

            if (port == -1)
            {
                    switch (serverType)
                    {
                        default:
                        case NaServer.SERVER_TYPE.FILER:
                            port = (transportType == NaServer.TRANSPORT_TYPE.HTTP ? 80 : 443);
                            break;
                        case NaServer.SERVER_TYPE.DFM:
                            port = (transportType == NaServer.TRANSPORT_TYPE.HTTP ? 8088 : 8488);
                            break;
                        case NaServer.SERVER_TYPE.OCUM:
                            port = 443;
                            break;
                        case NaServer.SERVER_TYPE.AGENT:
                            port = (transportType == NaServer.TRANSPORT_TYPE.HTTP ? 4092 : 4093);
                            break;
                    }
            }

            try
            {
                //1. Create an instance of NaServer object.
                //NaServer is used to connect to servers and invoke API's.
                if (vfiler != null)
                {
                    // Vfiler tunnelling requires ONTAPI version 7.1 to work 
                    s = new NaServer(args[index], 1, 7);
                }
                else
                {
                    s = new NaServer(args[index], 1, 0);
                 }

                //2. Set the server type
                s.ServerType = serverType;

                //3. Set the transport type
                s.TransportType = transportType;

                //4. Set the authentication style for subsequent ONTAPI authentications.
                s.Style = authStyle;

                //5. Set the login and password used for authenticating when
                //an ONTAPI API is invoked.
                if (authStyle == NaServer.AUTH_STYLE.LOGIN_PASSWORD)
                {
                    s.SetAdminUser(args[++index], args[++index]);
                }

                //6. Set the port number
                s.Port = port;

                //7. Optional - set the vfiler name for vfiler tunneling
                if (vfiler != null)
                {
                    s.SetVfilerTunneling(vfiler);
                }

                // Check if originator_id is set
                if (originatorId != null)
                {
                    s.OriginatorId = originatorId;
                }

                //Set the request timeout.
                if (timeOut != -1)
                {
                    s.TimeOut = timeOut;
                }

                if (useCBA)
                {
                    if(certFile == null && certPasswd != null)
                    {
                        Console.WriteLine("\nERROR: Certificate file not specified.");
                        Usage();
                    }
                    if (certFile != null)
                    {
                        if (certPasswd != null)
                        {
                            s.SetClientCertificate(certFile, certPasswd);
                        }
                        else
                        {
                            s.SetClientCertificate(certFile);
                        }
                    }
                    else
                    {
                        s.SetClientCertificate(storeName, storeLocation, certName);
                    }
                }
                
                s.ServerCertificateVerification = verifyServerCert;
                if (verifyServerCert)
                {
                    s.HostnameVerification = verifyHostname;
                }
                s.Snoop = 1;
                /* Invoke any  ONTAPI API with arguments
                    * in (key,value) pair 
                    * args[0]=filer,args[1]=user,args[2]=passwd
                    * args[3]=Ontapi API,args[4] onward arguments
                    * in (key,value) pair
                */
                try
                {
                    if (inputXML == 0)
                    {
                        if ((index+1) == args.Length)
                        {
                            Console.WriteLine("\nERROR: API not specified.");
                            Usage();
                        }
                        //8. Create an instance of NaElement which contains the ONTAPI API request
                        xi = new NaElement(args[++index]);
                    }
                    //Only use this for debugging
                    else
                    {
                        GetXMLInput(inputXML, ref args, ref index);
                        xi = s.ParseXMLInput(args[++index]);
                    }
                        
                    if (args.Length > index + 1)
                    {
                        for (int index2 = index + 1;index2 < args.Length;index2++)
                        {
                            //9. Optional - add the child elements to the parent 
                            xi.AddNewChild(args[index2], args[index2 + 1]);
                            index2++;
                        }
                    }

                    // Only use this for debugging purpose
                    if (showXML > 0)
                    {
                        if (showXML == 1)
                        {
                            Console.WriteLine("INPUT:\n" + xi.ToPrettyString(""));
                        }
                        else
                        {
                            s.DebugStyle = NaServer.DEBUG_STYLE.PRINT_PARSE;
                        }
                    }
                }
                catch (System.IndexOutOfRangeException)
                {
                    throw new NaApiFailedException("Mismatch in arguments passed "
                                                       + "(in (key,value) Pair) to "
                                                       + "Ontapi API", -1);
                }
                
                // 10. Invoke a single ONTAPI API to the server.
                // The response is stored in xo.
                xo = s.InvokeElem(xi);

                // Only use this for debugging purpose
               if (showXML > 0)
                {
                    if (showXML == 2)
                    {
                        //Simply return because the NaServer will print the raw XML OUTPUT.
                        return;
                    }
                    Console.WriteLine("OUTPUT:");
                }                    

                //11. Print the ONTAPI API response that is returned by the server
                Console.WriteLine(xo.ToPrettyString(""));
            }
            catch (NaApiFailedException e)
            {
                Console.Error.WriteLine(e.Message);
            }
            catch(Exception e)
            {
                Console.Error.WriteLine(e.Message);
            }
        }
    }
}
