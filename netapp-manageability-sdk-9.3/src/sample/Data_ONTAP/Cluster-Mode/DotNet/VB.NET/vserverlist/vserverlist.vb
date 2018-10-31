'============================================================'
'                                                            '
' vserverlist.vb                                             '
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

Module VserverList
    Dim server As NaServer
    Dim args As String()

    Public Sub PrintUsageAndExit()
        Console.WriteLine(Environment.NewLine & "Usage:")
        Console.WriteLine("vserverlist <cluster/vserver> <user> <passwd> [-v <vserver-name>]")
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

        While (flag = True)
            If (args.Length > 4) Then
                If (args.Length < 6 Or (Not args(4).Equals("-v"))) Then
                    PrintUsageAndExit()
                End If
                server.Vserver = args(5)
            End If
            xi = New NaElement("vserver-get-iter")
            If (Not tag.Equals("")) Then
                xi.AddNewChild("tag", tag)
            End If
            xo = server.InvokeElem(xi)
            If (xo.GetChildIntValue("num-records", 0) = 0) Then
                Console.WriteLine("No vserver(s) information available\n")
                Return
            End If
            tag = xo.GetChildContent("next-tag")
            If (tag = Nothing) Then
                flag = False
            End If
            Dim vserverList As List(Of NaElement) = xo.GetChildByName("attributes-list").GetChildren()
            Dim total As Integer = vserverList.Count
            Dim index As Integer
            Dim vserverInfo As NaElement
            Dim protocol As NaElement
            Dim nsSwitch As NaElement
            Dim rootVolAggr As String
            Dim rootVol As String
            Dim secStyle As String
            Dim state As String

            Console.WriteLine("----------------------------------------------------")
            For index = 0 To total - 1
                vserverInfo = vserverList(index)
                Console.WriteLine("Name                    : " + vserverInfo.GetChildContent("vserver-name"))
                Console.WriteLine("Type                    : " + vserverInfo.GetChildContent("vserver-type"))
                rootVolAggr = vserverInfo.GetChildContent("root-volume-aggregate")
                rootVol = vserverInfo.GetChildContent("root-volume")
                secStyle = vserverInfo.GetChildContent("root-volume-security-style")
                state = vserverInfo.GetChildContent("state")
                Console.WriteLine("Root volume aggregate   : " + IIf(rootVolAggr <> Nothing, rootVolAggr, ""))
                Console.WriteLine("Root volume             : " + IIf(rootVol <> Nothing, rootVol, ""))
                Console.WriteLine("Root volume sec style   : " + IIf(secStyle <> Nothing, secStyle, ""))
                Console.WriteLine("UUID                    : " + vserverInfo.GetChildContent("uuid"))
                Console.WriteLine("State                   : " + IIf(state <> Nothing, state, ""))
                Dim allowedProtocols As NaElement = vserverInfo.GetChildByName("allowed-protocols")
                Console.Write("Allowed protocols       : ")
                If (Not (allowedProtocols Is Nothing)) Then
                    Dim allowedProtocolsList As List(Of NaElement) = allowedProtocols.GetChildren()
                    Dim protoIndex As Integer
                    For protoIndex = 0 To allowedProtocolsList.Count - 1
                        protocol = allowedProtocolsList(protoIndex)
                        Console.Write(protocol.GetContent() + " ")
                    Next protoIndex
                End If
                Dim nameServerSwitch As NaElement = vserverInfo.GetChildByName("name-server-switch")
                Console.Write(Environment.NewLine & "Name server switch      : ")
                If (Not (nameServerSwitch Is Nothing)) Then
                    Dim nameServerSwitchList As List(Of NaElement) = nameServerSwitch.GetChildren()
                    Dim nsSwitchIndex As Integer
                    For nsSwitchIndex = 0 To nameServerSwitchList.Count - 1
                        nsSwitch = nameServerSwitchList(nsSwitchIndex)
                        Console.Write(nsSwitch.GetContent() + " ")
                    Next nsSwitchIndex
                End If
                Console.WriteLine(Environment.NewLine & "----------------------------------------------------")
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
