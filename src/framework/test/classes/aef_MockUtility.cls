/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description Utility class to help with easier mocking in text classes
 * @author Nathan Franklin
 * @changelog
 */
@IsTest
public class aef_MockUtility {

	/**
	 * Whenever the AnswerGenericDMLInserted/AnswerGenericDMLUpdated is used, these will store a reference to the record that was inserted
	 * This is used to verify the records that would be created
	 */
	public static List<SObject> mockDMLInsertedRecords = new List<SObject>();
	public static List<SObject> mockDMLUpdatedRecords = new List<SObject>();
	public static List<SObject> mockUnitOfWorkDMLs = new List<SObject>();

	public static fflib_ApexMocks Mocks {
		get {
			if(Mocks == null) {
				Mocks = new fflib_ApexMocks();
			}
			return Mocks;
		}
		private set;
	}

	/**
	 * Use this to mock Selector classes in unit tests
	 */
	public static aef_ApplicationSelector mockSelector(Type selectorType) {
		aef_ApplicationSelector selector = (aef_ApplicationSelector)Mocks.mock(selectorType);

		// A little hack here to stub any chained methods
		// This ensures that chained methods will not unexpectedly return null
		aef_MockUtility.Mocks.startStubbing();
		aef_MockUtility.Mocks.when(selector.setLimit(fflib_Match.anyInteger())).thenReturn(selector);
		aef_MockUtility.Mocks.when(selector.setOffset(fflib_Match.anyInteger())).thenReturn(selector);
		aef_MockUtility.Mocks.when(selector.setFieldOverrides((Set<SObjectField>)fflib_Match.anyObject())).thenReturn(selector);
		aef_MockUtility.Mocks.when(selector.setFieldOverrides((Map<SObjectType, Set<SObjectField>>)fflib_Match.anyObject())).thenReturn(selector);
		aef_MockUtility.Mocks.stopStubbing();

		aef_Application.Selectors.setMock(selectorType, selector);

		return selector;
	}

	/**
	 * Use this to mock Utility classes in unit tests
	 */
	public static Object mockUtility(Type utilityType) {
		Object utility = Mocks.mock(utilityType);
		aef_Application.Utilities.setMock(utilityType, utility);
		return utility;
	}

	/**
	 * Use this to return a stubbed aef_ApplicationDatabase instance
	 */
	public static aef_ApplicationDatabase mockDatabase() {
		aef_ApplicationDatabase utility = (aef_ApplicationDatabase)Mocks.mock(aef_ApplicationDatabase.class);
		aef_Application.Utilities.setMock(aef_ApplicationDatabase.class, utility);
		return utility;
	}
	
	/**
	 * Use this to return a stubbed aef_ApplicationUnitOfWork instance - Added Mathew
	 */
	public static aef_ApplicationUnitOfWork mockUnitOfWork() {
		aef_ApplicationUnitOfWork utility = (aef_ApplicationUnitOfWork)Mocks.mock(aef_ApplicationUnitOfWork.class);
		aef_Application.Utilities.setMock(aef_ApplicationUnitOfWork.class, utility);
		return utility;
	}	

	/**
	 * Stubs the aef_Application domain to stop all trigger processing
	 * Useful to load records for integration style testing.
	 */
	public static void disableTriggerExecution() {
		aef_SystemSettings__c settings = new aef_SystemSettings__c(DisableTriggers__c = true);
		insert settings;

//		// redirect calls made to the domain to the stub class we generate
//		fflib_ApexMocks mocks = new fflib_ApexMocks();
//		aef_ApplicationDomain mockDomain = (aef_ApplicationDomain)mocks.mock(aef_ApplicationDomain.class);
//		aef_Application.Domains.setMock(mockDomain);
//		return mockDomain;
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLInserted implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				record.Id = fflib_IDGenerator.generate(record.getSObjectType());

				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				saveResults.add(result);
			}

			// store a list of the records that were updated when this answer is invoked.
			mockDMLInsertedRecords.addAll(records);

			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to simulate a failed DML insert operation
	 */
	public class AnswerGenericDMLFailed implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => false,
						'id' => null,
						'errors' => new List<Map<String, Object>>{
								new Map<String, Object>{
										'message' => 'The request failed because of some random error'
								}
						}
				};
				saveResults.add(result);
			}
			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to simulate a failed DML update operation
	 */
	public class AnswerGenericDMLUpdateFailed implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
					'success' => false,
					'id' => record.Id,
					'errors' => new List<Map<String, Object>>{
						new Map<String, Object>{
							'message' => 'The request failed because of some random error'
						}
					}
				};
				saveResults.add(result);
			}
			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to simulate a failed DML update operation
	 * This alternates success/fail
	 */
	public class AnswerGenericDMLUpdatePartialFailed implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			Boolean isSuccess = true;
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
					'success' => isSuccess,
					'id' => record.Id,
					'errors' => (isSuccess ? null : new List<Map<String, Object>>{
						new Map<String, Object>{
							'message' => 'The request failed because of some random error'
						}
					})
				};
				saveResults.add(result);

				isSuccess = !isSuccess;
			}
			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLFailedLockError implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => false,
						'id' => null,
						'errors' => new List<Map<String, Object>>{
								new Map<String, Object>{
										'statusCode' => 'UNABLE_TO_LOCK_ROW',
										'message' => 'unable to obtain exclusive access to this record or 1 records: 000000000000000'
								}
						}
				};
				saveResults.add(result);
			}
			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML update operation
	 */
	public class AnswerGenericDMLUpdated implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				saveResults.add(result);
			}

			// store a list of the records that were updated when this answer is invoked.
			mockDMLUpdatedRecords.addAll(records);

			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML delete operation
	 */
	public class AnswerGenericDMLDeleted implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				saveResults.add(result);
			}
			List<Database.DeleteResult> result = (List<Database.DeleteResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.DeleteResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLDeleteFailed implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => false,
						'id' => null,
						'errors' => new List<Map<String, Object>>{
								new Map<String, Object>{
										'message' => 'The request failed because of some random error'
								}
						}
				};
				saveResults.add(result);
			}
			List<Database.DeleteResult> result = (List<Database.DeleteResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.DeleteResult>.class);
			return result;
		}
	}

	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericDMLDeleteFailedLockError implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				Map<String, Object> result = new Map<String, Object> {
						'success' => false,
						'id' => null,
						'errors' => new List<Map<String, Object>>{
								new Map<String, Object>{
										'statusCode' => 'UNABLE_TO_LOCK_ROW',
										'message' => 'unable to obtain exclusive access to this record or 1 records: 000000000000000'
								}
						}
				};
				saveResults.add(result);
			}
			List<Database.DeleteResult> result = (List<Database.DeleteResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.DeleteResult>.class);
			return result;
		}
	}
	
	/**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	public class AnswerGenericRegisterUnitOfWorkDML implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			Boolean isList = (invocation.getArgument(0) instanceof List<SObject>);		
			List<SObject> records = (isList ? (List<SObject>)invocation.getArgument(0) : new List<SObject>{(SObject)invocation.getArgument(0)});	
			// store a list of the records that were updated when this answer is invoked.
			mockUnitOfWorkDMLs.addAll(records);	
			return  (isList ? (Object)records : (Object)records[0]);
		}
	}	

	/**
	 * This Answer is used for methods requiring mocking that return VOID
	 * Example public void doThing() { }
	 */
	public class AnswerVoid implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			return null;
		}
	}

}