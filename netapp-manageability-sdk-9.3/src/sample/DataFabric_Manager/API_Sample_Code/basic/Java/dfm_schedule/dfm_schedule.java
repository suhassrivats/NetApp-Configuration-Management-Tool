/*
 * $Id:$
 *
 * dfm_schedule.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * This program will help managing the dfm schedules
 * You can create, list and delete dfm schedules
 *
 * This Sample code is supported from DataFabric Manager 3.6R2
 * onwards.
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */

import netapp.manage.*;
import java.io.*;
import java.lang.*;
import java.io.StringReader;
import java.util.List;
import java.util.Iterator;

public class dfm_schedule {
    private static NaServer server;
    private static String[] Arg;

    public static void USAGE() {
        System.out
                .println(""
                        + "Usage:\n"
                        + "dfm_schedule <dfmserver> <user> <password> list [ <schedule> ]\n"
                        + "\n"
                        + "dfm_schedule <dfmserver> <user> <password> delete <schedule>\n"
                        + "\n"
                        + "dfm_schedule <dfmserver> <user> <password> create <schedule> daily\n"
                        + "[ -h <shour> -m <sminute> ]\n"
                        + "\n"
                        + "dfm_schedule <dfmserver> <user> <password> create <schedule> weekly\n"
                        + "[ -d <dweek>] [ -h <shour> -m <sminute> ]\n"
                        + "\n"
                        + "dfm_schedule <dfmserver> <user> <password> create <schedule> monthly\n"
                        + "{ [ -D <dmonth> ] | [ -d <dweek> -w <wmonth> ] } [ -h <shour> -m <sminute>]\n"
                        + "\n"
                        + "<operation>     -- create or delete or list\n"
                        + "<schedule type> -- daily or weekly or monthly\n"
                        + "\n"
                        + "<dfmserver> -- Name/IP Address of the DFM server\n"
                        + "<user>      -- DFM server User name\n"
                        + "<password>  -- DFM server User Password\n"
                        + "<schedule>  -- Schedule name\n"
                        + "<dmonth>    -- Day of the month. Range: [1..31]\n"
                        + "<dweek>     -- Day of week for the schedule. Range: [0..6] (0 = \"Sun\")\n"
                        + "<shour>     -- Start hour of schedule. Range: [0..23]\n"
                        + "<sminute>   -- Start minute of schedule. Range: [0..59]\n"
                        + "<wmonth>    -- A value of 5 indicates the last week of the month. Range: "
                        + "[1..5]\n"
                        + "\n"
                        + "Note : Either <dweek> and <wmonth> should to be set, or <dmonth> should"
                        + " be set");
        System.exit(1);
    }

    public static void main(String[] args) {

        Arg = args;
        int arglen = Arg.length;
        // Checking for valid number of parameters
        if (arglen < 4)
            USAGE();

        String dfmserver = Arg[0];
        String dfmuser = Arg[1];
        String dfmpw = Arg[2];
        String dfmop = Arg[3];

        // checking for valid number of parameters for the respective operations
        if ((dfmop.equals("list") && arglen < 4)
                || (dfmop.equals("delete") && arglen != 5)
                || (dfmop.equals("create") && arglen < 6))
            USAGE();

        // checking if the operation selected is valid
        if ((!dfmop.equals("list")) && (!dfmop.equals("create"))
                && (!dfmop.equals("delete")))
            USAGE();

        try {
            // Initialize connection to server, and
            // request version 1.0 of the API set
            //
            // Creating a server object and setting appropriate attributes
            server = new NaServer(dfmserver, 1, 0);
            server.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            server.setServerType(NaServer.SERVER_TYPE_DFM);

            server.setAdminUser(dfmuser, dfmpw);

            // Calling the functions based on the operation selected
            if (dfmop.equals("create"))
                create();
            else if (dfmop.equals("list"))
                list();
            else if (dfmop.equals("delete"))
                delete();
            else
                USAGE();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static String result(String result) {
        // Checking for the string "passed" in the output
        String r = (result.equals("passed")) ? "Successful" : "UnSuccessful";
        return r;
    }

    public static void create() {
        String startHour = null;
        String startMinute = null;
        String dayOfWeek = null;
        String dayOfMonth = null;
        String weekOfMonth = null;
        // Getting the schedule name and type
        String dfmSchedule = Arg[4];
        String scheduleType = Arg[5];

        // Checking if the type selected is valid
        if ((!scheduleType.equals("daily")) && (!scheduleType.equals("weekly"))
                && (!scheduleType.equals("monthly")))
            USAGE();

        // parsing optional parameters
        int i = 6;
        while (i < Arg.length) {
            if (Arg[i].equals("-h")) {
                startHour = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-m")) {
                startMinute = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-d")) {
                dayOfWeek = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-D")) {
                dayOfMonth = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-w")) {
                weekOfMonth = Arg[++i];
                ++i;
            } else {
                USAGE();
            }

        }

        try {
            // creating the input for api execution
            // creating a dfm-schedule-create element and adding child elements
            NaElement input = new NaElement("dfm-schedule-create");
            NaElement schedule = new NaElement("schedule-content-info");
            schedule.addNewChild("schedule-name", dfmSchedule);
            schedule.addNewChild("schedule-type", scheduleType);
            schedule.addNewChild("schedule-category", "dfm_schedule");

            // creating a daily-list element
            if (scheduleType.equals("daily")
                    && (startHour != null || startMinute != null)) {
                NaElement daily = new NaElement("daily-list");
                NaElement dailyInfo = new NaElement("daily-info");
                if (startHour != null)
                    dailyInfo.addNewChild("start-hour", startHour);
                if (startMinute != null)
                    dailyInfo.addNewChild("start-minute", startMinute);
                daily.addChildElem(dailyInfo);
                // appending daily list to schedule
                schedule.addChildElem(daily);
            }

            // creating a weekly-list element
            if (scheduleType.equals("weekly")
                    && (startHour != null || startMinute != null || dayOfWeek != null)) {
                NaElement weekly = new NaElement("weekly-list");
                NaElement weeklyInfo = new NaElement("weekly-info");
                if (startHour != null)
                    weeklyInfo.addNewChild("start-hour", startHour);
                if (startMinute != null)
                    weeklyInfo.addNewChild("start-minute", startMinute);
                if (dayOfWeek != null)
                    weeklyInfo.addNewChild("day-of-week", dayOfWeek);
                weekly.addChildElem(weeklyInfo);
                // appending weekly list to schedule
                schedule.addChildElem(weekly);
            }

            // creating 2 monthly-list element
            if (scheduleType.equals("monthly")
                    && (startHour != null || startMinute != null
                            || dayOfWeek != null || dayOfMonth != null || weekOfMonth != null)) {
                NaElement monthly = new NaElement("monthly-list");
                NaElement monthlyInfo = new NaElement("monthly-info");
                if (startHour != null)
                    monthlyInfo.addNewChild("start-hour", startHour);
                if (startMinute != null)
                    monthlyInfo.addNewChild("start-minute", startMinute);
                if (dayOfMonth != null)
                    monthlyInfo.addNewChild("day-of-month", dayOfMonth);
                if (dayOfWeek != null)
                    monthlyInfo.addNewChild("day-of-week", dayOfWeek);
                if (weekOfMonth != null)
                    monthlyInfo.addNewChild("week-of-month", weekOfMonth);
                monthly.addChildElem(monthlyInfo);
                // appending monthly list to schedule
                schedule.addChildElem(monthly);
            }

            // appending schedule to main input
            input.addChildElem(schedule);

            // invoking the api && printing the xml ouput
            NaElement output = server.invokeElem(input);

            System.out.println("\nSchedule creation "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void list() {
        String dfmSchedule = null;

        try {
            // creating a dfm schedule start element
            NaElement input = new NaElement("dfm-schedule-list-info-iter-start");
            input.addNewChild("schedule-category", "dfm_schedule");
            if (Arg.length > 4) {
                dfmSchedule = Arg[4];
                input.addNewChild("schedule-name-or-id", dfmSchedule);
            }

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            // Extracting the record && tag values && printing them
            String records = output.getChildContent("records");

            String tag = output.getChildContent("tag");

            if (records.equals("0"))
                System.out.println("\nNo schedules to display");

            // Extracting records one at a time
            input = new NaElement("dfm-schedule-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the schedule-content-list child element
            NaElement stat = record.getChildByName("schedule-content-list");

            // Navigating to the schedule-info child element
            List infoList = null;

            if (stat != null)
                infoList = stat.getChildren();
            if (infoList == null)
                return;

            Iterator infoIter = infoList.iterator();

            // Iterating through each record
            while (infoIter.hasNext()) {
                String value;
                NaElement info = (NaElement) infoIter.next();

                System.out.println("-----------------------------------------");
                // extracting the schedule details && printing it
                System.out.println("Schedule Name : "
                        + info.getChildContent("schedule-name"));

                System.out.println("Schedule Id          : "
                        + info.getChildContent("schedule-id"));

                System.out.println("Schedule Description : "
                        + info.getChildContent("schedule-description"));

                System.out.println("-----------------------------------------");

                // printing details if only one schedule is selected for listing
                if (dfmSchedule != null) {

                    System.out.println("\nSchedule Type        : "
                            + info.getChildContent("schedule-type"));

                    System.out.println("Schedule Category    : "
                            + info.getChildContent("schedule-category"));

                    String type = info.getChildContent("schedule-type");

                    NaElement typeList = info.getChildByName(type + "-list");
                    if (typeList != null) {
                        NaElement typeInfo = typeList.getChildByName(type
                                + "-info");

                        if (type.equals("daily")) {

                            System.out.println("Item Id              : "
                                    + typeInfo.getChildContent("item-id"));

                            value = typeInfo.getChildContent("start-hour");
                            System.out.print("Start Hour           : ");
                            if (value != null)
                                System.out.print(value);

                            value = typeInfo.getChildContent("start-minute");
                            System.out.print("\nStart Minute         : ");
                            if (value != null)
                                System.out.println(value);

                        } else if (type.equals("weekly")) {
                            System.out.println("Item Id              : "
                                    + typeInfo.getChildContent("item-id"));

                            value = typeInfo.getChildContent("start-hour");
                            System.out.print("Start Hour           : ");
                            if (value != null)
                                System.out.print(value);

                            value = typeInfo.getChildContent("start-minute");
                            System.out.print("\nStart Minute         : ");
                            if (value != null)
                                System.out.print(value);

                            value = typeInfo.getChildContent("day-of-week");
                            System.out.print("\nDay Of Week          : ");
                            if (value != null)
                                System.out.println(value);

                        } else if (type.equals("monthly")) {

                            System.out.println("Item Id              : "
                                    + typeInfo.getChildContent("item-id"));

                            value = typeInfo.getChildContent("start-hour");
                            System.out.print("Start Hour           : ");
                            if (value != null)
                                System.out.print(value);

                            value = typeInfo.getChildContent("start-minute");
                            System.out.print("\nStart Minute         : ");
                            if (value != null)
                                System.out.print(value);

                            value = typeInfo.getChildContent("day-of-week");
                            System.out.print("\nDay Of Week          : ");
                            if (value != null)
                                System.out.print(value);

                            value = typeInfo.getChildContent("week-of-month");
                            System.out.print("\nWeek Of Month        : ");
                            if (value != null)
                                System.out.print(value);

                            value = typeInfo.getChildContent("day-of-month");
                            System.out.print("\nDay Of Month         : ");
                            if (value != null)
                                System.out.println(value);
                        }
                    }
                }
            }

            // invoking the iter-end zapi
            input = new NaElement("dfm-schedule-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void delete() {
        String dfmSchedule = Arg[4];

        try {
            // invoking the api && printing the xml ouput
            NaElement input = new NaElement("dfm-schedule-destroy");
            input.addNewChild("schedule-name-or-id", dfmSchedule);
            input.addNewChild("schedule-category", "dfm_schedule");
            NaElement output = server.invokeElem(input);

            System.out.println("\nSchedule deletion "
                    + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}