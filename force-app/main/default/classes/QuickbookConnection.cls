/**
*  Purpose         :   This class is responsible for Quickbook connection operations
*
*  Created Date    :   08/07/2021
*
*  Created By      :   Suresh Koumar
*
*  Revision Logs   :   V_2.0 - Created
*
**/
public with sharing class QuickbookConnection {
    public static String docId { get; set;}
    public static String invoiceJson { get; set;}
     
    public QuickbookConnection(ApexPages.StandardController connController) {}
    /**
    * @ description: This method calls the quickbook oauth api to get connection code 
    *
    * @ return: void
    **/
    public static PageReference getConnectionCode(){
        QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
        System.debug('Quickbook connection custom setting info retrieved.');
        if(settingInfo != null) {
            String scope = 'com.intuit.quickbooks.accounting';
            String redirectUrl = QuickbookSFHelper.getRedirectUrl();
            System.debug('redirectUrl: ' + redirectUrl);
            String oauthUrl = QuickbookConstants.QB_OAUTH_CODE_URL + '?client_id=' + settingInfo.ClientId__c + '&response_type=code&scope='
                + scope + '&redirect_uri=' + redirectUrl + '&state=' + QuickbookConstants.CONNECTION_NAME; 
            System.debug('oauthUrl##'+oauthUrl);
            PageReference reference = new PageReference(oauthUrl);
            return reference;
        } else {
            QuickbookHelper.setErrorMessage(QuickbookConstants.CUSTOM_SETTING_ERROR);
            String url = ApexPages.CurrentPage().getUrl() == null ? QUickbookConstants.SF_HOST_URL : ApexPages.CurrentPage().getUrl();
            return new PageReference(url); 
        }
    }
    
    /**
    * @ description: This method gets the access token from the quickbook and stores it in org
    *
    * @ return: void
    **/
    public static void getAccessToken(){
        QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
        System.debug('Quickbook connection custom setting info retrieved.');
        if(settingInfo != null) {

            String oAuthCode = ApexPages.currentPage().getParameters().get('code');
            String realmId = ApexPages.currentPage().getParameters().get('realmId');
            String state = ApexPages.currentPage().getParameters().get('state');
            String requestBody = 'grant_type=authorization_code&code='+oAuthCode+'&redirect_uri='+QuickbookSFHelper.getRedirectUrl();
            HttpResponse httpRes = QuickbookHelper.postAPICall(QuickbookConstants.QB_OAUTH_TOKEN_URL,
                                   QuickbookConstants.getBasicOauthString(settingInfo.ClientId__c, settingInfo.ClientSecret__c),
                                   'application/x-www-form-urlencoded', requestBody);
            if(httpRes.getStatusCode() == 200) {
                Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());
                System.debug('Response received: ' + response_Map);
                Quickbook_Connection__c quickBookConnection = QuickbookHelper.getQuickbookConnection();
                quickBookConnection = QuickbookHelper.setQuickbookConnection(response_Map, quickBookConnection);
                quickBookConnection.Company_Id__c = realmId;
                quickBookConnection.Name = QuickbookConstants.CONNECTION_NAME;
                
                //Check isupdatable or isCreatable
                if (Schema.sObjectType.Quickbook_Connection__c.isCreateable() || Schema.sObjectType.Quickbook_Connection__c.isUpdateable()) {
                    upsert as user quickBookConnection ;
                }
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm,'Authenticated Successfully.'));
            } else{
                QuickbookHelper.setErrorMessage('Unexpected Error: Status Code '+httpRes.getStatuscode() + ' Message: ' + httpRes.getBody());
            }
        } else {
            QuickbookHelper.setErrorMessage(QuickbookConstants.CUSTOM_SETTING_ERROR);
        }
    }
    
    /**
    * @ description                     : This method refresh the expired access token.
    * @args: quickBookConnection        : Quickbook connection record
    * 
    * @ return: Quickbook_Connection__c : updated quickbook connection record
    **/
    public static Quickbook_Connection__c refreshAccessToken(Quickbook_Connection__c quickBookConnection){
        QuickbookSetting__c settingInfo = QuickbookHelper.getConfiguration();
        System.debug('Quickbook connection custom setting info retrieved.');
        if(settingInfo != null) {
            
            if(quickBookConnection != null && !String.isBlank(quickBookConnection.Refresh_Token__c)) {
                String requestBody = 'grant_type=refresh_token&refresh_token='+quickBookConnection.Refresh_Token__c;
                
                System.debug('Calling Quickbook refresh token api.');
                HttpResponse httpRes = QuickbookHelper.postAPICall(QuickbookConstants.QB_OAUTH_TOKEN_URL, 
                                       QuickbookConstants.getBasicOauthString(settingInfo.ClientId__c, settingInfo.ClientSecret__c),
                                                                   'application/x-www-form-urlencoded', requestBody);
                if(httpRes.getStatusCode() == 200) {
                    Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());
                    System.debug('Response received Successfully: ' + response_Map);
                    return QuickbookHelper.setQuickbookConnection(response_Map, quickBookConnection); 
                } else {
                    throw QuickbookHelper.parseHttpError(httpRes);
                }
            } else { 
                System.debug('Refresh token not found to refresh access token.');
                throw new QuickbookException.QuickbookConnectionException('Refresh token not found to refresh access token.');
            }
        } else {
            System.debug(QuickbookConstants.CUSTOM_SETTING_ERROR);
            throw new QuickbookException.QuickbookConnectionException(QuickbookConstants.CUSTOM_SETTING_ERROR);
        }
    }    
}