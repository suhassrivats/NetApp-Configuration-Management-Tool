'======================================================================='
'                                                                       '
' vfiler_tunnel.vb                                                      '
'                                                                       '
'                                                                       '
' This sample code demonstrates how to execute ONTAPI APIs              '
' on a vfiler through the physical filer                                '
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
'                                                                       '
'======================================================================='


Imports System
Imports NetApp.Manage


Module VfilerTunnel

    Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage: vfiler_tunnel <vfiler-name> <filer> " _
            & "<user> <password> <ONTAPI-name> [<param-name> <arg>] ..." & Environment.NewLine)
        Environment.Exit(1)
    End Sub


    Sub Main(ByVal args As String())
        Dim vfiler As String
        Dim filer As String
        Dim user As String
        Dim passwd As String
        Dim s As NaServer = Nothing
        Dim xi As NaElement = Nothing
        Dim xo As NaElement = Nothing
        Dim index As Integer = 4

        If args.Length < 5 Then
            Usage()
        End If

        Try
            vfiler = args(0)
            filer = args(1)
            user = args(2)
            passwd = args(3)

            ' Vfiler tunnelling requires ONTAPI version 7.0 to work 
            s = New NaServer(filer, 1, 7)
            s.SetAdminUser(user, passwd)
            s.SetVfilerTunneling(vfiler)


            'Invoke any  ONTAPI API with arguments
            ' in (key,value) pair 
            ' args(0)=filer,args(1)=user,args(2)=passwd
            ' args(3)=Ontapi API,args(4) onward arguments
            ' in (key,value) pair
            Try

                'Create an instance of NaElement which contains the ONTAPI API request
                xi = New NaElement(args(index))

                If (args.Length > index + 1) Then
                    Dim index2 As Integer
                    For index2 = index + 1 To args.Length - 1
                        'Optional - add the child elements to the parent 
                        xi.AddNewChild(args(index2), args(index2 + 1))
                        index2 = index2 + 1
                    Next index2
                End If

            Catch ex As System.IndexOutOfRangeException
                Throw New NaApiFailedException("Mismatch in arguments passed " & _
                                               "(in (key,value) Pair) to " & _
                                                "Ontapi API", -1)
            End Try

            'Invoke a single ONTAPI API to the server.
            xo = s.InvokeElem(xi)

            'Print the ONTAPI API response that is returned by the server
            Console.WriteLine(xo.ToPrettyString(""))

        Catch ex As NaApiFailedException
            Console.Error.WriteLine(ex.Message)

        Catch ex As Exception
            Console.Error.WriteLine(ex.Message)

        End Try

    End Sub

End Module
