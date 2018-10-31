Imports System
Imports System.Collections.Generic
Imports NetApp.Manage

Module SnapMan
    Public Sub Usage()
        Console.WriteLine(Environment.NewLine & "Usage: snapman <-list|-create|-rename|-delete> <filer> <user> <passwd> <vol> ")
        Console.WriteLine(Environment.NewLine & " -list <filer> <user> <passwd> <vol> ")
        Console.WriteLine(" -create <filer> <user> <passwd> <vol> <snapshotname> ")
        Console.WriteLine(" -rename <filer> <user> <passwd> <vol> <oldsnapshotname> <newname>")
        Console.WriteLine(" -delete <filer> <user> <passwd> <vol> <snapshotname>")
        Console.WriteLine(" -schedule <filer> <user> <passwd> <vol>")
        Console.WriteLine(Environment.NewLine & "E.g. snapman -list filer1 root 6a55w0r9 vol0")
        Environment.Exit(-1)
    End Sub

    Public Sub CreateSnapshot(ByVal args() As String)
        Dim serverName As String = args(1)
        Dim user As String = args(2)
        Dim passwd As String = args(3)
        Dim volume As String = args(4)
        Dim snapshot As String = ""
        Dim server As NaServer
        Dim input As NaElement
        Dim output As NaElement

        Try

            server = New NaServer(serverName, 1, 0)
            server.SetAdminUser(user, passwd)

            input = New NaElement("snapshot-create")
            If args.Length = 6 Then
                snapshot = args(5)
                input.AddNewChild("volume", volume)
                input.AddNewChild("snapshot", snapshot)
            Else
                Console.Error.WriteLine("Invalid number of arguments")
                Usage()
                Environment.Exit(-1)
            End If
            output = server.InvokeElem(input)
            Console.WriteLine("Snapshot " + snapshot + " created for volume " + volume + " on filer " + serverName)
        Catch ex As Exception
            Console.Error.WriteLine("ERROR: " + ex.Message)
        End Try
    End Sub
    Public Sub DeleteSnapshot(ByVal args() As String)

        Dim serverName As String = args(1)
        Dim user As String = args(2)
        Dim passwd As String = args(3)
        Dim volume As String = args(4)
        Dim snapshot As String = ""
        Dim server As NaServer
        Dim input As NaElement
        Dim output As NaElement

        Try
            server = New NaServer(serverName, 1, 0)
            server.SetAdminUser(user, passwd)
            input = New NaElement("snapshot-delete")

            If args.Length = 6 Then
                snapshot = args(5)
                input.AddNewChild("volume", volume)
                input.AddNewChild("snapshot", snapshot)
            Else
                Console.Error.WriteLine("Invalid number of arguments")
                Usage()
                Environment.Exit(-1)
            End If
            output = server.InvokeElem(input)
            Console.WriteLine("Snapshot " + snapshot + " deleted from volume " + volume + " on filer " + serverName)

        Catch ex As Exception
            Console.Error.WriteLine("ERROR: " + ex.Message)
        End Try
    End Sub
    Public Sub RenameSnapshot(ByVal args() As String)

        Dim serverName As String = args(1)
        Dim user As String = args(2)
        Dim passwd As String = args(3)
        Dim volume As String = args(4)
        Dim oldSnapshot As String = ""
        Dim newSnapshot As String = ""
        Dim server As NaServer
        Dim input As NaElement
        Dim output As NaElement

        Try
            server = New NaServer(serverName, 1, 0)
            server.SetAdminUser(user, passwd)
            input = New NaElement("snapshot-rename")

            If args.Length = 7 Then
                oldSnapshot = args(5)
                newSnapshot = args(6)
                input = New NaElement("snapshot-rename")
                input.AddNewChild("volume", volume)
                input.AddNewChild("current-name", oldSnapshot)
                input.AddNewChild("new-name", newSnapshot)
            Else
                Console.Error.WriteLine("Invalid number of arguments")
                Usage()
                Environment.Exit(-1)
            End If

            output = server.InvokeElem(input)
            Console.WriteLine("Snapshot " + oldSnapshot + " renamed to " + newSnapshot + " for volume " + volume + " on filer " + serverName)
        Catch ex As Exception
            Console.Error.WriteLine("ERROR: " + ex.Message)
        End Try
    End Sub
    Public Sub ListInfo(ByVal args() As String)

        Dim serverName As String = args(1)
        Dim user As String = args(2)
        Dim passwd As String = args(3)
        Dim volume As String = args(4)
        Dim server As NaServer
        Dim input As NaElement
        Dim output As NaElement

        Try

            server = New NaServer(serverName, 1, 0)
            server.SetAdminUser(user, passwd)
            input = New NaElement("snapshot-list-info")
            input.AddNewChild("volume", volume)
            output = server.InvokeElem(input)

            Dim snapshots As IList = output.GetChildByName("snapshots").GetChildren()
            Dim snapiter As IEnumerator = snapshots.GetEnumerator()
            While snapiter.MoveNext()

                Dim snapshot As NaElement = snapiter.Current
                Console.WriteLine("SNAPSHOT:")
                Dim accessTime As Integer = snapshot.GetChildIntValue("access-time", 0)
                Dim dateTime As DateTime = New DateTime(1970, 1, 1, 0, 0, 0).AddSeconds(accessTime)
                Console.WriteLine(" NAME=" + snapshot.GetChildContent("name"))
                Console.WriteLine(" ACCESS TIME (GMT)=" + dateTime)
                Console.WriteLine(" BUSY= " + snapshot.GetChildContent("busy"))
                Console.WriteLine(" TOTAL (of 1024B)= " + snapshot.GetChildContent("total"))
                Console.WriteLine(" CUMULATIVE TOTAL (of 1024B)= " + snapshot.GetChildContent("cumulative-total"))
                Console.WriteLine(" DEPENDENCY= " + snapshot.GetChildContent("dependency"))
                Console.WriteLine()
            End While
        Catch ex As Exception
            Console.Error.WriteLine("ERROR: " + ex.Message)
        End Try

    End Sub
    Public Sub GetSchedule(ByVal args() As String)

        Dim serverName As String = args(1)
        Dim user As String = args(2)
        Dim passwd As String = args(3)
        Dim volume As String = args(4)
        Dim server As NaServer
        Dim input As NaElement
        Dim output As NaElement

        Try

            server = New NaServer(serverName, 1, 0)
            server.SetAdminUser(user, passwd)

            input = New NaElement("snapshot-get-schedule")
            If args.Length = 5 Then

                input.AddNewChild("volume", volume)

            Else

                Console.Error.WriteLine("Invalid number of arguments")
                Usage()
                Environment.Exit(-1)
            End If

            output = server.InvokeElem(input)
            Console.WriteLine("Snapshot schedule for volume " + volume + " on filer " + serverName)
            Console.WriteLine("---------------------------------------------------------------")
            Console.WriteLine("Snapshots are taken on minutes [" + output.GetChildContent("which-minutes") + "] of each hour (" + output.GetChildContent("minutes") + " kept)")
            Console.WriteLine("Snapshots are taken on hours [" + output.GetChildContent("which-hours") + "] of each day (" + output.GetChildContent("hours") + " kept)")
            Console.WriteLine(output.GetChildContent("days") + " nightly snapshots are kept")
            Console.WriteLine(output.GetChildContent("weeks") + " weekly snapshots are kept")
            Console.WriteLine("")

        Catch ex As Exception
            Console.Error.WriteLine("ERROR: " + ex.Message)
        End Try
    End Sub



    Sub Main(ByVal args As String())

        If (args.Length < 5) Then
            Usage()
            Exit Sub
        End If

        Select Case args(0)
            Case "-create"
                CreateSnapshot(args)
            Case "-rename"
                RenameSnapshot(args)
            Case "-delete"
                DeleteSnapshot(args)
            Case "-list"
                ListInfo(args)
            Case "-schedule"
                GetSchedule(args)
            Case Else
                Usage()
        End Select
    End Sub
End Module

