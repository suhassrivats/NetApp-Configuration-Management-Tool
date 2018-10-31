//============================================================//
//                                                            //
//                                                            //
// Vfiler.cs                                                  //
//                                                            //
// Copyright (c) 2010 NetApp, Inc. All rights reserved.       //
// Specifications subject to change without notice.           // 
//                                                            //
// This sample code is used to manage the vfiler units.       // 
// You can create and delete vFiler units, create, list and   //
// delete vFiler templates.                                   //
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

namespace Vfiler
{
    /// <summary>
    /// This class will manage vFiler units
    /// </summary>
    class vfiler
    {

        /// <summary>
        /// The default HTTP port number for the DFM server.
        /// </summary>
        private static readonly int DEFAULT_DFM_HTTP_PORT = 8088;

        /// <summary>
        /// Client interface to the DFM server.
        /// </summary>
        private static DfmService dfmService;
        private static string[] args;

        /// <summary>
        /// This function will print various usage options.
        /// </summary>
        public static void PrintUsageAndExit()
        {
            Console.WriteLine("" +
            "Usage:\n" +
            "Vfiler <dfmserver> <user> <password> delete <name>\n" +
            "\n" +
            "Vfiler <dfmserver> <user> <password> create <name> <rpool> <ip> [ <tname> ]\n"
            + "\n" +
            "Vfiler <dfmserver> <user> <password> template-list [ <tname> ]\n" +
            "\n" +
            "Vfiler <dfmserver> <user> <password> template-delete <tname>\n" +
            "\n" +
            "Vfiler <dfmserver> <user> <password> template-create <a-tname>\n" +
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
            "<cauth>     -- CIFS authentication mode Possible values: \"active_directory\""
            + ",\n" +
            "               \"workgroup\". Default value: \"workgroup\"\n" +
            "<cdomain>   -- Active Directory domain .This field is applicable only when\n" +
            "               cifs-auth-type is set to \"active-directory\"\n" +
            "<csecurity> -- The security style Possible values: \"ntfs\", \"multiprotocol\""
            + "\n" +
            "               Default value is: \"multiprotocol\"");
            System.Environment.Exit(1);
        }

        /// <summary>
        /// Creates the client proxy that you can use to invoke DFM APIs.
        /// </summary>
        private static void CreatedfmService(string dfmServer, string dfmUser, string dfmPasswd)
        {
            String protocol = "http";
            int portno = DEFAULT_DFM_HTTP_PORT;

            String url = protocol + "://" + dfmServer + ":" + portno + "/apis/soap/v1";
            ICredentials credentials = new NetworkCredential(dfmUser, dfmPasswd);
            dfmService = new DfmService();
            dfmService.Credentials = credentials;
            dfmService.Url = url;
        }

        /// <summary>
        /// Entry point for Vfiler.
        /// </summary>
        public static void Main(string[] Args)
        {
            args = Args;
            if (args.Length < 4)
            {
                PrintUsageAndExit();
            }

            String dfmServer = args[0];
            String dfmUser = args[1];
            String dfmPwd = args[2];
            String dfmOp = args[3];

            try {
                CreatedfmService(dfmServer, dfmUser, dfmPwd);

                // Calling the functions based on the operation selected
                if (dfmOp.Equals("create") && args.Length >= 7)
                {
                    Create();
                }
                else if (dfmOp.Equals("delete") && args.Length == 5)
                {
                    Delete();
                }
                else if (dfmOp.Equals("template-list") && args.Length >= 4)
                {
                    TemplateList();
                }
                else if (dfmOp.Equals("template-create") && args.Length >= 5)
                {
                    TemplateCreate();
                }
                else if (dfmOp.Equals("template-delete") && args.Length == 5)
                {
                    TemplateDelete();
                }
                else
                {
                    PrintUsageAndExit();
                }
            }
            catch (Exception e)
            {
                Console.Error.WriteLine(e.Message);
            }
        }

        ///<summary>
        /// Creates a vfiler using the info provided on the command line
        /// and (if a template name was specified) sets it up.
        ///</summary>
            public static void Create() {
            String templateName = null;

            // Getting the vfiler name, resource pool name and ip
            String vfilerName = args[4];
            String poolName = args[5];
            String ip = args[6];
            
            // doing an argument check
            if (args.Length > 7) {
                templateName = args[7];
            }
            
            try {
                // creating a vfiler create instance
                VfilerCreate param = new VfilerCreate();
                
                // setting the ip, vfiler name and resourcepool parameter
                param.IpAddress = ip;
                param.Name = vfilerName;
                param.ResourceNameOrId = poolName;
                
                // invoking the vfiler create API and capturing the output data structure
                VfilerCreateResult res = dfmService.VfilerCreate(param);
                
                // printing success message if there is no exception
                Console.WriteLine("\nvFiler unit creation successful");
                
                // extracting and printing the root volume and filer name from the output datastructure
                Console.WriteLine(
                    "\nvFiler unit created on Storage System : " + res.FilerName
                    + "\nRoot Volume : " + res.RootVolumeName);

                // Doing a vfiler setup if the template name is input
                if (templateName != null) {
                    setup(vfilerName, templateName);
                }
            } catch(SoapException e) {
                
                // printing error string if any. the string has the error code and the error description
                Console.Error.WriteLine(e.Message);
            }
        }

            ///<summary>
            /// Sets up the vfiler with the given vfiler name and template name.
            ///</summary>
            public static void setup(String vfilerName, String templateName) {
            
            try {
                // creating a vfiler setup instance
                VfilerSetup param = new VfilerSetup();
                
                // setting the vfiler name and template name
                param.VfilerNameOrId = vfilerName;
                param.VfilerTemplateNameOrId = templateName;
                
                // invoking the vfiler setup API
                dfmService.VfilerSetup(param);

                Console.WriteLine("\nvFiler unit setup with template " + templateName +" Successful");
            } catch(SoapException e) {
                // printing error string if any. the string has the error code and the error description
                Console.Error.WriteLine(e.Message);
            }
        }

            ///<summary>
            /// Deletes the vfiler specified on the command line. 
            ///</summary>
            public static void Delete() {
            String vfilerName = args[4];
            
            try {
                VfilerDestroy param = new VfilerDestroy();
                param.VfilerNameOrId = vfilerName;
                dfmService.VfilerDestroy(param);

                Console.WriteLine("\nvFiler unit deletion successful");
            } catch(SoapException e) {
                // printing error string if any. the string has the error code and the error description
                Console.Error.WriteLine(e.Message);
            }
        }

            ///<summary>
            /// Creates a vfiler template using info provided on the command line.
            ///</summary>
            public static void TemplateCreate() {
            String cifsAuth = null;
            String cifsDomain = null;
            String cifsSecurity = null;

            // Getting the template name
            String templateName = args[4];

            // parsing optional parameters
            int i = 5;
            while (i < args.Length) {
                if (args[i].Equals("-a")) {
                    cifsAuth = args[++i]; ++i ;
                } else if (args[i].Equals("-d")) {
                    cifsDomain = args[++i]; ++i ;
                } else if (args[i].Equals("-s")) {
                    cifsSecurity = args[++i]; ++i ;
                } else {
                    PrintUsageAndExit();
                }
            }
            try {
                // creating a template create instance
                VfilerTemplateCreate param = new VfilerTemplateCreate();
                // creating a template info wrapper instance
                WrapperOfVfilerTemplateInfo wparam = new WrapperOfVfilerTemplateInfo();
                // creating a template info instance
                VfilerTemplateInfo vparam = new VfilerTemplateInfo();
                // setting the template name
                vparam.VfilerTemplateName = templateName;
                // setting the cifs authentication parameter if input
                vparam.CifsAuthType = cifsAuth;
                // setting the cifs domain parameter if input
                vparam.CifsDomain = cifsDomain;
                // setting the cifs security parameter if input
                vparam.CifsSecurityStyle = cifsSecurity;
                // attaching the template info object to template info wrapper
                wparam.VfilerTemplateInfo = vparam;
                // attaching the template info wrapper to template create instance
                param.VfilerTemplate = wparam;
                
                // invoking the template create API.
                dfmService.VfilerTemplateCreate(param);

                // printing success message
                Console.WriteLine("\nvFiler template creation successful");
            } catch(SoapException e) {
                // printing error string if any. the string has the error code and the error description
                Console.Error.WriteLine(e.Message);
            }   
        }

            ///<summary>
            /// If a vfiler template name is specified on the command line,
            /// then list info about that template.
            /// Otherwise, list info about every vfiler template.
            ///</summary>
            public static void TemplateList() {
            String templateName = null;
            try {
                // creating the list start instance
                VfilerTemplateListInfoIterStart sparam = new VfilerTemplateListInfoIterStart();
                
                // setting the template name if present
                if (args.Length > 4) {
                    templateName = args[4];
                    sparam.VfilerTemplateNameOrId = templateName;
                }
                
                // invoking the list iter start API and capturing the output datastructure
                VfilerTemplateListInfoIterStartResult sres = dfmService.VfilerTemplateListInfoIterStart(sparam);
                
                // Extracting the record && tag values from the output datastructure
                String tag = sres.Tag;
                String records = sres.Records;
                // Doing a check on number of records
                if ( Convert.ToInt32(records) <= 0) {
                    Console.WriteLine("\nNo templates to display");
                }
                else {
                    // creating a list iter next instance
                    VfilerTemplateListInfoIterNext nparam = new VfilerTemplateListInfoIterNext();
                    // setting maximum to number of records and setting the tag
                    nparam.Maximum = records;
                    nparam.Tag = tag;
                    // invoking the list iter next API and capturing the output datastructure
                    VfilerTemplateListInfoIterNextResult nres = dfmService.VfilerTemplateListInfoIterNext(nparam);
                    // extracting the array of template info from the output data structure
                    VfilerTemplateInfo[] stat = nres.VfilerTemplates;
                    
                    if (stat != null) {
                        foreach (VfilerTemplateInfo info in stat) {
        
                            Console.WriteLine("----------------------------------------------------");
                            printField("Template Name", info.VfilerTemplateName);
                            printField("Template Id", info.VfilerTemplateId);
                            printField("Template Description", info.Description);
        
                            Console.WriteLine("\n----------------------------------------------------");
                            
                            // printing details if only one template is selected for listing
                            if (templateName != null) {
        
                                printField("CIFS Authentication", info.CifsAuthType);
                                printField("CIFS Domain", info.CifsDomain);
                                printField("CIFS Security Style", info.CifsSecurityStyle);                                
                                printField("DNS Domain", info.DnsDomain);
                                printField("NIS Domain", info.NisDomain);
                            }
                        }
                    }
                }

                // creating a list iter end instance
                VfilerTemplateListInfoIterEnd eparam = new VfilerTemplateListInfoIterEnd();
                // setting the tag parameter
                eparam.Tag = tag;
                // invoking the API
                dfmService.VfilerTemplateListInfoIterEnd(eparam);
            } catch(SoapException e) {
                // printing error string if any. the string has the error code and the error description
                Console.Error.WriteLine(e.Message);
            }
        }

            ///<summary>
            /// Deletes the vfiler template specified on the command line.  
           ///</summary>
            public static void TemplateDelete() {
            String templateName = args[4];
            
            try {
                // creating the template delete param
                VfilerTemplateDelete param = new VfilerTemplateDelete();
                // setting the template name parameter
                param.VfilerTemplateNameOrId = templateName;
                // invoking the API
                dfmService.VfilerTemplateDelete(param);
                
                // printing success message if no exception
                Console.WriteLine("Deletion successful");
            } catch(SoapException e) {
                // printing error string if any. the string has the error code and the error description
                Console.Error.WriteLine(e.Message);
            }
        }

        private static void printField(String fieldName, Object fieldValue) {
            Console.WriteLine(String.Format(
                "{0,-25}: {1}", fieldName, fieldValue == null ? "" : fieldValue));
        }
    }
}

