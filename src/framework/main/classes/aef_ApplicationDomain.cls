/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * aef_Application specific Domain base class
 * This class has been modelled after the work of fflib - All credit to FinancialForce.com, inc and team
 * It's cut down and doesn't include some of the features like sobject describes (for performance reasons in large orgs).
 *
 * @author Nathan Franklin
 * @changelog
 */
public virtual inherited sharing class aef_ApplicationDomain {

	/**
	 * Provides access to the data represented by this domain class
	 **/
	public List<SObject> records { get; private set; }

	/**
	 * Derived from the records provided during construction, provides the native describe for the standard or custom object
	 **/
	public SObjectType sObjectType { get; private set; }

	/**
	 * Stores the change state of field values during the trigger lifecycle
	 */
	protected Map<Id, Set<SObjectField>> recordFieldChangeState = new Map<Id, Set<SObjectField>>();

	/**
	 * Retains instances of domain classes implementing trigger stateful
	 **/
	private static Map<Type, List<aef_ApplicationDomain>> triggerStateByClass;

	/**
	 * Retains the trigger tracking configuration used for each domain
	 **/
	private static Map<Type, TriggerEvent> triggerEventByClass;

	/**
	 * Stores a cached copy of the domain modules to minimise the need to continually instantiating new instances
	 */
	private static Map<String, Map<Type, Object>> cachedModules;

	static {
		cachedModules = new Map<String, Map<Type, Object>>();

		triggerStateByClass = new Map<Type, List<aef_ApplicationDomain>>();

		triggerEventByClass = new Map<Type, TriggerEvent>();
	}

	public static aef_ApplicationDomain newInstance(Type domainType, List<SObject> sObjectList) {
		aef_ApplicationDomain domain = aef_Application.Domains.newInstance(domainType, sObjectList);
		domain.setRecords(sObjectList);
		domain.registerModules();
		return domain;
	}

	public static Module newModuleInstance(Type moduleType) {
		return (Module)aef_Application.Utilities.newInstance(moduleType);
	}

	/**
	 * TODO
	 **/
	public void setRecords(List<SObject> sObjectList) {
		// Ensure the domain class has its own copy of the data
		this.records = filter(sObjectList.clone());

		// Capture SObjectType describe for this domain class
		this.sObjectType = sObjectList.getSObjectType();
	}

	/**
	 * Grab the name of the class for various actions. Since Apex does not provide class Reflection then it's necessary to use this in order to know what the name of the most subclassed class is.
	 * In tests, using String.valueOf(this).substringBefore(':') consistently return results of 1-4ms which, in my opinion, is an acceptable overhead
	 *
	 * Test for this
	 * aef_Application.Profiler.start('this');
	 * for(Integer i = 0;i<5000;i++) {
	 *	  aef_ApplicationUnitOfWorkAsyncHandler d = new aef_ApplicationUnitOfWorkAsyncHandler();
	 *	  String classNameD = String.valueOf(d).substringBefore(':');
	 *	  aef_ApplicationUnitOfWorkBase c = new aef_ApplicationUnitOfWorkBase();
	 *	  String classNameC = String.valueOf(c).substringBefore(':');
	 *	  aef_QueryBuilder s = new aef_QueryBuilder();
	 *	  String classNameS = String.valueOf(s).substringBefore(':');
	 * }
	 * System.assert(false, aef_Application.Profiler.stop('this'));
	 */
	public String className {
		get {
			if(String.isEmpty(className)) {
				className = String.valueOf(this).substringBefore(':');
			}
			return className;
		}
		private set;
	}

	public virtual void registerModules() {}

	/**
	 * Override this to set the scope of the domain object, usually by Record Type or similar.
	 */
	public virtual List<SObject> filter(List<SObject> sObjectList) {
		return sObjectList;
	}

	//	public virtual aef_ApplicationUnitOfWork newUnitOfWork() {
	//		return null;
	//	}

	public void onBeforeInsert(aef_ApplicationUnitOfWork uow) {
		// process each module
		//System.debug(className + ': onBeforeInsert');
		Map<Type, Object> modules = cachedModules.get(className);
		if (modules != null) {
			for (Object module : modules.values()) {
				//System.debug('Module: ' + module);
				IModule instance = (IModule) module;
				if (instance.getTriggerEvents().beforeInsertEnabled) {
					instance.onBeforeInsert(records, uow);
				}
			}
		}
	}

	public void onAfterInsert(aef_ApplicationUnitOfWork uow) {
		//System.debug(className  + ': onAfterInsert');
		Map<Type, Object> modules = cachedModules.get(className);
		if (modules != null) {
			for (Object module : modules.values()) {
				//System.debug('Module: ' + module);
				IModule instance = (IModule) module;
				if (instance.getTriggerEvents().afterInsertEnabled) {
					instance.onAfterInsert(records, uow);
				}
			}
		}
	}

	public void onBeforeUpdate(Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
		//System.debug(className  + ': onBeforeUpdate');
		Map<Type, Object> modules = cachedModules.get(className);
		if (modules != null) {
			for (Object module : modules.values()) {
				//System.debug('Module: ' + module);
				IModule instance = (IModule) module;
				if (instance.getTriggerEvents().beforeUpdateEnabled) {
					instance.onBeforeUpdate(records, existingRecords, uow);
				}
			}
		}
	}

	public void onAfterUpdate(Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {
		// process each module
		//System.debug(className + ': onAfterUpdate');
		Map<Type, Object> modules = cachedModules.get(className);
		if (modules != null) {
			for (Object module : modules.values()) {
				//System.debug('Module: ' + module);
				IModule instance = (IModule) module;
				if (instance.getTriggerEvents().afterUpdateEnabled) {
					instance.onAfterUpdate(records, existingRecords, uow);
				}
			}
		}
	}

	// TODO: delete handlers
	//	public override void onBeforeDelete(Map<Id,SObject> existingRecords) {}
	//	public override void onAfterDelete(Map<Id,SObject> existingRecords) {}


	public void registerModule(Type moduleClass) {
		// remove any modules which are not 'active'
		//		if(!ApplicationFeatures.getInstance().isModuleActive(moduleClass)) {
		//			System.debug('Skipping Module: ' + moduleClass);
		//			return;
		//		}

		// store this module in transaction cache
		String thisClass = className;
		if (cachedModules.get(thisClass) == null) {
			cachedModules.put(thisClass, new Map<Type, Object>());
		}
		if (cachedModules.get(thisClass).get(moduleClass) == null) {
			// Construct the module
			cachedModules.get(thisClass).put(moduleClass, newModuleInstance(moduleClass));

//			// TODO -> Link domain (if needed)
//			// provide a link to the domain calling this module
//			// this is incase the module needs to access the domain (for bypassing other modules for example)
//			((IModule)cachedModules.get(thisClass).get(moduleClass)).setDomain(this);
		}
	}

	public class TriggerEvent {
		public Boolean beforeInsertEnabled { get; private set; }
		public Boolean beforeUpdateEnabled { get; private set; }
		public Boolean beforeDeleteEnabled { get; private set; }

		public Boolean afterInsertEnabled { get; private set; }
		public Boolean afterUpdateEnabled { get; private set; }
		public Boolean afterDeleteEnabled { get; private set; }
		public Boolean afterUndeleteEnabled { get; private set; }

		public TriggerEvent() {
			this.disableAll();
		}

		// befores
		public TriggerEvent enableBeforeInsert() {
			beforeInsertEnabled = true; return this;
		}
		public TriggerEvent enableBeforeUpdate() {
			beforeUpdateEnabled = true; return this;
		}
		public TriggerEvent enableBeforeDelete() {
			beforeDeleteEnabled = true; return this;
		}

		public TriggerEvent disableBeforeInsert() {
			beforeInsertEnabled = false; return this;
		}
		public TriggerEvent disableBeforeUpdate() {
			beforeUpdateEnabled = false; return this;
		}
		public TriggerEvent disableBeforeDelete() {
			beforeDeleteEnabled = false; return this;
		}

		// afters
		public TriggerEvent enableAfterInsert() {
			afterInsertEnabled = true; return this;
		}
		public TriggerEvent enableAfterUpdate() {
			afterUpdateEnabled = true; return this;
		}
		public TriggerEvent enableAfterDelete() {
			afterDeleteEnabled = true; return this;
		}
		public TriggerEvent enableAfterUndelete() {
			afterUndeleteEnabled = true; return this;
		}


		public TriggerEvent disableAfterInsert() {
			afterInsertEnabled = false; return this;
		}
		public TriggerEvent disableAfterUpdate() {
			afterUpdateEnabled = false; return this;
		}
		public TriggerEvent disableAfterDelete() {
			afterDeleteEnabled = false; return this;
		}
		public TriggerEvent disableAfterUndelete() {
			afterUndeleteEnabled = false; return this;
		}

		public TriggerEvent enableAll() {
			return this.enableAllBefore().enableAllAfter();
		}

		public TriggerEvent disableAll() {
			return this.disableAllBefore().disableAllAfter();
		}

		public TriggerEvent enableAllBefore() {
			return this.enableBeforeInsert().enableBeforeUpdate().enableBeforeDelete();
		}

		public TriggerEvent disableAllBefore() {
			return this.disableBeforeInsert().disableBeforeUpdate().disableBeforeDelete();
		}

		public TriggerEvent enableAllAfter() {
			return this.enableAfterInsert().enableAfterUpdate().enableAfterDelete().enableAfterUndelete();
		}

		public TriggerEvent disableAllAfter() {
			return this.disableAfterInsert().disableAfterUpdate().disableAfterDelete().disableAfterUndelete();
		}
	}

	public virtual class Module implements IModule {
		private aef_ApplicationDomain moduleDomain;

		@TestVisible
		private TriggerEvent triggerEvents;

		public virtual TriggerEvent getTriggerEvents() {
			if (triggerEvents == null) {
				triggerEvents = new TriggerEvent().disableAll();
			}
			return triggerEvents;
		}

		public virtual void onBeforeInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {}
		public virtual void onAfterInsert(List<SObject> records, aef_ApplicationUnitOfWork uow) {}

		public virtual void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {}
		public virtual void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow) {}

		public virtual void onBeforeDelete(List<SObject> records, aef_ApplicationUnitOfWork uow) {}
		public virtual void onAfterDelete(List<SObject> records, aef_ApplicationUnitOfWork uow) {}

//		/**
//		 * Sets the link this module has with the domain that invoked it (if any)
//		 */
//		public void setDomain(aef_ApplicationDomain domain) {
//			moduleDomain = domain;
//		}
//
//		/**
//		 * Returns the link this module has with the domain that invoked it (if any)
//		 */
//		public aef_ApplicationDomain getDomain() {
//			return moduleDomain;
//		}

		// returns an empty string
		@TestVisible
		protected String nullToString(String nullString) {
			String emptyString = nullString == null ? '' : nullString;
			return emptyString;
		}

		/**
		 * Grabs a list of record ids where the values in the monitored fields have changed. This is just a bulkified helper method.
		 * TODO: TO minimise looping this should somehow be better written at the domain or trigger handler level
		 */
		protected Map<Id, Set<SObjectField>> getIsChanged(List<SObject> records, Map<Id, SObject> oldRecords, Set<SObjectField> comparisonFields) {
			Map<Id, Set<SObjectField>> output = new Map<Id, Set<SObjectField>>();
			for (SObject record : records) {
				for (SObjectField field : comparisonFields) {
					if(record.get(field) != oldRecords.get(record.Id).get(field)) {
						if(output.get(record.Id) == null) {
							output.put(record.Id, new Set<SObjectField>());
						}
						output.get(record.Id).add(field);
					}
				}
			}
			return output;
		}

	}

	public interface IModule {

		/**
		 * Determines which trigger events the module should respond to
		 */
		TriggerEvent getTriggerEvents();

		void onBeforeInsert(List<SObject> records, aef_ApplicationUnitOfWork uow);
		void onAfterInsert(List<SObject> records, aef_ApplicationUnitOfWork uow);

		void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow);
		void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, aef_ApplicationUnitOfWork uow);

		void onBeforeDelete(List<SObject> records, aef_ApplicationUnitOfWork uow);
		void onAfterDelete(List<SObject> records, aef_ApplicationUnitOfWork uow);

//		void setDomain(aef_ApplicationDomain domain);
//		aef_ApplicationDomain getDomain();
	}

	// returns an empty string
	@TestVisible
	protected String nullToString(String nullString) {
		String emptyString = nullString == null ? '' : nullString;
		return emptyString;
	}

	public class ApplicationDomainException extends Exception {}
}