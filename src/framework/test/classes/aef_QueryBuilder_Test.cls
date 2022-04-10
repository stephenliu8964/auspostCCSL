/**
	MIT License

	Copyright (c) 2018 Alex

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/
@IsTest
private with sharing class aef_QueryBuilder_Test {

	@IsTest
	private static void testEnsureAllFieldsMethodsAddToTheQuery() {
		System.debug('testEnsureAllFieldsMethodsAddToTheQuery');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addField(Account.NumberOfEmployees);
		qb.addFields(new List<SObjectField>{Account.Industry});
		qb.addFields(new Set<SObjectField>{Account.Phone});
		qb.addFields(new List<String>{'AnnualRevenue'});
		qb.addFields(new Set<String>{'AccountSource'});

		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');
		System.assertEquals(true, Pattern.compile('(?ism)\\bName\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select Name field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bNumberOfEmployees\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select NumberOfEmployees field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bIndustry\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select Industry field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bPhone\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select Phone field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bAnnualRevenue\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select AnnualRevenue field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bAccountSource\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select AccountSource field');

		// ensure the generated query does not throw an error
		System.assertEquals(true, Database.query(soql).isEmpty());
	}

	@IsTest
	private static void testEnsureThatLimitAndOffsetProducesCorrectQueryOutput() {
		System.debug('testEnsureThatLimitAndOffsetProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.setLimit(20);
		qb.setOffset(5);
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT\\s+20\\s+OFFSET\\s+5\\s*$').matcher(soql).find(), 'Resulting query does not set LIMIT and OFFSET correctly');
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.setLimit(20);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT\\s+20\\s*$').matcher(soql).find(), 'Resulting query does not set LIMIT correctly');
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.setOffset(5);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?OFFSET\\s+5\\s*$').matcher(soql).find(), 'Resulting query does not set OFFSET correctly');
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testEnsureThatOrderByProducesCorrectQueryOutput() {
		System.debug('testEnsureThatOrderByProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrder(new aef_QueryBuilder.Order('Id', 'Desc'));
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Desc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrder(new aef_QueryBuilder.Order('Id'));
		qb.addOrder(new aef_QueryBuilder.Order(Account.Name));
		qb.addOrder((new aef_QueryBuilder.Order(Account.Industry)).setSortingOrderAsc());
		qb.addOrder((new aef_QueryBuilder.Order(Account.CreatedDate)).setSortingOrderDesc());
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Asc\\s*,\\s*Name\\s+Asc\\s*,\\s*Industry\\s+Asc\\s*,\\s*CreatedDate\\s+Desc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrder(new aef_QueryBuilder.Order('Id'));
		qb.addOrder(new aef_QueryBuilder.Order(Account.Name).setNullsOrderLast());
		qb.addOrder((new aef_QueryBuilder.Order(Account.Industry)).setSortingOrderAsc().setNullsOrder('FIRST'));
		qb.addOrder((new aef_QueryBuilder.Order(Account.CreatedDate)).setSortingOrderDesc().setNullsOrderFirst());
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Asc\\s*,\\s*Name\\s+Asc\\s+nulls\\s+last\\s*?,\\s*Industry\\s+Asc\\s+nulls\\s+first\\s*,\\s*CreatedDate\\s+Desc\\s+nulls\\s+first\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		// verify that multiple order by clauses work
		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrder(new aef_QueryBuilder.Order('Id', 'Desc'));
		qb.addOrder(new aef_QueryBuilder.Order('Name', 'Asc'));
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Desc\\s*,\\s*Name\\s+Asc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		// verify that multiple ASC order by clauses work
		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrderAsc('Id');
		qb.addOrderAsc(Account.Name);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Asc\\s*,\\s*Name\\s+Asc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		// verify that multiple DESC order by clauses work
		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrderDesc('Id');
		qb.addOrderDesc(Account.Name);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Desc\\s*,\\s*Name\\s+Desc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testEnsureThatGroupByProducesCorrectQueryOutput() {
		System.debug('testEnsureThatGroupByProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addGroupBy('Name');
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Group\\s+By\\s+Name\\s*$').matcher(soql).find(), 'Resulting query does not set Group By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		// verify that multiple order by clauses work
		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addField('Industry');
		qb.addGroupBy(new Set<String>{'Name'});
		qb.addGroupBy(Account.Industry);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Group\\s+By\\s+Name\\s*,\\s*Industry\\s*$').matcher(soql).find(), 'Resulting query does not set Group By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testEnsureThatSelectCountProducesCorrectQueryOutput() {
		System.debug('testEnsureThatSelectCountProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addConditions().add(new aef_QueryBuilder.CompareCondition('Name').eq('Nathan')).endConditions();
		String soql = qb.toCountString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+COUNT\\s*\\(\\s*\\)\\s+\\bfrom account\\b.*?Where.*$').matcher(soql).find(), 'Resulting query does not select COUNT correctly: ' + soql);
		System.assertEquals(0, Database.countQuery(soql));

	}

	@IsTest
	private static void testEnsureThatSelectCountWithLimitAndOffsetProducesCorrectQueryOutput() {
		System.debug('testEnsureThatSelectCountWithLimitAndOffsetProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.setLimit(1);
		qb.setOffset(4);
		String soql = qb.toCountString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+COUNT\\s*\\(\\s*\\)\\s+\\bfrom account\\s+LIMIT\\s+1\\s+OFFSET\\s+4\\s*$').matcher(soql).find(), 'Resulting query does not select COUNT correctly: ' + soql);
		System.assertEquals(0, Database.countQuery(soql));

	}

	@IsTest
	private static void testEnsureThatScopeProducesCorrectQueryOutput() {
		System.debug('testEnsureThatScopeProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.setScope(aef_QueryBuilder.FilterScope.Mine);
		qb.addField('Industry');
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+?Industry\\s+?from account\\s+?using scope mine\\b.*$').matcher(soql).find(), 'Resulting query does not use SCOPE correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.setScope(aef_QueryBuilder.FilterScope.Mine);
		soql = qb.toCountString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+?COUNT\\s*\\(\\s*\\)\\s+?from account\\s+?using scope mine\\b.*$').matcher(soql).find(), 'Resulting query does not use SCOPE correctly: ' + soql);
		System.assertEquals(0, Database.countQuery(soql));

	}

	@IsTest
	private static void testEnsureThatForViewProducesCorrectQueryOutput() {
		System.debug('testEnsureThatForViewProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.setForView(true);
		qb.addField('Industry');
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+?Industry\\s+?from account\\s+?for view\\b.*$').matcher(soql).find(), 'Resulting query does not use FOR VIEW correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.setForView();
		qb.addField('Industry');
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+?Industry\\s+?from account\\s+?for view\\b.*$').matcher(soql).find(), 'Resulting query does not use FOR VIEW correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testEnsureThatForReferenceProducesCorrectQueryOutput() {
		System.debug('testEnsureThatForReferenceProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.setForReference();
		qb.addField('Industry');
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+?Industry\\s+?from account\\s+?for reference\\b.*$').matcher(soql).find(), 'Resulting query does not use FOR REFERENCE correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testEnsureThatWithSecurityEnforcedProducesCorrectQueryOutput() {
		System.debug('testEnsureThatWithSecurityEnforcedProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.setWithSecurityEnforced();
		qb.addField('Industry');
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+?Industry\\s+?from account\\s+?WITH SECURITY_ENFORCED\\b.*$').matcher(soql).find(), 'Resulting query does not use SECURITY_ENFORCED correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testEnsureThatEmptyFieldsAddsIdProducesCorrectQueryOutput() {
		System.debug('testEnsureThatWithSecurityEnforcedProducesCorrectQueryOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+?Id\\s+?from account').matcher(soql).find(), 'Resulting query does not select Id field: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testPreviewCodeCoverageOutput() {
		System.debug('testPreviewCodeCoverageOutput');

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addField('Industry');
		aef_QueryBuilder qb2 = qb.preview();

		// Lame assertion
		System.assertEquals(qb, qb2);
	}

	@IsTest
	private static void testEnsureRelatedParentFieldsCanBeAddedToQuery() {
		System.debug('testEnsureRelatedParentFieldsCanBeAddedToQuery');

		aef_QueryBuilder parentQb = new aef_QueryBuilder(Account.SObjectType);
		parentQb.addFields(new List<SObjectField>{Account.Name});

		aef_QueryBuilder qb = new aef_QueryBuilder(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.FirstName, Contact.LastName, Contact.AccountId});
		qb.addRelatedFields(parentQb, 'Account');

		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select from Contact');
		System.assertEquals(true, Pattern.compile('(?ism)\\bAccount\\.Name\\b.*?from contact').matcher(soql).find(), 'Resulting query does not select Account.Name field');

		// ensure the generated query does not throw an error
		List<Contact> records = Database.query(soql);
		System.assertEquals(true, records.isEmpty());
	}

	@IsTest
	private static void testEnsureSubQueryCanBeAddedToQuery() {
		System.debug('testEnsureSubQueryCanBeAddedToQuery');

		aef_QueryBuilder childrenQb = new aef_QueryBuilder('Contacts'); // note the extra 's' on the end
		childrenQb.addFields(new List<SObjectField>{Contact.FirstName, Contact.LastName});

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Name});
		qb.addSubQuery(childrenQb);

		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bFrom Contacts\\b').matcher(soql).find(), 'Resulting query does not select from Contacts');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');
		System.assertEquals(true, Pattern.compile('(?ism)\\bName\\b').matcher(soql).find(), 'Resulting query does not select Name field');
		System.assertEquals(true, qb.hasSubQueries());

		// ensure the generated query does not throw an error
		List<Account> records = Database.query(soql);
		System.assertEquals(true, records.isEmpty());

		childrenQb = new aef_QueryBuilder(Contact.SObjectType); // note the extra 's' on the end
		childrenQb.addFields(new List<SObjectField>{Contact.FirstName, Contact.LastName});

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Name});
		qb.addSubQuery(childrenQb, 'Contacts');

		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bFrom Contacts\\b').matcher(soql).find(), 'Resulting query does not select from Contacts');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');
		System.assertEquals(true, Pattern.compile('(?ism)\\bName\\b').matcher(soql).find(), 'Resulting query does not select Name field');
		System.assertEquals(true, qb.hasSubQueries());

		// ensure the generated query does not throw an error
		records = Database.query(soql);
		System.assertEquals(true, records.isEmpty());
	}

	@IsTest
	private static void testEnsureAllConstructorsLinkTheCorrectSObject() {
		System.debug('testEnsureAllConstructorsLinkTheCorrectSObject');

		aef_QueryBuilder qb;

		qb = aef_QueryBuilder.newInstance().addFrom(Account.SObjectType);
		System.assertEquals('Account', qb.fromSobject);

		qb = new aef_QueryBuilder(Account.SObjectType);
		System.assertEquals('Account', qb.fromSobject);

		qb = new aef_QueryBuilder('Account');
		System.assertEquals('Account', qb.fromSobject);

		qb = aef_QueryBuilder.newInstance(aef_AccountsSelector.class).addFrom('Account');
		System.assertEquals('Account', qb.fromSobject);

	}

	@IsTest
	private static void testEnsureThatCorrectCompareConditionLogicHasBeenAppliedToQueryBuilderIntegration() {
		System.debug('testEnsureThatCorrectCompareConditionLogicHasBeenAppliedToQueryBuilderIntegration');

		aef_MockUtility.disableTriggerExecution();

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(2, accounts[0].Id, false);
		insert contacts;

		// eq string
		aef_QueryBuilder qb = new aef_QueryBuilder(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		String soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Contact.FirstName).eq('First Name 1')).endConditions().toSoqlString();
		List<SObject> records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = new aef_QueryBuilder(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition('FirstName').eq('First Name 1')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// not equal string
		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Contact.FirstName).ne('First Name 1')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// equals boolean
		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Contact.DoNotCall).eq(true)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(2, records.size());

		// not equal boolean
		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Contact.DoNotCall).ne(true)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		// eq decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.AnnualRevenue).eq(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// not eq decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.AnnualRevenue).ne(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		// less than decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.AnnualRevenue).lt(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		// less than equals decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.AnnualRevenue).lte(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// greater than decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.AnnualRevenue).gt(999999)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// greater than decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.AnnualRevenue).gte(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// not equal decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.AnnualRevenue).ne(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		// less than equal date
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.CreatedDate).lte(Datetime.now().addDays(1))).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// greater than equal date
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.CreatedDate).gte(Datetime.now().addDays(-1))).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// less than date
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.CreatedDate).lt(Datetime.now().addDays(1))).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// greater than date
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.CompareCondition(Account.CreatedDate).gt(Datetime.now().addDays(-1))).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

	}

	@IsTest
	private static void testEnsureThatComplexConditionOrderingProducesCorrectString() {
		System.debug('testEnsureThatComplexConditionOrderingProducesCorrectString');

		// complex order by
		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		String soql = qb.addConditionsWithOrder('2 AND (3 OR 1)')
			.add(new aef_QueryBuilder.CompareCondition(Account.AnnualRevenue).eq(1000000))
			.add(new aef_QueryBuilder.CompareCondition(Account.Industry).eq('Commercial'))
			.add(new aef_QueryBuilder.CompareCondition(Account.Name).eq('Test'))
			.endConditions().toSoqlString();
		System.assertEquals(0, Database.query(soql).size());
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\s+where\\s+industry\\b.*?\\bAND\\b\\s*?\\(\\s*?Name\\b.*?\\bOR\\s*?AnnualRevenue\\b.*?\\)').matcher(soql).find(), 'Resulting query does not set condition order: ' + soql);

	}

	@IsTest
	private static void testEnsureThatSimpleConditionProducesCorrectString() {
		System.debug('testEnsureThatSimpleConditionProducesCorrectString');

		// complex order by
		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		String soql = qb.addConditions()
			.add(new aef_QueryBuilder.SimpleCondition(Account.AnnualRevenue + ' = 22'))
			.endConditions().toSoqlString();
		System.assertEquals(0, Database.query(soql).size());
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\s+where\\s+AnnualRevenue\\b\\s*?=\\s*?22').matcher(soql).find(), 'Resulting query does not produce correct string: ' + soql);

	}

	@IsTest
	private static void testEnsureThatCorrectNullConditionLogicHasBeenAppliedToQueryBuilderIntegration() {
		System.debug('testEnsureThatCorrectNullConditionLogicHasBeenAppliedToQueryBuilderIntegration');

		aef_MockUtility.disableTriggerExecution();

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, false);
		accounts[0].Industry = null;
		insert accounts;

		// is null
		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		String soql = qb.addConditions().add(new aef_QueryBuilder.NullCondition(Account.Industry).isNull()).endConditions().toSoqlString();
		List<SObject> records = Database.query(soql);
		System.assertEquals(1, records.size());
		System.assertEquals(accounts[0].Id, records[0].Id);

		// is null string field
		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.NullCondition('Industry').isNull()).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());
		System.assertEquals(accounts[0].Id, records[0].Id);

		// not null
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.NullCondition(Account.Industry).notNull()).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());
		System.assertEquals(accounts[1].Id, records[0].Id);

	}

	@IsTest
	private static void testEnsureThatCorrectLikeConditionLogicHasBeenAppliedToQueryBuilderIntegration() {
		System.debug('testEnsureThatCorrectLikeConditionLogicHasBeenAppliedToQueryBuilderIntegration');

		aef_MockUtility.disableTriggerExecution();

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, false);
		insert accounts;

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		String soql = qb.addConditions().add(new aef_QueryBuilder.LikeCondition(Account.Name).likeAnyBoth('Test Name')).endConditions().toSoqlString();
		List<SObject> records = Database.query(soql);
		System.assertEquals(2, records.size());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.LikeCondition('Name').likeAnyBoth('Test Name')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(2, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.LikeCondition(Account.Name).likeAnyLeft('Name 1')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.LikeCondition(Account.Name).likeAnyRight('Test Name 1')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

	}

	@IsTest
	private static void testEnsureThatCorrectInConditionLogicHasBeenAppliedToQueryBuilderIntegration() {
		System.debug('testEnsureThatCorrectInConditionLogicHasBeenAppliedToQueryBuilderIntegration');

		aef_MockUtility.disableTriggerExecution();

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(2, accounts[0].Id, false);
		insert contacts;

		aef_QueryBuilder qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		String soql = qb.addConditions().add(new aef_QueryBuilder.InCondition(Account.Name).inCollection(new Set<String>{'Test Name 1'})).endConditions().toSoqlString();
		List<SObject> records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition(Account.Name).inCollection(new List<String>{'Test Name 1'})).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition('Name').inCollection(new Set<String>{'Test Name 1'})).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = new aef_QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition('Name').inCollection(new List<String>{'Test Name 1'})).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition(Contact.Id).inCollection(contacts)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(2, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition(Account.AnnualRevenue).inCollection(new Set<Decimal>{1000000})).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition(Account.AnnualRevenue).inCollection(new List<Decimal>{1000000})).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition(Account.Id).notIn(accounts)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		aef_QueryBuilder qbInner = new aef_QueryBuilder(Account.SObjectType);
		qbInner.addFields(new List<SObjectField>{Account.Id});
		qbInner.addConditions().add(new aef_QueryBuilder.InCondition(Account.Id).inCollection(accounts)).endConditions();

		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition(Contact.AccountId).inCollection(qbInner)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(2, records.size());

		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new aef_QueryBuilder.InCondition(Contact.AccountId).notIn(qbInner)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

	}

	public virtual inherited sharing class aef_AccountsSelector extends aef_ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Account.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {
				Account.Id, Account.Name, Account.Type, Account.OwnerId, Account.AccountNumber
			};
		}

		public virtual override aef_QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
			aef_QueryBuilder builder = super.newQueryBuilder(selectorOptions);
			return builder;
		}

	}
}