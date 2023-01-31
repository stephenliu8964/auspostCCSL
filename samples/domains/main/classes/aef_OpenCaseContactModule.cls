public inherited sharing class aef_OpenCaseContactModule extends aef_ApplicationDomain.Module{
    public aef_OpenCaseContactModule() {
        getTriggerEvents().enableAfterInsert().enableAfterUpdate();
    }
    public override void onAfterInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {
        updateContactCaseNumbers((List<Case>)records, null, uow);
    }


    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
        updateContactCaseNumbers((List<Case>)records, (Map<Id, Case>)existingRecords, uow);
    }

    private void updateContactCaseNumbers(List<Case> records, Map<Id, Case> existingRecords, aef_ApplicationUnitOfWork uow) {
        Set<Id> toProcessContactIds = new Set<Id>();
        for (Case record : records) {
            if (existingRecords == null || (record.Status != existingRecords.get(record.Id).Status)) { // only process when new case or case status changed
                toProcessContactIds.add(record.ContactId);
            }
        }

        if(!toProcessContactIds.isEmpty()) {
            Map<String, Object> params = new Map<String, Object>{'contactIds' => toProcessContactIds};
            uow.registerAsyncWork(new aef_ApplicationUnitOfWork.AsyncStagingWorker(AsyncUpdateContactCaseNumbers.class, params));
        }
    }

    public without sharing class AsyncUpdateContactCaseNumbers extends aef_ApplicationUnitOfWork.AsyncWorker {
        Set<Id> contactIds;

        public override Type getClassType() {
            return AsyncUpdateContactCaseNumbers.class;
        }

        public override SObjectType getSObjectTypeGroup() {
            return Contact.SObjectType;
        }

        /**
         * Override the default deserialisation which simply executes deserialiseUntyped
         */
        public override void deserialiseParams(String serialisedParams) {
            ContactParams params = (ContactParams)JSON.deserialize(serialisedParams, ContactParams.class);
            this.contactIds = params.contactIds;
        }

        public override void execute(aef_ApplicationUnitOfWork uow) {
            Map<String, Object> openCaseSearchParams = new Map<String, Object>{
                    'contactIds' => contactIds
            };
            List<Case> toProcessCases = aef_CasesSelector.newInstance().search(openCaseSearchParams, new Set<Object>(), true);

            Map<Id, List<Case>> contactIdsWithOpenCases = new Map<Id, List<Case>>();
            Map<Id, List<Case>> contactIdsWithClosedCases = new Map<Id, List<Case>>();
            for(Case record : toProcessCases) {
                if (!record.IsClosed) {
                    if (contactIdsWithOpenCases.get(record.contactId) == null) {
                        contactIdsWithOpenCases.put(record.contactId, new List<Case>{record});
                    } else {
                        contactIdsWithOpenCases.get(record.contactId).add(record);
                    }
                    if (contactIdsWithClosedCases.isEmpty()) {
                        contactIdsWithClosedCases.put(record.contactId, new List<Case>());
                    }
                } else {
                    if (contactIdsWithClosedCases.get(record.contactId) == null) {
                        contactIdsWithClosedCases.put(record.contactId, new List<Case>{record});
                    } else {
                        contactIdsWithClosedCases.get(record.contactId).add(record);
                    }
                    if (contactIdsWithOpenCases.isEmpty()) {
                        contactIdsWithOpenCases.put(record.contactId, new List<Case>());
                    }
                }
            }

            List<Contact> contactWithOpenCase = aef_OpenCaseService.getInstance().populateContactNumberOfOpenCases(contactIdsWithOpenCases);
            for(Contact record : contactWithOpenCase) {
                uow.registerDirty(record, new Set<SObjectField>{Contact.Number_of_Open_Cases__c}, false, 'aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers');
            }

            List<Contact> contactWithClosedCase = aef_OpenCaseService.getInstance().populateContactNumberOfClosedCases(contactIdsWithClosedCases);
            for(Contact record : contactWithClosedCase) {
                uow.registerDirty(record, new Set<SObjectField>{Contact.Number_of_Closed_Cases__c}, false, 'aef_OpenCaseContactModule.AsyncUpdateContactCaseNumbers');
            }
        }
    }

    public class ContactParams {
        public Set<Id> contactIds;
    }

    public static aef_OpenCaseContactModule newInstance() {
        return (aef_OpenCaseContactModule)aef_Application.Utilities.newInstance(aef_OpenCaseContactModule.class);
    }
}