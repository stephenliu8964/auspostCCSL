/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Whenever an account is classified as Government with a certain annual revenue,
 * this module keeps the Rating field in sync and coordinates account manager notification
 *
 * @author Nathan Franklin
 * @changelog
 */
public inherited sharing class aef_GovernmentAccountRatingModule extends aef_ApplicationDomain.Module {

	private static final Integer HOT_REVENUE_THRESHOLD = 2000000;
	private static final String HOT_RATING = 'Hot';
	private static final String TASK_SUBJECT_TEXT = 'Review Account: Status Changed to Hot';
	private static final Integer TASK_COMPLETION_DATE_THRESHOLD = 3;

	// Setup which triggers this module should respond to
	public aef_GovernmentAccountRatingModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		setDefaultHotRating((List<Account>)records, null, uow);
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
		setDefaultHotRating((List<Account>)records, (Map<Id, Account>)existingRecords, uow);
	}

	private void setDefaultHotRating(List<Account> records, Map<Id, Account> existingRecords, aef_ApplicationUnitOfWork uow) {

		Set<Id> processableAccountIds = new Set<Id>();
		Map<Id, Set<SObjectField>> changedRecords = new Map<Id, Set<SObjectField>>();
		if(existingRecords != null && !existingRecords.isEmpty()) {
			changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Industry, Account.AnnualRevenue});
		}

		for(Account record : records) {
			// check if either industry field or revenue field has changed and the revenue matches the threshold and the account is not already classified as hot
			// NOTE: we don't need to check the value of industry since it will always be classed as Government since this module is executed in the Government domain
			if(((existingRecords != null && existingRecords.get(record.Id) == null) || (changedRecords.get(record.Id) != null && !changedRecords.get(record.Id).isEmpty())) && record.AnnualRevenue >= HOT_REVENUE_THRESHOLD && !HOT_RATING.equalsIgnoreCase(record.Rating)) {
				record.Rating = HOT_RATING;

				if(!String.valueOf(record.OwnerId).startsWith('00G')) {
					// don't add accounts where the owner is a queue
					processableAccountIds.add(record.Id);
				}
			}
		}

		if(!processableAccountIds.isEmpty()) {
			// for all the accounts that have been classified (or reclassified) as Hot, we need to notifiy the account manager via a task
			// since this is not time-critical, we defer it to async
			Map<String, Object> params = new Map<String, Object>{'accountIds' => processableAccountIds};
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncTaskCreation.class, params));
		}
	}

	public without sharing class AsyncTaskCreation extends aef_ApplicationUnitOfWork.AsyncWorker {

		Set<Id> accountIds;

		public override Type getClassType() {
			return AsyncTaskCreation.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Task.SObjectType;
		}

		/**
		 * Override the default deserialisation which simply executes deserialiseUntyped
		 */
		public override void deserialiseParams(String serialisedParams) {
			AccountParams params = (AccountParams)JSON.deserialize(serialisedParams, AccountParams.class);
			this.accountIds = params.accountIds;
		}

		public override void execute(aef_ApplicationUnitOfWork uow) {
			Set<Id> ownerIds = new Set<Id>();
			List<Account> accounts = aef_AccountsSelector.newInstance().selectById(accountIds);
			for(Account record : accounts) {
				// don't add accounts where the owner is a queue
				if(!String.valueOf(record.OwnerId).startsWith('00G')) {
					ownerIds.add(record.OwnerId);
				}
			}

			if(!ownerIds.isEmpty()) {
				Map<String, Object> searchParams = new Map<String, Object>{
					'whatIds' => accountIds,
					'ownerIds' => ownerIds,
					'isClosed' => false
				};
				List<Task> openAccountManagerTasks = aef_TasksSelector.newInstance().search(searchParams, new Set<Object>(), true);

				// determines whether an open task exists for the account manager against the Account record
				Map<Id, Boolean> accountTaskOwnerMappings = new Map<Id, Boolean>();
				for(Task record : openAccountManagerTasks) {
					if(accountTaskOwnerMappings.get(record.WhatId) == null) {
						accountTaskOwnerMappings.put(record.WhatId, true);
					}
				}

				for (Account record : accounts) {
					if(accountTaskOwnerMappings.get(record.Id) != true) {
						uow.registerNew(new Task(WhatId = record.Id, OwnerId = record.OwnerId, Subject = TASK_SUBJECT_TEXT, ActivityDate = System.today().addDays(TASK_COMPLETION_DATE_THRESHOLD)), false, 'aef_GovernmentAccountRatingModule.AsyncTaskCreation');
					}
				}
			}
		}
	}

	public class AccountParams {
		public Set<Id> accountIds;
	}

	public static aef_GovernmentAccountRatingModule newInstance() {
		return (aef_GovernmentAccountRatingModule)aef_Application.Utilities.newInstance(aef_GovernmentAccountRatingModule.class);
	}
}