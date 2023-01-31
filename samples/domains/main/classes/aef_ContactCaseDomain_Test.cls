@IsTest
private class aef_ContactCaseDomain_Test {
    @IsTest
    private static void testCasesWithContactId() {
        List<Contact> contacts = aef_ApplicationTestDataFactory.getContacts(2, null, true);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].ContactId = contacts[0].Id;

        aef_ContactCaseDomain domain = (aef_ContactCaseDomain)aef_ApplicationDomain.newInstance(aef_ContactCaseDomain.class, cases);

        System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
        System.assertEquals(cases[0].Id, domain.records[0].Id, 'Expected enterprise record');
    }
}