public inherited sharing class aef_AccountRegistrationDomain extends aef_ApplicationDomain{
    public static aef_AccountRegistrationDomain newInstance(List<SObject> sObjectList) {
        return (aef_AccountRegistrationDomain)aef_ApplicationDomain.newInstance(aef_AccountRegistrationDomain.class, sObjectList);
    }

    /**
     * These are the modules that the domain will use for triggers or method execution
     */
    public override void registerModules() {

        // used to retro fit case priority when an account is reclassified as enterprise
        registerModule(aef_AccountRegistrationModule.class);

    }

    /**
     * Prefilter the records passed in to ensure this domain class only processes applicable records.
     */
    public override List<SObject> filter(List<SObject> records) {
        return aef_AccountRegistrationService.getInstance().filterAccountsWithName(records);
    }
}