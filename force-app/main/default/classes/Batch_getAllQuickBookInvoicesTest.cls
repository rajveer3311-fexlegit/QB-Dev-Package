/**
*  Purpose         : This class is the test class for Batch_getAllQuickBookInvoices
*
*  Created Date    : 25/09/2023
*
*  Created By      : Rajveer Singh Rawat
*
*  Revision Logs   : V1.0 - Created
*
**/
@isTest
public class Batch_getAllQuickBookInvoicesTest {
    
    //This method will get the invoice data from Quickbook online and insert record here
    @isTest
    public static void test_getInvoices() {
        
        //setup data 
        mockData();
         //Query Account records
        List<Account> accountlist = [Select Name,Quickbook_Customer_Id__c From Account Where Name = 'FEXLE Services Private Limited' Order By Quickbook_Customer_Id__c];
        
        //QuickBook Custom setting 
        QuickbookSetting__c qbSetting = getQBSetting();
        //QuickBook connection 
        Quickbook_Connection__c connection = getQBConnection();
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'QB-invoice-No-SerLine-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        Test.StartTest();          
        //Execute batch
        Database.executeBatch(new Batch_getAllQuickBookInvoices(1,null));
        Test.stopTest();
        
        //Inserted records
        //QB Invoice records
        List<Quickbook_Invoice__c> invoiceRecs = [Select id, Name, Total_Amount__c, Balance_Due__c from Quickbook_Invoice__c];
        //Service Lines
        List<Quickbook_Service_Line__c> serviceLines = [Select id,Quickbook_Invoice_Id__c,Quickbook_Invoice__c,Name From Quickbook_Service_Line__c];
        System.assertEquals(invoiceRecs.size(), 1);
        System.assertEquals(invoiceRecs[0].Name, 'IN-1075');
        System.assertEquals(serviceLines.size(), 1);
        System.assertEquals(serviceLines[0].Quickbook_Invoice__c, invoiceRecs[0].Id);
    }
    
    //This method will test the Invoice record with no service lines
    @isTest
    public static void test_getInvoicesNoLines() {
        
        //QuickBook Custom setting 
        QuickbookSetting__c qbSetting = getQBSetting();
        //QuickBook connection 
        Quickbook_Connection__c connection = getQBConnection();
        
        Test.startTest();
        //Execute batch
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'No-invoice-Lines';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        // Start the batch job
        try{
            Batch_getAllQuickBookInvoices batchInstance = new Batch_getAllQuickBookInvoices(1,null);
            Id batchJobId = Database.executeBatch(batchInstance);
            Test.stopTest();
        }catch(Exception e){
            System.assertEquals(e.getMessage(), 'Required lines data not found.');
        }
    }
    
    //This method will test the Invoice record with no customer references 
    @isTest
    public static void test_NoCustomerRef() {
        
        //setup data 
        mockData();
        
        //QuickBook Custom setting 
        QuickbookSetting__c qbSetting = getQBSetting();
        //QuickBook connection 
        Quickbook_Connection__c connection = getQBConnection();
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'NoCustomer-invoice-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        Try{
            Test.StartTest();  
            //Execute batch
            Database.executeBatch(new Batch_getAllQuickBookInvoices(1,null));
            Test.stopTest();
        }Catch(Exception e){
            System.assertEquals(e.getMessage(), 'Required SF account with Quickbook customer id');
        } 
    }
    
    //This method will test the Invoice record have improper descriptions
    @isTest
    public static void test_improperDescription() {
        
        //setup data 
        mockData();
        
        //QuickBook Custom setting 
        QuickbookSetting__c qbSetting = getQBSetting();
        //QuickBook connection 
        Quickbook_Connection__c connection = getQBConnection();

        QuickbookHttpMockResponse.CALLOUT_TYPE = 'QB-ImpDescription-invoice-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        Test.StartTest();  
        //Execute batch
        Database.executeBatch(new Batch_getAllQuickBookInvoices(1,null));
        Test.stopTest();
        
        //Inserted records
        //QB Invoice records
        List<Quickbook_Invoice__c> invoiceRecs = [Select id, Name, Total_Amount__c,Sub_Total__c,Balance_Due__c from Quickbook_Invoice__c];
        
        //Service Lines
        List<Quickbook_Service_Line__c> serviceLines = [Select id,Quickbook_Invoice_Id__c,Quickbook_Invoice__c,Name From Quickbook_Service_Line__c];
        System.assertEquals(invoiceRecs.size(), 1);
        System.assertEquals(invoiceRecs[0].Name, 'IN-1075');
        System.assertEquals(invoiceRecs[0].Sub_Total__c, 4500);
        System.assertEquals(serviceLines.size(), 0);
    }
    
    //This method will test the Invoice record have no descriptions
    @isTest
    public static void test_NoDescription() {
        
        //setup data 
        mockData();
        
        //QuickBook Custom setting 
        QuickbookSetting__c qbSetting = getQBSetting();
        //QuickBook connection 
        Quickbook_Connection__c connection = getQBConnection();
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'No-Desc-invoice-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        Try{
            Test.StartTest();  
            //Execute batch
            Database.executeBatch(new Batch_getAllQuickBookInvoices(1,null));
            Test.stopTest();
        }Catch(Exception e){
            System.assert(e.getMessage().contains('Line description not available for invoice record'));
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
    
    //Create all setup records
    public static void mockData() {
        //Create account records
        List<Account> listOfAccounts = new List<Account>();
        listOfAccounts.add(new Account(Name='FEXLE Services Private Limited',Active__c='true',Quickbook_Customer_Id__c='59'));
        listOfAccounts.add(new Account(Name='FEXLE Services Private Limited',Active__c='true',Quickbook_Customer_Id__c='2'));
        insert listOfAccounts;
    }
}