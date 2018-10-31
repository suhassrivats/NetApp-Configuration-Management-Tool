#=======================================================================#
#                                                                       #
# perf_operation.ps1                                                    #
#                                                                       #
# Copyright 2009 NetApp, Inc. All rights                                #
# reserved. Specifications subject to change without notice.            #
#                                                                       #
# This SDK sample code is provided AS IS, with no support or            #
# warranties of any kind, including but not limited to                  #
# warranties of merchantability or fitness of any kind,                 #
# expressed or implied.  This code is subject to the license            #
# agreement that accompanies the SDK.                                   #
#                                                                       #
#  Sample for usage of following perf group API:                        #
#          perf-object-list-info                                        #
#          perf-object-counter-list-info                                #
#          perf-object-instance-list-info                               #
#          perf-object-get-instances-iter-*                             #
#                                                                       #
# Usage: perf_operation.ps1 <filer> <user> <password> <operation>       #
#                                                                       #
# <filer>      -- Name/IP address of the filer                          #
# <user>       -- User name                                             #
# <password>   -- Password                                              #
# <operation>  --                                                       #
#      object-list - Get the list of perforance objects                 #
#                in the system                                          #
#      instance-list - Get the list of instances for a given            #
#                  performance object                                   #
#      counter-list - Get the list of counters available for a          #
#                 given performance object                              #
#      get-counter-values - get the values of the counters for          #
#                   all instance of a performance object                #
#=======================================================================#

function PrintUsage
{
    Write("Usage: perf_operation <filer> <username> <passwd> <operation>")
    Write("Possible operations are:")
    Write(" object-list - Get the list of perforance objects in the system")
    Write(" instance-list - Get the list of instances for a given performance object")
    Write(" counter-list - Get the list of counters available for a given performance object")
    Write(" get-counter-values - get the values of the counters for all the instances of a performance object")
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

if($ARGS.Length -lt 4)
{
    PrintUsage;
}
   
Invoke-Expression LoadAssembly;

$serverName = $ARGS[0];
$user = $ARGS[1];
$passwd = $ARGS[2];
$operation = $ARGS[3];
$objName; 

[NetApp.Manage.NaServer] $server = 
New-Object NetApp.Manage.NaServer($serverName,"1","3");
[NetApp.Manage.NaElement] $input = $null;
[NetApp.Manage.NaElement] $output = $null;

$server.SetAdminUser($ARGS[1],$ARGS[2]);

if($operation -eq "object-list")
{
    $input =  New-Object NetApp.Manage.NaElement("perf-object-list-info")
    $output = $server.InvokeElem($input);
    [System.Collections.IList] $objList =  $output.GetChildByName("objects").GetChildren();
    [System.Collections.IEnumerator] $objIter = $objList.GetEnumerator();
    while($objIter.MoveNext())
    {
        [NetApp.Manage.NaElement]$objInfo = $objIter.Current
        Write("Object Name: " + $objInfo.GetChildContent("name") +  
        "`t Privilege level: " + $objInfo.GetChildContent("privilege-level"));
    }
}
elseif($operation -eq "instance-list")
{
    if($ARGS.Length -lt 5)
    {
        Write("Usage: perf_operation.ps1 <filer> <user> <password> instance-list <object-name>");
        exit(1);
    }
    $input = New-Object NetApp.Manage.NaElement("perf-object-instance-list-info")
    $objName = $ARGS[4];
    $input.AddNewChild("objectname", $objName);
    $output = $server.InvokeElem($input);
    [System.Collections.IList] $instList = 
            $output.GetChildByName("instances").GetChildren();
    [System.Collections.IEnumerator] $instIter = $instList.GetEnumerator();
    while ($instIter.MoveNext())
    {
        [NetApp.Manage.NaElement] $instInfo = $instIter.Current;
        Write("Instance Name: " + $instInfo.GetChildContent("name"));
    }
}
elseif($operation -eq "counter-list")
{
    if($ARGS.Length -lt 5)
    {
        Write("Usage: perf_operation.ps1 <filer> <user> <password> counter-list <object-name>")
        exit(1);    
    }
    $input =  New-Object NetApp.Manage.NaElement("perf-object-counter-list-info");
    $objName = $ARGS[4];
    $input.AddNewChild("objectname", $objName);
    $output = $server.InvokeElem($input);
    [System.Collections.IList] $counterList = 
    $output.GetChildByName("counters").GetChildren();
    [System.Collections.IEnumerator] $counterIter = 
    $counterList.GetEnumerator();

    while ($counterIter.MoveNext())
    {
        [NetApp.Manage.NaElement] $counterInfo = $counterIter.Current
        Write("`nCounter Name: " + $counterInfo.GetChildContent("name"));
        $baseCounter = $counterInfo.GetChildContent("base-counter");
        if ( $baseCounter -eq $null) 
        {
            $baseCounter = "None";
        }
        Write("Base Counter: " + $baseCounter);
        Write("Privilege Level: " + $counterInfo.GetChildContent("privilege-level"));
        $unit = $counterInfo.GetChildContent("unit");
        if($unit -eq $null)
        {
            $unit = "None";
         }
         Write("Unit:" + $unit);
    }
}
elseIf($operation -eq "get-counter-values")
{
    $totalRecords = 0;
    $maxRecords = 10;
    $numRecords = 0;
    $iterTag = $null;

    if ($ARGS.Length -lt 5)
    {
        write("Usage: perf_operation.ps1 <filer> <user> <password> get-counter-values <objectname> [<counter1> <counter2> ...]");
        exit(1);
    }
    $input =  
    New-Object NetApp.Manage.NaElement("perf-object-get-instances-iter-start");
    $objName = $ARGS[4];
    $input.AddNewChild("objectname", $objName);
    [NetApp.Manage.NaElement] $counters = 
    New-Object NetApp.Manage.NaElement("counters");

    #Now store rest of the counter names as child element of counters.
    $counterIndex = 5;

    while ($counterIndex -lt $ARGS.Length)
    {
        $counters.AddNewChild("counter", $ARGS[$counterIndex]);
        $counterIndex++;
    }
    if ($counterIndex -gt 5) 
    {
        $input.AddChildElement($counters);
    }

    $output = $server.InvokeElem($input);
    $totalRecords = $output.GetChildIntValue("records", -1);
    $iterTag = $output.GetChildContent("tag");
    $input = 
    New-Object NetApp.Manage.NaElement("perf-object-get-instances-iter-next");
    $input.AddNewChild("tag", $iterTag);
    $input.AddNewChild("maximum", $totalRecords);
    $output = $server.InvokeElem($input)
    $numRecords = $output.GetChildIntValue("records", 0);

    if($numRecords -gt 0)
    {
        [System.Collections.IList] $instList = 
            $output.GetChildByName("instances").GetChildren();
        [System.Collections.IEnumerator] $instIter = $instList.GetEnumerator();
        while ($instIter.MoveNext())
        {
            [NetApp.Manage.NaElement] $instData = $instIter.Current;
            Write("Instance: " + $instData.GetChildContent("name"));
            [System.Collections.IList]  $counterList = 
            $instData.GetChildByName("counters").GetChildren();
            [System.Collections.IEnumerator] $counterIter = 
                $counterList.GetEnumerator();

            while($counterIter.MoveNext())
            {
                [NetApp.Manage.NaElement] $counterData = $counterIter.Current;
                write("Counter Name: " + $counterData.GetChildContent("name") + " Counter value: " + $counterData.GetChildContent("value"));
            }
        }
    }
    $input =  New-Object NetApp.Manage.NaElement("perf-object-get-instances-iter-end");
    $input.AddNewChild("tag", $iterTag);
    $output = $server.InvokeElem($input);
}
else
{
    PrintUsage;
}
trap [Exception] { 
      write-error $("ERROR: " + $_.Exception.Message); 
      exit(1); 
}
