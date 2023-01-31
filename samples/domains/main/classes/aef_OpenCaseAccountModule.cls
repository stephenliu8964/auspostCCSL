public inherited sharing class aef_OpenCaseAccountModule extends aef_ApplicationDomain.Module{
    public aef_OpenCaseAccountModule() {
        getTriggerEvents().enableAfterInsert().enableAfterUpdate();
    }
    public override void onAfterInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {
        updateAccountCaseNumbers((List<Case>)records, null, uow);
    }


    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
        updateAccountCaseNumbers((List<Case>)records, (Map<Id, Case>)existingRecords, uow);
    }

    private void updateAccountCaseNumbers(List<Case> records, Map<Id, Case> existingRecords, aef_ApplicationUnitOfWork uow) {
        Set<Id> toProcessAccountIds = new Set<Id>();
        for (Case record : records) {
            if (existingRecords == null || (record.Status != existingRecords.get(record.Id).Status)) { // only process when new case or case status changed
                toProcessAccountIds.add(record.AccountId);
            }
        }

        if(!toProcessAccountIds.isEmpty()) {
            Map<String, Object> params = new Map<String, Object>{'accountIds' => toProcessAccountIds};
            uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncUpdateAccountCaseNumbers.class, params));
        }
    }

    public without sharing class AsyncUpdateAccountCaseNumbers extends aef_ApplicationUnitOfWork.AsyncWorker {
        Set<Id> accountIds;

        public override Type getClassType() {
            return AsyncUpdateAccountCaseNumbers.class;
        }

        public override SObjectType getSObjectTypeGroup() {
            return Account.SObjectType;
        }

        /**
         * Override the default deserialisation which simply executes deserialiseUntyped
         */
        public override void deserialiseParams(String serialisedParams) {
            AccountParams params = (AccountParams)JSON.deserialize(serialisedParams, AccountParams.class);
            this.accountIds = params.accountIds;
        }

        public override void execute(aef_ApplicationUnitOfWork uow) {
            Map<String, Object> openCaseSearchParams = new Map<String, Object>{
                    'accountIds' => accountIds
            };
            List<Case> toProcessCases = aef_CasesSelector.newInstance().search(openCaseSearchParams, new Set<Object>(), true);

            Map<Id, List<Case>> accountIdsWithOpenCases = new Map<Id, List<Case>>();
            Map<Id, List<Case>> accountIdsWithClosedCases = new Map<Id, List<Case>>();
            for(Case record : toProcessCases) {
                if (!record.IsClosed) {
                    if (accountIdsWithOpenCases.get(record.AccountId) == null) {
                        accountIdsWithOpenCases.put(record.AccountId, new List<Case>{record});
                    } else {
                        accountIdsWithOpenCases.get(record.AccountId).add(record);
                    }
                    if (accountIdsWithClosedCases.isEmpty()) {
                        accountIdsWithClosedCases.put(record.AccountId, new List<Case>());
                    }
                } else {
                    if (accountIdsWithClosedCases.get(record.AccountId) == null) {
                        accountIdsWithClosedCases.put(record.AccountId, new List<Case>{record});
                    } else {
                        accountIdsWithClosedCases.get(record.AccountId).add(record);
                    }
                    if (accountIdsWithOpenCases.isEmpty()) {
                        accountIdsWithOpenCases.put(record.AccountId, new List<Case>());
                    }
                }
            }

            List<Account> accountWithOpenCase = aef_OpenCaseService.getInstance().populateAccountNumberOfOpenCases(accountIdsWithOpenCases);
            for(Account record : accountWithOpenCase) {
                uow.registerDirty(record, new Set<SObjectField>{Account.Number_of_Open_Cases__c}, false, 'aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers');
            }

            List<Account> accountWithClosedCase = aef_OpenCaseService.getInstance().populateAccountNumberOfClosedCases(accountIdsWithClosedCases);
            for(Account record : accountWithClosedCase) {
                uow.registerDirty(record, new Set<SObjectField>{Account.Number_of_Closed_Cases__c}, false, 'aef_OpenCaseAccountModule.AsyncUpdateAccountCaseNumbers');
            }
        }
    }

    public class AccountParams {
        public Set<Id> accountIds;
    }


    public static aef_OpenCaseAccountModule newInstance() {
        return (aef_OpenCaseAccountModule)aef_Application.Utilities.newInstance(aef_OpenCaseAccountModule.class);
    }
}