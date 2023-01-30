public with sharing class aef_Scenario3ChainedMaxStackSync {

	public static void clearData() {
		List<Account> accounts = [SELECT Id FROM Account WHERE Name LIKE 'Test Account%'];
		aef_ApplicationDatabase.getInstance().dmlDelete(accounts);

		List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Test Last Name%'];
		aef_ApplicationDatabase.getInstance().dmlDelete(contacts);

		List<Case> cases = [SELECT Id FROM Case WHERE Subject LIKE 'Test Case Creation%'];
		aef_ApplicationDatabase.getInstance().dmlDelete(cases);
	}

	public static void play() {

		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(new List<SObjectType>{
				Account.SObjectType, Contact.SObjectType, Case.SObjectType, CaseComment.SObjectType
		});

		uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedRandomContactUpdate.class));

		// normally this would be handled automatically with the trigger framework
		uow.commitWork();

	}

	public class AsyncWorkerChainedRandomContactUpdate extends aef_ApplicationUnitOfWork.AsyncWorker {

		public override Type getClassType() {
			return AsyncWorkerChainedRandomContactUpdate.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Contact.SObjectType;
		}

		public override void execute(aef_ApplicationUnitOfWork uow) {
			List<Contact> updateableContacts = new List<Contact>();
			Set<Id> accountIds = new Set<Id>();

			List<Account> accounts = new List<Account>{
					new Account(Name = 'Test Account 1', AccountNumber = '00000001'),
					new Account(Name = 'Test Account 2', AccountNumber = '00000002')
			};
			aef_ApplicationDatabase.getInstance().dmlInsert(accounts);

			List<Contact> contacts = new List<Contact>{
					new Contact(FirstName = 'Test First Name 1', LastName = 'Test Last Name 1', Phone = '0400000000', AccountId = accounts[0].Id),
					new Contact(FirstName = 'Test First Name 2', LastName = 'Test Last Name 2', Phone = '0400000001', AccountId = accounts[0].Id),
					new Contact(FirstName = 'Test First Name 3', LastName = 'Test Last Name 3', Phone = '0400000002', AccountId = accounts[1].Id),
					new Contact(FirstName = 'Test First Name 4', LastName = 'Test Last Name 4', Phone = '0400000003', AccountId = accounts[1].Id)
			};
			aef_ApplicationDatabase.getInstance().dmlInsert(contacts);

			for(Contact contactRecord : contacts) {
				String numberValue = (contactRecord.Phone == null ? '1' : String.valueOf(Integer.valueOf(contactRecord.Phone) + 1));
				updateableContacts.add(new Contact(Id = contactRecord.Id, Phone = numberValue));

				accountIds.add(contactRecord.AccountId);
			}
			uow.registerDirty(updateableContacts, new Set<SObjectField>{Contact.Phone}, 'AsyncWorkerRandomContactUpdate');

			Map<String, Object> params = new Map<String, Object>{'accountIds' => accountIds};
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedAccountUpdate.class, params));
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedAccountUpdate.class, params));
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedAccountUpdate.class, params));
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedAccountUpdate.class, params));

		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.DISCARD_AND_LOG;
		}

	}

	public class AsyncWorkerChainedAccountUpdate extends aef_ApplicationUnitOfWork.AsyncWorker {

		Set<Id> accountIds = new Set<Id>();

		public override Type getClassType() {
			return AsyncWorkerChainedAccountUpdate.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Account.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if(!String.isEmpty(serialisedParams)) {
				Map<String, Set<Id>> params = (Map<String, Set<Id>>)JSON.deserialize(serialisedParams, Map<String, Set<Id>>.class);
				accountIds = params.get('accountIds');
			}
		}

		public override void execute(aef_ApplicationUnitOfWork uow) {

			List<Account> updateableAccounts = new List<Account>();

			List<Account> accounts = [SELECT Id, Name, NumberOfEmployees FROM Account WHERE Id IN :accountIds];
			for(Account accountRecord : accounts) {
				Decimal numberValue = (accountRecord.NumberOfEmployees == null ? 1 : accountRecord.NumberOfEmployees + 1);
				updateableAccounts.add(new Account(Id = accountRecord.Id, NumberOfEmployees = Integer.valueOf(numberValue)));
			}
			uow.registerDirty(updateableAccounts, new Set<SObjectField>{Account.NumberOfEmployees}, 'AsyncWorkerChainedAccountUpdate');

			Map<String, Object> params = new Map<String, Object>{'accountIds' => accountIds};
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedAccountContactsUpdate.class, params));
		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.DISCARD_AND_LOG;
		}

	}

	public class AsyncWorkerChainedAccountContactsUpdate extends aef_ApplicationUnitOfWork.AsyncWorker {

		Set<Id> accountIds = new Set<Id>();

		public override Type getClassType() {
			return AsyncWorkerChainedAccountContactsUpdate.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Contact.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if(!String.isEmpty(serialisedParams)) {
				Map<String, Set<Id>> params = (Map<String, Set<Id>>)JSON.deserialize(serialisedParams, Map<String, Set<Id>>.class);
				accountIds = params.get('accountIds');
			}
		}

		public override void execute(aef_ApplicationUnitOfWork uow) {

			Set<Id> contactIds = new Set<Id>();
			List<Contact> updateableContacts = new List<Contact>();
			List<Contact> contacts = [SELECT Id, AccountId, Birthdate FROM Contact WHERE AccountId IN :accountIds];
			for(Contact contactRecord : contacts) {
				Date value = (contactRecord.Birthdate == null ? System.today() : contactRecord.Birthdate.addDays(1));
				updateableContacts.add(new Contact(Id = contactRecord.Id, Birthdate = value));
				contactIds.add(contactRecord.Id);
			}
			uow.registerDirty(updateableContacts, new Set<SObjectField>{Contact.Birthdate}, 'AsyncWorkerRandomContactUpdate');

			Map<String, Object> params = new Map<String, Object>{'contactIds' => contactIds};
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedCaseCreation.class, params));

		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.DISCARD_AND_LOG;
		}

	}

	public class AsyncWorkerChainedCaseCreation extends aef_ApplicationUnitOfWork.AsyncWorker {

		Set<Id> contactIds = new Set<Id>();

		public override Type getClassType() {
			return AsyncWorkerChainedCaseCreation.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Case.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if(!String.isEmpty(serialisedParams)) {
				Map<String, Set<Id>> params = (Map<String, Set<Id>>)JSON.deserialize(serialisedParams, Map<String, Set<Id>>.class);
				contactIds = params.get('contactIds');
			}
		}

		public override void execute(aef_ApplicationUnitOfWork uow) {

			List<Case> createableCases = new List<Case>();
			List<Contact> contacts = [SELECT Id, AccountId, Birthdate FROM Contact WHERE Id IN :contactIds];
			for(Contact contactRecord : contacts) {
				Case cc = new Case(Subject = 'Test Case Creation', ContactId = contactRecord.Id);
				createableCases.add(cc);
			}

			// can't use uow here because we need the ids
			aef_ApplicationDatabase.getInstance().dmlInsert(createableCases);

			Set<Id> caseIds = new Map<Id, Case>(createableCases).keySet();
			Map<String, Object> params = new Map<String, Object>{'caseIds' => caseIds};
			uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedCaseCommentCreation.class, params));

		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.DISCARD_AND_LOG;
		}

	}

	public class AsyncWorkerChainedCaseCommentCreation extends aef_ApplicationUnitOfWork.AsyncWorker {

		Set<Id> caseIds = new Set<Id>();

		public override Type getClassType() {
			return AsyncWorkerChainedCaseCommentCreation.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return CaseComment.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if(!String.isEmpty(serialisedParams)) {
				Map<String, Set<Id>> params = (Map<String, Set<Id>>)JSON.deserialize(serialisedParams, Map<String, Set<Id>>.class);
				caseIds = params.get('caseIds');
			}
		}

		public override void execute(aef_ApplicationUnitOfWork uow) {

			List<CaseComment> createableCaseComments = new List<CaseComment>();

			for(Id caseId : caseIds) {
				CaseComment cc = new CaseComment(ParentId = caseId, IsPublished = true, CommentBody = 'My Case Comment');
				createableCaseComments.add(cc);
			}

			uow.registerNew(createableCaseComments);

		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.PROCESS_SYNC;
		}

	}

}