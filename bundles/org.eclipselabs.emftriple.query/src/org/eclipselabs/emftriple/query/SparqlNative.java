/*******************************************************************************
 * Copyright (c) 2011 Guillaume Hillairet.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *    Guillaume Hillairet - initial API and implementation
 *******************************************************************************/
package org.eclipselabs.emftriple.query;

import org.eclipse.emf.common.util.URI;

/**
 * The class {@link SparqlNative} allows creation of SPARQL queries from 
 * plain String.
 * 
 * @author guillaume hillairet
 * @since 0.8.0
 */
public class SparqlNative implements Query {

	private final String query;

	public SparqlNative(String query) {
		this.query = query;
	}
	
	@Override
	public String get() {
		return query;
	}
	
	@Override
	public URI toURI(URI resourceURI) {
		final String uri;
		
//		if (resourceURI.hasQuery()) {
//			uri=resourceURI+"&query=";
//		} else {
//			uri=resourceURI+"?query=";
//		}
		String query = get().replaceAll(" ", "%20").replaceAll("#", "%23");
		return resourceURI.appendQuery(query);
//		return URI.createURI(uri+query);
	}
}
