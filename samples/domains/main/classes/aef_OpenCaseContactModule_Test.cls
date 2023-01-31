@IsTest
private class aef_OpenCaseContactModule_Test {
    @IsTest
    private static void testEnsureAfterUpdateTriggersContactUpdate() {
        List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(1, null, true);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].ContactId = contacts[0].Id;
        cases[0].Status = 'Closed';
        cases[1].ContactId = contacts[0].Id;
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
        aef_MockUtility.Mocks.when(mockOpenCaseService.filterCasesWithContactId((List<Case>)fflib_Match.eq(oldCases))).thenReturn(oldCases);
        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_OpenCaseContactModule module = aef_OpenCaseContactModule.newInstance();
        module.onAfterUpdate(cases, new Map<Id, Case>(oldCases), mockUOW);

        Test.stopTest();

        // verify worker was enqueued correctly
        fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(aef_ApplicationUnitOfWork.AsyncStagingWorker.class);
        ((aef_ApplicationUnitOfWork)aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(1))).registerAsyncWork((aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.capture());

        aef_ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.getValue();

        System.assertEquals(aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers.class, stagedWorker.classType, 'Expected aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers to be enqueued');
        System.assertEquals(new Map<String, Object>{ 'contactIds' => new Set<Id>{contacts[0].Id}}, stagedWorker.params, 'Unexpected params');
    }

    @IsTest
    private static void testEnsureAfterInsertTriggersContactUpdate() {
        List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(1, null, true);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].ContactId = contacts[0].Id;
        cases[0].Status = 'Closed';
        cases[1].ContactId = contacts[0].Id;
        cases[1].Status = 'Closed';
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        // =====================================
        // Stubbing
        // =====================================
        aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
        aef_OpenCaseService mockOpenCaseService = (aef_OpenCaseService)aef_MockUtility.mockUtility(aef_OpenCaseService.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();

        aef_MockUtility.Mocks.when(mockOpenCaseService.filterCasesWithContactId((List<Case>)fflib_Match.eq(cases))).thenReturn(new List<Case>());

        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_OpenCaseContactModule module = aef_OpenCaseContactModule.newInstance();
        module.onAfterInsert(cases, mockUOW);

        Test.stopTest();

        // verify worker was enqueued correctly
        fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(aef_ApplicationUnitOfWork.AsyncStagingWorker.class);
        ((aef_ApplicationUnitOfWork)aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(1))).registerAsyncWork((aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.capture());

        aef_ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.getValue();

        System.assertEquals(aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers.class, stagedWorker.classType, 'Expected aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers to be enqueued');
        System.assertEquals(new Map<String, Object>{ 'contactIds' => new Set<Id>{contacts[0].Id}}, stagedWorker.params, 'Unexpected params');
    }

    @IsTest
    private static void testEnsureContactUpdatesAreTriggeredInAsyncWorker() {
        List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(1, null, true);
        Map<Id, Contact> contactsMap = new Map<Id, Contact>(contacts);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].ContactId = contacts[0].Id;
        cases[0].Status = 'New';
        cases[1].ContactId = contacts[0].Id;
        cases[1].Status = 'New';
        Map<Id, Case> casesMap = new Map<Id, Case>(cases);

        Map<Id, List<Case>> contactIdOpenCasesMap = new Map<Id, List<Case>>();
        contactIdOpenCasesMap.put(contacts[0].Id, new List<Case>{cases[0]});
        Map<Id, List<Case>> contactIdClosedCasesMap = new Map<Id, List<Case>>();
        contactIdClosedCasesMap.put(contacts[0].Id, new List<Case>{cases[1]});

        List<Contact> updatedContact = new List<Contact>{
                contacts[0].clone(true)
        };
        updatedContact[0].Number_of_Open_Cases__c = 2;
        updatedContact[0].Number_of_Closed_Cases__c = 0;

        // =====================================
        // Stubbing
        // =====================================
        aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
        aef_CasesSelector mockCasesSelector = (aef_CasesSelector)aef_MockUtility.mockSelector(aef_CasesSelector.class);
        aef_ContactsSelector mockContactsSelector = (aef_ContactsSelector)aef_MockUtility.mockSelector(aef_ContactsSelector.class);
        aef_OpenCaseService mockOpenCaseService = (aef_OpenCaseService)aef_MockUtility.mockUtility(aef_OpenCaseService.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();

        aef_MockUtility.Mocks.when(mockCasesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(cases);
        aef_MockUtility.Mocks.when(mockContactsSelector.selectById((Set<Id>)fflib_Match.eq(contactsMap.keySet()))).thenReturn(contacts);

        aef_MockUtility.Mocks.when(mockUOW.registerDirty((Contact)fflib_Match.anySObject(), (Set<SObjectField>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyString())).thenAnswer(new aef_MockUtility.AnswerGenericRegisterUnitOfWorkDML());

        aef_MockUtility.Mocks.when(mockOpenCaseService.populateContactNumberOfOpenCases((Map<Id, List<Case>>)fflib_Match.eq(contactIdOpenCasesMap))).thenReturn(updatedContact);
        aef_MockUtility.Mocks.when(mockOpenCaseService.populateContactNumberOfClosedCases((Map<Id, List<Case>>)fflib_Match.eq(contactIdClosedCasesMap))).thenReturn(updatedContact);

        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers asyncWorker = new aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers();

        // deserialise the parameters (this is what the async framework calls before the worker runs)
        asyncWorker.deserialiseParams(JSON.serialize(new Map<String, Object>{'contactIds' => new Set<Id>{contacts[0].Id}}));

        // execute the worker
        asyncWorker.execute(mockUOW);

        Test.stopTest();

        System.assertEquals(Case.SObjectType, asyncWorker.getSObjectTypeGroup(), 'SObject group must be set to Case for proper async grouping');
        System.assertEquals(aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers.class, asyncWorker.getClassType(), 'Due to lack of reflection, getClassType must return aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers');

        // verify the Case will be updated correctly and capture the arguments for review
        fflib_ArgumentCaptor updateableContactsCapture = fflib_ArgumentCaptor.forClass(List<Case>.class);
        ((aef_ApplicationUnitOfWork) aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(2))).registerDirty((Contact)updateableContactsCapture.capture(), (Set<SObjectField>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyString());

        // verify both cases passed in were queued for updating
        List<Object> updateableContact = (List<Object>)updateableContactsCapture.getAllValues();
        System.assertEquals(1, updateableContact.size(), 'Expected to update 1 case records');

        // verify the records passed into uow and that the priority was updated to High
        System.assertEquals(updatedContact[0].Id, ((Contact)updateableContact[0]).Id, 'Did not expect the current Contact');
        System.assertEquals(updatedContact[0].Number_of_Open_Cases__c, ((Contact)updateableContact[0]).Number_of_Open_Cases__c, 'Did not expect the current Number_of_Open_Cases__c');
        System.assertEquals(updatedContact[0].Number_of_Closed_Cases__c, ((Contact)updateableContact[0]).Number_of_Closed_Cases__c, 'Did not expect the current Number_of_Closed_Cases__c');
    }
}