/*
 * Copyright (c) 2001-2003 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample code to describe how to create, split
 * estimate and see the status for flexclone.
 */

import java.io.IOException;
import java.net.UnknownHostException;
import java.util.List;
import java.util.Iterator;
import java.lang.Object;
import netapp.manage.*;

public class flexclone {

    private static NaServer s;

    private static void printUsage() {
        System.out.println("Usage: flexclone <filer> <user>"
                + " <password> <command> <clone_volname> [<parent>]");
        System.out.println(" <filer> - the name/ipaddress of the filer");
        System.out.println(" <user>,<password> - User and password for "
                + "remote authentication");
        System.out.println(" <command> - command to be executed. The "
                + "possible value are:");
        System.out.println(" create - to create a new clone");
        System.out.println(" estimate - to estimate the size "
                + "before spliting the clone");
        System.out.println(" split - to split the clone ");
        System.out.println(" status - give the status of the clone");
        System.out.println(" <clone_volname> - desired name of the clone "
                + "volume ");
        System.out.println(" <parent> - name of the parent volume to "
                + " create  the clone. This option is only valid for "
                + "\"create\" command");
    }

    /*
     * Function: createFlexClone Description: Function to demostrate
     * "vol-clone-create" api to create a new flexclone. Parameters: clonename -
     * name of the clone parentclone - parent of the new clone Return: 0 if
     * successful otherwise a negative value
     */

    int createFlexClone(String clonename, String parentvol) {
        try {
            NaElement xi;
            NaElement xo;
            xi = new NaElement("volume-clone-create");
            xi.addNewChild("parent-volume", parentvol);
            xi.addNewChild("volume", clonename);
            xo = s.invokeElem(xi);
            System.out.println(" Creation of clone " + "volume '" + clonename
                    + "' has completed\n");
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println(e.getMessage());
            return -1;
        }

        return 0;
    }

    /*
     * Function: estimateCloneSplit Description: Function to demostrate
     * "volume-clone-split-estimate" api to estimate the size for flexclone
     * split Parameters: clonename - name of the clone parentclone - parent of
     * the new clone Return: 0 if successful otherwise a negative value
     */
    int estimateCloneSplit(String clonename) {
        try {
            NaElement xi, xo;
            xi = new NaElement("volume-clone-split-estimate");
            xi.addNewChild("volume", clonename);
            xo = s.invokeElem(xi);

            NaElement cloneSplitEstimate = xo
                    .getChildByName("clone-split-estimate");
            /*
             * block estimate is given in no of 4kb blocks required
             */
            int splitEstInMB = cloneSplitEstimate.getChildIntValue(
                    "estimate-blocks", 0) * 4 / 1000;
            System.out.println("An estimated " + splitEstInMB
                    + "mb available storage is " + "required in the"
                    + " aggregate to split clone" + " volume '" + clonename
                    + "' from its parent.");
        } catch (Exception e) {
            e.printStackTrace();
            return -2;
        }
        return 0;
    }

    /*
     * Function: startCloneSplit Description: Function to demostrate using
     * "volume-clone-split-start" api to split a flexclone Parameters: clonename
     * - name of the clone Return: 0 if successful otherwise a negative value
     */
    int startCloneSplit(String clonename) {
        try {
            NaElement xi, xo;
            xi = new NaElement("volume-clone-split-start");
            xi.addNewChild("volume", clonename);
            xo = s.invokeElem(xi);
            System.out.println("Starting volume clone split on" + " volume '"
                    + clonename + "'.\n.Use 'status'"
                    + " command to monitor progress");

        } catch (Exception e) {
            e.printStackTrace();
            return -3;
        }

        return 0;
    }

    /*
     * Function: cloneSplitStatus Description: Function to demostrate using
     * "volume-clone-split-status" api to query the progress of the flexclone
     * split Parameters: clonename - name of the clone Return: 0 if successful
     * otherwise a negative value
     */
    int cloneSplitStatus(String clonename) {
        try {
            NaElement xi, xo;
            xi = new NaElement("volume-clone-split-status");
            xi.addNewChild("volume", clonename);
            xo = s.invokeElem(xi);

            /*
             * Retrieve the clone status parameters: blocks-scanned: integer -
             * Number of the clone's blocks that have been scanned to date by
             * the split. blocks-updated integer - Total number of the clone's
             * blocks that have been updated to date by the split.
             * inode-percentage-complete integer - Percent of the clone's inodes
             * processed to date by I the split. inodes-processed integer -
             * Number of the clone's inodes processed to date byI the split.
             * inodes-total integer - Total number of inodes in the clone. name
             * string - Name of the clone being split.
             */
            List cloneStatusList = xo.getChildByName("clone-split-details")
                    .getChildren();

            for (Iterator i = cloneStatusList.iterator(); i.hasNext();) {
                NaElement cloneStatus = (NaElement) i.next();
                int blkScanned = cloneStatus.getChildIntValue("blocks-scanned",
                        0);
                int blkUpdated = cloneStatus.getChildIntValue("blocks-updated",
                        0);
                ;
                int inodeProcessed = cloneStatus.getChildIntValue(
                        "inodes-processed", 0);
                int inodeTotal = cloneStatus
                        .getChildIntValue("inodes-total", 0);
                int inodePerComplete = cloneStatus.getChildIntValue(
                        "inode-percentage-complete", 0);

                System.out.print("Volume '" + clonename + "'," + inodeProcessed
                        + "of " + inodeTotal + "inodes processed ("
                        + inodePerComplete + "%).");
                System.out.println(blkScanned + " blocks scanned." + blkUpdated
                        + " blocks updated.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            return -3;
        }

        return 0;
    }

    public static void main(String[] args) {

        if (args.length < 5 || args.length > 6
                || (args.length == 6 && args[3].equals("create") == false)) {
            printUsage();
            return;
        }

        if (!(args[3].equals("create") == true
                || args[3].equals("estimate") == true
                || args[3].equals("split") == true || args[3].equals("status") == true)) {
            System.out.println(args[3] + " is not a valid command.");
            printUsage();
            return;
        }

        if (args[4].equals("") == true
                || (args[3].equals("create") == true && args[5].equals("") == true)) {
            System.out.println("<clone_volname> and <parent> cannot"
                    + " be empty strings\n");
            printUsage();
            return;
        }

        String filer = args[0];
        String login = args[1];
        String password = args[2];
        String command = args[3];
        String clonename = args[4];

        try {
            s = new NaServer(filer, 1, 0);
        } catch (UnknownHostException e) {
            System.out.println("Unknown host: " + filer);
            System.exit(1);
            return;
        }

        s.setStyle(1);
        s.setAdminUser(login, password);
        System.out.println();

        /*
         * Exectute the command
         */
        flexclone execCmd = new flexclone();
        /*
         * Execute the Filer command
         */
        int ret = 0;
        if (command.equals("create")) {

            ret = execCmd.createFlexClone(clonename, args[5]);
        }

        if (command.equals("estimate")) {
            ret = execCmd.estimateCloneSplit(clonename);
        }

        if (command.equals("split")) {
            ret = execCmd.startCloneSplit(clonename);
        }

        if (command.equals("status")) {
            ret = execCmd.cloneSplitStatus(clonename);
        }
    }
}
