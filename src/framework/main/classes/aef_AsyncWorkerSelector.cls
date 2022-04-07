/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Selector class for retrieving aef_AsyncWorker__c records
 *
 * @author Nathan Franklin
 * @changelog
 */
public inherited sharing class aef_AsyncWorkerSelector extends aef_ApplicationSelector {

	public enum Options {

	}

	public static aef_AsyncWorkerSelector newInstance() {
		return (aef_AsyncWorkerSelector)aef_Application.Selectors.newInstance(aef_AsyncWorkerSelector.class);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static aef_AsyncWorkerSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		aef_AsyncWorkerSelector selector = (aef_AsyncWorkerSelector)aef_Application.Selectors.newInstance(aef_AsyncWorkerSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return aef_AsyncWorker__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				aef_AsyncWorker__c.ClassType__c, aef_AsyncWorker__c.CurrentLockRetryAttempts__c, aef_AsyncWorker__c.CurrentStack__c, aef_AsyncWorker__c.CurrentStackDepth__c,
				aef_AsyncWorker__c.LastError__c, aef_AsyncWorker__c.MaxNumberRetries__c, aef_AsyncWorker__c.Parameters1__c, aef_AsyncWorker__c.Parameters2__c, aef_AsyncWorker__c.Parameters3__c, aef_AsyncWorker__c.Parameters4__c, aef_AsyncWorker__c.QueueableJobId__c,
				aef_AsyncWorker__c.SObjectTypeGroup__c, aef_AsyncWorker__c.UnitOfWorkSObjectTypes__c, aef_AsyncWorker__c.UserId__c, aef_AsyncWorker__c.RequiresCallouts__c, aef_AsyncWorker__c.ForcedIntoCurrentContext__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, aef_AsyncWorker__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, aef_AsyncWorker__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		aef_QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions().add(new aef_QueryBuilder.SimpleCondition(aef_AsyncWorker__c.Id + ' in :ids')).endConditions();
		return new Map<Id, aef_AsyncWorker__c>((List<aef_AsyncWorker__c>)Database.query(qb.toSoqlString()));
	}

}