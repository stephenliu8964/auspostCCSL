/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Helper class for aef_ApplicationUnitOfWork_Test
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
public class aef_ApplicationUnitOfWorkTestUtility {

	public static Integer asyncWorkerCount = 0;
	public static List<String> asyncStack = new List<String>();

	public class MyAsyncWorker1 extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorker1');

			asyncStack.add('MyAsyncWorker1');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorker1.class;
		}
	}

	public class MyAsyncWorker1a extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorker1a');

			asyncStack.add('MyAsyncWorker1a');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorker1a.class;
		}
	}

	public class MyAsyncWorker2 extends aef_ApplicationUnitOfWork.AsyncWorker implements Database.AllowsCallouts{
		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorker2');

			asyncStack.add('MyAsyncWorker2');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorker2.class;
		}
	}

	public class MyAsyncWorker3 extends aef_ApplicationUnitOfWork.AsyncWorker {
		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorker3');

			asyncStack.add('MyAsyncWorker3');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Contact.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorker3.class;
		}
	}

	public class MyAsyncWorker4 extends aef_ApplicationUnitOfWork.AsyncWorker {
		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorker4');

			asyncStack.add('MyAsyncWorker4');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Case.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorker4.class;
		}
	}

	public class MyAsyncWorker4a extends aef_ApplicationUnitOfWork.AsyncWorker {
		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorker4a');

			asyncStack.add('MyAsyncWorker4a');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Case.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorker4a.class;
		}
	}

	/**
	 * Infinite loop test
	 */
	public class MyAsyncWorker5 extends aef_ApplicationUnitOfWork.AsyncWorker {
		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorker5');

			asyncStack.add('MyAsyncWorker5');
			asyncWorkerCount++;

			aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker5 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(MyAsyncWorker5.class, new Map<String, Object>{'key1' => 'value1'});
			uow.registerAsyncWork(stagingWorker5);
		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.THROW_EXECPTION;
		}

		public override Type getClassType() {
			return MyAsyncWorker5.class;
		}
	}

	/**
	 * Testing chaining of async workers
	 */
	public class MyAsyncWorkerForcedAsyncEnqueueWorker extends aef_ApplicationUnitOfWork.AsyncWorker {
		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerForcedAsyncEnqueueWorker');

			asyncStack.add('MyAsyncWorkerForcedAsyncEnqueueWorker');
			asyncWorkerCount++;

			// this one will be forced into a new async container
			aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker = new aef_ApplicationUnitOfWork.AsyncStagingWorker(MyAsyncWorkerForcedAsyncWorker.class);
			uow.registerAsyncWork(stagingWorker);

			// this one will be processed in the existing container
			aef_ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new aef_ApplicationUnitOfWork.AsyncStagingWorker(MyAsyncWorker1.class, new Map<String, Object>{'key1' => 'value1'});
			uow.registerAsyncWork(stagingWorker2);
		}

		public override Type getClassType() {
			return MyAsyncWorkerForcedAsyncEnqueueWorker.class;
		}
	}

	public class MyAsyncWorkerForcedAsyncWorker extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerForcedAsyncWorker');

			asyncStack.add('MyAsyncWorkerForcedAsyncWorker');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorkerForcedAsyncWorker.class;
		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.FORCE_ASYNC;
		}

	}

	public class MyAsyncWorkerDeserialisesParams extends aef_ApplicationUnitOfWork.AsyncWorker {

		public MyAsyncWorkerDeserialisesParamsParameters myParams;

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.assertEquals('This', myParams.MyParam1, 'Incorect MyParams values: ' + myParams);
			System.assertEquals('Deserialised', myParams.MyParam2, 'Incorect MyParams values: ' + myParams);
			System.assertEquals('Correctly', myParams.MyParam3, 'Incorect MyParams values: ' + myParams);

			System.debug('MyAsyncWorkerDeserialisesParams');

			asyncStack.add('MyAsyncWorkerDeserialisesParams');
			asyncWorkerCount++;

			throw new WorkerThrowsException();
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorkerDeserialisesParams.class;
		}

		public override void deserialiseParams(String serialisedParams) {
			myParams = (MyAsyncWorkerDeserialisesParamsParameters)JSON.deserialize(serialisedParams, MyAsyncWorkerDeserialisesParamsParameters.class);
		}
	}

	public class MyAsyncWorkerThrowsExceptions extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerThrowsExceptions');

			asyncStack.add('MyAsyncWorkerThrowsExceptions');
			asyncWorkerCount++;

			throw new WorkerThrowsException();
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorkerThrowsExceptions.class;
		}
	}

	public class MyAsyncWorkerIsDiscarded extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerIsDiscarded');

			asyncStack.add('MyAsyncWorkerIsDiscarded');
			asyncWorkerCount++;

			throw new WorkerThrowsException();
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.DISCARD_AND_LOG;
		}

		public override Type getClassType() {
			return MyAsyncWorkerIsDiscarded.class;
		}
	}

	public class MyAsyncWorkerIsProcessedInSync1 extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerIsProcessedInSync1');

			asyncStack.add('MyAsyncWorkerIsProcessedInSync1');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.PROCESS_SYNC;
		}

		public override Type getClassType() {
			return MyAsyncWorkerIsProcessedInSync1.class;
		}
	}

	public class MyAsyncWorkerIsProcessedInSync2 extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerIsProcessedInSync2');

			asyncStack.add('MyAsyncWorkerIsProcessedInSync2');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.PROCESS_SYNC;
		}

		public override Type getClassType() {
			return MyAsyncWorkerIsProcessedInSync2.class;
		}
	}

	/**
	 * Testing chaining of async workers
	 */
	public class MyAsyncWorkerThrowDMLLockExceptionError extends aef_ApplicationUnitOfWork.AsyncWorker {
		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerThrowDMLLockExceptionError');

			asyncStack.add('MyAsyncWorkerThrowDMLLockExceptionError');
			asyncWorkerCount++;

			if(asyncWorkerCount < 2) {
				// Simulate the record locking result if a record is locked for update
				DmlException e = new DmlException();
				e.setMessage('UNABLE_TO_LOCK_ROW');
				throw e;
			}
		}

		public override Type getClassType() {
			return MyAsyncWorkerThrowDMLLockExceptionError.class;
		}
	}

	public class MyAsyncWorkerWithLargeRetryAttempts extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerWithLargeRetryAttempts');

			asyncStack.add('MyAsyncWorkerWithLargeRetryAttempts');
			asyncWorkerCount++;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override Type getClassType() {
			return MyAsyncWorkerWithLargeRetryAttempts.class;
		}

		public override Integer getRetryAttemptsOnLockFailure() {
			return 100000;
		}
	}

	/**
	 * Handles a dummy callout to test whether an async queueable worker was invoked with AllowCallouts
	 * This method would throw a CalloutException if not invoked with AllowCallouts
	 */
	public class AsyncWorkerThatDoesCallout extends aef_ApplicationUnitOfWork.AsyncWorker implements Database.AllowsCallouts {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('AsyncWorkerThatDoesCallout');

			asyncStack.add('AsyncWorkerThatDoesCallout');
			asyncWorkerCount++;

			// Used with QueueableWorkerDummyCalloutHttpMock
			HttpRequest req = new HttpRequest();
			req.setEndpoint('dummyEndpoint');
			Http http = new Http();
			http.send(req);

			markCalloutSavepoint(Database.setSavepoint());

		}

		public override Type getClassType() {
			return AsyncWorkerThatDoesCallout.class;
		}
	}

	/**
	 * Handles a dummy callout to test whether an async queueable worker was invoked with AllowCallouts
	 * This method would throw a CalloutException if not invoked with AllowCallouts
	 */
	public class MyAsyncWorkerDoesCalloutsButIsntConfiguredTo extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			System.debug('MyAsyncWorkerDoesCalloutsButIsntConfiguredTo');

			asyncStack.add('MyAsyncWorkerDoesCalloutsButIsntConfiguredTo');
			asyncWorkerCount++;

			// should trigger a callout exception when used with a queueable
			HttpRequest req = new HttpRequest();
			req.setEndpoint('dummyEndpoint');
			Http http = new Http();
			http.send(req);

		}

		public override Type getClassType() {
			return MyAsyncWorkerDoesCalloutsButIsntConfiguredTo.class;
		}
	}

	/**
	 * Handles a dummy callout to test whether an async queueable worker was invoked with AllowsCallouts
	 * This method would throw a CalloutException if not invoked with AllowCallouts
	 */
	public class MyAsyncWorkerFailsAfterSuccessfulCallout extends aef_ApplicationUnitOfWork.AsyncWorker implements Database.AllowsCallouts {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			asyncStack.add('MyAsyncWorkerFailsAfterSuccessfulCallout');

			// Used with QueueableWorkerDummyCalloutHttpMock
			HttpRequest req = new HttpRequest();
			req.setEndpoint('dummyEndpoint');
			Http http = new Http();
			http.send(req);

			markCalloutSavepoint(Database.setSavepoint());

			// Insert a basic account record here to ensure it is rolled back when an exception is thrown from the worker
			Account acc = new Account(Name = 'MyAsyncWorkerFailsAfterSuccessfulCallout');
			insert acc;

			throw new WorkerThrowsException('Failed');

		}

		public override Type getClassType() {
			return MyAsyncWorkerFailsAfterSuccessfulCallout.class;
		}
	}

	public class MyAsyncWorkerInsertsAnAccount extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			asyncStack.add('MyAsyncWorkerInsertsAnAccount');

			Account acc = new Account(Name = 'MyAsyncWorkerInsertsAnAccount');
			insert acc;

		}

		public override Type getClassType() {
			return MyAsyncWorkerInsertsAnAccount.class;
		}
	}

	public class MyAsyncWorkerInsertsAnAccountThenThrowsAnError extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			asyncStack.add('MyAsyncWorkerInsertsAnAccountThenThrowsAnError');

			Account acc = new Account(Name = 'MyAsyncWorkerInsertsAnAccountThenThrowsAnError');
			insert acc;

			throw new WorkerThrowsException('Failed');

		}

		public override Type getClassType() {
			return MyAsyncWorkerInsertsAnAccountThenThrowsAnError.class;
		}
	}

	/**
	 * Throws a DML Lock error that should be caught and cause the job to be reenqueued
	 */
	public class MyAsyncWorkerThrowsLockErrors extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			asyncStack.add('MyAsyncWorkerThrowsLockErrors');

			DmlException e = new DmlException();
			e.setMessage('UNABLE_TO_LOCK_ROW');
			throw e;
		}

		public override Type getClassType() {
			return MyAsyncWorkerThrowsLockErrors.class;
		}
	}

	/**
	 * Throws a DML Lock error that should be caught and cause the job to be reenqueued
	 */
	public class MyAsyncWorkerThrowsLockErrors2 extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override void execute(aef_ApplicationUnitOfWork uow) {
			asyncStack.add('MyAsyncWorkerThrowsLockErrors2');

			Account acc = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

			Map<String, Object> errorObj = new Map<String, Object>{
				'message' => 'exclusive access to record',
				'statusCode' => 'UNABLE_TO_LOCK_ROW'
			};
			Database.Error dbError = (Database.Error)JSON.deserialize(JSON.serialize(errorObj), Database.Error.class);
			aef_ApplicationUnitOfWorkBase.DatabaseError wrapper = new aef_ApplicationUnitOfWorkBase.DatabaseError(acc, new List<Database.Error>{dbError}, new List<String>{'MyAsyncWorkerThrowsLockErrors2'}, 'UPDATE');

			aef_ApplicationUnitOfWorkBase.UnitOfWorkDatabaseException e = new aef_ApplicationUnitOfWorkBase.UnitOfWorkDatabaseException(new List<aef_ApplicationUnitOfWorkBase.DatabaseError>{wrapper});
			throw e;
		}

		public override Type getClassType() {
			return MyAsyncWorkerThrowsLockErrors2.class;
		}
	}

	public class AsyncAPIFiveEventsSuccessHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			List<String> idsInBody = request.getBody().split(',');
			if(idsInBody.size() == 5) {
				// we only send a successful response if the API was invoked with the expected number of Id's
				response.setStatusCode(200);
			} else {
				// make sure the API returns a 500 so it can handle the exception
				response.setStatusCode(500);
			}
			return response;
		}
	}

	public class AsyncAPISuccessHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			if(request.getBody().length() == 18) {
				// we only send a successful response if the API was invoked with the expected number of Id's
				response.setStatusCode(200);
			} else {
				// make sure the API returns a 500 so it can handle the exception
				response.setStatusCode(500);
			}
			return response;
		}
	}

	public class AsyncAPIFailedHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(500);
			return response;
		}
	}

	public class QueueableWorkerDummyCalloutHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			return response;
		}
	}

	public class WorkerThrowsException extends Exception { }

	public class MyAsyncWorkerDeserialisesParamsParameters {
		public String MyParam1;
		public String MyParam2;
		public String MyParam3;
	}

}