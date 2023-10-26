/**
*  Purpose         : This class is scheduled whenever any event occur QB online in 24 hr it will reflect the event on SF org.
*
*  Created Date    : 20/10/2023
*
*  Created By      : Rajveer Singh Rawat
*
*  Revision Logs   : V1.0 - Created
*
**/
global with sharing class Batch_QuickbookEventOperation implements Database.Batchable<QuickbookInvoice>,Database.AllowsCallouts,Database.Stateful{
   
    global List<QuickbookInvoice> listOfQBInvoices = new List<QuickbookInvoice>();
    
    //Get the QuickBook connection record for the API calling setup 
    Quickbook_Connection__c quickBookConnection = QuickbookHelper.getQuickbookConnection();
    
    //Change start position after every 1000 records
    public Batch_QuickbookEventOperation(List<QuickbookInvoice> listOfInvoices){
        listOfQBInvoices = listOfInvoices;
    }
    
    public Iterable<QuickbookInvoice> start(Database.BatchableContext bc) { 
        
        //List of QB Invoices
        listOfQBInvoices = listOfQBInvoices.size() == 0 ? QuickbookService.getQBInvoicesChanges(quickBookConnection,'') : listOfQBInvoices;
        return listOfQBInvoices;
    }
    
    //This method will make the events on SF org 
    public void execute(Database.BatchableContext bc, List<QuickbookInvoice> quickBookInvoices){
        //This method will insert/update/delete QB Invoice and service Lines record 
        QuickBookService.upsertInvoicesResponse(quickBookInvoices,null,null);
    }
    
    //Execute any post-processing operations
    public void finish(Database.BatchableContext bc){
        
        //Check list size
        if(listOfQBInvoices.size() >= 1000 || Test.isRunningTest()){
            String lastRecordDateTime;
            for(QuickbookInvoice qb : listOfQBInvoices){
                if(qb.status != 'Deleted'){
                    lastRecordDateTime = qb.MetaData.LastUpdatedTime;
                }
            }
            //Call this method to get next date data
            listOfQBInvoices = QuickbookService.getQBInvoicesChanges(quickBookConnection,lastRecordDateTime);
            if(!Test.isRunningTest())
                Database.executeBatch(new Batch_QuickbookEventOperation(listOfQBInvoices));
        }
    }
}