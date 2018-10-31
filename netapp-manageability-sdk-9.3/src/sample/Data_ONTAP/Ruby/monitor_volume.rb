#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# monitor_volume.py                                          #
#                                                            #
# Monitors volume on a storage system and sends e-mail on    #
# space usage crossing threshold.                            #
#                                                            #
# Copyright 2011 Network Appliance, Inc. All rights          #
# reserved. Specifications subject to change without notice. #
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
#============================================================#

require 'net/smtp'
$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage()
    print ("monitor_volume.rb  <user> <password> \n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    exit 
end
   
   
# Get volume information
# Math/Round.rb needs to be present in the perl library for this to work.
def get_volume_info()
    s = NaServer.new($storage, 1, 3)
    s.set_admin_user($user, $pw)
    $volumes.each do |volume|
        out = s.invoke( "volume-list-info","volume", volume )
    	if (out.results_status() == "failed")
            print(out.results_reason() +"\n")
            exit
    	end
    	volume_info = out.child_get("volumes")
    	result = volume_info.children_get()
    	result.each do |vol|
	    $total_volume_size = vol.child_get_int("size-total")
	    $used_volume_size = vol.child_get_int("size-used")
	    $percent_space_avail = 100 - vol.child_get_int("percentage-used")
	    if ($percent_space_avail < $threshold.to_i)
	        send_mail(volume)
	    end
        end
    end
end


#Read configuration details from volume_config
def read_config_file()
    File.open("volume_config","r") do |file|
        while content = file.gets
            if(not((content =~ /#/) and (content != "")))
	        if(content =~ /filers/i)
		    tmp = content.split('=')
		    $storage = tmp[1].chomp
                elsif(content =~ /frequency/i)
                    tmp = content.split('=')
                    $poll_frequency = tmp[1].chomp
                elsif(content =~ /total_poll_count/i)
                    tmp = content.split('=')
                    $total_poll_count = tmp[1].chomp
                elsif(content =~ /volume/i)
                    tmp = content.split('=')
                    $volumes = tmp[1].chomp
                elsif(content =~ /threshold/i)
                    tmp = content.split('=')
                    $threshold = tmp[1].chomp
                elsif(content =~ /mailserver/i)
                    tmp = content.split('=')
                    $mailserver = tmp[1].chomp
                elsif(content =~ /to/i)
                    tmp = content.split('=')
                    $to_addr = tmp[1].chomp
                elsif(content =~ /from/i)
                    tmp = content.split('=')
                    $from_addr = tmp[1].chomp
	        end
	    end
        end
    end
end

    
# Send e-mail
def send_mail(vol)
    subject = "Volume usage on storage system : " + $storage + "\n"
    header = "From :" + $from_addr + "\r\nTo:" + $to_addr + "\r\nSubject :" + subject
    total_size_mb = (($total_volume_size)/(1024 * 1024)).round
    used_size_mb = (($used_volume_size)/(1024 * 1024)).round
    msg = "Volume Statistics for " + (vol).to_s +
          "\nTotal Size  :" + (total_size_mb).to_s +
          "\nUsed Size  :" + (used_size_mb).to_s +
          "\n" + ($percent_space_avail).to_s + "% space available \n"
    message = header + msg
    Net::SMTP.start($mailserver, 25) do |smtp|
        smtp.send_message message, $from_addr, $to_addr
    end
end

	
def monitor_volume()
    read_config_file()
    get_volume_info()
end

args = ARGV.length
if(args < 2)
    print_usage() 
end
$storage = ""
$user = ARGV.shift
$pw = ARGV.shift
$poll_frequency = 0
$total_poll_count = 1
$mailserver = ""
$from_addr = ""
$to_addr = ""
$threshold = ""
$volumes = ""
$total_volume_size = 0
$used_volume_size = 0
$percent_space_avail = 0

i = 0
while(i < $total_poll_count.to_i)
    monitor_volume()
    sleep($poll_frequency.to_i)
    i = i + 1
end




