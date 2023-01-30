/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * @author Nathan Franklin
 * @changelog
*/
@IsTest
private class aef_CasesSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors aef_QueryBuilder is generating the correct output
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

		aef_CasesSelector selector = aef_CasesSelector.newInstance();
		aef_QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select from Case');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors aef_QueryBuilder is generating the correct output
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

		aef_CasesSelector selector = aef_CasesSelector.newInstance();

		String soql;
		aef_QueryBuilder qb;

		qb = selector.newQueryBuilder(new Set<Object>{aef_CasesSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Owner fields. ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Contact\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Contact fields. ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{aef_CasesSelector.Options.WITH_ACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Account\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Account fields. ' + soql);

		// test to make sure child options can be passed into other selectors
		qb = selector.newQueryBuilder(new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT, aef_ContactsSelector.Options.WITH_ACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Contact\\.Account\\..*?\\bfrom case\\b').matcher(soql).find(), 'Resulting query does not select Contact Account fields. ' + soql);

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

		aef_CasesSelector selector = aef_CasesSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
			Case.SObjectType => new Set<SObjectField>{Case.CaseNumber},
			Account.SObjectType => new Set<SObjectField>{Account.AnnualRevenue},
			Contact.SObjectType => new Set<SObjectField>{Contact.AccountId},
			Name.SObjectType => new Set<SObjectField>{Name.LastName}
		});

		aef_QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{aef_CasesSelector.Options.WITH_ACCOUNT, aef_CasesSelector.Options.WITH_CONTACT, aef_ContactsSelector.Options.WITH_OWNER});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bAccount\\.AnnualRevenue\\b.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bContact\\.Owner\\.LastName\\b.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bCaseNumber\\b.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\bContact\\.Owner\\b\\.FirstName.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\bAccount\\.Name\\b.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\bContact\\.FirstName\\b.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\bSubject\\b.*?\\bfrom Case\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors aef_QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithSearch() {

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

		aef_CasesSelector selector = aef_CasesSelector.newInstance();

		Map<String, Object> searchParams;
		String soql;

		searchParams = new Map<String, Object>{'accountIds' => new Set<Id>{'001000000000000'}};
		soql = selector.getSearchSoql(searchParams, new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT}, true);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE\\s+?AccountId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bContact\\..*?from Case\\s+?WHERE\\s+?AccountId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);

		searchParams = new Map<String, Object>{'ownerIds' => new Set<Id>{'005000000000000'}};
		soql = selector.getSearchSoql(searchParams, new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT}, true);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE\\s+?OwnerId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bContact\\..*?from Case\\s+?WHERE\\s+?OwnerId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);

		searchParams = new Map<String, Object>{'isClosed' => false};
		soql = selector.getSearchSoql(searchParams, new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT}, true);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE\\s+?IsClosed\\s*=\\s*').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bContact\\..*?from Case\\s+?WHERE\\s+?IsClosed\\s*=\\s*').matcher(soql).find(), 'Resulting query was not correct: ' + soql);

		searchParams = new Map<String, Object>{'contactIds' => new Set<Id>{'003000000000000'}};
		soql = selector.getSearchSoql(searchParams, new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT}, true);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE\\s+?ContactId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bContact\\..*?from Case\\s+?WHERE\\s+?ContactId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);

		searchParams = new Map<String, Object>{'accountIds' => new Set<Id>{'001000000000000'}, 'ownerIds' => new Set<Id>{'005000000000000'}, 'isClosed' => false, 'contactIds' => new Set<Id>{'003000000000000'}};
		soql = selector.getSearchSoql(searchParams, new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT}, true);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?AccountId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?OwnerId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?IsClosed\\s*=\\s*').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?ContactId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?\\bAND\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);

		searchParams = new Map<String, Object>{'accountIds' => new Set<Id>{'001000000000000'}, 'ownerIds' => new Set<Id>{'005000000000000'}, 'isClosed' => false, 'contactIds' => new Set<Id>{'003000000000000'}};
		soql = selector.getSearchSoql(searchParams, new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT}, false);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?AccountId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?OwnerId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?IsClosed\\s*=\\s*').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?ContactId\\s+IN\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Case\\s+?WHERE.+?\\bOR\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data.
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

		Map<Id, Contact> contactsMap = new Map<Id, Contact>(contacts);
		List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, contactsMap.keySet(), false);
		insert cases;

		Map<Id, Case> casesMap = new Map<Id, Case>(cases);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_CasesSelector selector;
		Map<String, Object> searchParams;
		List<Case> results;

		selector = aef_CasesSelector.newInstance(1);
		results = selector.selectById(casesMap.keySet());
		System.assertEquals(1, results.size(), 'Result count was wrong');

		selector = aef_CasesSelector.newInstance();
		results = selector.selectById(casesMap.keySet());
		System.assertEquals(2, results.size(), 'Result count was wrong');

		results = selector.selectById(casesMap.keySet(), new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT});
		System.assertEquals(2, results.size(), 'Result count was wrong');
		System.assertNotEquals(null, results[0].Contact, 'Expected Contact object');
		System.assertNotEquals(null, results[1].Contact, 'Expected Contact object');

		selector.setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{
			Case.SObjectType => new Set<SObjectField>{Case.CaseNumber},
			Contact.SObjectType => new Set<SObjectField>{Contact.FirstName}
		});

		results = selector.selectById(casesMap.keySet(), new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT});
		try {
			String subject = results[0].Subject;

			System.assert(false, 'SObjectException should be thrown.');
		} catch(SObjectException ex) {
			// should throw a queryexception
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'SObjectException should be thrown: ' + ex);
		}

		try {
			String lastName = results[0].Contact.LastName;

			System.assert(false, 'SObjectException should be thrown.');
		} catch(SObjectException ex) {
			// should throw a queryexception
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'SObjectException should be thrown: ' + ex);
		}

		// test search method - (put in the same integration test for performance).... probably could be split out
		aef_CasesSelector selector2 = aef_CasesSelector.newInstance();
		searchParams = new Map<String, Object>{'accountIds' => new Set<Id>{accounts[0].Id}, 'contactIds' => new Set<Id>{contacts[1].Id}};
		results = selector2.search(searchParams, new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT}, false);
		System.assertEquals(2, results.size());
		System.assertEquals(accounts[0].Id, results[0].AccountId);
		System.assertEquals(contacts[1].Id, results[1].ContactId);

		searchParams = new Map<String, Object>{'accountIds' => new Set<Id>{accounts[0].Id}, 'contactIds' => new Set<Id>{contacts[1].Id}};
		results = selector2.search(searchParams, new Set<Object>{aef_CasesSelector.Options.WITH_CONTACT}, true);
		System.assertEquals(0, results.size());

		Test.stopTest();

	}
}