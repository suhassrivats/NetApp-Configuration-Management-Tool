#============================================================
#
# $ID$
#
# apitest.py
#
# apitest executes ONTAP APIs.
#
# Copyright (c) 2011 NetApp, Inc. All rights reserved.
# Specifications subject to change without notice.
#
# This SDK sample code is provided AS IS, with no support or
# warranties of any kind, including but not limited to
# warranties of merchantability or fitness of any kind,
# expressed or implied.  This code is subject to the license
# agreement that accompanies the SDK.
#
# tab size = 8
#
#============================================================

from xml.dom import minidom 
import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *

def print_usage() :
    print("\nUsage:\n")
    print("\t" + prog + " [options] <host> <user> <password> <API> [ <paramname> <arg> ...]\n")
    print("\nOptions:\n")
    print("\t-i              API specified as XML input, on the command line\n")
    print("\t-I              API specified as XML input, on standard input\n")
    print("\t-t {type}       Server type(type = filer, dfm, ocum, agent)\n")
    print("\t-v {vfiler name | vserver name}	For vfiler-tunneling or vserver-tunneling \n")
    print("\t-n              Use HTTP\n")
    print("\t-p {port}       Override port to use\n")
    print("\t-x              Show the XML input and output\n")
    print("\t-X              Show the raw XML input and output\n")
    print("\t-c              Connection timeout\n")
    print("\t-h              Use Host equiv authentication mechanism.\n")
    print("\t-o {originator_id}       Pass Originator Id\n")
    print("\t-C {cert-file}  Client certificate file to use. The default is not to use certificate\n")
    print("\t-K {key-file}   Private key file to use. If not specified, then the certificate file will be used\n")
    print("\t-T {ca-file} File containing trusted certificate(s) to be used for server certificate verification\n")
    print("\t-S     Enable server certificate verification\n")
    print("\t-H     Enable hostname verification\n\n")
    print("Note: \n")
    print("     Use server type 'dfm' (-t dfm) for OnCommand Unified Manager server version 5.2 or earlier. \n")
    print("     Use server type 'ocum' (-t ocum) for OnCommand Unified Manager server version 6.0 or later. \n\n")
    print("     By default username and password shall be used for client authentication. \n")
    print("     Specify -C option for using Certificate Based Authentication(CBA). \n")
    print("     Server certificate and Hostname verification is disabled by default for CBA. \n")
    print("     All the certificates provided should be in PEM format.\n")
    print("     Do not provide username and password for -h or CBA options.\n")
    print("     The username or UID of the user administering the storage systems can be passed\n")
    print("     to ONTAP as originator-id for audit logging.\n\n")
    print("Examples:\n")
    print("            " + prog + " toaster root bread system-get-version\n")
    print("            " + prog + " -s toaster root bread system-get-version\n")
    print("            " + prog + " toaster root bread quota-report volume vol0\n")
    print("            " + prog + " -t dfm -C my_cert.pem -K my_key.pem amana dfm-about\n")
    print("            " + prog + " -t dfm -C my_cert.pem -K my_key.pem -S -T server_cert.pem amana dfm-about\n\n")
    sys.exit (1)


prog = sys.argv[0]
args = len(sys.argv) - 1

# check for valid number of parameters
if (args < 3):
    print_usage()

dodfm = None
doocum = None
dovfiler = None
doagent = None
dossl = 1
host_equiv = None
dofiler = None
option_set = None
showxml = 0
inputxml = 0
api = None
use_port = -1
server_type = "FILER"
vfiler_name = ""
set_timeout = 0
timeout = 0
send_oid = None
use_cba = 0
client_cert = None
client_key = None
ca_file = None
need_server_cert_verification = 0
need_hostname_verification = 0
opt = sys.argv[1]
i = 2

if(re.match(r'^-',opt)):
    option_set = 1

    while (re.match(r'^-',opt)):
        option = opt.split('-')
        if(option[1] == 'i'):
            inputxml = 1

        elif(option[1] == 'n'):
            dossl = None

        elif(option[1] == 'x'):
            showxml = 1

        elif(option[1] == 'X'):
            showxml = 2

        elif(option[1] == 'I'):
            inputxml = 2

        elif(option[1] == 'p'):
            use_port = int(sys.argv[i])
            i = i  + 1

        elif(option[1] == 'v'):
            vfiler_name = sys.argv[i]
            i = i + 1
            dovfiler = 1

        elif(option[1] == 't'):
            server_type =sys.argv[i]
            i = i + 1

            if (use_port == -1):

                if(server_type == "dfm"):
                    dodfm = 1
                    server_type = "DFM"

                if(server_type == "ocum"):
                    doocum = 1
                    dossl = 1
                    server_type = "OCUM"

                if(server_type == "agent"):
                    doagent = 1
                    server_type = "AGENT"

                if(server_type == "filer"):
                    dofiler = 1
                    server_type = "FILER"

        elif(option[1] == 'h'):
            host_equiv = 1

        elif(option[1] == 'c'):
            set_timeout = 1
            timeout = int(sys.argv[i])
            i = i + 1

        elif(option[1] == 'o'):
            originator_id = sys.argv[i]
            i = i + 1
            send_oid = 1

        elif(option[1] == 'C'):
            use_cba = 1
            dossl = 1
            cert_file = sys.argv[i]
            i = i + 1

        elif(option[1] == 'K'):
            client_key = sys.argv[i]
            i = i + 1

        elif(option[1] == 'T'):
            ca_file = sys.argv[i]
            i = i + 1

        elif(option[1] == 'S'):
            need_server_cert_verification = 1

        elif(option[1] == 'H'):
            need_hostname_verification = 1

        else:
            print_usage()

        opt = sys.argv[i]
        i = i + 1
        option = opt.split('-')

    if(option_set):
        host = opt

    else:
        host = sys.argv[i]
        i = i + 1

else :
    host = opt
   
if(args < 4 and host_equiv != 1):
    print_usage()

if ((dodfm or doocum) and dovfiler) :
    print ("The -v option is not a valid option for OnCommand Unified Manager server.\n")
    sys.exit (2)

if ((dodfm or doocum) and send_oid) :
    print ("The -o option is not a valid option for OnCommand Unified Manager server.\n")
    sys.exit (2)

if (use_port == -1) :

    if (dodfm) :

        if(dossl):
            use_port = 8488

        else:
            use_port = 8088

    elif (doocum) :

        use_port = 443

    elif (doagent) :

        if(dossl):
            use_port = 4093

        else:
            use_port = 4092

    else:

        if(dossl):
            use_port = 443

        else:
            use_port = 80


if(host_equiv != 1 and use_cba != 1) :

    if(i <= args-1):
        user  = sys.argv[i]
        i = i + 1
        password = sys.argv[i]
        i = i + 1
    
    else:
        print_usage()
		
if(inputxml != 2):
    
    if(i <= args):
        api = sys.argv[i]
        i = i + 1
    
    else:
        print_usage()

if (inputxml == 2) :

    if((args-i) > 0):
        print ("The -I option expects no API on the command-line, it expects standard input\n")
        print_usage()

    else :
        ## read from stdin
        #use Ctrl+X for termination
        ct = 0
		
        try:
            std_in=[]
            std_in.append(sys.stdin.readline().rstrip("\n"))
            ct = ct + 1
			
            while(std_in[ct-1]):
               std_in.append(sys.stdin.readline().rstrip("\n")) 
               ct = ct + 1
			   
        except KeyboardInterrupt:
               print() 
			   
        std_in = "".join(std_in)
        sys.argv.append(std_in[0:(len(std_in))])
   
    try:
        minidom.parseString(sys.argv[i])
		
    except:
        print("\nParse Error\n")
        sys.exit(1)
		
    api = sys.argv[i]
    i = i + 1

if (api == None and host_equiv != 1) :
    print("API not specified\n")
    print_usage()

if (need_hostname_verification == 1 and need_server_cert_verification == 0):
    print("Hostname verification cannot be enabled when server certificate verification is disabled.\n")
    sys.exit(2)

# Open server.Vfiler tunnelling requires ONTAPI version 7.0 to work.
# NaServer is called to connect to servers and invoke API's.
# The argument passed should be:
# NaServer(hostname, major API version number, minor API version number)
#

if(dovfiler):
    s = NaServer(host, 1, 7)

else:
    s = NaServer(host, 1, 0)

if ( s == None ) :
    print ("Initializing server elements failed.\n")
    sys.exit (3)

if (dossl == None) :

    response = s.set_transport_type('HTTP')

    if (response and response.results_errno() != 0) :
        r = response.results_reason()
        print ("Unable to set HTTPS transport" + r + "\n")
        sys.exit (2)

# Set the login and password used for authenticating when
# an ONTAPI API is invoked.
# When Host_equiv is  set,dont set username ,password

if(host_equiv != 1 and use_cba != 1):
    s.set_admin_user(user, password)


# Set the name of the vfiler on which the API
# commands need to be invoked.
#

if (dovfiler):
    s.set_vfiler(vfiler_name)

if (send_oid):
    s.set_originator_id(originator_id)

# Set the Type of API Server.
#
response = s.set_server_type(server_type)

if (response and response.results_errno() != 0) :
    r = response.results_reason()
    print ("Unable to set server transport" + r + "\n")
    sys.exit (2)

if(set_timeout == 1) :

    if(timeout > 0) :
        s.set_timeout(timeout)
    
    else :
        print ("Invalid value for connection timeout." + " Connection timeout value should be greater than 0.\n") 
        sys.exit (2)

#Set the style of the server

if(host_equiv == 1) :
    s.set_style("HOSTS")


if (use_cba == 1) :
    response = s.set_style("CERTIFICATE")
    if (response):
        print("Unable to set style: " + response.results_reason() + "\n")
        sys.exit(2)
    response = s.set_client_cert_and_key(cert_file, client_key)
    if (response):
        print(response.results_reason() + "\n")
        sys.exit(2)

if (dossl or need_server_cert_verification):
    response = s.set_server_cert_verification(need_server_cert_verification)
    if (response):
        print(response.results_reason() + "\n")
        sys.exit(2)
    if (need_server_cert_verification):
        response = s.set_hostname_verification(need_hostname_verification)
        if (response):
            print(response.results_reason() + "\n")
            sys.exit(2)

if (ca_file):
    response = s.set_ca_certs(ca_file)
    if (response):
        print(response.results_reason() + "\n")
        sys.exit(2)

#
# Set the TCP port used for API invocations on the server.
#
if (use_port != -1) :
    s.set_port(use_port)

# This is needed for -X option.
if (showxml == 2) :
    s.set_debug_style("NA_PRINT_DONT_PARSE")

if (inputxml > 0) :
	
    try :
        minidom.parseString(api)
		
    except:
        print("\nParse Error\n")
        sys.exit(1) 
		
    rxi = s.parse_raw_xml(api)

    if (showxml == 1) :
        print ("INPUT:\n" + rxi.sprintf() + "\n")

    rxo = s.invoke_elem(rxi)
    print ("\nOUTPUT: \n" + rxo.sprintf())
    sys.exit (5)

# Create a XML element to print

if (showxml == 1) :
    x = NaElement(api)
    length = args-i
	
    if((length & 1) != 0):
	
        while(i <= args):
            key = sys.argv[i]
            i = i + 1
            value = sys.argv[i]
            i = i + 1
            x.child_add(NaElement(key,value))

    else:
        print("Invalid number of parameters")
        print_usage()

    print("\nINPUT: \n" + x.sprintf())
    rxo = s.invoke_elem(x)
    print("\nOUTPUT: \n" + rxo.sprintf())
    sys.exit (5)


#
# invoke the api with api name and any supplied key-value pairs
#
x = NaElement(api)
length = args - i

if((length & 1) != 0):

    while(i <= args):
        key = sys.argv[i]
        i = i + 1
        value = sys.argv[i]
        i = i + 1
        x.child_add(NaElement(key,value))
else:
    print("Invalid number of parameters")
    print_usage()

rxo = s.invoke_elem(x)

if ( rxo == None ) :
    print ("invoke_api failed to host as user:password.\n")
    sys.exit(6)

if (showxml == 2) :
    print ("\nOUTPUT: \n" + rxo.sprintf())

else :
    print ("\nOUTPUT: \n" + rxo.sprintf() + "\n")





