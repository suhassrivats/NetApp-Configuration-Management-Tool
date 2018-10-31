#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# vollist.ps1                                                #
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
if($ARGS.Length -lt 3)
{
   write $("Usage: vollist.ps1 <filer> <user> <passwd> [<vol-name>]");
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

[NetApp.Manage.NaServer] $s = New-Object NetApp.Manage.NaServer ($ARGS[0],"1","0")
$s.SetAdminUser($ARGS[1],$ARGS[2])
[NetApp.Manage.NaElement] $in =  New-Object NetApp.Manage.NaElement("volume-list-info");

if($ARGS.Length -gt 3)
{
    $in.AddNewChild("volume",$ARGS[3])
}

[NetApp.Manage.NaElement] $out = $s.InvokeElem($in); 

[System.Collections.IList] $volList =  $out.GetChildByName("volumes").GetChildren();
[System.Collections.IEnumerator] $volIter = $volList.GetEnumerator();

write $("`n---------------------------------------------------------------------"); 
write $("Volume `t`t State `t Size-total `t Size-Avail `t Size-used"); 
write $("---------------------------------------------------------------------"); 
while($volIter.MoveNext()){
[NetApp.Manage.NaElement] $volInfo = $volIter.Current;
write ($volInfo.GetChildContent("name") + "`t`t" + $volInfo.GetChildContent("state") + "`t" + $volInfo.GetChildContent("size-total") + "`t" + $volInfo.GetChildContent("size-available")+ "`t" + $volInfo.GetChildContent("size-used"));
}
write $("---------------------------------------------------------------------`n"); 
trap [Exception] { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
   }
   
