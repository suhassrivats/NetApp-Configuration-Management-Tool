/*
 * $Id:$
 *
 * StorageService.java
 *
 * Copyright (c) 2010 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to manage storage services and provision storage.
 * Using this sample code, you can create a new storage service with either 
 * Backup or Mirror protection policy, list/delete storage service, provision, 
 * de-provision and re-size storage.
 *
 * This Sample code is supported from DataFabric Manager 4.0 onwards.
 */

import javax.xml.ws.BindingProvider;
import javax.xml.ws.soap.SOAPFaultException;
import java.util.List;
import java.util.Iterator;
import java.math.BigInteger;
import java.util.Map;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.Unmarshaller; 
import javax.xml.bind.JAXBElement;
import org.w3c.dom.Node;
import com.netapp.management.v1.*;

/**
 * This class is used to manage storage services and provision storage. 
 */
public class StorageService {

    /**
     * Interface to the DFM server
     */
    private static DfmInterface dfmInterface;

    /**
     * The default port number for the DFM server (over HTTP).
     */
    private static final int DEFAULT_DFM_PORT = 8088;

    /**
     * Prints various options available for storage service.
     */
    public static void printUsageAndExit() {
        System.out.println("\n Usage:\n" +
        " StorageService <dfm-server> <user> <passwd> list [<srv-name>] \n" +
        " StorageService <dfm-server> <user> <passwd> create <srv-name> <prot-pol> <pri-prov-pol> " +
                        "<pri-rpool> <sec-prov-pol> <sec-rpool> \n" +
        " StorageService <dfm-server> <user> <passwd> provision <srv-name> <stg-name> <size> \n" +
        " StorageService <dfm-server> <user> <passwd> re-size <ds-name> <member-name> <new-size> \n" +
        " StorageService <dfm-server> <user> <passwd> de-provision <srv-name> <stg-name> \n" +
        " StorageService <dfm-server> <user> <passwd> delete <srv-name> [-f] \n\n" +
        "  dfm-server    -- Name/IP Address of the DFM Server \n"  +
        "  user          -- DFM Server user name \n" +
        "  password      -- DFM Server password \n" +
        "  srv-name      -- Name of the storage service \n" +
        "  prot-pol      -- Name of the protection policy ('backup' or 'mirror')\n" +
        "  pri-prov-pol  -- Name of the provisioning policy for primary node \n" +
        "  sec-prov-pol  -- Name of the provisioning policy (secondary type) for backup or mirror node \n" +
        "  pri-rpool     -- Name of the resource pool for primary node \n" +
        "  sec-rpool     -- Name of the resource pool for backup or mirror node \n" +
        "  stg-name      -- Name of the storage container \n" +
        "  size          -- Size (in bytes) of the storage container. Minimum size is 20 MB \n" +
        "  ds-name       -- Name of the dataset \n" +
        "  member-name   -- Name of the member in a dataset \n" + 
        "  new-size      -- New size (in bytes) of the storage container. Minimum size is 20 MB \n" +
        "  -f            -- Allows deleting a storage service that is attached to datasets \n\n" +
        " Note: Provision will set the export protocol settings to CIFS. This option will " +
            "only work for policies that support CIFS.\n\n" );
        System.exit(1);
    }

    /**
     * Creates the client proxy that can be used to invoke DFM APIs.
     * @return    Dfm interface
     */
    private static DfmInterface createDfmInterface(String dfmServer, int portno, String dfmUser, String dfmPwd) {
        String url = "http://" + dfmServer + ":" + portno + "/apis/soap/v1";

        // Create a DFMService instance to get the DFM interface and set the 
        // binding properties for authentication.
        DfmService ss = new DfmService();
        DfmInterface dfmInterface = ss.getDfmPort();

        BindingProvider provider = (BindingProvider) dfmInterface;
        Map<String, Object> reqContext = provider.getRequestContext();
        reqContext.put(BindingProvider.USERNAME_PROPERTY, dfmUser);
        reqContext.put(BindingProvider.PASSWORD_PROPERTY, dfmPwd);
        reqContext.put(BindingProvider.ENDPOINT_ADDRESS_PROPERTY, url);
        return dfmInterface;
    }

    /**
     * Entry point for storage service.
     */
    public static void main(String args[]) {

        // Check for valid no. of arguments
        if ( args.length < 4) {
            printUsageAndExit();
        }

        try {
            String server = args[0];
            String user = args[1];
            String passwd = args[2];

            // create a DFM interface
            dfmInterface = createDfmInterface(server, DEFAULT_DFM_PORT, user, passwd);

            // Parse the command-line arguments
            if (args[3].equals("create") && args.length >= 10) {
                String srvName = args[4];
                String protPolicy = "Back up";
                String priProvPolicy = args[6];
                String priRpool = args[7];
                String secProvPolicy = args[8];
                String secRpool = args[9];

                if (!(args[5].equalsIgnoreCase("Backup") || args[5].equalsIgnoreCase("Mirror"))) {
                    System.out.println("Invalid protection policy!");
                    printUsageAndExit();
                }
                if (args[5].equalsIgnoreCase("Mirror")) {
                    protPolicy = "Mirror";
                }
                createService(srvName, protPolicy, priProvPolicy, priRpool, 
                secProvPolicy, secRpool);
            }
            else if (args[3].equals("list")) {
                String srvName = null;

                if (args.length > 4) {
                    srvName = args[4];
                }
                listService(srvName);
            }
            else if (args[3].equals("delete") && args.length >= 5) {
                String srvName = args[4];
                boolean force = false;

                if (args.length > 5 && args[5].equals("-f")) {
                    force = true;
                }
                deleteService(srvName, force);
            }
            else if (args[3].equals("provision") && args.length >= 7) {
                String srvName = args[4];
                String provName = args[5];
                long size = Long.parseLong(args[6]);
                provisionStorage(srvName, provName, size);
            }
            else if(args[3].equals("de-provision") && args.length >= 6) {
                String srvName = args[4];
                String provName = args[5];
                deProvisionStorage(srvName, provName);
            }
            else if(args[3].equals("re-size") && args.length >= 7) {
                String dsName = args[4];
                String memberName = args[5];
                long size = Long.parseLong(args[6]);
                resizeStorage(dsName, memberName, size);
            }
            else {
                printUsageAndExit();
            }
        }
        catch (SOAPFaultException se) {
            FaultDetail fd = getFaultDetail(se);
            System.out.println("Error:");
            System.out.println(" Name   : " + fd.getOperationError().getName());
            System.out.println(" Reason : " + fd.getReason());
        }
        catch (Exception e) {
            System.err.println(e.toString());
            e.printStackTrace();
        }
    }

    /**
     * Creates a new storage service.
     * @param     srvName           Name of the new storage service. 
     * @param     protPolicy        Name of the protection policy. 
     * @param     priProvPolicy     Provisioning policy name for primary node.
     * @param     priRpool          Resource pool name for primary node.
     * @param     secProvPolicy     Provisioning policy name for secondary node.
     * @param     secRpool          Resource pool name for secondary node.
     */
    public static void createService(String srvName, String protPolicy, 
        String priProvPolicy, String priRpool, String secProvPolicy, String secRpool) 
                throws SOAPFaultException {
        // Create StorageServiceCreate instance and set the service name, 
        // and protection policy information.
        StorageServiceCreate serviceCreate = new StorageServiceCreate();
        serviceCreate.setStorageServiceName(srvName);
        serviceCreate.setProtectionPolicyNameOrId(protPolicy);

        // Create NodeAttributes array for setting up primary and 
        // secondary policy node attributes
        ArrayOfStorageServiceNodeAttributes arrayOfnodeAttributes = new ArrayOfStorageServiceNodeAttributes();
        serviceCreate.setStorageServiceNodeList(arrayOfnodeAttributes);
        List<StorageServiceNodeAttributes> nodeAttributesList = arrayOfnodeAttributes.getStorageServiceNodeAttributes();

        // Create primary node attribute to set primary Dp node name, 
        // prov policy and resource pools.
        StorageServiceNodeAttributes priNodeAttrs = new StorageServiceNodeAttributes();
        priNodeAttrs.setProvisioningPolicyNameOrId(priProvPolicy);

        // Get the Primary node name for the given protection policy. 
        // By default the Primary node name will be 'Primary data'. You can 
        // ignore calling this method if you already know the primary node name.
        String priNodeName = getDpPrimaryNodeName(protPolicy);
        if (priNodeName != null) {
            priNodeAttrs.setDpNodeName(priNodeName); 
        }
        nodeAttributesList.add(priNodeAttrs);
        ArrayOfResourcepoolNameOrId arrayOfPrimaryResourcepool = new ArrayOfResourcepoolNameOrId();
        arrayOfPrimaryResourcepool.getResourcepoolNameOrId().add(priRpool);
        priNodeAttrs.setResourcepools(arrayOfPrimaryResourcepool);

        // Create secondary node attribute to set secondary DP node name, 
        // prov policy and resource pools.
        StorageServiceNodeAttributes secNodeAttrs = new StorageServiceNodeAttributes();
        secNodeAttrs.setProvisioningPolicyNameOrId(secProvPolicy);
        // Set the secondary Node name for the given protection policy. 
        // By default Secondary node name will be 'Backup' for 'Back up' 
        // protection policy and 'Mirror' for  'Mirror' protection policy.
        if (protPolicy.equals("Back up")) {
            secNodeAttrs.setDpNodeName("Backup");
        }
        else {
            secNodeAttrs.setDpNodeName("Mirror");
        }
        nodeAttributesList.add(secNodeAttrs);
        ArrayOfResourcepoolNameOrId arrayOfSecondaryResourcepool = new ArrayOfResourcepoolNameOrId();
        arrayOfSecondaryResourcepool.getResourcepoolNameOrId().add(secRpool);
        secNodeAttrs.setResourcepools(arrayOfSecondaryResourcepool);

        // Invoke storageServiceCreate API. The API will return a CreateResult 
        // structure which contains the Id of the new storage service.
        StorageServiceCreateResult serviceCreateResult = dfmInterface.storageServiceCreate(serviceCreate);
        System.out.println("Storage Service created with Id: " + serviceCreateResult.getStorageServiceId());
    }

    /**
     * Deletes a specified storage service.
     * @param    srvName         Name of the storage service to destroy.
     * @param    forceDestroy    Flag to force destroy a service. 
     *           If forceDestroy is true, it destroys a storage Service that is 
     *           attached to Datasets. By default, only storage services that 
     *           are not associated with any Datasets can be destroyed. 
     */
    public static void deleteService(String srvName, boolean forceDestroy) throws SOAPFaultException {
        // Create StorageServiceDestroy instance and set the service name
        StorageServiceDestroy ssDestroy = new StorageServiceDestroy();
        ssDestroy.setStorageServiceNameOrId(srvName);
        ssDestroy.setForce(forceDestroy);

        // Invoke storageServiceDestroy API
        dfmInterface.storageServiceDestroy(ssDestroy);
        System.out.println("\n Storage service deletion successful!");
    }

    /**
     * Lists information about a specified storage service.
     * @param    srvName        Name of the storage service. 
     *                          If this is null, then this method will list 
     *                          info about all the storage services.
     */
    public static void listService(String srvName) throws SOAPFaultException {
        // Create StorageServiceListInfoIterStart instance to start iteration 
        // of services
        StorageServiceListInfoIterStart ssIterStart = new StorageServiceListInfoIterStart();

        ssIterStart.setObjectNameOrId(srvName);

        // Invoke storageServiceListInfoIterStart API. The API will return a 
        // IterStartResult structure which contain tag and record values
        // and extract the tag and record values returned in IterStartResult
        StorageServiceListInfoIterStartResult ssIterStartResult = dfmInterface.storageServiceListInfoIterStart(ssIterStart);
        BigInteger records = ssIterStartResult.getRecords();
        String tag = ssIterStartResult.getTag();

        // Create StorageServiceListInfoIterEnd instance to end iteration 
        // of services
        StorageServiceListInfoIterEnd ssIterEnd = new StorageServiceListInfoIterEnd();
        ssIterEnd.setTag(tag);

        if (records.longValue() == 0) {
            System.out.println("No storage services to list\n");
            // End the service iteration
            dfmInterface.storageServiceListInfoIterEnd(ssIterEnd);
            return;
        }

        // Create StorageServiceListInfoIterNext instance and set max no. of 
        // records to return.
        StorageServiceListInfoIterNext ssIterNext = new StorageServiceListInfoIterNext();
        ssIterNext.setMaximum(records);
        ssIterNext.setTag(tag);

        // Invoke storageServiceListInfoIterNext API. The API will return a 
        // IterNextResult structure which contain service records.
        StorageServiceListInfoIterNextResult ssIterNextResult = dfmInterface.storageServiceListInfoIterNext(ssIterNext);
        ArrayOfStorageServiceInfo arrayOfSSInfo = ssIterNextResult.getStorageServices();

        List<StorageServiceInfo> ssInfoList = arrayOfSSInfo.getStorageServiceInfo();
        // Iterate through each service
        for (StorageServiceInfo ssInfo : ssInfoList) {
            System.out.println("---------------------------------------------------------------------");
            System.out.println(" Service name      : " + ssInfo.getStorageServiceName());
            if(ssInfo.getProtectionPolicyName() != null) {
                System.out.println(" Protection policy : " + ssInfo.getProtectionPolicyName());
            }

            // Get the information about storage service nodes.
            ArrayOfStorageServiceNodeInfo arrayOfSSNodeInfo = ssInfo.getStorageServiceNodes();
            if (arrayOfSSNodeInfo != null) {
                System.out.println("\n Node Info: ");
                List<StorageServiceNodeInfo> ssNodeInfoList = arrayOfSSNodeInfo.getStorageServiceNodeInfo();
                // Iterate through each node in the service
                for (StorageServiceNodeInfo ssNodeInfo : ssNodeInfoList) {
                    System.out.println("\t Node name       : " + ssNodeInfo.getDpNodeName());
                    if (ssNodeInfo.getProvisioningPolicyName() != null) {
                       System.out.println("\t Prov Pol name   : " + ssNodeInfo.getProvisioningPolicyName());
                    }   
                    ArrayOfResourcepoolInfo arrayOfRpInfo = ssNodeInfo.getResourcepools();
                    if (arrayOfRpInfo == null) {
                        continue;
                    }
                    System.out.print("\t Resource pools  : ");
                    List<ResourcepoolInfo> rpInfoList = arrayOfRpInfo.getResourcepoolInfo();
                    for (ResourcepoolInfo rpInfo : rpInfoList) {
                        System.out.print(rpInfo.getResourcepoolName() + "  ");
                    }
                    System.out.println("\n");
                }
            }
            // Get the list of Datasets attached to the storage service.
            ArrayOfDatasetReference  arrayOfDsReference = ssInfo.getDatasets();
            if (arrayOfDsReference != null) {
                System.out.println(" Datasets: ");
                List<DatasetReference> dsReferenceList = arrayOfDsReference.getDatasetReference();
                // Iterate through each dataset in the service
                for (DatasetReference dsReference : dsReferenceList) {
                    System.out.println("\t" + dsReference.getDatasetName());
                }
            }
        }
        System.out.println("---------------------------------------------------------------------");
        // End the service iteration
        dfmInterface.storageServiceListInfoIterEnd(ssIterEnd);
    }

    /**
     * Provisions storage with given size and sets the export protocol settings to CIFS.
     * @param     serviceName           Name of the service. 
     * @param     stgName               Name of the storage container.
     * @param     size                  Size in bytes to provision.
     */
    public static void provisionStorage(String srvName, String stgName, long size) throws SOAPFaultException {

        // Creates dataset with name: <service-name> + _ + <storage-container>
        String dsName = srvName + "_" + stgName;

        // Create StorageServiceDatasetProvision request and set 
        // provision attributes
        StorageServiceDatasetProvision datasetProvision = new StorageServiceDatasetProvision();
        datasetProvision.setDatasetName(dsName);
        datasetProvision.setStorageServiceNameOrId(srvName);
        WrapperOfProvisionMemberRequestInfo wrapperOfMemberRequestInfo = new WrapperOfProvisionMemberRequestInfo();
        datasetProvision.setProvisionMember(wrapperOfMemberRequestInfo);
        ProvisionMemberRequestInfo memberRequestInfo = new ProvisionMemberRequestInfo();
        wrapperOfMemberRequestInfo.setProvisionMemberRequestInfo(memberRequestInfo);
        memberRequestInfo.setName(stgName);
        memberRequestInfo.setSize(size);
        //memberRequestInfo.setMaximumDataSize(2*size);
        ArrayOfStorageSetInfo arrayOfSSInfo = new ArrayOfStorageSetInfo();
        StorageSetInfo ssInfo = new StorageSetInfo();
        arrayOfSSInfo.getStorageSetInfo().add(ssInfo);
        // Set the dataset export protocol settings to CIFS for everyone with 
        // full control.
        DatasetExportInfo dsExpInfo = new DatasetExportInfo();
        dsExpInfo.setDatasetExportProtocol("CIFS");
        DatasetCifsExportSetting dsCifsExpSettings = new DatasetCifsExportSetting();
        ArrayOfDatasetCifsSharePermission arrayOfDsCifsPermission = new ArrayOfDatasetCifsSharePermission();
        DatasetCifsSharePermission dsCifsPermission = new DatasetCifsSharePermission();
        dsCifsPermission.setCifsUsername("everyone");
        dsCifsPermission.setPermission("full_control");
        arrayOfDsCifsPermission.getDatasetCifsSharePermission().add(dsCifsPermission);
        dsCifsExpSettings.setDatasetCifsSharePermissions(arrayOfDsCifsPermission);
        dsExpInfo.setDatasetCifsExportSetting(dsCifsExpSettings);
        ssInfo.setDatasetExportInfo(dsExpInfo);
        // Set the primary node name for protection policy.
        // Note: Ignore calling thie method if you already know the primary node name.
        String priNodeName = getServicePrimaryNodeName(srvName);
        ssInfo.setDpNodeName(priNodeName);
        datasetProvision.setStorageSetDetails(arrayOfSSInfo);
        // Invoke storageServiceDatasetProvision API. The API will return 
        // ProvisionResult structure which contain the dataset Id of the newly 
        // provisioned Dataset.
        StorageServiceDatasetProvisionResult datasetProvisionResult = dfmInterface.storageServiceDatasetProvision(datasetProvision);
        System.out.println("\nDataset: " + dsName + " created with Id: " + datasetProvisionResult.getDatasetId());
        getDatasetExportSettingsInfo(dsName);
      }

    /**
     * De-provisions a specified storage container.
     * @param     srvName              Name of the storge service. 
     * @param    stgName               Name  of the storage container.
     */
    public static void deProvisionStorage(String srvName, String stgName) throws SOAPFaultException {
        // Destroy the datset that is created in provision request.
        // dataset name: <service-name> + _ + <storage-container>
        String dsName = srvName + "_" + stgName;

        DatasetDestroy dsDestroy = new DatasetDestroy();
        dsDestroy.setDatasetNameOrId(dsName);
        dsDestroy.setForce(true);
        dfmInterface.datasetDestroy(dsDestroy);
        System.out.println("De-provision successful!");
     }

    /**
     * Resizes a specified storage member in a dataset.
     * For resize, you need to know the dataset member on which you provisioned.
     * @param     dsName              Name of the dataset. 
     * @param     memberName          Name of the member to re-size.
     * @param     size                New size in bytes to re-size.
     */
    public static void resizeStorage(String dsName, String memberName, long size) {
        int lockId = 0;
        int jobId = 0;
        try {
            DatasetEditBegin dsEditBegin = new DatasetEditBegin();
            dsEditBegin.setDatasetNameOrId(dsName);
            DatasetEditBeginResult dsEditBeginResult = dfmInterface.datasetEditBegin(dsEditBegin);
            lockId = dsEditBeginResult.getEditLockId();
            DatasetResizeMember dsResizeMember = new DatasetResizeMember();
            dsResizeMember.setEditLockId(lockId);
            ResizeMemberRequestInfo resizeMemberRequestInfo = new ResizeMemberRequestInfo();
            dsResizeMember.setResizeMemberRequestInfo(resizeMemberRequestInfo);
            resizeMemberRequestInfo.setMemberName(memberName);
            resizeMemberRequestInfo.setNewSize(size);
            dfmInterface.datasetResizeMember(dsResizeMember);
            DatasetEditCommit dsEditCommit = new DatasetEditCommit();
            dsEditCommit.setEditLockId(lockId);
            DatasetEditCommitResult dsEditCommitResult = dfmInterface.datasetEditCommit(dsEditCommit);
            jobId = dsEditCommitResult.getJobIds().getJobInfo().get(0).getJobId().intValue();
            // Track the job status for resize
             System.out.print("Re-sizing.. \n Tracking JobId: " + jobId);
            trackJob(jobId);
        }
        catch(Exception e) {
            System.err.println("ERROR:" + e.toString());
            if (lockId != 0) {
                DatasetEditRollback dsEditRollback = new DatasetEditRollback();
                dsEditRollback.setEditLockId(lockId);
                dfmInterface.datasetEditRollback(dsEditRollback);
            }
        }
    }

    /**
     * Tracks the status of the given Job. 
     * @param     jobId                Id of the Job.
     */
    public static void trackJob(Integer jobId)  throws SOAPFaultException {
        String jobStatus = "running";
        try {
            System.out.print(" Status: " + jobStatus);
            // Continiously poll to see if the job has completed
            while (jobStatus.equals("queued") || jobStatus.equals("running") || jobStatus.equals("aborting")) {
                DpJobListIterStart jobListIterStart = new DpJobListIterStart();
                jobListIterStart.setJobId(jobId);
                DpJobListIterStartResult jobListIterStartResult = dfmInterface.dpJobListIterStart(jobListIterStart);
                DpJobListIterNext jobListIterNext = new DpJobListIterNext();
                jobListIterNext.setMaximum(jobListIterStartResult.getRecords());
                jobListIterNext.setTag(jobListIterStartResult.getTag());
                DpJobListIterNextResult jobListIterNextResult = dfmInterface.dpJobListIterNext(jobListIterNext);
                ArrayOfDpJobInfo arrayOfJobInfo = jobListIterNextResult.getJobs();
                DpJobInfo jobInfo = arrayOfJobInfo.getDpJobInfo().get(0);
                jobStatus = jobInfo.getJobState();
                if (jobStatus.equals("completed") || jobStatus.equals("aborted")) {
                    System.out.println("\nOverall Status: " + jobInfo.getJobOverallStatus());
                }
                else {
                    Thread.sleep(3000); System.out.print(".");
                }
                DpJobListIterEnd jobListIterEnd = new DpJobListIterEnd();
                jobListIterEnd.setTag(jobListIterStartResult.getTag());
                dfmInterface.dpJobListIterEnd(jobListIterEnd);
            }
        } catch (Exception e) {
            System.err.println("ERROR:" + e.toString());
            System.exit(1);
        }
    }

    /**
     * Returns FaultDetail for the given SOAPFaultException.
     * FaultDetail provides error code, name and reason for failure. 
     * This method can be used to check for specific error code/name.
     * @param    se        SOAPFaultException from which the fault details are retrieved.
     * @return  FaultDetail containing error reason and information.
     */
    public static FaultDetail getFaultDetail(SOAPFaultException se) {
        // Construct FaultDetail object which we return incase if we 
        // fail to unmarshall SoapFault entries into FaultDetail.
        FaultDetail faultDetail = new FaultDetail();
        faultDetail.setReason(se.getFault().getFaultString());
        faultDetail.setOperationError(new OperationError());
        faultDetail.getOperationError().setName("");
        try {
            // Get the SoapFault detail entries and extract our FaultDetail
            Iterator<?> detailEntriesIter = se.getFault().getDetail().getDetailEntries();
            if (detailEntriesIter.hasNext()) {
                Node detailEntryNode = (Node)detailEntriesIter.next();
                JAXBContext context = JAXBContext.newInstance(FaultDetail.class);
                Unmarshaller unmarshaller = context.createUnmarshaller();
                JAXBElement<FaultDetail> faultDetailElem = unmarshaller.unmarshal(detailEntryNode,FaultDetail.class);
                return faultDetailElem.getValue();
            }
            else {
                return faultDetail;
            }
        }
        catch (Exception e) {
            return faultDetail;
        }
    }

    /**
     * Returns the primary node name for the given storage service.
     * @param    srvName        Name of the storage service
     * @return   Name of the primary node.
     */
    public static String getServicePrimaryNodeName(String srvName) throws SOAPFaultException {
        String policyName = null;
        String priNodeName = null;

        // Create StorageServiceListInfoIterStart instance to start iteration 
        // of services
        StorageServiceListInfoIterStart ssIterStart = new StorageServiceListInfoIterStart();
        ssIterStart.setObjectNameOrId(srvName);

        // Invoke storageServiceListInfoIterStart API. The API will return a 
        // IterStartResult structure which contain tag and record values
        // and extract the tag and record values returned in IterStartResult
        StorageServiceListInfoIterStartResult ssIterStartResult = dfmInterface.storageServiceListInfoIterStart(ssIterStart);
        BigInteger records = ssIterStartResult.getRecords();
        String tag = ssIterStartResult.getTag();

        // Create StorageServiceListInfoIterEnd instance to end iteration 
        // of services
        StorageServiceListInfoIterEnd ssIterEnd = new StorageServiceListInfoIterEnd();
        ssIterEnd.setTag(tag);

        if (records.longValue() == 0) {
            // End the service iteration
            dfmInterface.storageServiceListInfoIterEnd(ssIterEnd);
            return priNodeName;
        }

        // Create StorageServiceListInfoIterNext instance and set max no. of 
        // records to return.
        StorageServiceListInfoIterNext ssIterNext = new StorageServiceListInfoIterNext();
        ssIterNext.setMaximum(records);
        ssIterNext.setTag(tag);

        // Invoke storageServiceListInfoIterNext API. The API will return a 
        // IterNextResult structure which contain prot policy name.
        StorageServiceListInfoIterNextResult ssIterNextResult = dfmInterface.storageServiceListInfoIterNext(ssIterNext);
        ArrayOfStorageServiceInfo arrayOfSSInfo = ssIterNextResult.getStorageServices();

        List<StorageServiceInfo> ssInfoList = arrayOfSSInfo.getStorageServiceInfo();
        // Iterate through the service
        for (StorageServiceInfo ssInfo : ssInfoList) {
            policyName = ssInfo.getProtectionPolicyName();
        }
        // End the service iteration
        dfmInterface.storageServiceListInfoIterEnd(ssIterEnd);
        priNodeName = getDpPrimaryNodeName(policyName);
        return priNodeName;
    }

    /**
     * Returns primary node name for the given protection policy.
     * @param    policyName        Name of the protection policy.
     * @return   primary node name.
     */
    public static String getDpPrimaryNodeName(String policyName) throws SOAPFaultException {
        String priNodeName = null;

        if(policyName == null) {
            return priNodeName;
        }
        // Create DpPolicyListIterStart instance to start iteration of policies
        DpPolicyListIterStart policyIterStart = new DpPolicyListIterStart();
        policyIterStart.setDpPolicyNameOrId(policyName);

        // Invoke dpPolicyListIterStart API. The API will return a 
        // IterStartResult structure which contain tag and record values.
        DpPolicyListIterStartResult policyIterStartResult = dfmInterface.dpPolicyListIterStart(policyIterStart);

        String tag = policyIterStartResult.getTag();
        int polRecords = policyIterStartResult.getRecords();

        // Create DpPolicyListIterEnd instance to end iteration of policies
        DpPolicyListIterEnd  policyIterEnd = new DpPolicyListIterEnd();
        policyIterEnd.setTag(tag);

        if (polRecords == 0) {
            // End the policy iteration
            dfmInterface.dpPolicyListIterEnd(policyIterEnd);
            return priNodeName;
        }
        // Create DpPolicyListIterNext instance and set max no. of records 
        // to return
        DpPolicyListIterNext policyIterNext = new DpPolicyListIterNext();
        policyIterNext.setMaximum(polRecords);
        policyIterNext.setTag(tag);

        // Invoke dpPolicyListIterNext API. The API will return a 
        // IterNextResult record which contain policy records. 
        DpPolicyListIterNextResult policyIterNextResult = dfmInterface.dpPolicyListIterNext(policyIterNext);

        ArrayOfDpPolicyInfo arrayOfPolicyInfo = policyIterNextResult.getDpPolicyInfos();
        List<DpPolicyInfo> policyListInfo = arrayOfPolicyInfo.getDpPolicyInfo();

        for (DpPolicyInfo info : policyListInfo) {
            String policyType;
            DpPolicyContent content = info.getDpPolicyContent();
            ArrayOfDpPolicyNodeInfo arrayOfNodeInfo = content.getDpPolicyNodes();
            if (arrayOfNodeInfo == null) {
                continue;
            }
            List<DpPolicyNodeInfo> nodeListInfo = arrayOfNodeInfo.getDpPolicyNodeInfo();
            for (DpPolicyNodeInfo nodeInfo : nodeListInfo) {
                // Check for the primary node (node id = 1)
                if (nodeInfo.getId() == 1) {
                    priNodeName = nodeInfo.getName();
                    break;
                }
            }
        }
        // End the policy iteration
        dfmInterface.dpPolicyListIterEnd(policyIterEnd);
        return priNodeName;
    }
  
    /**
     * Gets the export settings for storage members that is provisioned into the dataset.
     * @param    dsName        Name of the dataset.
     */  
    public static void getDatasetExportSettingsInfo(String dsName) throws SOAPFaultException {

        // Frame the datasetMemberListInfoIterStart info API to return the 
        // storage information
        DatasetMemberListInfoIterStart dsMemberIterStart = new DatasetMemberListInfoIterStart();
        dsMemberIterStart.setDatasetNameOrId(dsName);
        dsMemberIterStart.setIncludeExportsInfo(true);
        dsMemberIterStart.setIncludeIsAvailable(true);
        dsMemberIterStart.setIncludeIndirect(true);
        //dsMemberIterStart.setSuppressStatusRefresh(true);
        
        // Invoke datasetMemberListInfoIterStart API request
        DatasetMemberListInfoIterStartResult dsMemberIterStartResult = dfmInterface.datasetMemberListInfoIterStart(dsMemberIterStart);

        BigInteger memberRecords = dsMemberIterStartResult.getRecords();
        String memberTag = dsMemberIterStartResult.getTag();
        DatasetMemberListInfoIterNext dsMemberIterNext = new DatasetMemberListInfoIterNext();
        dsMemberIterNext.setMaximum(memberRecords);
        dsMemberIterNext.setTag(memberTag);

        DatasetMemberListInfoIterNextResult dsMemberIterNextResult = dfmInterface.datasetMemberListInfoIterNext(dsMemberIterNext);
        ArrayOfDatasetMemberInfo arrayOfDsMemberInfo = dsMemberIterNextResult.getDatasetMembers();

        // Get the list of dataset members 
        List<DatasetMemberInfo> dsMemberList = arrayOfDsMemberInfo.getDatasetMemberInfo();

        // Iterate through each dataset member
        for (Iterator<DatasetMemberInfo> dsMemIter = dsMemberList.iterator(); 
            dsMemIter.hasNext(); ) {
            DatasetMemberInfo dsMemberInfo = dsMemIter.next();
            String memberName = dsMemberInfo.getMemberName();
            //System.out.println(memberName);
            if (dsMemberInfo.getCifsShareNames() != null) {
                List<String>  cifsShareNameList = dsMemberInfo.getCifsShareNames().getCifsShareName();
                for (String cifsShareName : cifsShareNameList) {
                    System.out.println("Physical resource:" + memberName);
                    System.out.println("Export path:" + cifsShareName + "\n");
                }
           }
            if (dsMemberInfo.getNfsExportName() != null) {
                System.out.println("Physical resource:" + memberName);
                System.out.println("Export path:" + dsMemberInfo.getNfsExportName() + "\n");
            }
        }
        DatasetMemberListInfoIterEnd dsMemberIterEnd = new DatasetMemberListInfoIterEnd();
        dsMemberIterEnd.setTag(memberTag);
        dfmInterface.datasetMemberListInfoIterEnd(dsMemberIterEnd);
     }
}

