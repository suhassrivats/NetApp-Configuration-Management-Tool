#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# encrypt_string.ps1                                         #
#                                                            #
# Application which uses ONTAPI APIs to get snapshot lists,  #
# schedules, create, rename and delete snapshots.            #
#                                                            #
# Copyright 2009 NetApp. All rights reserved. Specifications #
# subject to change without notice.                          # 
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
#                                                            #
# See PrintUsage for command-line syntax.                    #
#                                                            #
#============================================================#

if($ARGS.Length -lt 4)
{
   write $("Usage: hello_ontapi.ps1 <filer> <user> <passwd> <test-password>");
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

LoadAssembly;

$s = New-Object NetApp.Manage.NaServer ($ARGS[0],"1","0");
$s.SetAdminUser($ARGS[1],$ARGS[2]);

$xi = New-Object NetApp.Manage.NaElement("test-password-set");
$xi.AddNewEncryptedChild("password", $ARGS[3]);

write $("`nINPUT XML with encrypted password:");
$output = $xi.ToString();
write ($output);

[NetApp.Manage.NaElement] $xo = $s.InvokeElem($xi);

write $("`nOUTPUT XML with decrypted password:");
$output = $xo.ToString();
write($output);

$decPasswd = $xi.GetChildEncryptContent("password");
write $("`nRESULT: Expected decrypted password from server:" + $decPasswd + "`n");

trap [Exception] { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
   }
   
