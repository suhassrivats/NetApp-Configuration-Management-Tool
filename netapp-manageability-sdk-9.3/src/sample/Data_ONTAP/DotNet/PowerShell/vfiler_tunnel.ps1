#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# vfiler_tunnel.ps1                                          #
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
function usage
{
	write $("`nUsage:vfiler-tunnel {options} <vfiler-name> <filer> <user> <password> <ONTAPI-name> [key value] ...");
	write $("`nOptions:");
	write $("`n -s Use SSL`n");
	Exit(1);
}

if($ARGS.Length -lt 3)
{
   usage;
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

$index=$ARGS[0].IndexOf('-');
if($index -eq 0 -and $ARGS[0][$index] -eq  '-'){
    $options=$ARGS[0].Substring($index+1);
    if($options -eq "s" -and $ARGS.Length -gt 5){
	    $dos1=1;
    }else {
	    usage;
    }
}

if($dos1 -eq 1)
{
    # Initialize connection to server, and
    # request version 1.7 of the API set for vfiler-tunneling
	
	$s = New-Object NetApp.Manage.NaServer ($ARGS[2],"1","7");
	$s.SetAdminUser($ARGS[3],$ARGS[4]);
	$s.TransportType = "HTTPS";
	$s.SetVfilerTunneling($ARGS[1]);
                    
	# Invoke any  ONTAPI API with arguments
	# in (key,value) pair
	# args[0]=option,args[1]=vfiler-name,args[2]=vfiler,
	# args[3]=user,args[4] = passwd, args[5]=Ontapi API,
	# args[6] onwards arguments in (key,value)
	# pair
	#
	$xi = New-Object NetApp.Manage.NaElement($ARGS[5]);
    if($ARGS.Length -gt 6){
	    for($index1=6;$index1 -lt $ARGS.Length;$index1++){
     	    $xi.AddNewChild($ARGS[$index1], $ARGS[$index1+1]);
			$index1++;
		}
	}
}
else 
{
    #Initialize connection to server, and
    #request version 1.7 of the API set for vfiler-tunneling
    #
    $s = New-Object NetApp.Manage.NaServer($ARGS[1],1,7);
    $s.SetAdminUser($ARGS[2], $ARGS[3]);
	$s.TransportType = "HTTP";
    $s.SetVfilerTunneling($ARGS[0]);

    # Invoke any  ONTAPI API with arguments
    # in (key,value) pair
    # args[0]=filer,args[1]=user,args[2]=passwd
    # args[3]=Ontapi API,args[4] onward arguments
    #
    $xi = New-Object NetApp.Manage.NaElement($ARGS[4]);
    if($ARGS.Length -gt 5){
	    for($index2=5;$index2 -lt $ARGS.Length;$index2++){
			$xi.AddNewChild($ARGS[$index2], $ARGS[$index2+1]);
			$index2++;
	    }
	}
}

[NetApp.Manage.NaElement] $xo = $s.InvokeElem($xi);
write $xo.ToPrettyString("");

trap [Exception] { 
      write-error $("ERROR! " + $_.Exception.Message); 
      exit(1); 
   }
