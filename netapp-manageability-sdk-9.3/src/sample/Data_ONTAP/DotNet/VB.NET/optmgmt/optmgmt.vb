'==========================================================================='
'                                                                           '
'                                                                           '
' optmgmt.vb                                                                '
'                                                                           '
' ONTAPI API lists option information, get value of a specific              '
' option, and set value for a specific option.		                        '
'                                                                           '
' Copyright 2008 NetApp, Inc. All rights                                    '
' reserved. Specifications subject to change without notice.                '
'                                                                           '
' This SDK sample code is provided AS IS, with no support or                '
' warranties of any kind, including but not limited to                      '
' warranties of merchantability or fitness of any kind,                     '
' expressed or implied.  This code is subject to the license                '
' agreement that accompanies the SDK.                                       '
'                                                                           '
'                                                                           '
' Usage:							                                        '
' optmgmt <filer> <user> <password> [<operation>] [<optionName>] [<value>]  '
' <filer> 	-- Name/IP address of the filer			                        '
' <user>  	-- User name					                                '
' <password> 	-- Password					                                '
' <operation> 	-- get/set					                                '
' <optionName>	-- Name of the option on which get/set operation            '
'		   needs to be performed			                                '
' <value> 	-- This is required only for set operation. 	                '
'		   Provide the value that needs to be assigned for                  '
'		   the option					                                    '
'                                                                           '
'==========================================================================='

Imports System
Imports System.Collections.Generic
Imports NetApp.Manage

Module OptMgmt
    Public Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage: optmgmt <filer> <username> <passwd> [<operation(get/set)> [<optionName>] [<value>]]")
    End Sub
    Public Sub Main()
        Dim args As String() = Environment.GetCommandLineArgs()

        If (args.Length < 4) Then
            Usage()
            Exit Sub
        End If

        Dim serverName As String = args(1)
        Dim user As String = args(2)
        Dim passwd As String = args(3)
        Dim operation As String = ""
        Dim name As String = ""
        Dim value As String = ""

        
        Try
            'Initialize connection to server, and request version 1.0 of the API set
            Dim server As New NaServer(serverName, 1, 0)
            Dim output As NaElement = Nothing

            server.ServerType = NaServer.SERVER_TYPE.FILER
            server.TransportType = NaServer.TRANSPORT_TYPE.HTTP
            server.SetAdminUser(user, passwd)

            If args.Length > 4 Then
                operation = args(4)
                'Find the given operation
                If (operation = "get") Then
                    If (args.Length < 6) Then
                        Console.WriteLine("operation get requires an option name")
                        Exit Sub
                    End If
                    name = args(5)
                                        
                    'Invoke option get Info ONTAPI API
                    output = server.Invoke("options-get","name",name)
                    Console.WriteLine("----------------------------")
                    Console.WriteLine("Option Value:" & output.GetChildContent("value"))
                    Console.WriteLine("Cluster Constraint:" & output.GetChildContent("cluster-constraint"))
                    Console.WriteLine("----------------------------")
                Else
                    If (operation = "set") Then
                        If (args.Length < 7) Then
                            Console.WriteLine("operation set requires option name and value pair")
                            Exit Sub
                        End If
                        name = args(5)
                        value = args(6)
                        output = server.Invoke("options-set","name",name,"value",value)
                        Console.WriteLine("----------------------------")
                        If (output.GetChildContent("message") <> Nothing) Then
                            Console.WriteLine("Message:" & output.GetChildContent("message"))
                        End If
                        Console.WriteLine("Cluster Constraint:" & output.GetChildContent("cluster-constraint"))
                        Console.WriteLine("----------------------------")
                    Else
                        Console.WriteLine("Invalid Operation")
                        Usage()
                        Exit Sub
                    End If
                    End If
            Else
                
                output = server.Invoke("options-list-info")
                Dim optList As List(Of NaElement) = output.GetChildByName("options").GetChildren()
                Dim total As Integer = optList.Count
                Dim optInfo As NaElement
                Dim index As Integer

                For index = 0 To total - 1
                    Console.WriteLine("---------------------------------")
                    optInfo = optList(index)
                    Console.WriteLine("Option Name:" & optInfo.GetChildContent("name"))
                    Console.WriteLine("Option Value:" & optInfo.GetChildContent("value"))
                    Console.WriteLine("Cluster Constraint:" & optInfo.GetChildContent("cluster-constraint"))
                Next index
            End If
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try
    End Sub
End Module