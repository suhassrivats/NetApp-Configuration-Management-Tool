#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# snapman.ps1                                                #
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

function PrintUsage
{
        write("Usage: snapman.ps1 <filer> <user> <passwd> <vol> <options> ");
        write("Possible options are: create rename delete schedule");
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

if($ARGS.Length -lt 5)
{
    PrintUsage;
}
   
Invoke-Expression LoadAssembly;

$cmdArgs = $ARGS;
$serverName = $cmdArgs[0];
$user = $cmdArgs[1];
$passwd = $cmdArgs[2];
$volume = $cmdArgs[3];
$snapshot = "";

function CreateSnapshot
{
    if($cmdArgs.Length -lt 6) 
    {
        Write("Invalid number of arguments.");
        Write("Usage: snapman.ps1 <filer> <user> <passwd> <vol> create <snapshot-name> ");
        exit(1);
     }
    [NetApp.Manage.NaServer] $server = 
    New-Object NetApp.Manage.NaServer($serverName,"1","0");
    [NetApp.Manage.NaElement] $input = 
    New-Object NetApp.Manage.NaElement("snapshot-create");
    [NetApp.Manage.NaElement] $output = $null;

    $server.SetAdminUser($user, $passwd)
    $snapshot = $cmdArgs[5];
    $input.AddNewChild("volume", $volume);
    $input.AddNewChild("snapshot", $snapshot);
    $output = $server.InvokeElem($input)
    write("Snapshot " + $snapshot + " created for volume " + $volume + " on filer " + $serverName);
    trap [Exception] 
    { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
    }
}

function DeleteSnapshot
{
     if($cmdArgs.Length -lt 6) 
    {
        Write("Invalid number of arguments.");
        Write("Usage: snapman.ps1 <filer> <user> <passwd> <vol> delete <snapshot-name> ");
        exit(1);
    }
    $snapshot = $cmdArgs[5];
    [NetApp.Manage.NaServer] $server = 
    New-Object NetApp.Manage.NaServer($serverName,"1","0");
    [NetApp.Manage.NaElement] $input = 
    New-Object NetApp.Manage.NaElement("snapshot-delete");
    [NetApp.Manage.NaElement] $output = $null;

    $server.SetAdminUser($user, $passwd)
    $input.AddNewChild("volume", $volume);
    $input.AddNewChild("snapshot", $snapshot);
    $output = $server.InvokeElem($input);
    write("Snapshot " + $snapshot + " deleted from volume " + $volume + " on filer " + $serverName)
    
    trap [Exception] 
    { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
    }
}

function RenameSnapshot
{
    if ($cmdArgs.Length -lt 7) 
    {
        Write("Invalid number of arguments.");
        Write("Usage: snapman.ps1 <filer> <user> <passwd> <vol> rename <old-snapshot-name> <new-snapshot-name>");
        exit(1);
    }

    $oldSnapshot = $cmdArgs[5];
    $newSnapshot = $cmdArgs[6];
    [NetApp.Manage.NaServer] $server = 
    New-Object NetApp.Manage.NaServer($serverName,"1","0");
    [NetApp.Manage.NaElement] $input = 
    New-Object NetApp.Manage.NaElement("snapshot-rename");
    [NetApp.Manage.NaElement] $output = $null;
 
    $server.SetAdminUser($user, $passwd)
    $input.AddNewChild("volume", $volume);
    $input.AddNewChild("current-name", $oldSnapshot);
    $input.AddNewChild("new-name", $newSnapshot);
    $output = $server.InvokeElem($input);
    write("Snapshot " + $oldSnapshot + " renamed to " + $newSnapshot + " for volume " + $volume + " on filer " + $serverName);
    
    trap [Exception] 
    { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
    }
}

function ListInfo
{
    [NetApp.Manage.NaServer] $server = 
    New-Object NetApp.Manage.NaServer($serverName,"1","1");
    [NetApp.Manage.NaElement] $input = 
    New-Object NetApp.Manage.NaElement("snapshot-list-info");
    [NetApp.Manage.NaElement] $output = $null;

    $server.SetAdminUser($user, $passwd)
    $input.AddNewChild("volume",$volume);
    $output = $server.InvokeElem($input);
    [System.Collections.IList] $snapshots = $output.GetChildByName("snapshots").GetChildren();
    [System.Collections.IEnumerator] $snapIter = $snapshots.GetEnumerator();
    
    while($snapiter.MoveNext())
    {
        [NetApp.Manage.NaElement] $snapshot = $snapIter.Current;
        write("SNAPSHOT:")
        [System.Int32] $accessTime = $snapshot.GetChildIntValue("access-time", 0);
        [System.DateTime] $dateTimePrev = 
		New-Object System.DateTime(1970, 1, 1, 0, 0, 0);
        $dateTime = $dateTimePrev.AddSeconds($accessTime);
        write("`nNAME: " + $snapshot.GetChildContent("name"));
        write("ACCESS TIME (GMT):" + $dateTime);
        write("BUSY: " + $snapshot.GetChildContent("busy"));
        write("TOTAL (of 1024B): " + $snapshot.GetChildContent("total"));
        write("CUMULATIVE TOTAL (of 1024B): " + $snapshot.GetChildContent("cumulative-total"));
        write("DEPENDENCY: " + $snapshot.GetChildContent("dependency"));
    }
    trap [Exception] 
    { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
    }
}  

function GetSchedule
{
    [NetApp.Manage.NaServer] $server = 
    New-Object NetApp.Manage.NaServer($serverName,"1","0");
    [NetApp.Manage.NaElement] $input = 
    New-Object NetApp.Manage.NaElement("snapshot-get-schedule");
    [NetApp.Manage.NaElement] $output = $null;
    
    $server.SetAdminUser($user, $passwd)
    $input.AddNewChild("volume", $volume)

    $output = $server.InvokeElem($input)
    write("Snapshot schedule for volume " + $volume + " on filer " + $serverName);
    write("---------------------------------------------------------------");
    write("Snapshots are taken on minutes [" + $output.GetChildContent("which-minutes") + "] of each hour (" + $output.GetChildContent("minutes") + " kept)");
    write("Snapshots are taken on hours [" + $output.GetChildContent("which-hours") + "] of each day (" + $output.GetChildContent("hours") + " kept)");
    write($output.GetChildContent("days") + " nightly snapshots are kept");
    write($output.GetChildContent("weeks") + " weekly snapshots are kept");
    trap [Exception] 
    { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
    }
}

switch ($ARGS[4])
{
    "create"
    {
        Invoke-Expression CreateSnapshot;
    }
    "rename"
    {
        RenameSnapshot;
    }
    "delete"
    {
        DeleteSnapshot;
    }
    "list"
    {
        ListInfo;
    }
    "schedule"
    {
        GetSchedule;
    }
    default 
    {
        Write $("`nERROR: Invalid command.");
        printUsage;   
    }
}

