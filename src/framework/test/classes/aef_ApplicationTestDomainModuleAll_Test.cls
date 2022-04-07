/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * This is an aef_ApplicationDomain.Module for use in aef_ApplicationDomain_Test and aef_ApplicationDomainTriggerHandler_Test
 * This needed its own root class since it requires an inner type IConstructableModule
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
public class aef_ApplicationTestDomainModuleAll_Test extends aef_ApplicationDomain.Module {

	public aef_ApplicationTestDomainModuleAll_Test() {
		getTriggerEvents().enableAll();
	}
	public override void onBeforeInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain1_Test.moduleOnBeforeInsertCalled++;
	}

	public override void onAfterInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain1_Test.moduleOnAfterInsertCalled++;
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain1_Test.moduleOnBeforeUpdateCalled++;
		aef_ApplicationTestDomain1_Test.moduleBeforeUpdateChangedValues = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.NumberOfEmployees});
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain1_Test.moduleOnAfterUpdateCalled++;
		aef_ApplicationTestDomain1_Test.moduleAfterUpdateChangedValues = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.NumberOfEmployees});
	}

	public override void onBeforeDelete(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain1_Test.moduleOnBeforeDeleteCalled++;
	}

	public override void onAfterDelete(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain1_Test.moduleOnAfterDeleteCalled++;
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements aef_ApplicationDomain.IConstructableModule {
		public aef_ApplicationDomain.Module construct() {
			return new aef_ApplicationTestDomainModuleAll_Test();
		}
	}
}