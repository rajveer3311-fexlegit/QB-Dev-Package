/**
 *  Purpose         : Mock Response class for Quickbook apis
 *
 *  Created Date    :  11/08/2021
 *
 *  Created By      : Suresh Koumar
 *
 *  Revision Logs   :  V_1.0 - Created
 *                     V_1.1 - Modified By : Rajveer Singh Rawat - 04/10/2023
 *
 **/
@isTest 
global class QuickbookHttpMockResponse implements HttpCalloutMock {
    
    public static String CALLOUT_TYPE = '';
    Date dt = Date.today()-1;
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
    	response.setStatusCode(200);
        
        if(CALLOUT_TYPE.equals('oauth-callout')) {
            response.setBody('{"access_token" : "token","refresh_token" : "refreshtoken","expires_in" : 3600,"x_refresh_token_expires_in" : 18000}');
        } else if(CALLOUT_TYPE.equals('api-callout')) {
        	response.setBody('{"data":"test response string"}');
        }else if(CALLOUT_TYPE.equals('No-QB-invoice-callout')) {
            response.setBody('{}');
        }else if(CALLOUT_TYPE.equals('QB-invoice-callout')) {
            response.setBody('{"QueryResponse":{"Invoice":[{"Id":"183","DocNumber":"IN-1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test description","Amount":600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16","ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet"}]}}');
        }else if(CALLOUT_TYPE.equals('QB-invoice-No-SerLine-callout')) {
            response.setBody('{"QueryResponse":{"Invoice":[{"Id":"183","DocNumber":"IN-1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test description","Amount":600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16","ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet"}]}}');
        }else if(CALLOUT_TYPE.equals('No-QBDetails-invoice-callout')) {
            response.setBody('{"QueryResponse":{"Invoice":[{"Id":"183","DocNumber":"IN-1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test Desc","Amount":600.00}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet"}]}}');
        }else if(CALLOUT_TYPE.equals('QB-ImpDescription-invoice-callout')) {
            response.setBody('{"QueryResponse":{"Invoice":[{"Id":"183","DocNumber":"IN-1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test Desc","Amount":4500.00,"DetailType":"SubTotalLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16","ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet"}]}}');
        }else if(CALLOUT_TYPE.equals('NoCustomer-invoice-callout')) {
            response.setBody('{"QueryResponse":{"Invoice":[{"Id":"183","DocNumber":"IN-1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test Desc","Amount":600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16","ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"12","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet"}]}}');
        }else if(CALLOUT_TYPE.equals('No-Desc-invoice-callout')) {
            response.setBody('{"QueryResponse":{"Invoice":[{"Id":"183","DocNumber":"IN-1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Amount":600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16","ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet"}]}}');
        }else if(CALLOUT_TYPE.equals('No-invoice-Lines')) {
            response.setBody('{"QueryResponse":{"Invoice":[{"Id":"183","DocNumber":"IN-1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet"}]}}');
        }else if(CALLOUT_TYPE.equals('invoice-callout') || CALLOUT_TYPE.equals('refresh-invoice-callout')) {
            Double dueBalance = (CALLOUT_TYPE.equals('refresh-invoice-callout')) ? 0 : 600.00;
            response.setBody('{"QueryResponse":{"Invoice":[{"Id":"183","DocNumber":"1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test Desc","Amount":600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16","ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}},{"Amount":600.00,"DetailType":"SubTotalLineDetail","SubTotalLineDetail":{}}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet","Balance":'+dueBalance+'}]}}');
        } else if(CALLOUT_TYPE.equals('No-Lines')) {
            response.setBody('{"Invoice":{"Id":"183","DocNumber":"1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test Desc","Amount":600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16","ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}},{"Amount":600.00,"DetailType":"SubTotalLineDetail","SubTotalLineDetail":{}}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet","Balance":600.00}}');
        } else if(CALLOUT_TYPE.equals('create-invoice-callout')) {
            response.setBody('{"Invoice":{"Id":"183","DocNumber":"1075","TxnDate":"2021-07-19","CurrencyRef":{"value": "INR"},"Line":[{"Id":"1","LineNum":1,"Description":"Test Desc","Amount":600.00,"DetailType":"SalesItemLineDetail","SalesItemLineDetail":{"ServiceDate":"2021-07-16","ItemRef":{"value":"2","name":"Landscaping:Hours"},"UnitPrice":100,"Qty":6,"TaxCodeRef":{"value":"TAX"}}},{"Amount":600.00,"DetailType":"SubTotalLineDetail","SubTotalLineDetail":{}}],"TxnTaxDetail":{"TotalTax":0},"CustomerRef":{"value":"59","name":"Prodly"},"DueDate":"2021-07-22","TotalAmt":600.00,"ApplyTaxAfterDiscount":false,"PrintStatus":"NeedToPrint","EmailStatus":"NotSet","Balance":600.00}}');
        } else if(CALLOUT_TYPE.equals('create-invoice-callout-quickbook-customer')) {
            response.setBody('{"Invoice": {"Id": "183","DocNumber": "IN-10000001","TxnDate": "2021-07-19","CurrencyRef": {"value": "INR","Line": [{"Id": "1","LineNum": 1,"Description": "Test Desc","Amount": 600,"DetailType": "SalesItemLineDetail","SalesItemLineDetail": {"ServiceDate": "2021-07-16","ItemRef": {"value": "2","name": "Landscaping:Hours"},"UnitPrice": 100,"Qty": 6,"TaxCodeRef": {"value": "TAX"}}},{"Amount": 600,"DetailType": "SubTotalLineDetail","SubTotalLineDetail": {}}],"TxnTaxDetail": {"TotalTax": 0},"CustomerRef": {"value": "1","name": "Prodly"},"DueDate": "2021-07-22","TotalAmt": 600,"ApplyTaxAfterDiscount": false,"PrintStatus": "NeedToPrint","EmailStatus": "NotSet"}}}');
        } else if(CALLOUT_TYPE.equals('error-callout')) {
            response.setBody('{"Fault":{"Error":[{"Detail":"test error message."}]}}');
        	response.setStatusCode(400); 
        } else if(CALLOUT_TYPE.equals('remote-site-callout-error')) {
            CalloutException e = (CalloutException)CalloutException.class.newInstance();
        	e.setMessage('Unauthorized endpoint, please check Setup->Security->Remote site settings.');
        	throw e;
        } else if(CALLOUT_TYPE.equals('Yest-Invoice_callout')){
            response.setBody('{"CDCResponse": [{"QueryResponse": [{},{"Invoice": [{"AllowIPNPayment": false,"AllowOnlinePayment": false,"AllowOnlineCreditCardPayment": true,"AllowOnlineACHPayment": true,"domain": "QBO","sparse": false,'+
                            '"Id": "43","SyncToken": "0","MetaData": {"CreateTime": "'+dt+'","LastUpdatedTime": "'+dt+'"},'+
                            '"LinkedTxn": [],"Line": [{"Id": "1","LineNum": 1,"Description": "test 3311","Amount": 0,"DetailType": "SalesItemLineDetail","SalesItemLineDetail": {"ItemRef": {"value": "2","name": "Hours"},"UnitPrice": 0,"Qty": 1,'+
                            '"TaxCodeRef": {"value": "NON"}}},{"Amount": 0,"DetailType": "SubTotalLineDetail","SubTotalLineDetail": {}}],'+
                            '"CustomerRef": {"value": "1","name": "Raja Ram"},"BillAddr": {"Id": "50","Line1": "Raja Ram","Line2": "Fexle"},'+
							'"ShipAddr": {"Id": "2"},"SalesTermRef": {"value": "3","name": "Net 30"},"DueDate": "2023-11-20","TotalAmt": 0,'+
							'"ApplyTaxAfterDiscount": false,"PrintStatus": "NotSet","EmailStatus": "NotSet","BillEmail": {"Address": "rs2405199@gmail.com"},"Balance": 0},{"domain": "QBO","status": "Deleted","Id": "62","MetaData": {"LastUpdatedTime": "'+dt+'"}}]}]}]}');
        } else if(CALLOUT_TYPE.equals('Yest-Deleted_Invoice')){
            response.setBody('{"CDCResponse": [{"QueryResponse": [{},{"Invoice": [{"domain": "QBO","status": "Deleted","Id": "62","MetaData": {"LastUpdatedTime": "'+dt+'"}}]}]}]}');
        }
        response.setHeader('Content-Type', 'application/json');
        return response;
    }
}