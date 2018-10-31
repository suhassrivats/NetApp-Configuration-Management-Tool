#============================================================
#
# $ID$
#
# apitest.rb
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

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage
    print("\nUsage:\n")
    print("\t" + $0 + " [options] <host> <user> <password> <API> [ <paramname> <arg> ...]\n")
    print("\nOptions:\n")
    print("\t-i              API specified as XML input, on the command line\n")
    print("\t-I              API specified as XML input, on standard input\n")
    print("\t-t {type}       Server type(type = filer, dfm, ocum, agent)\n")
    print("\t-v {vfiler name | vserver name} For vfiler-tunneling or vserver-tunneling\n")
    print("\t-n              Use HTTP\n")
    print("\t-p {port}       Override port to use\n")
    print("\t-x              Show the XML input and output\n")
    print("\t-X              Show the raw XML input and output\n")
    print("\t-c              Connection timeout\n")
    print("\t-h              Use Host equiv authentication mechanism. Do not provide username, password with -h option\n")
    print("\t-o {originator-id}       Pass Originator Id\n")
    print("\t-C {cert-file}  Client certificate file to use. The default is not to use certificate\n")
    print("\t-K {key-file}   Private key file to use. If not specified, then the certificate file will be used\n")
    print("\t-P {key-passwd} Passphrase to access the private key file\n")
    print("\t-T {ca-file} File containing trusted certificate(s) to be used for server certificate verification\n")
    print("\t-S     Enable server certificate verification\n")
    print("\t-H     Enable hostname verification\n")
    print("Note: \n")
    print("     Use server type 'dfm' (-t dfm) for OnCommand Unified Manager server version 5.2 or earlier. \n")
    print("     Use server type 'ocum' (-t ocum) for OnCommand Unified Manager server version 6.0 or later. \n\n")
    print("     By default username and password shall be used for client authentication. \n")
    print("     Specify -C option for using Certificate Based Authentication(CBA). \n")
    print("     Server certificate and Hostname verification is disabled by default for CBA. \n")
    print("     -T option can also be used for building the client certificate chain.\n")
    print("     All the certificates provided should be in PEM format.\n")
    print("     Do not provide username and password for -h, -r or CBA options.\n")
    print("     The username or UID of the user administering the storage systems can be passed\n")
    print("     to ONTAP as originator-id for audit logging.\n\n")
    print("Examples:\n")
    print("                        " + $0 + " toaster root bread system-get-version\n")
    print("                        " + $0 + " -s toaster root bread system-get-version\n")
    print("                        " + $0 + " toaster root bread quota-report volume vol0\n")
    print("                        " + $0 + " -t dfm -C my_cert.pem -K my_key.pem -P keypasswd amana dfm-about\n")
    print("                        " + $0 + " -t dfm -C my_cert.pem -K my_key.pem -P keypasswd -S -T server_cert.pem amana dfm-about\n\n")
    exit 
end

args = ARGV.length
# check for valid number of parameters
if (args < 3)
    print_usage()
end
dodfm = false
doocum = false
dovfiler = false
doagent = false
dossl = true
host_equiv = false
dofiler = false
option_set = nil
xo = nil
arr = nil
xi = nil
save_arg = nil
index = nil
showxml = nil
inputxml = nil
api = nil
use_port = -1
server_type = "FILER"
vfiler_name = ""
set_timeout = 0
timeout = 0
send_oid = false
originator_id = ""
use_cba = false
cert_file = nil
key_file = nil
key_passwd = nil
need_server_cert_verification = false
need_hostname_verification = false
ca_file = nil
opt = ARGV.shift
i = 2

if(opt =~ /-/)
    option_set = 1	
    while(opt =~ /^-/)
        option = opt.split('-')
        if(option[1] == 'i')
            inputxml = 1
        elsif(option[1] == 'n')
            dossl = false
        elsif(option[1] == 'x')
            showxml = 1
        elsif(option[1] == 'X')
            showxml = 2
        elsif(option[1] == 'I')
            inputxml = 2
        elsif(option[1] == 'p')
            use_port = ARGV.shift
        elsif(option[1] == 'v')
            vfiler_name = ARGV.shift
            dovfiler = true
        elsif(option[1] == 't')
            server_type =ARGV.shift
            i = i + 1
            if (use_port == -1)
                if(server_type == "dfm")
                    dodfm = true
                    server_type = "DFM"
                elsif(server_type == "ocum")
                    doocum = true
                    dossl = true
                    server_type = "OCUM"
                elsif(server_type == "agent")
                    doagent = true
                    server_type = "AGENT"
                elsif(server_type == "filer")
                    dofiler = true
                    server_type = "FILER"
                end
            end
        elsif(option[1] == 'h')
            host_equiv = true
        elsif(option[1] == 'c')
            set_timeout = 1
            timeout = Integer(ARGV.shift)
        elsif(option[1] == 'o')
            originator_id = ARGV.shift
            send_oid = true
        elsif(option[1] == 'C')
            cert_file = ARGV.shift
            use_cba = true
            dossl = true
        elsif(option[1] == 'K')
            key_file = ARGV.shift
        elsif(option[1] == 'P')
            key_passwd = ARGV.shift
        elsif(option[1] == 'T')
            ca_file = ARGV.shift
        elsif(option[1] == 'S')
            need_server_cert_verification = true
        elsif(option[1] == 'H')
            need_hostname_verification = true
        else
            print_usage()
    end
    opt = ARGV.shift
    option = opt.split('-')
    end
    host = option_set ? opt : ARGV.shift
else 
    host = opt
end
if(args < 4 and host_equiv.eql?(false))
    print_usage() 
end
if((dodfm or doocum) and dovfiler) 
    print ("The -v option is not a valid option for OnCommand Unified Manager server.\n")
    exit 
end

if((dodfm or doocum) and send_oid)
    print ("The -o option is not a valid option for OnCommand Unified Manager server.\n")
    exit
end

if (use_port == -1) 
    if (dodfm) 
        use_port = dossl ? 8488 : 8088
    elsif (doocum) 
        use_port = 443
    elsif (doagent) 
        use_port = dossl ? 4093 : 4092
    else
        use_port = dossl ? 443 : 80
    end
end

if(host_equiv.eql?(false) and use_cba.eql?(false))
    user  = ARGV.shift
    password = ARGV.shift
end
if(inputxml != 2)
    if(ARGV.length  > 0)
        api = ARGV.shift
    else
        print_usage()
    end
end
if (inputxml == 2) 
    if(ARGV.length > 0)
        print ("The -I option expects no API on the command-line, it expects standard input\n")
        print_usage()
    else 
        ## read from stdin
        std_in = $stdin.read
        api_array = std_in.split(' ')
        api = api_array.join()
    end
    api = api.to_s
end

#
# Open server.Vfiler tunnelling requires ONTAPI version 7.0 to work.
# NaServer is called to connect to servers and invoke API's.
# The argument passed should be:
# NaServer(hostname, major API version number, minor API version number)
#
s = (dovfiler) ? NaServer.new(host, 1, 7): NaServer.new(host, 1, 0)
if(not s)
    print("Initializing server elements failed.\n")
    exit
end
if (dossl) 
    response = s.set_transport_type("HTTPS")
    if(response and response.results_errno != 0)
        r = response.results_reason()
        print("Unable to set HTTPS transport ",r,"\n")
        exit
    end
else
    s.set_transport_type("HTTP")
end

#
# Set the login and password used for authenticating when
# an ONTAPI API is invoked.
# When Host_equiv is  set,dont set username ,password
#
if(host_equiv.eql?(false) and use_cba.eql?(false))
    s.set_admin_user(user, password)
end

#
# Set the name of the vfiler on which the API 
# commands need to be invoked.
#
if (dovfiler) 
    s.set_vfiler(vfiler_name)
end

if (send_oid)
    s.set_originator_id(originator_id)
end

#
# Set the Type of API Server.
#
response = s.set_server_type(server_type)
if(response and response.results_errno != 0)
    r = response.results_reason()
    print("Unable to set server type ",r,"\n")
    exit 
end

if (use_cba.eql?(true))
    response = s.set_style("CERTIFICATE")
    if (response)
        print ("Unable to set style: " + response.results_reason() + "\n")
        exit
    end
    response = s.set_client_cert_and_key(cert_file, key_file, key_passwd)
    if (response)
        print response.results_reason() + "\n"
        exit
    end
end

if (dossl.eql?(true))
    response = s.set_server_cert_verification(need_server_cert_verification)
    if (response)
        print (response.results_reason() + "\n")
        exit
    end
    if (need_server_cert_verification)
        response = s.set_hostname_verification(need_hostname_verification)
        if (response)
            print (response.results_reason() + "\n")
            exit
        end
    end
end

if (ca_file)
    response = s.set_ca_certs(ca_file)
    if (response)
        print (response.results_reason() + "\n")
        exit
    end
end


#
# Set the TCP port used for API invocations on the server.
#
if (use_port != -1) 
    s.set_port(use_port) 
end
if(set_timeout == 1)
    if(timeout > 0)
        s.set_timeout(timeout)
    else
        print("Invalid value for connection timeout.. Connection timeout value should be greater than 0.\n")
        exit 
    end
end

#
#Set the style of the server
#
if(host_equiv.eql?(true)) 
    s.set_style("HOSTS")
end

# This is needed for -X option.
if (showxml == 2) 
    s.set_debug_style("NA_PRINT_DONT_PARSE") 
end
if (inputxml.to_i > 0) 	
    rxi = s.parse_raw_xml(api)	
    if (showxml == 1) 
        print("INPUT:\n" + rxi.sprintf() + "\n") 
    end
    rxo = s.invoke_elem(rxi)
    print("\nOUTPUT:\n" + rxo.sprintf() + "\n")
    exit 
end

# Create a XML element to print 
if (showxml == 1) 
    #save_arg = ARGV
    length = ARGV.length - 1
    xi = NaElement.new(api)
    if((length&1) != 0)
        while(ARGV.length > 0)
            key = ARGV.shift
            value = ARGV.shift
            xi.child_add(NaElement.new(key, value))
        end
    else
        print("\nInvalid number of Parameters\n")
        print_usage()
    end
    print("\nINPUT: \n" + xi.sprintf() + "\n")
    rxo = s.invoke_elem(xi)
    print("\nOUTPUT: \n" + rxo.sprintf())
    exit
end

#
# invoke the api with api name and any supplied key-value pairs
#
x = NaElement.new(api)
length =ARGV.length - 1
if((length & 1) != 0)
    while(ARGV.length > 0)
        key = ARGV.shift
        value = ARGV.shift
        x.child_add(NaElement.new(key, value))
    end
else
    print("\nInvalid number of parameters\n")
    print_usage()
end
rxo = s.invoke_elem(x)
if(not rxo)
    print("invoke_api failed to host as user:password.\n")
    exit 
end
if (showxml == 2) 
    print("\nOUTPUT: \n" + rxo.sprintf())
else 
    print("\nOUTPUT: \n" + rxo.sprintf() + "\n")
end
