/*
 * $Id:$
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 */
 
import java.util.Map;

import javax.xml.ws.BindingProvider;
import javax.xml.ws.soap.SOAPFaultException;

import com.netapp.management.v1.*;

/**
 * This class will help managing the vfiler units
 * you can create and delete vFiler units, create,list and delete vFiler 
 * templates.
 *
 *
 * This Sample code is supported from DataFabric Manager 4.0 onwards.
 */
public final class Vfiler {

    /**
     * The default port number for the DFM server (over HTTP).
     */
    private static final int DEFAULT_DFM_PORT = 8088;

    /**
     * Client interface to the DFM server
     */
    private static DfmInterface dfmInterface;
    
    /**
     * Command line arguments
     */
    private static String[] args;
    
    public static void printUsageAndExit(){
        System.out.println("" +
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

        System.exit(1);
    }

    public static void main(String[] arg) throws Exception {
        
        args = arg;
        // Checking for valid number of parameters
        if (args.length < 4) {
            printUsageAndExit();
        }

        String dfmServer = args[0];
        String dfmUser = args[1];
        String dfmPwd = args[2];
        String dfmOp = args[3];

        // creating a interface instance
        dfmInterface = createDfmInterface(dfmServer, DEFAULT_DFM_PORT, dfmUser, dfmPwd);

        // Calling the functions based on the operation selected
        if (dfmOp.equals("create") && args.length >= 7) {
            create();
        }
        else if (dfmOp.equals("delete") && args.length == 5) {
            delete();
        }
        else if (dfmOp.equals("template-list")  && args.length >= 4) {
            templateList();
        }
        else if (dfmOp.equals("template-create") &&  args.length >= 5) {
            templateCreate();
        }
        else if (dfmOp.equals("template-delete")  &&  args.length == 5) {
            templateDelete();
        }
        else {
            printUsageAndExit();
        }
    }

    /**
     * Creates the client proxy that you can use to invoke DFM APIs.
     */
    private static DfmInterface createDfmInterface(String dfmServer, int portno, String dfmUser, String dfmPwd) {
        String url = "http://" + dfmServer + ":" + portno + "/apis/soap/v1";

        DfmService ss = new DfmService();
        DfmInterface dfmInterface = ss.getDfmPort();

        BindingProvider provider = (BindingProvider) dfmInterface;
        Map<String, Object> reqContext = provider.getRequestContext();
        reqContext.put(BindingProvider.USERNAME_PROPERTY, dfmUser);
        reqContext.put(BindingProvider.PASSWORD_PROPERTY, dfmPwd);
        reqContext.put(BindingProvider.ENDPOINT_ADDRESS_PROPERTY, url);
        return dfmInterface;
    }

    /**
     * Creates a vfiler using the info provided on the command line
     * and (if a template name was specified) sets it up.
     */
    public static void create() {
        String templateName = null;

        // Getting the vfiler name, resource pool name and ip
        String vfilerName = args[4];
        String poolName = args[5];
        String ip = args[6];
        
        // doing an argument check
        if (args.length > 7) {
            templateName = args[7];
        }
        
        try {
            // creating a vfiler create instance
            VfilerCreate param = new VfilerCreate();
            
            // setting the ip, vfiler name and resourcepool parameter
            param.setIpAddress(ip);
            param.setName(vfilerName);
            param.setResourceNameOrId(poolName);
            
            // invoking the vfiler create API and capturing the output data structure
            VfilerCreateResult res = dfmInterface.vfilerCreate(param);
            
            // printing success message if there is no exception
            System.out.println("\nvFiler unit creation successful");
            
            // extracting and printing the root volume and filer name from the output datastructure
            System.out.println(
                "\nvFiler unit created on Storage System : " + res.getFilerName()
                + "\nRoot Volume : " + res.getRootVolumeName());

            // Doing a vfiler setup if the template name is input
            if (templateName != null) {
                setup(vfilerName, templateName);
            }
        } catch(SOAPFaultException se) {
            
            // printing error string if any. the string has the error code and the error description
            System.err.println(se.getFault().getFaultString());
        }
    }

    /**
     * Sets up the vfiler with the given vfiler name and template name.
     */
    public static void setup(String vfilerName, String templateName) {
        
        try {
            // creating a vfiler setup instance
            VfilerSetup param = new VfilerSetup();
            
            // setting the vfiler name and template name
            param.setVfilerNameOrId(vfilerName);
            param.setVfilerTemplateNameOrId(templateName);
            
            // invoking the vfiler setup API
            dfmInterface.vfilerSetup(param);

            System.out.println("\nvFiler unit setup with template " + templateName +" Successful");
        } catch(SOAPFaultException se) {
            // printing error string if any. the string has the error code and the error description
            System.err.println(se.getFault().getFaultString());
        }
    }

    /**
     * Deletes the vfiler specified on the command line. 
     */
    public static void delete() {
        String vfilerName = args[4];
        
        try {
            VfilerDestroy param = new VfilerDestroy();
            param.setVfilerNameOrId(vfilerName);
            dfmInterface.vfilerDestroy(param);

            System.out.println("\nvFiler unit deletion successful");
        } catch(SOAPFaultException se) {
            // printing error string if any. the string has the error code and the error description
            System.err.println(se.getFault().getFaultString());
        }
    }

    /**
     * Creates a vfiler template using info provided on the command line.
     */
    public static void templateCreate() {
        String cifsAuth = null;
        String cifsDomain = null;
        String cifsSecurity = null;

        // Getting the template name
        String templateName = args[4];

        // parsing optional parameters
        int i = 5;
        while (i < args.length) {
            if (args[i].equals("-a")) {
                cifsAuth = args[++i]; ++i ;
            } else if (args[i].equals("-d")) {
                cifsDomain = args[++i]; ++i ;
            } else if (args[i].equals("-s")) {
                cifsSecurity = args[++i]; ++i ;
            } else {
                printUsageAndExit();
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
            vparam.setVfilerTemplateName(templateName);
            // setting the cifs authentication parameter if input
            vparam.setCifsAuthType(cifsAuth);
            // setting the cifs domain parameter if input
            vparam.setCifsDomain(cifsDomain);
            // setting the cifs security parameter if input
            vparam.setCifsSecurityStyle(cifsSecurity);
            // attaching the template info object to template info wrapper
            wparam.setVfilerTemplateInfo(vparam);
            // attaching the template info wrapper to template create instance
            param.setVfilerTemplate(wparam);
            
            // invoking the template create API.
            dfmInterface.vfilerTemplateCreate(param);

            // printing success message
            System.out.println("\nvFiler template creation successful");
        } catch(SOAPFaultException se) {
            // printing error string if any. the string has the error code and the error description
            System.err.println(se.getFault().getFaultString());
        }   
    }

    /**
     * If a vfiler template name is specified on the command line,
     * then list info about that template.
     * Otherwise, list info about every vfiler template.
     */
    public static void templateList() {
        String templateName = null;
        try {
            // creating the list start instance
            VfilerTemplateListInfoIterStart sparam = new VfilerTemplateListInfoIterStart();
            
            // setting the template name if present
            if (args.length > 4) {
                templateName = args[4];
                sparam.setVfilerTemplateNameOrId(templateName);
            }
            
            // invoking the list iter start API and capturing the output datastructure
            VfilerTemplateListInfoIterStartResult sres = dfmInterface.vfilerTemplateListInfoIterStart(sparam);
            
            // Extracting the record && tag values from the output datastructure
            String tag = sres.getTag();
            int records = sres.getRecords();
            // Doing a check on number of records
            if (records <= 0) {
                System.out.println("\nNo templates to display");
            }
            else {
                // creating a list iter next instance
                VfilerTemplateListInfoIterNext nparam = new VfilerTemplateListInfoIterNext();
                // setting maximum to number of records and setting the tag
                nparam.setMaximum(records);
                nparam.setTag(tag);
                // invoking the list iter next API and capturing the output datastructure
                VfilerTemplateListInfoIterNextResult nres = dfmInterface.vfilerTemplateListInfoIterNext(nparam);
                // extracting the array of template info from the output data structure
                ArrayOfVfilerTemplateInfo stat = nres.getVfilerTemplates();
                
                if (stat != null) {
                    for (VfilerTemplateInfo info : stat.getVfilerTemplateInfo()) {
    
                        System.out.println("----------------------------------------------------");
                        printField("Template Name", info.getVfilerTemplateName());
                        printField("Template Id", info.getVfilerTemplateId());
                        printField("Template Description", info.getDescription());
    
                        System.out.println("\n----------------------------------------------------");
                        
                        // printing details if only one template is selected for listing
                        if (templateName != null) {
    
                            printField("CIFS Authentication", info.getCifsAuthType());
                            printField("CIFS Domain", info.getCifsDomain());
                            printField("CIFS Security Style", info.getCifsSecurityStyle());
                            printField("DNS Domain", info.getDnsDomain());
                            printField("NIS Domain", info.getNisDomain());
                        }
                    }
                }
            }

            // creating a list iter end instance
            VfilerTemplateListInfoIterEnd eparam = new VfilerTemplateListInfoIterEnd();
            // setting the tag parameter
            eparam.setTag(tag);
            // invoking the API
            dfmInterface.vfilerTemplateListInfoIterEnd(eparam);
        } catch(SOAPFaultException se) {
            // printing error string if any. the string has the error code and the error description
            System.err.println(se.getFault().getFaultString());
        }
    }

    /**
     * Deletes the vfiler template specified on the command line.  
     */
    public static void templateDelete() {
        String templateName = args[4];
        
        try {
            // creating the template delete param
            VfilerTemplateDelete param = new VfilerTemplateDelete();
            // setting the template name parameter
            param.setVfilerTemplateNameOrId(templateName);
            // invoking the API
            dfmInterface.vfilerTemplateDelete(param);
            
            // printing success message if no exception
            System.out.println("Deletion successful");
        } catch(SOAPFaultException se) {
            // printing error string if any. the string has the error code and the error description
            System.err.println(se.getFault().getFaultString());
        }
    }

    private static void printField(String fieldName, Object fieldValue) {
        System.out.println(String.format(
                "%-25s: %s",
                fieldName, 
                fieldValue == null ? "" : fieldValue));
    }

}
