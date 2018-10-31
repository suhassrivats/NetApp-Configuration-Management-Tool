This README file explains how to create a multi-tenant and non-multi-tenant, SLA based 
storage provisioning using sample codes provided in the DFM server SDK bundle.  Not all 
capabilities are explored in this workflow, only key actions needed from the sample codes 
has been used to compile below workflow for a multi-tenant, SLA based storage setup for 
a datacenter.

---------------------------------------------------------------------------------
Table of Contents
---------------------------------------------------------------------------------
1. RESOURCE POOL
   1a. Create a primary resource pool - "Primary_pool"
   1b. Create a backup resource pool - "Backup_Pool"
   1c. List resource pools
2. POLICIES
   2a. Provisioning Policy
   2b. Protection Policy
3. MULTISTORE (for Multi-tenant env)
   3a. Create Multistore
4. DATASET
   4a. Create a dataset
   4b. Add protection and provisioning policies.
---------------------------------------------------------------------------------


1. RESOURCE POOL
   1a. Create a primary resource pool - "Primary_pool" and add storage system 
       members.  Add appropriate resource labels to indicate the storage quality 
       or category. For example, add FAS6000 series systems with GOLD label and 
       FAS3000 as SILVER. You can create such classifications based on the disk 
       type, FC or SATA.
	   
       a. Create Resource pool "Primary_Pool"
	       resource_pool.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD create POOL_NAME
		  
	      For e.g:
	       resource_pool.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD create Primary_Pool
	   
       b. Add members (STORAGE_SYSTEM_NAME) into the resouce pool (Primary_Pool) 
	      with resource-labels (GOLD).  Repeat the below step for each member that 
	      you want to add.  Make sure you add appropriate labels.
	   
           resource_pool.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD member add POOL_NAME STORAGE_SYSTEM_NAME RESOURCE_LABEL   
		   
          For e.g:
           resource_pool.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD member add Primary_Pool fas6fc GOLD   
           resource_pool.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD member add Primary_Pool fas3sata SILVER   
		   
		  
    1b. Create a backup resource pool - "Backup_Pool" with similar steps as shown 
	above.  You can opt not to provide resource pool labels 
		
	1c. List resource pools
		
        a. List all resouce pools 
			
           resource_pool.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD list
			
        b. List members in a particular resouce pool
            resource_pool.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD member list POOL_NAME
			
           For e.g:
            resource_pool.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD member list Primary_Pool
			

2. POLICIES
   2a. Provisioning Policy
   
       a. List all provisioning policies
	      
           policy.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD list prov
		  
       b. Create a new provisioning policy with resource labels.  This policy is dedicated 
          to create or provision new storage from a resouce pool with members tagged with
          the same resouce label "GOLD".  Choose a policy type - "nas", "san" or "all".
          Note: the option default is to use default values for quotas and thin provision
          attributes.
	  
           policy.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD create prov POLICY_NAME POLICY_TYPE RESOURCE_LABEL default
		
          For e.g:
           policy.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD create prov my_nas_policy nas GOLD default
		    
	  The policy created will have default settings for "Disk failure protection" and "Space threshold". Make
	  sure the resource pool member are compliant.
		  

   2b. Protection Policy
	    
	a. List all protection policies
	      
	    policy.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD list dp mirror
		   
	   Choose a policy for protection.  In this case let us choose a policy that mirrors data.  
	   Make a note of the protection policy "Mirror" from the output list.  
		
	   Policy Name     : Mirror
	   Connection Type : mirror
	   Source Node     : Primary data
	   To Node         : Mirror
		   
	
3. MULTISTORE 
   3a. Multistores enable creation of a multi-tenant environment on NetApp storage systems.  
       This step is optional if you do not want to create a multi-tenant environment.Create 
       a multistore and attach it to the dataset (shown below) to enable all storage to be 
       provisioned on a particular system and moved under a multistore to enable a secure 
       compartmentalized access to users.  These multistores can be provisioned from the same 
       resouce pool where data resides.  But, if you are looking to setup a multi-tenant 
       environment, provision multistores manually making sure you create multistores on the 
       resource pool members with same resource labels as that of the labels in the 
       provisioning policy.
	   
       a. Create a multistore with NAS (nfs & cifs) protocols enabled.
	   
           multistore.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD create MULTISTORE_NAME IP_ADDRESS PROTOCOL STORAGE_SYSTEM_OR_RPOOL
		  
	      For e.g:
	       multistore.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD create fas6ms1 10.10.10.1 nas fas6fc
		  
	      Options for PROTOCOL - "nas", "san" or "all"
		  
	      Note: Choose the storage system on which you would like to create new multistore based on
	      the resource-labels provided during resource pool creation.  

       b. Setup the Multistore 
	       multistore.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD setup MULTISTORE_NAME INTERFACE IP_ADDRESS NETMASK
		  
	      For e.g:
	       multistore.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD setup fas6ms1 e0a 10.10.10.1 255.255.255.0
		  
		  
4. DATASET
   4a. Create a dataset.  
        dataset.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD create DATASET_NAME MULTISTORE_TO_ATTACH
	   
       For e.g:
        dataset.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD create Oil_Pri_data fas6ms1
	   
   4b. Add protection and provisioning policies.  The resource pool list depends on the policy chosen. 
       This code has been designed to use "Mirror" protection policy which can work with either one or 
       two resource pools.  Below example shows creation of a dataset with mirror protection policy
       attached - RPOOL1 is the source and RPOOL2 will be the destination for the Mirror relationship.
	   
        dataset.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD update DATASET_NAME PROV_POLICY PROT_POLICY RPOOL1 [RPOOL2]
 
       For e.g:
        dataset.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD update Oil_Pri_data my_nas_policy Mirror Primary_Pool Backup_Pool
	   

   4c. With this setup complete, any storage that is provisioned from this dataset will be automatically 
       provisioned and protected.  Provision new storage of size 5GB from the newly created dataset.
	   
        dataset.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD provision DATASET_NAME MEMBER_TO_PROV SIZE 
	   
       For e.g:
        dataset.rb DFM_SERVER DFM_ADMIN DFM_ADMIN_PWD provision Oil_Pri_data Docs_lib 5000000000
	   
	   
	   
