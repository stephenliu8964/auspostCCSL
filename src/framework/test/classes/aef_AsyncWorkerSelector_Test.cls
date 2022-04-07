/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 * @description
 * Test class covering aef_AsyncWorkerSelector
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
public with sharing class aef_AsyncWorkerSelector_Test {

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

		aef_AsyncWorkerSelector selector = aef_AsyncWorkerSelector.newInstance();
		aef_QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom aef_AsyncWorker__c\\b').matcher(soql).find(), 'Resulting query does not select from aef_AsyncWorker__c');

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

		aef_AsyncWorkerSelector selector = aef_AsyncWorkerSelector.newInstance(0, new Set<SObjectField>{aef_AsyncWorker__c.ClassType__c});

		aef_QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)ClassType__c\\b.*?\\bfrom aef_AsyncWorker__c\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)LastError__c\\b.*?\\bfrom aef_AsyncWorker__c\\b').matcher(soql).find(), 'Resulting query was not correct: ' + soql);

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

		List<aef_AsyncWorker__c> workers = new List<aef_AsyncWorker__c>{
				new aef_AsyncWorker__c(Processing__c = false)
		};
		insert workers;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		aef_AsyncWorkerSelector selector = aef_AsyncWorkerSelector.newInstance();
		Map<Id, aef_AsyncWorker__c> results = selector.selectById(new Set<Id>{workers[0].Id});
		System.assertEquals(1, results.size(), 'Result count was wrong');

		Test.stopTest();

	}
}