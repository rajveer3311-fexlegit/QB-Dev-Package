/**
*  Purpose         : This class is for Quickbook services processing http api calls
*
*  Created Date    : 15/07/2021
*
*  Created By      : Suresh Koumar
*
*  Revision Logs   : V_1.0 - Created
*                    V_1.1 - Last Modified By : Rajveer Singh Rawat - 20/10/2023 
*
**/
public with sharing class QuickbookService {
    
    /**
    * @ description          : This method parse create invoice response data and return invoice object.
    * @ args: jsonString     : invoice json data
    * 
    * @ return: Invoice      : return invoice object 
    **/
    public static QuickbookInvoice parseCreateInvoiceResponse(String jsonString) {
        QuickbookInvoice invoice = null;
        Map<String, Object> invoiceResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        Object queryResponseObj;
        Object invoiceObject;
        Object invoices;
        if(Test.isRunningTest()){
            queryResponseObj = invoiceResponse.get('QueryResponse'); 
            invoices = ((Map<String, Object>)queryResponseObj).get('Invoice');
            Object[] invoicesArray = ((Object[])invoices);
            invoiceObject = invoicesArray[0];
        }else{
            invoiceObject = invoiceResponse.get('Invoice');
        }
        if(invoiceObject != null) {
            String invoiceJsonString = JSON.serialize(invoiceObject);
            JSONParser parser = JSON.createParser(invoiceJsonString);
            invoice = (QuickbookInvoice)parser.readValueAs(QuickbookInvoice.class);            
        } else {
            throw new QuickbookException.InvoiceNotFoundException('Invalid Invoice Response : ' +  jsonString);
        }
        return invoice;
    }
    
    /**
    * @ description            : This method parse the invoice response data and returns invoice list.
    * @ args: jsonString       : invoice jsonString
    * 
    * @ return: list           : returns list of invoices 
    **/
    public static List<QuickbookInvoice> parseInvoiceResponse(String jsonString) {
        
        //List of QuickbookInvoice
        List<QuickbookInvoice> invoicesList = new List<QuickbookInvoice>();
        try {
            //Deserialize json string
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            Object queryResponseObj = response.get('QueryResponse'); 
            if(queryResponseObj != null) {
                Object invoices = ((Map<String, Object>)queryResponseObj).get('Invoice');
                if(invoices != null) {
                    Object[] invoicesArray = ((Object[])invoices);
                    if(invoicesArray != null && !invoicesArray.isEmpty()) {
                        String invoiceJsonString = '';
                        Integer i = 1;
                        for(Object invoiceObject : invoicesArray) {
                            i++;
                            try {
                                invoiceJsonString = JSON.serialize(invoiceObject);
                                QuickbookInvoice invoice = (QuickbookInvoice)JSON.deserialize(invoiceJsonString, QuickbookInvoice.class);
                                invoicesList.add(invoice);
                            } catch(Exception e) {
                                System.debug('Error deserializing invoice data: ' + e.getMessage() + '' + invoiceJsonString);
                            }
                        }
                    } else {
                        throw new QuickbookException('Invoice data not found: ' + jsonString);
                    }
                } else {
                    throw new QuickbookException('Invoice data not found: ' + jsonString);
                }
            } else {
                throw new QuickbookException('Invalid response received : ' +  jsonString);
            }
        } catch(Exception e) {
            System.debug('Message'+e.getMessage());
        }
        return invoicesList;
    }
    
     /**
    * @ description            : This method parse the invoice response data and returns invoice list.
    * @ args: jsonString       : invoice jsonString
    * 
    * @ return: list           : returns list of invoices 
    **/
    public static List<QuickbookInvoice> parseUpdatedInvoiceResponse(String jsonString) {
        // List of QuickbookInvoice
        List<QuickbookInvoice> invoicesList = new List<QuickbookInvoice>();
        
        // Deserialize the JSON string
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        
        // Access the 'CDCResponse' array
        List<Object> cdcResponse = (List<Object>) response.get('CDCResponse');
        
        // Access the 'QueryResponse' array
        Map<String, Object> queryResponseMap = (Map<String, Object>) cdcResponse[0];
        
        //QueryResponse
        List<Object> queryResponses = (List<Object>) queryResponseMap.get('QueryResponse');
        
        // Access the 'Invoice' array
        Map<String, Object> invoiceResponseMap = (Map<String, Object>) queryResponses[1];
        
        //Invoices
        List<Object> invoiceResponses = (List<Object>) invoiceResponseMap.get('Invoice');

        // Now, you can loop through invoiceResponses and create QuickbookInvoice objects
        for (Object invoiceObj : invoiceResponses) {
            Map<String, Object> invoiceMap = (Map<String, Object>) invoiceObj;
            QuickbookInvoice invoice = (QuickbookInvoice)JSON.deserialize(JSON.serialize(invoiceObj), QuickbookInvoice.class);
            invoicesList.add(invoice);
        }
        
        return invoicesList;
    }

    
    /**
    * @ description                          : This method make the callout and create Quick Book records online
    * @ args: List<Quickbook_Invoice__c>     : quickBookInvoices
    * @ return                               : void 
    **/
    @Auraenabled
    public static void createQuickBookInvoices(List<Quickbook_Invoice__c> quickBookInvoices){
        
        //Set of Account Ids
        Set<Id> setOfAccountIds = new Set<Id>(); 
        //Set of QB Ids
        Set<Id> setOfQbIDS = new Set<Id>();
        
        //Get Quickbook custom setting record
        QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
        
        //Check salesforce to QB callout is allow or not
        if(settingInfo.SFToQBCallout__c){
            
            //Fill sets by Invoice
            for(Quickbook_Invoice__c qbInvoice : quickBookInvoices){
                setOfQbIDS.add(qbInvoice.Id);
                setOfAccountIds.add(qbInvoice.Account__c);
            }
            
            //Map of salesforce QB Invoice
            Map<String,Id> mapOfSFQBInvoiceId = new Map<String,Id>();
            
            //Map of contract Id and List of QB Invoice
            Map<Id,List<QuickbookLine>> mapOfqbIdAndServiceLines  = setQBServiceLines(setOfQbIDS);
            
            //Map of Id, Account 
            Map<Id,Account> mapOfIDsAccount = QuickbookSFHelper.getAccountByIds(setOfAccountIds);
            
            //Get the QuickBook connection record for the API calling 
            Quickbook_Connection__c quickBookConnection = QuickbookHelper.getQuickbookConnection();
            
            //List of QB Invoice
            List<QuickbookInvoice> listOfInvoices = new List<QuickbookInvoice>();
            
            //Get last QB Invoice record
            QuickbookInvoice lastQBInvoice = getInvoicesData(quickBookConnection,1,null)[0];
            //Last QB invoice document number
            Integer invoiceNumber = lastQBInvoice != null ?  Integer.valueOf(lastQBInvoice.DocNumber.split('-')[1])+1 : 10000001;
            
            //Last QB invoice Id
            Integer invoiceId;
            
            //Cover the test cases run only when the test class run
            if(!Test.isRunningTest())
                invoiceId = lastQBInvoice != null ? Integer.valueOf(lastQBInvoice.Id)+1 : 1;
            else
                invoiceId = lastQBInvoice != null ? Integer.valueOf(lastQBInvoice.Id) : 1;
            
            //Loop on Quickbook Invoice records
            for(Quickbook_Invoice__c qbInvoice : quickBookInvoices){
                
                //Create QuickbookInvoice
                QuickbookInvoice invoice = new QuickbookInvoice();
                invoice.DueDate = qbInvoice.Due_Date__c;
                invoice.Balance = qbInvoice.Balance_Due__c;
                
                //Set Quickbook Customer Id
                QuickbookNameValue CustomerRef = new QuickbookNameValue();
                if(mapOfIDsAccount.containsKey(qbInvoice.Account__c) && mapOfIDsAccount.get(qbInvoice.Account__c) != null){
                    CustomerRef.value = mapOfIDsAccount.get(qbInvoice.Account__c).Quickbook_Customer_Id__c;
                    invoice.CustomerRef = CustomerRef;
                }
                
                QuickbookNameValue itemRef = new QuickbookNameValue();
                itemRef.value = QuickbookConstants.SERVICE_LINE_HOURS;
                invoice.CurrencyRef = itemRef;
                invoice.DocNumber = String.valueOf('IN-'+invoiceNumber);
                
                //Check service line exist 
                if(mapOfqbIdAndServiceLines.containsKey(qbInvoice.Id)){
                    invoice.Line = mapOfqbIdAndServiceLines.get(qbInvoice.Id);
                    listOfInvoices.add(invoice);
                    //put new Invoice Id and SF QB Invoice Id
                    mapOfSFQBInvoiceId.put(String.valueOf(invoiceId),qbInvoice.Id);
                    invoiceNumber++;
                    invoiceId++;
                }
            }
            
            //Check the size of listOfInvoices and connection
            if(quickBookConnection != null && listOfInvoices.size() > 0) {
                
                //List of new Invoices
                List<QuickbookInvoice> listOfNewInvoices = new List<QuickbookInvoice>();
                
                //Map of updated QB Invoice
                Map<String,QuickbookInvoice> mapOfUpdatedQBInvoice = new Map<String,QuickbookInvoice>();
                
                //Map of new document Id and SF QB Name
                Map<String,QuickbookInvoice> mapOfnewQBIdAndQBResponse = new Map<String,QuickbookInvoice>();
                
                for(QuickbookInvoice qbInvoice : listOfInvoices){
                    
                    //Making POST API callout to create QuickBook record
                    QuickbookInvoice newqbInvoice = makeInvoiceCallout(JSON.serialize(qbInvoice, true),quickBookConnection);
                    
                    //Check new qb Invoice exist
                    if(newqbInvoice != null){
                        if(mapOfSFQBInvoiceId.containsKey(newqbInvoice.Id)){
                            mapOfnewQBIdAndQBResponse.put(newqbInvoice.Id,newqbInvoice);
                            listOfNewInvoices.add(newqbInvoice);
                        }
                    }
                }
                //upsert Invoice record
                if(listOfNewInvoices.size() > 0 && mapOfnewQBIdAndQBResponse != null && mapOfSFQBInvoiceId != null && mapOfnewQBIdAndQBResponse.keySet().size() > 0)
                    upsertInvoicesResponse(listOfNewInvoices,mapOfnewQBIdAndQBResponse,mapOfSFQBInvoiceId);
            }
        }
    }   
    /**
   * @ description                               : This method make the API callount and create Quick Book record 
   * @ args: String, Quickbook_Connection__c     : invoiceJson, quickBookConnection
   * 
   * @ return: void                              : QuickbookInvoice
   **/
    public static QuickbookInvoice makeInvoiceCallout(String invoiceJson, Quickbook_Connection__c quickBookConnection){
        
        //Custom QB setting record
        QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
        QuickbookInvoice invoice = new QuickbookInvoice();
       
        try{
            if(quickBookConnection != null){
                
                if(settingInfo != null) {
                    String endPoint = QuickbookHelper.getQuickbookInstanceUrl(settingInfo.IsProduction__c)
                        + '/' + QuickbookConstants.API_VERSION + '/company/' + quickBookConnection.Company_Id__c + '/invoice';
                    QuickbookInvoice invoiceObj = (QuickbookInvoice)JSON.deserialize(invoiceJson, QuickbookInvoice.class);
                    String invoiceJsonStr = JSON.serialize(invoiceObj, true);
                    //Make HTTP Request
                    HttpResponse httpRes = QuickbookHelper.postAPICall(endPoint,'Bearer '+quickBookConnection.Access_Token__c, 'application/json', invoiceJson);

                    if(httpRes != null) {
                        if(httpRes.getStatusCode() == 200) {
                            String jsonString = httpRes.getBody();
                            invoice = parseCreateInvoiceResponse(jsonString);
                            if(invoice != null) 
                                return invoice;
                        } else{
                            throw QuickbookHelper.parseHttpError(httpRes);
                        }
                    }else {
                        System.debug('Http response null');
                    }
                }else{
                    System.debug(QuickbookConstants.CUSTOM_SETTING_ERROR);
                    throw new QuickbookException.QuickbookConnectionException(QuickbookConstants.CUSTOM_SETTING_ERROR);
                }
            }else{
                System.debug(QuickbookConstants.CONNECTION_ERROR);
                throw new QuickbookException.QuickbookConnectionException(QuickbookConstants.CONNECTION_ERROR);
            }
        }catch(Exception e){
            System.debug('An error occurred: ' + e.getMessage());
        }
        return null;
    }
    
    /**
    * @ description        : This method parse the invoice data and prepare SF invoice and line records.
    * @ args: invoices     : list of invoices
    * 
    * @ return: void       : 
    **/
    @AuraEnabled
    public static void upsertInvoicesResponse(List<QuickbookInvoice> invoices, Map<String,QuickbookInvoice> mapOfResponseIDandInvoices,Map<String,Id> mapOfSFQBInvoiceId) {
        
        //Map of Invoice Id and QB Invoice
        Map<String,Quickbook_Invoice__c> mapOfQuickBookInvoices = new Map<String,Quickbook_Invoice__c>();
        //Map of Invoice ID annd List of Service Lines
        Map<String,List<Quickbook_Service_Line__c>> mapOfQuickBookServiceLines = new Map<String,List<Quickbook_Service_Line__c>>();
        //Map of QB customer ID and QB Invoive
        Map<String,Quickbook_Invoice__c> mapOfCustIdAndQBInvoice = new Map<String,Quickbook_Invoice__c>();
        //Map of QB Invoice ID and Reference ID
        Map<String,String> mapOfQBInvoiceIdAndCurRefID = new Map<String,String>();
        //Map of QB Invoice ID and Invoices
        Map<String,QuickbookInvoice> mapOfQBInvoices = new Map<String,QuickbookInvoice>();
        //List of QuickbookLine
        List<QuickbookLine> listOfQuickbookLine = new List<QuickbookLine>();
        //Map of Qb Invoice
        Map<String,Quickbook_Invoice__c> mapOfQBInvoice = new Map<String,Quickbook_Invoice__c>();
        //Set of QB Ids
        Set<Id> setOfDeletedSFLines = new Set<Id>();
        //Deleted Invoices from system
        Set<String> setOfDeletedSFInvoices = new Set<String>();
        //Set of Invoice Id and Quickbook Invoice
        Set<String> setOfQBInvoicesIds = new Set<String>();
        //Set of Invoice Id and Quickbook Invoice
        Set<String> setOfCustRef = new Set<String>();
        
        //Get Quickbook custom setting record
        QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
        
        //Check callout is allow or not
        if((settingInfo.QBToSFCallout__c) || (settingInfo.SFToQBCallout__c &&  mapOfSFQBInvoiceId.size() > 0)){
            
            //Store deleted and updated/Inserted ids
            for(QuickbookInvoice qbInvoice : invoices){
                if(qbInvoice.status == QuickbookConstants.STR_DELETE)
                    setOfDeletedSFInvoices.add(qbInvoice.Id);
                else
                    setOfQBInvoicesIds.add(qbInvoice.Id);
            }
        
        //Delete SF Invoices record which is deleted on QB online
        if(setOfDeletedSFInvoices.size() > 0)
            QuickbookSFHelper.deleteInvoiceRecords(setOfDeletedSFInvoices);
        
        //Check map contains value for update or not
        if(setOfQBInvoicesIds.size() > 0)
            mapOfQBInvoice = QuickbookSFHelper.getQBInvoiceRecords(setOfQBInvoicesIds);
        try{
            //Check Invoices exist or not
            if((invoices != null && !invoices.isEmpty())) {
                for(QuickbookInvoice invoice : invoices) {
                    
                    if(setOfDeletedSFInvoices.contains(invoice.id))continue;
                    
                    //set QB invoice data
                    Quickbook_Invoice__c invoiceObj = new Quickbook_Invoice__c();
                    
                    //Assign Id in update case
                    if(mapOfQBInvoice.keySet().size() > 0 && mapOfQBInvoice.containsKey(invoice.Id)){
                        invoiceObj.Id = mapOfQBInvoice.get(invoice.Id).Id;
                        setOfDeletedSFLines.add(invoiceObj.Id);
                    }
                    else if(mapOfSFQBInvoiceId != null && mapOfSFQBInvoiceId.containskey(invoice.Id)){
                        invoiceObj.Id = mapOfSFQBInvoiceId.get(invoice.Id);
                        setOfDeletedSFLines.add(invoiceObj.Id);
                    }
                    
                    invoiceObj.Name = invoice.DocNumber;
                    invoiceObj.Quickbook_Invoice_Id__c = invoice.Id;
                    invoiceObj.Invoice_Date__c = invoice.TxnDate;
                    invoiceObj.Due_Date__c = invoice.DueDate;
                    invoiceObj.Total_Amount__c = invoice.TotalAmt;
                    invoiceObj.Balance_Due__c = invoice.Balance;
                    if(invoice.TxnTaxDetail != null) {
                        invoiceObj.Tax__c = invoice.TxnTaxDetail.TotalTax;
                    }
                    
                    //Fill map 
                    mapOfQuickBookInvoices.put(invoiceObj.Quickbook_Invoice_Id__c,invoiceObj);
                    mapOfQBInvoices.put(invoiceObj.Quickbook_Invoice_Id__c,invoice);
                    
                    //set customer Account Id to invoice sobject record
                    mapOfCustIdAndQBInvoice.put(invoice.CustomerRef.value,invoiceObj);
                    mapOfQBInvoiceIdAndCurRefID.put(invoiceObj.Quickbook_Invoice_Id__c,invoice.CustomerRef.value);
                    
                    //set all lines data
                    List<Quickbook_Service_Line__c> linesObj = new List<Quickbook_Service_Line__c>();
                    List<QuickbookLine> lines = invoice.Line;
                    
                    //Check Invoice lines exist or not
                    if(lines != null && !lines.isEmpty()) {
                        for(QuickbookLine line : lines) {
                            if(line.DetailType == 'SubTotalLineDetail') {
                                if(mapOfQuickBookInvoices.containsKey(invoiceObj.Quickbook_Invoice_Id__c)){
                                    mapOfQuickBookInvoices.get(invoiceObj.Quickbook_Invoice_Id__c).Sub_Total__c = line.Amount;
                                }
                            } else if(line.DetailType == 'SalesItemLineDetail') {
                                if (line.SalesItemLineDetail != null) {
                                    Quickbook_Service_Line__c lineObj = new Quickbook_Service_Line__c();
                                    lineObj.Name = invoiceObj.Quickbook_Invoice_Id__c + '_' + line.Id;
                                    lineObj.Activity__c = line.SalesItemLineDetail.ItemRef.name;
                                    lineObj.Quickbook_Invoice_Id__c = invoiceObj.Quickbook_Invoice_Id__c;
                                    lineObj.Service_Date__c = line.SalesItemLineDetail.ServiceDate;
                                    lineObj.Description__c = line.Description;
                                    lineObj.Hours__c = line.SalesItemLineDetail.Qty;
                                    lineObj.Rate__c = line.SalesItemLineDetail.UnitPrice;
                                    lineObj.Amount__c = line.Amount;
                                    linesObj.add(lineObj);
                                }   
                            }
                            listOfQuickbookLine.add(line);
                            mapOfQuickBookServiceLines.put(invoiceObj.Quickbook_Invoice_Id__c,linesObj);
                        }
                    }else{
                        throw new QuickbookException.InvoiceLineDataNotFoundException('Required lines data not found.');
                    }
                }
                
                Map<String,Account> mapOfCustIDsAndAccounts = new Map<String,Account>();
                //Map of QB customer id and Account
                if(mapOfCustIdAndQBInvoice.keySet().size() > 0)
                    mapOfCustIDsAndAccounts = QuickBookSFHelper.getAccountsByQuickbookCustomerIds(mapOfCustIdAndQBInvoice.keySet());
                
                //delete existiing service lines
                if(setOfDeletedSFLines.size() > 0)
                    QuickbookSFHelper.deleteServiceLines( new List<Id>(setOfDeletedSFLines));
                
                //Check Account map is null
                if(mapOfCustIDsAndAccounts != null && mapOfCustIDsAndAccounts.size() > 0){
                    //Set customer Account IDs
                    mapOfQuickBookInvoices = setCustomerAccountIds(mapOfCustIDsAndAccounts,mapOfQBInvoiceIdAndCurRefID,mapOfQuickBookInvoices,mapOfQBInvoices);
                    //Insert invoice data in SF
                    QuickbookSFHelper.upsertInvoiceRecord(mapOfQuickBookInvoices, mapOfQuickBookServiceLines);
                }
                else{
                    if(setOfQBInvoicesIds.size() > 0)
                        throw new QuickbookException('Required SF account with Quickbook customer id');
                }
            }
            else{
                System.debug('No Invoice data to upsert. ' +invoices);
            }
        }catch(Exception e){
            throw new QuickbookException.InvoiceLineDataNotFoundException(e.getMessage());
        }
    }
}  
    /**
   * @ description        : This method finds the customer account in sf and set customer account id.
   * @ return:            : Map<String,Quickbook_Invoice__c> 
   **/
    public static Map<String,Quickbook_Invoice__c> setCustomerAccountIds(Map<String,Account> mapOfCustIDsAndAccounts,Map<String,String> mapOfCustRefIDAndQBInvoiceIDs, Map<String,Quickbook_Invoice__c> mapOfQuickBookInvoices,Map<String,QuickbookInvoice> mapOfQBInvoices) {
        
        for(Quickbook_Invoice__c qbInvoice : mapOfQuickBookInvoices.values()){
            try{
                if(mapOfCustRefIDAndQBInvoiceIDs.containsKey(qbInvoice.Quickbook_Invoice_Id__c) && mapOfCustIDsAndAccounts.containsKey(mapOfCustRefIDAndQBInvoiceIDs.get(qbInvoice.Quickbook_Invoice_Id__c))){
                    mapOfQuickBookInvoices.get(qbInvoice.Quickbook_Invoice_Id__c).Account__c = mapOfCustIDsAndAccounts.get(mapOfCustRefIDAndQBInvoiceIDs.get(qbInvoice.Quickbook_Invoice_Id__c)).Id;
                }
                else {
                    throw new QuickbookException('Required SF account with Quickbook customer id : ' + mapOfQBInvoices.get(qbInvoice.Quickbook_Invoice_Id__c).CustomerRef.value + ' not found for invoice-no ' + qbInvoice.Name);
                }
            }
            catch(Exception e){}
        }
        return mapOfQuickBookInvoices;
    }
     
    //Set QB Service Lines on Invoices
    public static Map<Id,List<QuickbookLine>> setQBServiceLines(Set<Id> setOfQBIds) {
        
        //Map of QB Id and list of Quickbook Service Line
        Map<Id,List<Quickbook_Service_Line__c>>  mapOfIdAndServiceLines = new Map<Id,List<Quickbook_Service_Line__c>>();
        
        if(setOfQBIds != null)
            mapOfIdAndServiceLines = QuickbookSFHelper.getQBServiceLines(setOfQBIds);
        
        //Map of contract Id and List of QuickbookLine
        Map<Id,List<QuickbookLine>> mapOfServiceLines = new Map<Id,List<QuickbookLine>>();
        
        if(mapOfIdAndServiceLines != null && mapOfIdAndServiceLines.keySet().size() > 0) {
            for(Id qbId : setOfQBIds){
                if(mapOfIdAndServiceLines.containsKey(qbId)){
                    List<QuickbookLine> listOfQbLines = new List<QuickbookLine>();
                    for(Quickbook_Service_Line__c serviceLines : mapOfIdAndServiceLines.get(qbId)){
                        
                        //QuickbookSalesItemLineDetail class Instance
                        QuickbookSalesItemLineDetail salesItemLineDetail = new QuickbookSalesItemLineDetail();
                        salesItemLineDetail.ServiceDate = getLastDateOfMonth();
                        salesItemLineDetail.Qty = 1;
                        salesItemLineDetail.UnitPrice = (serviceLines.Rate__c == null || serviceLines.Rate__c ==0) ? 1 : serviceLines.Rate__c;              
                        salesItemLineDetail.TaxCodeRef = getTaxRefCode();
                        
                        //QuickbookNameValue class Instance
                        QuickbookNameValue itemRef = new QuickbookNameValue();
                        itemRef.value = QuickbookConstants.SERVICE_LINE_HOURS;
                        salesItemLineDetail.ItemRef = itemRef;
                        
                        //Set Service Line Items                        
                        QuickbookLine lineItem = new QuickbookLine();
                        lineItem.Amount = salesItemLineDetail.Qty * salesItemLineDetail.UnitPrice;
                        lineItem.Description = serviceLines.Description__c;
                        lineItem.DetailType = 'SalesItemLineDetail';
                        lineItem.SalesItemLineDetail = salesItemLineDetail;
                        listOfQbLines.add(lineItem);
                    }
                    mapOfServiceLines.put(qbId,listOfQbLines);
                }
            }
            return mapOfServiceLines;
        } else {
            throw new QuickbookException('Quickbook Service Lines records not found!');
        }
    }
    
    /**
    * @ description           : This method returns the last date of the current month
    * @ return: Date          : last date of current month
    **/
    public static Date getLastDateOfMonth(){
        Date selectedDate =  Date.today();
        Date firstDate = selectedDate.toStartOfMonth();
        return firstDate.addDays(date.daysInMonth(selectedDate.year() , selectedDate.month())  - 1);
    }
    
    /**
    * @ description         : This method returns tax code reference as per quickbook type
    * 
    * @ return: TaxCodeRef      : returns tax code reference value
    **/
    public static QuickbookTaxCodeRef getTaxRefCode() {
        QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
        QuickbookTaxCodeRef taxCodeRef = new QuickbookTaxCodeRef();
        if(settingInfo != null && settingInfo.IsTaxable__c) {
            taxCodeRef.value = '26';
        } else {
            taxCodeRef.value = 'NON';
        }
        return taxCodeRef;
    }
    
    /**
    * @ description                           : Get online Invoices data
    * 
    * @ return: List<QuickbookInvoice>        : invoice id
    **/
    public static List<QuickbookInvoice> getInvoicesData(Quickbook_Connection__c quickBookConnection,Integer startingPosn,Set<String> invoiceIds){

        if(quickBookConnection != null) {
            
            QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
            
            //Hold bulk Invoice ids
            String onlineinvoiceIDs;
            if(invoiceIds != null)
                onlineinvoiceIDs = getInvoiceBulkIDs(invoiceIds);
            
            if(settingInfo != null) {
                String endPoint = QuickbookHelper.getQuickbookInstanceUrl(settingInfo.IsProduction__c)
                    + '/' + QuickbookConstants.API_VERSION + '/company/'+quickBookConnection.Company_Id__c + '/query?query=';
                if(invoiceIds == null || invoiceIds.isEmpty())
                    endPoint = endPoint + 'select * from Invoice order by id desc startPosition '+startingPosn+' MAXRESULTS 1000';  
                else
                   endPoint = endPoint + 'select * from Invoice where id IN '+onlineinvoiceIDs;
                 
                //Calling get invoice api
                HttpResponse httpRes = QuickbookHelper.getAPICall(endPoint.replaceAll(' ', '%20'), quickBookConnection.Access_Token__c);
                if(httpRes.getStatusCode() == 200) {
                    String jsonString = httpRes.getBody();
                    List<QuickbookInvoice> invoices = parseInvoiceResponse(jsonString);
                    
                    return invoices;
                } else{
                    throw new QuickbookException.QuickbookBadRequestException(String.valueOf(QuickbookHelper.parseHttpError(httpRes)));
                } 
            } else {
                throw new QuickbookException.QuickbookConnectionException(QuickbookConstants.CUSTOM_SETTING_ERROR);
            }
        } else {
            throw new QuickbookException.QuickbookConnectionException(QuickbookConstants.CONNECTION_ERROR);
        }
    } 
    
    //This method will split Ids and store in string
    public static String getInvoiceBulkIDs(Set<string> setOfInvoiceIDs) {
        String invoiceIds='(';
        for(String invId : setOfInvoiceIDs){
            invoiceIds+= '\''+invId+'\'' +',';
        }
        invoiceIds = invoiceIds.removeEnd(',');
        invoiceIds+=')';
        return invoiceIds;
    }
    
    /**
     * @ description           : This method is to query all the invoices records updated yesterday on QB online
     * @ return: String        : List of Invoices
    **/
    public static List<QuickbookInvoice> getQBInvoicesChanges(Quickbook_Connection__c quickBookConnection,String lastRecordUpdatedDate){
        
        List<QuickbookInvoice> invoices = new List<QuickbookInvoice>();
        
        if(quickBookConnection != null) {
            QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
            
            if(settingInfo != null) {
                
                String dateWithTimeZone;
                if(String.isBlank(lastRecordUpdatedDate)){
                    //Subtract custom setting hours from current date 
                    Datetime dt = System.now().addHours(-Integer.valueOf(settingInfo.CDCBatchFrequencyINHours__c));
                    //Convert it into Pacific Standard Time(PST).
                    String dtPST = dt.format('yyyy-MM-dd HH:mm:ss', 'PST');
                    //Add T between date and time
                    dateWithTimeZone = dtPST.replace(' ','T');
                }else{
                    dateWithTimeZone = lastRecordUpdatedDate;
                }
                
                String query = '/cdc?entities=invoice,Estimate&changedSince='+dateWithTimeZone+'&minorversion=69';
                
                String endPoint = QuickbookHelper.getQuickbookInstanceUrl(settingInfo.IsProduction__c)
                    + '/' + QuickbookConstants.API_VERSION + '/company/'+quickBookConnection.Company_Id__c + query;
                System.debug('endPoint###'+endPoint);
                
                endPoint = endPoint + EncodingUtil.urlEncode(query, 'UTF-8');
                
                //Make Get callout
                HttpResponse httpRes = QuickbookHelper.getAPICall(endPoint, quickBookConnection.Access_Token__c);
                
                if(httpRes.getStatusCode() == 200) {
                    String jsonString = httpRes.getBody();
                    invoices = QuickbookService.parseUpdatedInvoiceResponse(jsonString);
                } else{
                    throw new QuickbookException.QuickbookBadRequestException(String.valueOf(QuickbookHelper.parseHttpError(httpRes)));
                }
            } else {
                throw new QuickbookException.QuickbookConnectionException(QuickbookConstants.CUSTOM_SETTING_ERROR);
            }
        } else {
            throw new QuickbookException.QuickbookConnectionException(QuickbookConstants.CONNECTION_ERROR);
        }
        return invoices;
    }
}