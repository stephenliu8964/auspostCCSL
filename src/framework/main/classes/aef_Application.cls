/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 *
 * @description This is the handler for class interaction within the aef_Application
				This class is predominately used to enable proper test class mocking
 * @author Nathan Franklin
 * @changelog
 */
public with sharing class aef_Application {

	public static UtilityFactory Utilities;
	public static SelectorFactory Selectors;
	public static DomainFactory Domains;
	public static ProfileFactory Profiler;

	static {
		Utilities = new UtilityFactory();
		Selectors = new SelectorFactory();
		Domains = new DomainFactory();
		Profiler = new ProfileFactory();
	}

	public class UtilityFactory {

		Map<Type, Object> mockInstances = new Map<Type, Object>();
		Map<Type, Object> instances = new Map<Type, Object>();

		/**
		 * Store a list of type instance mappings to be able grab the correct instance of a selector when needed
		 * This is used to we can provide mocks in test classes to override default functionality
		 */
		@TestVisible
		private void setMock(Type utilityType, Object instance) {
			mockInstances.put(utilityType, instance);
		}

		/**
		 * Used to inject mocking class for writing isolated unit tests
		 * When not running tests, the method simply returns the normal instance
		 */
		public Object getInstance(Type utilityType) {
			if(Test.isRunningTest() && mockInstances.get(utilityType) != null) {
				return mockInstances.get(utilityType);
			} else if(instances.get(utilityType) == null) {
				instances.put(utilityType, utilityType.newInstance());
			}
			return instances.get(utilityType);
		}

		/**
		 * Used to inject mocking class for writing isolated unit tests
		 * When not running tests, the method simply returns the normal instance
		 */
		public Object newInstance(Type utilityType) {
			if(Test.isRunningTest() && mockInstances.get(utilityType) != null) {
				return mockInstances.get(utilityType);
			} else {
				return utilityType.newInstance();
			}
		}
	}

	public class SelectorFactory {

		Map<Type, aef_ApplicationSelector> mockSelectors = new Map<Type, aef_ApplicationSelector>();

		/**
		 * Store a list of type instance mappings to be able grab the correct instance of a selector when needed
		 * This is used to we can provide mocks in test classes to override default functionality of a selector class where we don't care about the results
		 */
		@TestVisible
		private void setMock(Type selectorType, aef_ApplicationSelector selectorInstance) {
			mockSelectors.put(selectorType, selectorInstance);
		}

		/**
		 * Used to inject mocking class for writing isolated unit tests
		 * When not running tests, the method simply returns the normal instance
		 */
		public aef_ApplicationSelector newInstance(Type selectorType) {
			if(Test.isRunningTest() && mockSelectors.get(selectorType) != null) {
				aef_ApplicationSelector selector = mockSelectors.get(selectorType);
				return selector;
			} else {
				return (aef_ApplicationSelector)selectorType.newInstance();
			}
		}
	}

	public class DomainFactory {

		Map<Type, aef_ApplicationDomain> mockDomains = new Map<Type, aef_ApplicationDomain>();

		/**
		 * Store a list of type instance mappings to be able grab the correct instance when needed
		 * This is used to we can provide mocks in test classes to override default functionality where we don't care about the results
		 */
		@TestVisible
		private void setMock(Type domainType, aef_ApplicationDomain domainInstance) {
			mockDomains.put(domainType, domainInstance);
		}

		/**
		 * Used to inject mocking class for writing isolated unit tests
		 * When not running tests, the method simply returns the normal instance
		 */
		public aef_ApplicationDomain newInstance(Type domainType, List<SObject> sObjectList) {
			if(Test.isRunningTest() && mockDomains.get(domainType) != null) {
				aef_ApplicationDomain domain = mockDomains.get(domainType);
				return domain;
			} else {
				return (aef_ApplicationDomain)domainType.newInstance();
			}
		}
	}

	public class GenericFactory {
		private Map<Type, Object> instances = new Map<Type, Object>();

		@TestVisible
		private void put(Type classType, Object instance) {
			instances.put(classType, instance);
		}

		public Object get(Type classType) {
			return instances.get(classType);
		}
	}

	public class ProfileFactory {
		private Map<String, Long> profileMap;

		public ProfileFactory() {
			profileMap = new Map<String, Long>();
		}

		public void start(String key) {
			profileMap.put(key, System.currentTimeMillis());
		}
		public void stop(String key) {
			System.debug('Profiler Results: ' + key + ' ' + (System.currentTimeMillis() - profileMap.get(key)) + 'ms');
		}
	}

}