//============================================================//
//                                                            //
//                                                            //
// UsageMetrics.cs                                            //
//                                                            //
// Copyright 2010 NetApp. All rights reserved.                // 
// Specifications subject to change without notice.           // 
//                                                            //
// Sample code to demonstrate how to compute space and/or     // 
// I/O usage metrics for a dataset and how to retrieve the    //
// computed space metrics and I/O metrics using               //
// webservice APIs.                                           //
//                                                            //
// This Sample code is supported from                         //
// DataFabric Manager 5.0 onwards.                            // 
//                                                            //
//============================================================//

using System;
using System.Web.Services.Protocols;
using System.Net;

namespace UsageMetrics
{
    /// <summary>
    /// This class is used to compute and retrieve space and I/O usage metrics.
    /// </summary>
    class UsageMetrics
    {

        /// <summary>
        /// The default HTTP and HTTPS port numbers for the DFM server.
        /// </summary>
        private static readonly int DEFAULT_DFM_HTTP_PORT = 8088;


        /// <summary>
        /// Client interface to the DFM server.
        /// </summary>
        private static DfmService dfmService;

        /// <summary>
        /// This function will print various usage options.
        /// </summary>
        public static void printUsageAndExit() {
            Console.WriteLine("\n Usage:\n" +
            " UsageMetrics <dfm-server> <user> <passwd> compute <ds-name> <timestamp> [-s ] [-i] \n" +
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
            " Note: compute command computes space and/or IO usage metrics for a dataset. Use the list command to retrieve the \n" + 
            "       computed space or IO usage metrics. \n");
            Environment.Exit(1);
        }

        /// <summary>
        /// Creates the client proxy that you can use to invoke DFM APIs.
        /// </summary>
        private static void CreateDfmService(string dfmServer, string dfmUser, string dfmPasswd)
        {
            String protocol = "http";
            int portno = DEFAULT_DFM_HTTP_PORT;

            String url = protocol + "://" + dfmServer + ":" + portno + "/apis/soap/v1";
            ICredentials credentials = new NetworkCredential(dfmUser, dfmPasswd);
            dfmService = new DfmService();
            dfmService.Credentials = credentials;
            dfmService.Url = url;
        }

        /// <summary>
        /// Entry point for UsageMetrics.
        /// </summary>
        public static void Main(string[] args)
        {
            // Check for valid no. of arguments
            if (args.Length < 5)
            {
                printUsageAndExit();
            }
            try
            {
                string server = args[0];
                string user = args[1];
                string passwd = args[2];
                string command = args[3];
                string dsName = null;
                string timestamp = null;
                bool useSpaceMetrics = false;
                bool useIoMetrics = false;
                string day = null;
                string month = null;
                string year = null;

                // create a DFM interface
                CreateDfmService(server, user, passwd);

                // Parse the command-line arguments
                if (command.Equals("compute")) {
                    if (args.Length < 6) {
                        printUsageAndExit();
                    }
                    dsName = args[4];
                    timestamp = args[5];
                    for (int i = 6; i < args.Length; i++) {
                        if (args[i].Equals("-s")) {
                            useSpaceMetrics = true;
                        }
                        else if (args[i].Equals("-i")){
                            useIoMetrics = true;
                        }
                        else {
                            printUsageAndExit();
                        }
                    }
                    ComputeDatasetUsageMetrics(dsName, timestamp, useSpaceMetrics, useIoMetrics);
                }
                else if (command.Equals("list")) {
                    int index = 4;
                    if (args[index].Equals("-n")) {
                        dsName = args[index + 1];
                        index = index + 2;
                    }
                    if (index < args.Length && args[index].Equals("-s")) {
                            useSpaceMetrics = true;
                            index++;
                    }
                    else if (index < args.Length && args[index].Equals("-i")) {
                        useIoMetrics = true;
                        index++;
                    }
                    else {
                        printUsageAndExit();
                    }
                    for(int i = index; i < args.Length; i++){
                        if (args[i].Equals("-d")) {
                            day = args[++i];
                        }
                        else if (args[i].Equals("-m")) {
                            month = args[++i];
                        }
                        else if (args[i].Equals("-y")) {
                            year = args[++i];
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
            catch (Exception e) {
                Console.Error.WriteLine(e.Message);
            }
        }

        /// <summary>
        /// Computes dataset space and/or I/O usage metrics.
        /// </summary>
        /// <param name="dsName">Name or ID of the dataset.</param>
        /// <param name="timestamp">Time (in seconds) up to which usage metrics
        ///  for the dataset needs to be computed.</param>
        /// <param name="useSpaceMetrics">Flag to compute space usage metrics.</param>
        /// <param name="useIOMetrics">Flag to compute I/O usage metrics.</param>
        public static void ComputeDatasetUsageMetrics(String dsName, String timestamp, 
            bool useSpaceMetrics, bool useIOMetrics) 
        {
            try
            {
                // Create DatasetComputeUsageMetric instance and set the dataset name, 
                //  timestamp, space and I/O metrics flags.
                DatasetComputeUsageMetric dsUsageMetric = new DatasetComputeUsageMetric();
                dsUsageMetric.DatasetNameOrId = dsName;
                dsUsageMetric.Timestamp = timestamp;
                dsUsageMetric.ComputeSpaceUsageMetric = useSpaceMetrics;
                dsUsageMetric.ComputeIoUsageMetric = useIOMetrics;

                // Invoke datasetComputeUsageMetric API. 
                dfmService.DatasetComputeUsageMetric(dsUsageMetric);
                
                Console.WriteLine("Command executed successfully.");
            }
            catch (SoapException e)
            {
                Console.Error.WriteLine(e.Message);
            }
        }

        /// <summary>
        /// Lists dataset's space usage metrics.
        /// </summary>
        /// <param name="dsName">Name or Id of the dataset.</param>
        /// <param name="day">The day for which the usage metric is required.</param>
        /// <param name="month">The month for which the usage metric is required.</param>
        /// <param name="year">The year for which the usage metric is required.</param>
        public static void listDatasetSpaceUsageMetrics(string dsName, string day, string month, string year)
        {
            try
            {
            // Create DatasetSpaceMetricListInfoIterStart instance and set the dataset name, 
            // day, month and year parameters
            DatasetSpaceMetricListInfoIterStart dsSpaceIterStart  = new DatasetSpaceMetricListInfoIterStart();
            dsSpaceIterStart.ObjectNameOrId = dsName;
            dsSpaceIterStart.Day = day;
            dsSpaceIterStart.Month = month;
            dsSpaceIterStart.Year = year;

            // Invoke datasetSpaceMetricListInfoIterStart API. This API will return a IterStartResult structure which contain  
            // tag and record values and extract the tag and record values returned in IterStartResult
            DatasetSpaceMetricListInfoIterStartResult dsSpaceIterStartResult = dfmService.DatasetSpaceMetricListInfoIterStart(dsSpaceIterStart);
            string tag = dsSpaceIterStartResult.Tag ;
            string records = dsSpaceIterStartResult.Records;
            
            // Create DatasetSpaceMetricListInfoIterEnd instance to end iteration of space metrics
            DatasetSpaceMetricListInfoIterEnd dsSpaceIterEnd = new DatasetSpaceMetricListInfoIterEnd();
            dsSpaceIterEnd.Tag = tag;

            if (Convert.ToInt32(records) == 0)
            {
                Console.WriteLine("No dataset's space usage measurements to list\n");
                // End the metric iteration
                dfmService.DatasetSpaceMetricListInfoIterEnd(dsSpaceIterEnd);
                return;
            }
            
            // Create DatasetSpaceMetricListInfoIterNext instance and set the tag and max no. of records to return.
            DatasetSpaceMetricListInfoIterNext dsSpaceIterNext = new DatasetSpaceMetricListInfoIterNext();
            dsSpaceIterNext.Tag = tag;
            dsSpaceIterNext.Maximum = records;
            
            // Invoke datasetSpaceMetricListInfoIterNext API. The API will return a IterNextResult structure 
            // which contain DatasetSpaceMetric records.
            DatasetSpaceMetricListInfoIterNextResult dsSpaceIterNextResult = dfmService.DatasetSpaceMetricListInfoIterNext(dsSpaceIterNext);
            DatasetSpaceMetricInfo[] dsSpaceMetricInfoList = dsSpaceIterNextResult.DatasetSpaceMetrics;

            // Iterate through each space metric info
            foreach (DatasetSpaceMetricInfo dsSpaceMetricInfo in dsSpaceMetricInfoList) 
            {
                Console.WriteLine("---------------------------------------------------------------------");
                
                // Extract the information about dataset node.
                WrapperOfMetricDatasetNodeInfo wrapperOfMetricDsnodeInfo = dsSpaceMetricInfo.DatasetNode;
                MetricDatasetNodeInfo metricDsNodeInfo = wrapperOfMetricDsnodeInfo.MetricDatasetNodeInfo;
                Console.WriteLine(" Dataset node info                 :");
                printField("  Dataset", metricDsNodeInfo.DatasetName);
                printField("  DP Node Name", metricDsNodeInfo.DpNodeName);
                printField("  ProvisioningPolicy", metricDsNodeInfo.ProvisioningPolicyName);
                printField("  ProtectionPolicy", metricDsNodeInfo.ProtectionPolicyName);
                printField("  Storage Service", metricDsNodeInfo.StorageServiceName);
                Console.WriteLine();
                DateTime datetime = new DateTime(1970, 1, 1, 0, 0, 0).AddSeconds(
                    Convert.ToDouble(dsSpaceMetricInfo.Timestamp));
                printField(" Timestamp", datetime.ToLocalTime());
                printField(" Is overcharge", dsSpaceMetricInfo.IsOvercharge);
                printField(" Is space data partial", dsSpaceMetricInfo.IsSpaceDataPartial);
                Console.WriteLine();

                // Extract the information about average space usage measurement.
                Console.WriteLine(" Average space usage measurements  :");
                WrapperOfSpaceMeasurement  wrapperOfSpaceMeasurement = dsSpaceMetricInfo.AvgSpaceMeasurement;
                SpaceMeasurement avgSpaceMeasurement = wrapperOfSpaceMeasurement.SpaceMeasurement;
                printField("  Effective used data space", avgSpaceMeasurement.EffectiveUsedDataSpace, "bytes");
                printField("  Guaranteed Space", avgSpaceMeasurement.GuaranteedSpace, "bytes");
                printField("  Physical used data space", avgSpaceMeasurement.PhysicalUsedDataSpace, "bytes");
                printField("  Snapshot reserve", avgSpaceMeasurement.SnapshotReserve, "bytes");
                printField("  Total data space", avgSpaceMeasurement.TotalDataSpace, "bytes");
                printField("  Total Space", avgSpaceMeasurement.TotalSpace, "bytes");
                printField("  Used snapshot Space", avgSpaceMeasurement.UsedSnapshotSpace, "bytes");
                Console.WriteLine();

                // Extract the information about maximum space usage measurement.
                Console.WriteLine(" Maximum space usage measurements  :");
                wrapperOfSpaceMeasurement = dsSpaceMetricInfo.MaxSpaceMeasurement;
                SpaceMeasurement maxSpaceMeasurement = wrapperOfSpaceMeasurement.SpaceMeasurement;
                printField("  Effective used data space", maxSpaceMeasurement.EffectiveUsedDataSpace, "bytes");
                printField("  Guaranteed Space", maxSpaceMeasurement.GuaranteedSpace, "bytes");
                printField("  Physical used data space", maxSpaceMeasurement.PhysicalUsedDataSpace, "bytes");
                printField("  Snapshot reserve", maxSpaceMeasurement.SnapshotReserve, "bytes");
                printField("  Total data space", maxSpaceMeasurement.TotalDataSpace, "bytes");
                printField("  Total Space", maxSpaceMeasurement.TotalSpace, "bytes");
                printField("  Used snapshot Space ", maxSpaceMeasurement.UsedSnapshotSpace, "bytes");
            }
            Console.WriteLine("---------------------------------------------------------------------");
            // End the space metric iteration
            dfmService.DatasetSpaceMetricListInfoIterEnd(dsSpaceIterEnd);
            }
            catch (SoapException e)
            {
                Console.Error.WriteLine(e.Message);
            }
        }


        /// <summary>
        /// Lists dataset's I/O usage metrics.
        /// </summary>
        /// <param name="dsName">Name or Id of the dataset.</param>
        /// <param name="day">The day for which the usage metric is required.</param>
        /// <param name="month">The month for which the usage metric is required.</param>
        /// <param name="year">The year for which the usage metric is required.</param>
        public static void listDatasetIoUsageMetrics(string dsName, string day, string month, string year)
        {
            try
            {

            // Create DatasetIoMetricListInfoIterStart instance and set the dataset name, 
            // day, month and year parameters
            DatasetIoMetricListInfoIterStart dsIoIterStart  = new DatasetIoMetricListInfoIterStart();
            dsIoIterStart.ObjectNameOrId = dsName;
            dsIoIterStart.Day = day;
            dsIoIterStart.Month = month;
            dsIoIterStart.Year = year;

            // Invoke datasetIoMetricListInfoIterStart API. This API will return a IterStartResult structure which contain  
            // tag and record values and extract the tag and record values returned in IterStartResult
            DatasetIoMetricListInfoIterStartResult dsIoIterStartResult = dfmService.DatasetIoMetricListInfoIterStart(dsIoIterStart);
            string tag = dsIoIterStartResult.Tag;
            string records = dsIoIterStartResult.Records;
            
            // Create DatasetIoMetricListInfoIterEnd instance to end iteration of io metrics
            DatasetIoMetricListInfoIterEnd dsIoIterEnd = new DatasetIoMetricListInfoIterEnd();
            dsIoIterEnd.Tag = tag;
            
            if (Convert.ToInt32(records) == 0) {
                Console.WriteLine("No dataset's I/O usage measurements to list\n");
                // End the metric iteration
                dfmService.DatasetIoMetricListInfoIterEnd(dsIoIterEnd);
                return;
            }
            
            // Create DatasetIoMetricListInfoIterNext instance and set the tag and max no. of records to return.
            DatasetIoMetricListInfoIterNext dsIoIterNext = new DatasetIoMetricListInfoIterNext();
            dsIoIterNext.Tag = tag;
            dsIoIterNext.Maximum = records;
            
            // Invoke datasetIoMetricListInfoIterNext API. The API will return a IterNextResult structure 
            // which contain DatasetIoMetric records.
            DatasetIoMetricListInfoIterNextResult dsIoIterNextResult = dfmService.DatasetIoMetricListInfoIterNext(dsIoIterNext);
            
            DatasetIoMetricInfo[] dsIoMetricInfoList = dsIoIterNextResult.DatasetIoMetrics;
            // Iterate through each Io Metric record
            foreach (DatasetIoMetricInfo dsIoMetricInfo in dsIoMetricInfoList) 
            {
                Console.WriteLine("---------------------------------------------------------------------");
                
                // Extract the information about dataset node.
                WrapperOfMetricDatasetNodeInfo wrapperOfMetricDsnodeInfo = dsIoMetricInfo.DatasetNode;
                MetricDatasetNodeInfo metricDsNodeInfo = wrapperOfMetricDsnodeInfo.MetricDatasetNodeInfo;
                Console.WriteLine(" Dataset node info                 : ");
                printField("  Dataset", metricDsNodeInfo.DatasetName);
                printField("  DP Node Name", metricDsNodeInfo.DpNodeName);
                printField("  ProvisioningPolicy", metricDsNodeInfo.ProvisioningPolicyName);
                printField("  ProtectionPolicy", metricDsNodeInfo.ProtectionPolicyName);
                printField("  Storage Service", metricDsNodeInfo.StorageServiceName);
                Console.WriteLine();
                DateTime datetime = new DateTime(1970, 1, 1, 0, 0, 0).AddSeconds(
                    Convert.ToDouble(dsIoMetricInfo.Timestamp));
                printField(" Timestamp", datetime.ToLocalTime());
                printField(" Is overcharge", dsIoMetricInfo.IsOvercharge);
                Console.WriteLine();

                // Extract the information about I/O measurement.
                IoMeasurement ioMeasurement = dsIoMetricInfo.IoMeasurement;
                Console.WriteLine(" I/O Measurement                   : ");
                printField("  Data read", ioMeasurement.DataRead, "bytes");
                printField("  Data written", ioMeasurement.DataWritten, "bytes");
            }
            Console.WriteLine("---------------------------------------------------------------------");
            // End the io metric iteration
            dfmService.DatasetIoMetricListInfoIterEnd(dsIoIterEnd);
            }
            catch (SoapException e)
            {
                Console.Error.WriteLine(e.Message);
            }
        }
        
        public static void printField(String fieldName, Object fieldValue)
        {
            printField(fieldName, fieldValue, null);
        }

        public static void printField(string fieldName, Object fieldValue, String units) 
        {
            Console.WriteLine(string.Format (
                    "{0,-35}: {1} {2}",
                    fieldName, 
                    fieldValue == null ? "" : fieldValue,
                    units == null ? "" : (fieldValue == null ? "" : units)
                    ));
        }
    }
}

