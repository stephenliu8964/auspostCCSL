/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 * 
 * @description
 * @author Nathan Franklin
 * @changelog
*/
@IsTest
private class aef_AccountsSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_AccountsSelector selector = aef_AccountsSelector.newInstance();
		aef_QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_AccountsSelector selector = aef_AccountsSelector.newInstance();

		String soql;
		aef_QueryBuilder qb;

		qb = selector.newQueryBuilder(new Set<Object>{aef_AccountsSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select Owner fields. ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{aef_AccountsSelector.Options.WITH_CONTACTS});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Contacts\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Contact child records: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{aef_AccountsSelector.Options.WITH_TASKS});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Tasks\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Task child records: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{aef_AccountsSelector.Options.WITH_CONTACTS, aef_ContactsSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?Owner\\..*\\bfrom Contacts\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Contact Owner child records: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors aef_QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_AccountsSelector selector = aef_AccountsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
			Account.SObjectType => new Set<SObjectField>{Account.AnnualRevenue},
			Contact.SObjectType => new Set<SObjectField>{Contact.AccountId},
			Name.SObjectType => new Set<SObjectField>{Name.LastName},
			Task.SObjectType => new Set<SObjectField>{Task.ActivityDate}
		});

		aef_QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{aef_AccountsSelector.Options.WITH_CONTACTS, aef_ContactsSelector.Options.WITH_OWNER, aef_AccountsSelector.Options.WITH_TASKS});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)AnnualRevenue\\b.*?\\bfrom Account\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?Owner\\.LastName\\b.*?from Contacts\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Task child records: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?AccountId\\b.*?from Contacts\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Task child records: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?ActivityDate\\b.*?from Tasks\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Task child records: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Select.*?\\(Select.*?Owner\\.FirstName\\b.*?from Contacts\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Task child records: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)AccountNumber\\b.*?\\bfrom Account\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Select.*?\\(Select.*?Description\\b.*?from Tasks\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Task child records: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Select.*?\\(Select.*?FirstName\\b.*?from Contacts\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not include Task child records: ' + soql);

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_MockUtility.disableTriggerExecution();

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, false);
		insert accounts;

		Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);

		List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(2, accountsMap.keySet(), false);
		insert contacts;

		List<Task> tasks = aef_ApplicationTestDataFactory.getTasks(2, null, accountsMap.keySet(), false);
		insert tasks;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_AccountsSelector selector = aef_AccountsSelector.newInstance(1);
		List<Account> results = selector.selectById(accountsMap.keySet());
		System.assertEquals(1, results.size(), 'Result count was wrong');

		selector = aef_AccountsSelector.newInstance();
		results = selector.selectByAccountNumber(new Set<String>{'1'});
		System.assertEquals(1, results.size(), 'Result count  was wrong');
		System.assertEquals(accounts[0].Id, results[0].Id, 'Result was wrong');

		results = selector.selectById(accountsMap.keySet(), new Set<Object>{aef_AccountsSelector.Options.WITH_OWNER});
		System.assertEquals(2, results.size(), 'Result count was wrong');
		System.assertNotEquals(null, results[0].Owner, 'Expected Owner object');
		System.assertNotEquals(null, results[1].Owner, 'Expected Owner object');

		results = selector.selectById(accountsMap.keySet(), new Set<Object>{aef_AccountsSelector.Options.WITH_CONTACTS});
		System.assertNotEquals(null, results[0].Contacts, 'Expected Contacts object');
		System.assertNotEquals(null, results[1].Contacts, 'Expected Contacts object');

		results = selector.selectById(accountsMap.keySet(), new Set<Object>{aef_AccountsSelector.Options.WITH_TASKS});
		System.assertNotEquals(null, results[0].Tasks, 'Expected Tasks object');
		System.assertNotEquals(null, results[1].Tasks, 'Expected Tasks object');

		selector.setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{
			Account.SObjectType => new Set<SObjectField>{Account.Name},
			Contact.SObjectType => new Set<SObjectField>{Contact.FirstName}
		});

		results = selector.selectById(accountsMap.keySet(), new Set<Object>{aef_AccountsSelector.Options.WITH_CONTACTS});
		try {
			Decimal revenue = results[0].AnnualRevenue;

			System.assert(false, 'SObjectException should be thrown.');
		} catch(SObjectException ex) {
			// should throw a queryexception
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'SObjectException should be thrown: ' + ex);
		}

		try {
			String lastName = results[0].Contacts[0].LastName;

			System.assert(false, 'SObjectException should be thrown.');
		} catch(SObjectException ex) {
			// should throw a queryexception
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'SObjectException should be thrown: ' + ex);
		}

		Test.stopTest();

	}
}