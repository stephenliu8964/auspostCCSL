/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @author Nathan Franklin
 * @description Test Class covering aef_Application
 * @changelog
 */
@IsTest
private with sharing class aef_Application_Test {

	/**
	 * Tests each of the factories to ensure the correct objects are returned when needed
	 */
	@IsTest
	private static void testFactories() {
		MyClassMock aef_MockUtility = new MyClassMock();
		MySelectorMock mockSelector = new MySelectorMock();
		aef_ApplicationTestDomain1_Test mockDomain = new aef_ApplicationTestDomain1_Test();

		Object output = aef_Application.Utilities.getInstance(MyClass.class);
		System.assert(output instanceof MyClass, 'getInstance expected an instance of MyClass');

		output = aef_Application.Utilities.newInstance(MyClass.class);
		System.assert(output instanceof MyClass, 'getInstance expected an instance of MyClass');

		aef_Application.Utilities.setMock(MyClass.class, aef_MockUtility);
		output = aef_Application.Utilities.getInstance(MyClass.class);
		System.assert(output == aef_MockUtility, 'getInstance expected an instance of MyClassMock');

		output = aef_Application.Utilities.newInstance(MyClass.class);
		System.assert(output == aef_MockUtility, 'getInstance expected an instance of MyClassMock');

		output = aef_Application.Selectors.newInstance(MySelector.class);
		System.assert(output instanceof MySelector, 'getInstance expected an instance of MySelector');

		aef_Application.Selectors.setMock(MySelector.class, mockSelector);
		output = aef_Application.Selectors.newInstance(MySelector.class);
		System.assert(output == mockSelector, 'getInstance expected an instance of MySelectorMock');

		aef_Application.Domains.setMock(aef_ApplicationTestDomain1_Test.class, mockDomain);
		output = aef_Application.Domains.newInstance(aef_ApplicationTestDomain1_Test.class, new List<SObject>{});
		System.assert(output == mockDomain, 'newInstance expected an instance of aef_ApplicationTestDomain1_Test');

		// test profiler
		aef_Application.Profiler.start('test');
		aef_Application.Profiler.stop('test');

		aef_Application.GenericFactory factory = new aef_Application.GenericFactory();
		factory.put(MyClassMock.class, aef_MockUtility);
		System.assert(factory.get(MyClassMock.class) == aef_MockUtility, 'getInstance expected an instance of MySelectorMock');

	}

	private class MyClassMock { }
	private class MyClass { }

	public class MySelector extends aef_ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Contact.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {Contact.Id, Contact.AccountId, Contact.FirstName, Contact.LastName, Account.OwnerId};
		}

	}

	public class MySelectorMock extends aef_ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Contact.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {Contact.Id, Contact.AccountId, Contact.FirstName, Contact.LastName, Account.OwnerId};
		}

	}

}