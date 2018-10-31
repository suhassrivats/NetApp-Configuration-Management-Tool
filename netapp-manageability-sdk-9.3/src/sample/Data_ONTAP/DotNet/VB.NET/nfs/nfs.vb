'===================================================================='
'                                                                    '
'                                                                    '
' nfs.vb                                                             '
'                                                                    '
' Copyright 2008 NetApp, Inc. All rights                             '
' reserved. Specifications subject to change without notice.         '
'                                                                    '
' This SDK sample code is provided AS IS, with no support or         '
' warranties of any kind, including but not limited to               '
' warranties of merchantability or fitness of any kind,              '
' expressed or implied.  This code is subject to the license         '
' agreement that accompanies the SDK.                                '
'                                                                    '
'                                                                    '
' Sample for usage of following nfs group API:                       '
'                      nfs-enable                                    '
'                      nfs-disable                                   '
'                      nfs-status                                    '
'                      nfs-exportfs-list-rules                       '
'                                                                    '
' Usage:                                                             '
' nfs <filer> <user> <password> <operation>                          '
'                                                                    '
' <filer>      -- Name/IP address of the filer                       '
' <user>       -- User name                                          '
' <password>   -- Password                                           '
' <operation>  --                                                    '
'                 enable                                             '
'                 disable                                            '
'                 status                                             '
'                 list                                               '
'                                                                    '
'==================================================================='


Imports System
Imports System.Collections.Generic
Imports NetApp.Manage

Module nfs
    Public Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage: nfs <filer> <username> <passwd> <operation>")
        Console.WriteLine(Environment.NewLine & "Possible opeartions are:" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "enable - To enable NFS Service")
        Console.WriteLine(ControlChars.Tab & "disable - To disable NFS Service")
        Console.WriteLine(ControlChars.Tab & "status - To print the status of NFS Service")
        Console.WriteLine(ControlChars.Tab & "list - To list the NFS export rules")
    End Sub
    Sub Main(ByVal args As String())

        If (args.Length < 4) Then
            Usage()
            Exit Sub
        End If

        Dim serverName As String = args(0)
        Dim user As String = args(1)
        Dim passwd As String = args(2)
        Dim operation As String = args(3)

        Try
            'Initialize connection to server, and request version 1.0 of the API set
            Dim server As New NaServer(serverName, 1, 3)
            server.ServerType = NaServer.SERVER_TYPE.FILER
            server.SetAdminUser(user, passwd)
            Dim xi As NaElement
            Dim xo As NaElement

            'Check for the operation and invoke the corresponding API.
            If operation.Equals("enable") Then
                xi = New NaElement("nfs-enable")
                xo = server.InvokeElem(xi)
                Console.WriteLine("enabled successfully!")

            ElseIf operation.Equals("disable") Then
                xi = New NaElement("nfs-disable")
                xo = server.InvokeElem(xi)
                Console.WriteLine("disabled successfully!")

            ElseIf operation.Equals("status") Then
                xi = New NaElement("nfs-status")
                xo = server.InvokeElem(xi)
                Dim enabled As String = xo.GetChildContent("is-enabled")
                If enabled.Equals("true") Then
                    Console.WriteLine("NFS Server is enabled")
                Else
                    Console.WriteLine("NFS Server is disabled")
                End If

            ElseIf operation.Equals("list") Then
                xi = New NaElement("nfs-exportfs-list-rules")
                xo = server.InvokeElem(xi)

                Dim rulesList As List(Of NaElement) = xo.GetChildByName("rules").GetChildren()

                For Each ruleInfo As NaElement In rulesList
                    Dim pathName As String = ruleInfo.GetChildContent("pathname")
                    Dim rwList As String = "rw="
                    Dim roList As String = "ro="
                    Dim rootList As String = "root="
                    Dim privilege As String = ""

                    If ruleInfo.GetChildByName("read-only") IsNot Nothing Then
                        privilege = "read-only"
                    ElseIf ruleInfo.GetChildByName("read-write") IsNot Nothing Then
                        privilege = "read-write"
                    ElseIf ruleInfo.GetChildByName("root") IsNot Nothing Then
                        privilege = "root"
                    End If

                    Dim ruleElem As NaElement = ruleInfo.GetChildByName(privilege)
                    Dim hostList As List(Of NaElement) = ruleElem.GetChildren()
                    For Each hostInfo As NaElement In hostList
                        If hostInfo.GetChildContent("all-hosts") <> Nothing Then
                            Dim allhost As String = hostInfo.GetChildContent("all-hosts")
                            If allhost.CompareTo("true") = 0 Then
                                If privilege.Equals("read-only") Then
                                    roList = roList + "all-hosts"
                                ElseIf privilege.Equals("read-write") Then
                                    rwList = rwList + "all-hosts"
                                ElseIf privilege.Equals("root") Then
                                    rootList = rootList + "all-hosts"
                                End If
                            End If
                        ElseIf hostInfo.GetChildContent("name") <> Nothing Then
                            If privilege.Equals("read-only") Then
                                roList = roList + hostInfo.GetChildContent("name") + ":"
                            ElseIf privilege.Equals("read") Then
                                rwList = rwList + hostInfo.GetChildContent("name") + ":"
                            ElseIf privilege.Equals("root") Then
                                rootList = rootList + hostInfo.GetChildContent("name") + ":"
                            End If
                        End If
                    Next hostInfo
                    pathName = pathName + "  "
                    If roList.CompareTo("ro=") <> 0 Then
                        pathName = pathName + roList
                    End If
                    If rwList.CompareTo("rw=") <> 0 Then
                        pathName = pathName + "," + rwList
                    End If
                    If rootList.CompareTo("root=") <> 0 Then
                        pathName = pathName + "," + rootList
                    End If
                    Console.WriteLine("pathname: " & pathName)
                Next ruleInfo
            Else
                Usage()
                Exit Sub
            End If
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try
    End Sub

End Module
