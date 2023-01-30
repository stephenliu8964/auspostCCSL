/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description Sample Domain Trigger Handler for Account
 * @author Nathan Franklin
 * @changelog
 */
public inherited sharing class aef_CaseTriggerHandler extends aef_ApplicationDomainTriggerHandler {

	public override SObjectType getSObjectType() {
		return Case.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
			aef_EnterpriseCasesDomain.class
		};
	}

	/**
	 * Unit of work that encapsulates all the required objects for each domain within this SObject
	 * Only a single UOW context for all domains
	 */
	public override aef_ApplicationUnitOfWork newUnitOfWork() {
		return aef_ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			Case.SObjectType
		};
	}

}