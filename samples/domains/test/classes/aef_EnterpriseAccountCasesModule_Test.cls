/**
 * @description
 * Test class for aef_EnterpriseAccountCasesModule
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
private class aef_EnterpriseAccountCasesModule_Test {

	/**
	 * Test:
	 *  When an account is updated to be classified as an 'enterprise' account, make sure the async job to update case priority is triggered
	 */
	@IsTest
	private static void testEnsureAfterUpdateTriggersCaseUpdate() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].AnnualRevenue = 5000000;
		accounts[1].AnnualRevenue = 5000000;

		List<Account> oldAccounts = new List<Account>{
			accounts[0].clone(true),
			accounts[1].clone(true)
		};
		oldAccounts[0].AnnualRevenue = 2000000;
		oldAccounts[1].AnnualRevenue = 2000000;

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
		aef_EnterpriseService mockEnterpriseService = (aef_EnterpriseService)aef_MockUtility.mockUtility(aef_EnterpriseService.class);

		// set up our responses
		aef_MockUtility.Mocks.startStubbing();

		// filterEnterpriseAccounts should return nothing since the accounts in oldmap did were not classed as 'enterprise'
		aef_MockUtility.Mocks.when(mockEnterpriseService.filterEnterpriseAccounts((List<Account>)fflib_Match.eq(oldAccounts))).thenReturn(new List<Account>());

		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_EnterpriseAccountCasesModule module = aef_EnterpriseAccountCasesModule.newInstance();
		module.onAfterUpdate(accounts, new Map<Id, Account>(oldAccounts), mockUOW);

		Test.stopTest();

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(aef_ApplicationUnitOfWork.AsyncStagingWorker.class); // <-- grab the case update that was passed into registerDirty()
		((aef_ApplicationUnitOfWork)aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(1))).registerAsyncWork((aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.capture());

		aef_ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (aef_ApplicationUnitOfWork.AsyncStagingWorker)stagedWorkerCapture.getValue();

		System.assertEquals(aef_EnterpriseAccountCasesModule.AsyncRetroFitCasePriorities.class, stagedWorker.classType, 'Expected AsyncRetroFitCasePriorities to be enqueued');
		System.assertEquals(new Map<String, Object>{ 'accountIds' => new Set<Id>{accounts[0].Id, accounts[1].Id}}, stagedWorker.params, 'Unexpected params');
	}

	/**
	 * Test:
	 *  When an account is updated to be classified as an 'enterprise' account when it was already an enterprise account, make sure the async job to update case priority is NOT triggered
	 */
	@IsTest
	private static void testEnsureAfterUpdateDoesNotTriggerCaseUpdate() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].AnnualRevenue = 5000000;
		accounts[1].AnnualRevenue = 5000000;

		List<Account> oldAccounts = new List<Account>{
			accounts[0].clone(true),
			accounts[1].clone(true)
		};

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
		aef_EnterpriseService mockEnterpriseService = (aef_EnterpriseService)aef_MockUtility.mockUtility(aef_EnterpriseService.class);

		// set up our responses
		aef_MockUtility.Mocks.startStubbing();

		// filterEnterpriseAccounts should return both of the old records since the accounts in oldmap did werealready classed as 'enterprise'
		aef_MockUtility.Mocks.when(mockEnterpriseService.filterEnterpriseAccounts((List<Account>)fflib_Match.eq(oldAccounts))).thenReturn(oldAccounts);

		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_EnterpriseAccountCasesModule module = aef_EnterpriseAccountCasesModule.newInstance();
		module.onAfterUpdate(accounts, new Map<Id, Account>(oldAccounts), mockUOW);

		Test.stopTest();

		// verify worker was enqueued
		((aef_ApplicationUnitOfWork)aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(0))).registerAsyncWork((aef_ApplicationUnitOfWork.AsyncStagingWorker)fflib_Match.anyObject());
	}


	/**
	 * Test:
	 * Ensures that the correct cases are pushed to be updated
	 */
	@IsTest
	private static void testEnsureCaseUpdatesAreTriggeredInAsyncWorker() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].AnnualRevenue = 5000000;
		accounts[1].AnnualRevenue = 5000000;

		List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(2, new Map<Id, Account>(accounts).keySet(), true);

		List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, new Map<Id, Contact>(contacts).keySet(), true);
		cases[0].AccountId = accounts[0].Id;
		cases[0].Priority = 'Low';

		cases[1].AccountId = accounts[1].Id;
		cases[1].Priority = 'Low';

		// these are the cases that should be returned after the cases to be updated are reclassified in the service class
		List<Case> reclassifiedCases = new List<Case>{
			cases[0].clone(true),
			cases[1].clone(true)
		};
		reclassifiedCases[0].Priority = 'High';
		reclassifiedCases[1].Priority = 'High';

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationUnitOfWork mockUOW = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);
		aef_CasesSelector mockCasesSelector = (aef_CasesSelector)aef_MockUtility.mockSelector(aef_CasesSelector.class);
		aef_EnterpriseService mockEnterpriseService = (aef_EnterpriseService)aef_MockUtility.mockUtility(aef_EnterpriseService.class);

		// set up our responses
		aef_MockUtility.Mocks.startStubbing();

		// catch the call to search cases records and return the expected cases
		aef_MockUtility.Mocks.when(mockCasesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(cases);

		// catch the actual update of the case to the uow
		aef_MockUtility.Mocks.when(mockUOW.registerDirty((Case)fflib_Match.anySObject(), (Set<SObjectField>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyString())).thenAnswer(new aef_MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		// reclassifyCasePriorities should change the priority of the case records and return the Cases for update
		aef_MockUtility.Mocks.when(mockEnterpriseService.reclassifyCasePriorities((List<Case>)fflib_Match.eq(cases))).thenReturn(reclassifiedCases);

		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_EnterpriseAccountCasesModule.AsyncRetroFitCasePriorities asyncWorker = new aef_EnterpriseAccountCasesModule.AsyncRetroFitCasePriorities();

		// deserialise the parameters (this is what the async framework calls before the worker runs)
		asyncWorker.deserialiseParams(JSON.serialize(new Map<String, Object>{'accountIds' => new Set<Id>{accounts[0].Id, accounts[1].Id}}));

		// execute the worker
		asyncWorker.execute(mockUOW);

		Test.stopTest();

		System.assertEquals(Case.SObjectType, asyncWorker.getSObjectTypeGroup(), 'SObject group must be set to Case for proper async grouping');
		System.assertEquals(aef_EnterpriseAccountCasesModule.AsyncRetroFitCasePriorities.class, asyncWorker.getClassType(), 'Due to lack of reflection, getClassType must return aef_EnterpriseAccountCasesModule.AsyncRetroFitCasePriorities');

		// verify the Case will be updated correctly and capture the arguments for review
		fflib_ArgumentCaptor updateableCasesCapture = fflib_ArgumentCaptor.forClass(List<Case>.class); // <-- grab the case update that was passed into registerDirty()
		((aef_ApplicationUnitOfWork) aef_MockUtility.Mocks.verify(mockUOW, aef_MockUtility.Mocks.times(2))).registerDirty((Case)updateableCasesCapture.capture(), (Set<SObjectField>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyString());

		// verify both cases passed in were queued for updating
		List<Object> updateableCases = (List<Object>)updateableCasesCapture.getAllValues();
		System.assertEquals(2, updateableCases.size(), 'Expected to update 2 case records');

		// verify the records passed into uow and that the priority was updated to High
		System.assertEquals(reclassifiedCases[0].Id, ((Case)updateableCases[0]).Id, 'Did not expect the current case');
		System.assertEquals(reclassifiedCases[0].Priority, ((Case)updateableCases[0]).Priority, 'Did not expect the current priority');

		System.assertEquals(reclassifiedCases[1].Id, ((Case)updateableCases[1]).Id, 'Did not expect the current case');
		System.assertEquals(reclassifiedCases[1].Priority, ((Case)updateableCases[1]).Priority, 'Did not expect the current priority');
	}

}