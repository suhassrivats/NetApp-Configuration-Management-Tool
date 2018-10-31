'======================================================================='
'                                                                       '
' vollist.vb                                                            '
'                                                                       '
'                                                                       '
' Sample code for using ONTAPI API to list volume information			'
'                                                                       '
' Copyright 2008 NetApp, Inc. All rights                                '
' reserved. Specifications subject to change without notice.            '
'                                                                       '
' This SDK sample code is provided AS IS, with no support or            '
' warranties of any kind, including but not limited to                  '
' warranties of merchantability or fitness of any kind,                 '
' expressed or implied.  This code is subject to the license            '
' agreement that accompanies the SDK.                                   '
'                                                                       '
' Usage: vollist <filer> <username> <passwd> [<volume>]                 '
'                                                                       '
'======================================================================='

Imports System
Imports System.Collections.Generic
Imports NetApp.Manage

Module VolList
    Public Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage: vollist <filer> <username> <passwd> [<volume>]")
    End Sub
    Sub Main()
        Dim args As String() = Environment.GetCommandLineArgs()

        If (args.Length < 4) Then
            Usage()
            Exit Sub
        End If

        Dim serverName As String = args(1)
        Dim user As String = args(2)
        Dim passwd As String = args(3)
        Dim volume As String = ""

        If (args.Length > 4) Then
            volume = args(4)
        End If

        Try
            'Initialize connection to server, and request version 1.0 of the API set.
            Dim server As New NaServer(serverName, 1, 0)

            server.ServerType = NaServer.SERVER_TYPE.FILER
            server.TransportType = NaServer.TRANSPORT_TYPE.HTTP
            server.SetAdminUser(user, passwd)

            'Frame the volume-list-Info ONTAPI API request
            Dim input As New NaElement("volume-list-info")
            If (volume <> "") Then
                input.AddNewChild("volume", volume)
            End If
            Dim output As NaElement

            'Invoke volume-list-Info ONTAPI API
            output = server.InvokeElem(input)

            'Get the list of children from 'output' element and iterate 
            'through each of the child element to retrieve their values
            Dim volList As List(Of NaElement) = output.GetChildByName("volumes").GetChildren()
            Dim total As Integer = volList.Count
            Dim volInfo As NaElement
            Dim index As Integer

            For index = 0 To total - 1
                Console.WriteLine("---------------------------------")
                volInfo = volList(index)
                Console.Write("Volume Name:")
                Console.WriteLine(volInfo.GetChildContent("name"))
                Console.Write("Volume State:")
                Console.WriteLine(volInfo.GetChildContent("state"))
                Console.Write("Disk Count:")
                Console.WriteLine(volInfo.GetChildIntValue("disk-count", -1))
                Console.Write("Total Files:")
                Console.WriteLine(volInfo.GetChildIntValue("files-total", -1))
                Console.Write("No of files used:")
                Console.WriteLine(volInfo.GetChildIntValue("files-used", -1))
            Next index
        Catch ex As NaException
            Console.WriteLine(ex.Message)
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try
    End Sub

End Module
