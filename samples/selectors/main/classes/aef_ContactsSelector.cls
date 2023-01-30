/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description A very simple selector class
 * @author Nathan Franklin
 * @changelog
 */
public virtual inherited sharing class aef_ContactsSelector extends aef_ApplicationSelector {

	public enum Options {
		WITH_OWNER, WITH_ACCOUNT
	}

	public static aef_ContactsSelector newInstance() {
		return (aef_ContactsSelector)aef_Application.Selectors.newInstance(aef_ContactsSelector.class);
	}
	public static aef_ContactsSelector newInstance(Integer recordLimit) {
		return (aef_ContactsSelector)aef_Application.Selectors.newInstance(aef_ContactsSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return Contact.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Contact.Id, Contact.AccountId, Contact.FirstName, Contact.LastName, Contact.OwnerId, Contact.Name,
			Contact.Email, Contact.Phone, Contact.Fax, Contact.MobilePhone, Contact.HomePhone, Contact.Salutation,
			Contact.Title
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<Contact> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<Contact> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		aef_QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new aef_QueryBuilder.SimpleCondition(Contact.Id + ' in :ids')).endConditions();
		return (List<Contact>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on account Id's
	 */
	public List<Contact> selectByAccountId(Set<Id> accountIds) {
		return selectByAccountId(accountIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Account Id's
	 */
	public List<Contact> selectByAccountId(Set<Id> accountIds, Set<Object> selectorOptions) {
		aef_QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new aef_QueryBuilder.SimpleCondition(Contact.AccountId + ' in :accountIds')).endConditions();
		return (List<Contact>)Database.query(qb.toSoqlString());
	}

	/**
	 * Grabs a new aef_QueryBuilder
	 */
	public virtual override aef_QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	/**
	 * Grabs a new aef_QueryBuilder based on the selector options passed in
	 */
	public virtual override aef_QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		aef_QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(aef_OwnersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Owner');
		}

		if(selectorOptions.contains(Options.WITH_ACCOUNT)) {
			builder.addRelatedFields(aef_AccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Account');
		}

		return builder;
	}

}