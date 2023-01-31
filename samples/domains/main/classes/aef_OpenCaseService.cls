public inherited sharing class aef_OpenCaseService {

    public static aef_OpenCaseService getInstance() {
        return (aef_OpenCaseService)aef_Application.Utilities.getInstance(aef_OpenCaseService.class);
    }

    public Set<Id> filterCasesWithAccountId(Set<Id> caseIds) {
        List<Case> cases = ((aef_CasesSelector)aef_CasesSelector.newInstance().setFieldOverrides(new Set<SObjectField>{Case.IsClosed,Case.AccountId})).selectById(caseIds);
        return new Map<Id, Case>(filterCasesWithAccountId(cases)).keySet();
    }

    public List<Case> filterCasesWithAccountId(List<Case> cases) {
        List<SObject> output = new List<SObject>();
        for(Case record : cases) {
            if(record.AccountId != null) {
                output.add(record);
            }
        }
        return output;
    }

    public Set<Id> filterCasesWithContactId(Set<Id> caseIds) {
        List<Case> cases = ((aef_CasesSelector)aef_CasesSelector.newInstance().setFieldOverrides(new Set<SObjectField>{Case.IsClosed,Case.ContactId})).selectById(caseIds);
        return new Map<Id, Case>(filterCasesWithContactId(cases)).keySet();
    }

    public List<Case> filterCasesWithContactId(List<Case> cases) {
        List<SObject> output = new List<SObject>();
        for(Case record : cases) {
            if(record.ContactId != null) {
                output.add(record);
            }
        }
        return output;
    }

    public List<Account> populateAccountNumberOfOpenCases(Map<Id, List<Case>> accountIdsWithOpenCases) {
        List<Account> output = aef_AccountsSelector.newInstance().selectById(accountIdsWithOpenCases.keySet());

        for(Account record : output) {
            record.Number_of_Open_Cases__c = accountIdsWithOpenCases.get(record.Id)?.size();
        }
        return output;
    }

    public List<Account> populateAccountNumberOfClosedCases(Map<Id, List<Case>> accountIdsWithClosedCases) {
        List<Account> output = aef_AccountsSelector.newInstance().selectById(accountIdsWithClosedCases.keySet());

        for(Account record : output) {
            record.Number_of_Closed_Cases__c = accountIdsWithClosedCases.get(record.Id)?.size();
        }
        return output;
    }

    public List<Contact> populateContactNumberOfOpenCases(Map<Id, List<Case>> contactIdsWithOpenCases) {
        List<Contact> output = aef_ContactsSelector.newInstance().selectById(contactIdsWithOpenCases.keySet());

        for(Contact record : output) {
            record.Number_of_Open_Cases__c = contactIdsWithOpenCases.get(record.Id)?.size();
        }
        return output;
    }

    public List<Contact> populateContactNumberOfClosedCases(Map<Id, List<Case>> contactIdsWithClosedCases) {
        List<Contact> output = aef_ContactsSelector.newInstance().selectById(contactIdsWithClosedCases.keySet());

        for(Contact record : output) {
            record.Number_of_Closed_Cases__c = contactIdsWithClosedCases.get(record.Id)?.size();
        }
        return output;
    }
}