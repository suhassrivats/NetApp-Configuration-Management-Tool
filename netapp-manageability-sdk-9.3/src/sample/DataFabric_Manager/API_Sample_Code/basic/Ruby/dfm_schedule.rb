#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dfm_schedule.rb                                               #
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

$:.unshift '../../../../../../lib/ruby/NetApp'
require 'NaServer'

def usage
    print ("\nUsage:\ndfm_schedule.rb <dfmserver> <user> <password> list [ <schedule type> ]\n")
    print ("dfm_schedule.rb <dfmserver> <user> <password> delete <schedule type>\n")
    print ("dfm_schedule.rb <dfmserver> <user> <password> create  schedule_name daily [ -h <shour> -m <sminute> ]\n")
    print ("dfm_schedule.rb <dfmserver> <user> <password> create schedule_name weekly [ -d <dweek>] [ -h <shour> -m <sminute> ]\n")
    print ("dfm_schedule.rb <dfmserver> <user> <password> create schedule_name monthly { [ -D <dmonth> ] | [ -d <dweek> -w <wmonth> ] } [ -h <shour> -m <sminute>]\n")
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
    print ("Note : Either <dweek> and <wmonth> should to be set, or <dmonth> should be set\n\n")
    exit 
end


def create()
    # creating the input for api execution
    # creating a dfm-schedule-create element and adding child elements
    schedule_input = NaElement.new("dfm-schedule-create")
    schedule = NaElement.new("schedule-content-info")
    schedule.child_add_string( "schedule-name", $dfmname)
    schedule.child_add_string( "schedule-type", $dfmtype )
    schedule.child_add_string( "schedule-category", "dfm_schedule" )
    # creating a daily-list element
    if($dfmtype == "daily" and ( $start_hour or $start_minute ))
        daily = NaElement.new("daily-list")
        daily_info = NaElement.new("daily-info")
        if($start_hour)
            print("\nadding start_hour")
	    daily_info.child_add_string( "start-hour", $start_hour) 
	end
        if($start_minute)
	    daily_info.child_add_string( "start-minute", $start_minute ) 
	end
    	daily.child_add(daily_info)
    	# appending daily list to schedule
	schedule.child_add(daily)
    end
	
    # creating a weekly-list element
    if(($dfmtype == "weekly")and ($start_hour or $start_minute or $day_of_week))
        weekly = NaElement.new("weekly-list")
        weekly_info = NaElement.new("weekly-info")
        weekly_info.child_add_string( "start-hour", $start_hour) if($start_hour)          
	weekly_info.child_add_string( "start-minute", $start_minute ) if ($start_minute)
	weekly_info.child_add_string( "day-of-week", $day_of_week ) if($day_of_week)
	weekly.child_add(weekly_info)
	# appending weekly list to schedule
	schedule.child_add(weekly)
    end
	
    if(($dfmtype == "monthly")and($start_hour or $start_minute or $day_of_week or $day_of_month or $week_of_month ))
        monthly = NaElement.new("monthly-list")
        monthly_info = NaElement.new("monthly-info")
        if($start_hour)
	    monthly_info.child_add_string( "start-hour", $start_hour )
	end
	if($start_minute)
	    monthly_info.child_add_string( "start-minute", $start_minute ) 
	end
	if($day_of_month)
	    monthly_info.child_add_string( "day-of-month", $day_of_month ) 
	end
	if($day_of_week)
	    monthly_info.child_add_string( "day-of-week", $day_of_week ) 
	end
        if($week_of_month)
	    monthly_info.child_add_string( "week-of-month", $week_of_month )
	end
        monthly.child_add(monthly_info)
        # appending monthly list to schedule
	schedule.child_add(monthly)
    end
    # appending schedule to main input
    schedule_input.child_add(schedule)
    print("\nappending\n")
    # invoking the api and printing the xml ouput
    output = $serv.invoke_elem(schedule_input)
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end
    print ("\nSchedule creation Successful \n")
end


def dfm_list()
    #invoking the api and capturing the ouput
    if ($dfmname)
        output = $serv.invoke( "dfm-schedule-list-info-iter-start", "schedule-category", "dfm_schedule", "schedule-name-or-id", $dfmname )
    else 
        output = $serv.invoke( "dfm-schedule-list-info-iter-start","schedule-category", "dfm_schedule" )
    end
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end
    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")
    tag = output.child_get_string("tag")
    if(records.to_i == 0)
        print("\nNo schedules to display\n")
        record = $serv.invoke("dfm-schedule-list-info-iter-end", "tag", tag)
        exit
    end
    # Extracting records one at a time
    record = $serv.invoke( "dfm-schedule-list-info-iter-next",	"maximum", records, "tag", tag )
    if ( record.results_status() == "failed" )
        print( "Error : " +record.results_reason() + "\n" )
        exit
    end	
    # Navigating to the schedule-content-list child element
    if(not record)
        exit    
    else
        stat = record.child_get("schedule-content-list")
    end	
    # Navigating to the schedule-info child element
    if(not stat)
        exit
    else
        info = stat.children_get() 
    end
    # Iterating through each record
    info.each do |element|
        # extracting the schedule details and printing it
        print('-'*80 + "\n")
        print ("Schedule Name : " + element.child_get_string("schedule-name") + "\n")
        print ("Schedule Id : "  + element.child_get_string("schedule-id") + "\n")
        print ("Schedule Description : " + element.child_get_string("schedule-description") + "\n")
        # printing detials if only one schedule is selected for listing
        if ($dfmname)
            schedule_type = element.child_get_string("schedule-type")
            print ("\nSchedule Type        : " + schedule_type + "\n")
            print ("Schedule Category    : " + element.child_get_string("schedule-category") + "\n")
            type_list = element.child_get(schedule_type + "-list")
            if (type_list)
                type_info = type_list.child_get(schedule_type + "-info")
                if(schedule_type == 'daily') 
                    print ("Item Id              : " + type_info.child_get_string("item-id") + "\n")
                    print ("Start Hour           : " + type_info.child_get_string("start-hour") + "\n")
                    print ("Start Minute         : " + type_info.child_get_string("start-minute") + "\n")

                elsif(schedule_type == 'weekly' )
                    print ("Item Id              : " + type_info.child_get_string("item-id") + "\n")
                    print ("Start Hour           : " + type_info.child_get_string("start-hour") + "\n")
                    print ("Start Minute         : " + type_info.child_get_string("start-minute") + "\n")
                    print ("Day Of Week          : " + type_info.child_get_string("day-of-week") + "\n")

                elsif(schedule_type  == 'monthly' )
                    print ("Item Id              : " + type_info.child_get_string("item-id") + "\n")
                    print ("Start Hour           : " + type_info.child_get_string("start-hour") + "\n")
                    print ("Start Minute         : " + type_info.child_get_string("start-minute") + "\n")
                    day_of_week = type_info.child_get_string("day-of-week")
                    if(day_of_week)
                        print ("Day Of Week          : " + type_info.child_get_string("day-of-week") + "\n")
                    end
                    week_of_month = type_info.child_get_string("week-of-month")
                    if(week_of_month)
                        print ("Week Of Month        : " + type_info.child_get_string("week-of-month") +"\n")
                    end
                    day_of_month = type_info.child_get_string("day-of-month")
                    if(day_of_month)
                        print ("Day Of Month         : " + type_info.child_get_string("day-of-month") +"\n")
                    end
	        end
	    end
        end				
        print ('-'*80 + "\n")
    end	
    # invoking the iter-end zapi
    output = $serv.invoke( "dfm-schedule-list-info-iter-end", "tag", tag )
    if(output.results_status() == "failed")
        print( "Error : " +output.results_reason() +"\n" )
        exit
    end
end


def schedule_del()
    output = $serv.invoke( "dfm-schedule-destroy", "schedule-name-or-id", $dfmname, "schedule-category", "dfm_schedule" )
    if(output.results_status() == "failed")
        print( "Error : " +output.results_reason() + "\n" )
        exit
    end
    print ("\nSchedule deletion Successful \n")
end


args = ARGV.length
if(args < 4)
    usage()
end
dfmserver =  ARGV[0]
dfmuser =  ARGV[1]
dfmpw =  ARGV[2]
dfmop =  ARGV[3]
$start_hour = nil
$start_minute  = nil
$day_of_week = nil
$day_of_month  = nil
$week_of_month = nil
if(args > 3)
    $dfmname = ARGV[4]
else
    $dfmname = nil
end

# checking for valid number of parameters for the respective operations
if(dfmop == "delete" and args < 5) 
    print("usage....\n")
    usage()
end
if(dfmop == "create" and args < 6)
    usage()
elsif(dfmop == "create")
    $dfmname =  ARGV[4]
    $dfmtype =  ARGV[5]	
    if(args > 6)
	opt_param =  ARGV[6, ARGV.length-1] 
    end
end

# checking if the operation selected is valid
if((dfmop != "list") and (dfmop != "create") and (dfmop != "delete"))
    usage() 
end
# Checking if the type selected is valid
if((dfmop == "create") and ($dfmtype != "daily") and ($dfmtype != "weekly") and ($dfmtype != "monthly"))
    usage()
end

# parsing optional parameters
i = 0  
while (args > 6 and i < opt_param.length)
    if(opt_param[i]  == '-h')
        i = i + 1 
        $start_hour    = opt_param[i]
        i = i + 1
    elsif(opt_param[i]  == '-m')
        i = i + 1 
        $start_minute  = opt_param[i]
        i = i + 1		
    elsif(opt_param[i]  == '-d' )
        i = i + 1 
        $day_of_week   = opt_param[i]
        i = i + 1		
    elsif(opt_param[i]  == '-D')
        i = i + 1     
        $day_of_month  = opt_param[i]
        i = i + 1	
	elsif(opt_param[i]  == '-w')
        i = i + 1 
        $week_of_month = opt_param[i]
        i = i + 1		
    else 
        usage()
    end
end
	
# Creating a server object and setting appropriate attributes
$serv = NaServer.new(dfmserver, 1, 0 )
$serv.set_style('LOGIN')
$serv.set_server_type('DFM')
$serv.set_admin_user( dfmuser, dfmpw )

# Calling the subroutines based on the operation selected
if(dfmop == 'create')
    create()
elsif(dfmop == 'list')
    dfm_list()
elsif(dfmop == 'delete')
    schedule_del()
else
    usage()
end

