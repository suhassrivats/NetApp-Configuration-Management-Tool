#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# perf_operation.rb                                             #
#                                                               #
# Sample code for the usage of following APIs:                  #
#                       perf-object-list-info                   #
#                       perf-object-counter-list-info           #
#                       perf-object-instance-list-info          #
#                       perf-object-get-instances-iter-*        #
#                                                               #
# Copyright 2011 Network Appliance, Inc. All rights             #
# reserved. Specifications subject to change without notice.    #
#                                                               #
# This SDK sample code is provided AS IS, with no support or    #
# warranties of any kind, including but not limited to          #
# warranties of merchantability or fitness of any kind,         #
# expressed or implied.  This code is subject to the license    #
# agreement that accompanies the SDK.                           #
#                                                               #
#===============================================================#

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage()
    print("perf_operation.rb <storage> <user> <password> <operation> <value1>")
    print("[<value2>]\n")
    print("<storage>   -- Storage system name\n")
    print("<user>      -- User name\n")
    print("<password>  -- Password\n")
    print("<operation> -- Operation to be performed: \n")
    print("\tobject-list   - Get the list of perforance objects in the system\n")
    print("\tinstance-list - Get the list of instances for a given performance object\n")
    print("\tcounter-list  - Get the list of counters available for a given performance object\n")
    print("\tget-counter-values - Get the values of the counters for all the instances of a performance object\n")
    print("[<value1>]  -- Depends on the operation \n")
    print("[<value2>]  -- Depends on the operation \n")
    exit 
end

    
# perf-object-list-info operation
# Usage: perf_operation.rb <storage> <user> <password> object-list
def get_object_list()
    list_in = NaElement.new("perf-object-list-info")
    # Invoke API
    out = $s.invoke_elem(list_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    obj_info = out.child_get("objects")
    result = obj_info.children_get()
    result.each do |obj|
        obj_name = obj.child_get_string("name")
        priv = obj.child_get_string("privilege-level")
        print("Object Name = " + obj_name + "\t\t\t\tPrivilege Level = " + priv + "\n")
    end	
    print("\n")
end


# perf-object-instance-list-info operation
# Usage: perf_operation.rb <storage> <user> <password> instance-list <objectname>
def get_instance_list()
    if ($args < 5)
        print ("Usage: perf_operation.rb <storage> <user> <password> instance-list <objectname> \n")
        exit 
    end
    list_in = NaElement.new("perf-object-instance-list-info")
    obj_name = ARGV[4]
    list_in.child_add_string("objectname", obj_name)    
    # Invoke API
    out = $s.invoke_elem(list_in)	
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    inst_info = out.child_get("instances")
    result = inst_info.children_get()	
    result.each do |inst|
        inst_name = inst.child_get_string("name")
        print("Instance Name = " + inst_name + " \n")
    end	
    print("\n")
end


# perf-object-counter-list-info operation
# Usage: perf_operation.rb <storage> <user> <password> counter-list <objectname>
def get_counter_list()
    if ($args < 5) 
        print ("Usage: perf_operation.rb <storage> <user> <password> counter-list <objectname>")
        exit 
    end
    list_in = NaElement.new("perf-object-counter-list-info")
    obj_name =ARGV[4]
    list_in.child_add_string("objectname", obj_name)
    # Invoke API
    out = $s.invoke_elem(list_in)	
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end    		
    counter_info = out.child_get("counters")
    result = counter_info.children_get()	
    result.each do |counter|
        counter_name = counter.child_get_string("name")
        print("Counter Name = " + counter_name + "\t")		
        if (counter.child_get_string("base-counter"))
            base_counter = counter.child_get_string("base-counter")
            print("Base Counter = " + base_counter + "\t")			
        else 
            print("Base Counter = none\t\t")
	end		
        privilege_level = counter.child_get_string("privilege-level")
        print("Privilege_level = " + privilege_level + "\t")
        if (counter.child_get_string("unit")) 
            unit = counter.child_get_string("unit")
            print("Unit = " + unit + "\t\t")
        else 
            print("Unit = None\t\t")
	end		
	print("\n")
    end
end


# perf-object-get-instances-iter-* operation
# Usage: perf_operation.rb <storage> <user> <password> get-counter-values <objectname> [ <counter1> <counter2>...]
 
def get_counter_values()
    max_records = 10
    if ($args < 5) 
        print ("Usage: perf_operation.rb <storage> <user> <password> get-counter-values <objectname> [ <counter1> <counter2> ...]")
        exit 
    end
    perf_in = NaElement.new("perf-object-get-instances-iter-start")
    obj_name = ARGV[4]
    perf_in.child_add_string("objectname",obj_name)
    if ( $args > 5 ) 
        i = 5
        counters = NaElement.new("counters")
        while(i < ARGV.length)
            counters.child_add_string("counter", ARGV[i])
            i = i + 1
	end
        perf_in.child_add(counters)
    end	

    # Invoke API
    out = $s.invoke_elem(perf_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end    
    iter_tag = out.child_get_string("tag")
    begin
	perf_in = NaElement.new("perf-object-get-instances-iter-next")
        perf_in.child_add_string("tag", iter_tag)
        perf_in.child_add_string("maximum", max_records)
        out = $s.invoke_elem(perf_in)
        if(out.results_status() == "failed")
            print(out.results_reason() + "\n")
            exit
	end		
	num_records = out.child_get_int("records")	
        if(Integer(num_records) > 0) 
            instances_list = out.child_get("instances")            
            instances = instances_list.children_get()
	    instances.each do |inst|
                inst_name = inst.child_get_string("name")
                print ("Instance = " + inst_name + "\n")
                counters_list = inst.child_get("counters")
                counters = counters_list.children_get()
		counters.each do |counter|
                    counter_name = counter.child_get_string("name")
                    counter_value = counter.child_get_string("value")
                    print("Counter Name = " + counter_name + "  Counter Value = " + counter_value + "\n")
		end
	    end
    	    print("\n")		
	end
    end while(Integer(num_records) != 0)
		
    perf_in = NaElement.new("perf-object-get-instances-iter-end")
    perf_in.child_add_string("tag", iter_tag)
    out = $s.invoke_elem(perf_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
end

    
def main() 		
    if($args < 4)
	print_usage() 
    end
    storage = ARGV[0]
    user = ARGV[1]
    pw  = ARGV[2]
    command = ARGV[3]
    $s = NaServer.new(storage, 1, 3)
    $s.set_admin_user(user, pw)
    if(command == "object-list")
        get_object_list()
    elsif(command == "instance-list")
        get_instance_list()
    elsif(command == "counter-list")
        get_counter_list()
    elsif(command == "get-counter-values")
        get_counter_values()
    else
        print("Invalid operation\n")
        print_usage()
    end
end

$args = ARGV.length
main()


