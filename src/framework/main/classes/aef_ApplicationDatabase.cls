/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @author Nathan Franklin
 * @description A very simple selector class that sits in the base domain
 * @changelog
 */
public inherited sharing class aef_ApplicationDatabase {

	public static aef_ApplicationDatabase getInstance() {
		return (aef_ApplicationDatabase)aef_Application.Utilities.getInstance(aef_ApplicationDatabase.class);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.SaveResult> dmlInsert(List<SObject> objList) {
		return dmlInsert(objList, true);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.SaveResult> dmlInsert(List<SObject> objList, Boolean allOrNothing) {
		return Database.insert(objList, allOrNothing);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.SaveResult> dmlUpdate(List<SObject> objList) {
		return dmlUpdate(objList, true);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.SaveResult> dmlUpdate(List<SObject> objList, Boolean allOrNothing) {
		return Database.update(objList, allOrNothing);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.DeleteResult> dmlDelete(List<SObject> objList) {
		return dmlDelete(objList, true);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.DeleteResult> dmlDelete(List<SObject> objList, Boolean allOrNothing) {
		return Database.delete(objList, allOrNothing);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public Boolean eventPublish(List<SObject> objList) {
		EventBus.publish(objList);
		return true;
	}
	/**
	 * Note: return restult as System.savepoint , used for rollback
	 */
	public System.Savepoint dmlSetSavePoint() {
		System.Savepoint sSavePoint = Database.setSavepoint();
		return sSavePoint;
	}
	/**
	 * Note: return result as true after roll back
	 */
	public Boolean dmlRollback(System.Savepoint databaseSavepoint) {
		Database.rollback(databaseSavepoint);
		return true;
	}

	public Id enqueueJob(Object queueable) {
		return System.enqueueJob(queueable);
	}
}