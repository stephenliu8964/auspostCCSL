/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @author Nathan Franklin
 * @description A very simple selector class that sits in the base domain
 * @changelog
 */
public virtual inherited sharing class aef_CasesSelector extends aef_ApplicationSelector {

	public enum Options {
		WITH_OWNER, WITH_CONTACT, WITH_ACCOUNT
		//, WITH_CASECOMMENTS, WITH_ATTACHMENTS etc... can be implemented
	}

	public static aef_CasesSelector newInstance() {
		return (aef_CasesSelector)aef_Application.Selectors.newInstance(aef_CasesSelector.class);
	}
	public static aef_CasesSelector newInstance(Integer recordLimit) {
		return (aef_CasesSelector)aef_Application.Selectors.newInstance(aef_CasesSelector.class).setLimit(recordLimit);
	}

	/**
	 * @param fieldOverrides Allows fields to be overridden for this selector
	 */
	public static aef_CasesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		aef_CasesSelector selector = (aef_CasesSelector)aef_Application.Selectors.newInstance(aef_CasesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides Allows fields to be overridden for this selector and all related/child selectors
	 */
	public static aef_CasesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		aef_CasesSelector selector = (aef_CasesSelector)aef_Application.Selectors.newInstance(aef_CasesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Case.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Case.Id, Case.AccountId, Case.BusinessHoursId, Case.CaseNumber, Case.Origin, Case.OwnerId, Case.Reason,
			Case.IsClosed, Case.IsClosedOnCreate, Case.ContactEmail, Case.ContactMobile, Case.ContactId,
			Case.ContactPhone, Case.CreatedById, Case.ClosedDate, Case.CreatedDate, Case.Description,
			Case.IsEscalated, Case.Comments, Case.LastModifiedDate, Case.LastModifiedById, Case.ParentId,
			Case.Priority, Case.Status, Case.Subject, Case.Type, Case.SuppliedCompany, Case.SuppliedEmail,
			Case.SuppliedName, Case.SuppliedPhone
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual List<Case> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual List<Case> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		aef_QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new aef_QueryBuilder.SimpleCondition(Case.Id + ' in :ids')).endConditions();
		return (List<Case>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 accountIds: maps to AccountId (Set<Id>/Id)
	 *						 contactIds: maps to ContactOd (Set<Id>/Id)
	 *						 ownerIds: maps to OwnerId (Set<Id>/Id)
	 *						 isClosed: maps to IsClosed (Boolean)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return Map<Id, Task>
	 */
	public List<Case> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		// bind vars set in the getSearchSoql
		// will only work if these are defined here
		Set<Id> accountIds = (Set<Id>)(searchParams.get('accountIds') == null ? new Set<Id>() : (searchParams.get('accountIds') instanceof Set<Id> ? searchParams.get('accountIds') : new Set<Id>{(Id)searchParams.get('accountIds')}));
		Set<Id> contactIds = (Set<Id>)(searchParams.get('contactIds') == null ? new Set<Id>() : (searchParams.get('contactIds') instanceof Set<Id> ? searchParams.get('contactIds') : new Set<Id>{(Id)searchParams.get('contactIds')}));
		Set<Id> ownerIds = (Set<Id>)(searchParams.get('ownerIds') == null ? new Set<Id>() : (searchParams.get('ownerIds') instanceof Set<Id> ? searchParams.get('ownerIds') : new Set<Id>{(Id)searchParams.get('ownerIds')}));
		Boolean isClosed = (Boolean) searchParams.get('isClosed');

		return (List<Case>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 accountIds: maps to AccountId (Set<Id>/Id)
	 *						 contactIds: maps to ContactOd (Set<Id>/Id)
	 *						 ownerIds: maps to OwnerId (Set<Id>/Id)
	 *						 isClosed: maps to IsClosed (Boolean)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return Map<Id, Task>
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		aef_QueryBuilder builder = newQueryBuilder(selectorOptions);

		// add our tracking query
		aef_QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('contactIds')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('ContactId in :contactIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('accountIds')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('AccountId in :accountIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('isClosed')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('IsClosed = :isClosed'));
			conditionCount++;
		}
		if(searchParams.containsKey('ownerIds')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('OwnerId in :ownerIds'));
			conditionCount++;
		}

		// build our condition string which would end up being something liek the following:
		// 1 AND 2 AND 3
		// 1 OR 2 OR 3
		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);
		return conditions.endConditions().toSoqlString();
	}

	public virtual override aef_QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override aef_QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		aef_QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(aef_OwnersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Owner');
		}

		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(aef_ContactsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Contact');
		}

		if(selectorOptions.contains(Options.WITH_ACCOUNT)) {
			builder.addRelatedFields(aef_AccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Account');
		}

		return builder;
	}

}