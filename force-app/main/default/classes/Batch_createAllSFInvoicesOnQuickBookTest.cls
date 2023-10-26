/**
*  Purpose         : This class is the test class of Batch_createAllSFInvoicesOnQuickBook
*
*  Created Date    : 25/09/2023
*
*  Created By      : Rajveer Singh Rawat
*
*  Revision Logs   : V1.0 - Created
*
**/
@isTest
public class Batch_createAllSFInvoicesOnQuickBookTest {
    
    //This method will put the SF record and insert into QB online Invoice record
    @isTest
    public static void Test_createAllInvoicesIntoQB(){
        //setup data 
        mockData();
        //Query Account records
        List<Account> accountlist = [Select Name,Quickbook_Customer_Id__c From Account Where Name = 'FEXLE Services Private Limited' Order By Quickbook_Customer_Id__c];
        //Get Contact records
        List<Contact> listOfContact = [Select id,Name From Contact Where LastName IN ('Contact1','Contact2')];
        //QuickBook Custom setting 
        QuickbookSetting__c qbSetting = getQBSetting();
        //QuickBook connection 
        Quickbook_Connection__c connection = getQBConnection();
        
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
        Database.executeBatch(new Batch_createAllSFInvoicesOnQuickBook(), 98);
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
    
    
    //This method will test when no custom setting record exist
    @isTest
    public static void Test_noSFToQBCalloutAllow(){
         
        //QuickBook Custom setting 
        QuickbookSetting__c qbSetting = getQBSetting();
        qbSetting.SFToQBCallout__c = false;
        update qbSetting;
         
        //setup data 
        mockData();
        
        //Query Account records
        List<Account> accountlist = [Select Name,Quickbook_Customer_Id__c From Account Where Name = 'FEXLE Services Private Limited' Order By Quickbook_Customer_Id__c];
        
        //List of QB Invoice
        List<Quickbook_Invoice__c> listOfqbInvoices = new List<Quickbook_Invoice__c>();
        listOfqbInvoices.add(new Quickbook_Invoice__c(Account__c=accountlist[0].Id,Invoice_Date__c=System.today().addMonths(-3)));
        listOfqbInvoices.add(new Quickbook_Invoice__c(Account__c=accountlist[1].Id,Invoice_Date__c=System.today().addMonths(-3)));
        insert listOfqbInvoices;
        
        //Create Service Lines record
        List<Quickbook_Service_Line__c> serviceLines = new List<Quickbook_Service_Line__c>();
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_1',Quickbook_Invoice__c=listOfqbInvoices[0].Id,Rate__c=20000,Description__c='Test My Invoice'));
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_2',Quickbook_Invoice__c=listOfqbInvoices[1].Id,Rate__c=40000,Description__c='Test My Invoice-2'));
        insert serviceLines;
        
        List<Quickbook_Invoice__c> listOfInvoices = [Select Id From Quickbook_Invoice__c];
        System.assertEquals(listOfInvoices.size(),2);
        
        //QuickBook connection 
        Quickbook_Connection__c connection = getQBConnection(); 
        
        Test.startTest();
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'QB-invoice-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        //Execute batch
        Database.executeBatch(new Batch_createAllSFInvoicesOnQuickBook(), 95); 
        Test.stopTest();
    }   
    
    //This method will test when no QB connection record exist
    @isTest
    public static void test_noConnection(){
        //setup data 
        mockData();
        //Query Account records
        List<Account> accountlist = [Select Name,Quickbook_Customer_Id__c From Account Where Name = 'FEXLE Services Private Limited' Order By Quickbook_Customer_Id__c];
        //Get Contact records
        List<Contact> listOfContact = [Select id,Name From Contact Where LastName IN ('Contact1','Contact2')];
        
        //List of QB Invoice
        List<Quickbook_Invoice__c> listOfqbInvoices = new List<Quickbook_Invoice__c>();
        listOfqbInvoices.add(new Quickbook_Invoice__c(Account__c=accountlist[0].Id,Invoice_Date__c=System.today().addMonths(-3)));
        listOfqbInvoices.add(new Quickbook_Invoice__c(Account__c=accountlist[1].Id,Invoice_Date__c=System.today().addMonths(-3)));
        insert listOfqbInvoices;
        
        //Create Service Lines record
        List<Quickbook_Service_Line__c> serviceLines = new List<Quickbook_Service_Line__c>();
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_1',Quickbook_Invoice__c=listOfqbInvoices[0].Id,Rate__c=20000,Description__c='Test My Invoice'));
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_2',Quickbook_Invoice__c=listOfqbInvoices[1].Id,Rate__c=40000,Description__c='Test My Invoice-2'));
        insert serviceLines;
        
         //QuickBook connection 
        QuickbookSetting__c setting = getQBSetting();
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'QB-invoice-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        try{
            Test.startTest();
            //Execute batch
            Database.executeBatch(new Batch_createAllSFInvoicesOnQuickBook(), 98); 
            Test.stopTest();
        }Catch(Exception e){
            System.assert(e.getMessage().contains(QuickbookConstants.CONNECTION_ERROR));
        }
    }
    
    //This method will test the 400 error
    @isTest
    public static void Test_error400_Exception(){
        //setup data 
        mockData();
        //Query Account records
        List<Account> accountlist = [Select Name,Quickbook_Customer_Id__c From Account Where Name = 'FEXLE Services Private Limited' Order By Quickbook_Customer_Id__c];
        //Get Contact records
        List<Contact> listOfContact = [Select id,Name From Contact Where LastName IN ('Contact1','Contact2')];
       
        //QuickBook Custom setting 
        QuickbookSetting__c qbSetting = getQBSetting();
        //QuickBook connection 
        Quickbook_Connection__c connection = getQBConnection();
        
        //List of QB Invoice
        List<Quickbook_Invoice__c> listOfqbInvoices = new List<Quickbook_Invoice__c>();
        listOfqbInvoices.add(new Quickbook_Invoice__c(Account__c=accountlist[0].Id,Invoice_Date__c=System.today().addMonths(-3)));
        listOfqbInvoices.add(new Quickbook_Invoice__c(Account__c=accountlist[1].Id,Invoice_Date__c=System.today().addMonths(-3)));
        insert listOfqbInvoices;
        
        //Create Service Lines record
        List<Quickbook_Service_Line__c> serviceLines = new List<Quickbook_Service_Line__c>();
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_1',Quickbook_Invoice__c=listOfqbInvoices[0].Id,Rate__c=20000,Description__c='Test My Invoice'));
        serviceLines.add(new Quickbook_Service_Line__c(Name='SL_2',Quickbook_Invoice__c=listOfqbInvoices[1].Id,Rate__c=40000,Description__c='Test My Invoice-2'));
        insert serviceLines;
        
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'error-callout';
       	Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        try{
            Test.startTest();
            //Execute batch
            Database.executeBatch(new Batch_createAllSFInvoicesOnQuickBook(), 98);
            Test.stopTest();
            //Test stop here
        }Catch(Exception e){
            System.assert(e.getMessage().contains('test error message'));
        }
    }   
    
    //Get QB connection record 
    public static Quickbook_Connection__c getQBConnection(){
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
    
    //Get QuickBook custom setting record
    public static QuickbookSetting__c getQBSetting(){
        //Test when custom setting is present 
        QuickbookSetting__c setting = new QuickbookSetting__c();
        setting.ClientId__c = 'clientId';
        setting.ClientSecret__c = 'secret';
        setting.CDCBatchFrequencyINHours__c = 2;
        setting.SFToQBCallout__c = true;
        setting.QBToSFCallout__c = true;
        insert setting;
        return setting;
    }
    
    //Setup all data
    public static void mockData() {
        //Create account records
        List<Account> listOfAccounts = new List<Account>();
        listOfAccounts.add(new Account(Name='FEXLE Services Private Limited',Active__c='true',Quickbook_Customer_Id__c='59'));
        listOfAccounts.add(new Account(Name='FEXLE Services Private Limited',Active__c='true',Quickbook_Customer_Id__c='2'));
        insert listOfAccounts;
        
        //Create contact records
        List<Contact> listOfContact = new List<Contact>();
        listOfContact.add(new Contact(LastName='Contact1',AccountId=listOfAccounts[0].Id));
        listOfContact.add(new Contact(LastName='Contact2',AccountId=listOfAccounts[1].Id));
        insert listOfContact;        
    }
}