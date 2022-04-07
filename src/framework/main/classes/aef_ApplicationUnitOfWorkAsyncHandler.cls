/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Platform Event handler for pushing Async operations into Queueables
 *
 * @author Nathan Franklin
 * @tests aef_ApplicationUnitOfWorkAsyncEvent_Test, aef_ApplicationUnitOfWork_Test
 * @changelog
 */
public with sharing class aef_ApplicationUnitOfWorkAsyncHandler {

	/**
	 * When an async container is forced (either by passing null in for SObject group or implementing Database.AllowsCallouts), we use an increment to break the group key generation up to force a new group to be created
	 */
	private static Integer exclusiveSObjectGroupIncrement = 0;
	private static Integer exclusiveCalloutGroupIncrement = 0;

	public static aef_ApplicationUnitOfWorkAsyncHandler getInstance() {
		return (aef_ApplicationUnitOfWorkAsyncHandler)aef_Application.Utilities.getInstance(aef_ApplicationUnitOfWorkAsyncHandler.class);
	}

	private static final Map<SObjectField, SObjectField> WORKER_RECORD_MAPPINGS = new Map<SObjectField, SObjectField>{
			aef_AsyncWorkerEvent__e.ClassType__c => aef_AsyncWorker__c.ClassType__c,
			aef_AsyncWorkerEvent__e.CurrentLockRetryAttempts__c => aef_AsyncWorker__c.CurrentLockRetryAttempts__c,
			aef_AsyncWorkerEvent__e.CurrentStack__c => aef_AsyncWorker__c.CurrentStack__c,
			aef_AsyncWorkerEvent__e.CurrentStackDepth__c => aef_AsyncWorker__c.CurrentStackDepth__c,
			aef_AsyncWorkerEvent__e.MaxNumberRetries__c => aef_AsyncWorker__c.MaxNumberRetries__c,
			aef_AsyncWorkerEvent__e.Parameters1__c => aef_AsyncWorker__c.Parameters1__c,
			aef_AsyncWorkerEvent__e.Parameters2__c => aef_AsyncWorker__c.Parameters2__c,
			aef_AsyncWorkerEvent__e.Parameters3__c => aef_AsyncWorker__c.Parameters3__c,
			aef_AsyncWorkerEvent__e.Parameters4__c => aef_AsyncWorker__c.Parameters4__c,
			aef_AsyncWorkerEvent__e.SObjectTypeGroup__c => aef_AsyncWorker__c.SObjectTypeGroup__c,
			aef_AsyncWorkerEvent__e.UnitOfWorkSObjectTypes__c => aef_AsyncWorker__c.UnitOfWorkSObjectTypes__c,
			aef_AsyncWorkerEvent__e.UserId__c => aef_AsyncWorker__c.UserId__c,
			aef_AsyncWorkerEvent__e.RequiresCallouts__c => aef_AsyncWorker__c.RequiresCallouts__c
	};

	/**
	 * A testing class hack to override the static MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION
	 */
	@TestVisible
	private static Integer testClassMaxAsyncQueueableOverride = 0;

	/**
	 * A testing class hack to override the static final MAX_GROUPED_ASYNC_WORKERS
	 */
	@TestVisible
	private static Integer testClassMaxGroupedWorkers = 0;

	/**
	 * The maximum hard stack depth (ignore the workers getMaxDepthAction instruction. This is to mitigate against infinit loop scenarios.
	 */
	private static final Integer MAX_HARD_STACK_DEPTH {
		get {
			if(MAX_HARD_STACK_DEPTH == null) {
				aef_SystemSettings__c settings = aef_SystemSettings__c.getInstance();
				MAX_HARD_STACK_DEPTH = Integer.valueOf((settings?.AsyncFrameworkNoExceptionMaxDepth__c == null ? 10 : settings.AsyncFrameworkNoExceptionMaxDepth__c));
			}
			return MAX_HARD_STACK_DEPTH;
		}
		private set;
	}


	/**
	 * The maximum allowed queueable jobs that can be created inside the exclusive async worker platform event (should be 50 as per documentation)
	 */
	@TestVisible
	private static final Integer MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION {
		get {
			if(MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION == null) {
				if(Test.isRunningTest() && testClassMaxAsyncQueueableOverride != 0) {
					MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION = testClassMaxAsyncQueueableOverride;
				} else {
					MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION = Limits.getLimitQueueableJobs();
				}
			}
			return MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION;
		}
		private set;
	}

	/**
	 * The maximum number of workers that can be grouped together before a new queueable will be triggered
	 */
	@TestVisible
	private static final Integer MAX_GROUPED_ASYNC_WORKERS {
		get {
			if(MAX_GROUPED_ASYNC_WORKERS == null) {
				if(Test.isRunningTest() && testClassMaxGroupedWorkers != 0) {
					MAX_GROUPED_ASYNC_WORKERS = testClassMaxGroupedWorkers;
				} else {
					aef_SystemSettings__c settings = aef_SystemSettings__c.getInstance();
					MAX_GROUPED_ASYNC_WORKERS = Integer.valueOf((settings?.AsyncFrameworkMaxGroupedWorkers__c == null ? 5 : settings.AsyncFrameworkMaxGroupedWorkers__c));
				}
			}
			return MAX_GROUPED_ASYNC_WORKERS;
		}
		private set;
	}

	public void dispatch(List<aef_AsyncWorkerEvent__e> events) {
		System.debug('aef_ApplicationUnitOfWorkAsyncHandler:dispatch');

		String lastReplayId = '';

		List<Exception> generatedExceptions = new List<Exception>();

		Map<String, List<aef_AsyncWorker__c>> groupedProcessable = new Map<String, List<aef_AsyncWorker__c>>();

		for(Integer i=0;i<events.size();i++) {

			// note the overarching try catch block
			// this is to ensure that any errors that exist with the data will not stop other events from being processed
			// on error, we discard the operation and log the error
			try {
				String groupKey = getNextAvailableGroupKey(events[i], groupedProcessable);

				// make sure there is still capacity to process more groups
				if(groupedProcessable.get(groupKey) == null && groupedProcessable.size() >= MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION) {
					// stop processing any more platform events since we wouldn't be able to enqueue any more platform events
					// we set the last successfully processed message below, so breaking from here will simply spawn a new transaction from the next unprocessed event message
					break;
				} else if(groupedProcessable.get(groupKey) == null) {
					// create the group
					groupedProcessable.put(groupKey, new List<aef_AsyncWorker__c>());
				}

				// add this item into the group
				groupedProcessable.get(groupKey).add(convertAsyncEventToWorkerRecord(events[i]));

			} catch(Exception ex) {
				// log the error that prevented this async worker from running correctly.
				// it's important that we catch these errors to ensure that the queue never stops processing
				generatedExceptions.add(ex);

				System.debug('Exception: ' + ex);
				System.debug(ex.getStackTraceString());
			}

			lastReplayId = events[i].ReplayId;
		}

		// store a log for any events with conversion and grouping problems
		if(!generatedExceptions.isEmpty()) {
			aef_ApplicationLogger.getInstance().logException(aef_ApplicationLogger.wrapException(generatedExceptions), aef_ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(aef_ApplicationUnitOfWorkAsyncHandler.class), 'dispatch', 'AsyncWorkerEventTrigger', aef_ApplicationLogger.LoggingLevel.ERROR);
		}

		// insert records into aef_AsyncWorker__c which will then be passed into the async API
		// we use this object as a way to track the pending async operations to be completed...
		if(!groupedProcessable.isEmpty()) {
			System.debug('Group Count: ' + groupedProcessable.size());

			List<aef_AsyncWorker__c> insertable = new List<aef_AsyncWorker__c>();
			for(String groupKey : groupedProcessable.keySet()) {
				System.debug('Group: ' + groupedProcessable.get(groupKey));
				insertable.addAll(groupedProcessable.get(groupKey));
			}

			List<Database.SaveResult> results = aef_ApplicationDatabase.getInstance().dmlInsert(insertable, false);
			aef_ApplicationLogger.getInstance().logFailedDatabaseResults(results, aef_ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(aef_ApplicationUnitOfWorkAsyncHandler.class), 'dispatch', 'AsyncWorkerEventTrigger', aef_ApplicationLogger.LoggingLevel.ERROR);

			// queue these workers up into their queueables
			processAsyncWorkerQueue(groupedProcessable.values());
		}

		// Set the Replay ID of the last successfully processed event message.
		// If a limit is hit, the trigger refires and processing starts with the
		// event after the last one processed (the set Replay ID)
		if(!String.isEmpty(lastReplayId)) {
			System.debug('Replay: ' + lastReplayId);
			EventBus.TriggerContext.currentContext().setResumeCheckpoint(lastReplayId);
		}

	}

	/**
	 * The group key is used to group workers together that have been received in the event bus
	 * This allows us to logically group workers together
	 */
	@TestVisible
	private String getNextAvailableGroupKey(aef_AsyncWorkerEvent__e event, Map<String, List<aef_AsyncWorker__c>> currentGroupingQueue) {

		// NOTE: we use integer increments to force a new group when the worker needs it
		// SObjectTypeGroup being null or RequiresCallouts being true force a unique group
		String key = '';
		key += event.UnitOfWorkSObjectTypes__c + '-';
		key += (String.isEmpty(event.SObjectTypeGroup__c) ? String.valueOf(++exclusiveSObjectGroupIncrement) : event.SObjectTypeGroup__c) + '-';
		key += event.UserId__c + '-';
		key += event.CurrentStackDepth__c + '-';
		key += (event.RequiresCallouts__c ? String.valueOf(++exclusiveCalloutGroupIncrement) : String.valueOf(event.RequiresCallouts__c));

		Integer increment = 1;
		while(true) {
			String checkKey = key + '-' + String.valueOf(increment);
			if(currentGroupingQueue.get(checkKey) == null || (currentGroupingQueue.get(checkKey) != null && currentGroupingQueue.get(checkKey).size() < MAX_GROUPED_ASYNC_WORKERS)) {
				key = checkKey;
				break;
			} else {
				increment++;
			}
		}

		System.debug('Found Group Key: ' + key);

		return key;
	}

	/**
	 * Spawn queueables based on the work provided in asyncWorkers variable. This is built from the platform event handler
	 * The exact number of ids will vary based on their group configuration and limits specified in
	 *      MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION and MAX_GROUPED_ASYNC_WORKERS
	 *
	 * NOTE:
	 * The method does not perform any grouping operations, it assumes the grouping is completed prior to calling this method, hence the List<List> input
	 * The number of groups passed in here MUST NOT exceed the available number of queueables since each group is queued into a separate enqueueable (max limit is 50 groups)
	 */
	public void processAsyncWorkerQueue(List<List<aef_AsyncWorker__c>> groupedAsyncWorkers) {
		List<aef_AsyncWorker__c> updateableAsyncWorkerRecords = new List<aef_AsyncWorker__c>();
		System.debug('asyncWorkers: ' + groupedAsyncWorkers);

		List<Exception> failedQueueWorkers = new List<Exception>();

		for(List<aef_AsyncWorker__c> asyncWorkers : groupedAsyncWorkers) {
			// ignore any empty groups
			if(asyncWorkers.isEmpty()) {
				continue;
			}

			// note the overarching try catch block
			// this is to ensure that any errors that exist with the data will not stop other events from being processed
			// on error, we discard the operation and log the error
			try {
				Id jobId;

				Set<Id> workerIds = new Map<Id, aef_AsyncWorker__c>(asyncWorkers).keySet();

				if (!asyncWorkers[0].RequiresCallouts__c) {
					// the normal AsyncWorker interface is enqueued when the worker does not require callouts
					// this queueable is a queueable without callouts
					AsyncQueueable queueable = new AsyncQueueable(workerIds);
					jobId = aef_ApplicationDatabase.getInstance().enqueueJob(queueable);
					System.debug('Queued: ' + queueable);
				} else {
					// for a scenario where an async worker requires to make callouts
					// we launch a special queueable that allows callouts
					AsyncQueueableWithCallout queueable = new AsyncQueueableWithCallout(workerIds);
					jobId = aef_ApplicationDatabase.getInstance().enqueueJob(queueable);
					System.debug('Queued: ' + queueable);
				}

				for(Id workerId : workerIds) {
					updateableAsyncWorkerRecords.add(new aef_AsyncWorker__c(Id = workerId, QueueableJobId__c = jobId));
				}
			} catch(Exception ex) {
				// log the error that prevented this async worker from running correctly.
				// it's important that we catch these errors to ensure that the queue never stops processing
				failedQueueWorkers.add(ex);

				System.debug('Exception: ' + ex);
				System.debug(ex.getStackTraceString());
			}
		}

		if(!updateableAsyncWorkerRecords.isEmpty()) {
			List<Database.SaveResult> saveResults = aef_ApplicationDatabase.getInstance().dmlUpdate(updateableAsyncWorkerRecords, false);
			aef_ApplicationLogger.getInstance().logFailedDatabaseResults(saveResults, aef_ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(aef_ApplicationUnitOfWork.class), 'processAsyncWorkerQueue', '', aef_ApplicationLogger.LoggingLevel.ERROR);
		}

		if(!failedQueueWorkers.isEmpty()) {
			// make sure we log and jobs that failed to be enqueued
			aef_ApplicationLogger.getInstance().logException(aef_ApplicationLogger.wrapException(failedQueueWorkers), aef_ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(aef_ApplicationUnitOfWork.class), 'processAsyncWorkerQueue', '', aef_ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Handle the processing of our async workers
	 * Based on a specific criteria, some workers can be grouped together
	 * This is based on isGrouped() being true
	 */
	private with sharing class AsyncQueueable implements Queueable {
		Set<Id> groupedWorkerIds;

		public AsyncQueueable(Set<Id> groupedWorkerIds) {
			this.groupedWorkerIds = groupedWorkerIds;
		}

		public void execute(QueueableContext context) {
			handleExecution(groupedWorkerIds);
		}
	}

	/**
	 * Handle the processing of our async workers with an optional callout
	 * This queueable is automatically called when a single async worker is being enqueued (no grouping)
	 */
	private with sharing class AsyncQueueableWithCallout implements Queueable, Database.AllowsCallouts {
		Set<Id> groupedWorkerIds;

		public AsyncQueueableWithCallout(Set<Id> groupedWorkerIds) {
			this.groupedWorkerIds = groupedWorkerIds;
		}

		public void execute(QueueableContext context) {
			handleExecution(groupedWorkerIds);
		}
	}

	private static void handleExecution(Set<Id> groupedWorkerIds) {
		handleExecution(aef_AsyncWorkerSelector.newInstance().selectById(groupedWorkerIds).values());
	}

	/**
	 * This is executed once we are inside a queueable context via AsyncQueueable / AsyncQueueableWithCallout
	 * There could be 1 or more workers grouped together
	 *
	 * Any workers grouped here will have gone through isLogicalGroup() method in order to be grouped.
	 * With this in mind, we can leverage the details of the first worker to get the current stack depth, stack and other key details
	 */
	public static void handleExecution(List<aef_AsyncWorker__c> asyncWorkerRecords) {
		if(asyncWorkerRecords == null || asyncWorkerRecords.isEmpty()) {
			return;
		}

		Boolean retrievedSObjectUnitOfWork = false;
		List<SObjectType> unitOfWorkSObjectTypes = new List<SObjectType>();
		Map<Id, aef_AsyncWorker__c> deletableWorkerRecords = new Map<Id, aef_AsyncWorker__c>();
		Map<Id, aef_AsyncWorker__c> updatableWorkerRecords = new Map<Id, aef_AsyncWorker__c>();
		List<aef_AsyncWorker__c> processableAsyncWorkerRecords = new List<aef_AsyncWorker__c>();
		List<aef_ApplicationUnitOfWork.IAsyncWorker> instantiatedWorkers = new List<aef_ApplicationUnitOfWork.IAsyncWorker>();

		// make sure there will be no runtime issues with 'framework' code
		for(aef_AsyncWorker__c asyncWorkerRecord : asyncWorkerRecords) {
			try {
				System.debug(asyncWorkerRecord);
				if(asyncWorkerRecord.ClassType__c == null || String.isEmpty(asyncWorkerRecord.ClassType__c) ||
						asyncWorkerRecord.RequiresCallouts__c == null ||
						asyncWorkerRecord.UserId__c == null || String.isEmpty(asyncWorkerRecord.UserId__c) ||
						asyncWorkerRecord.UnitOfWorkSObjectTypes__c == null || String.isEmpty(asyncWorkerRecord.UnitOfWorkSObjectTypes__c)) {
					throw new aef_ApplicationUnitOfWork.AsyncUnitOfWorkException('Worker definition is not configured correctly');
				}

				Type classType = Type.forName(asyncWorkerRecord.ClassType__c);
				if(classType == null) {
					throw new aef_ApplicationUnitOfWork.AsyncUnitOfWorkException('Worker definition is not configured correctly');
				}

				aef_ApplicationUnitOfWork.IAsyncWorker asyncWorker = (aef_ApplicationUnitOfWork.IAsyncWorker)(Type.forName(asyncWorkerRecord.ClassType__c).newInstance());

				// set the user based on the record
				asyncWorker.setUserId(Id.valueOf(asyncWorkerRecord.UserId__c));

				// build the unit of work that will be used with this async execution
				if(!retrievedSObjectUnitOfWork) {
					for (String sObjectType : (List<String>) JSON.deserialize(asyncWorkerRecord.UnitOfWorkSObjectTypes__c, List<String>.class)) {
						unitOfWorkSObjectTypes.add(((SObject) Type.forName(sObjectType).newInstance()).getSObjectType());
					}
					retrievedSObjectUnitOfWork = true;
				}

				// store a list of valid workers and their worker instances to process below
				// this give us a level of certainty that 'framework' code will not error once the execution of the workers has started
				processableAsyncWorkerRecords.add(asyncWorkerRecord);
				instantiatedWorkers.add(asyncWorker);
			} catch (Exception ex) {
				System.debug('Config validation exception: ' + ex);
				// the worker would never be able to execute so we put it into error state immediately and ignore its actual execution
				updatableWorkerRecords.putAll(attachErrorToAsyncWorkerRecords(new List<aef_AsyncWorker__c>{asyncWorkerRecord}, ex));
			}
		}

		if(!processableAsyncWorkerRecords.isEmpty()) {
			// grab a an instance of the uow that will be used based on the validation and preparation above
			aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(unitOfWorkSObjectTypes);

			Integer currentStackDepth = (processableAsyncWorkerRecords[0].CurrentStackDepth__c == null ? 0 : Integer.valueOf(processableAsyncWorkerRecords[0].CurrentStackDepth__c));
			Integer maxNumberRetries = (processableAsyncWorkerRecords[0].MaxNumberRetries__c == null ? 1 : Integer.valueOf(processableAsyncWorkerRecords[0].MaxNumberRetries__c));
			Integer currentRetryCount = (processableAsyncWorkerRecords[0].CurrentLockRetryAttempts__c == null ? 1 : Integer.valueOf(processableAsyncWorkerRecords[0].CurrentLockRetryAttempts__c));
			String sObjectTypeGroup = (String.isEmpty(processableAsyncWorkerRecords[0].SObjectTypeGroup__c) ? '' : processableAsyncWorkerRecords[0].SObjectTypeGroup__c);
			String currentStack = (String.isEmpty(processableAsyncWorkerRecords[0].CurrentStack__c) ? '' : processableAsyncWorkerRecords[0].CurrentStack__c);
			String sObjectUnitOfWorkTypesJSON = processableAsyncWorkerRecords[0].UnitOfWorkSObjectTypes__c;
			Id userId = (Id)processableAsyncWorkerRecords[0].UserId__c;

			// ==========================================================================================
			// THE MOST IMPORTANT STEP TO HELP MITIGATE INFINITE STACK DEPTH
			// ==========================================================================================
			// increase the current stack depth IMMEDIATELY!
			// track the stack depth and the stack so we can prevent an infinite loop
			// NOTE: We only increase the stack depth if the current worker was not forced into the current context due to the stack depth being exceeded
			//       ForcedIntoCurrentContext__c should only be populated when in aef_ApplicationUnitOfWork.doAsyncWork()
			if (processableAsyncWorkerRecords[0].ForcedIntoCurrentContext__c != true) {
				aef_ApplicationUnitOfWork.currentAsyncStackDepth = currentStackDepth + 1;
			}

			// failsafe (hard coded to try and prevent infinite looping if other failsafes fail)
			if (aef_ApplicationUnitOfWork.currentAsyncStackDepth > MAX_HARD_STACK_DEPTH) {
				throw new aef_ApplicationUnitOfWork.AsyncUnitOfWorkException('Stack is too deep (failsafe)');
			}

			// set the current stack that led us to this async operation
			aef_ApplicationUnitOfWork.currentAsyncStack = (String.isEmpty(currentStack) ? new List<String>() : currentStack.split('\n'));

			// set the user id here incase we go further down into the stack with subsequent exclusive async worker throughout the worker's execution cycle...
			aef_ApplicationUnitOfWork.currentAsyncUserId = userId;

			System.debug('Stack information: ');
			System.debug('currentStackDepth: ' + aef_ApplicationUnitOfWork.currentAsyncStackDepth);
			System.debug('currentStack: ' + aef_ApplicationUnitOfWork.currentAsyncStack);
			System.debug('');
			System.debug('Handling queueable work: ');
			System.debug('sObjectUnitOfWorkTypesJSON: ' + sObjectUnitOfWorkTypesJSON);
			System.debug('userId: ' + userId);
			System.debug('maxNumberRetries: ' + maxNumberRetries);
			System.debug('currentRetryCount: ' + currentRetryCount);
			System.debug('sObjectTypeGroup: ' + sObjectTypeGroup);

			// stores a reference to the last used asyncWorker
			// we need this in the event of the worker requiring callouts and an exception is thrown
			// storing this reference allows us to call asyncWorker.getCalloutSavepoint();
			aef_ApplicationUnitOfWork.IAsyncWorker asyncWorker;

			// create a savepoint to ensure that we can roll back the whole transaction if any lock errors occur
			// we only do this if the work does not require callouts since calling this prior to a callout, the callout would generate a CalloutException
			// if the work requires a callout, then it's the responsibility of the worker to call markCalloutSavepoint on IAsyncWorker (which would normally happen after a callout)
			System.Savepoint sp;
			if (!processableAsyncWorkerRecords[0].RequiresCallouts__c) {
				sp = aef_ApplicationDatabase.getInstance().dmlSetSavePoint();
			}

			try {

				if (!processableAsyncWorkerRecords[0].RequiresCallouts__c) {
					// tells the Unit of Work to throw an exception when it detects a lock error. This is irrespective of any row level configuration (throwOnError config with registerNew, registerDirty etc...)
					// we use this as a part of the retry capability in the 'catch' handler below
					// NOTE: This is only done in the event of an async worker not requiring a callout.
					//          Where a worker requires a callout, it's expected that the worker would manage this setting directly as needed!
					//          This is needed since committing the uow is done outside of the workers execution context
					//          REASONING: At times a worker performs a read callout which means it would be ok to re-run the worker, however in the event of a write, the retry logic may be undeseriable

					uow.throwLockErrors = true;
				}

				// execute all the workers grouped together in this queueable
				// co-ordinate any subsequent actions using a UOW

				for (Integer i=0;i<processableAsyncWorkerRecords.size();i++) {
					aef_AsyncWorker__c asyncWorkerRecord = processableAsyncWorkerRecords[i];
					asyncWorker = instantiatedWorkers[i];

					// create a savepoint for the individual worker to rollback any database activity that occurs within that specific worker if an exception occurs
					// this is to allow any additional workers to continue their execution making any database changes necessary
					// NOTE: We do not do this for workers that require callouts as per above documentation
					System.Savepoint workerSavePoint;
					if (!processableAsyncWorkerRecords[0].RequiresCallouts__c) {
						workerSavePoint = aef_ApplicationDatabase.getInstance().dmlSetSavePoint();
					}

					// Add an entry to the stack so if registerAsyncWork is called it take a snap shot of the stack so it can copy it into a new AsyncWorker__e platform event
					// This helps keep track of the stack for debugging
					aef_ApplicationUnitOfWork.currentAsyncStack.add('Worker: ' + asyncWorkerRecord.ClassType__c);
					Integer stackElement = aef_ApplicationUnitOfWork.currentAsyncStack.size() - 1;

					// this is where the main execution of the individual worker occurs
					// we wrap this individually to ensure errors do not spill over into other grouped workers
					try {
						// deserialise the parameters to allows the worker to use them in its execute method
						// NOTE: deserialise can be overridden by the worker if it needs to deserialise into a specific structure or if it wants to walk the json or whatever
						asyncWorker.deserialiseParams(String.join(new List<String>{asyncWorkerRecord.Parameters1__c, asyncWorkerRecord.Parameters2__c, asyncWorkerRecord.Parameters3__c, asyncWorkerRecord.Parameters4__c}, ''));

						asyncWorker.execute(uow);

						// since the worker execution completed successfully, we queue this record up for deletion (assuming uow.commitWork does not throw errors)
						deletableWorkerRecords.put(asyncWorkerRecord.Id, asyncWorkerRecord);

					} catch (Exception ex) {
						System.debug('Exception: ' + ex);
						// NOTE: the developer may choose to catch and handle errors directly which is ok

						// we need to check whether the exception thrown is a lock error or not or whether the worker was processing callouts
						if (asyncWorkerRecord.RequiresCallouts__c || isLockException(ex)) {
							// if an exception occurs then we just throw the exception and let the main exception handler process this
							// this is because if a worker requires callouts, there will only ever be 1 worker and we let the main catch block handle this
							// additionally, if it's a lock error, then the whole transaction fails and again, we want the main catch block to handle the decision about whether the workers should be re-endqueued or not
							throw ex;
						} else {
							// since this worker threw an exception (thats not a lock exception), we don't want this to impede on the other workers that will run in this group
							// we rollback the database to the point before the worker ran and then continue to the next worker
							// A SPECIAL NOTE: if the worker is using UOW register* methods then database activity still might occur for this worker after all workers have been processed.
							aef_ApplicationDatabase.getInstance().dmlRollback(workerSavePoint);

							// mark this worker as failed and then we can continue onto the next worker (if there is one)
							updatableWorkerRecords.putAll(attachErrorToAsyncWorkerRecords(new List<aef_AsyncWorker__c>{asyncWorkerRecord}, ex));
						}
					} finally {
						// since the currentAsyncStack is a static, we need to remove the item we added above since we are finished that that processing
						aef_ApplicationUnitOfWork.currentAsyncStack.remove(stackElement);
					}
				}

				// commit any work as a result of the executed workers
				// with throwLockErrors = true (set above), and lock errors will generate an UnitOfWorkDatabaseException (irrespective of any individual config at the async worker level)
				// NOTE: async workers that use callouts, must set throwLockErrors manually if needed to trigger a lock error
				uow.commitWork();

			} catch (Exception ex) {

				// NOTE: We catch exceptions to log errors from the workers but also to check if there were lock errors which can be retried
				//          This catches errors thrown from the worker itself (incase the work is doing direct dmls for example), or, from the UOW (commitWork)
				// when an exception occurs, we need to rollback all the database activity from the last save point
				if (asyncWorker == null) {
					// for whatever reason we did not get to the point of even instantiating a new worker.
					// this means it's probably an error with the framework or with the data that was passed in.
					throw new aef_ApplicationUnitOfWork.AsyncUnitOfWorkException('AsyncWorker was empty');
				} else if (processableAsyncWorkerRecords[0].RequiresCallouts__c) {
					if (asyncWorker.getCalloutSavepoint() != null) {
						// if the async worker has marked a savepoint then we rollback the transaction to that point
						// marking a save point is optional as the rollback might need to NOT happen in some scenarios
						aef_ApplicationDatabase.getInstance().dmlRollback(asyncWorker.getCalloutSavepoint());
					}
				} else {
					aef_ApplicationDatabase.getInstance().dmlRollback(sp);
				}

				if (isLockException(ex) && currentRetryCount < maxNumberRetries) {
					// the transaction needs to be retried since it failed because of a lock error
					System.debug('UNABLE_TO_LOCK_ROW, queueing the work to be processed again');
					System.debug(ex);

					// build a list of platform events to republish since this transaction failed
					List<aef_AsyncWorkerEvent__e> events = new List<aef_AsyncWorkerEvent__e>();
					for (aef_AsyncWorker__c asyncWorkerRecord : processableAsyncWorkerRecords) {
						aef_AsyncWorkerEvent__e ev = convertAsyncWorkerRecordToEvent(asyncWorkerRecord);
						ev.CurrentLockRetryAttempts__c = (ev.CurrentLockRetryAttempts__c == null ? 0 : Integer.valueOf(ev.CurrentLockRetryAttempts__c));
						ev.CurrentLockRetryAttempts__c++;
						events.add(ev);
					}

					// requeue the workers for reprocessing
					if (!events.isEmpty()) {
						aef_ApplicationDatabase.getInstance().eventPublish(events);
					}

					// remove the records that will be retried (these will be added as new records)
					deletableWorkerRecords.putAll(processableAsyncWorkerRecords);
				} else {
					// Update for the main exception handler scenario which would cover framework exception errors or lock error retry attempts are exceeded
					// INdividual workers individual exceptions are handles as each worker is processed and would not be processed here
					try {
						aef_ApplicationDatabase.getInstance().dmlUpdate(attachErrorToAsyncWorkerRecords(processableAsyncWorkerRecords, ex));
					} catch (Exception exp) {
						aef_ApplicationLogger.getInstance().logException(aef_ApplicationLogger.wrapException(exp), aef_ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(aef_ApplicationUnitOfWork.class), 'handleExecution', '', aef_ApplicationLogger.LoggingLevel.ERROR);
					}
				}
			}
		}

		// put this into it's own try catch block to ensure a lock error here doesn't result in all the workers being re-enqueued
		if(!deletableWorkerRecords.isEmpty()) {
			try {
				// remove the aef_AsyncWorker__c records because we are now finished with them
				aef_ApplicationDatabase.getInstance().dmlDelete(deletableWorkerRecords.values());
			} catch (Exception ex) {
				aef_ApplicationLogger.getInstance().logException(aef_ApplicationLogger.wrapException(ex), aef_ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(aef_ApplicationUnitOfWork.class), 'handleExecution', '', aef_ApplicationLogger.LoggingLevel.ERROR);
			}
		}

		// put this into it's own try catch block to ensure a lock error here doesn't result in all the workers being re-enqueued
		if(!updatableWorkerRecords.isEmpty()) {
			try {
				// remove the aef_AsyncWorker__c records because we are now finished with them
				aef_ApplicationDatabase.getInstance().dmlUpdate(updatableWorkerRecords.values());
			} catch (Exception ex) {
				aef_ApplicationLogger.getInstance().logException(aef_ApplicationLogger.wrapException(ex), aef_ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(aef_ApplicationUnitOfWork.class), 'handleExecution', '', aef_ApplicationLogger.LoggingLevel.ERROR);
			}
		}
	}

	private static List<aef_AsyncWorker__c> attachErrorToAsyncWorkerRecords(List<aef_AsyncWorker__c> asyncWorkerRecords, Exception ex) {
		List<aef_AsyncWorker__c> output = new List<aef_AsyncWorker__c>();

		String error = ex.getTypeName() + ': ' + ex.getMessage() + '\n' +
				ex.getStackTraceString();

		for (aef_AsyncWorker__c asyncWorkerRecord : asyncWorkerRecords) {
			output.add(new aef_AsyncWorker__c(Id = asyncWorkerRecord.Id, CurrentStack__c = String.join(aef_ApplicationUnitOfWork.currentAsyncStack, '\n'), IsError__c = true, LastError__c = error));
		}

		return output;
	}

	/**
	 * A lock could present itself in 1 of 2 ways:
	 * 1. If the developer is calling DML's directly then a DmlException would be thrown
	 * 2. If the developer is using aef_ApplicationUnitOfWork then it processes then inserts, updates, deletes that cause a lock error will be wrapped in UnitOfWorkDatabaseException
	 */
	private static Boolean isLockException(Exception ex) {
		Boolean isLock = (ex instanceof DmlException && ex.getMessage().contains('UNABLE_TO_LOCK_ROW'));
		if(!isLock) {
			isLock = (ex instanceof aef_ApplicationUnitOfWorkBase.UnitOfWorkDatabaseException && ((aef_ApplicationUnitOfWorkBase.UnitOfWorkDatabaseException)ex).containsLockError());
		}
		return isLock;
	}

	/**
	 * Will populate an aef_AsyncWorker__c record from an aef_AsyncWorkerEvent__e record
	 */
	private static aef_AsyncWorker__c convertAsyncEventToWorkerRecord(aef_AsyncWorkerEvent__e event) {
		aef_AsyncWorker__c asyncWorker = new aef_AsyncWorker__c();
		for(SObjectField field : WORKER_RECORD_MAPPINGS.keySet()) {
			asyncWorker.put(WORKER_RECORD_MAPPINGS.get(field), event.get(field));
		}
		return asyncWorker;
	}

	/**
	 * Will populate an aef_AsyncWorkerEvent__e record from an aef_AsyncWorker__c record
	 */
	private static aef_AsyncWorkerEvent__e convertAsyncWorkerRecordToEvent(aef_AsyncWorker__c workerRecord) {
		aef_AsyncWorkerEvent__e asyncWorkerEvent = new aef_AsyncWorkerEvent__e();
		for(SObjectField field : WORKER_RECORD_MAPPINGS.keySet()) {
			asyncWorkerEvent.put(field, workerRecord.get(WORKER_RECORD_MAPPINGS.get(field)));
		}
		return asyncWorkerEvent;
	}

}