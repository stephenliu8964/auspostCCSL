public inherited sharing class aef_AccountRegistrationModule extends aef_ApplicationDomain.Module{
    public aef_AccountRegistrationModule() {
        getTriggerEvents().enableAfterInsert();
    }

    public override void onAfterInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {
        registerAccounts((List<Account>)records, uow);
    }

    private void registerAccounts(List<Account> records, aef_ApplicationUnitOfWork uow) {
        Set<Id> accountIds = new Set<Id>();
        for (Account account : records) {
            accountIds.add(account.Id);
        }

        Map<String, Object> params = new Map<String, Object>{'accountIds' => accountIds};
        uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncRegisterAccountWithKey.class, params));
    }

    public without sharing class AsyncRegisterAccountWithKey extends aef_ApplicationUnitOfWork.AsyncWorker implements Database.AllowsCallouts{

        Set<Id> accountIds;

        public override Type getClassType() {
            return AsyncRegisterAccountWithKey.class;
        }

        public override SObjectType getSObjectTypeGroup() {
            return Account.SObjectType;
        }

        public override void deserialiseParams(String serialisedParams) {
            AccountParams params = (AccountParams)JSON.deserialize(serialisedParams, AccountParams.class);
            this.accountIds = params.accountIds;
        }

        public override void execute(aef_ApplicationUnitOfWork uow) {
            List<Account> accounts = ((aef_AccountsSelector)aef_AccountsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{Account.Name,Account.Registration_Key__c})).selectById(accountIds);
            List<Account> updatedAccounts = aef_AccountRegistrationService.getInstance().getAccountRegistrationKey(accounts);

            if(!updatedAccounts.isEmpty()) {
                for(Account record : updatedAccounts) {
                    uow.registerDirty(record, new Set<SObjectField>{Account.Registration_Key__c}, false, 'aef_AccountRegistrationModule.AsyncRegisterAccountWithKey');
                }
            }
        }
    }

    public class AccountParams {
        public Set<Id> accountIds;
    }

    public static aef_AccountRegistrationModule newInstance() {
        return (aef_AccountRegistrationModule)aef_Application.Utilities.newInstance(aef_AccountRegistrationModule.class);
    }
}