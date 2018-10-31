'============================================================'
'                                                            '
' vollist.vb                                                 '
'                                                            '
' Sample code to list the volumes available in the cluster.  '
'                                                            '
' This sample code is supported from Cluster-Mode            '
' Data ONTAP 8.1 onwards.                                    '
'                                                            '
' Copyright 2011 NetApp, Inc. All rights reserved.           '
' Specifications subject to change without notice.           '
'                                                            '
'============================================================'

Imports System
Imports System.Collections.Generic
Imports NetApp.Manage

Module VolList
    Dim server As NaServer
    Dim args As String()

    Public Sub PrintUsageAndExit()
        Console.WriteLine(Environment.NewLine & "Usage:")
        Console.WriteLine("vollist <cluster/vserver> <user> <passwd> [-v <vserver-name>]")
        Console.WriteLine("<cluster>             -- IP address of the cluster")
        Console.WriteLine("<vserver>             -- IP address of the vserver")
        Console.WriteLine("<user>                -- User name")
        Console.WriteLine("<passwd>              -- Password")
        Console.WriteLine("<vserver-name>        -- Name of the vserver")
        Console.WriteLine("Note: ")
        Console.WriteLine(" -v switch is required when you want to tunnel the command to a vserver using cluster interface")
        Environment.Exit(-1)
    End Sub

    Sub ListVolumes()
        Dim xi, xo As NaElement
        Dim tag As String = ""
        Dim flag As Boolean = True
        Dim vserverName, volName, aggrName, volType, volState, size, availSize As String
        While (flag = True)
            If (args.Length > 4) Then
                If (args.Length < 6 Or (Not args(4).Equals("-v"))) Then
                    PrintUsageAndExit()
                End If
                server.Vserver = args(5)
            End If
            xi = New NaElement("volume-get-iter")
            If (Not tag.Equals("")) Then
                xi.AddNewChild("tag", tag)
            End If
            xo = server.InvokeElem(xi)
            If (xo.GetChildIntValue("num-records", 0) = 0) Then
                Console.WriteLine("No volume(s) information available")
                Return
            End If
            tag = xo.GetChildContent("next-tag")
            If (tag = Nothing) Then
                flag = False
            End If
            Dim volList As List(Of NaElement) = xo.GetChildByName("attributes-list").GetChildren()
            Dim total As Integer = volList.Count
            Dim index As Integer
            Dim volInfo As NaElement
            Dim volStateAttrs As NaElement
            Dim volSizeAttrs As NaElement

            Console.WriteLine("----------------------------------------------------")
            For index = 0 To total - 1
                volInfo = volList(index)
                vserverName = ""
                volName = ""
                aggrName = ""
                volType = ""
                volState = ""
                size = ""
                availSize = ""
                Dim volIdAttrs As NaElement = volInfo.GetChildByName("volume-id-attributes")
                If (Not (volIdAttrs Is Nothing)) Then
                    vserverName = volIdAttrs.GetChildContent("owning-vserver-name")
                    volName = volIdAttrs.GetChildContent("name")
                    aggrName = volIdAttrs.GetChildContent("containing-aggregate-name")
                    volType = volIdAttrs.GetChildContent("type")
                End If

                Console.WriteLine("Vserver Name            : " + IIf(vserverName <> Nothing, vserverName, ""))
                Console.WriteLine("Volume Name             : " + IIf(volName <> Nothing, volName, ""))
                Console.WriteLine("Aggregate Name          : " + IIf(aggrName <> Nothing, aggrName, ""))
                Console.WriteLine("Volume type             : " + IIf(volType <> Nothing, volType, ""))
                volStateAttrs = volInfo.GetChildByName("volume-state-attributes")
                If (Not (volIdAttrs Is Nothing)) Then
                    volState = volStateAttrs.GetChildContent("state")
                End If
                Console.WriteLine("Volume state            : " + IIf(volState <> Nothing, volState, ""))
                volSizeAttrs = volInfo.GetChildByName("volume-space-attributes")
                If (Not (volSizeAttrs Is Nothing)) Then
                    size = volSizeAttrs.GetChildContent("size")
                    availSize = volSizeAttrs.GetChildContent("size-available")
                End If
                Console.WriteLine("Size (bytes)            : " + IIf(size <> Nothing, size, ""))
                Console.WriteLine("Available Size (bytes)  : " + IIf(availSize <> Nothing, availSize, ""))
                Console.WriteLine("----------------------------------------------------")
            Next index
        End While
    End Sub

    Sub Main()
        args = Environment.GetCommandLineArgs()

        If (args.Length < 4) Then
            PrintUsageAndExit()
            Exit Sub
        End If

        Dim serverName As String = args(1)
        Dim user As String = args(2)
        Dim passwd As String = args(3)

        Try
            'Initialize connection to server, and request version 1.15 of the API set.
            server = New NaServer(serverName, 1, 15)

            server.ServerType = NaServer.SERVER_TYPE.FILER
            server.TransportType = NaServer.TRANSPORT_TYPE.HTTP
            server.SetAdminUser(user, passwd)

            ListVolumes()
           
        Catch ex As NaException
            Console.WriteLine(ex.Message)
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try
    End Sub

End Module
