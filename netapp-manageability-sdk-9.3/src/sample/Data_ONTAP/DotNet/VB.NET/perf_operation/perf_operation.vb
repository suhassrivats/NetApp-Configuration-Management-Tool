'======================================================================='
'                                                                       '
'                                                                       '
' perf_operation.vb                                                     '
'                                                                       '
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
'  Sample for usage of following perf group API:                        '
'          perf-object-list-info                                        '
'          perf-object-counter-list-info                                '
'          perf-object-instance-list-info                               '
'          perf-object-get-instances-iter-*                             '
'                                                                       '
' Usage:                                                                '
' perf_operation <filer> <user> <password> <operation>                  '
'                                                                       '
' <filer>      -- Name/IP address of the filer                          '
' <user>       -- User name                                             '
' <password>   -- Password                                              '
' <operation>  --                                                       '
'      object-list - Get the list of perforance objects                 '
'                in the system                                          '
'      instance-list - Get the list of instances for a given            '
'                  performance object                                   '
'      counter-list - Get the list of counters available for a          '
'                 given performance object                              '
'      get-counter-values - get the values of the counters for          '
'                   all instance of a performance object                '
'======================================================================='

Imports System
Imports System.Collections.Generic
Imports NetApp.Manage


Module Perf_Operation
    Public Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage: perf_operation <filer> <username> <passwd> <operation>")
        Console.WriteLine(Environment.NewLine & "Possible operations are:")
        Console.WriteLine("  object-list - Get the list of perforance objects in the system")
        Console.WriteLine("  instance-list - Get the list of instances for a given performance object")
        Console.WriteLine("  counter-list - Get the list of counters available for a given performance object")
        Console.WriteLine("  get-counter-values - get the values of the counters for all the instances of a performance object")
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
        Dim objName As String

        Try
            Dim server As New NaServer(serverName, 1, 3)
            server.ServerType = NaServer.SERVER_TYPE.FILER
            server.SetAdminUser(user, passwd)
            Dim input As NaElement
            Dim output As NaElement

            If operation = "object-list" Then
                input = New NaElement("perf-object-list-info")
                output = server.InvokeElem(input)
                Dim objList As IList(Of NaElement) = output.GetChildByName("objects").GetChildren()
                Dim objIter As IEnumerator(Of NaElement) = objList.GetEnumerator()

                While objIter.MoveNext()
                    Dim objInfo As NaElement = objIter.Current
                    Console.Out.Write("Object Name = " + objInfo.GetChildContent("name") + ControlChars.Tab)
                    Console.Out.WriteLine("privilege level = " + objInfo.GetChildContent("privilege-level"))
                    Console.Out.WriteLine()
                End While

            ElseIf operation = "instance-list" Then
                If args.Length < 5 Then
                    Console.Out.WriteLine("Usage:")
                    Console.Out.WriteLine("perf_operation <filer> <user> <password> <instance-list> <objectname>")
                    Environment.Exit(1)
                End If
                input = New NaElement("perf-object-instance-list-info")
                objName = args(4)
                input.AddNewChild("objectname", objName)
                output = server.InvokeElem(input)
                Dim instList As IList(Of NaElement) = output.GetChildByName("instances").GetChildren()
                Dim instIter As IEnumerator(Of NaElement) = instList.GetEnumerator()
                While instIter.MoveNext()
                    Dim instInfo As NaElement = instIter.Current
                    Console.Out.WriteLine("Instance Name = " + instInfo.GetChildContent("name"))
                End While

            ElseIf operation = "counter-list" Then
                If args.Length < 5 Then
                    Console.Out.WriteLine("Usage:")
                    Console.Out.WriteLine("perf_operation <filer> <user> <password> <counter-list> <objectname>")
                    System.Environment.Exit(1)
                End If

                input = New NaElement("perf-object-counter-list-info")
                objName = args(4)
                input.AddNewChild("objectname", objName)
                output = server.InvokeElem(input)
                Dim counterList As IList(Of NaElement) = output.GetChildByName("counters").GetChildren()
                Dim counterIter As IEnumerator(Of NaElement) = counterList.GetEnumerator()

                While counterIter.MoveNext()
                    Dim counterInfo As NaElement = counterIter.Current
                    Console.Out.Write("Counter Name = " + counterInfo.GetChildContent("name"))

                    If counterInfo.GetChildContent("base-counter") <> Nothing Then
                        Console.Out.Write("Base Counter = " + counterInfo.GetChildContent("base-counter"))
                    Else
                        System.Console.Out.Write(", Base Counter = none")
                    End If

                    Console.Out.Write(", Privilege Level = " + counterInfo.GetChildContent("privilege-level"))
                    If counterInfo.GetChildContent("unit") <> Nothing Then
                        Console.Out.Write(", Unit = " + counterInfo.GetChildContent("unit"))
                    Else
                        Console.Out.Write(", Unit = none")
                    End If
                    Console.WriteLine()
                    Console.WriteLine()
                End While

            ElseIf operation = "get-counter-values" Then
                Dim totalRecords As Integer = 0
                Dim maxRecords As Integer = 10
                Dim numRecords As Integer = 0
                Dim iterTag As String = Nothing

                If args.Length < 5 Then

                    System.Console.Out.WriteLine("Usage:")
                    System.Console.Out.WriteLine("perf_operation <filer> <user> <password> <get-counter-values> <objectname> [<counter1> <counter2> ...]")
                    System.Environment.Exit(1)
                End If

                input = New NaElement("perf-object-get-instances-iter-start")
                objName = args(4)
                input.AddNewChild("objectname", objName)
                Dim counters As NaElement = New NaElement("counters")

                'Now store rest of the counter names as child element of counters.
                ' Here it has been hard coded as 5 because first counter is specified at 6th position from 
                ' cmd prompt
                Dim counterIndex As Integer = 5


                While counterIndex < args.Length
                    counters.AddNewChild("counter", args(counterIndex))
                    counterIndex = counterIndex + 1
                End While

                If counterIndex > 5 Then
                    input.AddChildElement(counters)
                End If

                output = server.InvokeElem(input)
                totalRecords = output.GetChildIntValue("records", -1)
                iterTag = output.GetChildContent("tag")

                Do
                    input = New NaElement("perf-object-get-instances-iter-next")
                    input.AddNewChild("tag", iterTag)
                    input.AddNewChild("maximum", System.Convert.ToString(maxRecords))
                    output = server.InvokeElem(input)
                    numRecords = output.GetChildIntValue("records", 0)

                    If numRecords <> 0 Then

                        Dim instList As IList(Of NaElement) = output.GetChildByName("instances").GetChildren()
                        Dim instIter As IEnumerator(Of NaElement) = instList.GetEnumerator()

                        While instIter.MoveNext()

                            Dim instData As NaElement = instIter.Current
                            Console.Out.WriteLine("Instance = " + instData.GetChildContent("name"))

                            Dim counterList As IList(Of NaElement) = instData.GetChildByName("counters").GetChildren()
                            Dim counterIter As IEnumerator(Of NaElement) = counterList.GetEnumerator()

                            While counterIter.MoveNext()
                                Dim counterData As NaElement = counterIter.Current
                                System.Console.Out.Write("counter name = " + counterData.GetChildContent("name"))
                                Console.Out.WriteLine(ControlChars.Tab & "counter value = " + counterData.GetChildContent("value"))
                                Console.Out.WriteLine()
                            End While
                        End While
                    End If
                Loop While numRecords <> 0

                input = New NaElement("perf-object-get-instances-iter-end")
                input.AddNewChild("tag", iterTag)
                output = server.InvokeElem(input)
            Else
                Usage()
            End If
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try
    End Sub

End Module
