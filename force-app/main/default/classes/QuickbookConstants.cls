/*
 *  Description     :   This class is for Quickbook Constants.
 *                   
 *  Created By      :   Suresh koumar                  
 *                   
 *  Created Date    :   08/06/2021                   
 *                   
 *  Revision Logs   :   V_1.0 - Created                   
 *
 */
public with sharing class QuickbookConstants {
    
    //Quickbook default connection name value
	public static final String CONNECTION_NAME = 'Production';
    //Quickbook url api version
    public static final String API_VERSION = 'v3';
    //Quickbook service line 'Hours' id value
    public static final String SERVICE_LINE_HOURS = '2';
    
    //salesforce urls
    public static final String SF_SANDBOX = 'https://test.salesforce.com/apex/QuickbookConnection';
    public static final String SF_PRODUCTION = 'https://login.salesforce.com/apex/QuickbookConnection';
    public static final String SF_HOST_URL = 'https://login.salesforce.com';
    
    //quickbook urls
    public static final String QB_PRODUCTION = 'https://quickbooks.api.intuit.com';
    public static final String QB_SANDBOX = 'https://sandbox-quickbooks.api.intuit.com';
    public static final String QB_OAUTH_CODE_URL = 'https://appcenter.intuit.com/connect/oauth2';
    public static final String QB_OAUTH_TOKEN_URL = 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer';
    
    //ERROR_MESSAGES
    public static final String CONNECTION_ERROR = 'Quickbook connection is not established!';
    public static final String CUSTOM_SETTING_ERROR = 'Quickbook app custom setting info not available!';
    
    public static final String CONTACT_EMAIL = 'test@fexle.com';
    public static final String CONTACT_MAILINGSTREET = 'Test Street';
    public static final String CONTACT_MAILINGCITY = 'Test City';
    public static final String CONTACT_MAILINGSTATE = 'Test State';
    public static final String CONTACT_MAILINGCOUNTRY = 'Test Country';
    public static final String CONTACT_MAILINGPOSTALCODE = '302020';
    public static final String GENDER = 'Male';
    public static final String STR_PHONE_NUMBER = '123-456-7890';
    public static final String CONTACT_ACCOUNTNAME = 'Software Engineer';
    
    public static final String STR_DELETE = 'Deleted';
    
    public static String getBasicOauthString(String clientId, String clientSecret) {
        return 'Basic ' +EncodingUtil.base64Encode(Blob.valueOf(clientId + ':' + clientSecret));
    }
}