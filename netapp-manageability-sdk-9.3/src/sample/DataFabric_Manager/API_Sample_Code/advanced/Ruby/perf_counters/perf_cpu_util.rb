#===============================================================#
#                                                               #
# ID                                                            #
#                                                               #
# perf_cpu_util.rb                                              #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.7.1   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../../lib/ruby/NetApp'
require 'NaServer'


def print_help() 
	print ("\nCommand:\n")
	print ("perf_cpu_util.rb <dfm> <user> <password> <storage-system>\n")
	print ("<dfm>            -- DFM Server name\n")
	print ("<user>           -- User name\n")
	print ("<password>       -- Password\n")
	print ("<storage-system> -- Storage system\n")
	print ("-" * 80 + "\n")
	print ("This sample code prints CPU utilization statistics of a storage \n")
	print ("system. The sample code collects CPU utilization data for 2 weeks\n")
	print ("and prints the data in a format, which enables comparision of CPU\n")
	print ("utilization in day, hour format for both the weeks\n")
	print ("Output data of this sample code can be used to generate chart.\n")
	print ("To generate the graph, redirect output of this sample code to\n")
	print ("an Excel sheet.\n")
	exit 
end


def per_week_data(server_ctx, start_time, end_time)
	perf_in = NaElement.new("perf-get-counter-data")
	perf_in.child_add_string("start-time", start_time.asctime)
	perf_in.child_add_string("end-time", end_time.asctime)
	perf_in.child_add_string("sample-rate", 3600)
	perf_in.child_add_string("time-consolidation-method", "average")
	instance_info = NaElement.new("instance-counter-info")
	instance_info.child_add_string("object-name-or-id", ARGV[3])
	counter_info = NaElement.new("counter-info")
	perf_obj_ctr = NaElement.new("perf-object-counter")
	perf_obj_ctr.child_add_string("object-type", "system")
	perf_obj_ctr.child_add_string("counter-name", "avg_processor_busy")
	counter_info.child_add(perf_obj_ctr)
	instance_info.child_add(counter_info)
	perf_in.child_add(instance_info)
	perf_out = server_ctx.invoke_elem(perf_in)	
	if(perf_out.results_status() == "failed") 
		print(perf_out.results_reason() +"\n")
		exit
	end	
	return perf_out
end


def get_time_arr(perf_out) 
	i = 0
	time_arr = []
	instance = perf_out.child_get("perf-instances")
	instances = instance.children_get()
	instances.each do |rec|
		counters = rec.child_get("counters")
		perf_cnt_data = counters.children_get()		
		perf_cnt_data.each do |rec1|
			counter_str = rec1.child_get_string("counter-data")
			counter_arr = counter_str.split(',')			
			counter_arr.each do |time_val|
				time_val_arr = time_val.split(':')
				time_arr[i] = time_val_arr[0].to_f
				i = i + 1
			end
		end
	end	
	return time_arr
end


def get_data_arr(perf_out)
	i = 0
	data_arr = []
	instance = perf_out.child_get("perf-instances")
	instances = instance.children_get()
	instances.each do |rec|
		counters = rec.child_get("counters")
		perf_cnt_data = counters.children_get()		
		perf_cnt_data.each do |rec1|
			counter_str = rec1.child_get_string("counter-data")
			counter_arr = counter_str.split(',')			 
			counter_arr.each do |time_val|
				time_val_arr = time_val.split(':')
				data_arr[i] = time_val_arr[1].to_f
				i = i + 1
			end
		end
	end	
	return data_arr
end


def print_output() 
	print ("Week1\t\t\t\t\t\t\t\t\t\tWeek2\t\n")
	print ("Time\t\t\t\tCPU Busy\t\t\t\t\tTime\t\t\t\tCPU Busy\n")
	i = 0
	j = 0	
	while(i < $time_arr1.length and j < $time_arr2.length)		
		if (($time_arr2[j] - $time_arr1[i]) > 608400) 
			print (Time.at($time_arr1[i]).to_s + "\t" + $data_arr1[i].to_s + "\t\t")
			i = i + 1
			print ("\t\t\t")		
		elsif (($time_arr2[j] - $time_arr1[i]) < 601200)
			print (Time.at($time_arr2[j]))
			print ("\t" + $data_arr2[j].to_s + "\t\t\t")
			j = j + 1			
		else 
			print(Time.at($time_arr1[i]).to_s + "\t" + $data_arr1[i].to_s + "\t\t")
			i = i + 1
			print (Time.at($time_arr2[j]).to_s + "\t" + $data_arr2[j].to_s + "\t\t\t")
			j = j + 1
		end
		print("\t\t\t ")
	end	
	print("")	
	while(i < $time_arr1.length) 
        print( Time.at($time_arr1[i]).to_s + "\t" + $data_arr1[i].to_s + " \t\t\t\t\t\t")
		i = i + 1
		print(" ")
	end    
    while(j < $time_arr2.length)
        print (Time.at($time_arr2[j]).to_s + "\t" + $data_arr2[j].to_s + "\t\t\t\t\t\t ")
		j = j + 1
		print(" ")
	end
end

    
def main() 	
	dfm = ARGV[0]
	user = ARGV[1]
	pw  = ARGV[2]
	
	# Initialize server context
	server_ctx = NaServer.new(dfm, 1, 0)
	server_ctx.set_admin_user(user, pw)
	server_ctx.set_server_type("DFM")

	# Start time and end time for week1 data collection
	#Start time = current time - (60sec * 60min * 24hrs * 14days)
	starttime1 = Time.now - 1209600
	#end time = current time - (60sec * 60min * 24hrs * 7days)
	endtime1 = Time.now - 604800

	# Start time and end time for week2 data collection
	#Start time = current time - (60sec * 60min * 24hrs * 7days)
	starttime2 = Time.now - 604800
	# end time = current time
	endtime2 = Time.now

	# Collect data for Week1
	perf_out1 = per_week_data(server_ctx, starttime1, endtime1)

	# Collect data for Week2
	perf_out2 = per_week_data(server_ctx, starttime2, endtime2)
	$time_arr1 = get_time_arr(perf_out1)
	$time_arr2 = get_time_arr(perf_out2)
	$data_arr1 = get_data_arr(perf_out1)
	$data_arr2 = get_data_arr(perf_out2)
	print_output()
	exit
end

	
# Command line arguments
args = ARGV.length
# check for valid number of parameters
if (args != 4)
	print_help()
end
$time_arr1 = []
$time_arr2 = []
$data_arr1 = []
$data_arr2 = []
#Invoke routine
main()

#=========================== POD ============================#

'=head1 NAME

  perf_cpu_util.rb - Prints CPU utilization statistics. This sample code
  compares CPU utilization statistics of 2 weeks.


=head1 SYNOPSIS

  perf_cpu_util.rb <dfm> <user> <password> <storage-system>

=head1 ARGUMENTS

  <dfm>
  DFM Server name.

  <user>
  User name.

  <password>
  Password.

  <storage-system>
  Storage system.

=head1 SEE ALSO

  NaElement.rb, NaServer.rb

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut'

