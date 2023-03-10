/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @author Nathan Franklin
 * @description Test Class covering aef_ApplicationLogger
 * @changelog
 */
@IsTest
private class aef_ApplicationLogger_Test {

	/**
	 * Test to ensure that any failed save results from updates/inserts will be logged into the Logging object
	 */
	@IsTest
	private static void testEnsureFailedSaveResultsAreLoggedCorrectly() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_SystemSettings__c settings = new aef_SystemSettings__c(LoggingLevel__c = 'ERROR');
		insert settings;

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(10, false);
		List<Database.SaveResult> results = getUpdatePartialFailures(accounts);

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();

		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		// this one should trigger an insert to the database
		aef_ApplicationLogger.getInstance().logFailedDatabaseResults(results, 'MyApp', 'MyClass', 'MyMethod', 'MyTrigger', aef_ApplicationLogger.LoggingLevel.ERROR);

		// this one should be ignored since it's logging level is INFO
		aef_ApplicationLogger.getInstance().logFailedDatabaseResults(results, 'MyApp1', 'MyClass1', 'MyMethod1', 'MyTrigger1', aef_ApplicationLogger.LoggingLevel.INFO);

		Test.stopTest();

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)sobjectCapture.capture(), fflib_Match.anyBoolean());
		List<SObject> records = (List<SObject>)sobjectCapture.getValue();

		System.assertEquals(5, records.size());

		for(aef_Log__c record : (List<aef_Log__c>)records) {
			System.assertEquals('MyApp', record.Application__c);
			System.assertEquals('MyClass', record.ClassName__c);
			System.assertEquals('MyMethod', record.MethodName__c);
			System.assertEquals('MyTrigger', record.ApexTrigger__c);
			System.assert(record.ExceptionType__c.contains('DmlException'));
			System.assert(record.ExceptionDetails__c.contains('The request failed because of some random error'));
		}

	}

	/**
	 * Test to ensure that any failed save results from deletes will be logged into the Logging object
	 */
	@IsTest
	private static void testEnsureFailedDeleteSaveResultsAreLoggedCorrectly() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_SystemSettings__c settings = new aef_SystemSettings__c(LoggingLevel__c = 'ERROR');
		insert settings;

		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(10, false);
		List<Database.DeleteResult> results = getDeletePartialFailures(accounts);

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();

		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		// this one should trigger an insert to the database
		aef_ApplicationLogger.getInstance().logFailedDatabaseResults(results, 'MyApp', 'MyClass', 'MyMethod', 'MyTrigger', aef_ApplicationLogger.LoggingLevel.ERROR);

		// this one should be ignored since it's logging level is INFO
		aef_ApplicationLogger.getInstance().logFailedDatabaseResults(results, 'MyApp1', 'MyClass1', 'MyMethod1', 'MyTrigger1', aef_ApplicationLogger.LoggingLevel.INFO);

		Test.stopTest();

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)sobjectCapture.capture(), fflib_Match.anyBoolean());
		List<SObject> records = (List<SObject>)sobjectCapture.getValue();

		System.assertEquals(5, records.size());

		for(aef_Log__c record : (List<aef_Log__c>)records) {
			System.assertEquals('MyApp', record.Application__c);
			System.assertEquals('MyClass', record.ClassName__c);
			System.assertEquals('MyMethod', record.MethodName__c);
			System.assertEquals('MyTrigger', record.ApexTrigger__c);
			System.assert(record.ExceptionType__c.contains('DmlException'));
			System.assert(record.ExceptionDetails__c.contains('The request failed because of some random error'));
		}

	}

	/**
	 * Test to ensure that any exceptions will logged correctly. Positive and Negative
	 */
	@IsTest
	private static void testEnsureExceptionsAreLoggedCorrectly() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_SystemSettings__c settings = new aef_SystemSettings__c(LoggingLevel__c = 'ERROR');
		insert settings;

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();

		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		//positive test
		try {
			throw new MyStrangeException('A random error');
		} catch(Exception ex) {
			// this one should trigger an insert to the database
			aef_ApplicationLogger.getInstance().logException(aef_ApplicationLogger.wrapException(ex), 'MyApp', 'MyClass', 'MyMethod', 'MyTrigger', aef_ApplicationLogger.LoggingLevel.ERROR);
		}

		// negative test
		try {
			throw new MyStrangeException('Some other type of error');
		} catch(Exception ex) {
			// this one should be ignored since it's logging level is INFO
			aef_ApplicationLogger.getInstance().logException(aef_ApplicationLogger.wrapException(ex), 'MyApp1', 'MyClass1', 'MyMethod1', 'MyTrigger1', aef_ApplicationLogger.LoggingLevel.INFO);
		}

		Test.stopTest();

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)sobjectCapture.capture(), fflib_Match.anyBoolean());
		List<SObject> records = (List<SObject>)sobjectCapture.getValue();

		System.assertEquals(1, records.size());

		for(aef_Log__c record : (List<aef_Log__c>)records) {
			System.assertEquals('MyApp', record.Application__c);
			System.assertEquals('MyClass', record.ClassName__c);
			System.assertEquals('MyMethod', record.MethodName__c);
			System.assertEquals('MyTrigger', record.ApexTrigger__c);
			System.assert(record.ExceptionType__c.contains('MyStrangeException'));
			System.assert(record.ExceptionDetails__c.contains('A random error'));
		}

	}

	/**
	 * Test to ensure that any messages will logged correctly. Positive and Negative
	 */
	@IsTest
	private static void testEnsureMessagesAreLoggedCorrectly() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_SystemSettings__c settings = new aef_SystemSettings__c(LoggingLevel__c = 'ERROR');
		insert settings;

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();

		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		// this one should trigger an insert to the database
		List<String> messages = new List<String>{'message1', 'message2', 'message3'};
		List<String> additionalInfo = new List<String>{'additional1', 'additional2', 'additional3'};
		aef_ApplicationLogger.getInstance().logMessage(messages, additionalInfo, 'MyApp', 'MyClass', 'MyMethod', 'MyTrigger', aef_ApplicationLogger.LoggingLevel.ERROR);

		// this one should be ignored since it's logging level is INFO
		messages = new List<String>{'message4', 'message5', 'message6'};
		additionalInfo = new List<String>{'additional4', 'additional5', 'additional6'};
		aef_ApplicationLogger.getInstance().logMessage(messages, additionalInfo, 'MyApp1', 'MyClass1', 'MyMethod1', 'MyTrigger1', aef_ApplicationLogger.LoggingLevel.INFO);

		Test.stopTest();

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)sobjectCapture.capture(), fflib_Match.anyBoolean());
		List<SObject> records = (List<SObject>)sobjectCapture.getValue();

		System.assertEquals(3, records.size());

		Integer index = 1;
		for(aef_Log__c record : (List<aef_Log__c>)records) {
			System.assertEquals('MyApp', record.Application__c);
			System.assertEquals('MyClass', record.ClassName__c);
			System.assertEquals('MyMethod', record.MethodName__c);
			System.assertEquals('MyTrigger', record.ApexTrigger__c);
			System.assert(record.AdditionalInformation__c.contains('additional' + String.valueOf(index)));
			System.assert(record.ExceptionDetails__c.contains('message' + String.valueOf(index)));

			index++;
		}

	}

	/**
	 * Test to ensure that any generic messages will logged correctly. Positive and Negative
	 */
	@IsTest
	private static void testEnsureGenericMessagesAreLoggedCorrectly() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_SystemSettings__c settings = new aef_SystemSettings__c(LoggingLevel__c = 'ERROR');
		insert settings;

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();

		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		// this one should trigger an insert to the database
		List<String> messages = new List<String>{'message1', 'message2', 'message3'};
		aef_ApplicationLogger.getInstance().logGenericMessage(messages, 'MyApp', 'MyClass', 'MyMethod', 'MyTrigger', aef_ApplicationLogger.LoggingLevel.ERROR);

		// this one should be ignored since it's logging level is INFO
		messages = new List<String>{'message4', 'message5', 'message6'};
		aef_ApplicationLogger.getInstance().logGenericMessage(messages, 'MyApp1', 'MyClass1', 'MyMethod1', 'MyTrigger1', aef_ApplicationLogger.LoggingLevel.INFO);

		Test.stopTest();

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)sobjectCapture.capture(), fflib_Match.anyBoolean());
		List<SObject> records = (List<SObject>)sobjectCapture.getValue();

		System.assertEquals(3, records.size());

		Integer index = 1;
		for(aef_Log__c record : (List<aef_Log__c>)records) {
			System.assertEquals('MyApp', record.Application__c);
			System.assertEquals('MyClass', record.ClassName__c);
			System.assertEquals('MyMethod', record.MethodName__c);
			System.assertEquals('MyTrigger', record.ApexTrigger__c);
			System.assert(record.ExceptionDetails__c.contains('message' + String.valueOf(index)));

			index++;
		}

	}

	private static List<Database.SaveResult> getUpdatePartialFailures(List<SObject> records) {
		Boolean isSuccess = true;
		List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
		for(SObject record : records) {
			Map<String, Object> result = new Map<String, Object> {
				'success' => isSuccess,
				'id' => record.Id,
				'errors' => (isSuccess ? null : new List<Map<String, Object>>{
					new Map<String, Object>{
						'message' => 'The request failed because of some random error'
					}
				})
			};
			saveResults.add(result);

			isSuccess = !isSuccess;
		}
		List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
		return result;
	}

	private static List<Database.DeleteResult> getDeletePartialFailures(List<SObject> records) {
		Boolean isSuccess = true;
		List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
		for(SObject record : records) {
			Map<String, Object> result = new Map<String, Object> {
				'success' => isSuccess,
				'id' => record.Id,
				'errors' => (isSuccess ? null : new List<Map<String, Object>>{
					new Map<String, Object>{
						'message' => 'The request failed because of some random error',
						'statusCode' => 'DELETE_FAILED'
					}
				})
			};
			saveResults.add(result);

			isSuccess = !isSuccess;
		}
		List<Database.DeleteResult> result = (List<Database.DeleteResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.DeleteResult>.class);
		return result;
	}

	public class MyStrangeException extends Exception {}

}