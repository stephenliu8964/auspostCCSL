@IsTest
private class aef_OpenCaseDomain_Test {
    @IsTest
    private static void testCasesWithAccountId() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);

        List<Case> cases = aef_ApplicationTestDataFactory.getCases(2, null, true);
        cases[0].AccountId = accounts[0].Id;

        aef_OpenCaseDomain domain = (aef_OpenCaseDomain)aef_ApplicationDomain.newInstance(aef_OpenCaseDomain.class, cases);

        System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
        System.assertEquals(cases[0].Id, domain.records[0].Id, 'Expected enterprise record');
    }
}