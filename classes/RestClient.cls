/**
 * Created by DDiaconescu on 19/11/2018.
 */

/**
* RestClient.cls
* Description: defines the generic REST client
* defines calls for this callout from the process builder, batch jobs and an @future call
**/
global with sharing class RestClient extends RestCallout{

    /**
    * @description constructor
    */
    public RestClient() {
    }

    /**
    * @description GET wrapped method
    * @param String namedCredential
    * @param String path
    * @return RestResult restResult
    */
    public static RestResult getNow(String namedCredential, String path){
        RestClient client = new RestClient();
        return client.get(namedCredential, path, 200, 'All');
    }

    /**
    * @description GET wrapped method polymorphic with expected status code and log level
    * @param String namedCredential
    * @param String path
    * @param Integer expectedStatusCode
    * @return RestResult restResult
    */
    public static RestResult getNow(String namedCredential, String path, Integer expectedStatusCode, String logLevel){
        RestClient client = new RestClient();
        return client.get(namedCredential, path, expectedStatusCode, logLevel);
    }

    /**
    * @description GET wrapped future method
    * @param String namedCredential
    * @param String path
    */
    @future(callout=true)
    public static void getFuture(String namedCredential, String path) {
        RestClient client = new RestClient();
        client.get(namedCredential, path, 200, 'All');
    }

    /**
    * @description GET wrapped future method polymorphic with expected status code and log level
    * @param String namedCredential
    * @param String path
    * @param Integer expectedStatusCode
    */
    @future(callout=true)
    public static void getFuture(String namedCredential, String path, Integer expectedStatusCode, String logLevel) {
        RestClient client = new RestClient();
        client.get(namedCredential, path, expectedStatusCode, logLevel);
    }

   /**
   * @description POST wrapped method
   * @param String namedCredential
   * @param String path
   * @param String body
   * @return RestResult restResult
   */
    public static RestResult postNow(String namedCredential, String path, String body){
        RestClient client = new RestClient();
        return client.post(namedCredential, path, body, 200, 'All');
    }

    /**
   * @description POST wrapped method polymorphic with expected status code and log level
   * @param String namedCredential
   * @param String path
   * @param String body
   * @param Integer expectedStatusCode
   * @return RestResult restResult
   */
    public static RestResult postNow(String namedCredential, String path, String body, Integer expectedStatusCode, String logLevel){
        RestClient client = new RestClient();
        return client.post(namedCredential, path, body, expectedStatusCode, logLevel);
    }

    /**
    * @description POST wrapped future method
    * @param String namedCredential
    * @param String path
    * @param String body
    */
    @future(callout=true)
    public static void postFuture(String namedCredential, String path, String body) {
        RestClient client = new RestClient();
        client.post(namedCredential, path, body, 200, 'All');
    }

    /**
    * @description POST wrapped future method polymorphic with expected status code and log level
    * @param String namedCredential
    * @param String path
    * @param String body
    * @param Integer expectedStatusCode
    */
    @future(callout=true)
    public static void postFuture(String namedCredential, String path, String body, Integer expectedStatusCode, String logLevel) {
        RestClient client = new RestClient();
        client.post(namedCredential, path, body, expectedStatusCode, logLevel);
    }



    /**
    * @description wrapped invocable method
    * @param List<InvocableObject> invocableObject
    * @return List<RestResult> restResultList
    */
    @InvocableMethod (label='Make a REST call' description='execute a REST call, now on in the future')
    global static List<RestResult> restInvokable(List<InvocableObject> invocableObjectList) {
        InvocableObject invocableObject = invocableObjectList[0];
        Integer expectedStatusCode = invocableObject.expectedStatusCode != null ? invocableObject.expectedStatusCode : 200;
        String logLevel = invocableObject.logLevel != null ? invocableObject.logLevel : 'All';
        List<RestResult> restResultList = new List<RestResult>();
        if (invocableObject.method!= null && invocableObject.method.toUpperCase() == 'GET') {
            if (invocableObject.future) {
                getFuture(invocableObject.namedCredential, invocableObject.path, expectedStatusCode, logLevel);
            } else {
                restResultList.add(getNow(invocableObject.namedCredential, invocableObject.path, expectedStatusCode, logLevel));
            }
        } else if (invocableObject.method!= null && invocableObject.method.toUpperCase() == 'POST') {
            if (invocableObject.future) {
                postFuture(invocableObject.namedCredential, invocableObject.path,invocableObject.body, expectedStatusCode, logLevel);
            } else {
                RestResult res = postNow(invocableObject.namedCredential, invocableObject.path,invocableObject.body, expectedStatusCode, logLevel);
                restResultList.add(res);
            }
        }
        return restResultList;
    }


    /**
    * @description GET core method
    * @param String namedCredential
    * @param String path
    * @return RestResult restResult
    */
    public RestResult get(String namedCredential, String path, Integer expectedStatusCode, String logLevel) {
        RestResult restResult = new RestResult();
        RestLogBuilder logBuilder = new RestLogBuilder().withLogLevel(logLevel).withStartTime(System.now());
        try {
            this.setNamedCredential(namedCredential, path);
            this.setMethod('GET');
            this.call();
            if(this.httpResponse.getStatusCode() != expectedStatusCode) {
                throw new System.CalloutException('Status Code: ' + this.httpResponse.getStatusCode() + ' Response : ' + this.httpResponse.getBody());
            }
            restResult.success = true;
            restResult.data = this.httpResponse.getBody();
        } catch (Exception e) {
            logBuilder = logBuilder.withException(e).withErrorCode(String.valueOf(this.httpResponse.getStatusCode()));
            restResult.success = false;
            restResult.data = this.httpResponse.getBody();
            restResult.error = e.getMessage();
        } finally {
            logBuilder.withEndpoint(this.httpRequest.getEndpoint())
                    .withRequestBody(null)
                    .withResponseBody(this.httpResponse != null ? this.httpResponse.getBody() : null)
                    .withEndTime(System.now())
                    .queueLog();
        }
        return restResult;
    }


    /**
    * @description POST core method
    * @param String namedCredential
    * @param String path
    * @param String body
    * @return RestResult restResult
    */
    public RestResult post(String namedCredential, String path, String body, Integer expectedStatusCode, String logLevel) {
        RestResult restResult = new RestResult();
        RestLogBuilder logBuilder = new RestLogBuilder().withLogLevel(logLevel).withStartTime(System.now());
        try {
            this.setNamedCredential(namedCredential, path);
            this.setMethod('POST');
            this.setBody(body);
            this.call();

            if(this.httpResponse.getStatusCode() != expectedStatusCode) {
                throw new System.CalloutException('Status Code: ' + this.httpResponse.getStatusCode() + ' Response : ' + this.httpResponse.getBody());
            }
            restResult.success = true;
            restResult.data = this.httpResponse.getBody();
        } catch (Exception e) {
            logBuilder = logBuilder.withException(e).withErrorCode(String.valueOf(this.httpResponse.getStatusCode()));
            restResult.success = false;
            restResult.data = this.httpResponse.getBody();
            restResult.error = e.getMessage();
        } finally {
            logBuilder.withEndpoint(this.httpRequest.getEndpoint())
                    .withRequestBody(this.httpRequest.getBody())
                    .withResponseBody(this.httpResponse != null ? this.httpResponse.getBody() : null)
                    .withEndTime(System.now())
                    .queueLog();
        }
        return restResult;
    }

    /**
    * RestResult.cls
    * Description: custom response from the REST client
    **/
    global class RestResult {
        /**
        * @description defines call outcome
        */
        @InvocableVariable
        global Boolean success;
        /**
        * @description defines call return data
        */
        @InvocableVariable
        global String data;
        /**
        * @description defines call error messages
        */
        @InvocableVariable
        global String error;
    }

    /**
    * InvocableObject.cls
    * Description: defines an invocable object
    **/
    global class InvocableObject {
        /**
        * @description defines namedCredential
        */
        @InvocableVariable(label='endpoint' description='' required=true )
        global String namedCredential;
        /**
        * @description defines path
        */
        @InvocableVariable(label='path' description='' required=true)
        global String path;
        /**
        * @description defines method
        */
        @InvocableVariable(label='method' description='' required=true)
        global String method;
        /**
        * @description defines @future execution
        */
        @InvocableVariable(label='future call' description='' required=true)
        global Boolean future;
        /**
        * @description defines post body
        */
        @InvocableVariable(label='body' description='' required=false)
        global String body;
        /**
       * @description defines expected status code
       */
        @InvocableVariable(label='expected status code' description='' required=false)
        global Integer expectedStatusCode;
        /**
        * @description defines log level
        */
        @InvocableVariable(label='log level' description='' required=false)
        global String logLevel;
    }

}