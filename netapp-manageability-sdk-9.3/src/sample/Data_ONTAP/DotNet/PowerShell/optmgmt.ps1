#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# optmgmt.ps1                                                #
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
	write $("`nUsage : optmgmt <filername> <username> <passwd> [operation(get/set)] [<optionName>] [<value>]");
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

$s = New-Object NetApp.Manage.NaServer ($ARGS[0],"1","0");
$s.SetAdminUser($ARGS[1],$ARGS[2]);
	
if ($ARGS.Length  -gt  3)
{
	$op = $ARGS[3];
	#
    # Get value of a specific option
    #
    if ($op -eq "get")
    {
        $xi = New-Object NetApp.Manage.NaElement("options-get");
        if ($ARGS.Length -eq 5) {
            $xi.AddNewChild("name", $ARGS[4]);
		}
        else
        {
            write $("Improper number of arguments. Correct and re-run.");
            Exit(1);
        }
                        
        $xo = $s.InvokeElem($xi);
        write $("----------------------------");
        write $("Option Value: " + $xo.GetChildContent("value"));
        write $("Cluster Constraint: " +  $xo.GetChildContent("cluster-constraint"));
        write $("----------------------------");
    }
    #
    # Set value of a specific option
    elseif ($op -eq "set")
    {
		$xi = New-Object NetApp.Manage.NaElement("options-set");
        if ($ARGS.Length -eq 6)
        {
			$xi.AddNewChild("name", $ARGS[4]);
            $xi.AddNewChild("value", $ARGS[5]);
        }
        else
        {
			Write-Error $("Improper number of arguments. Correct and re-run.");
            Exit(1);
        }
        $xo = $s.InvokeElem($xi);
        write $("----------------------------");
        if ($xo.GetChildContent("message"))
        {
            write $("Message: ");
            write $xo.GetChildContent("message");
        }
        write $("Cluster Constraint: " + $xo.GetChildContent("cluster-constraint"));
        write $("----------------------------");
    }
    else
    {
		write $("Invalid Operation");
		Exit(1);
    }
    Exit(0);
}
#
# List out all the options
#
else
{
	$xi = New-Object NetApp.Manage.NaElement("options-list-info");

    $xo = $s.InvokeElem($xi);
    #
    # Get the list of children from element(Here 
    # 'xo') and iterate through each of the child 
    # element to fetch their values
    #
    [System.Collections.IList] $optionList = $xo.GetChildByName("options").GetChildren();
    [System.Collections.IEnumerator] $optionIter = $optionList.GetEnumerator();
    while ($optionIter.MoveNext())
    {
        $optionInfo = [NetApp.Manage.NaElement] $optionIter.Current;
        write $("----------------------------");
        write $("Option Name: " + $optionInfo.GetChildContent("name"));
        write $("Option Value: " + $optionInfo.GetChildContent("value"));
        write $("Cluster Constraint: " + $optionInfo.GetChildContent("cluster-constraint"));
    }
}

trap [Exception] { 
      write-error $("ERROR! " + $_.Exception.Message); 
      exit(1); 
}
