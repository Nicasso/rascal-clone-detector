module UnitTests

import CloneDetector;

import Prelude;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::m3::AST;
import lang::java::m3::Core;


public test bool testSimilarity() {
	node node1 = makeNode("node1", "321");
	node node2 = makeNode("node2", "123");
	
	if (calculateSimilarity(node1, node2) == 0) {
		return true;
	}
	
	return false;
}

public test bool testSimilarity2() {
	node theOnlyNode = makeNode("theOnlyNode", "1337");
	
	if (calculateSimilarity(theOnlyNode, theOnlyNode) == 1) {
		return true;
	}
	
	return false;
}

public test bool testSubTreeMass() {
	node node1 = makeNode("node1", "321");
	node node2 = makeNode("node2", node1);

	if (calculateMass(node2) == 2) {
		return true;
	}

	return false;
}

public test bool testMinimumCloneSizeCheck() {
	loc defaultLocation = |unknown:///|;
	defaultLocation = defaultLocation[offset = 1];
	defaultLocation = defaultLocation[length = 1];
	defaultLocation = defaultLocation[begin = <1, 1>];
	defaultLocation = defaultLocation[end = <100, 100>];
	
	if (minimumCloneSizeCheck(defaultLocation)) {
		return true;
	}
	
	return false;
}

public test bool testMinimumCloneSizeCheck2() {
	loc defaultLocation = |unknown:///|;
	defaultLocation = defaultLocation[offset = 1];
	defaultLocation = defaultLocation[length = 1];
	defaultLocation = defaultLocation[begin = <1, 1>];
	defaultLocation = defaultLocation[end = <5, 5>];
	
	if (!minimumCloneSizeCheck(defaultLocation)) {
		return true;
	}
	
	return false;
}

public test bool testRemoveSymmetricPairs() {
	lrel[tuple[node,loc] L, tuple[node,loc] R] complementBucket = [];
	
	loc defaultLocation = |unknown:///|;
	
	node node1 = makeNode("node1", "321");
	node node2 = makeNode("node2", "123");
	
	complementBucket += [<<node1, defaultLocation>, <node2, defaultLocation>>,<<node2, defaultLocation>, <node1, defaultLocation>>];
	
	if (size(removeSymmetricPairs(complementBucket)) == 1) {
		return true;
	}
	return false;
}