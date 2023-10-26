/**
*  Purpose         : This class is scheduled whenever we need to create all QuickBook online account Invoices record into SF org
*
*  Created Date    : 25/09/2023
*
*  Created By      : Rajveer Singh Rawat
*
*  Revision Logs   : V1.0 - Created
*
**/
global with sharing class Batch_getAllQuickBookInvoices implements Database.Batchable<QuickbookInvoice>,Database.AllowsCallouts,Database.Stateful{
    
    //Set starting position 
    global Integer startingPosn;
    //Stop the batch when value is true
    global Boolean stopBatch;
    global List<QuickbookInvoice> listOfQBInvoice;
    
    //Get the QuickBook connection record for the API calling setup 
    Quickbook_Connection__c quickBookConnection = QuickbookHelper.getQuickbookConnection();
    
    //Change start position after every 1000 records
    public Batch_getAllQuickBookInvoices(Integer startPosn,List<QuickbookInvoice> listOfInvoices){
        startingPosn = startPosn;
        listOfQBInvoice = listOfInvoices;
    }
    
    public Iterable<QuickbookInvoice> start(Database.BatchableContext bc) { 
        
        //Quickbook Invoices records
        listOfQBInvoice = startingPosn == 1 ? QuickBookService.getInvoicesData(quickBookConnection,startingPosn,null) : listOfQBInvoice;
        if(listOfQBInvoice == null || listOfQBInvoice.isEmpty() || listOfQBInvoice.size() < 1000)
            stopBatch = true;
        else
            stopBatch = false;
        return listOfQBInvoice != null ? listOfQBInvoice : null;
    }
    
    public void execute(Database.BatchableContext bc, List<QuickbookInvoice> quickBookInvoices){
        //This method will insert QB Invoice and service Lines record 
        QuickBookService.upsertInvoicesResponse(quickBookInvoices,null,null);
    }
    
    //execute any post-processing operations
    public void finish(Database.BatchableContext bc){

        //Increament 1000 every time
        startingPosn+=1000;

        //Get next Quickbook Invoices records
        if(listOfQBInvoice != null){
            listOfQBInvoice = QuickBookService.getInvoicesData(quickBookConnection,startingPosn,null);
            if(listOfQBInvoice == null || listOfQBInvoice.isEmpty())
                stopBatch = true;
            else
                stopBatch = false; 
        }
        
        //Running batch in chain until empty record
        if(!stopBatch && !Test.isRunningTest()){ 
            Database.executeBatch(new Batch_getAllQuickBookInvoices(startingPosn,listOfQBInvoice),200);
        }
    }
}