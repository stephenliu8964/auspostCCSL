/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Test class for aef_ApplicationDomain
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
private class aef_ApplicationDomain_Test {

	/**
	 * Scenario: Ensure the aef_Application domain fires:
	 * 1. All the methods from aef_ApplicationTestDomain1_Test.TestModuleAll
	 * 2. None the methods from aef_ApplicationTestDomain1_Test.TestModuleNone
	 *
	 * Utilise the static count variables in aef_ApplicationTestDomain1_Test to confirm
	 */
	@IsTest
	public static void testApplicationDomain1() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
		List<Account> oldAccounts = aef_ApplicationTestDataFactory.getAccounts(2, false);

		// setup our old values so we can perform comparisons on what is changed
		oldAccounts[0].Id = accounts[0].Id;
		oldAccounts[0].NumberOfEmployees = 10;

		oldAccounts[1].Id = accounts[1].Id;
		oldAccounts[1].NumberOfEmployees = 10;

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationUnitOfWork uow = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_ApplicationTestDomain1_Test domain = (aef_ApplicationTestDomain1_Test)aef_ApplicationDomain.newInstance(aef_ApplicationTestDomain1_Test.class, accounts);
		System.assertEquals(1, domain.records.size(), 'Expected only 1 record, instead got ' + domain.records.size());
		System.assertEquals('aef_ApplicationTestDomain1_Test', domain.className, 'Expected aef_ApplicationTestDomain1_Test, instead got ' + domain.className);

		// test method handlers
		domain.onBeforeInsert(uow);
		domain.onAfterInsert(uow);
		domain.onBeforeUpdate(new Map<Id, Account>(oldAccounts), uow);
		domain.onAfterUpdate(new Map<Id, Account>(oldAccounts), uow);
		//		domain.onBeforeDelete(uow);
		//		domain.onAfterDelete(uow);

		System.assertEquals(1, aef_ApplicationTestDomain1_Test.moduleOnBeforeInsertCalled, 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain1_Test.moduleOnAfterInsertCalled, 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain1_Test.moduleOnBeforeUpdateCalled, 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain1_Test.moduleOnAfterUpdateCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

		// verify that getIsChanged fired successfully in the module
		System.assertEquals(1, aef_ApplicationTestDomain1_Test.moduleBeforeUpdateChangedValues.size(), 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain1_Test.moduleBeforeUpdateChangedValues.get(accounts[0].Id).size(), 'Expected only 1');
		System.assert(aef_ApplicationTestDomain1_Test.moduleBeforeUpdateChangedValues.get(accounts[0].Id).contains(Account.NumberOfEmployees), 'Expected only 1');

		System.assertEquals(1, aef_ApplicationTestDomain1_Test.moduleAfterUpdateChangedValues.size(), 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain1_Test.moduleAfterUpdateChangedValues.get(accounts[0].Id).size(), 'Expected only 1');
		System.assert(aef_ApplicationTestDomain1_Test.moduleAfterUpdateChangedValues.get(accounts[0].Id).contains(Account.NumberOfEmployees), 'Expected only 1');

		Test.stopTest();

	}

	/**
	 * Scenario: Ensure the aef_Application domain fires:
	 * 1. All the methods from aef_ApplicationTestDomain2_Test.TestModuleAll
	 * 2. None the methods from aef_ApplicationTestDomain2_Test.TestModuleNone
	 *
	 * Utilise the static count variables in aef_ApplicationTestDomain2_Test to confirm
	 */
	@IsTest
	public static void testApplicationDomain2() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
		List<Account> oldAccounts = aef_ApplicationTestDataFactory.getAccounts(2, false);

		// setup our old values so we can perform comparisons on what is changed
		oldAccounts[0].Id = accounts[0].Id;
		oldAccounts[0].NumberOfEmployees = 10;

		oldAccounts[1].Id = accounts[1].Id;
		oldAccounts[1].NumberOfEmployees = 10;

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationUnitOfWork uow = (aef_ApplicationUnitOfWork)aef_MockUtility.mockUtility(aef_ApplicationUnitOfWork.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_ApplicationTestDomain2_Test domain = (aef_ApplicationTestDomain2_Test)aef_ApplicationDomain.newInstance(aef_ApplicationTestDomain2_Test.class, accounts);
		System.assertEquals(1, domain.records.size(), 'Expected only 1 record, instead got ' + domain.records.size());
		System.assertEquals('aef_ApplicationTestDomain2_Test', domain.className, 'Expected aef_ApplicationTestDomain2_Test, instead got ' + domain.className);

		// test method handlers
		domain.onBeforeInsert(uow);
		domain.onAfterInsert(uow);
		domain.onBeforeUpdate(new Map<Id, Account>(oldAccounts), uow);
		domain.onAfterUpdate(new Map<Id, Account>(oldAccounts), uow);
		//		domain.onBeforeDelete(uow);
		//		domain.onAfterDelete(uow);

		System.assertEquals(1, aef_ApplicationTestDomain2_Test.moduleOnBeforeInsertCalled, 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain2_Test.moduleOnAfterInsertCalled, 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain2_Test.moduleOnBeforeUpdateCalled, 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain2_Test.moduleOnAfterUpdateCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

		// verify that getIsChanged fired successfully in the module
		System.assertEquals(1, aef_ApplicationTestDomain2_Test.moduleBeforeUpdateChangedValues.size(), 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain2_Test.moduleBeforeUpdateChangedValues.get(accounts[0].Id).size(), 'Expected only 1');
		System.assert(aef_ApplicationTestDomain2_Test.moduleBeforeUpdateChangedValues.get(accounts[0].Id).contains(Account.NumberOfEmployees), 'Expected only 1');

		System.assertEquals(1, aef_ApplicationTestDomain2_Test.moduleAfterUpdateChangedValues.size(), 'Expected only 1');
		System.assertEquals(1, aef_ApplicationTestDomain2_Test.moduleAfterUpdateChangedValues.get(accounts[0].Id).size(), 'Expected only 1');
		System.assert(aef_ApplicationTestDomain2_Test.moduleAfterUpdateChangedValues.get(accounts[0].Id).contains(Account.NumberOfEmployees), 'Expected only 1');

		Test.stopTest();

	}

	/**
	 * SUndry test
	 */
	@IsTest
	public static void testSundry() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(10, false);

		// =====================================
		// Stubbing
		// =====================================


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_ApplicationDomain.Module module = new aef_ApplicationDomain.Module();

		module.onBeforeInsert(null, null);
		module.onAfterInsert(null, null);

		module.onBeforeUpdate(null, null, null);
		module.onAfterUpdate(null, null, null);

		module.onBeforeDelete(null, null);
		module.onAfterDelete(null, null);

		System.assertEquals('', module.nullToString(null));

		aef_ApplicationDomain domain = new aef_ApplicationDomain();

		System.assertEquals('', domain.nullToString(null));
		System.assertEquals(accounts, domain.filter(accounts));

		domain.registerModules();

		Test.stopTest();

	}

}