//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// useradmin.c                                                //
//                                                            //
// Sample code for API level access for a particular user     // 
// using useradmin                                            //
//                                                            //
// This sample code demonstrates the following                // 
// using ONTAPI APIs :                                        //
//    user-add/user-modify/user-list/role-add/role-list etc   //
//                                                            //
// Copyright 2003 Network Appliance, Inc. All rights          //
// reserved. Specifications subject to change without notice. // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
//                                                            //
// See printUsage() for command-line syntax                   //
//                                                            //
//============================================================//

//234567890123456789012345678901234567890123456789012345678901234567890123456789

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "netapp_api.h"

//============================================================//
//
// portability
//
#ifdef WIN32
	#define strcasecmp _stricmp
#endif


#if defined(__LP64__)
#define INT_TO_PTR_CAST	(intptr_t)(int)
#else
#define INT_TO_PTR_CAST	(intptr_t)
#endif


int strsafecmp(char *s1, char *s2) {
	if(s1 == NULL) {
		return -1;
	}
	return (strcmp(s1,s2));
}

void printUsage()
{
	fprintf(stderr, "Usage: useradmin <filer> <user> <password> "); 
	fprintf(stderr,	"<operation> [<value1>] [<value2>] ..\n");
	fprintf(stderr, "<filer>	  --"); 
	fprintf(stderr, "Name/IP address of the filer \n");
	fprintf(stderr, "<user> 	  -- User name\n");
	fprintf(stderr, "<password>   -- Password\n");
	fprintf(stderr, "<operation>  -- "); 
	fprintf(stderr, "user-add/user-modify/user-list/role-add/role-list/group-add/group-list\n");
	fprintf(stderr, "<value1>\t-- This depends on the operation\n");
	fprintf(stderr, "<value2>\t-- This depends on the operation\n");
}

void printRoleAddUsage() {
	fprintf(stderr, "Usage: useradmin <filer> <user> <password> "); 
	fprintf(stderr,	"role-add <name> -ac <allowed-capability-name> [-c <comment>]  \n");
}

void printUserUsage(int modify) {
    fprintf(stderr, "Usage: useradmin <filer> <user> <password> "); 
    if(modify == 1) {
	    fprintf(stderr,	"user-modify <name> [-pmina <passwd-min-age>] ");
    }
    else {
        fprintf(stderr,	"user-add <name> <passwd> [-pmina <passwd-min-age>] ");
    }
    fprintf(stderr,"[-pmaxa <passwd-max-age>] [-fname <full-name>] [-rid <rid>] ");
    fprintf(stderr,"[-c <comment>] [-s <status>] -group <group-name> \n");
    
}

void printGroupAddUsage() {
	fprintf(stderr, "Usage: useradmin <filer> <user> <password> "); 
	fprintf(stderr,	"group-add <group-name> [-c <comment>] -rname <role-name> \n");
}


int main(int argc, char* argv[])
{
	int 		r = 1, i = 0;
	na_server_t*	s;
	na_elem_t*		out;
	na_elem_t*		outputElem;
	na_elem_t*		ss;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;
	
	char			err[256];
	char*			filername = argv[1];
	char*			user = argv[2]; 
	char*			passwd = argv[3];
	char*			operation = argv[4];

	
	int recordsCnt = 0;
	char *    argvBuff[20];


	int flag = 1;


	if (argc < 5) {
		printUsage();
		return -1;
	}

	for(i = 0 ; i < 20; i++) {
		if(i < argc) {
			argvBuff[i] = argv[i];
		}
		else {
			argvBuff[i] = NULL;
		}
	}
	
	//
	// One-time initialization of system on client
	//
	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}
	
	//
	// Initialize connection to server, and
	// request version 1.1 of the API set.
	//
	s = na_server_open(filername, 1, 1); 
	
	//
	// Set connection style (HTTP)
	//
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, user, passwd);

    
	if(!strcmp(operation, "user-add") || !strcmp(operation,"user-modify"))
	{
        na_elem_t *in = NULL;
	    na_elem_t *user = NULL;
	    na_elem_t *user_info = NULL;
	    na_elem_t *all_cap = NULL;
	    na_elem_t *all_cap_info = NULL;
	    int cc = 5;
        

        if(argc < 7) {
            if(!strcmp(operation, "user-modify")) {
                printUserUsage(1);
            }
            else {
                printUserUsage(0);
            }
            return -1;
        }
	     
        user = na_elem_new("useradmin-user");
	    user_info = na_elem_new("useradmin-user-info");

        na_child_add_string(user_info, "name",argvBuff[cc++]);

        if(!strcmp(operation,"user-add")) {
            in = na_elem_new("useradmin-user-add");
            na_child_add_string(in, "password",argvBuff[cc++]);
        }
        else {
            in = na_elem_new("useradmin-user-modify");
        }
	
        
        if(!strsafecmp(argvBuff[cc],"-pmina")) {
	        na_child_add_string(user_info, "password-minimum-age",argvBuff[++cc]);
	        ++cc;
        }
        if(!strsafecmp(argvBuff[cc],"-pmaxa")) {
	        na_child_add_string(user_info, "password-maximum-age",argvBuff[++cc]);
	        ++cc;
        }
        if(!strsafecmp(argvBuff[cc],"-fname")) {
	        na_child_add_string(user_info, "full-name",argvBuff[++cc]);
	        ++cc;
        }
        if(!strsafecmp(argvBuff[cc],"-rid")) {
	        na_child_add_string(user_info, "rid",argvBuff[++cc]);
	        ++cc;
        }
	    if(!strsafecmp(argvBuff[cc],"-c")) {
	        na_child_add_string(user_info, "comment",argvBuff[++cc]);
	        ++cc;
        }
		if(!strsafecmp(argvBuff[cc],"-s")) {
	        na_child_add_string(user_info, "status",argvBuff[++cc]);
	        ++cc;
        }
	    
        if(!strsafecmp(argvBuff[cc],"-group"))	{
		    na_elem_t* elm_groups = na_elem_new("useradmin-groups");
		    na_elem_t* elm_group_info = na_elem_new("useradmin-group-info");
		    na_child_add_string(elm_group_info, "name",argvBuff[++cc]);
	    	na_child_add(elm_groups,elm_group_info);
            na_child_add(user_info,elm_groups);
	    }
		else {
			fprintf(stderr,	"group name missing\n\n");
			if(!strcmp(operation, "user-modify")) {
                printUserUsage(1);
            }
            else {
                printUserUsage(0);
            }
			return -1;
		}

        
	    na_child_add(user,user_info);
	    na_child_add(in,user);
     
    	out = na_server_invoke_elem(s,in);

        if (na_results_status(out) != NA_OK) {
		    printf("Error %d: %s\n", na_results_errno(out),
		    na_results_reason(out));
		    na_elem_free(in);
		    return -2;
	    }
		else {
			printf("Operation successful!\n");
		}

	}
    else if(!strcmp(operation, "role-add")) {
        na_elem_t *in = NULL;
	    na_elem_t *role = NULL;
	    na_elem_t *role_info = NULL;
	    na_elem_t *all_cap = NULL;
	    na_elem_t *all_cap_info = NULL;
	    int pos = 5;

        if(argc < 8)
        {
            printRoleAddUsage();
            return -1;
        }
	     
	    in = na_elem_new("useradmin-role-add");
	    role = na_elem_new("useradmin-role");
	    role_info = na_elem_new("useradmin-role-info");
	
	    na_child_add_string(role_info, "name",argvBuff[pos++]);

		if(!strsafecmp(argvBuff[pos],"-ac")) {
		    
		all_cap = na_elem_new("allowed-capabilities");
		all_cap_info = na_elem_new("useradmin-capability-info");
		na_child_add_string(all_cap_info,"name", argvBuff[++pos]);
		na_child_add(all_cap,all_cap_info);
        }
		else {
			printRoleAddUsage();
            return -1;
		}
    
	    if(!strsafecmp(argvBuff[pos],"-c")) {
	        na_child_add_string(role_info, "comment",argvBuff[++pos]);
	        ++pos;
        }
		
		na_child_add(role_info,all_cap);
		na_child_add(role,role_info);
	    na_child_add(in,role);
     
    	out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
		    printf("Error %d: %s\n", na_results_errno(out),
		    na_results_reason(out));
		    return -2;
	    }
		else {
			printf("Operation successful!\n");
		}
	}
	else if(!strcmp(operation, "group-add")) {
        na_elem_t *in = NULL;
	    na_elem_t *group = NULL;
	    na_elem_t *group_info = NULL;
		na_elem_t *role = NULL;
	    na_elem_t *role_info = NULL;
	    na_elem_t *all_cap = NULL;
	    na_elem_t *all_cap_info = NULL;
	    int pos = 5;

        if(argc < 8)
        {
            printGroupAddUsage();
            return -1;
        }
	     
	    in = na_elem_new("useradmin-group-add");
	    group = na_elem_new("useradmin-group");
	    group_info = na_elem_new("useradmin-group-info");
	
	    na_child_add_string(group_info, "name",argvBuff[pos++]);
    
	    if(!strsafecmp(argvBuff[pos],"-c")) {
	        na_child_add_string(group_info, "comment",argvBuff[++pos]);
	        ++pos;
        }
		
		if(!strsafecmp(argvBuff[pos],"-rname")) {
			 role = na_elem_new("useradmin-roles");
			role_info = na_elem_new("useradmin-role-info");
			na_child_add_string(role_info, "name",argvBuff[++pos]);
			++pos;
			na_child_add(role,role_info);
			na_child_add(group_info,role);
		}
		else {
			fprintf(stderr,	"role name missing\n");
			printGroupAddUsage();
			return -1;
		}

		na_child_add(group,group_info);
	    na_child_add(in,group);
     
    	out = na_server_invoke_elem(s,in);
		
		if (na_results_status(out) != NA_OK) {
		    printf("Error %d: %s\n", na_results_errno(out),
		    na_results_reason(out));
		    return -2;
	    }
		else {
			printf("Operation successful!\n");
		}
	}
    else if(!strcmp(operation, "group-list")) {
        na_elem_t *in = NULL;
        in = na_elem_new("useradmin-group-list");
	
	    if(argvBuff[5] != NULL) {
            na_child_add_string(in, "group-name",argvBuff[5]);
        }
	    if(argvBuff[6] != NULL) {
            na_child_add_string(in, "verbose",argvBuff[6]);
        }
        out = na_server_invoke_elem(s,in);

        if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
		return -3;
	    }
	    else {
		     outputElem = na_elem_child(out, "useradmin-groups");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return -2;
			}
					
			printf("------------------------------------------------------\n");
			
			for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {
				
				if(na_child_get_string(ss,"allowed-capabilities")) {
					na_elem_t* outElem1 = ss;
					na_elem_iter_t	iter1;
					na_elem_t* ss1;
				
					printf("  allowed-capabilities:");
          
                    outElem1 = na_elem_child(ss, "useradmin-roles");

                    for (iter1 = na_child_iterator(outElem1);
						(ss1 = na_iterator_next(&iter1)) != NULL;  ) {
						
						if(na_child_get_string(ss1,"name")) {
							printf("%s\t",na_child_get_string(ss1,"name"));
						}

					}
					printf("\n");
				}
				if(na_child_get_string(ss,"name")) {
					printf("  name:%s\n",na_child_get_string(ss,"name"));
				}
                if(na_child_get_string(ss,"comment")) {
					printf("  comment:%s\n",na_child_get_string(ss,"comment"));
				}
				if(na_child_get_string(ss,"rid")) {
					printf("  rid:%s\n",na_child_get_string(ss,"rid"));
				}
				if(na_child_get_string(ss,"useradmin-roles")) {
					na_elem_t* outElem1;
					na_elem_iter_t	iter1;
					na_elem_t* ss1;

					printf("  useradmin-roles:\n");

				    outElem1 = na_elem_child(ss, "useradmin-roles");
					
					for (iter1 = na_child_iterator(outElem1);
						(ss1 = na_iterator_next(&iter1)) != NULL;  ) {
						
						if(na_child_get_string(ss1,"allowed-capabilities")) {
							na_elem_t* outElem2 = ss1;
							na_elem_iter_t	iter2;
							na_elem_t* ss2;

							printf("    allowed-capabilities:");
							outElem2 = na_elem_child(ss, "allowed-capabilities");
							
							for (iter2 = na_child_iterator(outElem2);
								(ss2 = na_iterator_next(&iter2)) != NULL;  ) {
								if(na_child_get_string(ss2,"name")) {
								    printf("%s  ",na_child_get_string(ss2,"name"));
								}
							}
							printf("\n");
						}
                        if(na_child_get_string(ss1,"name")) {
							printf("    name:%s\n",na_child_get_string(ss1,"name"));
						}
						if(na_child_get_string(ss1,"comment")) {
							printf("    comment:%s\n",na_child_get_string(ss1,"comment"));
						}
					}
				    printf("\n");
				}
				printf("----------------------------------------------------\n");				  
			}
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
    else if(!strcmp(operation, "role-list")) {
        na_elem_t *in = NULL;
        in = na_elem_new("useradmin-role-list");
	    
	    if(argvBuff[5] != NULL) {
            na_child_add_string(in, "role-name",argvBuff[5]);
        }
	     	 
    	out = na_server_invoke_elem(s,in);

        if (na_results_status(out) != NA_OK) {
		    printf("Error %d: %s\n", na_results_errno(out),
		    na_results_reason(out));
		    return -2;
	    }
	    else {
		    outputElem = na_elem_child(out, "useradmin-roles");
			if (outputElem == NULL) {
                na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return -2;
            }
			
            printf("--------------------------------------------------------------\n");
			
			for (iter = na_child_iterator(outputElem);
			    (ss = na_iterator_next(&iter)) != NULL;  ) {
                
				if(na_child_get_string(ss,"name")) {
					printf("  name:%s\n",na_child_get_string(ss,"name"));
				}
                if(na_child_get_string(ss,"comment")) {
					printf("  comment:%s\n",na_child_get_string(ss,"comment"));
				}
                if(na_child_get_string(ss,"allowed-capabilities")) {
					na_elem_t* outElem1 ;
					na_elem_iter_t	iter1;
					na_elem_t* ss1;
				
					printf("  useradmin-allowed-capability-info names:\n");

                    outElem1 = na_elem_child(ss, "allowed-capabilities");

					for (iter1 = na_child_iterator(outElem1);
						(ss1 = na_iterator_next(&iter1)) != NULL;  ) {
						
						if(na_child_get_string(ss1,"name")) {
							printf("        %s\n",na_child_get_string(ss1,"name"));
						}

					}
					printf("\n");
				}
				
				printf("--------------------------------------------------------------\n");				  
			}
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}

    else if(!strcmp(operation, "user-list")) {
       na_elem_t *in = NULL;
    
       in = na_elem_new("useradmin-user-list");
	    
	   out = na_server_invoke_elem(s,in);

        if (na_results_status(out) != NA_OK) {
		    printf("Error %d: %s\n", na_results_errno(out),
		    na_results_reason(out));
		    return -2;
	    }
	    else {
		    outputElem = na_elem_child(out, "useradmin-users");
			if (outputElem == NULL) {
			    na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return -2;
			}
			  
			printf("------------------------------------------------------\n");
			
			for (iter = na_child_iterator(outputElem);
			    (ss = na_iterator_next(&iter)) != NULL;  ) {
				
				if(na_child_get_string(ss,"allowed-capabilities")) {
					na_elem_t* outElem1 ;
					na_elem_iter_t	iter1;
					na_elem_t* ss1;
				
					printf("  allowed-capabilities:\n");

                    outElem1 = na_elem_child(ss, "allowed-capabilities");
                    //parse for allowed capabilities name(s)
					for (iter1 = na_child_iterator(outElem1);
						(ss1 = na_iterator_next(&iter1)) != NULL;  ) {
						
						if(na_child_get_string(ss1,"name")) {
							printf("    %s\n",na_child_get_string(ss1,"name"));
						}
					}
					printf("\n");
				}
                if(na_child_get_string(ss,"name")) {
					printf("  name:%s\n",na_child_get_string(ss,"name"));
				}
				if(na_child_get_string(ss,"comment")) {
					printf("  comment:%s\n",na_child_get_string(ss,"comment"));
				}
                if(na_child_get_string(ss,"full-name")) {
					printf("  comment:%s\n",na_child_get_string(ss,"full-name"));
				}
                if(na_child_get_string(ss,"password-maximum-age")) {
					printf("  name:%s\n",na_child_get_string(ss,"password-maximum-age"));
				}
                if(na_child_get_string(ss,"password-minimum-age")) {
					printf("  password-minimum-age:%s\n",na_child_get_string(ss,"password-minimum-age"));
				}
                if(na_child_get_string(ss,"rid")) {
					printf("  rid:%s\n",na_child_get_string(ss,"rid"));
				}
                if(na_child_get_string(ss,"status")) {
					printf("  status:%s\n",na_child_get_string(ss,"status"));
				}
                if(na_child_get_string(ss,"useradmin-groups")) {
					na_elem_t* outElem1 ;
					na_elem_iter_t	iter1;
					na_elem_t* ss1;
				
					printf("  useradmin-group-info names:\n");
                    //parse the useradmin groups
                    outElem1 = na_elem_child(ss, "useradmin-groups");

					for (iter1 = na_child_iterator(outElem1);
						(ss1 = na_iterator_next(&iter1)) != NULL;  ) {
						
                        if(na_child_get_string(ss1,"allowed-capabilities")) {
                            na_elem_t* outElem2 ;
					        na_elem_iter_t	iter2;
					        na_elem_t* ss2;

                            outElem2 = na_elem_child(ss1, "allowed-capabilities");
                            for (iter2 = na_child_iterator(outElem2);
						        (ss2 = na_iterator_next(&iter2)) != NULL;  ) {
                
                                if(na_child_get_string(ss2,"name")) {
							        printf("    %s\n",na_child_get_string(ss2,"name"));
						        }
              
                             }
					    }
                        if(na_child_get_string(ss1,"comment")) {
						    printf("    %s\n",na_child_get_string(ss1,"comment"));
					    }
					    if(na_child_get_string(ss1,"name")) {
						    printf("    %s\n",na_child_get_string(ss1,"name"));
					    }
                        if(na_child_get_string(ss1,"rid")) {
						    printf("    %s\n",na_child_get_string(ss1,"rid"));
					    }
                        if(na_child_get_string(ss1,"useradmin-roles")) {
                            na_elem_t* outElem2 ;
					        na_elem_iter_t	iter2;
					        na_elem_t* ss2;
                            //parse the useradmin roles
                            outElem2 = na_elem_child(ss1, "useradmin-roles");
                            for (iter2 = na_child_iterator(outElem2);
						        (ss2 = na_iterator_next(&iter2)) != NULL;  ) {

                                if(na_child_get_string(ss2,"allowed-capabilities")) {
							        na_elem_t* outElem3 ;
					                na_elem_iter_t	iter3;
					                na_elem_t* ss3;

                                    outElem3 = na_elem_child(ss2, "allowed-capabilities");
                                    for (iter3 = na_child_iterator(outElem3);
						                (ss3 = na_iterator_next(&iter3)) != NULL;  ) {
                                        if(na_child_get_string(ss3,"name")) {
							                printf("    %s\n",na_child_get_string(ss3,"name"));
						                } 
                                    }

						        }
                                if(na_child_get_string(ss2,"comment")) {
							        printf("    %s\n",na_child_get_string(ss2,"comment"));
						        }
                                if(na_child_get_string(ss2,"name")) {
							        printf("    %s\n",na_child_get_string(ss2,"name"));
						        }
                            }
					    }
					}
				    printf("\n");
				}
				printf("----------------------------------------------------\n");				  
            }
        }   
        na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
  

  else
  {
    printUsage();
    return -1;
  }

  return 0;  		
}

//============================================================//



