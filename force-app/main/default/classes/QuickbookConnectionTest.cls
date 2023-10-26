/**
 *  Purpose         :  Test class for QuickbookConnection class
 *
 *  Created Date    :  07/26/2021
 *
 *  Created By      :  Suresh Koumar
 *
 *  Revision Logs   :  V_1.0 - Created
 *
 **/
@IsTest
public class QuickbookConnectionTest {

    /**
     * @ description: This method test get code url. 
     *
     * @ return: void : 
    **/
    @isTest
    static void testGetConnectionCode() {
         
        /* Test error when custom setting is not present. */
        PageReference objPageRef = QuickbookConnection.getConnectionCode();
        System.assert(objPageRef != null);
        System.assertEquals(QuickbookConstants.SF_HOST_URL, objPageRef.getUrl());
        
        //Test error message
        testMessage(QuickbookConstants.CUSTOM_SETTING_ERROR, ApexPages.Severity.Error);
        
        /* Test when custom setting is present */ 
        QuickbookSetting__c setting = new QuickbookSetting__c();
        setting.ClientId__c = 'clientId';
        setting.ClientSecret__c = 'secret';
        insert setting;
        
        String redirectUrl = QuickbookSFHelper.getRedirectUrl();
        redirectUrl = EncodingUtil.urlEncode(redirectUrl, 'UTF-8');
        PageReference PageRef = QuickbookConnection.getConnectionCode();
        System.assert(PageRef != null);

        String url = QuickbookConstants.QB_OAUTH_CODE_URL + '?client_id=clientId&redirect_uri='+redirectUrl+'&response_type=code' +
            '&scope=com.intuit.quickbooks.accounting&state=' + QuickbookConstants.CONNECTION_NAME;
    	System.debug('PageRef.getUrl() ' + PageRef.getUrl());
        //confirm called url as per custom setting
        System.assertEquals(url, PageRef.getUrl());
    }
    
    /**
     * @ description: This method test get access token. 
     *
     * @ return: void : 
    **/
    @isTest
    static void testGetAccessToken() {
        Test.startTest();

        /* Test error when custom setting is not present. */
        QuickbookConnection.getAccessToken();
        testMessage(QuickbookConstants.CUSTOM_SETTING_ERROR, ApexPages.Severity.Error);
 
        /* Test when custom setting is present */ 
        QuickbookSetting__c setting = new QuickbookSetting__c();
        setting.ClientId__c = 'clientId';
        setting.ClientSecret__c = 'secret';
        insert setting;

        //test callout error response
        getAccessTokenCalloutError();
        
        //test callout success response
        getAccessTokenCallout();
        
        Test.stopTest();
    }
    
    /**
     * @ description: This method test get access token callout. 
     *
     * @ return: void : 
    **/
    @future(callout = true)
    public static void getAccessTokenCallout() {
    	QuickbookHttpMockResponse.CALLOUT_TYPE = 'oauth-callout';
       	Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
       	//Call test method
       	QuickbookConnection.getAccessToken();
       
       	List<Quickbook_Connection__c> connections = [Select id, Refresh_Token__c, Access_Token__c, Access_Token_Expires_In__c,
                                                   Refresh_Token_Expires_In__c from Quickbook_Connection__c];
        
       	// check connection record
       	System.assert(connections != null && !connections.isEmpty());
       	System.assertEquals(1, connections.size()); 
      	System.assertEquals('token', connections[0].Access_Token__c); 
       	System.assertEquals('refreshtoken', connections[0].Refresh_Token__c); 
       	System.assertEquals(3600, connections[0].Access_Token_Expires_In__c); 
       	System.assertEquals(18000, connections[0].Refresh_Token_Expires_In__c); 
        
       	//test message 
       	testMessage('Authenticated Successfully.', ApexPages.Severity.Confirm);

    }
    
    /**
     * @ description: This method test get access token callout with error response. 
     *
     * @ return: void : 
    **/
    @future(callout = true)
    public static void getAccessTokenCalloutError() {
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'error-callout';
       	Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
       //Call test method
       QuickbookConnection.getAccessToken();
          
       //test message 
       testMessage('Unexpected Error: Status Code 400 Message: {"Fault":{"Error":[{"Detail":"test error message."}]}}',
                   ApexPages.Severity.Error);
    }
    
    /**
     * @ description: This method test refresh access token. 
     *
     * @ return: void : 
    **/
    @isTest
    static void testRefreshAccessToken() {
        Test.startTest();
        /* Test error when custom setting is not present. */
        Quickbook_Connection__c connection = new Quickbook_Connection__c();
        
        try {
          connection = QuickbookConnection.refreshAccessToken(connection);
        } catch(QuickbookException.QuickbookConnectionException e) {
            //Asserts QuickbookConnectionException
            System.assert(e.getMessage().contains(QuickbookConstants.CUSTOM_SETTING_ERROR));
        }

        /* Test when custom setting is present */ 
        QuickbookSetting__c setting = new QuickbookSetting__c();
        setting.ClientId__c = 'clientId';
        setting.ClientSecret__c = 'secret';
        insert setting;
        
        try {
          connection = QuickbookConnection.refreshAccessToken(null);
        } catch(QuickbookException.QuickbookConnectionException e) {
            //Asserts QuickbookConnectionException
            System.assert(e.getMessage().contains('Refresh token not found to refresh access token.'));
        }
        
        refreshAccessTokenCalloutError();

        refreshAccessTokenCallout();
        
        Test.stopTest();
    }
    
    /**
     * @ description: This method test refresh token callout. 
     *
     * @ return: void : 
    **/
    @future(callout = true)
    public static void refreshAccessTokenCallout() {
    	QuickbookHttpMockResponse.CALLOUT_TYPE = 'oauth-callout';
       	Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        
        Quickbook_Connection__c connection = new Quickbook_Connection__c(); 
        connection.Refresh_Token__c='dummy_refreshtoken';
        
        connection = QuickbookConnection.refreshAccessToken(connection);
        System.assert(connection != null); 
        System.assertEquals('token', connection.Access_Token__c); 
        System.assertEquals('refreshtoken', connection.Refresh_Token__c); 
        System.assertEquals(3600, connection.Access_Token_Expires_In__c); 
        System.assertEquals(18000, connection.Refresh_Token_Expires_In__c); 
    }
    
    
    /**
     * @ description: This method test refresh access token callout with error response. 
     *
     * @ return: void : 
    **/
    @future(callout = true)
    public static void refreshAccessTokenCalloutError() {
    	QuickbookHttpMockResponse.CALLOUT_TYPE = 'error-callout';
       	Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
       
       	Quickbook_Connection__c connection = new Quickbook_Connection__c(); 
       	connection.Refresh_Token__c='dummy_refreshtoken';
       	//Call test method
        try {       
         	System.debug('connection!=null' + (connection!=null));   
          	connection = QuickbookConnection.refreshAccessToken(connection);
       } catch(QuickbookException.QuickbookBadRequestException e){
            //Asserts QuickbookBadRequestException
            System.assert(e.getMessage().contains('test error message.')); 
       }
        
    }
   
    /**
     * @ description              : This method test if required ui message is pushed on Visual force page. 
     * @args : uiMessage          : Message to be tested
     * @args : ApexPages.Severity : Message type 
     * 
     * @ return: void
    **/ 
   public static void testMessage(String uiMessage, ApexPages.Severity severity) {
      ApexPages.Message[] pageMessages = ApexPages.getMessages();
       
       System.assertNotEquals(0, pageMessages.size());
        
       Boolean messageFound = false;

       for(ApexPages.Message message : pageMessages) {
           System.debug('MSG: ' + message.getDetail());
           if(message.getDetail() == uiMessage
               && message.getSeverity() == severity) {
               messageFound = true;        
           }
       } 
       // assert expected message
       System.assert(messageFound);
    }
}