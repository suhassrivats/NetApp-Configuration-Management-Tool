'============================================================'
'                                                            '
' apitest.vb                                                 '
'                                                            '
' Exploratory application for ONTAPI APIs                    '
' It lets you call any ONTAPI API with named arguments       '
'    (essentially a command-line version of the zexplore     '
'     utility)                                               '
'                                                            '
' Copyright 2010 NetApp, Inc. All rights                     '
' reserved. Specifications subject to change without notice. ' 
'                                                            '
' This SDK sample code is provided AS IS, with no support or '
' warranties of any kind, including but not limited to       '
' warranties of merchantability or fitness of any kind,      '
' expressed or implied.  This code is subject to the license '
' agreement that accompanies the SDK.                        '
'                                                            '
' tab size = 4                                               '
'                                                            '
'============================================================'


Imports System
Imports NetApp.Manage


Module ApiTest
    Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage:" _
                & Environment.NewLine & ControlChars.Tab & "apitest (options) " _
                & "<host> <user> <password> <ONTAPI-name> [<paramname> <arg> ...]" & Environment.NewLine)
        Console.WriteLine("Options:" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-t {type}" _
                & ControlChars.Tab & "Server type(type = filer, dfm, ocum, agent)" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-v {vfiler name | vserver name}  " _
                & "For vfiler-tunneling or vserver-tunneling" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-r" & ControlChars.Tab & _
                "Use RPC transport" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-n" & ControlChars.Tab & _
                "Use SSL" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-p {port}" & ControlChars.Tab & _
                " Override port to use" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-c {timeout}" & ControlChars.Tab & _
                "Connection timeout value in seconds" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-i" & ControlChars.Tab & _
                "API specified as XML input, on the command line" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-I" & ControlChars.Tab & _
                "API specified as XML input, on standard input" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-x" & ControlChars.Tab & _
                "Show the XML input and output" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-X" & ControlChars.Tab & _
                "Show the raw XML input and output" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-h" & ControlChars.Tab & _
                "Use Host equiv authentication mechanism" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-o" & ControlChars.Tab & _
                "Pass Originator Id" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-C {cert-file}" & "   Location of the client certificate file" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-P {cert-passwd}" & " Password to access the client certificate file" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-T {cert-store-name}" & " Client certificate store name. The default is 'My' store" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-L {cert-store-loc}" & "  Client certificate store location. The default is 'CurrentUser'" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-N {cert-name}" & " Subject name of the client certificate in the certificate store" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-S" & "   Enable server certificate verification" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "-H" & "   Enable hostname verification" & Environment.NewLine)

        Console.WriteLine(Environment.NewLine & "Note:")
        Console.WriteLine(Environment.NewLine & "        Use server type 'dfm' (-t dfm) for OnCommand Unified Manager server version 5.2 or earlier.")
        Console.WriteLine(Environment.NewLine & "        Use server type 'ocum' (-t ocum) for OnCommand Unified Manager server version 6.0 or later." & Environment.NewLine)
        Console.WriteLine(Environment.NewLine & "        By default username and password shall be used for client authentication.")
        Console.WriteLine(Environment.NewLine & "        Specify either -C, -P or -S, -L, -N options for using Certificate Based Authentication (CBA)." & Environment.NewLine)
        Console.WriteLine(Environment.NewLine & "        Server certificate and Hostname verification is disabled by default for CBA." & Environment.NewLine)
        Console.WriteLine(Environment.NewLine & "        Do not provide username and password for -h, -r or CBA options." & Environment.NewLine)
        Console.WriteLine(Environment.NewLine & "        The username or UID of the user administering the storage systems can be passed")
        Console.WriteLine(Environment.NewLine & "        to ONTAP as originator-id for audit logging." & Environment.NewLine & Environment.NewLine)
        Console.WriteLine("Examples:" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "apitest sweetpea root tryme system-get-version")
        Console.WriteLine(Environment.NewLine & ControlChars.Tab & "apitest amana root meat " _
                & "quota-report volume vol0" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "apitest -t dfm -C clientcert.pfx -P mypasswd amana dfm-about" & Environment.NewLine)
        Console.WriteLine(ControlChars.Tab & "apitest -t dfm -T My -L CurrentUser -N ram amana dfm-about" & Environment.NewLine)
        Environment.Exit(1)
    End Sub

    Sub GetXMLInput(ByVal inputXML As Integer, ByRef args As String(), ByRef index As Integer)
        Dim readXML As String = ""
        Dim cnt As Integer = 0

        If inputXML = 1 Then
            If args.Length <= index Then
                Console.WriteLine("ERROR: API not specified")
                Usage()
            End If
            For cnt = index To args.Length - 1
                readXML = readXML + args(cnt)
            Next cnt
        Else
            Console.WriteLine("Enter the input XML:" & Environment.NewLine)
            Dim curLine As String = Console.ReadLine()
            While Not curLine Is Nothing
                readXML += curLine
                curLine = Console.ReadLine()
            End While
        End If
        Dim sep(3) As Char

        sep(0) = " "
        sep(1) = ControlChars.NewLine
        sep(2) = ControlChars.Tab

        args = readXML.Split(sep)
        readXML = ""

        For cnt = 0 To args.Length - 1
            If Not (args(cnt).Contains("\t") Or args(cnt).Contains(" ")) Then
                readXML = readXML + args(cnt)
            End If
        Next cnt
        args = readXML.Split(sep)
        index = -1
    End Sub
    Sub Main()
        Dim s As NaServer
        Dim xi As NaElement = Nothing
        Dim xo As NaElement
        Dim transportType As NaServer.TRANSPORT_TYPE = NaServer.TRANSPORT_TYPE.HTTPS
        Dim serverType As NaServer.SERVER_TYPE = NaServer.SERVER_TYPE.FILER
        Dim authStyle As NaServer.AUTH_STYLE = NaServer.AUTH_STYLE.LOGIN_PASSWORD
        Dim vfiler As String = Nothing
        Dim originatorId As String = Nothing
        Dim type As String
        Dim index As Integer = 1
        Dim showXML As Integer = 0
        Dim inputXML As Integer = 0
        Dim port As Integer = -1
        Dim timeOut As Integer = -1
        Dim status As Boolean = True
        Dim useRPC As Boolean = False
        Dim useHostsEquiv As Boolean = False
        Dim useCBA As Boolean = False
        Dim verifyServerCert As Boolean = False
        Dim verifyHostname As Boolean = False
        Dim certFile As String = Nothing
        Dim certPasswd As String = Nothing
        Dim storeName As NaServer.CERT_STORE_NAME = NaServer.CERT_STORE_NAME.MY
        Dim storeLocation As NaServer.CERT_STORE_LOCATION = NaServer.CERT_STORE_LOCATION.CURRENT_USER
        Dim certName As String = Nothing

        Dim args As String() = Environment.GetCommandLineArgs()
        If args.Length < 4 Then
            Usage()
        End If

        Try
            While (args(index).StartsWith("-"))
                If (args(index).Length <> 2) Then
                    Console.WriteLine(Environment.NewLine & "ERROR: Invalid Option")
                    Usage()
                End If

                Select Case args(index)(1)
                    Case "t"
                        type = args(index + 1)
                        If (type.Equals("dfm")) Then
                            serverType = NaServer.SERVER_TYPE.DFM
                        ElseIf (type.Equals("ocum")) Then
                            serverType = NaServer.SERVER_TYPE.OCUM
                            transportType = NaServer.TRANSPORT_TYPE.HTTPS
                        ElseIf (type.Equals("agent")) Then
                            serverType = NaServer.SERVER_TYPE.AGENT
                        ElseIf (type.Equals("filer")) Then
                            serverType = NaServer.SERVER_TYPE.FILER
                        Else
                            Console.WriteLine(Environment.NewLine & "ERROR: Invalid Option for Server type")
                            Usage()
                        End If
                        index = index + 2

                    Case "v"
                        vfiler = args(index + 1)
                        index = index + 2

                    Case "r"
                        authStyle = NaServer.AUTH_STYLE.RPC
                        useRPC = True
                        index = index + 1

                    Case "n"
                        transportType = NaServer.TRANSPORT_TYPE.HTTP
                        index = index + 1

                    Case "p"
                        status = Int32.TryParse(args(index + 1), port)
                        If (status = False) Then
                            Console.WriteLine(Environment.NewLine & "ERROR: Invalid port no")
                            Usage()
                        End If
                        index = index + 2
                    Case "h"
                        authStyle = NaServer.AUTH_STYLE.HOSTSEQUIV
                        useHostsEquiv = True
                        index = index + 1
                    Case "c"
                        status = Int32.TryParse(args(index + 1), timeOut)
                        If (status = False Or timeOut <= 0) Then
                            Console.WriteLine(Environment.NewLine & "ERROR: Invalid timeout value")
                            Usage()
                        End If
                        index = index + 2

                    Case "o"
                        originatorId = args(index + 1)
                        index = index + 2

                    Case "i"
                        inputXML = 1
                        index = index + 1

                    Case "I"
                        inputXML = 2
                        index = index + 1

                    Case "x"
                        showXML = 1
                        index = index + 1

                    Case "X"
                        showXML = 2
                        index = index + 1

                    Case "C"
                        certFile = args(index + 1)
                        useCBA = True
                        index = index + 2

                    Case "P"
                        useCBA = True
                        certPasswd = args(index + 1)
                        index = index + 2

                    Case "T"
                        Dim name As String = args(index + 1)
                        Select Case name
                            Case "AuthRoot"
                                storeName = NaServer.CERT_STORE_NAME.AUTH_ROOT
                            Case "CertificateAuthority"
                                storeName = NaServer.CERT_STORE_NAME.CERTIFICATE_AUTHORITY
                            Case "My"
                                storeName = NaServer.CERT_STORE_NAME.MY
                            Case "Root"
                                storeName = NaServer.CERT_STORE_NAME.ROOT
                            Case "TrustedPeople"
                                storeName = NaServer.CERT_STORE_NAME.TRUSTED_PEOPLE
                            Case Else
                                Console.WriteLine("Invalid store name: " + name)
                                Console.WriteLine("Valid store names are: ")
                                Console.WriteLine("My - certificate store for personal certificates")
                                Console.WriteLine("Root - certificate store for trusted root certificate authorities")
                                Console.WriteLine("AuthRoot - certificate store for third-party certificate authorities")
                                Console.WriteLine("CertificateAuthority - certificate store for intermediate certificate authorities")
                                Console.WriteLine("TrustedPeople - certificate store for directly trusted people and resources")
                                Usage()
                        End Select
                        index = index + 2

                    Case "L"
                        Dim loc As String = args(index + 1)
                        Select Case loc
                            Case "LocalMachine"
                                storeLocation = NaServer.CERT_STORE_LOCATION.LOCAL_MACHINE

                            Case "CurrentUser"
                                storeLocation = NaServer.CERT_STORE_LOCATION.CURRENT_USER
                            Case Else
                                Console.WriteLine("Invalid store location: " + loc)
                                Console.WriteLine("Valid store locations are: ")
                                Console.WriteLine("CurrentUser - certificate store used by the current user")
                                Console.WriteLine("LocalMachine - certificate store assigned to the local machine")
                                Usage()
                        End Select
                        index = index + 2

                    Case "N"
                        certName = args(index + 1)
                        useCBA = True
                        index = index + 2

                    Case "S"
                        verifyServerCert = True
                        index = index + 1

                    Case "H"
                        verifyHostname = True
                        index = index + 1

                    Case Else
                        Console.WriteLine(Environment.NewLine & "ERROR: Invalid Option")
                        Usage()
                End Select
                If (index >= args.Length) Then
                    Exit While
                End If
            End While

        Catch ex As System.IndexOutOfRangeException
            Console.WriteLine(Environment.NewLine & "ERROR: Invalid number of arguments")
            Usage()
        End Try

        If (authStyle = NaServer.AUTH_STYLE.LOGIN_PASSWORD And args.Length < 3) Then
            Usage()
        End If

        If (useHostsEquiv = True And useRPC = True) Then
            Console.WriteLine(Environment.NewLine & "ERROR: Invalid usage of " & _
                "authentication style. Do not use -r option and -h option together.")
            System.Environment.Exit(1)
        End If
        If (useRPC = True And timeOut <> -1) Then
            Console.WriteLine(Environment.NewLine & "ERROR: Connection timeout " & _
                "value cannot be set for RPC authentication style.")
            System.Environment.Exit(1)
        End If
        If (verifyHostname = True And verifyServerCert = False) Then
            Console.WriteLine(Environment.NewLine & "ERROR: Hostname verification cannot be enabled when server certificate verification is disabled.")
            Environment.Exit(1)
        End If
        If index = args.Length Then
            Console.WriteLine(Environment.NewLine & "ERROR: Host not specified.")
            Usage()
        End If

        If (useCBA) Then
            transportType = NaServer.TRANSPORT_TYPE.HTTPS
            authStyle = NaServer.AUTH_STYLE.CERTIFICATE
        End If
        If authStyle = NaServer.AUTH_STYLE.LOGIN_PASSWORD Then
            If index + 1 = args.Length Then
                Console.WriteLine(Environment.NewLine & "ERROR: User not specified.")
                Usage()
            End If
            If index + 2 = args.Length Then
                Console.WriteLine(Environment.NewLine & "ERROR: Password not specified.")
                Usage()
            End If
        End If

        If port = -1 Then
            Select Case serverType
                Case NaServer.SERVER_TYPE.FILER
                    port = IIf(transportType = NaServer.TRANSPORT_TYPE.HTTP, 80, 443)

                Case NaServer.SERVER_TYPE.DFM
                    port = IIf(transportType = NaServer.TRANSPORT_TYPE.HTTP, 8088, 8488)

                Case NaServer.SERVER_TYPE.OCUM
                    port = 443

                Case NaServer.SERVER_TYPE.AGENT
                    port = IIf(transportType = NaServer.TRANSPORT_TYPE.HTTP, 4092, 4093)

                Case Else
                    port = IIf(transportType = NaServer.TRANSPORT_TYPE.HTTP, 80, 443)
            End Select
        End If

        Try

            '1. Create an instance of NaServer object
            ' NaServer is called to connect to servers and invoke API's.
            ' The argument passed should be 
            ' NaServer(hostName, major API version number, minor API version number).
            '
            If vfiler <> Nothing Then
                ' Vfiler tunnelling requires ONTAPI version 7.0 to work 
                s = New NaServer(args(index), 1, 7)
            Else
                s = New NaServer(args(index), 1, 0)
            End If

            index = index + 1

            '2. Set the server type
            s.ServerType = serverType

            '3. Set the transport type
            s.TransportType = transportType

            '4. Set the authentication style for subsequent ONTAPI authentications.
            s.Style = authStyle

            '5. Set the login and password used for authenticating when
            'an ONTAPI API is invoked.
            If (authStyle = NaServer.AUTH_STYLE.LOGIN_PASSWORD) Then
                s.SetAdminUser(args(index), args(index + 1))
                index = index + 2
            End If



            '6. Set the port number
            s.Port = port

            '7. Optional - set the vfiler name for vfiler tunneling
            If vfiler <> Nothing Then
                s.SetVfilerTunneling(vfiler)
            End If

            'Check if originator_id is set
            If originatorId <> Nothing Then
                s.OriginatorId = originatorId
            End If

            'Set the request timeout.
            If timeOut <> -1 Then
                s.TimeOut = timeOut
            End If

            If useCBA Then
                If certFile = Nothing And certPasswd <> Nothing Then
                    Console.WriteLine(Environment.NewLine & "ERROR: Certificate file not specified.")
                    Usage()
                End If
                If certFile <> Nothing Then
                    If certPasswd <> Nothing Then
                        s.SetClientCertificate(certFile, certPasswd)
                    Else
                        s.SetClientCertificate(certFile)
                    End If
                Else
                    s.SetClientCertificate(storeName, storeLocation, certName)
                End If
            End If

            s.ServerCertificateVerification = verifyServerCert
            If (verifyServerCert) Then
                s.HostnameVerification = verifyHostname
            End If
            s.Snoop = 1

            'Invoke any  ONTAPI API with arguments
            ' in (key,value) pair 
            ' args(0)=filer,args(1)=user,args(2)=passwd
            ' args(3)=Ontapi API,args(4) onward arguments
            ' in (key,value) pair
            Try
                If inputXML = 0 Then
                    If index = args.Length Then
                        Console.WriteLine(Environment.NewLine & "ERROR: API not specified.")
                        Usage()
                    End If
                    '8. Create an instance of NaElement which contains the ONTAPI API request
                    xi = New NaElement(args(index))
                Else
                    'Only use this for debugging
                    GetXMLInput(inputXML, args, index)
                    index = index + 1
                    xi = s.ParseXMLInput(args(index))
                End If

                If (args.Length > index + 1) Then
                    Dim index2 As Integer
                    For index2 = index + 1 To args.Length - 1
                        '9. Optional - add the child elements to the parent 
                        xi.AddNewChild(args(index2), args(index2 + 1))
                        index2 = index2 + 1
                    Next index2
                End If

                'Only use this for debugging purpose
                If showXML > 0 Then
                    If showXML = 1 Then
                        Console.WriteLine("INPUT:" & Environment.NewLine & xi.ToPrettyString(""))
                    Else
                        s.DebugStyle = NaServer.DEBUG_STYLE.PRINT_PARSE
                    End If
                End If

            Catch ex As System.IndexOutOfRangeException
                Throw New NaApiFailedException("Mismatch in arguments passed " & _
                                               "(in (key,value) Pair) to " & _
                                                "Ontapi API", -1)
            End Try

            '10. Invoke a single ONTAPI API to the server.
            'The response is stored in xo.
            xo = s.InvokeElem(xi)

            'Only use this for debugging purpose
            If showXML > 0 Then
                If showXML = 1 Then
                    Console.WriteLine("OUTPUT:" & Environment.NewLine & xo.ToPrettyString(""))
                End If
            Else
                '11. Print the ONTAPI API response that is returned by the server
                Console.WriteLine(xo.ToPrettyString(""))
            End If
        Catch ex As NaApiFailedException
            Console.Error.WriteLine(ex.Message)
        Catch ex As Exception
            Console.Error.WriteLine(ex.Message)
        End Try
    End Sub
End Module
