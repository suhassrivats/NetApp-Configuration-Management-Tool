#===============================================================#
#                                                               #
# ID                                                            #
#                                                               #
# perf_aggr_latency.rb                                          #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# We do not have API to get read_latency, write_latency, and    #
# average_latency at aggregate level. This sample code          #
# demonstrates a method to get this data by reading the         #
# required latency of all volumes for the given aggregate.      #
# Use this information to generate latency at aggregate level.  #
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
	print ("perf_aggr_latency.rb <dfm> <user> <password> <aggr-name>\n")
	print ("<dfm>       -- DFM Server name\n")
	print ("<user>      -- User name\n")
	print ("<password>  -- Password\n")
	print ("<aggr-name> -- Name of the aggregate in format storage:aggrName\n")
	print ("-" * 80 + "\n")
	print ("This sample code provides information on read latency, write latency\n")
	print ("and average latency of an aggregate \n")
	print ("This data can be used to charts to represent data in graphical format.\n")
	print ("To generate the graph, redirect output of this sample code to\n")
	print ("an Excel sheet.\n")
	exit 
end
			

def print_output() 
	i = 0
	samples = $time1.length
	print ("Time\t\t\t\tRead Latency\tWrite Latency\tAverage Latency\n")	
	if (samples > 0) 	
		while(i < samples)
			print($time1[i])
			printf("\t%.4f\t\t%.4f\t\t%.4f\n",($read_latency[i].to_f/samples), ($write_latency[i].to_f/samples), ($avg_latency[i].to_f/samples))
			i = i + 1
		end
	end
end


def invoke_perf_zapi() 
	dfm = ARGV[0]
	user = ARGV[1]
	pw  = ARGV[2]
	aggr_name = ARGV[3]	
	# Initialize server context
	server_ctx = NaServer.new(dfm, 1, 0)
	server_ctx.set_admin_user(user, pw)
	server_ctx.set_server_type("DFM")
	# Create API request
	perf_in = NaElement.new("perf-get-counter-data")
	perf_in.child_add_string("duration", 6000)
	perf_in.child_add_string("number-samples", 50)
	perf_in.child_add_string("time-consolidation-method", "average")
	instance_info = NaElement.new("instance-counter-info")
	instance_info.child_add_string("object-name-or-id", aggr_name)
	counter_info = NaElement.new("counter-info")
	perf_obj_ctr1 = NaElement.new("perf-object-counter")
	perf_obj_ctr1.child_add_string("object-type", "volume")
	perf_obj_ctr1.child_add_string("counter-name", "read_latency")
	perf_obj_ctr2 = NaElement.new("perf-object-counter")
	perf_obj_ctr2.child_add_string("object-type", "volume")
	perf_obj_ctr2.child_add_string("counter-name", "write_latency")
	perf_obj_ctr3 = NaElement.new("perf-object-counter")
	perf_obj_ctr3.child_add_string("object-type", "volume")
	perf_obj_ctr3.child_add_string("counter-name", "avg_latency")
	counter_info.child_add(perf_obj_ctr1)
	counter_info.child_add(perf_obj_ctr2)
	counter_info.child_add(perf_obj_ctr3)
	instance_info.child_add(counter_info)
	perf_in.child_add(instance_info)
	perf_out = server_ctx.invoke_elem(perf_in)	
	if(perf_out.results_status() == "failed") 
		print(perf_out.results_reason() + "\n")
		exit
	end	
	return perf_out
end


def extract_perf_counter_data(perf_out) 
	gen_time_arr = 1
	time_i = 0
	read_i = 0
	write_i = 0
	avg_i = 0
	instance = perf_out.child_get("perf-instances")
	instances = instance.children_get()
	instances.each do |rec|
		vol_name = rec.child_get_string("instance-name")
		counters = rec.child_get("counters")
		perf_cnt_data = counters.children_get()		
		perf_cnt_data.each do |rec1|
			read_i = 0
			write_i = 0
			avg_i = 0
			counter_name = rec1.child_get_string("counter-name")
			counter_str = rec1.child_get_string("counter-data")
			counter_arr = counter_str.split(',')
			if(counter_name == "read_latency") 				
				counter_arr.each do |time_val|
					time_val_arr = time_val.split(':')					
					if(gen_time_arr) 
						$time1[time_i] = Time.at(time_val_arr[0].to_i)
						time_i = time_i + 1
					end
					if($read_latency[read_i]) 
						$read_latency[read_i] = $read_latency[read_i] + time_val_arr[1].to_f
					else 
						$read_latency[read_i] = time_val_arr[1].to_f
					end					
					read_i = read_i + 1
				end				
				gen_time_arr = nil	
				
			elsif(counter_name == "write_latency") 				
				counter_arr.each do |time_val|
					time_val_arr = time_val.split(':')					
					if(gen_time_arr) 
						$time1[time_i] = Time.at(time_val_arr[0].to_i)
						time_i = time_i + 1
					end					
					if($write_latency[write_i]) 
						$write_latency[write_i] = $write_latency[write_i] + time_val_arr[1].to_f					
					else 
						$write_latency[write_i] = time_val_arr[1].to_f
					end					
					write_i = write_i + 1
				end				
				gen_time_arr = nil
			
			elsif(counter_name == "avg_latency") 				
				counter_arr.each do |time_val|
					time_val_arr = time_val.split(':')					
					if(gen_time_arr) 
						$time1[time_i] = Time.at(time_val_arr[0].to_f)
						time_i = time_i + 1
					end					
					if ($avg_latency[avg_i]) 
						$avg_latency[avg_i] = $avg_latency[avg_i] + time_val_arr[1].to_f			
					else 
						$avg_latency[avg_i] = time_val_arr[1].to_f
					end					
					avg_i = avg_i + 1
				end				
				gen_time_arr = nil
			end
		end
	end
end


def main() 
	# check for valid number of parameters
	if ($args != 4)	
		print_help()
	end	
	perf_out = invoke_perf_zapi()
	extract_perf_counter_data(perf_out)
	print_output()
	exit 
end

	
# Command line arguments
$args = ARGV.length
$time1 = []
$read_latency = []
$write_latency = []
$avg_latency = []
#Invoke routine
main()

#=========================== POD ============================#

'=head1 NAME

  perf_aggr_latency.rb - This sample code provides information on read latency,
  write latency and average latency of an aggregate.

=head1 SYNOPSIS

  perf_aggr_latency.rb <dfm> <user> <password> <aggr-name>

=head1 ARGUMENTS

  <dfm>
  DFM Server name.

  <user>
  User name.

  <password>
  Password.

  <aggr-name>
  Name of the aggregate in format storage:aggrName.

=head1 SEE ALSO

  NaElement.rb, NaServer.rb

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut
'
