/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description A very simple selector class
 * @author Nathan Franklin
 * @changelog
 */
public virtual inherited sharing class aef_TasksSelector extends aef_ApplicationSelector {

	public enum Options {
		WITH_OWNER, WITH_WHO
	}

	public static aef_TasksSelector newInstance() {
		return (aef_TasksSelector)aef_Application.Selectors.newInstance(aef_TasksSelector.class);
	}

	public static aef_TasksSelector newInstance(Integer offsetLimit) {
		return (aef_TasksSelector)aef_Application.Selectors.newInstance(aef_TasksSelector.class).setOffset(offsetLimit);
	}

	public override SObjectType getSObjectType() {
		return Task.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Task.Id, Task.Subject, Task.Description, Task.ActivityDate, Task.OwnerId, Task.WhatId,
				Task.WhoId, Task.Status, Task.Type, Task.IsClosed,  Task.Priority, Task.OwnerId
		};
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 whatIds: maps to WhatId (Set<Id>/Id)
	 *						 ownerIds: maps to OwnerId (Set<Id>/Id)
	 *						 subjects: maps to Subject (Set<String>/String)
	 *						 fromActivityDate: maps to ActivityDate and is the oldest activity date to select (Datetime)
	 *						 isClosed: maps to IsClosed (Boolean)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return Map<Id, Task>
	 */
	public List<Task> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		aef_QueryBuilder builder = newQueryBuilder(selectorOptions);

		// add our tracking query
		aef_QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Set<Id> whatIds = (Set<Id>)(searchParams.get('whatIds') == null ? new Set<Id>() : (searchParams.get('whatIds') instanceof Set<Id> ? searchParams.get('whatIds') : new Set<Id>{(Id)searchParams.get('whatIds')}));
		Set<Id> ownerIds = (Set<Id>)(searchParams.get('ownerIds') == null ? new Set<Id>() : (searchParams.get('ownerIds') instanceof Set<Id> ? searchParams.get('ownerIds') : new Set<Id>{(Id)searchParams.get('ownerIds')}));
		Set<String> subjects = (Set<String>)(searchParams.get('subjects') == null ? new Set<String>() : (searchParams.get('subjects') instanceof Set<String> ? searchParams.get('subjects') : new Set<String>{String.valueOf(searchParams.get('subjects'))}));
		Date fromActivityDate = searchParams.get('fromActivityDate') == null ? null : Date.valueOf(String.valueOf(searchParams.get('fromActivityDate')));
		Date toActivityDate = searchParams.get('toActivityDate') == null ? null : Date.valueOf(String.valueOf(searchParams.get('toActivityDate')));
		Boolean isClosed = (Boolean) searchParams.get('isClosed');
		
		Integer conditionCount = 0;
		if(searchParams.containsKey('fromActivityDate')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('ActivityDate >= :fromActivityDate'));
			conditionCount++;
		}
		if(searchParams.containsKey('toActivityDate')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('ActivityDate < :toActivityDate'));
			conditionCount++;
		}
		if(searchParams.containsKey('whatIds')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('WhatId in :whatIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('isClosed')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('IsClosed = :isClosed'));
			conditionCount++;
		}
		if(searchParams.containsKey('subjects')) {
			conditions.add(new aef_QueryBuilder.SimpleCondition('Subject in :subjects'));
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
		String soql = conditions.endConditions().toSoqlString();

		return (List<Task>)Database.query(soql);
	}

	/**
	 * @description Run a simple query to get records based on Ids
	 */
	public List<Task> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Ids
	 */
	public List<Task> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		aef_QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new aef_QueryBuilder.SimpleCondition(Task.Id + ' in :ids')).endConditions();
		return (List<Task>)Database.query(qb.toSoqlString());
	}
   
   /**
	 * @description Run a simple query to get records based on what Ids | PBRP
	 */
	public List<Task> selectByWhatId(Set<Id> whatIds) {
		aef_QueryBuilder qb = newQueryBuilder(new Set<Object>()).addConditions().add(new aef_QueryBuilder.SimpleCondition(Task.WhatId + ' in :whatIds')).endConditions();
		return new List<Task>((List<Task>)Database.query(qb.toSoqlString()));
	}

	public virtual override aef_QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		aef_QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_WHO)) {
			builder.addRelatedFields(aef_OwnersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Who');
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(aef_OwnersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Owner');
		}

		return builder;
	}

	public virtual override List<aef_QueryBuilder.Order> getOrderBy() {
		return new List<aef_QueryBuilder.Order>{new aef_QueryBuilder.Order('ActivityDate', 'Desc NULLS First')};
	}
}