/**
 *  Purpose         : This class is for Quickbook Exception type
 *
 *  Created Date    :   22/07/2021
 *
 *  Created By      : Suresh Koumar
 *
 *  Revision Logs   :   V_1.0 - Created
 *
 **/
public class QuickbookException extends Exception {

    public class QuickbookConnectionException extends Exception {}
    
    public class QuickbookBadRequestException extends Exception {}
    
    public class InvoiceNotFoundException extends Exception {}
    
    public class InvoiceLineDataNotFoundException extends Exception {}
}