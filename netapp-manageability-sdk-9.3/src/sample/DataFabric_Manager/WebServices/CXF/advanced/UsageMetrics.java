/*
 * $Id:$
 *
 * UsageMetrics.java
 *
 * Copyright (c) 2010 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to compute space and/or I/O usage metrics 
 * for a dataset and how to retrieve the computed space or I/O metrics  
 * using webservice APIs.
 *
 * This Sample code is supported from DataFabric Manager 5.0 onwards.
 */

import javax.xml.ws.BindingProvider;
import javax.xml.ws.soap.SOAPFaultException;
import java.util.List;
import java.util.Iterator;
import java.util.Date;
import java.util.Map;
import java.text.SimpleDateFormat;
import java.math.BigInteger;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.Unmarshaller; 
import javax.xml.bind.JAXBElement;
import org.w3c.dom.Node;
import com.netapp.management.v1.*;

/**
 * This class is used to compute and retrieve space and I/O usage metrics. 
 */
public class UsageMetrics {

    /**
     * Interface to the DFM server
     */
    private static DfmInterface dfmInterface;

    /**
     * The default port number for the DFM server (over HTTP).
     */
    private static final int DEFAULT_DFM_PORT = 8088;

    /**
     * Prints various options available for UsageMetrics.
     */
    public static void printUsageAndExit() {
        System.out.println("\n Usage:\n" +
        " UsageMetrics <dfm-server> <user> <passwd> compute <ds-name> <timestamp> [-s] [-i] \n" +
        " UsageMetrics <dfm-server> <user> <passwd> list [-n <ds-name>] <-s | -i> [-d <day>] [-m <month>] [-y <year>] \n\n" +
        "  dfm-server    -- Name/IP Address of the DFM Server \n"  +
        "  user          -- DFM Server user name \n" +
        "  password      -- DFM Server password \n" +
        "  timestamp     -- Time (seconds since 1/1/1970 in UTC) upto which usage metrics for the dataset needs to be computed. Range: [1..2^31-1] \n" +
        "  ds-name       -- Name or ID the dataset \n" +
        "  -n            -- Flag to specify the name of the dataset \n" +
        "  -s            -- Flag to compute or list space usage metrics \n" +
        "  -i            -- Flag to compute or list I/O usage metrics \n" +
        "  day           -- The day for which the usage metric is required. Range: [1..31] \n" + 
        "  month         -- The month for which the usage metric is required. Range: [1..12] \n" + 
        "  year          -- The year for which the usage metric is required. Range: [1900..2^31-1] \n\n" +
        " Note: compute command computes space or IO usage metrics for a dataset. Use the list command to retrieve the \n" + 
        "       computed space or IO usage metrics. \n");
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
        if ( args.length < 5) {
            printUsageAndExit();
        }

        try {
            String server = args[0];
            String user = args[1];
            String passwd = args[2];
            String command = args[3];
            String dsName = null;
            BigInteger timestamp = null;
            boolean useSpaceMetrics = false;
            boolean useIoMetrics = false;
            Integer day = null;
            String month = null;
            Integer year = null;

            // create a DFM interface
            dfmInterface = createDfmInterface(server, DEFAULT_DFM_PORT, user, passwd);

            // Parse the command-line arguments
            if (command.equals("compute")) {
                if (args.length < 6) {
                    printUsageAndExit();
                }
                dsName = args[4];
                timestamp = new BigInteger(args[5]);
                for (int i = 6; i < args.length; i++) {
                    if (args[i].equals("-s")) {
                        useSpaceMetrics = true;
                    }
                    else if (args[i].equals("-i")){
                        useIoMetrics = true;
                    }
                    else {
                        printUsageAndExit();
                    }
                }
                computeDatasetUsageMetrics(dsName, timestamp, useSpaceMetrics, useIoMetrics);
            }
            else if (command.equals("list")) {
                int index = 4;
                if (args[index].equals("-n")) {
                    dsName = args[index + 1];
                    index = index + 2;
                }
                if (index < args.length && args[index].equals("-s")) {
                        useSpaceMetrics = true;
                        index++;
                }
                else if (index < args.length && args[index].equals("-i")) {
                    useIoMetrics = true;
                    index++;
                }
                else {
                    printUsageAndExit();
                }
                for(int i = index; i < args.length; i++){
                    if (args[i].equals("-d")) {
                        day = new Integer(args[++i]);
                    }
                    else if (args[i].equals("-m")) {
                        month = args[++i];
                    }
                    else if (args[i].equals("-y")) {
                        year = new Integer(args[++i]);
                    }
                    else {
                        printUsageAndExit();
                    }
                }
                
                if (useSpaceMetrics) {
                    listDatasetSpaceUsageMetrics(dsName, day, month, year);
                }
                else {
                    listDatasetIoUsageMetrics(dsName, day, month, year);
                }
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
        catch (NumberFormatException nfe) {
            System.err.println("Invalid parameter value: " + nfe.toString());
            nfe.printStackTrace();
        }
        catch (Exception e) {
            System.err.println(e.toString());
            e.printStackTrace();
        }
    }

    /**
     * Computes dataset space and/or I/O usage metrics.
     * @param     dsName           Name or ID of the dataset.
     * @param     timestamp        Time (in seconds) upto which usage metrics 
     *                             for the dataset needs to be computed.
     * @param     useSpaceMetrics  Flag to compute space usage metrics.
     * @param     useIOMetrics     Flag to compute I/O usage metrics.
     */
    public static void computeDatasetUsageMetrics(String dsName, BigInteger timestamp, 
        boolean useSpaceMetrics, boolean useIOMetrics) throws SOAPFaultException {
        // Create DatasetComputeUsageMetric instance and set the dataset name, 
        //  timestamp, space and io metrics flags.
        DatasetComputeUsageMetric dsUsageMetric = new DatasetComputeUsageMetric();
        dsUsageMetric.setDatasetNameOrId(dsName);
        dsUsageMetric.setTimestamp(timestamp);
        dsUsageMetric.setComputeSpaceUsageMetric(useSpaceMetrics);
        dsUsageMetric.setComputeIoUsageMetric(useIOMetrics);

        // Invoke datasetComputeUsageMetric API. 
        dfmInterface.datasetComputeUsageMetric(dsUsageMetric);
        
        System.out.println("Command executed successfully.");
    }

    /**
     * Lists dataset's space usage metrics.
     * @param    dsName          Name or Id of the dataset.
     * @param    day             The day for which the usage metric is required. 
     *           month           The month for which the usage metric is required.
     *           year            The year for which the usage metric is required. 
     */
    public static void listDatasetSpaceUsageMetrics(String dsName, Integer day, String month, Integer year) throws SOAPFaultException {
        // Create DatasetSpaceMetricListInfoIterStart instance and set the dataset name, 
        // day, month and year parameters
        DatasetSpaceMetricListInfoIterStart dsSpaceIterStart  = new DatasetSpaceMetricListInfoIterStart();
        dsSpaceIterStart.setObjectNameOrId(dsName);
        dsSpaceIterStart.setDay(day);
        dsSpaceIterStart.setMonth(month);
        dsSpaceIterStart.setYear(year);

        // Invoke datasetSpaceMetricListInfoIterStart API. This API will return a IterStartResult structure which contain  
        // tag and record values and extract the tag and record values returned in IterStartResult
        DatasetSpaceMetricListInfoIterStartResult dsSpaceIterStartResult = dfmInterface.datasetSpaceMetricListInfoIterStart(dsSpaceIterStart);
        String tag = dsSpaceIterStartResult.getTag();
        int records = dsSpaceIterStartResult.getRecords();
        
        // Create DatasetSpaceMetricListInfoIterEnd instance to end iteration of space metrics
        DatasetSpaceMetricListInfoIterEnd dsSpaceIterEnd = new DatasetSpaceMetricListInfoIterEnd();
        dsSpaceIterEnd.setTag(tag);
        
        if (records == 0) {
            System.out.println("No dataset's space usage measurements to list\n");
            // End the metric iteration
            dfmInterface.datasetSpaceMetricListInfoIterEnd(dsSpaceIterEnd);
            return;
        }
        
        // Create DatasetSpaceMetricListInfoIterNext instance and set the tag and max no. of records to return.
        DatasetSpaceMetricListInfoIterNext dsSpaceIterNext = new DatasetSpaceMetricListInfoIterNext();
        dsSpaceIterNext.setTag(tag);
        dsSpaceIterNext.setMaximum(records);
        
        // Invoke datasetSpaceMetricListInfoIterNext API. The API will return a IterNextResult structure 
        // which contain DatasetSpaceMetric records.
        DatasetSpaceMetricListInfoIterNextResult dsSpaceIterNextResult = dfmInterface.datasetSpaceMetricListInfoIterNext(dsSpaceIterNext);
        ArrayOfDatasetSpaceMetricInfo arrayOfDsSpaceMetricInfo = dsSpaceIterNextResult.getDatasetSpaceMetrics();
        
        if (arrayOfDsSpaceMetricInfo == null) {
            System.out.println("No dataset's space usage measurements to list\n");
            // End the metric iteration
            dfmInterface.datasetSpaceMetricListInfoIterEnd(dsSpaceIterEnd);
            return;
        }
        List<DatasetSpaceMetricInfo> dsSpaceMetricInfoList = arrayOfDsSpaceMetricInfo.getDatasetSpaceMetricInfo();
        // Iterate through each space metric info
        for (DatasetSpaceMetricInfo dsSpaceMetricInfo : dsSpaceMetricInfoList) {
            System.out.println("---------------------------------------------------------------------");
            
            // Extract the information about dataset node.
            WrapperOfMetricDatasetNodeInfo wrapperOfMetricDsnodeInfo = dsSpaceMetricInfo.getDatasetNode();
            MetricDatasetNodeInfo metricDsNodeInfo = wrapperOfMetricDsnodeInfo.getMetricDatasetNodeInfo();
            System.out.println(" Dataset node info                 :");
            printField("  Dataset", metricDsNodeInfo.getDatasetName());
            printField("  DP Node Name", metricDsNodeInfo.getDpNodeName());
            printField("  ProvisioningPolicy", metricDsNodeInfo.getProvisioningPolicyName());
            printField("  ProtectionPolicy", metricDsNodeInfo.getProtectionPolicyName());
            printField("  Storage Service", metricDsNodeInfo.getStorageServiceName());
            System.out.println();
            printField(" Timestamp", 
                     new SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(new Date((dsSpaceMetricInfo.getTimestamp().longValue()) *1000)));
            printField(" Is overcharge", 
                      (dsSpaceMetricInfo.isIsOvercharge() == null)  ? "false" : dsSpaceMetricInfo.isIsOvercharge());
            printField(" Is space data partial", 
                      (dsSpaceMetricInfo.isIsSpaceDataPartial() == null) ? "false" : dsSpaceMetricInfo.isIsSpaceDataPartial());
            System.out.println();

            // Extract the information about average space usage measurement.
            System.out.println(" Average space usage measurements  :");
            WrapperOfSpaceMeasurement  wrapperOfSpaceMeasurement = dsSpaceMetricInfo.getAvgSpaceMeasurement();
            SpaceMeasurement avgSpaceMeasurement = wrapperOfSpaceMeasurement.getSpaceMeasurement();
            printField("  Effective used data space", avgSpaceMeasurement.getEffectiveUsedDataSpace(), "bytes");
            printField("  Guaranteed Space", avgSpaceMeasurement.getGuaranteedSpace(), "bytes");
            printField("  Physical used data space", avgSpaceMeasurement.getPhysicalUsedDataSpace(), "bytes");
            printField("  Snapshot reserve", avgSpaceMeasurement.getSnapshotReserve(), "bytes");
            printField("  Total data space", avgSpaceMeasurement.getTotalDataSpace(), "bytes");
            printField("  Total Space", avgSpaceMeasurement.getTotalSpace(), "bytes");
            printField("  Used snapshot Space", avgSpaceMeasurement.getUsedSnapshotSpace(), "bytes");
            System.out.println();

            // Extract the information about maximum space usage measurement.
            System.out.println(" Maximum space usage measurements  :");
            wrapperOfSpaceMeasurement = dsSpaceMetricInfo.getMaxSpaceMeasurement();
            SpaceMeasurement maxSpaceMeasurement = wrapperOfSpaceMeasurement.getSpaceMeasurement();
            printField("  Effective used data space", maxSpaceMeasurement.getEffectiveUsedDataSpace(), "bytes");
            printField("  Guaranteed Space", maxSpaceMeasurement.getGuaranteedSpace(), "bytes");
            printField("  Physical used data space", maxSpaceMeasurement.getPhysicalUsedDataSpace(), "bytes");
            printField("  Snapshot reserve", maxSpaceMeasurement.getSnapshotReserve(), "bytes");
            printField("  Total data space", maxSpaceMeasurement.getTotalDataSpace(), "bytes");
            printField("  Total Space", maxSpaceMeasurement.getTotalSpace(), "bytes");
            printField("  Used snapshot Space ", maxSpaceMeasurement.getUsedSnapshotSpace(), "bytes");
        }
        System.out.println("---------------------------------------------------------------------");
        // End the space metric iteration
        dfmInterface.datasetSpaceMetricListInfoIterEnd(dsSpaceIterEnd);
    }

    /**
     * Lists dataset's I/O usage metrics.
     * @param    dsName          Name or Id of the dataset.
     * @param    day             The day for which the usage metric is required. 
     *           month           The month for which the usage metric is required.
     *           year            The year for which the usage metric is required. 
     */
    public static void listDatasetIoUsageMetrics(String dsName, Integer day, String month, Integer year) throws SOAPFaultException {
        // Create DatasetIoMetricListInfoIterStart instance and set the dataset name, 
        // day, month and year parameters
        DatasetIoMetricListInfoIterStart dsIoIterStart  = new DatasetIoMetricListInfoIterStart();
        dsIoIterStart.setObjectNameOrId(dsName);
        dsIoIterStart.setDay(day);
        dsIoIterStart.setMonth(month);
        dsIoIterStart.setYear(year);

        // Invoke datasetIoMetricListInfoIterStart API. This API will return a IterStartResult structure which contain  
        // tag and record values and extract the tag and record values returned in IterStartResult
        DatasetIoMetricListInfoIterStartResult dsIoIterStartResult = dfmInterface.datasetIoMetricListInfoIterStart(dsIoIterStart);
        String tag = dsIoIterStartResult.getTag();
        int records = dsIoIterStartResult.getRecords();
        
        // Create DatasetIoMetricListInfoIterEnd instance to end iteration of io metrics
        DatasetIoMetricListInfoIterEnd dsIoIterEnd = new DatasetIoMetricListInfoIterEnd();
        dsIoIterEnd.setTag(tag);
        
        if (records == 0) {
            System.out.println("No dataset's I/O usage measurements to list\n");
            // End the service iteration
            dfmInterface.datasetIoMetricListInfoIterEnd(dsIoIterEnd);
            return;
        }
        
        // Create DatasetIoMetricListInfoIterNext instance and set the tag and max no. of records to return.
        DatasetIoMetricListInfoIterNext dsIoIterNext = new DatasetIoMetricListInfoIterNext();
        dsIoIterNext.setTag(tag);
        dsIoIterNext.setMaximum(records);
        
        // Invoke datasetIoMetricListInfoIterNext API. The API will return a IterNextResult structure 
        // which contain DatasetIoMetric records.
        DatasetIoMetricListInfoIterNextResult dsIoIterNextResult = dfmInterface.datasetIoMetricListInfoIterNext(dsIoIterNext);
        
        ArrayOfDatasetIoMetricInfo arrayOfDsIoMetricInfo = dsIoIterNextResult.getDatasetIoMetrics();
                
        List<DatasetIoMetricInfo> dsIoMetricInfoList = arrayOfDsIoMetricInfo.getDatasetIoMetricInfo();
        // Iterate through each Io Metric record
        for (DatasetIoMetricInfo dsIoMetricInfo : dsIoMetricInfoList) {
            System.out.println("---------------------------------------------------------------------");
            
            // Extract the information about dataset node.
            WrapperOfMetricDatasetNodeInfo wrapperOfMetricDsnodeInfo = dsIoMetricInfo.getDatasetNode();
            MetricDatasetNodeInfo metricDsNodeInfo = wrapperOfMetricDsnodeInfo.getMetricDatasetNodeInfo();
            System.out.println(" Dataset node info                 : ");
            printField("  Dataset", metricDsNodeInfo.getDatasetName());
            printField("  DP Node Name", metricDsNodeInfo.getDpNodeName());
            printField("  ProvisioningPolicy", metricDsNodeInfo.getProvisioningPolicyName());
            printField("  ProtectionPolicy", metricDsNodeInfo.getProtectionPolicyName());
            printField("  Storage Service", metricDsNodeInfo.getStorageServiceName());
            System.out.println();

            printField(" Timestamp", 
                     new SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(new Date((dsIoMetricInfo.getTimestamp().longValue()) *1000)));
            printField(" Is overcharge", (dsIoMetricInfo.isIsOvercharge() == null) ? "false" : dsIoMetricInfo.isIsOvercharge());
            System.out.println();

            // Extract the information about io measurement.
            IoMeasurement ioMeasurement = dsIoMetricInfo.getIoMeasurement();
            System.out.println(" I/O Measurement                   : ");
            printField("  Data read", ioMeasurement.getDataRead(), "bytes");
            printField("  Data written", ioMeasurement.getDataWritten(), "bytes");
        }
        System.out.println("---------------------------------------------------------------------");
        // End the io metric iteration
        dfmInterface.datasetIoMetricListInfoIterEnd(dsIoIterEnd);
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
        // fail to un marshall SoapFault entries into FaultDetail.
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

    public static void printField(String fieldName, Object fieldValue) {
        printField(fieldName, fieldValue, null);
    }
    
    public static void printField(String fieldName, Object fieldValue, String units) {
        System.out.println(String.format(
            "%-35s: %s %s",
            fieldName, 
            fieldValue == null ? "" : fieldValue,
            units == null ? "" : (fieldValue == null ? "" : units)
            ));
    }
}

