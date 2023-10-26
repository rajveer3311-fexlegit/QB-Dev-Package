/**
*  Purpose         : This class is scheduled whenever we need to send SF Invoives data to QuickBook online account 
*                    It will create Invoice record same as exist in SF org
*
*  Created Date    : 27/09/2023
*
*  Created By      : Rajveer Singh Rawat
*
*  Revision Logs   : V1.0 - Created
*
**/
global with sharing class Batch_createAllSFInvoicesOnQuickBook implements Database.Batchable<sObject>,Database.AllowsCallouts{
   
   //Fetch all the SF org Invoices record 
   public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, 
                                         LastActivityDate, LastViewedDate, LastReferencedDate, Account__c, Balance_Due__c, Due_Date__c, Invoice_Date__c, Quickbook_Invoice_Id__c, 
                                         Quickbook_Status_Backend__c, Sub_Total__c, Tax__c, Account__r.Quickbook_Customer_Id__c, Total_Amount__c, Quickbook_Invoice_Link__c, Status__c 
                                         From Quickbook_Invoice__c Where Id != null WITH SECURITY_ENFORCED]);
    }
    
    public void execute(Database.BatchableContext bc, List<Quickbook_Invoice__c> quickBookInvoices){
        //Call this method to create QuickBook invoices records on QuickBook online account
        QuickbookService.createQuickBookInvoices(quickBookInvoices); 
    }
    
    //Execute any post-processing operations
    public void finish(Database.BatchableContext bc){}
}