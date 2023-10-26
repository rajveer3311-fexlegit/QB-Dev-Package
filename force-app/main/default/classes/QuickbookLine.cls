public with sharing class QuickbookLine {
    public String Id {get; set;}
    public String Description {get; set;}
    public Double Amount {get; set;}
    public String DetailType {get; set;}
    public QuickbookSalesItemLineDetail SalesItemLineDetail {get; set;}
}