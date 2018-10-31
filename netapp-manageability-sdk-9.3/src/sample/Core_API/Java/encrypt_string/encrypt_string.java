/*
 * $Id:$
 *
 * encrypt_string.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample code for using the netapp.manage.* classes to
 * make use of addNewEncryptedChild and getChildEncryptContent core APIs.
 */
import netapp.manage.*;

public class encrypt_string {
    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        String testPasswd;
        String encString;

        if (args.length < 4) {
            System.err
                    .println("Usage: encrypt_string  <filer> <user> <password> <test-password>");
            System.exit(1);
        }
        try {
            // Initialize connection to server, and
            // request version 1.3 of the API set
            //
            s = new NaServer(args[0], 1, 1);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);
            testPasswd = args[3];

            // Note: 'test-password-set' API is unsupported.
            // It's used here to demonstrate use addNewEncryptedChild().

            // 'test-password-set' is a test routine to test encrypted values.
            //
            // Input Name : password
            // Type : string encrypted
            // Description : Test password
            //
            // Output Name : decrypted-password
            // Type : string
            // Description : Resulting decrypted password.
            xi = new NaElement("test-password-set");

            // Encrypts data contained in content. Adds a new child element
            // with a given name and encrypted content.
            xi.addNewEncryptedChild("password", testPasswd);

            // decrypt the encrypted password.This should be same as testPasswd
            encString = xi.getChildEncryptContent("password");

            System.out.println("Expected decrypted password from server:"
                    + encString + "\n");

            // Invoke the API to the server.
            xo = s.invokeElem(xi);
            System.out.println(xo.toPrettyString(""));

            s.close();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
