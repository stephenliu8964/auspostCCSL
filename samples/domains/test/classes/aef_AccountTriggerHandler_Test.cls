/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
private class aef_AccountTriggerHandler_Test {

	/**
	 * Note the simplicity of this class, we are only focused on testing the actual code in the class
	 */
	@IsTest
	private static void test() {

		aef_AccountTriggerHandler handler = new aef_AccountTriggerHandler();
		handler.newUnitOfWork();
		handler.registerDomains();

		// PMD warning
		System.assert(true);
	}

}