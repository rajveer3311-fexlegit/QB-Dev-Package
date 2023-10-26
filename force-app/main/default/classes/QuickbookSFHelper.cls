/**
*  Purpose         :   This class is responsible for Quickbook related Salesforce operations
*
*  Created Date    :   09/08/2021
*
*  Created By      :   Suresh Koumar
*
*  Revision Logs   :   V_1.0 - Created
*                      V_1.1 - Last Modified By : Rajveer Singh Rawat - 12/10/2023 
*
**/
public with sharing class QuickbookSFHelper {

   /**  
     * @ description                : This method returns quickbook connection object.  
     *   
     * @ return: String           : redirect url
    **/    
    public static Quickbook_Connection__c getQuickbookConnection() {
        List<Quickbook_Connection__c> quickBookConnections = [Select Id, Name, Company_Id__c, Access_Token__c, Refresh_Token__c, Token_Updated_At__c,
            Access_Token_Expires_In__c, Refresh_Token_Expires_In__c From Quickbook_Connection__c where Name =: QuickbookConstants.CONNECTION_NAME WITH SECURITY_ENFORCED limit 1];
        if(quickBookConnections != null &&  !quickBookConnections.isEmpty() ) {
            return quickBookConnections[0];            
        } else {
            return null;
        }
    }
    
   /**  
     * @ description                : This method returns redirect url as per org type.  
     *   
     * @ return: String           : redirect url
    **/    
    public static String getRedirectUrl(){
        boolean orgType = [SELECT Id, IsSandbox from Organization LIMIT 1].IsSandbox;
        if(orgType) {
            return QuickbookConstants.SF_SANDBOX;
        } else {
            return QuickbookConstants.SF_PRODUCTION;
        }
    }
    
    /**
     * @ description            : This method finds the Quickbook Service Line
     * @ args: Set ID           : QB Invoice IDs
     * 
     * @ return                 : Map of Service line Id and List of Service lines       : 
    **/
    public static Map<Id,List<Quickbook_Service_Line__c>> getQBServiceLines(Set<Id> qbIds) {
        Map<Id,List<Quickbook_Service_Line__c>> mapOfQBIdAndServiceLines = new Map<Id,List<Quickbook_Service_Line__c>>();
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE,[Select id,Name,Service_Date__c,Resource__c,Rate__c,Quickbook_Invoice_Id__c,Quickbook_Invoice__c,Hours__c,Description__c,Activity__c,Amount__c From Quickbook_Service_Line__c where Quickbook_Invoice__c IN :qbIds WITH SECURITY_ENFORCED]);
        for(Quickbook_Service_Line__c serviceLine : (List<Quickbook_Service_Line__c>)securityDecision.getRecords()){
            if(!mapOfQBIdAndServiceLines.containsKey(serviceLine.Quickbook_Invoice__c))
                mapOfQBIdAndServiceLines.put(serviceLine.Quickbook_Invoice__c,new List<Quickbook_Service_Line__c>{serviceLine});
            else
                mapOfQBIdAndServiceLines.get(serviceLine.Quickbook_Invoice__c).add(serviceLine);
        }
        return mapOfQBIdAndServiceLines;
    } 
    
    /** 
     * @ description              : This method returns quickbook customer account sobject. 
     * @ args: Set<String>        : customerRef value 
     * @ Added By                 : Rajveer Singh Rawat
     * @ return                   : Account   
    **/ 
    public static Map<String,Account> getAccountsByQuickbookCustomerIds(Set<String> setOfCustRef) {
        Map<String,Account> mapOfCustIDsAndAccounts = new Map<String,Account>(); 
        for(Account acc : [select id,Quickbook_Customer_Id__c, Name from Account where Quickbook_Customer_Id__c IN :setOfCustRef]){
            mapOfCustIDsAndAccounts.put(acc.Quickbook_Customer_Id__c,acc);
        }
        return (mapOfCustIDsAndAccounts != null && !mapOfCustIDsAndAccounts.isEmpty()) ? mapOfCustIDsAndAccounts : null;
    }
    
    /** 
     * @ description              : This method returns account sobject by id. 
     * @ args: String          : Account id value 
     *  
     * @ return                   : Account   
    **/ 
    public static Account getAccountById(String recordId) {
        return [SELECT Quickbook_Customer_Id__c, Name from Account where Id =: recordId];
    }
    
    public static Map<Id,Account> getAccountByIds(Set<Id> recordIds) {
        return new Map<Id,Account>([SELECT Quickbook_Customer_Id__c, Name from Account where Id =: recordIds]);
    }
    
    /** 
     * @ description              : This method returns map of QB Invoice Id and Invoice
     * @ args: Set<String>        : Invoice Document number 
     * @ return                   : Map<String,Quickbook_Invoice__c>   
    **/
    public static Map<String,Quickbook_Invoice__c> getQBInvoiceRecords(Set<String> invoiceIds) {
        
        //Map of QB Invoice Id and QB Invoice
        Map<String,Quickbook_Invoice__c> mapOfInvoiceNoAndQBInvoice = new Map<String,Quickbook_Invoice__c>();
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, [Select Id, Quickbook_Invoice_Id__c, Name, Account__c From Quickbook_Invoice__c Where Quickbook_Invoice_Id__c IN :invoiceIds WITH SECURITY_ENFORCED]);
        for(Quickbook_Invoice__c qb : (List<Quickbook_Invoice__c>)securityDecision.getRecords()){
            mapOfInvoiceNoAndQBInvoice.put(qb.Quickbook_Invoice_Id__c,qb);
        }
        return mapOfInvoiceNoAndQBInvoice;
    }

    /** 
     * @ description              : This method returns Invoice data
     * @ args: Set<Id>            : Invoice Document number 
     * @ return                   : Map<String,Quickbook_Invoice__c>   
    **/
    public static Map<String,Quickbook_Invoice__c> getQBInvoiceRecordsByIds(Set<Id> invoiceIds) {
        
        //Map of QB Invoice Id and QB Invoice
        Map<String,Quickbook_Invoice__c> mapOfInvoiceNoAndQBInvoice = new Map<String,Quickbook_Invoice__c>();
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, [Select Id, Quickbook_Invoice_Id__c, Name, Account__c From Quickbook_Invoice__c Where Id IN :invoiceIds WITH SECURITY_ENFORCED]);
        for(Quickbook_Invoice__c qb : (List<Quickbook_Invoice__c>)securityDecision.getRecords()){
            mapOfInvoiceNoAndQBInvoice.put(qb.Quickbook_Invoice_Id__c,qb);
        }
        return mapOfInvoiceNoAndQBInvoice;
    }
    
     /** 
     * @ description                  : This method returns quickbook invoice record. 
     * @ args: String            : invoice id 
     *  
     * @ return: Quickbook_Invoice__c : quickbook invoice record   
    **/  
    public static Quickbook_Invoice__c getQuickbookInvoiceByInvoiceId(String invoiceId) {
        List<Quickbook_Invoice__c> records = [SELECT Id, Quickbook_Invoice_Id__c from Quickbook_Invoice__c where Quickbook_Invoice_Id__c =: invoiceId];
        return (records != null && !records.isEmpty()) ? records[0] : null;
        
    }

    /** 
     * @ description                 : This method returns Quickbook_Invoice__c exist or not 
     * @ args: String                : id 
     * @ return: Map<String, String> : quickbook invoice record Id 
    **/
    @Auraenabled
    public static Map<String, String> getQuickbookInvoiceById(String recordId) {
        Map<String, String> returnMap = new Map<String, String>();
        List<Quickbook_Invoice__c> quickbook = [SELECT Name, Account__r.Quickbook_Customer_Id__c, Quickbook_Invoice_Id__c from Quickbook_Invoice__c where Id=:recordId];
        if( quickbook[0].Quickbook_Invoice_Id__c != null ){
            returnMap.put('ERROR','Already had a quickbookId.');
            return returnMap;
        }
        returnMap.put('Quickbook',JSON.serialize(quickbook));
        return returnMap;
    }
    
    /** 
     * @ description             : This method returns Quickbook_Invoice__c record. 
     * @ args: Set<Id>           : QuickBook invoice IDs 
     * @ return: List<Quickbook_Invoice__c> : quickbook invoice records   
    **/
    public static List<Quickbook_Invoice__c> getQuickbookInvoiceIds(Set<Id> setOfInvoiceIds) {
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE,[Select Name, Account__r.Quickbook_Customer_Id__c, Quickbook_Invoice_Id__c,Account__c,Balance_Due__c,Due_Date__c From Quickbook_Invoice__c Where Id IN :setOfInvoiceIds WITH SECURITY_ENFORCED]);
        List<Quickbook_Invoice__c> listOfQBInvoices = (List<Quickbook_Invoice__c>)securityDecision.getRecords();
        return listOfQBInvoices;
    }
    
   /** 
     * @ description             : This method returns contact record. 
     * @ args: String            : contact id 
     *  
     * @ return: Contact         : contact record   
    **/ 
    public static Contact getContactById(String recordId) {
        return [SELECT Id, Name from Contact where Id =: recordId];
    }
    
    /** 
     * @ description             : This method returns contacts record. 
     * @ args: Set<Id>           : contact id 
     *  
     * @ return: Contact         : contact record   
    **/
    public static Map<Id,Contact> getContactByIds(Set<id> recordIds) {
        Map<Id,Contact> mapOfContacts = new Map<Id,Contact>([SELECT Id, Name from Contact where Id IN :recordIds]);
        return mapOfContacts;
    }
    
    /**
     * @ description                              : This method insert/update invoice sobject record and invoice lines sobject records.
     * @ args: mapOfQuickBookInvoices             : Map<String,Quickbook_Invoice__c>
     * @ args: mapOfQuickBookServiceLines         : Map<String,List<Quickbook_Service_Line__c>>
     * 
     * @ return: void      
    **/
   public static void upsertInvoiceRecord(Map<String,Quickbook_Invoice__c> mapOfQuickBookInvoices, Map<String,List<Quickbook_Service_Line__c>> mapOfQuickBookServiceLines) {
      
       //Map of newly created invoices records
       Map<String,Quickbook_Invoice__c> mapOfNewInvoices  = new Map<String,Quickbook_Invoice__c>();
       //This set will store the updated invoices ids
       Set<Id> setOfUpdateInvoice = new Set<Id>();
       //Set of newly created invoices Id
       Set<Id> setOfNewlyCreatedInvoices = new Set<Id>();
       
       for(Quickbook_Invoice__c qb : mapOfQuickBookInvoices.values()){
           setOfUpdateInvoice.add(qb.Id);
       }
       
       try {
            if(Schema.sObjectType.Quickbook_Invoice__c.isCreateable() || Schema.sObjectType.Quickbook_Invoice__c.isUpdateable()) {
                
                SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPSERTABLE, mapOfQuickBookInvoices.values());
                //upsert Invoice
                Database.UpsertResult[] saveResults = Database.upsert((List<Quickbook_Invoice__c>)securityDecision.getRecords(), false);
                
                // Populate the upsertResults map with the results of Quickbook_Invoice__c records
                for (Integer i = 0; i < saveResults.size(); i++) {
                    Database.UpsertResult sr = saveResults[i];
                    if (sr.isSuccess() && sr.getId() != null && !setOfUpdateInvoice.contains(sr.getId())) {
                        setOfNewlyCreatedInvoices.add(sr.getId());
                    }else{
                        System.debug('Qb sr.getErrors()###'+sr.getErrors());
                    }
                }
            }
           
            //Get newly created invoices records
           if(setOfNewlyCreatedInvoices.size() > 0)
               mapOfNewInvoices = getQBInvoiceRecordsByIds(setOfNewlyCreatedInvoices);
           
            //Map Invoice with service lines
            List<Quickbook_Service_Line__c> listOfQBServiceLine = new List<Quickbook_Service_Line__c>();
           
            for(String invoiceId : mapOfQuickBookServiceLines.keySet()){
                for(Quickbook_Service_Line__c line : mapOfQuickBookServiceLines.get(invoiceId)) {
                    if(mapOfQuickBookInvoices.containsKey(line.Quickbook_Invoice_Id__c)){
                        if(mapOfQuickBookInvoices.get(line.Quickbook_Invoice_Id__c).Id != null){
                            line.Quickbook_Invoice__c = mapOfQuickBookInvoices.get(line.Quickbook_Invoice_Id__c).Id;
                        }
                        else{
                            if(mapOfNewInvoices.containsKey(line.Quickbook_Invoice_Id__c))
                               line.Quickbook_Invoice__c = mapOfNewInvoices.get(line.Quickbook_Invoice_Id__c).Id;
                        }
                        listOfQBServiceLine.add(line);  
                    }
                }
            }
            if(listOfQBServiceLine.size() > 0 && (Schema.sObjectType.Quickbook_Service_Line__c.isCreateable() || Schema.sObjectType.Quickbook_Service_Line__c.isUpdateable())){
                SObjectAccessDecision securityDecisionLines = Security.stripInaccessible(AccessType.UPSERTABLE, listOfQBServiceLine);
                //Upsert Service lines records
                Database.UpsertResult[] saveResults = Database.upsert((List<Quickbook_Service_Line__c>)securityDecisionLines.getRecords(),false);
                for (Integer i = 0; i < saveResults.size(); i++) {
                    Database.UpsertResult sr = saveResults[i];
                    if (sr.isSuccess() && sr.getId() != null ) {
                        System.debug('**Sucess**');
                    }else{
                        System.debug('sr.getErrors()###'+sr.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            throw new QuickbookException('Error upserting: ' + e.getMessage());
        }
    }
    
    /**
     * @ description        : This method delete service line record on QB Invoice
     * @ args: setOfQBIds   : Set<Id>
     * @ return: void      
    **/
    @AuraEnabled
    public static void deleteServiceLines(List<Id> listOfQBIds){
        if(Schema.sObjectType.Quickbook_Service_Line__c.isDeletable())
           delete [Select Id From Quickbook_Service_Line__c Where Quickbook_Invoice__c IN :listOfQBIds WITH SECURITY_ENFORCED];
    }
    
    /**
     * @ description              : This method delete SF QB Invoice record from System
     * @ args: setOfQBInvoiceIds  : Set<String>
     * @ return: void      
    **/
    public static void deleteInvoiceRecords(Set<String> setOfQBInvoiceIds){
        if(Schema.sObjectType.Quickbook_Invoice__c.isDeletable()){
            List<Quickbook_Invoice__c> listOfDeletedInvoices = [Select Id From Quickbook_Invoice__c Where Quickbook_Invoice_Id__c IN :setOfQBInvoiceIds WITH SECURITY_ENFORCED];
            if(listOfDeletedInvoices.size() > 0)
                delete as user listOfDeletedInvoices;
        }
    }
    
    /**
     * @ description              : This method call from createInvoice LWC component and insert invoice record online 
     * @ args: recordId           : QB Invoice Id
     * @ return: void      
    **/
    @Auraenabled
    public static void createQuickBookInvoiceFromLWC(String recordId){
        QuickbookService.createQuickBookInvoices([SELECT Id, IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
                                                  SystemModstamp, LastActivityDate, LastViewedDate, LastReferencedDate, Account__c, Balance_Due__c, Due_Date__c, 
                                                  Invoice_Date__c, Quickbook_Invoice_Id__c, Quickbook_Status_Backend__c, Sub_Total__c, Tax__c, 
                                                  Account__r.Quickbook_Customer_Id__c, Total_Amount__c, Quickbook_Invoice_Link__c, Status__c 
                                                  FROM Quickbook_Invoice__c 
                                                  Where Id=:recordId WITH SECURITY_ENFORCED]);
    }
}