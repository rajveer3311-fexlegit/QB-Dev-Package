/**
 *  Purpose         : Test class for QuickbookHelper class
 *
 *  Created Date    : 29/07/2021
 *
 *  Created By      : Suresh Koumar
 *
 *  Revision Logs   : V_1.0 - Created
 *
 **/
@IsTest 
public class QuickbookHelperTest {
    
   /**
     * @ description: This method test get api call. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testGetAPICall() {
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'api-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        HTTPResponse res = QuickbookHelper.getAPICall(QuickbookConstants.QB_PRODUCTION, 'token');
        
        System.debug('>>> ' + res.getBody());
        System.assertEquals('{"data":"test response string"}', res.getBody());
        System.assertEquals(200, res.getStatusCode());
        System.assertEquals('application/json', res.getHeader('Content-Type'));   
    }
    
    /**
     * @ description: This method test post api call. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testPostAPICall() {
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'api-callout';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        HTTPResponse res = QuickbookHelper.postAPICall(QuickbookConstants.QB_PRODUCTION, 'token', 'application/json', '');
        
        System.assertEquals('{"data":"test response string"}', res.getBody());
        System.assertEquals(200, res.getStatusCode());
        System.assertEquals('application/json', res.getHeader('Content-Type'));   
    }

    /**
     * @ description: This method test get api call exception. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testGetAPICallException() {
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'remote-site-callout-error';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        HTTPResponse res = QuickbookHelper.getAPICall(QuickbookConstants.QB_PRODUCTION, 'token');       
        System.assertEquals(400, res.getStatusCode());
    }
    
    /**
     * @ description: This method test post api call exception. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testPostAPICallException() {
        QuickbookHttpMockResponse.CALLOUT_TYPE = 'remote-site-callout-error';
        Test.setMock(HttpCalloutMock.class, new QuickbookHttpMockResponse());
        HTTPResponse res = QuickbookHelper.postAPICall(QuickbookConstants.QB_PRODUCTION, 'token', 'application/json', '');
        
        System.assertEquals(400, res.getStatusCode());
    }
    
    /**
     * @ description: This method test get quickbook connection object. 
     *
     * @ return: void : 
    **/
    @isTest
   public static void testGetQuickbookConnection() {
        //test no existing connection record
        Quickbook_Connection__c connectionObj = QuickbookHelper.getQuickbookConnection();
        System.assert(connectionObj == null);
        
        Quickbook_Connection__c connection = new Quickbook_Connection__c();
        connection.Company_Id__c = 'CompanyId';
        connection.Access_Token__c = 'accesstoken';
        connection.Refresh_Token__c = 'refreshtoken';
        connection.Token_Updated_At__c = DateTime.now();
        connection.Access_Token_Expires_In__c = 3600;
        connection.Refresh_Token_Expires_In__c = 180000;
        connection.Name = QuickbookConstants.CONNECTION_NAME;
        insert connection;
        
       //test valid connection record
        connectionObj = QuickbookHelper.getQuickbookConnection();
        System.assert(connectionObj != null);
        System.assertEquals('accesstoken', connectionObj.Access_Token__c);  
        System.assertEquals('CompanyId', connectionObj.Company_Id__c);  
        System.assertEquals('refreshtoken', connectionObj.Refresh_Token__c);  
        System.assertEquals(3600, connectionObj.Access_Token_Expires_In__c);  
    }
    
    /**
     * @ description: This method test getQuickbookConfiguration custom setting info. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testGetConfiguration() {
        //test no custom setting
        QuickbookSetting__c configurationObj = QuickbookHelper.getConfiguration();
        System.assert(configurationObj == null);
        
        QuickbookSetting__c setting = new QuickbookSetting__c();
        setting.ClientId__c = 'clientId';
        setting.ClientSecret__c = 'secret';
        insert setting;
        
        //test valid custom setting object
        configurationObj = QuickbookHelper.getConfiguration();
        System.assert(configurationObj != null);
        System.assertEquals('clientId', configurationObj.ClientId__c);
        System.assertEquals('secret', configurationObj.ClientSecret__c);
        System.assertEquals(false, configurationObj.IsProduction__c);
        System.assertEquals(false, configurationObj.IsTaxable__c);
    }
    
    /**
     * @ description: This method test parseHttpError. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testParseHttpError() {
        //test bad request exception
        HttpResponse invalidResponse = new HttpResponse();
        invalidResponse.setBody('{"Error":[{"Detail":"test error message."}]}');
        invalidResponse.setStatusCode(400);
        invalidResponse.setHeader('Content-Type', 'application/json');
        
        Exception badRequestError = QuickbookHelper.parseHttpError(invalidResponse);
        System.assert(badRequestError != null);
        System.assert(badRequestError instanceOf QuickbookException.QuickbookBadRequestException);

    //test quickbook unknown exception        
        invalidResponse = new HttpResponse();
        invalidResponse.setBody('{"Fault":{"Error":[{"Detail":"test error message."}]}}');
        invalidResponse.setStatusCode(302);
        invalidResponse.setHeader('Content-Type', 'application/json');
         
        Exception unknownError = QuickbookHelper.parseHttpError(invalidResponse);
        System.assert(unknownError != null);
        System.assert(unknownError instanceOf QuickbookException);
        
        //test quickbook connection exception        
        invalidResponse = new HttpResponse();
        invalidResponse.setBody('{"Fault":{"Error":[{"Detail":"test error message."}]}}');
        invalidResponse.setStatusCode(401);
        invalidResponse.setHeader('Content-Type', 'application/json');
        
        Exception connectionError = QuickbookHelper.parseHttpError(invalidResponse);
        System.assert(connectionError != null);
        System.assert(connectionError instanceOf QuickbookException.QuickbookConnectionException);
          
        //test quickbook connection exception        
        invalidResponse = new HttpResponse();
        invalidResponse.setBody('{"Fault":{"Error":[{"Detail":"test error message."}]}}');
        invalidResponse.setStatusCode(403);
        invalidResponse.setHeader('Content-Type', 'application/json');
        
        Exception unauthorizeError = QuickbookHelper.parseHttpError(invalidResponse);
        System.assert(unauthorizeError != null);
        System.assert(unauthorizeError instanceOf QuickbookException.QuickbookConnectionException);
 
    }
    
    /**
     * @ description: This method test parseErrort. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testParseError() {
        HttpResponse invalidResponse = new HttpResponse();
        invalidResponse.setBody('{"Error":[{"Detail":"test error message."}]}');
        invalidResponse.setStatusCode(400);
        invalidResponse.setHeader('Content-Type', 'application/json');
        
        String errorMsg = QuickbookHelper.parseError(invalidResponse);
        System.assert(errorMsg.contains('Unknown error:'));
        
        HttpResponse response = new HttpResponse();
        response.setBody('{"Fault":{"Error":[{"Detail":"test error message."}]}}');
        response.setStatusCode(400);
        response.setHeader('Content-Type', 'application/json');
        
        String error = QuickbookHelper.parseError(response);
        System.assertEquals('test error message.', error);
    }
    
    /**
     * @ description: This method test error HttpResponse. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testErrorResponse() {
        QuickbookException e = new QuickbookException('Unauthorized endpoint');
        HttpResponse errorResponse = QuickbookHelper.errorResponse('http://testerror.com', e);
       System.assert(errorResponse.getBody().contains('Set Remote Site Setting for url'));
    }
    
    /**
     * @ description: This method test getQuickbookInstanceUrl. 
     *
     * @ return: void : 
    **/
    @isTest
    public static void testGetQuickbookInstanceUrl() {
      String url = QuickbookHelper.getQuickbookInstanceUrl(false);
      System.assertEquals(url, QuickbookConstants.QB_SANDBOX);
      url = QuickbookHelper.getQuickbookInstanceUrl(true);
      System.assertEquals(url, QuickbookConstants.QB_PRODUCTION);
    }
}