public inherited sharing class aef_OpenCaseDomain extends aef_ApplicationDomain{
    public static aef_OpenCaseDomain newInstance(List<SObject> sObjectList) {
        return (aef_OpenCaseDomain)aef_ApplicationDomain.newInstance(aef_OpenCaseDomain.class, sObjectList);
    }

    /**
     * These are the modules that the domain will use for triggers or method execution
     */
    public override void registerModules() {
        registerModule(aef_OpenCaseAccountModule.class);
    }

    /**
     * Prefilter the records passed in to ensure this domain class only processes applicable records.
     */
    public override List<SObject> filter(List<SObject> records) {
        return aef_OpenCaseService.getInstance().filterCasesWithAccountId(records);
    }
}