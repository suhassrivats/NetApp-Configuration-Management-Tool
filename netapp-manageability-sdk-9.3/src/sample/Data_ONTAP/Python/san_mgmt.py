#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# san_mgmt.py                                                #
#                                                            #
# Application which uses ONTAPI APIs to perform SAN          #
# management operations for lun/igroup/fcp/iscsi             #
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

import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *


def print_usage():
    print("Usage: sanmgmt.py <filer> <user> <password> <command> \n")
    print("<filer>	  -- Name/IP address of the filer \n")
    print("<user> 	  -- User name \n")
    print("<password>   -- Password \n\n")
    print("posible commands are: \n")
    print("lun    igroup    fcp    iscsi \n")
    sys.exit (1)


def print_LUN_usage() :
    print("Usage: sanmgmt.py <filer> <user> <password> lun")
    print(" <command> \n\n")
    print("Possible commands are:\n")
    print("create  destroy  show  clone  map  unmap  show-map \n\n")
    sys.exit (1)


def print_LUN_create_usage() :
    print("Usage: sanmgmt.py <filer> <user> <passwd> lun create <path> ")
    print("<size-in-bytes> <ostype> [-sre <space-res-enabled>] \n\n")
    print("space-res-enabled: true/false \n")
    print("ostype: solaris/windows/hpux/aix/linux/vmware. \n")
    sys.exit (1)

    
def print_clone_usage() :
    print("Usage: sanmgmt.py <filer> <user> <password> lun clone ")
    print("<command> \n")
    print("Possible commands are: \n")
    print("create  start  stop  status \n")
    sys.exit (1)


def print_igroup_usage() :
    print("Usage: sanmgmt.py <filer> <user> <password> igroup")
    print(" <command> \n\n")
    print("Possible commands are: \n")
    print("create  destroy  add  show \n")
    sys.exit (1)

def print_fcp_usage() :
    print("Usage: sanmgmt.py <filer> <user> <password> fcp")
    print(" <command> \n\n")
    print("Possible commands are: \n")
    print("start  stop  status  config  show \n")
    sys.exit (1)
    
def print_fcp_config_usage() :
    print("Usage: SANMgmt <filer> <user> <password> ")
    print("fcp config <adapter> < [ up | down ] ")
    print("[ mediatype { ptp | auto | loop } ] ")
    print("[ speed { auto | 1 | 2 | 4 } ] > \n")
    sys.exit (1)


def print_iscsi_usage():
    print("Usage: sanmgmt.py <filer> <user> <password> iscsi")
    print(" <command> \n\n")
    print("Possible commands are: \n")
    print("start  stop  status  interface  show \n")
    sys.exit (1)


def print_iscsi_interface_usage() :
    print("Usage: sanmgmt.py <filer> <user> <password> iscsi ")
    print("interface <command> \n\n")
    print("Possible commands are: \n")
    print("enable  disable  show \n")
    sys.exit (1)


def process_LUN(s):
    index = 5
    path = ""
    sre = ""
    lun_type = ""
    
    if(args < 5):
        print_LUN_usage()
        
    if(sys.argv[index] == "create") :
        
        if(args < 8) :
            print_LUN_create_usage()
            sys.exit (1)

        lun_in = NaElement("lun-create-by-size")
        index = index + 1
        lun_in.child_add_string("path", sys.argv[index])
        index = index + 1
        lun_in.child_add_string("size", sys.argv[index])
        index = index + 1
        lun_in.child_add_string("type", sys.argv[index])
        index = index + 1

        if(args > 8 and sys.argv[index] == "-sre") :
            index = index + 1
            lun_in.child_add_string("space-reservation-enabled", sys.argv[index])
            index = index + 1

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
    

    elif(sys.argv[index] == "destroy") :
        if(args < 6):
            print ("Usage: sanmgmt.py <filer> <user> <passwd> lun destroy [-f] <lun-path> \n\n")
            print ("If -f is used, the LUN specified would be deleted even in ")
            print ("online and/or mapped state.\n")
            sys.exit (1)

        lun_in = NaElement("lun-destroy")
        index = index + 1

        if(sys.argv[index] == "-f") :
            lun_in.child_add_string("force","true")
            index = index + 1

        lun_in.child_add_string("path", sys.argv[index])
        index = index + 1
        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(str(out.results_reason()) + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
    

    elif(sys.argv[index] == "show") :
        lun_in = NaElement("lun-list-info")

        if(args > 5) :

            if(sys.argv[index+1] == "help") :
                print ("Usage: sanmgmt.py <filer> <user> <passwd> lun show [<lun-path>] \n")
                sys.exit (1)

            index = index + 1
            lun_in.child_add_string("path", sys.argv[index])

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        lun_info = out.child_get("luns")
        result = lun_info.children_get()
        print ("\n")

        for lun in result:
            path = lun.child_get_string("path")
            print  ("\npath: " + path)
            size = lun.child_get_string("size")
            print  ("\nsize: " + size)
            online = lun.child_get_string("online")
            print  ("\nonline: " + online )
            mapped = lun.child_get_string("mapped")
            print  ("\nmapped: " + mapped  )
            uuid = lun.child_get_string("uuid")
            print  ("\nuuid: " + uuid  )
            ser_num = lun.child_get_string("serial-number")
            print  ("\nserial-number: " + ser_num  )
            blk_size = lun.child_get_string("block-size")
            print  ("\nblock-size: " + blk_size  )
            is_sre = lun.child_get_string("is-space-reservation-enabled")
            print  ("\nis-space-reservation-enabled: " + is_sre )
            lun_type = lun.child_get_string(" multiprotocol-type")
            print  ("\nmultiprotocol-type: " + str(lun_type))
            print ("\n--------------------------------------\n")
	
    elif(sys.argv[index] == "clone"):
        if(args < 6) :
            print_clone_usage()

        index = index + 1

        if(sys.argv[index] == "create") :

            if(args < 9) :
                print ("Usage: sanmgmt.py <filer> <user> <password> lun clone ")
                print ("create <parent-lun-path> <parent-snapshot> <path> ")
                print ("[-sre <space-res-enabled>] \n")
                sys.exit (1)

            lun_in = NaElement("lun-create-clone")
            index = index + 1
            lun_in.child_add_string("parent-lun-path", sys.argv[index])
            index = index + 1
            lun_in.child_add_string("parent-snap", sys.argv[index])
            index = index + 1
            lun_in.child_add_string("path", sys.argv[index])
            index = index + 1

            if(args > 10 and sys.argv[index] == "-sre") :
                index = index + 1
                lun_in.child_add_string("space-reservation-enabled", sys.argv[index])

            out = s.invoke_elem(lun_in)

            if(out.results_status() == "failed") :
                print(out.results_reason() + "\n")
                sys.exit(2)

            else :
                print ("Operation successful!\n")

        elif(sys.argv[index] == "status") :
            lun_in = NaElement("lun-clone-status-list-info")

            if(args > 6) :
                if(sys.argv[index+1] == "help") :
                    print ("Usage: sanmgmt.py <filer> <user> <password> lun ")
                    print ("clone status [<lun-path>] \n")
                    sys.exit (1)

                index = index + 1
                lun_in.child_add_string("path", sys.argv[index])

            out = s.invoke_elem(lun_in)

            if(out.results_status() == "failed") :
                print(out.results_reason() + "\n")
                sys.exit(2)
	    
            clone_info = out.child_get("clone-status")
            result = clone_info.children_get()
            print ("\n")

            for clone in result:
                path = clone.child_get_string("path")
                print  ("\npath: " + path )
                blks_cmp = clone.child_get_string("blocks-completed")
                print  ("\nblocks-completed: " + blks_cmp)
                blks_total = clone.child_get_string("blocks-total")
                print  ("\nblocks-total: " + blks_total )
                print ("\n--------------------------------------\n")

        elif(sys.argv[index] == "start") :
            lun_in = NaElement("lun-clone-start")

            if((args < 7) or (sys.argv[index+1] == "help")) :
                print ("Usage: sanmgmt.py <filer> <user> <password> lun ")
                print ("clone start <lun-path> \n")
                sys.exit (1)

            if(args > 6) :
                index = index + 1
                lun_in.child_add_string("path", sys.argv[index])

            out = s.invoke_elem(lun_in)

            if(out.results_status() == "failed") :
                print(out.results_reason() + "\n")
                sys.exit(2)

            else :
                print ("Operation successful!\n")


        elif(sys.argv[index] == "stop") :
            lun_in = NaElement("lun-clone-stop")

            if((args < 7) or (sys.argv[index+1] == "help")) :
                print ("Usage: sanmgmt.py <filer> <user> <password> lun ")
                print ("clone stop <lun-path> \n")
                sys.exit (1)

            if(args > 6) :
                index = index + 1
                lun_in.child_add_string("path", sys.argv[index])

            out = s.invoke_elem(lun_in)

            if(out.results_status() == "failed") :
                print(out.results_reason() + "\n")
                sys.exit(2)

            else :
                print ("Operation successful!\n")

        else :
            print_clone_usage()
	
    elif(sys.argv[index] == "map") :

        if(args < 7) :
            print ("Usage: sanmgmt.py <filer> <user> <password> lun map ")
            print ("<initiator-group> <lun-path> [-f] [-id <lun-id>]\n")
            sys.exit (1)

        lun_in = NaElement("lun-map")
        index = index + 1
        lun_in.child_add_string("initiator-group", sys.argv[index])
        index = index + 1
        lun_in.child_add_string("path", sys.argv[index])
        index = index + 1
        
        if(args > 7 and sys.argv[index] == "-f") :
            lun_in.child_add_string("force", "true")
            if(args > 8) :
                index = index + 1

        if(args > 7 and sys.argv[index] == "-id") :
            index = index + 1
            lun_in.child_add_string("lun-id", sys.argv[index])
            index = index + 1

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
	
    elif(sys.argv[index] == "unmap") :

        if(args < 7) :
            print ("Usage: sanmgmt.py <filer> <user> <password> lun unmap ")
            print ("<initiator-group> <lun-path> \n")
            sys.exit (1)

        lun_in = NaElement("lun-unmap")
        index = index + 1
        lun_in.child_add_string("initiator-group", sys.argv[index])
        index = index + 1
        lun_in.child_add_string("path", sys.argv[index])
        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
    

        
    elif(sys.argv[index] == "show-map") :
        lun_in = NaElement("lun-map-list-info")

        if(args < 6) :
            print ("Usage: sanmgmt.py <filer> <user> <password> lun show-map <lun-path> \n")
            sys.exit (1)

        index = index + 1
        lun_in.child_add_string("path", sys.argv[index])
        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        inititorgr_info = out.child_get("initiator-groups")
        result = inititorgr_info.children_get()
        print ("\n")

        for initiatorgr in result:
            gname = initiatorgr.child_get_string("initiator-group-name")
            print  ("\ninitiator-group-name: " + gname )
            ostype = initiatorgr.child_get_string("initiator-group-os-type")
            print  ("\ninitiator-group-os-type: " + ostype)
            gtype = initiatorgr.child_get_string("initiator-group-type")
            print  ("\ninitiator-group-type: " + gtype )
            alua = initiatorgr.child_get_string("initiator-group-alua-enabled")
            print  ("\ninitiator-group-alua-enabled: " + alua)
            lunid = initiatorgr.child_get_string("lun-id")

            if(lunid != "") :
                print  ("\nlun-id: " + lunid )

            initiators = initiatorgr.child_get("initiators")

            if(initiators != None) :
                iresult = initiators.children_get()
                print  ("\ninitiator-name(s):\n")

                for initiator in iresult:
                    iname = initiator.child_get_string("initiator-name")
                    print  (iname + "\n")
				
            print ("--------------------------------------\n")
	
    else :
        print_LUN_usage()

def process_igroup(s):
    index = 5
    path = ""
    sre = ""
    group_type = ""
    
    if(args < 5):
        print_igroup_usage()

    if(sys.argv[index] == "create"):

        if(args < 7) :
            print ("Usage: sanmgmt.py <filer> <user> <passwd> igroup create ")
            print ("<igroup-name> <igroup-type> [-bp <bind-portset>] ")
            print ("[-os <os-type>] \n\n")
            print ("igroup-type: fcp/iscsi \n")
            print ("os-type: solaris/windows/hpux/aix/linux. ")
            print ("If not specified, \"default\" is used. \n")
            sys.exit (1)

        lun_in = NaElement("igroup-create")
        index = index + 1
        lun_in.child_add_string("initiator-group-name", sys.argv[index])
        index = index + 1
        lun_in.child_add_string("initiator-group-type", sys.argv[index])
        
        if(args > 7 and sys.argv[index+1] == "-bp") :
            index = index + 2
            lun_in.child_add_string("bind-portset", sys.argv[index])

        if(args > 7 and sys.argv[index+1] == "-os") :
            index = index + 2
            lun_in.child_add_string("os-type", sys.argv[index])
            index = index + 1

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
	
    elif(sys.argv[index] == "destroy") :

        if(args < 6) :
            print ("Usage: sanmgmt.py <filer> <user> <passwd> igroup destroy <igroup-name> [-f]")
            print ("-f : Forcefully destroy igroup \n")
            sys.exit (1)

        lun_in = NaElement("igroup-destroy")
        index = index + 1
        lun_in.child_add_string("initiator-group-name", sys.argv[index])

        if(args > 6 and sys.argv[index+1] == "-f") :
            lun_in.child_add_string("force", "true")

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
        
    elif(sys.argv[index] == "show"):

        if(args > 6 and sys.argv[index+1] == "help") :
            print ("Usage: sanmgmt.py <filer> <user> <password> ")
            print ("lun show [<lun-path>] \n")
            sys.exit (1)
        
        lun_in = NaElement("igroup-list-info")

        if(args > 6) :
            index = index + 1
            lun_in.child_add_string("initiator-group-name", sys.argv[index])

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        igroup_info = out.child_get("initiator-groups")
        result = igroup_info.children_get()
        print ("\n")

        for igroup in result:
            name = igroup.child_get_string("initiator-group-name")
            print  ("initiator-group-name: " + name + "\n")
            ostype = igroup.child_get_string("initiator-group-os-type")
            print  ("initiator-group-os-type: " + ostype + "\n")
            group_type = igroup.child_get_string("initiator-group-type")
            print  ("initiator-group-type: "+ group_type +" \n")
            lunid = igroup.child_get_string("lun-id")

            if(lunid != None) :
                print  ("lun-id: " + str(lunid) + "\n")

            initiators = igroup.child_get_string("initiators")

            if(initiators != None and initiators != "") :
                iresult = initiators.children_get()
                print  ("initiator-name(s):\n")

                for initiator in iresult:
                    iname = initiator.child_get_string("initiator-name")
                    print (iname + "\n")
            print ("--------------------------------------\n")
	

    elif(sys.argv[index] == "add") :

        if((args < 7) or (args == 7 and sys.argv[index+1] == "-f")) :
            print ("Usage: sanmgmt.py <filer> <user> <passwd> igroup add ")
            print ("[-f] <igroup-name> <initiator> \n\n")
            print ("and type conflict checks with the cluster partner.\n")
            sys.exit (1)

        lun_in = NaElement("igroup-add")
        

        if(sys.argv[index+1] == "-f") :
            lun_in.child_add_string("force", "true")
            index = index + 1

        index = index + 1
        lun_in.child_add_string("initiator-group-name", sys.argv[index])
        index = index + 1
        lun_in.child_add_string("initiator", sys.argv[index])

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
	
	
    else :
        print_igroup_usage()
    
	
def process_fcp(s):
    index = 5
    path = ""
    sre = ""
    process_type = ""
    if(args < 5):
        print_fcp_usage()

    if(sys.argv[index] == "start") :
        lun_in = NaElement("fcp-service-start")
        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")

    elif(sys.argv[index] == "stop") :
        lun_in = NaElement("fcp-service-stop")
        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")

    elif(sys.argv[index] == "status") :
        lun_in = NaElement("fcp-service-status")
        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

       	if(out.child_get_string("is-available") == "true") :
            print ("FCP service is running.\n")

        else :
            print("FCP service is not running.\n")
	
		
    elif(sys.argv[index] == "config") :

        if((args < 7) or (sys.argv[index+1] == "help")) :
            print_fcp_config_usage()

        index = index + 2

        if(sys.argv[index] == "up") :
            lun_in = NaElement("fcp-adapter-config-up")
            lun_in.child_add_string("fcp-adapter", sys.argv[index-1])
	
        elif(sys.argv[index] == "down") :
            lun_in = NaElement("fcp-adapter-config-down")
            lun_in.child_add_string("fcp-adapter", sys.argv[index-1])
	
        elif(sys.argv[index] == "mediatype") :
            lun_in = NaElement("fcp-adapter-config-media-type")
            lun_in.child_add_string("fcp-adapter", sys.argv[index-1])
            index = index + 1
            lun_in.child_add_string("media-type", sys.argv[index])
		
        elif(sys.argv[index] == "speed") :
            lun_in = NaElement("fcp-adapter-set-speed")
            lun_in.child_add_string("fcp-adapter", sys.argv[index-1])
            index = index + 1
            lun_in.child_add_string("speed", sys.argv[index])

        else :
            print_fcp_config_usage()

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
		
    elif(sys.argv[index] == "show") :

        if(args > 5 and sys.argv[index+1] == "help") :
            print ("Usage: sanmgmt.py <filer> <user> <password> ")
            print ("fcp show [<fcp-adapter>] \n")
            sys.exit (1)

        lun_in = NaElement("fcp-adapter-list-info")

        if(args > 5) :
            index = index + 1
            lun_in.child_add_string("fcp-adapter", sys.argv[index])

        out = s.invoke_elem(lun_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        adapter_info = out.child_get("fcp-config-adapters")
        result = adapter_info.children_get()
        print ("\n")

        for adapter in result:
            adapter_name = adapter.child_get_string("adapter")
            print  ("adapter: " + adapter_name + "\n")
            nodename = adapter.child_get_string("node-name")
            print  ("node-name: " + nodename + "\n")
            port = adapter.child_get_string("port-name")
            print  ("port-name: " + port + "\n")
            addr = adapter.child_get_string("port-address")
            print  ("port-address: " + addr + "\n")
            adapter_type = adapter.child_get_string("adapter-type")
            print  ("adapter-type: " + adapter_type + "\n")
            media_type = adapter.child_get_string("media-type")
            print  ("media-type: " + media_type + "\n")
            speed = adapter.child_get_string("speed")
            print  ("speed: " + speed + "\n")
            partner = adapter.child_get_string("partner-adapter")
            print  ("partner-adapter: " + str(partner) + "\n")
            standby = adapter.child_get_string("standby")
            print  ("standby: " + standby + "\n")
            print ("--------------------------------------\n")
            
    else :
        print_fcp_usage()

def process_iscsi(s):
    index = 5
    path = ""
    sre = ""
    process_type = ""
    if(args < 5):
        print_iscsi_usage()    
    
    if(sys.argv[index] == "start") :
        process_in = NaElement("iscsi-service-start")
        out = s.invoke_elem(process_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() +"\n")
            sys.exit(2)

        else :
            print ("Operation successful!\n")
		
    elif(sys.argv[index] == "stop") :
        process_in = NaElement("iscsi-service-stop")
        out = s.invoke_elem(process_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

    elif(sys.argv[index] == "status") :
        process_in = NaElement("iscsi-service-status")
        out = s.invoke_elem(process_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        if(out.child_get_string("is-available") == "true") :
            print ("iSCSI service is running.\n")

        else :
            print("iSCSI service is not running.\n")
		
    elif(sys.argv[index] == "interface") :

        if((args < 6) or (sys.argv[index+1] == "help")) :
            print_iscsi_interface_usage()

        index = index + 1

        if(sys.argv[index] == "enable") :

            if(args < 7) :
                print ("Usage: sanmgmt.py <filer> <user> <password> iscsi ")
                print (" interface enable <interface-name>\n")
                sys.exit (1)
            
            process_in = NaElement("iscsi-interface-enable")
            index = index + 1
            process_in.child_add_string("interface-name", sys.argv[index])
            out = s.invoke_elem(process_in)

            if(out.results_status() == "failed") :
                print(out.results_reason() + "\n")
                sys.exit(2)

            else :
                print ("Operation successful!\n")
	
        elif(sys.argv[index] == "disable") :

            if(args < 7) :
                print ("Usage: sanmgmt.py <filer> <user> <password> iscsi ")
                print (" interface disable <interface-name>\n")
                sys.exit (1)

            process_in = NaElement("iscsi-interface-disable")
            index = index + 1
            process_in.child_add_string("interface-name", sys.argv[index])

            out = s.invoke_elem(process_in)

            if(out.results_status() == "failed") :
                print(out.results_reason() +"\n")
                sys.exit(2)

            else :
                print ("Operation successful!\n")
			
        elif(sys.argv[index] == "show") :
            index = index + 1
            process_in = NaElement("iscsi-interface-list-info")

            if(args > 6) :

                if(sys.argv[index] == "help") :
                    print ("Usage: sanmgmt.py <filer> <user> <password> iscsi ")
                    print (" interface show [<interface-name>]\n")
                    sys.exit (1)

                else :
                    index = index + 1
                    process_in.child_add_string("interface-name", sys.argv[index])
				
            out = s.invoke_elem(process_in)

            if(out.results_status() == "failed") :
                print(out.results_reason() + "\n")
                sys.exit(2)

            iscsi_interface_info = out.child_get("iscsi-interface-list-entries")
            result = iscsi_interface_info.children_get()
            print ("\n------------------------------------------------------\n")

            for interface in result:
                name = interface.child_get_string("interface-name")
                print  ("interface-name: " + name + "\n")
                enabled = interface.child_get_string("is-interface-enabled")
                print  ("is-interface-enabled: " + enabled + "\n")
                tpgroup = interface.child_get_string("tpgroup-name")
                print  ("tpgroup-name: " + tpgroup + "\n")
                print ("------------------------------------------------------\n")

        else :
            print_iscsi_interface_usage()

        out = s.invoke_elem(process_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

    elif(sys.argv[index] == "show") :
        index = index + 1

        if((args < 6) or (sys.argv[index] != "initiator")) :
            print ("Usage: sanmgmt.py <filer> <user> <password> iscsi ")
            print ("show initiator \n")
            sys.exit (1)

        process_in = NaElement("iscsi-initiator-list-info")
        out = s.invoke_elem(process_in)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

        inititor_info = out.child_get("iscsi-initiator-list-entries")
        result = inititor_info.children_get()
        print ("\n")

        for initiator in result:
            alname = initiator.child_get_string("initiator-aliasname")
            print  ("initiator-aliasname: " + alname + "\n")
            nodename = initiator.child_get_string("initiator-nodename")
            print  ("initiator-nodename: " + nodename + "\n")
            isid = initiator.child_get_string("isid")
            print  ("isid: " + isid + "\n")
            ssid = initiator.child_get_string("target-session-id")
            print  ("target-session-id: " + ssid + "\n")
            tptag = initiator.child_get_int("tpgroup-tag")
            print  ("tpgroup-tag: " + str(tptag) + "\n")
            print ("--------------------------------------\n")
        
    else :
        print_iscsi_usage()
  
 
def main():
    s = NaServer (filer, 1, 3)
    response = s.set_style('LOGIN')

    if (response and response.results_errno() != 0) :
        r = response.results_reason()
        print ("Unable to set authentication style " + r + "\n")
        sys.exit (2)

    s.set_admin_user(user, pw)
    response = s.set_transport_type('HTTP')

    if (response and response.results_errno() != 0) :
        r = response.results_reason()
        print ("Unable to set HTTP transport" + r + "\n")
        sys.exit (2)

    if(command == "lun"):
        process_LUN(s)

    elif(command == "igroup"):
        process_igroup(s)

    elif(command == "fcp"):
        process_fcp(s)

    elif(command == "iscsi"):
        process_iscsi(s)

    else:
        print ("Invalid operation\n")
        print_usage()


args = len(sys.argv) - 1

if(args < 4):
    print_usage()
    
filer = sys.argv[1]
user = sys.argv[2]
pw = sys.argv[3]
command = sys.argv[4]

main()

