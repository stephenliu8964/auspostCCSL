public with sharing class aef_Scenario7RetryLockSuccess {

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
					new Account(Name = 'Test Account 1', AccountNumber = '00000001')
			};
			aef_ApplicationDatabase.getInstance().dmlInsert(accounts);

			List<Contact> contacts = new List<Contact>{
					new Contact(FirstName = 'Test First Name 1', LastName = 'Test Last Name 1', Phone = '0400000000', AccountId = accounts[0].Id)
			};
			aef_ApplicationDatabase.getInstance().dmlInsert(contacts);

			for(Contact contactRecord : contacts) {
				String numberValue = (contactRecord.Phone == null ? '1' : String.valueOf(Integer.valueOf(contactRecord.Phone) + 1));
				updateableContacts.add(new Contact(Id = contactRecord.Id, Phone = numberValue));

				accountIds.add(contactRecord.AccountId);
			}
			uow.registerDirty(updateableContacts, new Set<SObjectField>{Contact.Phone}, 'AsyncWorkerRandomContactUpdate');

			// Lock scenario
			Map<String, Object> params = new Map<String, Object>{'accountIds' => accountIds};

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
			return null; // FORCE ASYNC container
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

			aef_ApplicationDatabase.getInstance().dmlUpdate(updateableAccounts);

			for(Integer i=0;i<2000000;i++) {
				System.debug('Do nothing');
			}
		}

		public override aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return aef_ApplicationUnitOfWork.ASYNC_MAX_DEPTH_ENQUEUE_ACTION.DISCARD_AND_LOG;
		}

	}

}