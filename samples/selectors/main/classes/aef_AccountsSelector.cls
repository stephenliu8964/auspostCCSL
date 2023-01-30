/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description A very simple selector class for Account
 * @author Nathan Franklin
 * @changelog
*/
public virtual inherited sharing class aef_AccountsSelector extends aef_ApplicationSelector {
	public enum Options {
		WITH_OWNER, WITH_CONTACTS, WITH_TASKS
		//, WITH_CASES, WITH_OPPORTUNITIES etc... can be implemented
	}

	public static aef_AccountsSelector newInstance() {
		return (aef_AccountsSelector)aef_Application.Selectors.newInstance(aef_AccountsSelector.class);
	}

	public static aef_AccountsSelector newInstance(Integer recordLimit) {
		return (aef_AccountsSelector)aef_Application.Selectors.newInstance(aef_AccountsSelector.class).setLimit(recordLimit);
	}

	/**
	 * @param fieldOverrides Allows fields to be overridden for this selector
	 */
	public static aef_AccountsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		aef_AccountsSelector selector = (aef_AccountsSelector)aef_Application.Selectors.newInstance(aef_AccountsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides Allows fields to be overridden for this selector and all related/child selectors
	 */
	public static aef_AccountsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		aef_AccountsSelector selector = (aef_AccountsSelector)aef_Application.Selectors.newInstance(aef_AccountsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return Account.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Account.Id, Account.Name, Account.Type, Account.OwnerId,
			Account.BillingStreet, Account.BillingCity, Account.BillingState,
			Account.BillingPostalCode, Account.Phone, Account.BillingCountry,
			Account.ShippingStreet, Account.ShippingCity, Account.ShippingState,
			Account.ShippingPostalCode, Account.ShippingCountry, Account.AccountNumber
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<Account> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<Account> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		aef_QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new aef_QueryBuilder.SimpleCondition(Account.Id + ' in :ids')).endConditions();
		return (List<Account>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on Account Numbers
	 */
	public List<Account> selectByAccountNumber(Set<String> accountNumbers) {
		return selectByAccountNumber(accountNumbers, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Account Numbers
	 */
	public List<Account> selectByAccountNumber(Set<String> accountNumbers, Set<Object> selectorOptions) {
		aef_QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new aef_QueryBuilder.SimpleCondition(Account.AccountNumber + ' in :accountNumbers')).endConditions();
		return (List<Account>)Database.query(qb.toSoqlString());
	}


	/**
	 * @description Grabs a new aef_QueryBuilder based on the selector options passed in
	 */
	public virtual override aef_QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		System.debug(selectorOptions);

		aef_QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(aef_OwnersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Owner');
		}

		if(selectorOptions.contains(Options.WITH_CONTACTS)) {
			// NOTE: We clone and remove WITH_CONTACTS to ensure we mitigate infinite looping scenarios
			// This is needed from time due to cyclic referencing
			builder.addSubQuery(aef_ContactsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(cloneAndRemoveOption(selectorOptions, Options.WITH_CONTACTS)), 'Contacts');
		}

		if(selectorOptions.contains(Options.WITH_TASKS)) {
			builder.addSubQuery(aef_TasksSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Tasks');
		}

		return builder;
	}

}