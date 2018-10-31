#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dfm_schedule.py                                               #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage dfm schedule         #
# on a DFM server                                               #
# You can create, list and delete dfm schedules                 #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

import re
import sys
sys.path.append("../../../../../../lib/python/NetApp")
from NaServer import * 

def usage():
    print ("Usage:dfm_schedule.py <dfmserver> <user> <password> list [ <schedule> ]\n")
    print ("dfm_schedule.py <dfmserver> <user> <password> delete <schedule>\n")
    print ("dfm_schedule.py <dfmserver> <user> <password> create <schedule> daily [ -h <shour> -m <sminute> ]\n")
    print ("dfm_schedule.py <dfmserver> <user> <password> create <schedule> weekly [ -d <dweek>] [ -h <shour> -m <sminute> ]\n")
    print ("dfm_schedule.py <dfmserver> <user> <password> create <schedule> monthly { [ -D <dmonth> ] | [ -d <dweek> -w <wmonth> ] } [ -h <shour> -m <sminute>]\n")
    print ("<operation>     -- create or delete or list\n")
    print ("<schedule type> -- daily or weekly or monthly\n")
    print ("<dfmserver> -- Name/IP Address of the DFM server\n")
    print ("<user>      -- DFM server User name\n")
    print ("<password>  -- DFM server User Password\n")
    print ("<schedule>  -- Schedule name\n")
    print ("<dmonth>    -- Day of the month. Range: [1..31]\n")
    print ("<dweek>     -- Day of week for the schedule. Range: [0..6] (0 = \"Sun\")\n")
    print ("<shour>     -- Start hour of schedule. Range: [0..23]\n")
    print ("<sminute>   -- Start minute of schedule. Range: [0..59]\n")
    print ("<wmonth>    -- A value of 5 indicates the last week of the month. Range: [1..5]\n")
    print ("Note : Either <dweek> and <wmonth> should to be set, or <dmonth> should be set")
    sys.exit (1)
    

def create(server):
    # creating the input for api execution
    # creating a dfm-schedule-create element and adding child elements
    schedule_input = NaElement("dfm-schedule-create")
    schedule = NaElement("schedule-content-info")
    schedule.child_add_string( "schedule-name", dfmname)
    schedule.child_add_string( "schedule-type", dfmtype )
    schedule.child_add_string( "schedule-category", "dfm_schedule" )

    # creating a daily-list element
    if(dfmtype == "daily" and ( start_hour or start_minute )):
        daily = NaElement("daily-list")
        daily_info = NaElement("daily-info")

        if(start_hour):
            daily_info.child_add_string( "start-hour", start_hour)

        if(start_minute):
            daily_info.child_add_string( "start-minute", start_minute )

        daily.child_add(daily_info)
        # appending daily list to schedule
        schedule.child_add(daily)

    # creating a weekly-list element
    if((dfmtype == "weekly")and (start_hour or start_minute or day_of_week)):
        weekly = NaElement("weekly-list")
        weekly_info = NaElement("weekly-info")

        if(start_hour):
            weekly_info.child_add_string( "start-hour", start_hour)

        if (start_minute):
            weekly_info.child_add_string( "start-minute", start_minute )

        if(day_of_week):
            weekly_info.child_add_string( "day-of-week", day_of_week )

        weekly.child_add(weekly_info)
        # appending weekly list to schedule
        schedule.child_add(weekly)

    if((dfmtype == "monthly")and(start_hour or start_minute or day_of_week or day_of_month or week_of_month )):
        monthly = NaElement("monthly-list")
        monthly_info = NaElement("monthly-info")

        if(start_hour):
            monthly_info.child_add_string( "start-hour", start_hour )

        if(start_minute):
            monthly_info.child_add_string( "start-minute", start_minute )

        if(day_of_month):
            monthly_info.child_add_string( "day-of-month", day_of_month )

        if(day_of_week):
            monthly_info.child_add_string( "day-of-week", day_of_week )

        if(week_of_month):
            monthly_info.child_add_string( "week-of-month", week_of_month )

        monthly.child_add(monthly_info)
        # appending monthly list to schedule
        schedule.child_add(monthly)

    # appending schedule to main input
    schedule_input.child_add(schedule)
    # invoking the api and printing the xml ouput
    output = server.invoke_elem(schedule_input)

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nSchedule creation Successful \n")


def dfm_list(server):
    #invoking the api and capturing the ouput
    if (dfmname):
        output = server.invoke( "dfm-schedule-list-info-iter-start","schedule-category", "dfm_schedule", "schedule-name-or-id",dfmname )

    else :
        output = server.invoke( "dfm-schedule-list-info-iter-start","schedule-category", "dfm_schedule" )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")

    if(not records):
        print("\nNo schedules to display\n")

    tag = output.child_get_string("tag")
    # Extracting records one at a time
    record = server.invoke( "dfm-schedule-list-info-iter-next",	"maximum", records, "tag", tag )

    if ( record.results_status() == "failed" ):
        print( "Error : " + record.results_reason() + "\n" )
        sys.exit(2)

    # Navigating to the schedule-content-list child element
    if(not record):
        sys.exit(0)
    else:
        stat = record.child_get("schedule-content-list")
    
    # Navigating to the schedule-info child element
    if(not stat):
        sys.exit (0)
    else:
        info = stat.children_get() 

    # Iterating through each record
    for info in info :
        # extracting the schedule details and printing it
        print ('-'*80 + "\n")
        print ("Schedule Name : " + info.child_get_string("schedule-name") + "\n")
        print ("Schedule Id : "  + info.child_get_string("schedule-id") + "\n")
        print ("Schedule Description : " + info.child_get_string("schedule-description") + "\n")
        print ('-'*80 + "\n")

        # printing detials if only one schedule is selected for listing
        if (dfmname):
            print ("\nSchedule Type        : " + info.child_get_string("schedule-type") + "\n")
            print ("Schedule Category    : " + info.child_get_string("schedule-category") + "\n")
            schedule_type = info.child_get_string("schedule-type")
            type_list = info.child_get("type-list")

            if (type_list):
                type_info = type_list.child_get("type-info")

                if(schedule_type == 'daily') :
                    print ("Item Id              : " + type_info.child_get_string("item-id") + "\n")
                    print ("Start Hour           : " + type_info.child_get_string("start-hour") + "\n")
                    print ("Start Minute         : " + type_info.child_get_string("start-minute") + "\n")

                elif(schedule_type == 'weekly' ):
                    print ("Item Id              : " + type_info.child_get_string("item-id") + "\n")
                    print ("Start Hour           : " + type_info.child_get_string("start-hour") + "\n")
                    print ("Start Minute         : " + type_info.child_get_string("start-minute") + "\n")
                    print ("Day Of Week          : " + type_info.child_get_string("day-of-week") + "\n")

                elif(schedule_type  == 'monthly' ):
                    print ("Item Id              : " + type_info.child_get_string("item-id") + "\n")
                    print ("Start Hour           : " + type_info.child_get_string("start-hour") + "\n")
                    print ("Start Minute         : " + type_info.child_get_string("start-minute") + "\n")
                    print ("Day Of Week          : " + type_info.child_get_string("day-of-week") + "\n")
                    print ("Week Of Month        : " + type_info.child_get_string("week-of-month") + "\n")
                    print ("Day Of Month         : " + type_info.child_get_string("day-of-month") + "\n")
    

    # invoking the iter-end zapi
    end = server.invoke( "dfm-schedule-list-info-iter-end", "tag", tag )

    if(end.results_status() == "failed"):
        print( "Error : " + end.results_reason() + "\n" )
        sys.exit(2)


def schedule_del(server):
    output = server.invoke( "dfm-schedule-destroy", "schedule-name-or-id", dfmname,"schedule-category", "dfm_schedule" )

    if(output.results_status() == "failed"):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nSchedule deletion Successful \n")
    

args = len(sys.argv) - 1

if(args < 4):
    usage()

dfmserver = sys.argv[1]
dfmuser = sys.argv[2]
dfmpw = sys.argv[3]
dfmop = sys.argv[4]
start_hour = None
start_minute  = None
day_of_week = None
day_of_month  = None
week_of_month = None

if(args > 4):
    dfmname = sys.argv[5]

else:
    dfmname = None

# checking for valid number of parameters for the respective operations  
if(dfmop == "delete" and args < 5) :
    print("usage....\n") 
    usage()

if(dfmop == "create" and args < 6):
    usage()

elif(dfmop == "create"):
    dfmname = sys.argv[5]
    dfmtype = sys.argv[6]

    if(args > 6):
        opt_param = sys.argv[7:]
    
# checking if the operation selected is valid
if((dfmop != "list") and (dfmop != "create") and (dfmop != "delete")):
    usage()
    
# Checking if the type selected is valid
if((dfmop == "create") and (dfmtype != "daily") and (dfmtype != "weekly") and (dfmtype != "monthly")):
    usage()

# parsing optional parameters
i = 0  
while (args > 6 and i < len(opt_param) ):

    if(opt_param[i]  == '-h'):
        i = i + 1 
        start_hour    = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-m'):
        i = i + 1 
        start_minute  = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-d' ):
        i = i + 1 
        day_of_week   = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-D'):
        i = i + 1     
        day_of_month  = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-w'):
        i = i + 1 
        week_of_month = opt_param[i]
        i = i + 1

    else :
        usage()

# Creating a server object and setting appropriate attributes
serv = NaServer(dfmserver, 1, 0 )
serv.set_style('LOGIN')
serv.set_transport_type('HTTP')
serv.set_server_type('DFM')
serv.set_port(8088)
serv.set_admin_user( dfmuser, dfmpw )

# Calling the subroutines based on the operation selected
if(dfmop == 'create'):
    create(serv)

elif(dfmop == 'list'):
    dfm_list(serv)

elif(dfmop == 'delete'):
    schedule_del(serv)

else:
    usage()

