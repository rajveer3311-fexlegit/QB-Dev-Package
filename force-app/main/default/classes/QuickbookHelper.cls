/**
 *  Purpose         : This class is for supportive method definations required for Quickbook Serivices.
 *
 *  Created Date    : 23/07/2021
 *
 *  Created By      : Suresh Koumar
 *
 *  Revision Logs   : V_1.0 - Created
 *
 **/
public with sharing class QuickbookHelper {
	
    private static Quickbook_Connection__c connection = null;
    public static Boolean persist {get;set;}
    
    static {
        QuickbookHelper.persist = false;
    }
    
    /**
     * @ description: This method calls http get api 
     *
     * @ args: endPoint       : endpoint url
     * @ args: accessToken    : access token value
     * 
     * @ return: HttpResponse : Returns response object
    **/
    public static HttpResponse getAPICall(String endPoint, String accessToken) {
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        Http http = new Http();
        httpReq.setMethod('GET');
        httpReq.setEndPoint(endPoint);
        httpReq.setHeader('Authorization' , 'Bearer ' + accessToken);
        httpReq.setHeader('Accept' , 'application/json');
        
        try {
            return http.send(httpReq);       
        } catch(System.Exception e){
      		return errorResponse(endPoint, e);
        }
    }
    
    /**
     * @ description: This method calls http post api 
     *
     * @ args: endPoint       : endpoint url
     * @ args: accessToken    : access token value
     * @ args: contentType    : content type header value
     * @ args: requestBody    : http request body
     *
   * @ return: HttpResponse : Returns response object
    **/
    public static HttpResponse postAPICall(String endPoint, String accessToken, String contentType, String requestBody) {
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        Http http = new Http();
        httpReq.setMethod('POST');
        httpReq.setEndPoint(endPoint);
        httpReq.setHeader('Authorization' , accessToken);
        httpReq.setHeader('Accept' , 'application/json');
        httpReq.setHeader('Content-Type' , contentType);
        httpReq.setBody(requestBody);
        System.debug('httpRes####'+httpRes);
        try{
            return http.send(httpReq);
        } catch(System.Exception e) {
            return errorResponse(endPoint, e); 
        }
    }
    
   /**
     * @ description      : This method creates http error response object 
     *
     * @ args: endPoint       : endpoint url
     * @ args: exception      : Exception object
     *
   * @ return: HttpResponse : Returns response object
    **/
    public static HttpResponse errorResponse(String endPoint, Exception e) {
            String errorMessage = '';
            Url url = new Url(endPoint);
            
            if(String.valueOf(e.getMessage()).startsWith('Unauthorized endpoint')){
                errorMessage ='Set Remote Site Setting for url \"'+ url.getHost() +'\"';
            } else {
                errorMessage = 'Unknown error- ' + e.getMessage();
            }
            System.debug(errorMessage);
            HttpResponse response = new HttpResponse();
          response.setBody('{"Fault":{"Error":[{"Detail":"'+errorMessage+'"}]}}');
          response.setStatusCode(400);
          response.setHeader('Content-Type', 'application/json');
            return response;
    }
    
    /**
     * @ description: This method returns the quickbook connection object 
     *
   * @ return: Quickbook_Connection__c : Connection object
    **/
    public static Quickbook_Connection__c getQuickbookConnection(){
        connection = QuickbookSFHelper.getQuickbookConnection();
        if(connection == null) {
            System.debug('QuickbookConnection__c object not found!');
          return null;
        }
        
        DateTime tokenUpdatedAt = connection.Token_Updated_At__c;
        Integer seconds = connection.Access_Token_Expires_In__c == null ? 330 
                        : ((Integer)connection.Access_Token_Expires_In__c - 300);
        tokenUpdatedAt = tokenUpdatedAt.addSeconds(seconds);
        if(DateTime.now() > tokenUpdatedAt) {
            connection = QuickbookConnection.refreshAccessToken(connection);
            System.debug('Access Token refreshed at: ' + DateTime.now());
            persist = true;
        }
        
        return connection;
    }
    
    /**
     * @ description: This method reads the quickbook custom setting info and returns data. 
     *
   * @ return: QuickbookSetting__c : Custom setting info
    **/
    public static QuickbookSetting__c getConfiguration() {
        
        QuickbookSetting__c setting = QuickbookSetting__c.getOrgDefaults();
        if(setting == null) {
            System.debug(QuickbookConstants.CUSTOM_SETTING_ERROR);
            return null;
        } else if(String.isBlank(setting.ClientId__c) || String.isBlank(setting.ClientSecret__c)){
            System.debug('QuickbookSetting__c client id or client secret is not set!');
            return null;            
        } else {
            return setting;
        }
    }
    
   /**
     * @ description: This method set the QuickbookConnection object
     * @ args: response_Map           : response map data
     * @ args: quickBookConnection      : quickbook connection object
     *
   * @ return: QuickbookConnection__c : updated connection object
    **/
     public static Quickbook_Connection__c setQuickbookConnection(Map<String, Object> response_Map,
                  Quickbook_Connection__c quickBookConnection) {
                                                              
        if(quickBookConnection == null) {
            System.debug('Creating new Connection Object: ');
            quickBookConnection = new Quickbook_Connection__c();
        } else {
            System.debug('Updating existing Connection Object' + quickBookConnection.Id);
        }
                          
        quickBookConnection.Token_Updated_At__c = DateTime.now();
        quickBookConnection.Access_Token__c = (String)response_Map.get('access_token');
        quickBookConnection.Refresh_Token__c = (String)response_Map.get('refresh_token');
        quickBookConnection.Access_Token_Expires_In__c =  (Decimal)response_Map.get('expires_in');
        quickBookConnection.Refresh_Token_Expires_In__c = (Decimal)response_Map.get('x_refresh_token_expires_in');
                      
        return quickBookConnection;
    }
    
    /**
     * @ description: This method log debug message and set the string message to ui. 
     *
   * @ return: void : 
    **/
    public static void setErrorMessage(String message) {
        System.debug(message);
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,message));    
    }

     /**  
     * @ description                : This method parse http error response and prepare respective exception object.  
     * @ args: httpRes          : Http Response object  
     *   
     * @ return: Exception       : QuickbookConnectionException or QuickbookBadRequestException or QuickbookException object
    **/    
    public static Exception parseHttpError(HttpResponse httpRes) {
        String message = '';
        if(httpRes.getStatuscode() == 400){
            System.debug('Error: ' + httpRes.getBody());
            message = parseError(httpRes);
            return new QuickbookException.QuickbookBadRequestException(message);
        } else if(httpRes.getStatuscode() == 401){
            message = 'Quickbook Access Token Expired or Invalid!';
            System.debug(message);
            return new QuickbookException.QuickbookConnectionException(message);
        } else if(httpRes.getStatuscode() == 403){
            message = 'Check Quickbook type in custom setting and re-establish connection.';
            System.debug(message);
            return new QuickbookException.QuickbookConnectionException(message);
        } else {
            message = 'Unexpected Error: Status Code '+httpRes.getStatuscode() + ' Message: ' + httpRes.getBody();
            System.debug(message);
            return new QuickbookException(message);
        } 
    }
    
     /**  
     * @ description                : This method parse http error response.  
     * @ args: httpRes          : HttpResponse object  
     *   
     * @ return: String           : error string
    **/
    public static String parseError(HttpResponse httpRes) {
        String error = httpRes.getBody();
        try {
            Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(error);
            Map<String, Object> fault = (Map<String, Object>)response_Map.get('Fault');
            List<Object> errors = (List<Object>)fault.get('Error');
            Map<String, Object> errorInfo = (Map<String, Object>)errors[0];
            System.debug('Error: ' + errorInfo.get('Detail'));                    
            return (String)errorInfo.get('Detail');
        } catch(Exception e){
            return 'Unknown error: ' + error;
        }                    
    } 

     /**  
     * @ description              : This method returns instance url as per quickbook type.  
     * @ args isProduction        : indicates quickbook type
     *   
     * @ return: String           : quickbook instance url
    **/    
    public static String getQuickbookInstanceUrl(boolean isProduction){
        String instanceUrl = '';                
        if(isProduction) {
            instanceUrl = QuickbookConstants.QB_PRODUCTION;
        } else {
            instanceUrl = QuickbookConstants.QB_SANDBOX;
        }
        
        return instanceUrl;
    }
}