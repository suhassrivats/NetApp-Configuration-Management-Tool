#===============================================================#
#                                                               #
# ID                                                            #
#                                                               #
# perf_disk_iops_latency.rb                                     #
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
	print ("perf_disk_iops_latency.rb <dfm> <user> <password> <aggr-name>\n")
	print ("<dfm>        -- DFM Server name\n")
	print ("<user>       -- User name\n")
	print ("<password>   -- Password\n")
	print ("<aggr-name>	-- Name of the aggregate in format storage:aggrName\n")
	print ("-" * 80 + "\n")
	print ("This sample code prints disk IOPs for the disks on which the\n")
	print ("given aggregate is present. This sample code also does prints \n")
	print ("minimum disk IOPs value and maximum disk IOPs value for the \n")
	print ("specific time stamp. \n")
	print ("Output data of this sample code can be used to generate chart.\n")
	print ("To generate the graph, redirect output of this sample code to\n")
	print ("an Excel sheet.\n")
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
$disk_arr = []
$disk_i = 0
$nsamples = 0
$i = 0


def invoke_perf_zapi() 
	dfm = ARGV[0]
	user = ARGV[1]
	pw  = ARGV[2]	
	# Initialize server context
	server_ctx = NaServer.new(dfm, 1, 0)
	server_ctx.set_transport_type("HTTP")
	server_ctx.set_style("LOGIN")
	server_ctx.set_admin_user(user, pw)
	server_ctx.set_server_type("DFM")
	server_ctx.set_port(8088)
	# Create API request
	perf_in = NaElement.new("perf-get-counter-data")
	perf_in.child_add_string("duration", 6000)
	perf_in.child_add_string("number-samples", 50)
	perf_in.child_add_string("time-consolidation-method", "average")
	instance_info = NaElement.new("instance-counter-info")
	instance_info.child_add_string("object-name-or-id", ARGV[3])
	counter_info = NaElement.new("counter-info")
	perf_obj_ctr = NaElement.new("perf-object-counter")
	perf_obj_ctr.child_add_string("object-type", "disk")
	perf_obj_ctr.child_add_string("counter-name", "total_transfers")
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


def extract_perf_counter_data(perf_out) 
	gen_time_arr = 1
	instance = perf_out.child_get("perf-instances")
	instances = instance.children_get()	
	instances.each do |rec|
		disk_name = rec.child_get_string("object-id")		
		if (disk_name) 
			$disk_arr[$disk_i] = disk_name
			$disk_i = $disk_i + 1
		end		
		counters = rec.child_get("counters")
		perf_cnt_data = counters.children_get()
		perf_cnt_data.each do |rec1|
			counter_str = rec1.child_get_string("counter-data")
			counter_arr = counter_str.split(',')			
			counter_arr.each do |time_val|
				time_val_arr = time_val.split(':')				
				if(gen_time_arr) 
					$time_arr[$i] = Time.at(time_val_arr[0].to_f)
					$nsamples = $i + 1
				end				
				$data_arr[$i] = time_val_arr[1].to_f
				$i = $i + 1
			end			
			gen_time_arr = nil
		end
	end
end

	
# Print output.
def print_output() 
	print ("Time\t\t\t\t ")
	# Print disk ID.
	$nsamples = $time_arr.length 
	l = 0	
	while(l < $disk_i)
		print ($disk_arr[l] + "\t")
		l = l + 1
	end	
	print ("Min Val\tMax Val\n")
	j = 0
	k = 0
	iter = 0
	
	while(iter < $nsamples)
		m = 0
		min_util = 9999999999999	#dum value
		max_util = 0
		min_index = 0
		max_index = 0
		print ($time_arr[iter].to_s + "\t")
		k = iter	
		while(k < $i)
			print ($data_arr[k].to_s + "\t")
			if (min_util > $data_arr[k]) 
				min_util = $data_arr[k]
				min_index = m
			end			
			if (max_util < $data_arr[k]) 
				max_util = $data_arr[k]
				max_index = m
			end			
			m = m + 1
			k = k + $nsamples
		end		
		print (min_util.to_s + "\t" + max_util.to_s + "\n")
		iter = iter + 1
	end	
	exit
end


def main() 	
	perf_out = invoke_perf_zapi()
	extract_perf_counter_data(perf_out)
	print_output()
	exit 
end

#Invoke routine
main()

'''#=========================== POD ============================#

=head1 NAME

  perf_disk_iops_latency.rb - This sample code prints disk IOPs for the disks
  on which the given aggregate is present. This sample code also does prints
  minimum disk IOPs value and maximum disk IOPs value for the specific
  time stamp.

=head1 SYNOPSIS

  perf_disk_iops_latency.rb <dfm> <user> <password> <aggr-name>

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

 Copyright (c) 2011 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut'''

