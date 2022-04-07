/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Test class for aef_ApplicationUnitOfWorkBase_Test
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
private class aef_ApplicationUnitOfWorkBase_Test {

	/**
	 * Scenario:
	 * Make sure that records are inserted in the correct order.
	 * Also registers relationships so when a new record is inserted that is linked to another new record, the relationships will resolve correctly.
	 */
	@IsTest
	private static void testEnsureNewRecordsAreInsertedCorrectly() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];
		List<Contact> contactRecords = aef_ApplicationTestDataFactory.getContacts(2, (Id)null, false);
		Case caseRecord = aef_ApplicationTestDataFactory.getCases(1, null, false)[0];
		Lead leadRecord = aef_ApplicationTestDataFactory.getLeads(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.stopStubbing();
		fflib_InOrder inOrder1 = new fflib_InOrder(aef_MockUtility.Mocks, new List<Object>{ mockDatabase });

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Lead.SObjectType,
			Account.SObjectType,
			Contact.SObjectType,
			Case.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(new List<Case>{caseRecord}, true, '');
		uow.registerNew(accountRecord, true, '');
		uow.registerNew(contactRecords[0], Contact.AccountId, accountRecord);
		uow.registerNew(contactRecords[1], Contact.AccountId, accountRecord, true, '');
		uow.registerNew(leadRecord);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{leadRecord}, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{accountRecord}, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{caseRecord}, false);

		// make sure the dmlInsert was executed in the specific order that they were added in
		((aef_ApplicationDatabase)inOrder1.verify(mockDatabase, aef_MockUtility.Mocks.calls(1))).dmlInsert(new List<SObject>{leadRecord}, false);
		((aef_ApplicationDatabase)inOrder1.verify(mockDatabase, aef_MockUtility.Mocks.calls(1))).dmlInsert(new List<SObject>{accountRecord}, false);
		((aef_ApplicationDatabase)inOrder1.verify(mockDatabase, aef_MockUtility.Mocks.calls(1))).dmlInsert(new List<SObject>{caseRecord}, false);

		System.assertNotEquals(null, accountRecord.Id, 'Expected Account Id to be set.');
		System.assertEquals(accountRecord.Id, contactRecords[0].AccountId, 'Expected Account Id to be set.');
		System.assertEquals(accountRecord.Id, contactRecords[1].AccountId, 'Expected Account Id to be set.');
	}

	/**
	 * Scenario:
	 *
	 * 1. New account record to be created
	 * 2. Existing contact record updated and will link newly created account record (AccountId)
	 * 3. 1 lead to be updated with it's entire dataset
	 */
	@IsTest
	private static void testEnsureDirtyRecordsContainAllFieldsRegistered() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];
		Contact contactRecord = aef_ApplicationTestDataFactory.getContacts(1, null, true)[0];
		Lead leadRecord = aef_ApplicationTestDataFactory.getLeads(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLUpdated());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Lead.SObjectType,
			Account.SObjectType,
			Contact.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accountRecord);
		uow.registerDirty(new List<SObject>{contactRecord}, true, '');
		uow.registerRelationship(contactRecord, Contact.AccountId, accountRecord);
		uow.registerDirty(new List<SObject>{leadRecord});

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{accountRecord}, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{contactRecord}, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{leadRecord}, false);

		System.assertEquals(accountRecord.Id, contactRecord.AccountId, 'Expected Account Id to be set.');
	}

	/**
	 * Scenario:
	 *
	 * 1. New account record to be created
	 * 2. New contact to be created and will link newly create account record (AccountId)
	 * 3. Existing contact updated and will link newly create account record (AccountId)
	 * 4. 1 lead to be updated with it's entire dataset
	 */
	@IsTest
	private static void testEnsureDirtyRecordsCanBePartiallyRegisteredAndConcatenatedWithRelationships() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];
		Contact contactRecord = aef_ApplicationTestDataFactory.getContacts(1, null, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLUpdated());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Account.SObjectType,
			Contact.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accountRecord);

		// the whole record will be registered
		uow.registerDirty(new Contact(Id = contactRecord.Id, FirstName = 'TEST', Email = 'test@test.com', HomePhone = '0400000001'));

		// the selected fields will be appended to the existing registered record
		uow.registerDirty(new List<Contact>{new Contact(Id = contactRecord.Id, LastName = 'TEST')}, new Set<SObjectField>{Contact.LastName}, '');

		// the selected fields will be appended to the existing registered record
		uow.registerDirty(new List<Contact>{new Contact(Id = contactRecord.Id, Birthdate = System.today())}, new Set<SObjectField>{Contact.Birthdate}, false, '');

		// the selected fields will be appended to the existing registered record
		// note the exclusion of the Description field
		uow.registerDirty(new Contact(Id = contactRecord.Id, HomePhone = '0400000000', Description = 'IMNOTUSED'), new Set<SObjectField>{Contact.HomePhone});

		// all fields will be appended to the existing registered record
		// note the return value will be a reference to the entire registered record
		Contact registeredContact = (Contact)uow.registerDirty(new Contact(Id = contactRecord.Id, MobilePhone = '0400000000'));

		// register the billing account relationship to the article
		uow.registerRelationship(registeredContact, Contact.AccountId, accountRecord);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{accountRecord}, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{registeredContact}, false);

		// verify the expected fields were included in the dmlUpdate
		// thse are progressivly built as the same record is
		Set<String> populatedFields = registeredContact.getPopulatedFieldsAsMap().keySet();
		System.assert(populatedFields.contains(String.valueOf(Contact.FirstName)), 'Partial Contact should have included field');
		System.assert(populatedFields.contains(String.valueOf(Contact.LastName)), 'Partial Contact should have included field');
		System.assert(populatedFields.contains(String.valueOf(Contact.Email)), 'Contact Article should have included field');
		System.assert(populatedFields.contains(String.valueOf(Contact.Birthdate)), 'Partial Contact should have included field');
		System.assert(populatedFields.contains(String.valueOf(Contact.HomePhone)), 'Partial Contact should have included field');
		System.assert(populatedFields.contains(String.valueOf(Contact.MobilePhone)), 'Partial Contact should have included field');
		System.assert(populatedFields.contains(String.valueOf(Contact.AccountId)), 'Partial Contact should have included field');
		System.assertEquals(false, populatedFields.contains(String.valueOf(Contact.Description)), 'Partial Contact should not have included field');
		System.assertEquals('0400000000', registeredContact.HomePhone, 'Value should have been overwritten');

		// ensure billing account was populated on Article record
		System.assertNotEquals(null, accountRecord.Id, 'Expected Account Id to not be null');
		System.assertEquals(accountRecord.Id, registeredContact.AccountId, 'Expected Account Id to be set');
	}

	/**
	 * Scenario
	 * Ensures that registered relationships in UOW are resolved correctly
	 */
	@IsTest
	private static void testRelationshipMapping() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountRecords = aef_ApplicationTestDataFactory.getAccounts(2, false);
		List<Campaign> campaignRecords = aef_ApplicationTestDataFactory.getCampaigns(2, false);
		List<Opportunity> opportunityRecords = aef_ApplicationTestDataFactory.getOpportunities(2, null, false);
		List<Contact> contactRecords = aef_ApplicationTestDataFactory.getContacts(2, null, false);

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Campaign.SObjectType,
			Account.SObjectType,
			Opportunity.SObjectType,
			Contact.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		// make sure that all the relationships are registered correctly
		uow.registerRelationship(opportunityRecords[0], Opportunity.AccountId, accountRecords[0]);
		uow.registerRelationship(opportunityRecords[0], Opportunity.CampaignId, campaignRecords[0]);
		uow.registerRelationship(contactRecords[0], Contact.AccountId, accountRecords[0]);

		uow.registerRelationship(opportunityRecords[1], Opportunity.AccountId, accountRecords[1]);
		uow.registerRelationship(opportunityRecords[1], Opportunity.CampaignId, campaignRecords[1]);
		uow.registerRelationship(contactRecords[1], Contact.AccountId, accountRecords[1]);

		uow.registerNew(campaignRecords);
		uow.registerNew(accountRecords);
		uow.registerNew(opportunityRecords);
		uow.registerNew(contactRecords);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(campaignRecords, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(accountRecords, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(opportunityRecords, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(contactRecords, false);

		System.assertNotEquals(null, accountRecords[0].Id);
		System.assertNotEquals(null, opportunityRecords[0].Id);
		System.assertNotEquals(null, contactRecords[0].Id);

		System.assertNotEquals(null, accountRecords[1].Id);
		System.assertNotEquals(null, opportunityRecords[1].Id);
		System.assertNotEquals(null, contactRecords[1].Id);

		System.assertEquals(accountRecords[0].Id, opportunityRecords[0].AccountId, 'Expected Account Id to be set.');
		System.assertEquals(campaignRecords[0].Id, opportunityRecords[0].CampaignId, 'Expected Campaign Id to be set.');
		System.assertEquals(accountRecords[0].Id, contactRecords[0].AccountId, 'Expected Account Id to be set.');

		System.assertEquals(accountRecords[1].Id, opportunityRecords[1].AccountId, 'Expected Account Id to be set.');
		System.assertEquals(campaignRecords[1].Id, opportunityRecords[1].CampaignId, 'Expected Campaign Id to be set.');
		System.assertEquals(accountRecords[1].Id, contactRecords[1].AccountId, 'Expected Account Id to be set.');
	}

	/**
	 * Scenario:
	 * Make sure that when calling upsert it routes the records to either an insert or an update
	 */
	@IsTest
	private static void testEnsureUpsertingRecordsDoesInsertsAndUpdates() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, false);
		accounts[0].Id = fflib_IDGenerator.generate(Account.getSObjectType());
		List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(2, (Id)null, false);
		contacts[0].Id = fflib_IDGenerator.generate(Contact.getSObjectType());

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLUpdated());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Contact.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerUpsert(accounts);
		uow.registerUpsert(contacts, true, '');

		// make sure relationships are registered correctly
		uow.registerRelationship(contacts[0], Contact.AccountId, accounts[0]);
		uow.registerRelationship(contacts[1], Contact.AccountId, accounts[1]);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{accounts[1]}, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{accounts[0]}, false);

		// make sure that the relationships were resolved correctly in the context of upserting
		System.assertNotEquals(null, accounts[1].Id, 'Expected Account Id to be set.');
		System.assertEquals(accounts[0].Id, contacts[0].AccountId, 'Expected Account Id to be set.');
		System.assertEquals(accounts[1].Id, contacts[1].AccountId, 'Expected Account Id to be set.');
	}

	/**
	 * Scenario:
	 * Ensures that a platform event is published on the successful completion of a transaction.
	 */
	@IsTest
	private static void testEnsurePlatformEventIsPublishedOnSuccessfulTransaction() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, false);

		// this is the event that Camunda would send to communicate the an app was provisioned successfully
		List<aef_AsyncWorkerEvent__e> events = new List<aef_AsyncWorkerEvent__e>{
				new aef_AsyncWorkerEvent__e(ClassType__c = 'Application__c', Parameters1__c = '{}'),
				new aef_AsyncWorkerEvent__e(ClassType__c = 'Application__c', Parameters1__c = '{}')
		};

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLInserted());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Account.SObjectType,
			aef_AsyncWorkerEvent__e.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accounts);
		uow.registerPublishAfterSuccessTransaction(events);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).eventPublish(events);

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Ensures that dmlDelete is called when a record is queued for deletion in UOW.
	 * This also verifies that the deletes are done in reverse order of the way they are added
	 */
	@IsTest
	private static void testEnsureRecordsDeletion() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];
		Lead leadRecord = aef_ApplicationTestDataFactory.getLeads(1, true)[0];
		List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(2, accountRecord.Id, true);

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLDeleted());
		aef_MockUtility.Mocks.stopStubbing();
		fflib_InOrder inOrder1 = new fflib_InOrder(aef_MockUtility.Mocks, new List<Object>{ mockDatabase });

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Lead.SObjectType,
			Account.SObjectType,
			Contact.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDeleted(accountRecord);
		uow.registerDeleted(contacts);
		uow.registerDeleted(new List<Lead>{leadRecord}, true, '');

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlDelete(new List<Account>{accountRecord}, false);
		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlDelete(contacts, false);

		// make sure the dmlDelete was executed in the specific order that they were added in
		((aef_ApplicationDatabase)inOrder1.verify(mockDatabase, aef_MockUtility.Mocks.calls(1))).dmlDelete(contacts, false);
		((aef_ApplicationDatabase)inOrder1.verify(mockDatabase, aef_MockUtility.Mocks.calls(1))).dmlDelete(new List<SObject>{accountRecord}, false);

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Make sure an exception is thrown if an SObject is added to a UOW that does not support it
	 */
	@IsTest
	private static void testSObjectInvalidForUnitOfWork() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Contact.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerNew(accountRecord);

			// make sure committing the work is done in the correct order
			uow.commitWork();

			System.assert(false);
		} catch(Exception e) {
			// Make sure that an exception is thrown when the sobject type is not registered in the uow
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * End-to-end integration flow
	 */
	@IsTest
	private static void testEnsureRecordsAreInsertedAndUpdatedIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_MockUtility.disableTriggerExecution();

		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert accountRecord;

		Campaign campaignRecord = aef_ApplicationTestDataFactory.getCampaigns(1, false)[0];
		Opportunity opportunityRecord = aef_ApplicationTestDataFactory.getOpportunities(1, accountRecord.Id, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Campaign.SObjectType,
			Account.SObjectType,
			Opportunity.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDirty(accountRecord);
		uow.registerNew(campaignRecord);
		uow.registerNew(opportunityRecord);

		uow.registerRelationship(opportunityRecord, Opportunity.CampaignId, campaignRecord);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		System.assertNotEquals(null, opportunityRecord.Id, 'Expected a record to be created');
		System.assertNotEquals(null, campaignRecord.Id, 'Expected a record to be created');
		System.assertEquals(campaignRecord.Id, opportunityRecord.CampaignId, 'Expected campaign id to be assigned');
	}

	/**
	 * Scenario:
	 * Make sure that a record is created in aef_Log__c when an DML error occurs and the UOW is not configured to throw an exception for that record
	 */
	@IsTest
	private static void testEnsureErrorsAreCorrectlyLoggedIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		aef_MockUtility.disableTriggerExecution();

		// do not parent it to account (we only create an account because of a data error in billing account trigger that hasn't been fixed)
		Opportunity opportunityRecord = aef_ApplicationTestDataFactory.getOpportunities(1, '001000000000000', false)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Opportunity.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		// should throw an exception since it's in a master-detail with Account and the Organisation__c field is not set
		uow.registerNew(opportunityRecord, false, 'aef_ApplicationUnitOfWork_Test.testEnsureErrorsAreCorrectlyLoggedIntegration');

		uow.commitWork();

		Test.stopTest();

		System.assertEquals(0, [Select Count() From Opportunity]);

		aef_Log__c log = [Select Id From aef_Log__c];
		System.assertNotEquals(null, log.Id);

	}

	/**
	 * Scenario:
	 * Make sure an insert operation occurs (additional insert) after the record insert is attempted.
	 * The second insert operation would be aef_Log__c.
	 * The mock AnswerGenericDMLFailed forces an error to be returned so the error can be simulated
	 */
	@IsTest
	private static void testEnsureErrorsAreLoggedOnInsertFailureWhenNoExceptionIsGenerated() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_ApplicationLogger mockLogger = (aef_ApplicationLogger)aef_MockUtility.mockUtility(aef_ApplicationLogger.class);

		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accountRecord, false, 'RandomClass.RandomMethod');

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, 1)).dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((aef_ApplicationLogger)aef_MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (aef_ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Make sure an exception is thrown after the record insert is attempted where the UOW is configured to throw an exception for that specific record
	 * The mock AnswerGenericDMLFailed simulates an error
	 */
	@IsTest
	private static void testEnsureExceptionIsThrownOnInsertFailure() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accountRecord, true, 'RandomClass.RandomMethod');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * Make sure an insert operation occurs after the record update is attempted.
	 * The insert operation to listen for would be aef_Log__c.
	 * The mock AnswerGenericDMLFailed forces an error to be returned so the error can be simulated
	 */
	@IsTest
	private static void testEnsureErrorsAreLoggedOnUpdateFailureWhenNoExceptionIsGenerated() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationLogger mockLogger = (aef_ApplicationLogger)aef_MockUtility.mockUtility(aef_ApplicationLogger.class);
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDirty(accountRecord, false, 'RandomClass.RandomMethod');

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((aef_ApplicationLogger)aef_MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (aef_ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Make sure an exception is thrown after the record update is attempted where the UOW is configured to throw an exception for that specific record
	 * The mock AnswerGenericDMLFailed simulates an error
	 */
	@IsTest
	private static void testEnsureExceptionIsThrownOnUpdateFailure() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDirty(accountRecord, true, 'RandomClass.RandomMethod');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * Make sure an insert operation occurs after the record dekete is attempted.
	 * The insert operation to listen for would be aef_Log__c.
	 * The mock AnswerGenericDMLDeleteFailed forces an error to be returned so the error can be simulated
	 */
	@IsTest
	private static void testEnsureErrorsAreLoggedOnDeleteFailureWhenNoExceptionIsGenerated() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationLogger mockLogger = (aef_ApplicationLogger)aef_MockUtility.mockUtility(aef_ApplicationLogger.class);
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLDeleteFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDeleted(accountRecord, false, 'RandomClass.RandomMethod');

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((aef_ApplicationDatabase)aef_MockUtility.Mocks.verify(mockDatabase, aef_MockUtility.Mocks.times(1))).dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((aef_ApplicationLogger)aef_MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (aef_ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Make sure an exception is thrown after the record delete is attempted where the UOW is configured to throw an exception for that specific record
	 * The mock AnswerGenericDMLDeleteFailed simulates an error
	 */
	@IsTest
	private static void testEnsureExceptionIsThrownOnDeleteFailure() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLDeleteFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDeleted(accountRecord, true, 'RandomClass.RandomMethod');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This tests an insert operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideGeneratesExceptionOnInsert() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLFailedLockError());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerNew(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This tests an update operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideGeneratesExceptionOnUpdate() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLFailedLockError());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerDirty(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * This ensures when an error occurs that is not an UNABLE_TO_LOCK_ROW error, no exception is thrown
	 * This tests an update operation and ensures no exception is thrown since the returned exception is not a 'lock' exception
	 */
	@IsTest
	private static void ensureLockFailureOverrideDoesNotGenerateExceptionOnUpdate() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		//NOTE: This test is not throwing a lock error
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerDirty(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// make sure no exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// an exception was thrown but not expected
			System.assert(false, 'Did not expect an exception to be thrown');
		}
	}

	/**
	 * Scenario:
	 * This ensures when an error occurs that is not an UNABLE_TO_LOCK_ROW error, no exception is thrown
	 * This tests an insert operation and ensures no exception is thrown since the returned exception is not a 'lock' exception
	 */
	@IsTest
	private static void ensureLockFailureOverrideDoesNotGenerateExceptionOnInsert() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		//NOTE: This test is not throwing a lock error
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerNew(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// make sure no exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// an exception was thrown but not expected
			System.assert(false, 'Did not expect an exception to be thrown');
		}
	}

	/**
	 * Scenario:
	 * This ensures when an error occurs that is not an UNABLE_TO_LOCK_ROW error, no exception is thrown
	 * This tests a delete operation and ensures no exception is thrown since the returned exception is not a 'lock' exception
	 */
	@IsTest
	private static void ensureLockFailureOverrideDoesNotGenerateExceptionOnDelete() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLDeleteFailed());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		//NOTE: This test is not throwing a lock error
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerDeleted(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// make sure no exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// an exception was thrown but not expected
			System.assert(false, 'Did not expect an exception to be thrown');
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This tests a delete operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideGeneratesExceptionOnDelete() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		aef_ApplicationDatabase mockDatabase = aef_MockUtility.mockDatabase();
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new aef_MockUtility.AnswerGenericDMLDeleteFailedLockError());
		aef_MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerDeleted(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * Make sure a new record can not be updated with unit of work
	 */
	@IsTest
	private static void ensureNewRecordsCanNotBeRegisteredDirty() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerDirty(accountRecord, false, 'My Error');

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(aef_ApplicationUnitOfWorkBase.UnitOfWorkException ex) {
			// make sure the exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// not sure what this exception is?
			System.assert(false, 'Incorrect exception type');
		}
	}

	/**
	 * Scenario:
	 * Make sure an existing record can not be inserted with unit of work
	 */
	@IsTest
	private static void ensureExistingRecordsCanNotBeRegisteredNew() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerNew(accountRecord, false, 'My Error');

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(aef_ApplicationUnitOfWorkBase.UnitOfWorkException ex) {
			// make sure the exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// not sure what this exception is?
			System.assert(false, 'Incorrect exception type');
		}
	}

	/**
	 * Scenario:
	 * Make sure an new record can not be deleted with unit of work
	 */
	@IsTest
	private static void ensureNewRecordsCanNotBeRegisterDeleted() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = aef_ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerDeleted(accountRecord, false, 'My Error');

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(aef_ApplicationUnitOfWorkBase.UnitOfWorkException ex) {
			// make sure the exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// not sure what this exception is?
			System.assert(false, 'Incorrect exception type');
		}
	}
}