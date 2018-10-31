
'==================================================================='   
'                                                                   '
'                                                                   '
' encrypt_string.vb                                                 '
'                                                                   '
' Demonstrates usage of AddNewEncryptedChild() and                  ' 
'                    GetChildEncryptContent() core APIs             '
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
' Usage: encrypt_string <filer> <user> <passwd> <test-passwd>       '
'==================================================================='

Imports System
Imports System.Collections.Generic
Imports NetApp.Manage


Module Encrypt_String
    Public Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage: encrypt_string <filer> <username> <passwd> <test-passwd>")
    End Sub
    Sub Main(ByVal args As String())

        If (args.Length < 4) Then
            Usage()
            Exit Sub
        End If

        Dim serverName As String = args(0)
        Dim user As String = args(1)
        Dim passwd As String = args(2)
        Dim testPasswd As String = args(3)
        Dim decPasswd As String

        Try
            Dim server As New NaServer(serverName, 1, 0)
            server.ServerType = NaServer.SERVER_TYPE.FILER
            server.SetAdminUser(user, passwd)

            ''test-password-set' API is a test routine to test  encrypted values.
            Dim input As New NaElement("test-password-set")

            'Creates a new element with key 'password' (first argument)
            'and value 'testPasswd' (second argument), encrypts data contained 
            'in value (second argument) with the default encryption key 
            'and adds the new element as a nested element of 'input' element
            input.AddNewEncryptedChild("password", testPasswd)

            decPasswd = input.GetChildEncryptContent("password")
            Console.WriteLine("Expected decrypted password from server:" & decPasswd & Environment.NewLine)

            Dim output As NaElement
            Dim result As String
            output = server.InvokeElem(input)
            result = output.ToPrettyString("")
            Console.WriteLine("Returned value : " & Environment.NewLine & result)
        Catch ex As NaException
            Console.WriteLine(ex.Message)
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try
    End Sub

End Module
