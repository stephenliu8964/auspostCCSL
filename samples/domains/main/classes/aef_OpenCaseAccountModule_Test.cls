@IsTest
private class aef_OpenCaseAccountModule_Test {
    @IsTest
    private static void testEnsureAfterUpdateTriggersAccountUpdate() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(1, true);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].AccountId = accounts[0].Id;
        cases[0].Status = 'Closed';
        cases[1].AccountId = accounts[0].Id;
        cases[1].Status = 'Closed';
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        List<Case> oldCases = new List<Case>{
                cases[0].clone(true),
                cases[1].clone(true)
        };
        oldCases[0].Status = 'New';
        oldCases[1].Status = 'New';

        // =====================================
        // Stubbing
        // =====================================
        aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
        aef_OpenCaseService mockOpenCaseService = (aef_OpenCaseService)aef_MockUtility.mockUtility(aef_OpenCaseService.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();

        aef_MockUtility.Mocks.when(mockOpenCaseService.filterCasesWithAccountId((List<Case>)fflib_Match.eq(oldCases))).thenReturn(oldCases);

        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_OpenCaseAccountModule module = aef_OpenCaseAccountModule.newInstance();
        module.onAfterUpdate(cases, new Map<Id, Case>(oldCases), mockUOW);

        Test.stopTest();

        // verify worker was enqueued correctly
        fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(aef_ApplicationUnitOfWork.AsyncStagingWorker.class);
        ((aef_ApplicationUnitOfWork)aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(1))).registerAsyncWork((aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.capture());

        aef_ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.getValue();

        System.assertEquals(aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers.class, stagedWorker.classType, 'Expected aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers to be enqueued');
        System.assertEquals(new Map<String, Object>{ 'accountIds' => new Set<Id>{accounts[0].Id}}, stagedWorker.params, 'Unexpected params');
    }

    @IsTest
    private static void testEnsureAfterInsertTriggersAccountUpdate() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(1, true);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].AccountId = accounts[0].Id;
        cases[0].Status = 'Closed';
        cases[1].AccountId = accounts[0].Id;
        cases[1].Status = 'Closed';
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        // =====================================
        // Stubbing
        // =====================================
        aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
        aef_OpenCaseService mockOpenCaseService = (aef_OpenCaseService)aef_MockUtility.mockUtility(aef_OpenCaseService.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();

        aef_MockUtility.Mocks.when(mockOpenCaseService.filterCasesWithAccountId((List<Case>)fflib_Match.eq(cases))).thenReturn(new List<Case>());

        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_OpenCaseAccountModule module = aef_OpenCaseAccountModule.newInstance();
        module.onAfterInsert(cases, mockUOW);

        Test.stopTest();

        // verify worker was enqueued correctly
        fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(aef_ApplicationUnitOfWork.AsyncStagingWorker.class);
        ((aef_ApplicationUnitOfWork)aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(1))).registerAsyncWork((aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.capture());

        aef_ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.getValue();

        System.assertEquals(aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers.class, stagedWorker.classType, 'Expected aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers to be enqueued');
        System.assertEquals(new Map<String, Object>{ 'accountIds' => new Set<Id>{accounts[0].Id}}, stagedWorker.params, 'Unexpected params');
    }

    @IsTest
    private static void testEnsureAccountUpdatesAreTriggeredInAsyncWorker() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(1, true);
        Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].AccountId = accounts[0].Id;
        cases[0].Status = 'New';
        cases[1].AccountId = accounts[0].Id;
        cases[1].Status = 'New';
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        Map<Id, List<Case>> accountIdOpenCasesMap = new Map<Id, List<Case>>();
        accountIdOpenCasesMap.put(accounts[0].Id, new List<Case>{cases[0]});
        Map<Id, List<Case>> accountIdClosedCasesMap = new Map<Id, List<Case>>();
        accountIdClosedCasesMap.put(accounts[0].Id, new List<Case>{cases[1]});

        List<Account> updatedAccount = new List<Account>{
                accounts[0].clone(true)
        };
        updatedAccount[0].Number_of_Open_Cases__c = 2;
        updatedAccount[0].Number_of_Closed_Cases__c = 0;

        // =====================================
        // Stubbing
        // =====================================
        aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
        aef_CasesSelector mockCasesSelector = (aef_CasesSelector)aef_MockUtility.mockSelector(aef_CasesSelector.class);
        aef_AccountsSelector mockAccountsSelector = (aef_AccountsSelector)aef_MockUtility.mockSelector(aef_AccountsSelector.class);
        aef_OpenCaseService mockOpenCaseService = (aef_OpenCaseService)aef_MockUtility.mockUtility(aef_OpenCaseService.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();

        aef_MockUtility.Mocks.when(mockCasesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(cases);
        aef_MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.eq(accountsMap.keySet()))).thenReturn(accounts);

        aef_MockUtility.Mocks.when(mockUOW.registerDirty((Account)fflib_Match.anySObject(), (Set<SObjectField>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyString())).thenAnswer(new aef_MockUtility.AnswerGenericRegisterUnitOfWorkDML());

        aef_MockUtility.Mocks.when(mockOpenCaseService.populateAccountNumberOfOpenCases((Map<Id, List<Case>>)fflib_Match.eq(accountIdOpenCasesMap))).thenReturn(updatedAccount);
        aef_MockUtility.Mocks.when(mockOpenCaseService.populateAccountNumberOfClosedCases((Map<Id, List<Case>>)fflib_Match.eq(accountIdClosedCasesMap))).thenReturn(updatedAccount);

        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers asyncWorker = new aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers();

        // deserialise the parameters (this is what the async framework calls before the worker runs)
        asyncWorker.deserialiseParams(JSON.serialize(new Map<String, Object>{'accountIds' => new Set<Id>{accounts[0].Id}}));

        // execute the worker
        asyncWorker.execute(mockUOW);

        Test.stopTest();

        System.assertEquals(Case.SObjectType, asyncWorker.getSObjectTypeGroup(), 'SObject group must be set to Case for proper async grouping');
        System.assertEquals(aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers.class, asyncWorker.getClassType(), 'Due to lack of reflection, getClassType must return aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers');

        // verify the Case will be updated correctly and capture the arguments for review
        fflib_ArgumentCaptor updateableAccountsCapture = fflib_ArgumentCaptor.forClass(List<Case>.class);
        ((aef_ApplicationUnitOfWork) aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(2))).registerDirty((Account)updateableAccountsCapture.capture(), (Set<SObjectField>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyString());

        // verify both cases passed in were queued for updating
        List<Object> updateableAccount = (List<Object>)updateableAccountsCapture.getAllValues();
        System.assertEquals(1, updateableAccount.size(), 'Expected to update 2 case records');

        // verify the records passed into uow and that the priority was updated to High
        System.assertEquals(updatedAccount[0].Id, ((Account)updateableAccount[0]).Id, 'Did not expect the current Account');
        System.assertEquals(updatedAccount[0].Number_of_Open_Cases__c, ((Account)updateableAccount[0]).Number_of_Open_Cases__c, 'Did not expect the current Number_of_Open_Cases__c');
        System.assertEquals(updatedAccount[0].Number_of_Closed_Cases__c, ((Account)updateableAccount[0]).Number_of_Closed_Cases__c, 'Did not expect the current Number_of_Closed_Cases__c');
    }
}