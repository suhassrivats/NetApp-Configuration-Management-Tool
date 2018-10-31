#============================================================#
#                                                            #
# apitest.ps1                                                #
#                                                            #
# Exploratory application for testing Data ONTAP APIs.       #
# It lets you call any Data ONTAP API with name-value pair   #
#  of arguments.                                             #
#                                                            #
# Copyright 2002-2010 NetApp, Inc. All rights                #
# reserved. Specifications subject to change without notice. # 
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
# Usage:apitest [options] <host> <user> <password>           #
#       <ONTAPI-name> [<param-name> <value> ...]             #
#============================================================#

function PrintUsage
{
        write $("Usage: apitest.ps1 [options] <host> <user> <password> <ONTAPI-name> [<param-name> <value> ...]`n");
        write $("Options:");
        write $("`t -t {type} `t Server type(type = filer, dfm, ocum, agent)");
        write $("`t -v {vfiler name | vserver name}  For vfiler-tunneling or vserver-tunneling \n"); 
        write $("`t -r `t Use RPC transport");
        write $("`t -n `t Use HTTP");
        write $("`t -p {port} `t Override port to use");
        write $("`t -c {timeout} `t Connection timeout value in seconds");
	write $("`t -o {originator_id} `t Pass Originator Id");
        write $("`t -C {cert-file}    Location of the client certificate file");
        write $("`t -P {cert-passwd}  Password to access the client certificate file");
        write $("`t -T {cert-store-name} Client certificate store name. The default is 'My' store");
        write $("`t -L {cert-store-loc}  Client certificate store location. The default is 'CurrentUser'");
        write $("`t -N {cert-name}  Subject name of the client certificate in the certificate store");
        write $("`t -S `t Enable server certificate verification");
        write $("`t -H `t Enable hostname verification");
        write $("`t -i `t API specified as XML input, on the command line");
        write $("`t -I `t API specified as XML input, on standard input");
        write $("`t -x `t Show the XML input and output");
        write $("`t -X `t Show the raw XML input and output");
        write $("`t -h `t Use Host equiv authentication mechanism");
        write $("`n  Note:");
        write $("        Use server type 'dfm' (-t dfm) for OnCommand Unified Manager server version 5.2 or earlier.");
        write $("        Use server type 'ocum' (-t ocum) for OnCommand Unified Manager server version 6.0 or later.`n");
        write $("        By default username and password shall be used for client authentication.");
        write $("        Specify either -C, -P or -S, -L, -N options for using Certificate Based Authentication (CBA).");
        write $("        Server certificate and Hostname verification is disabled by default for CBA.")
        write $("        Do not provide username and password for -h, -r or CBA options.")
	write $("        The username or UID of the user administering the storage systems can be passed")
	write $("        to ONTAP as originator-id for audit logging.")
        write $("`nExamples:");
        write $("`t apitest sweetpea root tryme system-get-version");
        write $("`t apitest amana root meat quota-report volume vol0");
        write $("`t apitest -t dfm -C clientcert.pfx -P mypasswd amana dfm-about");
        write $("`t apitest -t dfm -T My -L CurrentUser -N ram amana dfm-about`n");
        exit(1);
}

# function which tries to load ManageONTAP.dll library which is typically at 
# <sdk-install-root>\lib\DotNet directory.
function LoadAssembly
{
    $cur = (pwd).path;
    $library = $cur + "\ManageOntap.dll"

    if((test-path $library) -eq $true) {
        [System.Reflection.Assembly] $Assembly = 
        [System.Reflection.Assembly]::LoadFrom($library);
        return;
    }
    $library = $cur + "\..\..\..\..\..\lib\DotNet\ManageOntap.dll";
    if((test-path $library) -eq $true) {
        [System.Reflection.Assembly] $Assembly = 
        [System.Reflection.Assembly]::LoadFrom($library);
    }
    else {
        Write("ERROR:Unable to find ManageONTAP.dll.");
        exit(1);
    }
    trap [Exception] { 
      write-error $("ERROR:" + $_.Exception.Message); 
      exit(1); 
   }
}      

Invoke-Expression LoadAssembly;

# Check for valid no. of command line arguments
if ($ARGS.Length -lt  3) {
Invoke-Expression PrintUsage;
}

# Declaration of NaServer and NaElement classes which are used 
# to invoke Data ONTAP APIs.
[NetApp.Manage.NaServer] $s;
[NetApp.Manage.NaElement] $xi;
[NetApp.Manage.NaElement] $xo;

$transportType = "HTTPS";
$serverType = "FILER";
$authStyle = "LOGIN_PASSWORD"
$storeName = "MY";
$storeLocation = "CURRENT_USER";

[int]$index = 0;
$showXML = 0;
$inputXML = 0;
[int]$port = -1;
[int]$timeOut = 0;
[int]$status = 0;
[int]$useRPC = 0;
[int]$useHostsEquiv = 0;
[String] $vfiler = "";
[String] $originatorId = "";
[String] $type = "";
[String] $readXML = "";
[bool] $useCBA = $false;
[bool] $verifyServerCert = $false;
[bool] $verifyHostname = $false;
[String] $certFile = "";
[String] $certPasswd = "";
[String] $certName = "";
[int] $snoopLevel = 1;
#Parse the command line arguments
while ($index -lt $ARGS.Length -and $ARGS[$index][0] -eq "-") {
    switch -casesensitive ($ARGS[$index][1]) {
        "t" {
                $type = $ARGS[$index+1];
                if ($type -eq "dfm") {
                    $serverType = "DFM";
                }
                elseif ($type -eq "ocum"){
                    $serverType = "OCUM";
					$transportType = "HTTPS";
                }
                elseif ($type -eq "agent"){
                    $serverType = "AGENT";
                }
                elseif ($type -eq "filer") {
                    $serverType = "FILER";
                }
                else{
                    Write("`nERROR: Invalid Option for Server type.");
                    Invoke-Expression PrintUsage;
                }
                $index = $index + 2;
            }
        "v" {
                $vfiler = $ARGS[$index+1];
                $index = $index + 2;
            }
        "r" {
                $authStyle = "RPC";
                $useRPC = 1;
                $index++;
            }
        "n" {
                $transportType = "HTTP";
                $index++;
            }
        "i" {
                $inputXML = 1;
                $index++;  
            }
        "I" {
                $inputXML = 2;
                $index++;                            
            }
        "x" {
                $showXML = 1;
                $index++;
            }
        "X" {
                $showXML = 2;
                $index++;
            }
        "h" {
                $authStyle = "HOSTSEQUIV";
                $useHostsEquiv = 1;
                $index++;
            }
        "p" {
                [int] $port = $ARGS[$index+1];
                if($port -le 0) {
                    Write $("`nERROR: Invalid port number.");
                    exit(1);
                }
                trap [Exception] { 
                    write-error $("ERROR: Invalid port number. " + $_.Exception.Message); 
                    exit(1); 
                }
                $index = $index + 2;
            }
        "c" {
                $timeOut = $ARGS[$index+1];
                if($timeOut -le 1) {
                    write $("`nERROR: Invalid timeout value.");
                    exit(1);
                 }
                 $index = $index + 2;
            }
	"o" {
                $originatorId = $ARGS[$index+1];
                $index = $index + 2;
            }
        "C" {
                $useCBA = $true;
                $certFile = $ARGS[$index + 1];
                $index = $index + 2;
            }
        "P" {
                $useCBA = $true;
                $certPasswd = $ARGS[$index + 1];
                $index = $index + 2;
            }
        "T" {
                [String] $name = $ARGS[$index + 1];
                $useCBA = $true;
                if($name -eq "AuthRoot") {
                    $storeName = "AUTH_ROOT";
                }
                elseif($name -eq "CertificateAuthority") {
                    $storeName = "CERTIFICATE_AUTHORITY";
                }
                elseif($name -eq "My") {
                    $storeName = "MY";
                }
                elseif($name -eq "Root") {
                    $storeName = "ROOT";
                }
                elseif($name -eq "TrustedPeople") {
                    $storeName = "TRUSTED_PEOPLE";
                }
                else {
                    Write $("Invalid store name: " + $name);
                    Write $("Valid store names are: ");
                    Write $("My - certificate store for personal certificates");
                    Write $("Root - certificate store for trusted root certificate authorities");
                    Write $("AuthRoot - certificate store for third-party certificate authorities");
                    Write $("CertificateAuthority - certificate store for intermediate certificate authorities");
                    Write $("TrustedPeople - certificate store for directly trusted people and resources\n");
                    Invoke-Expression PrintUsage;
                }
                $index = $index + 2;
            }
        "L" {
                [String] $location = $ARGS[$index + 1];
                $useCBA = $true;
                if($location -eq "CurrentUser") {
                    $storeLocation = "CURRENT_USER";
                }
                elseif($location -eq "LocalMachine") {
                    $storeLocation = "LOCAL_MACHINE";
                }
                else {
                    Write $("Invalid store lcoation: " + $name);
                    Write $("Valid store locations are: ")
                    Write $("CurrentUser - certificate store used by the current user")
                    Write $("LocalMachine - certificate store assigned to the local machine")
                    Invoke-Expression PrintUsage;
                }
                $index = $index + 2;
            }
        "N" {
                $certName = $ARGS[$index + 1];
                $useCBA = $true;
                 $index = $index + 2;
            }
        "S" {
                $verifyServerCert = $true;
                $index++;
            }
        "H" {
                $verifyHostname = $true;
                $index++;
            }
            default {
                Write $("`nERROR: Invalid Option.");
                Invoke-Expression PrintUsage;   
            }
        } 
} 

    if ($authStyle -eq "LOGIN_PASSWORD" -and $ARGS.Length -lt 4) {
                Invoke-Expression PrintUsage;
    }

    if ($useHostsEquiv -eq 1 -and $useRPC -eq 1) {
                Write ("`nERROR: Invalid usage of authentication style.
                Do not use -r option and -h option together.`n");
                exit(1);
    }
	if ($useRPC -eq 1 -and $timeOut -gt 0) {
                Write ("`nERROR: Connection timeout value cannot be 
                set for RPC authentication style.`n");
                exit(1);
    }
    if ($verifyHostname -and !$verifyServerCert) {
            Write ("`nERROR: Hostname verification cannot be enabled when server certificate verification is disabled.`n")
            exit(1);
    }
    if ($index -eq $ARGS.Length)
    {
            Write ("`nERROR: Host not specified.");
            Invoke-Expression PrintUsage;
    }
    if ($useCBA) {
        $transportType = "HTTPS";
        $authStyle = "CERTIFICATE";
    }
    if ($authStyle -eq "LOGIN_PASSWORD") {
            
                if (($index+1) -eq $ARGS.Length) {
                    Write ("`nERROR: User not specified.");
                    Invoke-Expression PrintUsage;
                }
                elseif (($index+2) -eq $ARGS.Length) {
                    Write("`nERROR: Password not specified.");
                    Invoke-Expression PrintUsage;
                }
    }

    if ($port -eq -1) {
        if($serverType -eq "DFM") {
            if($transportType -eq "HTTP") {
                $port = 8088;
            }
            else {
                $port = 8488;
            }
        }
        elseif($serverType -eq "OCUM") {
            $port = 443;
        }
		elseif($serverType -eq "AGENT") {
            if($transportType -eq "HTTP") {
                $port = 4092;
            }
            else {
                $port = 4093;
            }
        }
        else {
            if($transportType -eq "HTTP") {
                $port = 80;
            }
            else {
                $port = 443;
            }
    }
}
                        
if ($vfiler -ne "") {
    $s = New-Object NetApp.Manage.NaServer($ARGS[$index], 1, 7);
    $s.SetVfilerTunneling($vfiler);
}
else {
    $s = New-Object NetApp.Manage.NaServer($ARGS[$index], 1, 0);
}

if ($originatorId -ne "") {
    $s.OriginatorId = $originatorId;
}

$s.ServerType = $serverType;
$s.TransportType = $transportType;
$s.Style = $authStyle;
    
if ($authStyle -eq  "LOGIN_PASSWORD") {
    $s.SetAdminUser($ARGS[++$index],$ARGS[++$index]);
}
    
$s.Port = $port;

if ($useCBA) {
    if (!$certFile -and $certPasswd) {
      Write ("`nERROR: Certificate file not specified.");
      Invoke-Expression PrintUsage;
    }
    if($certFile) {
        if ($certPasswd) {
            $s.SetClientCertificate($certFile, $certPasswd);
        }
        else {
            $s.SetClientCertificate($certFile);
        }
    }
    else {
        $s.SetClientCertificate($storeName, $storeLocation, $certName);
    }
}
$s.ServerCertificateVerification = $verifyServerCert;
if ($verifyServerCert) {
    $s.HostnameVerification = $verifyHostname;
}
$s.Snoop = $snoopLevel;

if ($timeOut -gt 0) {
    $s.TimeOut = $timeOut;
}

if ($inputXML -eq 0) {
    if (($index+1) -eq $ARGS.Length) {
        Write("`nERROR: API not specified.");
        Invoke-Expression PrintUsage;
    }
    $xi = New-Object NetApp.Manage.NaElement($ARGS[++$index]);

    if ($ARGS.Length -gt $index+1) {
        [int] $index2 = 0;
        for ($index2 = $index+1;$index2 -lt $ARGS.Length;$index2++) {
            $xi.AddNewChild($ARGS[$index2], $ARGS[$index2+1]);
            $index2++;
        }
    }
}
else {
    if ($inputXML -eq 1) {
        if ($ARGS.Length -eq $index+1) {
            Write("API not specified");
            Invoke-Expression PrintUsage;
        }
        [int] $index2 = 0;
        for ($index2 = $index+1;$index2 -lt $ARGS.Length;$index2++) {
            $readXML = $readXML + $ARGS[$index2];
        }
    }
    else {
        write("Enter the input XML:");
        [String] $curLine;
        while (($curLine = [Console]::ReadLine()) -ne $null) {
            $readXML += $curLine;
        }
    }
    [String] $args2 = $readXML.split(" `t`n`r");
    $readXML = "";
    for ($index2 = 0; $index2 -lt $args2.Length; $index2++) {
        if (!($args2[$index2] -ccontains "`t"  -or $args2[$index2] -ccontains " ")) {
            $readXML = $readXML + $args2[$index2];
        }
    }
    $args2 = $readXML.split("`t`n");
    $xi = $s.ParseXMLInput($args2);
}

if ($showXML -gt 0)	{
    if ($showXML -eq 1) {
        write("INPUT:`n" + $xi.ToPrettyString(""));
    }
    else{
        $s.DebugStyle = "PRINT_PARSE";
    }
}
$xo = $s.InvokeElem($xi);
if ($showXML -gt 0) {
    if ($showXML -eq 2) {
    return;
    }
    write("OUTPUT:");   
}                    
write($xo.ToPrettyString(""));
 
trap [Exception] { 
      write-error $("ERROR:" + $_.Exception.Message); 
      exit(1); 
}
