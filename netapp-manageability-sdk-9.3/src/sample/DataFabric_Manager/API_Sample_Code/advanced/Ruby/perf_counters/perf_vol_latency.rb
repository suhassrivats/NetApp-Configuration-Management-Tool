#===============================================================#
#                                                               #
# ID                                                            #
#                                                               #
# perf_vol_latency.rb                                           #
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
	print ("perf_vol_latency.rb <dfm> <user> <password> <aggr-name>\n")
	print ("<dfm>       -- DFM Server name\n")
	print ("<user>      -- User name\n")
	print ("<password>  -- Password\n")
	print ("<aggr-name> -- Name of the aggregate in format storage:aggrName\n")
	print ("-" * 80 + "\n")
	print ("This sample code prints average latency of all the volumes \n")
	print ("present in the given aggregate. This data can be used to \n")
	print ("generate distribution chart for volume average latency. \n")
	print ("To generate the graph, redirect output of this sample code to\n")
	print ("an Excel sheet.\n")
	exit 
end


def invoke_perf_zapi() 
	dfm = ARGV[0]
	user = ARGV[1]
	pw  = ARGV[2]
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
	instance_info.child_add_string("object-name-or-id", ARGV[3])
	counter_info = NaElement.new("counter-info")
	perf_obj_ctr = NaElement.new("perf-object-counter")
	perf_obj_ctr.child_add_string("object-type", "volume")
	perf_obj_ctr.child_add_string("counter-name", "avg_latency")
	counter_info.child_add(perf_obj_ctr)
	instance_info.child_add(counter_info)
	perf_in.child_add(instance_info)
	# Invoke API
	perf_out = server_ctx.invoke_elem(perf_in)	
	if(perf_out.results_status() == "failed") 
		print(perf_out.results_reason() +"\n")
		exit
	end	
	return perf_out
end


def extract_perf_counter_data(perf_out)
	gen_time_arr = 1
	i = 0
	instance = perf_out.child_get("perf-instances")
	instances = instance.children_get()
	instances.each do |rec|
		vol_name = rec.child_get_string("instance-name")		
		if (vol_name) 
			$vol_arr.push(vol_name)
		end		
		counters = rec.child_get("counters")
		perf_cnt_data = counters.children_get()		
		perf_cnt_data.each do |rec1|
			counter_str = rec1.child_get_string("counter-data")
			# counter-data is in time1:val1,time2:val2,..,timen:valn format.
			# Extract data from this format.
			counter_arr = counter_str.split(',')			
			counter_arr.each do |time_val|
				time_val_arr = time_val.split(':')
				if(gen_time_arr) 
					$time_arr[i] = Time.at(time_val_arr[0].to_f)
				end		
				$data_arr[i] = time_val_arr[1]
				i = i + 1
			end			
			gen_time_arr = nil
		end
	end
end


def print_output() 
	j = 0
	k = 0
	iter = 0
	nsamples = $time_arr.length 
	data_arr_len = $data_arr.length
	print ("Time\t\t\t\t")
	$vol_arr.each do |vol_name|
		print(vol_name + "\t")
	end	
	print ("\n")
	while(iter < nsamples)
		print($time_arr[iter].asctime + "\t")			
		k = iter
		while(k < data_arr_len)
			print ($data_arr[k].to_s + "\t\t")
			k = k + nsamples
		end		
		print "\n"
		iter = iter + 1
	end
end


def main() 		
	perf_out = invoke_perf_zapi()
	extract_perf_counter_data(perf_out)
	print_output()
	exit 
end


# Command line arguments
args = ARGV.length
# check for valid number of parameters
if (args != 4)	
	print_help() 
end
$time_arr = []
$data_arr = []
$vol_arr = []
#Invoke routine
main()

'''#=========================== POD ============================#

=head1 NAME

  perf_vol_latency.rb - Get average latency of all volumes present in an
	aggregate.


=head1 SYNOPSIS

  perf_vol_latency.rb <dfm> <user> <password> <aggr-name>

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

=cut'''

