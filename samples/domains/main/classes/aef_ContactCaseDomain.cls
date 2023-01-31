public inherited sharing class aef_ContactCaseDomain extends aef_ApplicationDomain{
    public static aef_ContactCaseDomain newInstance(List<SObject> sObjectList) {
        return (aef_ContactCaseDomain)aef_ApplicationDomain.newInstance(aef_ContactCaseDomain.class, sObjectList);
    }

    /**
     * These are the modules that the domain will use for triggers or method execution
     */
    public override void registerModules() {
        registerModule(aef_OpenCaseContactModule.class);
    }

    /**
     * Prefilter the records passed in to ensure this domain class only processes applicable records.
     */
    public override List<SObject> filter(List<SObject> records) {
        return aef_OpenCaseService.getInstance().filterCasesWithContactId(records);
    }

}