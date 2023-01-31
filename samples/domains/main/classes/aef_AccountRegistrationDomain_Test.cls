@IsTest
private class aef_AccountRegistrationDomain_Test {
    @IsTest
    private static void testFilterAccountsWithName() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);

        aef_AccountRegistrationDomain domain = (aef_AccountRegistrationDomain)aef_ApplicationDomain.newInstance(aef_AccountRegistrationDomain.class, accounts);

        System.assertEquals(2, domain.records.size(), 'Records should have been filtered in call to newInstance');
        System.assertEquals(accounts[0].Id, domain.records[0].Id, 'Expected enterprise record');
        System.assertEquals(accounts[1].Id, domain.records[1].Id, 'Expected enterprise record');
    }
}