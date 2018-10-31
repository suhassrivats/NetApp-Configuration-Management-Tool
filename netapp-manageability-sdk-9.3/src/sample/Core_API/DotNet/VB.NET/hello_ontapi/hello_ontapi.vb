'==================================================================='
'                                                                   '
'                                                                   '
' hello_ontapi.vb                                                   '
'                                                                   '
'  Hello World for the ONTAPI APIs                                  '
'                                                                   '
' Copyright 2008 NetApp, Inc. All rights                            '
' reserved. Specifications subject to change without notice.        '
'                                                                   '
' This SDK sample code is provided AS IS, with no support or        '
' warranties of any kind, including but not limited to              '
' warranties of merchantability or fitness of any kind,             '
' expressed or implied.  This code is subject to the license        '
' agreement that accompanies the SDK.                               '
'                                                                   '
'                                                                   '
' Usage: hello_ontapi <filer> <username> <passwd>                   '
'==================================================================='

Imports System
Imports System.Collections.Generic
Imports NetApp.Manage

Module Hello_Ontapi
    Public Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage: hello_ontapi <filer> <username> <passwd>")
    End Sub
    Sub Main(ByVal args As String())
        
        If (args.Length < 3) Then
            Usage()
            Exit Sub
        End If

        Dim serverName As String = args(0)
        Dim user As String = args(1)
        Dim passwd As String = args(2)

        Try
            'Initialize connection to server, and request version 1.1 of the API set.
            Dim server As New NaServer(serverName, 1, 0)
            server.ServerType = NaServer.SERVER_TYPE.FILER
            server.SetAdminUser(user, passwd)

            Dim output As NaElement
            Dim version As String

            'Invoke ONTAPI API to get the ONTAP version number of a filer.	
            output = server.Invoke("system-get-version")
            version = output.GetChildContent("version")
            Console.WriteLine("Hello world!  DOT version of " & serverName & " is " & version)
        Catch ex As NaException
            Console.Error.WriteLine(ex.Message)
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try
    End Sub

End Module
