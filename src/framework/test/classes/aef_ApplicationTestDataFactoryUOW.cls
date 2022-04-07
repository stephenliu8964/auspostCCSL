/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description Contains all the test data methods for Unit of Work test classes
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
public class aef_ApplicationTestDataFactoryUOW {

	public static List<aef_AsyncWorkerEvent__e> getAsyncWorkerEvents(Integer count, Object classType) {
		List<aef_AsyncWorkerEvent__e> output = (List<aef_AsyncWorkerEvent__e>)aef_ApplicationTestDataFactory.populateSObjects(aef_AsyncWorkerEvent__e.SObjectType, new Map<SObjectField, Object> {
				aef_AsyncWorkerEvent__e.MaxNumberRetries__c => aef_ApplicationUnitOfWork.MAX_LOCK_FAIL_RETRY_ATTEMPTS,
				aef_AsyncWorkerEvent__e.CurrentLockRetryAttempts__c => 0,
				aef_AsyncWorkerEvent__e.UserId__c => UserInfo.getUserId(),
				aef_AsyncWorkerEvent__e.ClassType__c => classType,
				aef_AsyncWorkerEvent__e.CurrentStackDepth__c => 0
		}, count);

		return output;
	}

	public static List<aef_AsyncWorker__c> getAsyncWorkerRecords(Integer count, Object classType, Object queueableIds, Boolean generateIds) {
		List<aef_AsyncWorker__c> output = (List<aef_AsyncWorker__c>)aef_ApplicationTestDataFactory.maybeGenerateIds(aef_ApplicationTestDataFactory.populateSObjects(aef_AsyncWorker__c.SObjectType, new Map<SObjectField, Object> {
				aef_AsyncWorker__c.MaxNumberRetries__c => aef_ApplicationUnitOfWork.MAX_LOCK_FAIL_RETRY_ATTEMPTS,
				aef_AsyncWorker__c.UserId__c => UserInfo.getUserId(),
				aef_AsyncWorker__c.ClassType__c => classType,
				aef_AsyncWorker__c.QueueableJobId__c => queueableIds,
				aef_AsyncWorker__c.CurrentStackDepth__c => 0
		}, count), generateIds);

		return output;
	}
	
}