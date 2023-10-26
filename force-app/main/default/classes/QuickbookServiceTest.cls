/**
 *  Purpose         : Test class for QuickbookService class
 *
 *  Created Date    : 27/07/2021
 * 
 *  Created By      : Suresh Koumar
 *
 *  Revision Logs   : V_1.0 - Created   
 *                    V_1.1 - Modified By : Rajveer Singh Rawat - 12/10/2023 
 *
 **/
@IsTest
public with sharing class QuickbookServiceTest {  
 
     /** 
     * @ description: This method test create new invoice. 
     *
     * @ return: void : 
    **/
    @isTest
    static void test_createInvoice() {

         String invoiceJson = '{"testkey":"testvalue"}';
        
        //test when connection record is not present
        try {
          QuickbookService.makeInvoiceCallout(invoiceJson,null);
        } catch(QuickbookException.QuickbookConnectionException e) {
            System.assert(e.getMessage().contains(QuickbookConstants.CONNECTION_ERROR));
        }
        
        //QB Connection
        Quickbook_Connection__c connection = getQBConnection();        
        
        //test when connection record is present but quickbook custom setting is not available
        try { 
            QuickbookService.makeInvoiceCallout(invoiceJson,connection);
        } catch(QuickbookException.QuickbookConnectionException e) {
            System.assert(e.getMessage().contains(QuickbookConstants.CUSTOM_SETTING_ERROR));
        }
        
        //Custom setting
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //Response code 400
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'error-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        try {
            Test.startTest();
            QuickbookService.makeInvoiceCallout(invoiceJson,connection);
            Test.stopTest();
        } catch(QuickbookException.QuickbookBadRequestException e) {
            System.assert(e.getMessage().contains('test error message.')); 
        }
        
        //Http response codde 200 case
    	QuickbookHttpMockResponse.CALLOUT_TYPE = 'QB-invoice-callout';
       	Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        try {
            QuickbookService.makeInvoiceCallout(invoiceJson,connection);
        } catch(QuickbookException.QuickbookBadRequestException e) {
            System.assert(e.getMessage().contains('test error message.'));
        }
    }
    
    /**
     * @ description: This method test connection error 
     * @ return: void : 
    **/
    @isTest
    static void test_connectionError() {
        //test when connection record is not available
        try {
          QuickbookService.getInvoicesData(null,1,null);
        } catch(QuickbookException.QuickbookConnectionException e) {
            System.assert(e.getMessage().contains(QuickbookConstants.CONNECTION_ERROR));
        }
        
        //QB Connection
        Quickbook_Connection__c connection = getQBConnection();
        
        try {
          QuickbookService.getInvoicesData(connection,1,null);
        } catch(QuickbookException.QuickbookConnectionException e) {
            System.assert(e.getMessage().contains(QuickbookConstants.CUSTOM_SETTING_ERROR));
        }
    }
    
    /**
     * @ description: This method test parse invoice response. 
     *
     * @ return: void : 
    **/
    @isTest
    static void test_parseInvoiceResponse() {
        
        //test invalid data
        try{
            List<QuickbookInvoice> invoices = QuickbookService.parseInvoiceResponse('test string');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('Invalid response received'));
        }
        
        List<QuickbookInvoice> noInvoices = QuickbookService.parseInvoiceResponse('{}');
        System.assertEquals(0, noInvoices.size());
        
        noInvoices = QuickbookService.parseInvoiceResponse('{"QueryResponse":{"test":"data"}}');
        System.assertEquals(0, noInvoices.size());
        
        noInvoices = QuickbookService.parseInvoiceResponse('{"QueryResponse":{"Invoice":[]}}');
        System.assertEquals(0, noInvoices.size());
        
        String jsonResponse = '{"QueryResponse":{"Invoice":[{"DocNumber":"1057","TxnDate":"2021-07-15","CurrencyRef":{"value":'
            +'"USD","name":"United States Dollar"},"Line":[{"Id":"1","LineNum":1,"Description":"abcdisc test\n new line","Amount":'
            +'600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ItemRef":{"value":"2","name":"Landscaping:Hours"},'
            +'"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"NON"}}},{"Id":"2","LineNum":2,"Amount":555.00,"DetailType":'
            +'"SalesItemLineDetail","SalesItemLineDetail":{"ItemRef":{"value":"7","name":"Landscaping:Installation"},"TaxCodeRef":'
            +'{"value":"NON"}}},{"Amount":1150.00,"DetailType":"SubTotalLineDetail","SubTotalLineDetail":{}}],"DueDate":"2021-07-18",'
            +'"TotalAmt":1155.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet","Balance":1155.00}]}}';
 
        try{
            noInvoices = QuickbookService.parseInvoiceResponse(jsonResponse);
        } catch(Exception e){
            System.assert(e.getMessage().contains('Error deserializing invoices'));
        }
        //test valid data
        jsonResponse = '{"QueryResponse":{"Invoice":[{"DocNumber":"1057","TxnDate":"2021-07-15","CurrencyRef":{"value":'
            +'"USD","name":"United States Dollar"},"Line":[{"Id":"1","LineNum":1,"Description":"abcdisc test new line","Amount":'
            +'600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ItemRef":{"value":"2","name":"Landscaping:Hours"},'
            +'"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"NON"}}},{"Id":"2","LineNum":2,"Amount":555.00,"DetailType":'
            +'"SalesItemLineDetail","SalesItemLineDetail":{"ItemRef":{"value":"7","name":"Landscaping:Installation"},"TaxCodeRef":'
            +'{"value":"NON"}}},{"Amount":1150.00,"DetailType":"SubTotalLineDetail","SubTotalLineDetail":{}}],"DueDate":"2021-07-18",'
            +'"TotalAmt":1155.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet","Balance":1155.00}]}}';
        
        //test QuickbookInvoice
        List<QuickbookInvoice> invoices = QuickbookService.parseInvoiceResponse(jsonResponse);
        System.assert(invoices != null);
        System.assert(invoices.size() > 0);
        
        QuickbookInvoice invoice = invoices[0];
        System.assertEquals('1057', invoice.DocNumber);
        System.assertEquals(1155.00, invoice.Balance);
        System.assertEquals(1155.00, invoice.TotalAmt);
        System.assertEquals(3, invoice.Line.Size());
        System.assertEquals(1150.00, invoice.Line[2].Amount);
        
        System.assertEquals('abcdisc test new line', invoice.Line[0].Description);
        System.assertEquals(600.00, invoice.Line[0].Amount);
        System.assertEquals('Landscaping:Hours', invoice.Line[0].SalesItemLineDetail.ItemRef.name);
        
        System.assertEquals(null, invoice.Line[1].Description);
        System.assertEquals(555.00, invoice.Line[1].Amount);
        System.assertEquals('Landscaping:Installation', invoice.Line[1].SalesItemLineDetail.ItemRef.name);
    }
    
    /**
     * @ description: This method test insert invoice response. 
     * @ return     : void
    **/
    @isTest
    public static void test_insertInvoicesResponse() {
        
        //Custom setting
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //mock data
        mockData();
        String invoiceJson = '{"Id":"183","DocNumber":"1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test My Desc"'
            				+',"Amount":600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16"'
            				+',"ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}}'
            				+'],"TxnTaxDetail":{"TotalTax":0}'
            				+',"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount"'
            				+':false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet","Balance":600.00}';
        
        QuickbookInvoice copyInvoice = (QuickbookInvoice)JSON.deserialize(invoiceJson, QuickbookInvoice.class);
        copyInvoice.Line = new List<QuickbookLine>();
        List<QuickbookInvoice> copyInvoices = new List<QuickbookInvoice>();
        copyInvoices.add(copyInvoice);
        
        try{
             QuickbookService.upsertInvoicesResponse(copyInvoices,null,null);
        } catch(QuickbookException.InvoiceLineDataNotFoundException e) {
            System.assert(e.getMessage().contains('Required lines data not found.'));
        }
        
        //Deserialize data
        QuickbookInvoice invoice = (QuickbookInvoice)JSON.deserialize(invoiceJson, QuickbookInvoice.class);
        List<QuickbookInvoice> invoices = new List<QuickbookInvoice>();
        invoices.add(invoice);
        QuickbookService.upsertInvoicesResponse(invoices,null,null);
        
        //Inserted QB Invoice
        List<Quickbook_Invoice__c> invoiceRecs = [Select id, Name, Total_Amount__c, Balance_Due__c from Quickbook_Invoice__c];
        System.assert(invoiceRecs != null && !invoiceRecs.isEmpty());
        System.assertEquals(1, invoiceRecs.size());
        System.assertEquals('1075', invoiceRecs[0].Name);
        System.assertEquals(600.00, invoiceRecs[0].Balance_Due__c);
        System.assertEquals(600.00, invoiceRecs[0].Total_Amount__c);
        
        //Inserted Service Lines
        List<Quickbook_Service_Line__c> serviceItems = [SELECT id, Name, Description__c, Amount__c,Activity__c from Quickbook_Service_Line__c];
        System.assert(serviceItems != null && !serviceItems.isEmpty());
        System.assertEquals(1, serviceItems.size());
        System.assertEquals('183_1', serviceItems[0].Name);
        
        System.assertEquals('Test My Desc', serviceItems[0].Description__c);
        System.assertEquals(600.00, serviceItems[0].Amount__c);
        System.assertEquals('Landscaping:Hours', serviceItems[0].Activity__c);
    }

    /**
     * @ description: This method test upsert invoice record. 
     * @ return: void : 
    **/
    @isTest
    public static void test_upsertInvoiceRecord() {
        
        //QB Connection
        Quickbook_Connection__c connection = getQBConnection();
        
        //Custom setting
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //mock data
        mockData();
        //List of Accounts
        List<Account> prodly = [Select id From Account];
        
        Quickbook_Invoice__c invoice = new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[0].Id, Sub_Total__c=100,Quickbook_Invoice_Id__c='11');
        
        //List of QB Service Lines
        List<Quickbook_Service_Line__c> linesObj = new List<Quickbook_Service_Line__c>();
        Quickbook_Service_Line__c lineObj = new Quickbook_Service_Line__c(Name=invoice.Name+ '_1', Activity__c='Hours',
                          Service_Date__c=System.today(), Description__c='test description', Hours__c=2,Rate__c=50,Amount__c=100, Quickbook_Invoice_Id__c='11');
        linesObj.add(lineObj);
        
        ///Map of Invoice Id and QB invoice
        Map<String,Quickbook_Invoice__c> mapOfQuickBookInvoices = new Map<String,Quickbook_Invoice__c>();
        mapOfQuickBookInvoices.put(invoice.Quickbook_Invoice_Id__c,invoice);
        
        //test exception while upserting
        try{
            QuickbookSFHelper.upsertInvoiceRecord(mapOfQuickBookInvoices, null);
        } catch(QuickbookException e){
            System.assert(e.getMessage().contains('Error upserting:'));
        }
        
        
        Map<String,List<Quickbook_Service_Line__c>> mapOfQuickBookServiceLines = new Map<String,List<Quickbook_Service_Line__c>>();
        mapOfQuickBookServiceLines.put(lineObj.Quickbook_Invoice_Id__c,new List<Quickbook_Service_Line__c>{lineObj});
        
        //test valid upsert case
        QuickbookSFHelper.upsertInvoiceRecord(mapOfQuickBookInvoices, mapOfQuickBookServiceLines);
        
        List<Quickbook_Invoice__c> invoices = [select id,Name,Sub_Total__c, Account__c, Total_Amount__c from Quickbook_Invoice__c];
        System.assert(invoices != null);
        System.assert(!invoices.isEmpty());
        System.assertEquals(1, invoices.size());
        System.assertEquals(100, invoices[0].Sub_Total__c);
        System.assertEquals(prodly[0].Id, invoices[0].Account__c);
        System.assertEquals(100, invoices[0].Total_Amount__c);
    }
    
    /**
     * @ description : This method test create invoice record. 
     * @ return      : void 
    **/
    @isTest
    public static void test_createInvoiceRecord() {
        
        //QB Connection
        Quickbook_Connection__c connection = getQBConnection();
        
        //Custom setting
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //mock data
        mockData();
        List<Account> accountList = [SELECT id from Account];
        
        //Insert QB Invoice       
        List<Quickbook_Invoice__c> qbInvoices = new List<Quickbook_Invoice__c>(); 
        qbInvoices.add(new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=accountList[0].Id,Sub_Total__c=100));
        insert qbInvoices;
        
        //Create Service Lines record
        List<Quickbook_Service_Line__c> serviceLines = new List<Quickbook_Service_Line__c>();
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_1',Quickbook_Invoice_Id__c='183',Quickbook_Invoice__c=qbInvoices[0].Id,Rate__c=20000,Description__c='Test My Invoice'));
        insert serviceLines;
        
        Test.startTest();
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'QB-invoice-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        QuickbookService.createQuickBookInvoices(qbInvoices);
        Test.stopTest();
        
        //QB Invoice records
        List<Quickbook_Invoice__c> invoiceRecs = [Select id, Name, Total_Amount__c, Balance_Due__c from Quickbook_Invoice__c];
        System.assertEquals(invoiceRecs.size(), 1);
        System.assertEquals(invoiceRecs[0].Name, 'IN-1075');
        
        //Service Lines
        List<Quickbook_Service_Line__c> serviceLine = [Select id,Quickbook_Invoice_Id__c,Quickbook_Invoice__c,Name From Quickbook_Service_Line__c];
        System.assertEquals(serviceLine.size(), 1);
        System.assertEquals(serviceLine[0].Quickbook_Invoice__c, invoiceRecs[0].Id);
    }
    
    /**
     * @ description : This method get the record based on Id
     * @ return      : void 
    **/
    @isTest
    public static void test_getInvoiceRecordByID() {
        
        //QB Connection
        Quickbook_Connection__c connection = getQBConnection();
        
        //Custom setting
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //mock data
        mockData();
        
        //Test start from here
        Test.startTest();
        
        //Call mock class
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'QB-invoice-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        //Assert
        List<QuickbookInvoice> qbInvoices = QuickbookService.getInvoicesData(connection,null,new Set<String>{'183'});
        System.assert(qbInvoices != null);
        System.assertEquals(qbInvoices[0].Id,'183');
        System.assertEquals(qbInvoices[0].docNumber,'IN-1075');
        
        Test.stopTest();
        //Test end here
    }
    
    /**
     * @ description: This method test response code 400 
     * @ return: void : 
    **/
    @isTest
    public static void test_responseCode_400() {
        
        //QB Connection
        Quickbook_Connection__c connection = getQBConnection();
        
        //Custom setting
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //mock data
        mockData();
        //Account list
        List<Account> accountList = [SELECT id from Account];
        
        //Insert QB Invoice       
        List<Quickbook_Invoice__c> qbInvoices = new List<Quickbook_Invoice__c>(); 
        qbInvoices.add(new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=accountList[0].Id,Sub_Total__c=100));
        qbInvoices.add(new Quickbook_Invoice__c(Name='1012', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=200,Balance_Due__c=300,Account__c=accountList[1].Id,Sub_Total__c=100));
        insert qbInvoices;
        
        //Create Service Lines record
        List<Quickbook_Service_Line__c> serviceLines = new List<Quickbook_Service_Line__c>();
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_1',Quickbook_Invoice_Id__c='183',Quickbook_Invoice__c=qbInvoices[0].Id,Rate__c=20000,Description__c='Test My Invoice'));
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_2',Quickbook_Invoice__c=qbInvoices[1].Id,Rate__c=40000,Description__c='Test My Invoice-2'));
        insert serviceLines;
            
        try {
            Test.startTest();
            QuickbookHttpMockResponse.CALLOUT_TYPE = 'error-callout';
            Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
            QuickbookService.createQuickBookInvoices(qbInvoices);
            Test.stopTest();
        } catch(Exception e) {
            System.assert(e.getMessage().contains('test error message'));
        }
    }
    
   /**
     * @ description: This method test last date of month. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void test_getLastDateOfMonth() {
      Date lastDate = QuickbookService.getLastDateOfMonth(); 
        System.assert(lastDate != null);
        
        Date nextMonthDate = lastDate.addDays(1);   
        System.assertEquals(1, nextMonthDate.day()); 
    }
    
     /** 
     * @ description: This method test GetTaxRefCode. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void test_getTaxRefCode() {
        
        //test when custom setting is not available
      	QuickbookTaxCodeRef taxRefCode = QuickbookService.getTaxRefCode(); 
        System.assert(taxRefCode != null);
        System.assertEquals('NON', taxRefCode.value);
        
        //Custom setting
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //test when custom setting is preset and quickbook type is sandbox
        taxRefCode = QuickbookService.getTaxRefCode(); 
        System.assert(taxRefCode != null);
        System.assertEquals('NON', taxRefCode.value);
        
        setting.IsTaxable__c = true;
        upsert setting;

        //test when custom setting is preset and quickbook type is production
        taxRefCode = QuickbookService.getTaxRefCode(); 
        System.assert(taxRefCode != null);
        System.assertEquals('26', taxRefCode.value);        
    }
    
    /**
     * @ description: This method test no service lines record exist on QB Invoice
     * @ return     : void
    **/
    @isTest
    public static void test_noServiceLineExists() {
        
        //QB Connection
        Quickbook_Connection__c connection = getQBConnection();
        
        //Custom setting
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //mock data
        mockData();
        //List of Accounts
        List<Account> prodly = [Select id From Account];
        
        Quickbook_Invoice__c invoice = new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[0].Id, Sub_Total__c=100,Quickbook_Invoice_Id__c='11');
        insert invoice;
        
        //test exception while upserting
        try{
            QuickbookService.setQBServiceLines(new Set<Id>{invoice.Id});
        } catch(QuickbookException e){
            System.assert(e.getMessage().contains('Quickbook Service Lines records not found!'));
        }
    }
    
    /**
     * @ description : This method test yesterday create event is happened on QB online
     * @ return      : void
    **/
    @isTest
    public static void test_getQBInvoicesChanges() {
        
        //Check no connection exist
        try{
            QuickbookService.getQBInvoicesChanges(null,'');
        }Catch(Exception e){
            System.assert(e.getMessage().contains(QuickbookConstants.CONNECTION_ERROR));
        }
        
        //QB Connection exist 
        Quickbook_Connection__c connection = getQBConnection();
        
         try{
            QuickbookService.getQBInvoicesChanges(connection,'');
        }Catch(Exception e){
            System.assert(e.getMessage().contains(QuickbookConstants.CUSTOM_SETTING_ERROR));
        }
        
        //QB Custom setting record
        QuickbookSetting__c setting = getQBCustomSetting();
        
        Test.startTest();
        //Call mock class
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'Yest-Invoice_callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        Test.stopTest();
        
        //Assert
        List<QuickbookInvoice> qbInvoices = QuickbookService.getQBInvoicesChanges(connection,'');
        System.assert(qbInvoices != null);
        System.assertEquals(qbInvoices[0].Id,'43');
    }
    
    /**
     * @ description : This method delete yesterday deleted Invoice record on QB online
     * @ return      : void
    **/
    @isTest
    public static void test_deleteInvoicesChanges() {
        
        Account accounts = new Account(Name='Test-3311',Quickbook_Customer_Id__c='1');
        insert accounts;
        
        //QB Connection exist 
        Quickbook_Connection__c connection = getQBConnection();
        
        //QB Custom setting record
        QuickbookSetting__c setting = getQBCustomSetting();
        
        //Insert QB Invoice       
        List<Quickbook_Invoice__c> qbInvoices = new List<Quickbook_Invoice__c>(); 
        qbInvoices.add(new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=accounts.Id,Sub_Total__c=100,Quickbook_Invoice_Id__c='62'));
        insert qbInvoices;
        
        //Create Service Lines record
        List<Quickbook_Service_Line__c> serviceLines = new List<Quickbook_Service_Line__c>();
        serviceLines.add(new Quickbook_Service_Line__c(Name='62_1',Quickbook_Invoice_Id__c='62',Quickbook_Invoice__c=qbInvoices[0].Id,Rate__c=20000,Description__c='Test My Invoice'));
        insert serviceLines;

        List<QuickbookInvoice> qbInvoices_1 = new List<QuickbookInvoice>();
        Test.startTest();
        //Call mock class
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'Yest-Deleted_Invoice';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        qbInvoices_1 = QuickbookService.getQBInvoicesChanges(connection,'');
        Test.stopTest();
                
        QuickbookService.upsertInvoicesResponse(qbInvoices_1,null,null);
        
        //QB Invoice records
        List<Quickbook_Invoice__c> invoiceRecs = [Select id, Name, Total_Amount__c, Balance_Due__c from Quickbook_Invoice__c];
        System.assertEquals(invoiceRecs.size(), 0);
        
        //Service Lines
        List<Quickbook_Service_Line__c> serviceLine = [Select id,Quickbook_Invoice_Id__c,Quickbook_Invoice__c,Name From Quickbook_Service_Line__c];
        System.assertEquals(serviceLine.size(),0);
    }
    
    //Create setup data   
    public static void mockData() {
        //Insert Account
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name='FEXLE Services Private Limited'));
        accounts.add(new Account(Name= 'Prodly Account', Quickbook_Customer_Id__c='59'));
        insert accounts;
    }
    
    //This method will return QB connection record
    public static Quickbook_Connection__c getQBConnection(){
        //QB Connection
        Quickbook_Connection__c connection = new Quickbook_Connection__c();
        connection.Company_Id__c = 'CompanyId';
        connection.Access_Token__c = 'accesstoken';
        connection.Refresh_Token__c = 'refreshtoken';
        connection.Token_Updated_At__c = DateTime.now();
        connection.Access_Token_Expires_In__c = 3600;
        connection.Refresh_Token_Expires_In__c = 180000;
        connection.Name = QuickbookConstants.CONNECTION_NAME;
        insert connection;
        return connection;
    }
    
    //Get QB custom setting record
    public static QuickbookSetting__c getQBCustomSetting(){
        QuickbookSetting__c setting = new QuickbookSetting__c();
        setting.ClientId__c = 'clientId';
        setting.ClientSecret__c = 'secret';
        setting.CDCBatchFrequencyINHours__c = 2;
        setting.SFToQBCallout__c = true;
        setting.QBToSFCallout__c = true;
        insert setting;
        return setting;
    }
}