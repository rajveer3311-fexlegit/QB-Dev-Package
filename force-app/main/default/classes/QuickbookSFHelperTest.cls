/**
 *  Purpose         : Test class for QuickbookSFHelper class
 *
 *  Created Date    : 09/08/2021
 *
 *  Created By      : Suresh Koumar
 *
 *  Revision Logs   : V_1.0 - Created 
 *                    V_1.1 - Last Modified By : Rajveer Singh Rawat - 12/10/2023 
 **/
@IsTest
public with sharing class QuickbookSFHelperTest {

    /**
     * @ description: This method test set quickbook connection object. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testSetQuickbookConnection() {
        Map<String, Object> response_Map = new Map<String, Object>();
        response_Map.put('access_token', 'token');
        response_Map.put('refresh_token', 'refreshtoken');
        response_Map.put('expires_in', 3600);
        response_Map.put('x_refresh_token_expires_in', 18000);
        
        //test for new connection sobject record created
        Quickbook_Connection__c testQuickBookConnection = QuickbookHelper.setQuickbookConnection(response_Map, null);
        System.assert(testQuickBookConnection != null);
        
        Quickbook_Connection__c quickBookConnection = new Quickbook_Connection__c();
        insert quickBookConnection; 
        
        //test for existing connection object updated
        testQuickBookConnection = QuickbookHelper.setQuickbookConnection(response_Map, quickBookConnection);
        System.assert(testQuickBookConnection != null);
        System.assertEquals('token', testQuickBookConnection.Access_Token__c);
        System.assertEquals('refreshtoken', testQuickBookConnection.Refresh_Token__c);
        System.assertEquals(3600, testQuickBookConnection.Access_Token_Expires_In__c);
        System.assertEquals(18000, testQuickBookConnection.Refresh_Token_Expires_In__c);   
    }
    
    /**
     * @ description: This method test getAccountByQuickbookCustomerId. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testGetAccountByQuickbookCustomerIds() {
        //mock data
        QuickbookServiceTest.mockData();
        Map<String,Account> accountsMap = QuickbookSFHelper.getAccountsByQuickbookCustomerIds(new Set<String>{'59'});
        System.assert(accountsMap != null);
        System.assertEquals('Prodly Account', accountsMap.values()[0].Name);
    }
    
    /**
     * @ description: This method test getAccountById. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testGetAccountById() {
        Account account = new Account(Name = 'Customer Account');
        insert account;
        
        Account accountObj = QuickbookSFHelper.getAccountById(account.Id);
        System.assert(accountObj != null);
        System.assertEquals('Customer Account', accountObj.Name);
    }
    
    /**
     * @ description  : This method test getAccountById. 
     * @ Added By     : Rajveer Singh Rawat
     * @ return       : void 
    **/
    @isTest
    public static void testGetAccountByIds() {
        //Insert Account record
        Account account = new Account(Name = 'Customer Account');
        insert account;
        
        Map<Id,Account> accountsMap = QuickbookSFHelper.getAccountByIds(new Set<Id>{account.Id});
        System.assert(accountsMap != null);
        System.assertEquals('Customer Account', accountsMap.values()[0].Name);
    }
    
    /**
     * @ description: This method test getQuickbookInvoiceByInvoiceId. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testGetQuickbookInvoiceByInvoiceId() {
        Account account = new Account(Name= 'Customer Account', Quickbook_Customer_Id__c='59');
        insert account;
        
        Quickbook_Invoice__c invoice = new Quickbook_Invoice__c(Account__c=account.Id, Quickbook_Invoice_Id__c='2');
        insert invoice;
        
        Quickbook_Invoice__c invoiceObj = QuickbookSFHelper.getQuickbookInvoiceByInvoiceId('2');
        System.assert(invoiceObj != null);
        System.assertEquals('2', invoiceObj.Quickbook_Invoice_Id__c);
    }
    
    /**
     * @ description  : This method test getQuickbookInvoiceById. 
     * @ Modified By  :  Rajveer Singh Rawat
     * @ return: void : 
    **/
    @isTest
    public static void testGetQuickbookInvoiceById() {
        Account account = new Account(Name= 'Customer Account', Quickbook_Customer_Id__c='59');
        insert account;
        
        Quickbook_Invoice__c invoice = new Quickbook_Invoice__c(Account__c=account.Id, Quickbook_Invoice_Id__c='2');
        insert invoice;
        
        Map<String, String> invoiceObj = QuickbookSFHelper.getQuickbookInvoiceById(invoice.Id);
        System.assert(invoiceObj != null);
    }
    
    /**
     * @ description: This method test getContactById. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testGetContactById() {
          //Modify By - Vikash - PM-1063 - 03/09/2023 - Changes added to Validation on contacts object
          //Start here
          Account acc = new Account(Name='Account-1');
          System.assert(acc != null);
          Contact contact = new Contact(FirstName= 'Customer',accountId = acc.Id , LastName='Account' ,
                                     	Aadhar_Card_Number__c = '123456789934' ,
                                        MobilePhone = QuickbookConstants.STR_PHONE_NUMBER ,
                                        Birthdate = System.today().addMonths(-150) ,
                                        Email = QuickbookConstants.CONTACT_EMAIL ,
                                        MailingStreet = QuickbookConstants.CONTACT_MAILINGSTREET ,
                                        MailingCity = QuickbookConstants.CONTACT_MAILINGCITY ,
                                        MailingState = QuickbookConstants.CONTACT_MAILINGSTATE ,
                                        MailingCountry = QuickbookConstants.CONTACT_MAILINGCOUNTRY ,
                                        MailingPostalCode = QuickbookConstants.CONTACT_MAILINGPOSTALCODE ,
                                        Gender__c = QuickbookConstants.GENDER , 
                                       	FEXLE_Anniversary_Date__c = System.today().addMonths(-30) ,
                               		Title = QuickbookConstants.CONTACT_ACCOUNTNAME);
        //Modify By - Vikash - PM-1063 - 03/09/2023 - Changes added to Validation on contacts object
        //End here
        insert contact;

        Contact contactObj = QuickbookSFHelper.getContactById(contact.Id);
        System.assert(contactObj != null);
        System.assertEquals('Customer Account', contactObj.Name);
    }
    
    /**
     * @ description: This method test Invoices records. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void test_getInvoices(){ 
        //Test start here
        Test.startTest();
        //mock data
        QuickbookServiceTest.mockData();
        List<Account> prodly = [SELECT id from Account where Name = 'Prodly Account'];
                
        Quickbook_Invoice__c invoice = new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[0].Id, Sub_Total__c=100,Quickbook_Invoice_Id__c='11');
        insert invoice;
        
        Map<String,Quickbook_Invoice__c> mapOfQB = QuickbookSFHelper.getQBInvoiceRecords(new Set<String>{invoice.Quickbook_Invoice_Id__c});
        System.assert(mapOfQB.keySet().Size() == 1);
        System.assert(mapOfQB != null);
        
        //Test stop here
        Test.stopTest();
    }
    
     /**
     * @ description: This method test set quickbook connection object. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void getQBConnection(){
        
        //QB connection setup
        Quickbook_Connection__c qb = QuickbookSFHelper.getQuickbookConnection();
        System.assert(qb == null);
        
        //Create QB connection record
        Quickbook_Connection__c connection = new Quickbook_Connection__c();
        connection.Company_Id__c = 'CompanyId';
        connection.Access_Token__c = 'accesstoken';
        connection.Refresh_Token__c = 'refreshtoken';
        connection.Token_Updated_At__c = DateTime.now();
        connection.Access_Token_Expires_In__c = 3600;
        connection.Refresh_Token_Expires_In__c = 180000;
        connection.Name = QuickbookConstants.CONNECTION_NAME;
        
        Test.startTest();
        insert connection;
        Quickbook_Connection__c qb_1 = QuickbookSFHelper.getQuickbookConnection();
        System.assert(qb_1 != null);
        System.assertEquals(connection.Company_Id__c, qb_1.Company_Id__c);
        Test.stopTest();
    }
    
    /**
     * @ description: This method test Invoices records. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void test_QBInvoiceIDS(){ 
        
        //Test start here
        Test.startTest();
        //mock data
        QuickbookServiceTest.mockData();
        List<Account> prodly = [SELECT id from Account where Name = 'Prodly Account'];
                
        Quickbook_Invoice__c invoice = new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[0].Id, Sub_Total__c=100,Quickbook_Invoice_Id__c='11');
        insert invoice;
        
        List<Quickbook_Invoice__c> listOfQB = QuickbookSFHelper.getQuickbookInvoiceIds(new Set<Id>{invoice.Id});
        System.assert(listOfQB != null);
        //Test stop here
        Test.stopTest();
    }
    
    //Test the use case of org type
    @isTest
    public static void test_redirectUrl(){
        String typeOfOrg = QuickbookSFHelper.getRedirectUrl();
        System.assert(typeOfOrg != null);
    }
    
    //Test the use case of contact
    @isTest
    public static void test_contact(){
        //Test start from here
        Test.startTest();
        //Create contact record
        Contact cont = new Contact(LastName='Test');
        insert cont;
        
        Map<Id,Contact> mapOfContacts = QuickbookSFHelper.getContactByIds(new Set<Id>{cont.Id});
        System.assert(mapOfContacts != null);
        
        //Test stop here
    }
    
    //Test the use case to insert record
    @isTest
    public static void test_upsertRecord(){
        //Test start here
        Test.startTest();
        //mock data
        QuickbookServiceTest.mockData();

        List<Account> prodly = [SELECT id from Account where Name = 'Prodly Account'];
                
        //Set QB Invoice data 
        Quickbook_Invoice__c invoice = new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[0].Id, Sub_Total__c=100,Quickbook_Invoice_Id__c='11');
        
        //QB Servic Lines
        List<Quickbook_Service_Line__c> linesObj = new List<Quickbook_Service_Line__c>();
        Quickbook_Service_Line__c lineObj = new Quickbook_Service_Line__c(Name=invoice.Name+ '_1', Activity__c='Hours',
                          Service_Date__c=System.today(), Description__c='test description', Hours__c=2,Rate__c=50,Amount__c=100, Quickbook_Invoice_Id__c='11');
        linesObj.add(lineObj);
        
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
        Test.stopTest();
        //Test stop here
    }
    
    //Test the use case to delete QB Invoice service lines
    @isTest
    public static void test_deleteQBServiceLines(){
       
        //Test start here
        Test.startTest();
        //mock data
        QuickbookServiceTest.mockData();

        //Accounts records
        List<Account> prodly = [SELECT id from Account];
         
        //List of QB Invoice data
        List<Quickbook_Invoice__c> qbInvoiceList = new List<Quickbook_Invoice__c>();
        qbInvoiceList.add(new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[0].Id, Sub_Total__c=100,Quickbook_Invoice_Id__c='11'));
        qbInvoiceList.add(new Quickbook_Invoice__c(Name='1012', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[1].Id, Sub_Total__c=200,Quickbook_Invoice_Id__c='12'));
        insert qbInvoiceList;
        
        //QB Service Lines
        List<Quickbook_Service_Line__c> linesObj = new List<Quickbook_Service_Line__c>();
        linesObj.add(new Quickbook_Service_Line__c(Quickbook_Invoice__c=qbInvoiceList[0].Id,Name=qbInvoiceList[0].Quickbook_Invoice_Id__c+ '_1', Activity__c='Hours',
                          Service_Date__c=System.today(), Description__c='test description', Hours__c=2,Rate__c=50,Amount__c=100, Quickbook_Invoice_Id__c='11'));
        linesObj.add(new Quickbook_Service_Line__c(Quickbook_Invoice__c=qbInvoiceList[0].Id,Name=qbInvoiceList[0].Quickbook_Invoice_Id__c+ '_2', Activity__c='Hours',
                          Service_Date__c=System.today(), Description__c='test description', Hours__c=3,Rate__c=500,Amount__c=200, Quickbook_Invoice_Id__c='12'));
        insert linesObj;
        
        QuickbookSFHelper.deleteServiceLines(new List<Id>{qbInvoiceList[0].Id,qbInvoiceList[1].Id});
        
        //Test stop here
        Test.stopTest();  
        
        List<Quickbook_Invoice__c> invoices = [select id,Name,Sub_Total__c, Account__c, Total_Amount__c from Quickbook_Invoice__c];
        System.assert(invoices != null);
        System.assert(invoices.size() == 2);
        
        List<Quickbook_Service_Line__c> invoiceLines = [select id From Quickbook_Service_Line__c];
        System.assert(invoiceLines.isEmpty());
    }
    
    //Test the use case to get QB service lines 
    @isTest
    public static void test_getQBServiceLines(){
       
        //Test start here
        Test.startTest();
        //mock data
        QuickbookServiceTest.mockData();

        //Accounts records
        List<Account> prodly = [SELECT id from Account];
         
        //List of QB Invoice data
        List<Quickbook_Invoice__c> qbInvoiceList = new List<Quickbook_Invoice__c>();
        qbInvoiceList.add(new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[0].Id, Sub_Total__c=100,Quickbook_Invoice_Id__c='11'));
        qbInvoiceList.add(new Quickbook_Invoice__c(Name='1012', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[1].Id, Sub_Total__c=200,Quickbook_Invoice_Id__c='12'));
        insert qbInvoiceList;
        
        //QB Service Lines
        List<Quickbook_Service_Line__c> linesObj = new List<Quickbook_Service_Line__c>();
        linesObj.add(new Quickbook_Service_Line__c(Quickbook_Invoice__c=qbInvoiceList[0].Id,Name=qbInvoiceList[0].Quickbook_Invoice_Id__c+ '_1', Activity__c='Hours',
                          Service_Date__c=System.today(), Description__c='test description', Hours__c=2,Rate__c=50,Amount__c=100, Quickbook_Invoice_Id__c='11'));
        linesObj.add(new Quickbook_Service_Line__c(Quickbook_Invoice__c=qbInvoiceList[0].Id,Name=qbInvoiceList[0].Quickbook_Invoice_Id__c+ '_2', Activity__c='Hours',
                          Service_Date__c=System.today(), Description__c='test description', Hours__c=3,Rate__c=500,Amount__c=200, Quickbook_Invoice_Id__c='12'));
        insert linesObj;
        
        Map<Id,List<Quickbook_Service_Line__c>> mapOfServiceLines = QuickbookSFHelper.getQBServiceLines(new Set<Id>{qbInvoiceList[0].Id,qbInvoiceList[1].Id});
        System.assert(mapOfServiceLines != null);
        System.assert(mapOfServiceLines.size() == 1);
        
        //Test stop here
        Test.stopTest();  
    }
    
    //Test the use case to delete QB Invoices records
    @isTest
    public static void test_deleteQBInvoices(){
       
        //Test start here
        Test.startTest();
        //mock data
        QuickbookServiceTest.mockData();

        //Accounts records
        List<Account> prodly = [SELECT id from Account];
         
        //List of QB Invoice data
        List<Quickbook_Invoice__c> qbInvoiceList = new List<Quickbook_Invoice__c>();
        qbInvoiceList.add(new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[0].Id, Sub_Total__c=100,Quickbook_Invoice_Id__c='11'));
        qbInvoiceList.add(new Quickbook_Invoice__c(Name='1012', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=prodly[1].Id, Sub_Total__c=200,Quickbook_Invoice_Id__c='12'));
        insert qbInvoiceList;
        
        //QB Service Lines
        List<Quickbook_Service_Line__c> linesObj = new List<Quickbook_Service_Line__c>();
        linesObj.add(new Quickbook_Service_Line__c(Quickbook_Invoice__c=qbInvoiceList[0].Id,Name=qbInvoiceList[0].Quickbook_Invoice_Id__c+ '_1', Activity__c='Hours',
                          Service_Date__c=System.today(), Description__c='test description', Hours__c=2,Rate__c=50,Amount__c=100, Quickbook_Invoice_Id__c='11'));
        linesObj.add(new Quickbook_Service_Line__c(Quickbook_Invoice__c=qbInvoiceList[0].Id,Name=qbInvoiceList[0].Quickbook_Invoice_Id__c+ '_2', Activity__c='Hours',
                          Service_Date__c=System.today(), Description__c='test description', Hours__c=3,Rate__c=500,Amount__c=200, Quickbook_Invoice_Id__c='12'));
        insert linesObj;
        
        QuickbookSFHelper.deleteInvoiceRecords(new Set<String>{qbInvoiceList[0].Quickbook_Invoice_Id__c,qbInvoiceList[1].Quickbook_Invoice_Id__c});
        
        //Test stop here
        Test.stopTest();  
        
        List<Quickbook_Invoice__c> invoices = [select id,Name,Sub_Total__c, Account__c, Total_Amount__c from Quickbook_Invoice__c];
        System.assert(invoices.isEmpty());
        
        List<Quickbook_Service_Line__c> invoiceLines = [select id From Quickbook_Service_Line__c];
        System.assert(invoiceLines.isEmpty());
    }
    
    //Test the use case to create QB Invoice by record Id
    @isTest
    public static void test_createQB_InvoiceById(){
       
       //QB Connection
        Quickbook_Connection__c connection = QuickbookServiceTest.getQBConnection();
        
        //Custom setting
        QuickbookSetting__c setting = QuickbookServiceTest.getQBCustomSetting();
        
        //mock data
        QuickbookServiceTest.mockData();
        
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
        QuickbookSFHelper.createQuickBookInvoiceFromLWC(qbInvoices[0].Id);
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
}