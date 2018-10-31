#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# nfs.ps1                                                    #
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
function Usage
{
   write $("Usage : nfs <filer> <user> <passwd> <operation>");
   write $("<filer>	-- Name/IP address of the filer");
   write $("<user>	-- User Name");
   write $("<passwd>	-- Password");
   write $("<operation>	--");
   write $("           enable - To enable NFS Service");
   write $("           disable - To disable NFS Service");
   write $("           status - To print the status of NFS Service");
   write $("           list - To list the NFS export rules");
}


if($ARGS.Length -lt 4)
{
   Usage;	
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

switch ($ARGS[3]) 
    { 
		default {"Error: Invalid operation!"}

        "enable" { 
			$in =  New-Object NetApp.Manage.NaElement("nfs-enable");
			$out = $s.InvokeElem($in); 
			write $("NFS enabled successfully!");
        } 
        "disable" {
			$in =  New-Object NetApp.Manage.NaElement("nfs-disable");
			$out = $s.InvokeElem($in); 
			write $("NFS Disabled successfully!");
		} 
        "status" {
			$in =  New-Object NetApp.Manage.NaElement("nfs-status");
			$out = $s.InvokeElem($in);
			$enabled = $out.GetChildContent("is-enabled");
			if ($enabled -eq "true")
			{
			    write $("NFS Server is enabled");
			}
			else
			{
			    write $("NFS Server is disabled");
			}
		} 
        "list" {
			$xi =  New-Object NetApp.Manage.NaElement("nfs-exportfs-list-rules");
	        [NetApp.Manage.NaElement] $xo = $s.InvokeElem($xi);
	    				
			[System.Collections.IList] $retList = $xo.GetChildByName("rules").GetChildren();
	        			
	   	    [System.Collections.IEnumerator] $retIter = $retList.GetEnumerator();
	    				
			while ($retIter.MoveNext())
			{
	    					
			    [NetApp.Manage.NaElement] $retInfo = [NetApp.Manage.NaElement] $retIter.Current;
				$pathName = $retInfo.GetChildContent("pathname");
				$rwList = "rw=";
				$roList = "ro=";
				$rootList = "root=";
	    		#write $retInfo.ToPrettyString(""); exit(0);
				
				if ($retInfo.GetChildByName("read-only"))
				{
					
				    [NetApp.Manage.NaElement] $ruleElem = $retInfo.GetChildByName("read-only"); 
				    [System.Collections.IList] $hosts = $ruleElem.GetChildren();
				    [System.Collections.IEnumerator] $hostIter = $hosts.GetEnumerator();
				    while ($hostIter.MoveNext())
				    {
					    [NetApp.Manage.NaElement] $hostInfo = [NetApp.Manage.NaElement] $hostIter.Current;
					    if ($hostInfo.GetChildContent("all-hosts"))
					    {
						    $allHost = $hostInfo.GetChildContent("all-hosts");
						    if ($allHost -eq "true")
						    {
							    $roList = $roList + "all-hosts";
							    break;
						    }
					    }
					    else 
						{
							if ($hostInfo.GetChildContent("name")) {
								$roList = $roList + $hostInfo.GetChildContent("name") + ":";
							}
						}
				    }
			    }
				
				if ($retInfo.GetChildByName("read-write"))
				{
					[NetApp.Manage.NaElement] $ruleElem = $retInfo.GetChildByName("read-write");
					[System.Collections.IList] $hosts = $ruleElem.GetChildren();
				    [System.Collections.IEnumerator] $hostIter = $hosts.GetEnumerator();
				    while ($hostIter.MoveNext())
				    {
	    			    [NetApp.Manage.NaElement] $hostInfo = [NetApp.Manage.NaElement] $hostIter.Current;
					    if ($hostInfo.GetChildContent("all-hosts"))
					    {
						    $allHost = $hostInfo.GetChildContent("all-hosts");
						    if ($allHost -eq "true")
						    {
								$rwList = $rwList + "all-hosts";
								break;
						    }
					    }
					    else 
						{
							if ($hostInfo.GetChildContent("name")) {
								$rwList = $rwList + $hostInfo.GetChildContent("name") + ":";
							}
						}
					}
				}
				
			    if ($retInfo.GetChildByName("root"))
			    {
				    [NetApp.Manage.NaElement] $ruleElem = $retInfo.GetChildByName("root");
				    [System.Collections.IList] $hosts = $ruleElem.GetChildren();
				    [System.Collections.IEnumerator] $hostIter = $hosts.GetEnumerator();
				    while ($hostIter.MoveNext())
				    {
					    [NetApp.Manage.NaElement] $hostInfo = [NetApp.Manage.NaElement] $hostIter.Current;
					    if ($hostInfo.GetChildContent("all-hosts"))
					    {
						    $allHost = $hostInfo.GetChildContent("all-hosts");
						    if ($allHost -eq "true")
						    {
							    $rootList = $rootList + "all-hosts";
							    break;
						    }
					    }
						else 
						{
							if ($hostInfo.GetChildContent("name")) {
								$rootList = $rootList + $hostInfo.GetChildContent("name") + ":";
							}
						}
				    }
				}

			    if ($roList -ne "ro=")
			    {
				    $pathName = $pathName + ", `t" + $roList;
			    }
			    if ($rwList -ne "rw=")
			    {
					$pathName = $pathName + ",  `t" + $rwList;
			    }
			    if ($rootList -ne "root=")
			    {
	                $pathName = $pathName + ",  `t" + $rootList;
			    }
	   					
			    write ($pathName);
			}

		}
    }

trap [Exception] { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
   }
