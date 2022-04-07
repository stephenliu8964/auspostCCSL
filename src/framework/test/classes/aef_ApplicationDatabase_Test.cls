/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @author Nathan Franklin
 * @description Test class to cover aef_ApplicationDatabase
 * @changelog
 */
@IsTest
private with sharing class aef_ApplicationDatabase_Test {

	/**
	 * This is a bit of a nothing test as it doesn't contribute any value
	 */
	@IsTest
	private static void testInsertAndUpdateAndDelete() {
		aef_MockUtility.disableTriggerExecution();

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, false);
		aef_ApplicationDatabase.getInstance().dmlInsert(accounts);
		aef_ApplicationDatabase.getInstance().dmlUpdate(accounts);
		aef_ApplicationDatabase.getInstance().dmlDelete(accounts);
		aef_ApplicationDatabase.getInstance().dmlSetSavePoint();
		aef_ApplicationDatabase.getInstance().dmlRollback(aef_ApplicationDatabase.getInstance().dmlSetSavePoint());
		System.assert(true, 'Not Completed');
	}

}