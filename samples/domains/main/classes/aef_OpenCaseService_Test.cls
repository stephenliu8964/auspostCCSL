@IsTest
private class aef_OpenCaseService_Test {
    @IsTest
    private static void testFilterCasesWithAccountId() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].AccountId = accounts[0].Id;
        cases[1].AccountId = null;
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        aef_CasesSelector mockSelector = (aef_CasesSelector)aef_MockUtility.mockSelector(aef_CasesSelector.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();
        aef_MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.eq(casesMap.keySet()))).thenReturn(cases);
        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_OpenCaseService service = aef_OpenCaseService.getInstance();
        List<Id> output = new List<Id>(service.filterCasesWithAccountId(casesMap.keySet()));
        List<Case> outputCases = new List<Case>(service.filterCasesWithAccountId(cases));

        Test.stopTest();

        // verify selectById was called
        ((aef_CasesSelector)aef_MockUtility.Mocks.verify(mockSelector, aef_MockUtility.Mocks.times(1))).selectById(casesMap.keySet());

        System.assertEquals(1, output.size());
        System.assertEquals(cases[0].Id, output[0]);

        System.assertEquals(1, outputCases.size());
        System.assertEquals(accounts[0].Id, outputCases[0].AccountId);
    }

    @IsTest
    private static void testFilterCasesWithContactId() {
        List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(2, null, true);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].ContactId = contacts[0].Id;
        cases[1].ContactId = null;
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        aef_CasesSelector mockSelector = (aef_CasesSelector)aef_MockUtility.mockSelector(aef_CasesSelector.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();
        aef_MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.eq(casesMap.keySet()))).thenReturn(cases);
        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_OpenCaseService service = aef_OpenCaseService.getInstance();
        List<Id> output = new List<Id>(service.filterCasesWithContactId(casesMap.keySet()));
        List<Case> outputCases = new List<Case>(service.filterCasesWithContactId(cases));

        Test.stopTest();

        // verify selectById was called
        ((aef_CasesSelector)aef_MockUtility.Mocks.verify(mockSelector, aef_MockUtility.Mocks.times(1))).selectById(casesMap.keySet());

        System.assertEquals(1, output.size());
        System.assertEquals(cases[0].Id, output[0]);

        System.assertEquals(1, outputCases.size());
        System.assertEquals(contacts[0].Id, outputCases[0].ContactId);
    }

    @IsTest
    private static void testPopulateAccountCaseNumbers() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(1, true);
        Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].AccountId = accounts[0].Id;
        cases[0].Status = 'New';
        cases[1].AccountId = accounts[0].Id;
        cases[1].Status = 'Closed';
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        aef_AccountsSelector mockSelector = (aef_AccountsSelector)aef_MockUtility.mockSelector(aef_AccountsSelector.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();
        aef_MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.eq(accountsMap.keySet()))).thenReturn(accounts);
        aef_MockUtility.Mocks.stopStubbing();

        Map<Id, List<Case>> accountIdsWithOpenCases = new Map<Id, List<Case>>();
        accountIdsWithOpenCases.put(accounts[0].Id, new List<Case>{cases[0]});

        Map<Id, List<Case>> accountIdsWithClosedCases = new Map<Id, List<Case>>();
        accountIdsWithClosedCases.put(accounts[0].Id, new List<Case>{cases[1]});

        Test.startTest();

        aef_OpenCaseService service = aef_OpenCaseService.getInstance();
        List<Account> openCaseAccount = new List<Account>(service.populateAccountNumberOfOpenCases(accountIdsWithOpenCases));
        List<Account> closedCaseAccount = new List<Account>(service.populateAccountNumberOfClosedCases(accountIdsWithClosedCases));

        Test.stopTest();

        System.assertEquals(1, openCaseAccount[0].Number_of_Open_Cases__c);
        System.assertEquals(1, closedCaseAccount[0].Number_of_Closed_Cases__c);
    }

    @IsTest
    private static void testPopulateContactCaseNumbers() {
        List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(1, null, true);
        Map<Id, Contact> contactsMap = new Map<Id, Contact>(contacts);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].ContactId = contacts[0].Id;
        cases[0].Status = 'New';
        cases[1].ContactId = contacts[0].Id;
        cases[1].Status = 'Closed';
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        aef_ContactsSelector mockSelector = (aef_ContactsSelector)aef_MockUtility.mockSelector(aef_ContactsSelector.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();
        aef_MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.eq(contactsMap.keySet()))).thenReturn(contacts);
        aef_MockUtility.Mocks.stopStubbing();

        Map<Id, List<Case>> contactIdsWithOpenCases = new Map<Id, List<Case>>();
        contactIdsWithOpenCases.put(contacts[0].Id, new List<Case>{cases[0]});

        Map<Id, List<Case>> contactIdsWithClosedCases = new Map<Id, List<Case>>();
        contactIdsWithClosedCases.put(contacts[0].Id, new List<Case>{cases[1]});

        Test.startTest();

        aef_OpenCaseService service = aef_OpenCaseService.getInstance();
        List<Contact> openCaseContact = new List<Contact>(service.populateContactNumberOfOpenCases(contactIdsWithOpenCases));
        List<Contact> closedCaseContact = new List<Contact>(service.populateContactNumberOfClosedCases(contactIdsWithClosedCases));

        Test.stopTest();

        System.assertEquals(1, openCaseContact[0].Number_of_Open_Cases__c);
        System.assertEquals(1, closedCaseContact[0].Number_of_Closed_Cases__c);
    }
}