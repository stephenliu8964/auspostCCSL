/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description Test Class covering aef_ApplicationSelector
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
public class aef_ApplicationSelector_Test {

	@IsTest
	public static void testClassNameReturnsCorrectValue() {
		aef_AccountsSelector selector = new aef_AccountsSelector();
		System.assertEquals('aef_AccountsSelector', selector.className, 'Class name property did not calculate correctly');
	}

	/**
	 * Test:
	 *  Ensures that the selectors aef_QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithoutSubQueries() {

		aef_AccountsSelector selector = new aef_AccountsSelector();
		aef_QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');

		// a bit dumb but should be ok for verification
		for(SObjectField field : selector.getSObjectFieldList()) {
			System.assertEquals(true, Pattern.compile('(?ism)\\b' + field + '\\b').matcher(soql).find(), 'Resulting query does not select ' + field);
		}

	}

	/**
	 * Test:
	 *  Ensures that the selectors aef_QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithLimit() {

		aef_AccountsSelector selector = new aef_AccountsSelector();
		selector.setLimit(5);
		selector.setOffset(10);

		aef_QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT 5').matcher(soql).find(), 'Resulting query does not include a LIMIT: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?OFFSET 10').matcher(soql).find(), 'Resulting query does not include an OFFSET: ' + soql);

	}

	/**
	 * Test:
	 *
	 */
	@IsTest
	public static void testCreateableFields() {

		aef_AccountsSelector selector = new aef_AccountsSelector();
		selector.setFieldOverrides(new Set<SObjectField>{Account.Id, Account.Name, Account.AccountSource});

		Set<SObjectField> creatableFields = new Set<SObjectField>(selector.getCreateableFields());
		System.assert(creatableFields.contains(Account.Name));
		System.assert(creatableFields.contains(Account.AccountSource));

		Set<SObjectField> allCreatableFields = aef_ApplicationSelector.getAllCreatableFieldsBySObjectType(Account.SObjectType);
		System.assert(!allCreatableFields.isEmpty());

		selector = new aef_AccountsSelector();
		selector.setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{Account.SObjectType => new Set<SObjectField>{Account.Id, Account.Name, Account.AccountSource}});

		creatableFields = new Set<SObjectField>(selector.getCreateableFields());
		System.assert(creatableFields.contains(Account.Name));
		System.assert(creatableFields.contains(Account.AccountSource));

	}

	/**
	 * Test:
	 *
	 */
	@IsTest
	public static void testIdFieldOnlyOption() {

		aef_AccountsSelector selector = new aef_AccountsSelector();

		aef_QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{aef_ApplicationSelector.Options.ID_FIELD_ONLY});
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)select\\s+id\\s+from\\s+account').matcher(soql).find(), 'Resulting query does not select Id field only from Account: ' + soql);

	}

	/**
	 * Test:
	 * Ensures that a clone option is removed when calling cloneAndRemoveOption
	 */
	@IsTest
	public static void testEnsureClonedOptionIsRemoved() {

		// this also covers newinstance method
		aef_AccountsSelector selector = (aef_AccountsSelector)aef_ApplicationSelector.newInstance(aef_AccountsSelector.class);

		Set<Object> expectedOptions = new Set<Object>{'Option1', 'Option3'};
		Set<Object> options = new Set<Object>{'Option1', 'Option2', 'Option3'};
		options = selector.cloneAndRemoveOption(options, 'Option2');

		System.assertEquals(expectedOptions, options);
	}

	/**
	 * Test:
	 *  Ensures that the selectors aef_QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testFieldOverridesProduceCorrectString() {

		aef_AccountsSelector selector = new aef_AccountsSelector();
		selector.setFieldOverrides(new Set<SObjectField>{Account.Id, Account.Name, Account.AccountSource});

		aef_QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(false, Pattern.compile('(?ism)\\bownerid\\b').matcher(soql).find(), 'Resulting query selects OwnerId from Account: ' + soql);

	}

	// TODO: Activate Cache
	//	/**
	//	 * Test:
	//	 *  Ensure that aef_Application Selector is caching what it should
	//	 */
	//	public static testMethod void testEnsureCacheByRecordIdFunctionsCorrectly() {
	//
	//		List<Id> accountIds = new List<Id>();
	//		Map<Id, Account> accounts = new Map<Id, Account>();
	//
	//		// pseudo records (not actually inserted to db)
	//		accountIds.add(fflib_IDGenerator.generate(Account.SObjectType));
	//		accountIds.add(fflib_IDGenerator.generate(Account.SObjectType));
	//
	//		Account acc = new Account(Id = accountIds[0], Name = 'Test 1');
	//		accounts.put(acc.Id, acc);
	//
	//		acc = new Account(Id = accountIds[1], Name = 'Test 2');
	//		accounts.put(acc.Id, acc);
	//
	//		aef_AccountsSelector selector = new aef_AccountsSelector();
	//
	//		// make sure the cache is empty
	//		aef_ApplicationSelector.CacheResult result = aef_ApplicationSelector.Cache.getByRecordId(selector, new Set<Id>(accountIds), 'selectById', 0);
	//		System.assertEquals(0, result.recordIds.size());
	//		System.assertEquals(0, result.rows.size());
	//
	//		// add both records to the cache
	//		aef_ApplicationSelector.Cache.putByRecordId(selector, accounts, 'selectById', 0);
	//
	//		// try and retrieve just 1 record and ensure we only get 1 result
	//		result = aef_ApplicationSelector.Cache.getByRecordId(selector, new Set<Id>{accountIds[0]}, 'selectById', 0);
	//		System.assertEquals(accountIds[0], new List<Id>(result.recordIds)[0]);
	//		System.assertEquals(1, result.recordIds.size());
	//
	//	}
	//
	//	/**
	//	 * Test:
	//	 *  Ensure that aef_Application Selector is caching what it should by related value
	//	 */
	//	public static testMethod void testEnsureCacheByRelatedValueFunctionsCorrectly() {
	//
	//		// pseudo records (not actually inserted to db)
	//		List<Id> accountIds = new List<Id>();
	//		Map<Id, Account> accounts = new Map<Id, Account>();
	//		accountIds.add(fflib_IDGenerator.generate(Account.SObjectType));
	//		accountIds.add(fflib_IDGenerator.generate(Account.SObjectType));
	//
	//		Account acc = new Account(Id = accountIds[0], Name = 'Test 1');
	//		accounts.put(acc.Id, acc);
	//		acc = new Account(Id = accountIds[1], Name = 'Test 2');
	//		accounts.put(acc.Id, acc);
	//
	//		List<Id> contactIds = new List<Id>();
	//		Map<Id, Contact> contacts = new Map<Id, Contact>();
	//		contactIds.add(fflib_IDGenerator.generate(Contact.SObjectType));
	//		contactIds.add(fflib_IDGenerator.generate(Contact.SObjectType));
	//		contactIds.add(fflib_IDGenerator.generate(Contact.SObjectType));
	//		contactIds.add(fflib_IDGenerator.generate(Contact.SObjectType));
	//
	//		Contact con = new Contact(Id = contactIds[0], AccountId = accountIds[0], FirstName = 'Test 1', LastName = 'Test 1');
	//		contacts.put(con.Id, con);
	//		con = new Contact(Id = contactIds[1], AccountId = accountIds[0], FirstName = 'Test 2', LastName = 'Test 2');
	//		contacts.put(con.Id, con);
	//		con = new Contact(Id = contactIds[2], AccountId = accountIds[1], FirstName = 'Test 3', LastName = 'Test 3');
	//		contacts.put(con.Id, con);
	//		con = new Contact(Id = contactIds[3], AccountId = accountIds[1], FirstName = 'Test 4', LastName = 'Test 4');
	//		contacts.put(con.Id, con);
	//
	//		aef_ContactsSelector selector = new aef_ContactsSelector();
	//
	//		// add all contact records to the cache
	//		aef_ApplicationSelector.Cache.putByRelatedValue(selector, contacts, Contact.AccountId, 'selectByAccountId', 0);
	//
	//		// try and retrieve all contact records from a single account and ensure we only get 2 contact records returned
	//		aef_ApplicationSelector.CacheResult result = aef_ApplicationSelector.Cache.getByRelatedValue(selector, new Set<String>{accountIds[0]}, 'selectByAccountId', 0);
	//		System.assertEquals(1, result.relatedValues.size());
	//		System.assertEquals(accountIds[0], new List<String>(result.relatedValues)[0]);
	//		System.assertEquals(2, result.rows.size());
	//
	//	}


	public class aef_AccountsSelector extends aef_ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Account.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {
					Account.Id, Account.Name, Account.Type, Account.OwnerId
			};
		}

	}

	public class aef_ContactsSelector extends aef_ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Contact.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {
					Contact.Id, Contact.AccountId, Contact.FirstName, Contact.LastName, Account.OwnerId
			};
		}

	}

}