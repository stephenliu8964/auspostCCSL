public inherited sharing class aef_AccountRegistrationService {
    public static aef_AccountRegistrationService getInstance() {
        return (aef_AccountRegistrationService)aef_Application.Utilities.getInstance(aef_AccountRegistrationService.class);
    }

    public Set<Id> filterAccountsWithName(Set<Id> accountIds) {
        List<Account> accounts = ((aef_AccountsSelector)aef_AccountsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{Account.Name})).selectById(accountIds);
        return new Map<Id, Account>(filterAccountsWithName(accounts)).keySet();
    }

    public List<Account> filterAccountsWithName(List<Account> accounts) {
        List<SObject> output = new List<SObject>();
        for(Account record : accounts) {
            if(record.Name != null) {
                output.add(record);
            }
        }
        return output;
    }

    public List<Account> getAccountRegistrationKey(List<Account> accounts) {
        Http http = new Http();

        try {
            for(Account account : accounts) {
                doAccountRegistrationCallout(account, http);
            }

        } catch(Exception ex) {
            aef_ApplicationLogger.getInstance().logException(aef_ApplicationLogger.wrapException(ex), 'Account Registration', 'aef_AccountRegistrationService', 'getAccountRegistrationKey', 'aef_AccountTriggerHandler', aef_ApplicationLogger.LoggingLevel.ERROR);
        }

        return accounts;
    }

    private Account doAccountRegistrationCallout(Account account, Http http) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://enterpriseminded.com/api/');
        request.setMethod('POST');

        Payload body = new Payload(account.Name);
        request.setBody(JSON.serialize(body));
        request.setHeader('Accept', '*/*');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        System.debug(request);

        HttpResponse response = http.send(request);
        System.debug(response);
        System.debug(response.getBody());

        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        account.Registration_Key__c = response.getStatusCode() == 200 ? (String) results.get('secretKey') : response.getStatusCode() == 500 ? (String) results.get('error') : 'Unknown Response';

        return account;
    }

    class Payload {
        String business_name;

        public Payload(String business_name){
            this.business_name = business_name;
        }
    }
}