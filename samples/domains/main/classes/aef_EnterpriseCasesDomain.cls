/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * @author Nathan Franklin
 * @changelog
 */
public inherited sharing class aef_EnterpriseCasesDomain extends aef_ApplicationDomain {

	private static Map<Id, Boolean> queriedAccountIds = new Map<Id, Boolean>();

	public static aef_EnterpriseCasesDomain newInstance(List<SObject> sObjectList) {
		return (aef_EnterpriseCasesDomain)aef_ApplicationDomain.newInstance(aef_EnterpriseCasesDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain will use for triggers or method execution
	 */
	public override void registerModules() {

		// used to default case priority when an account is reclassified as enterprise
		registerModule(aef_EnterpriseCasesModule.class);

	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 *
	 * NOTE: This is an example to show how you possibly could filter for a particular domain
	 *	   This could be written better in real world scenario, this simply illustrates how filter could work as one possibility
	 */
	public override List<SObject> filter(List<SObject> records) {

		Set<Id> accountIds = new Set<Id>();
		for(Case caseRecord : (List<Case>)records) {
			if(caseRecord.AccountId != null) {
				accountIds.add(caseRecord.AccountId);
			}
		}

		// remove all the ids that have already been queried in this transaction
		accountIds.removeAll(queriedAccountIds.keySet());
		if(!accountIds.isEmpty()) {
			// will use a soql to grab the account's 'enterprise' status'
			Set<Id> enterpriseAccountIds = aef_EnterpriseService.getInstance().filterEnterpriseAccounts(accountIds);
			for(Id accountId : accountIds) {
				// case the result so we don't need to go back to the database later
				queriedAccountIds.put(accountId, enterpriseAccountIds.contains(accountId));
			}
		}

		// grab all the records that are linked to enterprise accounts
		List<SObject> output = new List<SObject>();
		for(Case caseRecord : (List<Case>)records) {
			if(caseRecord.AccountId != null && queriedAccountIds.get(caseRecord.AccountId) == true) {
				output.add(caseRecord);
			}
		}

		return output;
	}
}