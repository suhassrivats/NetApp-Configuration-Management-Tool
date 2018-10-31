//================================================================//
//						                                          //
// $Id:$                                                          //
// encrypt_string.cs					       	                  //
//                              								  //
// Demonstrates usage of AddNewEncryptedChild() and               //
//          GetChildEncryptContent() core APIs        	          //
//                              								  //
// Copyright 2008 NetApp. All rights		                      //
// reserved. Specifications subject to change without notice.     //
//								                                  //
// This SDK sample code is provided AS IS, with no support or 	  //
// warranties of any kind, including but not limited to 	      //
// warranties of merchantability or fitness of any kind,	      //
// expressed or implied.  This code is subject to the license     //
// agreement that accompanies the SDK.				              //
//								                                  //
//								                                  //
// Usage: encrypt_string <filer> <user> <password> <test-password>//
//================================================================//
using System;
using NetApp.Manage;

namespace encrypt_string
{
    class EncryptString
    {
        static void Main(string[] args)
        {
            NaElement xi;
            NaElement xo;
            NaServer s;
            String decPasswd;

            if (args.Length < 4)
            {
                Console.Error.WriteLine("Usage: encrypt_string <filer> <user> <password> <test-password>");
                Environment.Exit(1);
            }

            String server = args[0], user = args[1], pwd = args[2], testPwd = args[3];

            try
            {
                Console.WriteLine("|--------------------------------------------------|");
                Console.WriteLine("| Program to demo use of encrypted child elements  |");
                Console.WriteLine("|--------------------------------------------------|\n");

                //Initialize connection to server, and
                //request version 1.3 of the API set
                //	
                s = new NaServer(server, 1, 1);
                s.Style = NaServer.AUTH_STYLE.LOGIN_PASSWORD;
                s.SetAdminUser(user, pwd);

                //Create input element
                xi = new NaElement("test-password-set");
                xi.AddNewEncryptedChild("password", testPwd);

                //try to get the decrypted password
                decPasswd = xi.GetChildEncryptContent("password");
                Console.WriteLine("Expected decrypted password from server:" + decPasswd);
	
                //Invokes ONTAPI API 
                xo = s.InvokeElem(xi);

                //Display output in XML format
                Console.WriteLine("\nOUTPUT XML:");
                String output = xo.ToString();
                Console.WriteLine(output);
            }
            catch (NaAuthException e)
            {
                System.Console.Error.WriteLine("Authorization Failed: " + e.Message);
            }
            catch (NaApiFailedException e)
            {
                System.Console.Error.WriteLine("API FAILED: " + e.Message);
            }
            catch (Exception e)
            {
                System.Console.Error.WriteLine(e.Message);
            }
        }
    }
}
