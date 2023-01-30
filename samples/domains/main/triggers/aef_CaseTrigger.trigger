/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * @author Nathan Franklin
 * @changelog
 */
trigger aef_CaseTrigger on Case (before insert, before update, after insert, after update) {
	// check the kill switch
	if(!aef_SystemSettings__c.getInstance().DisableTriggers__c) {
		(new aef_CaseTriggerHandler()).dispatch();
	}
}