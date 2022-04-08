/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * This is an aef_ApplicationDomain for use in aef_ApplicationDomain_Test
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
public class aef_ApplicationTestDomain2_Test extends aef_ApplicationDomain implements IHasClassType {

	// used to report back from the module which records where changed
	public static Map<Id, Set<SObjectField>> moduleBeforeUpdateChangedValues;
	public static Map<Id, Set<SObjectField>> moduleAfterUpdateChangedValues;

	public static Integer moduleOnBeforeInsertCalled = 0;
	public static Integer moduleOnAfterInsertCalled = 0;
	public static Integer moduleOnBeforeUpdateCalled = 0;
	public static Integer moduleOnAfterUpdateCalled = 0;
	public static Integer moduleOnBeforeDeleteCalled = 0;
	public static Integer moduleOnAfterDeleteCalled = 0;

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		registerModule(aef_ApplicationTestDomModAllAfter_Test.class);
		registerModule(aef_ApplicationTestDomModAllBeforeTest.class);
	}

	public Type getClassType() {
		return aef_ApplicationTestDomain2_Test.class;
	}

	public override List<SObject> filter(List<SObject> records) {
		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			if(record.get('Name') == 'Test Name 1') {
				output.add(record);
			}
		}
		return output;
	}
}