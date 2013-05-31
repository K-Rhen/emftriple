package org.eclipselabs.emftriple.jena.map

import com.hp.hpl.jena.rdf.model.Model
import com.hp.hpl.jena.rdf.model.Resource
import com.hp.hpl.jena.rdf.model.Statement
import java.util.Collection
import java.util.List
import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipselabs.emftriple.map.IDeserializer
import org.eclipselabs.emftriple.vocabularies.RDF

class Deserializer implements IDeserializer<Model> {

	override from(Model graph, org.eclipse.emf.ecore.resource.Resource resource) {
		val resourceSet = resource.resourceSet
		val contents = resource.contents
		val Map<Resource, EObject> mapOfObjects = newHashMap()
		val List<EObject> listOfObjects = newArrayList()

		graph.listSubjects.fold(listOfObjects, [list, it |
			from(it,  mapOfObjects, resourceSet).appendTo(list)
		])

		mapOfObjects.keySet.forEach[
			val res = it
			val eObject = mapOfObjects.get(it)
			val eClass = eObject.eClass
			val references = eClass.EAllReferences
			references.forEach[
				deSerialize(it, res, eObject, mapOfObjects, resourceSet)
			]
		]

		mapOfObjects.values.forEach[
			if (it.eContainer == null) contents.add(it)
		]
	}

	def EObject from(Resource res, Map<Resource, EObject> mapOfObjects, ResourceSet resourceSet) {
		val statement = res.getProperty(res.model.getProperty(RDF::type))
		switch statement {
			Statement case statement.object.URIResource: createEObject(statement, res, mapOfObjects, resourceSet)
			default: null
		}
	}

	protected def appendTo(EObject object, List<EObject> objects) {
		if (object != null) objects.add(object)
		objects
	}

	protected def createEObject(Statement stmt, Resource res, Map<Resource, EObject> mapOfObjects, ResourceSet resourceSet) {
		val eClassNode = stmt.object.asResource
		val eClassURI = URI::createURI(eClassNode.URI)
		val eClass = resourceSet.getEObject(eClassURI, true)
		switch eClass {
			EClass: {
				val eObject = EcoreUtil::create(eClass)
				eClass.EAllAttributes.forEach[
					deSerialize(it, res, eObject)
				]
				mapOfObjects.put(res, eObject)
				eObject
			}
			default: null
		}
	}

	def deSerialize(EAttribute attribute, Resource resource, EObject eObject) {
		if (attribute.derived || attribute.transient) return null;

		val propertyURI = EcoreUtil::getURI(attribute)
		val stmts = resource.listProperties(resource.model.getProperty(propertyURI.toString))

		if (attribute.many) {
			val values = eObject.eGet(attribute) as Collection<Object>
			stmts.forEach[
				val v = EcoreUtil::createFromString(attribute.EAttributeType, it.object.asLiteral.lexicalForm)
				if (v != null) values.add(v)
			]
		} else {
			val v = EcoreUtil::createFromString(attribute.EAttributeType, stmts.head.object.asLiteral.lexicalForm)
			if (v != null) eObject.eSet(attribute, v)
		}
	}

	def deSerialize(EReference reference, Resource resource, EObject eObject, Map<Resource, EObject> mapOfObjects, ResourceSet resourceSet) {
		if (reference.derived || reference.transient) return null;

		val propertyURI = EcoreUtil::getURI(reference)
		val stmts = resource.listProperties(resource.model.getProperty(propertyURI.toString))

		if (reference.many) {
			val values = eObject.eGet(reference) as Collection<Object>
			stmts.forEach[
				val v = it.object.asResource
				val o = mapOfObjects.get(v)
				if (o != null) values.add(o)
			]
		} else if (stmts.head != null) {
			val v = stmts.head.object.asResource
			val o = mapOfObjects.get(v)
			if (o != null) eObject.eSet(reference, o)
		}
	}

}