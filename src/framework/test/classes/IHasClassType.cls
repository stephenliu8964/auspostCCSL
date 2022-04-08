/**
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Since there is a lack of reflection in Apex, implementing this interface allows a class to expose a method getClassType which can be used for various method calls
 *
 * @author Nathan Franklin
 * @changelog
 */
public interface IHasClassType {

	/**
	 * This allows a class to expose its type via a concrete method
	 */
	Type getClassType();

}