//============================================================//
//                                                            //
//                                                            //
// HelloDfm.cs                                                //
//                                                            //
// Copyright 2010 NetApp. All rights reserved.                // 
// Specifications subject to change without notice.           // 
//                                                            //
// This sample code will print the version number of the      //
// DataFabric Manager server.                                 //
//                                                            //
// This Sample code is supported from                         //
// DataFabric Manager 4.0 onwards.                            // 
//                                                            //
//============================================================//

using System;
using System.Web.Services.Protocols;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

namespace HelloDfm
{
    /// <summary>
    /// This class will print the version number of the DFM Server.
    /// </summary>
    class HelloDfm
    {

        /// <summary>
        /// The default HTTP and HTTPS port numbers for the DFM server.
        /// </summary>
        private static readonly int DEFAULT_DFM_HTTP_PORT = 8088;
        private static readonly int DEFAULT_DFM_HTTPS_PORT = 8488;

        /// <summary>
        /// Client interface to the DFM server.
        /// </summary>
        private static DfmService dfmService;

        /// <summary>
        /// This function will print various usage options.
        /// </summary>
        public static void PrintUsageAndExit()
        {
            System.Console.WriteLine("Usage: HelloDfm <dfmserver> <user> <passwd> [ -s [ -i ] ] \n");
            System.Console.WriteLine("  -s          Use HTTPS transport");
            System.Console.WriteLine("  -i          Ignores server certificate validation process for HTTPS\n");
            System.Environment.Exit(1);
        }

        /// <summary>
        /// Creates the client proxy that you can use to invoke DFM APIs.
        /// </summary>
        private static void CreateDfmService(string dfmServer, string dfmUser, string dfmPasswd, bool useHttps, bool ignoreCert)
        {
            String protocol = "http";
            int portno = DEFAULT_DFM_HTTP_PORT;

            if (useHttps)
            {
                protocol = "https";
                portno = DEFAULT_DFM_HTTPS_PORT;
            }

            String url = protocol + "://" + dfmServer + ":" + portno + "/apis/soap/v1";
            dfmService = new DfmService();
            ICredentials credentials = new NetworkCredential(dfmUser, dfmPasswd);
            dfmService.Credentials = credentials;
            dfmService.Url = url;

            if (useHttps && ignoreCert)
            {
                //Console.WriteLine("Ignoring certificate validation..");
                ServicePointManager.ServerCertificateValidationCallback +=
                new RemoteCertificateValidationCallback(TrustAllServerCertificates);
            }
        }

        /// <summary>
        /// Entry point for HelloDfm.
        /// </summary>
        public static void Main(string[] args)
        {
            if (args.Length < 3)
            {
                PrintUsageAndExit();
            }

            String dfmServer = args[0];
            String dfmUser = args[1];
            String dfmPwd = args[2];
            bool useHttps = false;
            bool ignoreCert = false;

            if (args.Length > 3)
            {
                if (!args[3].Equals("-s"))
                {
                    PrintUsageAndExit();
                }
                useHttps = true;
                if (args.Length > 4 && args[4].Equals("-i"))
                {
                    ignoreCert = true;
                }
            }
            CreateDfmService(dfmServer, dfmUser, dfmPwd, useHttps, ignoreCert);
            DfmAbout();
        }
                
        /// <summary>
        /// Calls the DfmAbout API and prints the results.
        /// </summary>
        public static void DfmAbout()
        {
            try
            {
                DfmAbout dfmAbout = new DfmAbout();
                DfmAboutResult result = dfmService.DfmAbout(dfmAbout);
                Console.WriteLine("Hello world! DFM Server version is: " + result.Version);
            }
            catch (SoapException e)
            {
                Console.Error.WriteLine(e.Message);
            }
            catch (Exception e)
            {
                Console.Error.WriteLine(e.Message);
            }
        }

        /// <summary>
        /// Callback for validating a server certificate. This method will accept the certificate 
        /// sent by the server during handshake.
        /// </summary>
        public static bool TrustAllServerCertificates(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors)
        {
            return true;
        }
    }
}

