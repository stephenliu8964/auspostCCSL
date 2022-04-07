/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description Platform Event trigger exclusive async workers (a part of the unit of work framework)
 *              This passed work off to our handler that is responsible to spaning a queueable for each of these events
 *
 * @author Nathan Franklin
 * @changelog
 */
trigger aef_AsyncWorkerEventTrigger on aef_AsyncWorkerEvent__e (after insert) {
	// check the kill switch if there is a catastrophic failure
	if(!aef_SystemSettings__c.getInstance().AsyncFrameworkDisableEvents__c) {
		aef_ApplicationUnitOfWorkAsyncHandler.getInstance().dispatch(Trigger.new);
	}
}