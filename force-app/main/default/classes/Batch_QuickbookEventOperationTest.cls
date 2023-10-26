/**
*  Purpose         : This class is the test class for Batch_QuickbookEventOperation
*
*  Created Date    : 20/10/2023
*
*  Created By      : Rajveer Singh Rawat
*
*  Revision Logs   : V1.0 - Created 
*
**/
@isTest
public class Batch_QuickbookEventOperationTest {
    
    /**
     * @ description : This method test the use case when no connection record exist
     * @ return      : void
    **/
    @isTest
    public static void test_noConnectionExist() {
        //Check no connection exist
        try{
            Test.startTest();
            Database.executebatch(new Batch_QuickbookEventOperation(new List<QuickbookInvoice>()));
            Test.stopTest();
        }Catch(Exception e){
            System.assert(e.getMessage().contains(QuickbookConstants.CONNECTION_ERROR));
        }
    }
    
     /**
     * @ description : This method test the use case when no connection record exist
     * @ return      : void
    **/
    @isTest
    public static void test_noCustomSettingExist() {
        //QB Connection exist 
        Quickbook_Connection__c connection = getQBConnection();
        try{
            Test.startTest();
            Database.executebatch(new Batch_QuickbookEventOperation(new List<QuickbookInvoice>()));
            Test.stopTest();
        }Catch(Exception e){
            System.assert(e.getMessage().contains(QuickbookConstants.CUSTOM_SETTING_ERROR));
        }
    }
    
    /**
     * @ description : This method test yesterday create event is happened on QB online
     * @ return      : void
    **/
    @isTest
    public static void test_getQBInvoicesChanges() {
        
        //QB Connection exist 
        Quickbook_Connection__c connection = getQBConnection();
        
        //QB Custom setting record
        QuickbookSetting__c setting = getQBSetting();
        
        //Call mock data
        mockData();    

        Test.startTest();
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'Yest-Invoice_callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        Database.executebatch(new Batch_QuickbookEventOperation(new List<QuickbookInvoice>()));
        Test.stopTest();
        
        //Assert
        List<QuickbookInvoice> qbInvoices = QuickbookService.getQBInvoicesChanges(connection,'');
        System.assert(qbInvoices != null);
        System.assertEquals(qbInvoices[0].Id,'43');
    }
    
    /**
     * @ description : This method delete yesterday Invoice record on QB online
     * @ return      : void
    **/
    @isTest
    public static void test_deleteInvoicesChanges() {
        
        mockData();
        List<Account> accounts = [Select id From Account Where Quickbook_Customer_Id__c='1'];
        //QB Connection exist 
        Quickbook_Connection__c connection = getQBConnection();
        
        //QB Custom setting record
        QuickbookSetting__c setting = getQBSetting();
        
        //Insert QB Invoice       
        List<Quickbook_Invoice__c> qbInvoices = new List<Quickbook_Invoice__c>(); 
        qbInvoices.add(new Quickbook_Invoice__c(Name='1011', Invoice_Date__c=System.today(),Due_Date__c=System.today(),
                            Total_Amount__c=100,Balance_Due__c=100,Account__c=accounts[0].Id,Sub_Total__c=100,Quickbook_Invoice_Id__c='62'));
        insert qbInvoices;
        
        //Create Service Lines record
        List<Quickbook_Service_Line__c> serviceLines = new List<Quickbook_Service_Line__c>();
        serviceLines.add(new Quickbook_Service_Line__c(Name='62_1',Quickbook_Invoice_Id__c='62',Quickbook_Invoice__c=qbInvoices[0].Id,Rate__c=20000,Description__c='Test My Invoice'));
        insert serviceLines;
        
        Test.startTest();
        
        //Call mock class
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'Yest-Deleted_Invoice';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        Database.executebatch(new Batch_QuickbookEventOperation(new List<QuickbookInvoice>()));
        
        Test.stopTest();
                        
        //QB Invoice records
        List<Quickbook_Invoice__c> invoiceRecs = [Select id, Name, Total_Amount__c, Balance_Due__c from Quickbook_Invoice__c];
        System.assertEquals(invoiceRecs.size(), 0);
        
        //Service Lines
        List<Quickbook_Service_Line__c> serviceLine = [Select id,Quickbook_Invoice_Id__c,Quickbook_Invoice__c,Name From Quickbook_Service_Line__c];
        System.assertEquals(serviceLine.size(),0);
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
        setting.CDCBatchFrequencyINHours__c = 40;
        setting.SFToQBCallout__c = true;
        setting.QBToSFCallout__c = true;
        insert setting;
        return setting;
    }
    
    //Create all setup records
    public static void mockData() {
        //Create account records
        List<Account> listOfAccounts = new List<Account>();
        listOfAccounts.add(new Account(Name='FEXLE Services Private Limited',Active__c='true',Quickbook_Customer_Id__c='1'));
        insert listOfAccounts;
    }
}