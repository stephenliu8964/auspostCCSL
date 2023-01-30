public with sharing class aef_Scenario5WorkerGrouping {

	public static void play() {

		aef_ApplicationUnitOfWork uow = aef_ApplicationUnitOfWork.newInstance(new List<SObjectType>{
				Account.SObjectType, Contact.SObjectType
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

			for(Id accountId : accountIds) {
				Map<String, Object> params = new Map<String, Object>{'accountIds' => new Set<Id>{accountId}};
				uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedAccountUpdate.class, params));
				uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncWorkerChainedAccountUpdate2.class, params));
			}

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
		}

	}

	public class AsyncWorkerChainedAccountUpdate2 extends aef_ApplicationUnitOfWork.AsyncWorker {

		Set<Id> accountIds = new Set<Id>();

		public override Type getClassType() {
			return AsyncWorkerChainedAccountUpdate2.class;
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

			List<Account> accounts = [SELECT Id, Name, Phone FROM Account WHERE Id IN :accountIds];
			for(Account accountRecord : accounts) {
				String numberValue = (accountRecord.Phone == null ? '1' : String.valueOf(Integer.valueOf(accountRecord.Phone) + 1));
				updateableAccounts.add(new Account(Id = accountRecord.Id, Phone = numberValue));
			}
			uow.registerDirty(updateableAccounts, new Set<SObjectField>{Account.Phone}, 'AsyncWorkerChainedAccountUpdate2');
		}

	}

}