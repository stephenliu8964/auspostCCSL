/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * @author Nathan Franklin
 * @changelog
 */
public inherited sharing class aef_EnterpriseService {

	private static final Integer REVENUE_THRESHOLD = 4000000;
	private static final String ENTERPRISE_CASE_PRIORITY = 'High';

	public static aef_EnterpriseService getInstance() {
		return (aef_EnterpriseService)aef_Application.Utilities.getInstance(aef_EnterpriseService.class);
	}

	public Set<Id> filterEnterpriseAccounts(Set<Id> accountIds) {
		List<Account> accounts = ((aef_AccountsSelector)aef_AccountsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{Account.AnnualRevenue})).selectById(accountIds);
		return new Map<Id, Account>(filterEnterpriseAccounts(accounts)).keySet();
	}

	public List<Account> filterEnterpriseAccounts(List<Account> accounts) {
		List<SObject> output = new List<SObject>();
		for(Account record : accounts) {
			if(record.AnnualRevenue >= REVENUE_THRESHOLD) {
				output.add(record);
			}
		}
		return output;
	}

	/**
	 * Reclassify case priorities for enterprise accounts.
	 * NOTE: This sets the value by ref for the passed in value in addition to return the filtered cases too
	 * (flexible :) )
	 */
	public List<Case> reclassifyCasePriorities(List<Case> caseRecords) {
		List<Case> output = new List<Case>();
		for(Case caseRecord : caseRecords) {
			if(!ENTERPRISE_CASE_PRIORITY.equalsIgnoreCase(caseRecord.Priority)) {
				caseRecord.Priority = ENTERPRISE_CASE_PRIORITY;
				output.add(caseRecord);
			}
		}
		return output;
	}

}