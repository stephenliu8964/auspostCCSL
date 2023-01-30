/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 *
 * @author Nathan Franklin
 * @changelog
 */
public inherited sharing class aef_EnterpriseAccountCasesModule extends aef_ApplicationDomain.Module {

	// Setup which triggers this module should respond to
	public aef_EnterpriseAccountCasesModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
		maybeRetroFitCasePriorities((List<Account>)records, (Map<Id, Account>)existingRecords, uow);
	}

	private void maybeRetroFitCasePriorities(List<Account> records, Map<Id, Account> existingRecords, aef_ApplicationUnitOfWork uow) {

		Set<Id> processableAccountIds = new Set<Id>();
		Map<Id, Set<SObjectField>> changedRecords = new Map<Id, Set<SObjectField>>();
		if(existingRecords != null && !existingRecords.isEmpty()) {
			changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.AnnualRevenue});
		}

		// grab a list of the 'old state' records that were classed as enterprise
		// this will ensure we are only processing our actions if the old version of the record was not classed as an enterprise account
		// simply checking for changed annual revenue value is not enough since the original record could have already been classed as 'enterprise'
		Map<Id, Account> previousEnterpriseAccounts = new Map<Id, Account>(aef_EnterpriseService.getInstance().filterEnterpriseAccounts(existingRecords.values()));

		for(Account record : records) {
			// check if annualrevenue was changed AND if the previous version of the record WAS NOT classed as an enterprise account
			if(((existingRecords != null && existingRecords.get(record.Id) == null) || (changedRecords.get(record.Id) != null && !changedRecords.get(record.Id).isEmpty())) && previousEnterpriseAccounts.get(record.Id) == null) {
				processableAccountIds.add(record.Id);
			}
		}

		if(!processableAccountIds.isEmpty()) {
			// we need to retro fit any open cases to change their priority to high since the account was reclassified to an enterprise account
			// since this is not time-critical, we defer it to async
			Map<String, Object> params = new Map<String, Object>{'accountIds' => processableAccountIds};
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncRetroFitCasePriorities.class, params));
		}
	}

	public without sharing class AsyncRetroFitCasePriorities extends aef_ApplicationUnitOfWork.AsyncWorker {

		Set<Id> accountIds;

		public override Type getClassType() {
			return AsyncRetroFitCasePriorities.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Case.SObjectType;
		}

		/**
		 * Override the default deserialisation which simply executes deserialiseUntyped
		 */
		public override void deserialiseParams(String serialisedParams) {
			AccountParams params = (AccountParams)JSON.deserialize(serialisedParams, AccountParams.class);
			this.accountIds = params.accountIds;
		}

		public override void execute(aef_ApplicationUnitOfWork uow) {

			Map<String, Object> searchParams = new Map<String, Object>{
				'isClosed' => false,
				'accountIds' => accountIds
			};
			List<Case> openAccountCases = aef_CasesSelector.newInstance().search(searchParams, new Set<Object>(), true);

			if(!openAccountCases.isEmpty()) {

				// grab a filtered list of cases that need to updated to High priority
				List<Case> processableCasess = aef_EnterpriseService.getInstance().reclassifyCasePriorities(openAccountCases);

				if(!processableCasess.isEmpty()) {
					// trigger an update for the cases making sure we only update the Priority field and not the entire record (as its not necessary)
					for(Case caseRecord : processableCasess) {
						uow.registerDirty(caseRecord, new Set<SObjectField>{Case.Priority}, false, 'aef_EnterpriseAccountCasesModule.AsyncRetroFitCasePriorities');
					}
				}
			}
		}
	}

	public class AccountParams {
		public Set<Id> accountIds;
	}

	public static aef_EnterpriseAccountCasesModule newInstance() {
		return (aef_EnterpriseAccountCasesModule)aef_Application.Utilities.newInstance(aef_EnterpriseAccountCasesModule.class);
	}
}