/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
private class aef_EnterpriseAccountDomain_Test {

	/**
	 * TODO: Mock aef_EnterpriseService call since we don't need to actually execute it
	 */
	@IsTest
	private static void testMethods() {

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].AnnualRevenue = 5000000;

		aef_EnterpriseAccountDomain domain = (aef_EnterpriseAccountDomain)aef_ApplicationDomain.newInstance(aef_EnterpriseAccountDomain.class, accounts);

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(accounts[0].Id, domain.records[0].Id, 'Expected enterprise record');
	}

}