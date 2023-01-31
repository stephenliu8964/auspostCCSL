@IsTest
public class aef_AccountRegistrationService_Test {
    public static final String MOCK_KEY = 'somethingsecrecty123';
    public static final String MOCK_ERROR = 'something went wrong';

    @IsTest
    private static void testFilterAccountsWithName() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
        Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);

        aef_AccountsSelector mockSelector = (aef_AccountsSelector)aef_MockUtility.mockSelector(aef_AccountsSelector.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();
        aef_MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.eq(accountsMap.keySet()))).thenReturn(accounts);
        aef_MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        aef_AccountRegistrationService service = aef_AccountRegistrationService.getInstance();
        List<Id> output = new List<Id>(service.filterAccountsWithName(accountsMap.keySet()));
        List<Account> outputAccounts = new List<Account>(service.filterAccountsWithName(accounts));

        Test.stopTest();

        // verify selectById was called
        ((aef_AccountsSelector)aef_MockUtility.Mocks.verify(mockSelector, aef_MockUtility.Mocks.times(1))).selectById(accountsMap.keySet());

        System.assertEquals(2, output.size());
        System.assertEquals(accounts[0].Id, output[0]);
        System.assertEquals(accounts[1].Id, output[1]);

        System.assertEquals(2, outputAccounts.size());
        System.assertEquals(accounts[0].Id, outputAccounts[0].Id);
        System.assertEquals(accounts[1].Id, outputAccounts[1].Id);
    }

    @IsTest
    private static void testGetAccountRegistrationKey_success() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
        Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);

        aef_AccountsSelector mockSelector = (aef_AccountsSelector)aef_MockUtility.mockSelector(aef_AccountsSelector.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();
        aef_MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.eq(accountsMap.keySet()))).thenReturn(accounts);
        aef_MockUtility.Mocks.stopStubbing();
        Test.setMock(HttpCalloutMock.class, new AccountRegistrationCalloutMock(200, '{"success":true,"secretKey":"' + MOCK_KEY + '"}'));

        Test.startTest();

        aef_AccountRegistrationService service = aef_AccountRegistrationService.getInstance();
        List<Account> resultAccounts = new List<Account>(service.getAccountRegistrationKey(accounts));

        Test.stopTest();

        System.assertEquals(MOCK_KEY, resultAccounts[1].Registration_Key__c);
        System.assertEquals(MOCK_KEY, resultAccounts[1].Registration_Key__c);
    }

    @IsTest
    private static void testGetAccountRegistrationKey_fail() {
        List<Account> accounts = aef_ApplicationTestDataFactory.getAccounts(2, true);
        Map<Id, Account> accountsMap = new Map<Id, Account>(accounts);

        aef_AccountsSelector mockSelector = (aef_AccountsSelector)aef_MockUtility.mockSelector(aef_AccountsSelector.class);

        // set up our responses
        aef_MockUtility.Mocks.startStubbing();
        aef_MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.eq(accountsMap.keySet()))).thenReturn(accounts);
        aef_MockUtility.Mocks.stopStubbing();
        Test.setMock(HttpCalloutMock.class, new AccountRegistrationCalloutMock(500, '{"success":false,"error":"' + MOCK_ERROR + '"}'));

        Test.startTest();

        aef_AccountRegistrationService service = aef_AccountRegistrationService.getInstance();
        List<Account> resultAccounts = new List<Account>(service.getAccountRegistrationKey(accounts));

        Test.stopTest();

        System.assertEquals(MOCK_ERROR, resultAccounts[1].Registration_Key__c);
        System.assertEquals(MOCK_ERROR, resultAccounts[1].Registration_Key__c);
    }

    public class AccountRegistrationCalloutMock implements HttpCalloutMock{
        public Integer responseCode {get; set;}
        public String responseBody {get; set;}

        public AccountRegistrationCalloutMock(Integer responseCode, String responseBody) {
            this.responseCode = responseCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setBody(responseBody);
            res.setStatusCode(responseCode);
            return res;
        }
    }
}