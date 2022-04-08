/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * This is an aef_ApplicationDomain.Module for use in aef_ApplicationDomain_Test and aef_ApplicationDomainTriggerHandler_Test
 *
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
public class aef_ApplicationTestDomModAllAfter_Test extends aef_ApplicationDomain.Module {
	public aef_ApplicationTestDomModAllAfter_Test() {
		getTriggerEvents().enableAllAfter();
	}
	public override void onBeforeInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain2_Test.moduleOnBeforeInsertCalled++;
	}

	public override void onAfterInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain2_Test.moduleOnAfterInsertCalled++;
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain2_Test.moduleOnBeforeUpdateCalled++;
		aef_ApplicationTestDomain2_Test.moduleBeforeUpdateChangedValues = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.NumberOfEmployees});
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain2_Test.moduleOnAfterUpdateCalled++;
		aef_ApplicationTestDomain2_Test.moduleAfterUpdateChangedValues = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.NumberOfEmployees});
	}

	public override void onBeforeDelete(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain2_Test.moduleOnBeforeDeleteCalled++;
	}

	public override void onAfterDelete(List<SObject> records, aef_ApplicationUnitOfWork uow) {
		aef_ApplicationTestDomain2_Test.moduleOnAfterDeleteCalled++;
	}
}