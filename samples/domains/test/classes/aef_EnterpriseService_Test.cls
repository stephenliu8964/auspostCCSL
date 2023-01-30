/**
 * @description
 * Test class for aef_EnterpriseService
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
private class aef_EnterpriseService_Test {

	/**
	 * Test:
	 *  Ensures that only records matching an enterprise criteria are returned
	 */
	@IsTest
	private static void testFilterEnterpriseAccountsBySObject() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(4, true);
		Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);
		accounts[0].AnnualRevenue = 5000000;
		accounts[1].AnnualRevenue = 5000000;
		accounts[2].AnnualRevenue = 1000000;
		accounts[3].AnnualRevenue = 1000000;

		// =====================================
		// Stubbing
		// =====================================
		aef_AccountsSelector mockAccountsSelector = (aef_AccountsSelector)aef_MockUtility.mockSelector(aef_AccountsSelector.class);

		// set up our responses
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.eq(accountsMap.keySet()))).thenReturn(accounts);
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_EnterpriseService service = aef_EnterpriseService.getInstance();
		List<Id> output = new List<Id>(service.filterEnterpriseAccounts(accountsMap.keySet()));

		Test.stopTest();

		// verify selectById was called
		((aef_AccountsSelector)aef_MockUtility.Mocks.verify(mockAccountsSelector, aef_MockUtility.Mocks.times(1))).selectById(accountsMap.keySet());

		System.assertEquals(2, output.size());
		System.assertEquals(accounts[0].Id, output[0]);
		System.assertEquals(accounts[1].Id, output[1]);
	}

	/**
	 * Test:
	 *  Ensures that cases are reprioritised
	 */
	@IsTest
	private static void testCaseReprioritsation() {

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
		cases[1].Priority = 'High';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_EnterpriseService service = aef_EnterpriseService.getInstance();
		List<Case> output = service.reclassifyCasePriorities(cases);

		Test.stopTest();

		System.assertEquals(1, output.size());
		System.assertEquals('High', output[0].Priority);
	}

}