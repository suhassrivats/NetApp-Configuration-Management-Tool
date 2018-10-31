/*
 * $Id:$
 *
 * apitest.java
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample for using the netapp.manage.* classes to 
 * any ONTAPI API
 */
import netapp.manage.*;
import java.io.*;

public class apitest {

    public static void usage() {
        System.out.println("\nUsage:\n\tapitest (options) <host> <user> "
                + "<password> <ONTAPI-name> [<paramname> <arg> ...]\n");
        System.out.println("Options:\n");
        System.out
                .println("\t-i\tAPI specified as XML input, on the command line\n");
        System.out
                .println("\t-I\tAPI specified as XML input, on standard input\n");
        System.out
                .println("\t-t {type}\tServer type(type = filer, dfm, ocum, agent)\n");
        System.out
                .println("\t-v {vfiler name | vserver name}\tFor vfiler-tunneling or vserver-tunneling \n");
        System.out.println("\t-r\tUse RPC transport (Windows)\n");
        System.out.println("\t-n\tUse HTTP\n");
        System.out.println("\t-p\t{port}\n");
        System.out.println("\t-x\tShow the XML input and output\n");
        System.out.println("\t-X\tShow the raw XML input and output\n");
        System.out.println("\t-c\tConnection timeout\n");
        System.out.println("\t-h\tUse Host equiv authentication mechanism\n");
        System.out.println("\t-K\t{keystore-file}       Client keystore file to use\n");
        System.out.println("\t-P\t{keystore-passwd}     Password to access the keystore file\n");
        System.out.println("\t-E\t{keystore-key-passwd} Password to access the private key in the keystore file\n");
        System.out.println("\t-Y\t{keystore-file-type}  Type of the keystore file (JKS/PKCS12). Default is JKS\n");
        System.out.println("\t-T\t{truststore-file}     Truststore file to use during server certificate verification\n");
        System.out.println("\t-S\tEnable server certificate verification\n");
        System.out.println("\t-H\tEnable Hostname verification\n\n");
        System.out.println("Note:\n");
        System.out.println("\tUse server type 'dfm' (-t dfm) for OnCommand Unified Manager server version 5.2 or earlier.");
        System.out.println("\tUse server type 'ocum' (-t ocum) for OnCommand Unified Manager server version 6.0 or later.\n\n");
        System.out.println("\tBy default username and password shall be used for client authentication.");
        System.out.println("\tSpecify -K option for using Certificate Based Authentication (CBA).");
        System.out.println("\tServer certificate and Hostname verification is disabled by default for CBA.");  
        System.out.println("\tDo not provide username and password for -h, -r or CBA\n");
        System.out.println("Examples:\n");
        System.out.println("\tapitest sweetpea root tryme system-get-version");
        System.out.println("\tapitest amana root meat quota-report volume vol0");
        System.out.println("\tapitest -t dfm -K my_keystore.jks -P keypasswd amana dfm-about");
        System.out.println("\tapitest -t dfm -K my_keystore.jks -P keypasswd -S -T my_truststore.jks amana dfm-about\n");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi = null;
        NaElement xo;
        NaServer s;
        String server_type, user, password;
        int argcnt = 0, index, i = 0, ind = 1, showxml = 0;
        String read_xml = "";
        boolean dorpc, dovfiler, dofiler, dodfm, doocum, doagent, host_equiv;
        boolean dossl=true;
        boolean useTimeout = false;
        int inputxml = 0, use_port = -1;
        String Cur_Line, vfiler_name = null, platform_type;
        int timeout = 0;
        boolean useCBA = false;
        boolean verifyServerCert = false;
        boolean verifyHostname = false;
        String keyStoreFile, keyStorePasswd, keyPasswd, keyStoreType;
        String trustStoreFile;

        dofiler = dodfm = doocum = doagent = dorpc = dovfiler = host_equiv = false;
        keyStoreFile = keyStorePasswd = keyPasswd = trustStoreFile = null;
        keyStoreType = "JKS";

        if (args.length < 3)
            usage();

        index = args[0].indexOf('-');
        while (args[argcnt].startsWith("-")) {
            switch (args[argcnt].charAt(ind)) {
            case 'i':
                inputxml = 1;
                argcnt++;
                break;
            case 'I':
                inputxml = 2;
                argcnt++;
                break;
            case 't':
                server_type = args[argcnt + 1];
                if (server_type.equals("dfm"))
                    dodfm = true;
                else if (server_type.equals("ocum")) {
                    doocum = true;
                    dossl = true;
                }
                else if (server_type.equals("agent"))
                    doagent = true;
                else if (server_type.equals("filer"))
                    dofiler = true;
                argcnt = argcnt + 2;
                break;
            case 'v':
                vfiler_name = args[argcnt + 1];
                dovfiler = true;
                argcnt = argcnt + 2;
                break;
            case 'r':
                platform_type = (System.getProperty("os.name"));
                if (!platform_type.matches("(?i).*windows .*")) {
                    System.out.println("-r is valid only on windows\n");
                    System.exit(1);
                }
                dorpc = true;
                argcnt++;
                break;
            case 'n':
                dossl = false;
                argcnt++;
                break;
            case 'p':
                use_port = Integer.parseInt(args[argcnt + 1]);
                argcnt = argcnt + 2;
                break;
            case 'x':
                showxml = 1;
                argcnt++;
                break;
            case 'X':
                showxml = 2;
                argcnt++;
                break;
            case 'h':
                host_equiv = true;
                argcnt++;
                break;
            case 'c':
                useTimeout = true;
                timeout = Integer.parseInt(args[argcnt + 1]);
                argcnt = argcnt + 2;
                break;
            case 'K':
                useCBA = true;
                dossl = true;
                keyStoreFile = args[argcnt + 1];
                argcnt = argcnt + 2;
                break;
            case 'P':
                keyStorePasswd = args[argcnt + 1];
                argcnt = argcnt + 2;
                break;
            case 'E':
                keyPasswd = args[argcnt + 1];
                argcnt = argcnt + 2;
                break;
            case 'Y':
                keyStoreType = args[argcnt + 1];
                argcnt = argcnt + 2;
                break;
            case 'T':
                trustStoreFile = args[argcnt + 1];
                argcnt = argcnt + 2;
                break;
            case 'S':
                verifyServerCert = true;
                argcnt++;
                break;
            case 'H':
                verifyHostname = true;
                argcnt++;
                break;
            default:
                System.out.println("\nERROR::Invalid Option");
                usage();
            }
        }

        if ((args.length < 4) && (host_equiv == false && dorpc == false))
            usage();

        if ((dodfm || doocum) && dovfiler) {
            System.out.println("The -v option is not a valid option for OnCommand Unified Manager server.\n");
            System.exit(1);
        }
        if ((dodfm || doocum) && dorpc) {
            System.out.println("The -r option is not a vaid option for OnCommand Unified Manager server.\n");
            System.exit(1);
        }
        if (host_equiv && dorpc) {
            System.out.println("Invalid usage of authentication style. "
                    + "Do not use -r option and -h option together.\n");
            System.exit(1);
        }
	if (dorpc && useTimeout) {
		System.out.println("Connection timeout value cannot be set for RPC authentication style.\n");
		System.exit(1);
	}
        if (verifyHostname && !verifyServerCert) {
            System.out.println("Hostname verification cannot be enabled when server certificate verification is disabled.");
            System.exit(1); 
        }
        if (!(keyStoreType.equalsIgnoreCase("JKS") || keyStoreType.equalsIgnoreCase("PKCS12"))) {
            System.out.println("Invalid KeyStore type. Possible values are JKS and PKCS12.\n");
            System.exit(1);
        }
        /* Set the port to the host type specified */
        if (use_port == -1) {
            if (dodfm)
                use_port = (dossl) ? 8488 : 8088;
            else if (doocum)
                use_port = 443;
            else if (doagent)
                use_port = (dossl) ? 4093 : 4092;
            else
                use_port = (dossl) ? 443 : 80;
        }
        try {
            /* Vfiler tunnelling requires ONTAPI version 7.0 to work */
            /*
             * NaServer is called to connect to servers and invoke API's. The
             * argument passed should be: NaServer(hostname, major API version
             * number, minor API version number
             */
            if (vfiler_name != null)
                s = new NaServer(args[argcnt], 1, 7);
            else
                s = new NaServer(args[argcnt], 1, 0);

            /* This is needed for -X option */
            if (showxml == 2)
                s.setSnoop(-1);

            /*
             * Set the authentication style for subsequent ONTAPI
             * authentications.
             */
            if (dorpc)
                s.setStyle(NaServer.STYLE_RPC);
            else if (host_equiv) {
                s.setStyle(NaServer.STYLE_HOSTSEQUIV);
            } else if (useCBA)
                s.setStyle(NaServer.STYLE_CERTIFICATE);
            else
                s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);

            /*
             * Set the login and password used for authenticating when an ONTAPI
             * API is invoked. When host_equiv is set do not set username and
             * password
             */
            if (!host_equiv && !dorpc && !useCBA) {
                user = args[++argcnt];
                if (args.length == argcnt + 1) {
                    System.out.println("\nInsufficient Arguments Passed");
                    usage();
                }
                password = args[++argcnt];
                s.setAdminUser(user, password);
            }

            /* Set the TCP port used for API invocations on the server. */
            s.setPort(use_port);

            if (useTimeout) {
                if (timeout > 0) {
                    s.setTimeout(timeout);
                } else {
                    System.out
                            .println("\nInvalid value for connection timeout. "
                                    + "Connection timeout value should be greater "
                                    + "than 0.\n");
                    System.exit(1);
                }
            }

            /* Set the Type of API Server */
            if (dodfm)
                s.setServerType(NaServer.SERVER_TYPE_DFM);
            else if (doocum)
                s.setServerType(NaServer.SERVER_TYPE_OCUM);
            else if (doagent)
                s.setServerType(NaServer.SERVER_TYPE_AGENT);
            else
                s.setServerType(NaServer.SERVER_TYPE_FILER);
            if (!dossl)
                s.setTransportType(NaServer.TRANSPORT_TYPE_HTTP);

            /*
             * Set the name of the vfiler on which the API commands need to be
             * invoked.
             */
            if (vfiler_name != null)
                s.setVfilerTunneling(vfiler_name);

            if (useCBA) {
                if (keyStorePasswd == null) {
                    System.out.println("Missing keystore password\n");
                    usage();
                }
                s.setKeyStore(keyStoreFile, keyStorePasswd, keyPasswd);
                if(keyStoreType.equalsIgnoreCase("JKS")) {
                    s.setKeyStoreType(NaServer.KEYSTORE_TYPE_JKS);
                } else {
                    s.setKeyStoreType(NaServer.KEYSTORE_TYPE_PKCS12);
                }
            }
            if (dossl || verifyServerCert) {
                if (verifyServerCert) {
                    s.enableServerCertVerification();
                } else {
                    s.disableServerCertVerification();
                }
                if (verifyServerCert) {
                    if (verifyHostname) {
                        s.enableHostnameVerification();
                    } else {
                        s.disableHostnameVerification();
                    }
                }
            }
            if (trustStoreFile != null) {
                    s.setTrustStore(trustStoreFile);
            }
            if (inputxml > 0) {
                if (inputxml == 2) {
                    if (args.length - 1 > argcnt) {
                        System.out.println("The -I option expects no API "
                                + "on the command-line, "
                                + "it expects standard input\n");
                        usage();
                    }
                    /* Read the input from standard in. */
                    InputStreamReader converter = new InputStreamReader(
                            System.in);
                    BufferedReader in = new BufferedReader(
                            new InputStreamReader(System.in));
                    while ((Cur_Line = in.readLine()) != null)
                        read_xml = read_xml + Cur_Line;
                } else {
                    if (args.length == argcnt + 1) {
                        System.out.println("API not specified");
                        usage();
                    }
                    for (int cnt = argcnt + 1; cnt < args.length; cnt++)
                        read_xml = read_xml + args[cnt];
                }
                args = null;
                args = read_xml.split(" |\n");
                read_xml = "";
                for (int cnt = 0; cnt < args.length; cnt++)
                    if (!(args[cnt].matches("\t") || args[cnt].matches(" ")))
                        read_xml = read_xml + args[cnt];
                args = null;
                args = read_xml.split("\t|\n");
                argcnt = -1;
            }
            /*
             * Invoke any ONTAPI API with arguments in (key,value) pair
             * args[0]=filer,args[1]=user,args[2]=passwd args[3]=Ontapi
             * API,args[4] onward arguments in (key,value) pair
             */
            if (inputxml > 0)
                xi = s.getXMLParseInput(args[++argcnt]);
            else
                xi = new NaElement(args[++argcnt]);
            try {
                if (args.length > argcnt + 1) {
                    for (int index2 = argcnt + 1; index2 < args.length; index2++) {
                        xi.addNewChild(args[index2], args[index2 + 1]);
                        index2++;
                    }
                }
            } catch (ArrayIndexOutOfBoundsException e) {
                throw new NaAPIFailedException(-1,
                        "Mismatch in arguments passed "
                                + "(in (key,value) Pair) to " + "Ontapi API");
            }
            if (showxml == 1) {
                System.out.println("INPUT:\n" + xi.toPrettyString(""));
            }
            /* Invoke a single ONTAPI API */
            xo = s.invokeElem(xi);
            if (showxml != 2)
                System.out.println("OUTPUT:\n" + xo.toPrettyString(""));
            s.close();
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            System.exit(1);
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
