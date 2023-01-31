@IsTest
private class aef_AccountRegistrationModule_Test {
    @IsTest
    private static void testEnsureAfterInsertTriggersAccountUpdate() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
        Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);

        // =====================================
        // Stubbing
        // =====================================
        aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
        aef_AccountRegistrationService mockService = (aef_AccountRegistrationService)aef_MockUtility.mockUtility(aef_AccountRegistrationService.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();
        aef_MockUtility.Mocks.when(mockService.filterAccountsWithName((List<Account>)fflib_Match.eq(accounts))).thenReturn(accounts);
        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_AccountRegistrationModule module = aef_AccountRegistrationModule.newInstance();
        module.onAfterInsert(accounts, mockUOW);

        Test.stopTest();

        // verify worker was enqueued correctly
        fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(aef_ApplicationUnitOfWork.AsyncStagingWorker.class);
        ((aef_ApplicationUnitOfWork)aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(1))).registerAsyncWork((aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.capture());

        aef_ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.getValue();

        System.assertEquals(aef_AccountRegistrationModule.AsyncRegisterAccountWithKey.class, stagedWorker.classType, 'Expected aef_AccountRegistrationModule.AsyncRegisterAccountWithKey to be enqueued');
        System.assertEquals(new Map<String, Object>{ 'accountIds' => new Set<Id>{accounts[0].Id,accounts[1].Id}}, stagedWorker.params, 'Unexpected params');
    }

    @IsTest
    private static void testEnsureAccountUpdatesAreTriggeredInAsyncWorker() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
        Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);

        List<Account> updatedAccounts = new List<Account>{
                accounts[0].clone(true), accounts[1].clone(true)
        };
        updatedAccounts[0].Registration_Key__c = aef_AccountRegistrationService_Test.MOCK_KEY;
        updatedAccounts[1].Registration_Key__c = aef_AccountRegistrationService_Test.MOCK_KEY;

        // =====================================
        // Stubbing
        // =====================================
        aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
        aef_AccountsSelector mockSelector = (aef_AccountsSelector)aef_MockUtility.mockSelector(aef_AccountsSelector.class);
        aef_AccountRegistrationService mockService = (aef_AccountRegistrationService)aef_MockUtility.mockUtility(aef_AccountRegistrationService.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();

        aef_MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.eq(accountsMap.keySet()))).thenReturn(accounts);

        aef_MockUtility.Mocks.when(mockUOW.registerDirty((Account)fflib_Match.anySObject(), (Set<SObjectField>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyString())).thenAnswer(new aef_MockUtility.AnswerGenericRegisterUnitOfWorkDML());

        aef_MockUtility.Mocks.when(mockService.getAccountRegistrationKey((List<Account>)fflib_Match.eq(accounts))).thenReturn(updatedAccounts);

        aef_MockUtility.Mocks.stopStubbing();

        Test.setMock(HttpCalloutMock.class, new aef_AccountRegistrationService_Test.AccountRegistrationCalloutMock(200, '{"success":true,"secretKey":"' + aef_AccountRegistrationService_Test.MOCK_KEY + '"}'));

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_AccountRegistrationModule.AsyncRegisterAccountWithKey asyncWorker = new aef_AccountRegistrationModule.AsyncRegisterAccountWithKey();

        // deserialise the parameters (this is what the async framework calls before the worker runs)
        asyncWorker.deserialiseParams(JSON.serialize(new Map<String, Object>{'accountIds' => new Set<Id>{accounts[0].Id, accounts[1].Id}}));

        // execute the worker
        asyncWorker.execute(mockUOW);

        Test.stopTest();

        System.assertEquals(Account.SObjectType, asyncWorker.getSObjectTypeGroup(), 'SObject group must be set to Account for proper async grouping');
        System.assertEquals(aef_AccountRegistrationModule.AsyncRegisterAccountWithKey.class, asyncWorker.getClassType(), 'Due to lack of reflection, getClassType must return aef_AccountRegistrationModule.AsyncRegisterAccountWithKey');

        fflib_ArgumentCaptor updateableAccountsCapture = fflib_ArgumentCaptor.forClass(List<Account>.class);
        ((aef_ApplicationUnitOfWork) aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(2))).registerDirty((Contact)updateableAccountsCapture.capture(), (Set<SObjectField>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyString());

        List<Object> updateableAccounts = (List<Object>)updateableAccountsCapture.getAllValues();
        System.assertEquals(2, updateableAccounts.size(), 'Expected to update 2 records');

        System.assertEquals(updatedAccounts[0].Id, ((Account)updateableAccounts[0]).Id, 'Did not expect the current Contact');
        System.assertEquals(updatedAccounts[0].Registration_Key__c, ((Account)updateableAccounts[0]).Registration_Key__c, 'Did not expect the current Number_of_Open_Cases__c');

        System.assertEquals(updatedAccounts[1].Id, ((Account)updateableAccounts[1]).Id, 'Did not expect the current Contact');
        System.assertEquals(updatedAccounts[1].Registration_Key__c, ((Account)updateableAccounts[1]).Registration_Key__c, 'Did not expect the current Number_of_Open_Cases__c');
    }
}