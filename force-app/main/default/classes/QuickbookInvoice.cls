public with sharing class QuickbookInvoice {
    public String Id { get; set;}
    public String DocNumber { get; set;}
    public Date TxnDate {get; set;}
    public Date DueDate {get; set;}
    public Double TotalAmt {get; set;}
    public Double Balance {get; set;}
    public QuickbookNameValue CustomerRef {get; set;}
    public QuickbookNameValue CurrencyRef {get; set;}
    public List<QuickbookLine> Line {get; set;} 
    public QuickbookTxnTaxDetail TxnTaxDetail {get; set;}
    public QuickbookDates MetaData {get; set;}
    public String error {get; set;}
    
    public String status {get; set;}
    public String billingDiff {get; set;}
    
    
    public class QuickbookTxnTaxDetail {
    	public Double TotalTax {get; set;}
	}
    
    public class QuickbookDates {
    	public String CreateTime {get; set;}
        public String LastUpdatedTime {get; set;}
	}
}