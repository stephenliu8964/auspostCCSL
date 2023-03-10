/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Test class for aef_ApplicationUnitOfWork
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
private class aef_ApplicationUnitOfWork_Test {

	/**
	 * Scenario:
	 * Tests when registerAsyncWork is called that a new platform event is published
	 */
	@IsTest
	private static void testEndToEndEnsureAsyncWorkIsQueuedIntoAsyncContext() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker1.class, new Map<String, Object>{'key1' => 'value1'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker);
		uow.commitWork();

		Test.startTest();

		System.Savepoint sp = Database.setSavepoint();

		// deliver our platform events which should enqueue a queueable that invokes the async API
		Test.getEventBus().deliver();

		System.assertEquals(1, [SELECT Position FROM EventBusSubscriber WHERE Topic='aef_AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position, 'Expected platform event tip to be at 1');
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected handler to invoke queueable to call async API');

		// since we rolled everything back, this would no longer execute the queueable that calls the async API
		Test.stopTest();

		List<aef_Log__c> logs = [SELECT Id, ExceptionDetails__c FROM aef_Log__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

		List<String> expectedStack = new List<String>{
				'MyAsyncWorker1'
		};

		System.assertEquals(expectedStack, aef_ApplicationUnitOfWorkTestUtility.asyncStack, 'The workers were not executed correctly');

	}

	/**
	 * Scenario:
	 * Tests to ensure that when an asynchronous action is queued up in the UOW, that it will be pushed into a queueable context via the async platform event
	 * This ensures that workers are correctly grouped together
	 */
	@IsTest
	private static void testEnsureAsyncWorkGroupsAreQueuedIntoAsyncContextIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker1.class, new Map<String, Object>{'key1' => 'value1'});
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1a = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker1a.class, new Map<String, Object>{'key1' => 'value1'});
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker2.class, new Map<String, Object>{'key2' => 'value2'});
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker3 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker3.class, new Map<String, Object>{'key3' => 'value3'});
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker4 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker4.class, new Map<String, Object>{'key4' => 'value4'});
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker4a = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker4a.class, new Map<String, Object>{'key5' => 'value5'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Contact.SObjectType,
				Case.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker1);
		uow.registerAsyncWork(stagingWorker1a);
		uow.registerAsyncWork(stagingWorker2);
		uow.registerAsyncWork(stagingWorker3);
		uow.registerAsyncWork(stagingWorker4);
		uow.registerAsyncWork(stagingWorker4a);
		uow.commitWork();

		// deliver our platform events to see if a new queueable was added
		Test.getEventBus().deliver();

		System.assertEquals(6, [SELECT Position FROM EventBusSubscriber WHERE Topic='aef_AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position);
		System.assertEquals(4, [SELECT COUNT() FROM AsyncApexJob], 'Expected handler to invoke 3 worker threads');

		Test.stopTest();

		List<aef_Log__c> logs = [SELECT Id, ExceptionDetails__c FROM aef_Log__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

		List<String> expectedStack = new List<String>{
				'MyAsyncWorker1', // <-- group 1
				'MyAsyncWorker1a', // <-- group 1
				'MyAsyncWorker2', // <-- group 2
				'MyAsyncWorker3', // <-- group 3
				'MyAsyncWorker4', // <-- group 4
				'MyAsyncWorker4a' // <-- group 4
		};

		System.assertEquals(expectedStack, aef_ApplicationUnitOfWorkTestUtility.asyncStack, 'The workers were not executed correctly');

	}

	/**
	 * Scenario:
	 * Test to make sure that async operations do not continue to be enqueued beyond the allowed maximum stack depth
	 */
	@IsTest
	private static void testEnsureAsyncWorkDoesNotExceedTheMaximumStackDepth() {

		// =====================================
		// Data Preparation
		// =====================================

		// only allow a single level of async workers
		aef_ApplicationUnitOfWork.testClassMaxAsyncStackDepth = 1;


		// MyAsyncWorker5 will try and enqueue itself over and again
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker5 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker5.class, new Map<String, Object>{'key1' => 'value1'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{Account.SObjectType};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerAsyncWork(stagingWorker5);
		uow.commitWork();

		// force deliver the platform event generated by uow.commitWork();
		// this will queue a queueable to execute when Test.stopTest() is called
		Test.getEventBus().deliver();

		// this will execute the async worker which will try and enqueue another level of async worker
		// given this would exceed the stack depth, an exception would be thrown (which the framework will catch)
		Test.stopTest();

		// check the async worker error
		List<aef_AsyncWorker__c> workerRecords = [SELECT ClassType__c, IsError__c, LastError__c FROM aef_AsyncWorker__c];
		System.assertEquals(1, workerRecords.size(), 'Did not expect more than 1 worker record to be created');

		System.assert(workerRecords[0].IsError__c, 'Expected worker to be in error state since it tried to enqueue beyond the maximum stack depth');
		System.assert(workerRecords[0].LastError__c.contains('aef_ApplicationUnitOfWork.AsyncUnitOfWorkException'), 'Expected aef_ApplicationUnitOfWork.AsyncUnitOfWorkException exception, got: ' + workerRecords[0].LastError__c);

		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected same job count since an exception should prevent subsequent registration');
		List<String> expectedStack = new List<String>{
				'MyAsyncWorker5'
		};

		System.assertEquals(expectedStack, aef_ApplicationUnitOfWorkTestUtility.asyncStack, 'The workers were not executed correctly');
	}

	/**
	 * Scenario:
	 * Test to make sure that grouped async operations continue to execute even when one of the workers fails
	 */
	@IsTest
	private static void testEnsureGroupedAsyncWorkContinuesEvenWhenOneWorkerFails() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorkerThrowsExceptions = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorkerThrowsExceptions.class, new Map<String, Object>{'key1' => 'value1'});
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker1.class, new Map<String, Object>{'key1' => 'value1'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{Account.SObjectType};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerAsyncWork(stagingWorkerThrowsExceptions);
		uow.registerAsyncWork(stagingWorker1);
		uow.commitWork();

		// force deliver the platform event generated by uow.commitWork();
		// this will queue a queueable to execute when Test.stopTest() is called
		Test.getEventBus().deliver();

		// this will execute the async workers into a single queueable
		// One should fail, the other should execute,
		// One asyncworker record should be deleted, the other should remain
		Test.stopTest();

		// check the async worker error
		List<aef_AsyncWorker__c> workerRecords = [SELECT ClassType__c, IsError__c, LastError__c FROM aef_AsyncWorker__c];
		System.assertEquals(1, workerRecords.size(), 'Did not expect more than 1 worker record to remain');

		System.assert(workerRecords[0].IsError__c, 'Expected worker to be in error state');
		System.assert(workerRecords[0].LastError__c.contains('aef_ApplicationUnitOfWorkTestUtility.WorkerThrowsException'), 'Expected aef_ApplicationUnitOfWorkTestUtility.WorkerThrowsException exception, got: ' + workerRecords[0].LastError__c);

		// make sure only 1 group
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected only 1 queueable with 2 workers');

		List<String> expectedStack = new List<String>{
				'MyAsyncWorkerThrowsExceptions', //<-- an entry is added here even though an exception is thrown after
				'MyAsyncWorker1'
		};
		System.assertEquals(expectedStack, aef_ApplicationUnitOfWorkTestUtility.asyncStack, 'The workers were not executed correctly');
	}


	/**
	 * Scenario:
	 * Ensures that a log item is created when we need to discard an async worker due to max depth limitation
	 */
	@IsTest
	private static void testEnsureAsyncWorkIsDiscardedAndLoggedWhenMaxStackDepthIsReached() {

		// =====================================
		// Data Preparation
		// =====================================

		// only allow a single level of async workers
		aef_ApplicationUnitOfWork.testClassMaxAsyncStackDepth = 1;
		aef_ApplicationUnitOfWork.currentAsyncStackDepth = 1;

		// MyAsyncWorker5 will try and enqueue itself over and again
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorkerIsDiscarded.class);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker);
		uow.commitWork();

		Test.stopTest();

		List<aef_Log__c> logs = [SELECT Id, ExceptionDetails__c FROM aef_Log__c];
		System.assertEquals(1, logs.size(), logs);

		System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob], 'Did not expect queueables since worker should have been discarded');

	}

	/**
	 * Scenario:
	 * Makes sure that all work is executed in the same container once the stack depth is reached
	 */
	@IsTest
	private static void testEnsureAsyncWorkIsChainProcessedInSyncWhenMaxStackDepthIsReached() {

		// =====================================
		// Data Preparation
		// =====================================

		// do not allow any level of asynchronous processing
		// should cause all operations to be processed in sync
		aef_ApplicationUnitOfWork.testClassMaxAsyncStackDepth = 1;
		aef_ApplicationUnitOfWork.currentAsyncStackDepth = 1;

		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorkerIsProcessedInSync1.class);
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorkerIsProcessedInSync2.class);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker1);
		uow.registerAsyncWork(stagingWorker2);
		uow.commitWork();

		Test.getEventBus().deliver();

		Test.stopTest();

		System.assertEquals(2, aef_ApplicationUnitOfWorkTestUtility.asyncWorkerCount);
		System.assertEquals(new List<String>{'MyAsyncWorkerIsProcessedInSync1', 'MyAsyncWorkerIsProcessedInSync2'}, aef_ApplicationUnitOfWorkTestUtility.asyncStack);
		System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob], 'All work should have been processed in the current container');
	}

	/**
	 * Scenario:
	 * Event when a max stack depth is reached, if the async worker is configured with FORCE ASYNC, then it should be queued into an async context
	 * NOTE: The async one would always process after the one that is processed in sync
	 */
	@IsTest
	private static void testEnsureAsyncWorkIsPushedIntoAsyncWithForceAsync() {

		// =====================================
		// Data Preparation
		// =====================================

		// should cause all operations to be processed in sync except the ones explicity configures with FORCE_ASYNC
		aef_ApplicationUnitOfWork.testClassMaxAsyncStackDepth = 1;
		aef_ApplicationUnitOfWork.currentAsyncStackDepth = 1;

		// trigger an asynchronous proesssing
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorkerForcedAsyncWorker.class);

		// trigger a synchronous processing
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1a = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker1a.class);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Contact.SObjectType,
				Case.SObjectType
		};

		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker1);
		uow.registerAsyncWork(stagingWorker1a);
		uow.commitWork();

		// deliver our platform events to see if a new queueable was added
		Test.getEventBus().deliver();

		// only the one that is forced into ASYNC would publish a platform event
		System.assertEquals(1, [SELECT Position FROM EventBusSubscriber WHERE Topic='aef_AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position);

		// only 1 job should be enqueued which would be stagingWorker1a
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected handler to invoke queueable to call async API for worker 1');

		Test.stopTest();


		System.assertEquals(2, aef_ApplicationUnitOfWorkTestUtility.asyncWorkerCount, 'Still expected 2 workers to execute: 1 in current context, 1 in a forced async context');

		// NOTE that stagingWorker1a should be processed before the async worker (since a platform event would be published first which will eventually trigger a queueable)
		System.assertEquals(new List<String>{'MyAsyncWorker1a', 'MyAsyncWorkerForcedAsyncWorker'}, aef_ApplicationUnitOfWorkTestUtility.asyncStack);

		List<aef_Log__c> logs = [SELECT Id, ExceptionDetails__c FROM aef_Log__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

	}

	/**
	 * Scenario:
	 * Ensures that an error will be generated when an invalid configuration is set for an async worker
	 */
	@IsTest
	private static void testEnsureExceptionIsGeneratedWithInvalidAsyncWorkerConfiguration() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWork.class);
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker3 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorkerWithLargeRetryAttempts.class);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerAsyncWork(stagingWorker2);

			System.assert(false, 'An error was expected for an invalid config. Invalid class type');
		} catch(aef_ApplicationUnitOfWork.AsyncUnitOfWorkException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Generic error occurred: ' + ex);
		}

		try {
			uow.registerAsyncWork(stagingWorker3);

			System.assert(false, 'An error was expected for an invalid config. Invalid number of retry attempts specified');
		} catch(aef_ApplicationUnitOfWork.AsyncUnitOfWorkException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Generic error occurred: ' + ex);
		}
	}

	/**
	 * Scenario:
	 * Ensure that parameters are correctly deserialised based on the custom override method defined in the worker.
	 */
	@IsTest
	private static void testEnsureAsyncWorkerDeserialisesParametersCorrectlyIntegration() {

		// =====================================
		// Data Preparation
		// =====================================

		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorkerDeserialisesParams.class, new Map<String, String>{'MyParam1' => 'This', 'MyParam2' => 'Deserialised', 'MyParam3' => 'Correctly'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker);
		uow.commitWork();

		// deliver our platform events to see if a new queueable was added
		// this will only deliver 2 because of the queueable limit override
		Test.getEventBus().deliver();

		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected 2 queueable jobs to be added when aef_AsyncWorkerEvent__e event is published');

		System.assertEquals(new List<String>{'MyAsyncWorkerDeserialisesParams'}, aef_ApplicationUnitOfWorkTestUtility.asyncStack);

	}

	/**
	 * Scenario:
	 * Ensures that when the platform event is invoked for an async queueable, it does not exceed the number of queueables allowed for that transaction
	 * The platform event should exit gracefully and kick off another transaction
	 */
	@IsTest
	private static void testEnsureAsyncQueueablesDoNotExceedTheQueueableLimitIntegration() {

		// =====================================
		// Data Preparation
		// =====================================

		// make sure the platform event handle only enqueues 2 queueables
		aef_ApplicationUnitOfWorkAsyncHandler.testClassMaxAsyncQueueableOverride = 2;

		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker2.class, new Map<String, Object>{'key2' => 'value2'});
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker3 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker3.class, new Map<String, Object>{'key3' => 'value3'});
		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker4 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker4.class, new Map<String, Object>{'key4' => 'value4'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker2);
		uow.registerAsyncWork(stagingWorker3);
		uow.registerAsyncWork(stagingWorker4);

		uow.commitWork();

		// deliver our platform events to see if a new queueable was added
		// this will only deliver 2 because of the queueable limit override
		Test.getEventBus().deliver();

		System.assertEquals(2, [SELECT COUNT() FROM AsyncApexJob], 'Expected 2 queueable jobs to be added when aef_AsyncWorkerEvent__e event is published');

		// this will only deliver 2 because of the queueable limit override
		Test.getEventBus().deliver();

		Test.stopTest();

		System.assertEquals(3, [SELECT COUNT() FROM AsyncApexJob], 'Expected 1 additional queueable job (first 2 + this 1 = 3) to be added when aef_AsyncWorkerEvent__e event is published');

		System.assertEquals(3, aef_ApplicationUnitOfWorkTestUtility.asyncWorkerCount, 'MyAsyncWorker1 should have been invoked 4 times');

	}

	/**
	 * Scenario:
	 * Ensure the async and exclusive async work queues are populated
	 */
	@IsTest
	private static void testEnsureAsyncWorkersAreRegistered() {

		// =====================================
		// Data Preparation
		// =====================================

		aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(aef_ApplicationUnitOfWorkTestUtility.MyAsyncWorker1.class);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker1);
		uow.registerAsyncWork(stagingWorker1.clone());
		uow.registerAsyncWork(stagingWorker1.clone());
		uow.registerAsyncWork(stagingWorker1.clone());

		System.assertEquals(4, uow.getAsyncWorkCount());

		Test.stopTest();

	}

}