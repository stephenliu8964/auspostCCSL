/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description Yet another Test data factory...
 * @author Nathan Franklin
 * @changelog
*/
@IsTest
public with sharing class aef_ApplicationTestDataFactory {

	public static List<Account> getAccounts(Integer count, Boolean generateIds) {
		return (List<Account>)maybeGenerateIds(populateSObjects(Account.SObjectType, new Map<SObjectField, Object> {
				Account.Name => 'Test Name %count%',
				Account.NumberOfEmployees => '%count%',
				Account.AnnualRevenue => 1000000,
				Account.AccountNumber => '%count%',
				Account.Industry => 'Manufacturing'
		}, count), generateIds);
	}

	public static List<Contact> getContacts(Integer count, Object accountIdOrIds, Boolean generateIds) {
		return (List<Contact>)maybeGenerateIds(populateSObjects(Contact.SObjectType, new Map<SObjectField, Object> {
				Contact.FirstName => 'First Name %count%',
				Contact.LastName => 'Last Name %count%',
				Contact.Email => 'ZZtest%count%@test%count%.test%count%.com',
				Contact.DoNotCall => true,
				Contact.AccountId => accountIdOrIds
		}, count), generateIds);
	}

	public static List<Case> getCases(Integer count, Object contactIdOrIds, Boolean generateIds) {
		List<Case> output = (List<Case>)maybeGenerateIds(populateSObjects(Case.SObjectType, new Map<SObjectField, Object> {
				Case.Subject => 'Case Subject %count%',
				Case.Description => 'Case Description %count%',
				Case.Status => 'New',
				Case.ContactId => contactIdOrIds
		}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (Case)setUnwritableFields(output[i], new Map<String, Object>{'IsClosed' => false});
		}

		return output;
	}

	public static List<Task> getTasks(Integer count, Object whoIdsOrId, Object whatIdsOrId, Boolean generateIds) {
		List<Task> output = (List<Task>)maybeGenerateIds(populateSObjects(Task.SObjectType, new Map<SObjectField, Object> {
			Task.WhoId => whoIdsOrId,
			Task.WhatId => whatIdsOrId,
			Task.ActivityDate => System.today(),
			Task.Subject => 'Subject %count%'
		}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (Task)setUnwritableFields(output[i], new Map<String, Object>{'IsClosed' => false});
		}

		return output;
	}

	public static List<Lead> getLeads(Integer count, Boolean generateIds) {
		return (List<Lead>) maybeGenerateIds(populateSObjects(Lead.SObjectType, new Map<SObjectField, Object>{
			Lead.FirstName => 'First Name %count%',
			Lead.LastName => 'Last Name %count%',
			Lead.Company => 'Company %count%',
			Lead.Email => 'ZZtest%count%@test%count%.test%count%.com',
			Lead.MobilePhone => '0444123456',
			Lead.LeadSource => 'Client'
		}, count), generateIds);
	}

	public static List<Campaign> getCampaigns(Integer count, Boolean generateIds) {
		List<Campaign> output = (List<Campaign>)maybeGenerateIds(populateSObjects(Campaign.SObjectType, new Map<SObjectField, Object> {
			Campaign.Name => 'Campaign %count%'
		}, count), generateIds);

		return output;
	}

	public static List<UserRole> getUserRoles(Integer count, Boolean generateIds) {
		return (List<UserRole>)maybeGenerateIds(populateSObjects(UserRole.SObjectType, new Map<SObjectField, Object> {
				UserRole.DeveloperName => 'UserRole_%count%'
		}, count), generateIds);
	}

	public static List<User> getUsers(Integer count, Boolean generateIds) {
		return getUsers(count, defaultUserProfileId, generateIds);
	}

	public static List<User> getUsers(Integer count, Id profileId, Boolean generateIds) {
		List<User> output = (List<User>)maybeGenerateIds(populateSObjects(User.SObjectType, new Map<SObjectField, Object> {
				User.FirstName => 'First Name %count%',
				User.LastName => 'Last Name %count%',
				User.Username => 'ZZtest%count%@test%count%.test%count%.com',
				User.Email => 'ZZtest%count%@test%count%.test%count%.com',
				User.Alias => 'R12Z%count%',
				User.EmailEncodingKey => 'UTF-8',
				User.TimeZoneSidKey => 'Australia/Sydney',
				User.LanguageLocaleKey => 'en_AU',
				User.LocaleSidKey => 'en_AU',
				User.ProfileId => profileId
		}, count), generateIds);

		for(Integer i=0;i<output.size();i++) {
			output[i] = (User)setUnwritableFields(output[i], new Map<String, Object>{'Name' => output[i].FirstName + ' ' + output[i].LastName});
		}

		return output;
	}

	public static List<Opportunity> getOpportunities(Integer count, Object accountIdOrIds, Boolean generateIds){
		return (List<Opportunity>)maybeGenerateIds(populateSObjects(Opportunity.SObjectType, new Map<SObjectField, Object> {
			Opportunity.Name => 'test opportunity %count%',
			Opportunity.Type => 'New Customer',
			Opportunity.StageName => 'Identify',
			Opportunity.CloseDate => Date.today().addDays(365),
			Opportunity.AccountId => accountIdOrIds
		}, count), generateIds);
	}

	public static void generateRecordIds(List<SObject> records) {
		for(SObject record : records) {
			record.Id = fflib_IDGenerator.generate(record.getSObjectType());
		}
	}

	/**
	 * This little hack, idea courtesy of Andy Fawcett, will enable us to put values into fields that are not writeable for the purposes of mocking data without using DML operations
	 * An example of such a construct is .Owner on the SObject. The OwnerId field is writable, but we are unable to set the .Owner value (i suppose because it's automatically populated after calling a soql)
	 * NOTE: Not all relationship fields are unwritable, however, for the ones that are.... this method can be used.
	 * I would imagine this is not very performant, however, I'm sure it still trumps doing actual DML and SOQL operations
	 *
	 * NOTE: That Blobs (Attachment.Body for example) do not work with serialisation. Values should be nulled and reset after if you run into problems
	 */
	public static SObject setUnwritableFields(SObject record, Map<String, Object> relationshipFields) {
		Map<String, Object> recordAsMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(record));
		for(String key : relationshipFields.keySet()) {
			recordAsMap.put(key, relationshipFields.get(key));
		}
		return (SObject)JSON.deserialize(JSON.serialize(recordAsMap), SObject.class);
	}

	/**
	 * This little hack, idea courtesy of Andy Fawcett, will enable us to put values into fields that are not writeable for the purposes of mocking data without using DML operations
	 * An example of such a construct is .Owner on the SObject. The OwnerId field is writable, but we are unable to set the .Owner value (i suppose because it's automatically populated after calling a soql)
	 * NOTE: Not all relationship fields are unwritable, however, for the ones that are.... this method can be used.
	 * I would imagine this is not very performant, however, I'm sure it still trumps doing actual DML and SOQL operations
	 *
	 * NOTE: That Blobs (Attachment.Body for example) do not work with serialisation. Values should be nulled and reset after if you run into problems
	 */
	public static SObject setChildRelationships(SObject record, Map<String, List<SObject>> childRelationships) {
		Map<String, Object> recordAsMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(record));

		for(String childRelationship : childRelationships.keySet()) {
			recordAsMap.put(childRelationship, new Map<String, Object>{
					'done' => true,
					'totalSize' => childRelationships.get(childRelationship).size(),
					'records' => childRelationships.get(childRelationship)
			});
		}

		return (SObject)JSON.deserialize(JSON.serialize(recordAsMap), SObject.class);
	}

	public static List<SObject> maybeGenerateIds(List<SObject> records, Boolean generateIds) {
		if(generateIds) {
			generateRecordIds(records);
		}

		return records;
	}

	public static List<SObject> populateSObjects(SObjectType sObjectType, Map<SObjectField, Object> fields, Integer count) {
		List<SObject> output = new List<SObject>();
		for(Integer i=0;i<count;i++) {
			SObject record = sObjectType.newSObject();
			for(SObjectField fieldName : fields.keySet()) {
				Object value = fields.get(fieldName);
				if(!String.isEmpty(String.valueOf(value)) && String.valueOf(value).contains('%count%')) {
					value = normaliseDataType(fieldName, String.valueOf(value).replace('%count%', String.valueOf(i+1)));

				}
				if(value instanceof List<Id>) {
					record.put(fieldName, ((List<Id>) value).get(i));
				} else if(value instanceof Set<Id>) {
					record.put(fieldName, (new List<Id>((Set<Id>)value)).get(i));
				} else {
					record.put(fieldName, value);
				}
			}
			output.add(record);
		}

		return output;
	}

	private static Object normaliseDataType(SObjectField fieldName, String value) {
		DescribeFieldResult result = fieldName.getDescribe();
		if(result.getType() == Schema.DisplayType.CURRENCY || result.getType() == Schema.DisplayType.DOUBLE || result.getType() == Schema.DisplayType.PERCENT) {
			return Decimal.valueOf(value);
		} else if(result.getType() == Schema.DisplayType.INTEGER) {
			return Integer.valueOf(value);
		} else if(result.getType() == Schema.DisplayType.LONG) {
			return Long.valueOf(value);
		} else {
			return value;
		}
	}

	public static Id defaultUserProfileId {
		get {
			if(defaultUserProfileId == null) {
				defaultUserProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
			}
			return defaultUserProfileId;
		}
		private set;
	}
}