module UnitTests

import CloneDetector;

import Prelude;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::m3::AST;
import lang::java::m3::Core;
import Config;


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

public test bool testType1() {
	currentProject = |project://TestProject|;
	currentProject2 = |file://C:/Users/Nico/workspace/TestProject/|;
	
	set[loc] expectedPairs = {
	|file:///C:/Users/Nico/workspace/TestProject/src/Test.java|(98,127,<9,21>,<19,2>),
	|file:///C:/Users/Nico/workspace/TestProject/src/Test.java|(251,127,<21,21>,<31,2>)
	};
	
	main(1);
	
	int countingPairs = 0;
	set[loc] clonePairsPerClass = {};
	for (currentClass <- cloneClasses) {
		for (currentClone <- cloneClasses[currentClass]) {
			clonePairsPerClass += currentClone[0][1];
			clonePairsPerClass += currentClone[1][1];
			countingPairs += 1;
		}
	}
	
	bool good = true;
	for (uniqueClone <- clonePairsPerClass) {
		if(uniqueClone notin expectedPairs) {
			good = false;
		}
	}
		
	if(countingPairs == 1 && good == true) {
		return true;
	}
	return false;
}

public test bool testType2() {
	currentProject = |project://TestProject2|;
	currentProject2 = |file://C:/Users/Nico/workspace/TestProject2/|;
	
	set[loc] expectedPairs = {
	|file:///C:/Users/Nico/workspace/TestProject2/src/Test.java|(98,127,<9,21>,<19,2>),
	|file:///C:/Users/Nico/workspace/TestProject2/src/Test.java|(251,127,<21,21>,<31,2>)
	};
	
	main(2);
	
	int countingPairs = 0;
	set[loc] clonePairsPerClass = {};
	for (currentClass <- cloneClasses) {
		for (currentClone <- cloneClasses[currentClass]) {
			clonePairsPerClass += currentClone[0][1];
			clonePairsPerClass += currentClone[1][1];
			countingPairs += 1;
		}
	}
	
	bool good = true;
	for (uniqueClone <- clonePairsPerClass) {
		if(uniqueClone notin expectedPairs) {
			good = false;
		}
	}
		
	if(countingPairs == 1 && good == true) {
		return true;
	}
	return false;
}

public test bool testType3() {
	currentProject = |project://TestProject3|;
	currentProject2 = |file://C:/Users/Nico/workspace/TestProject3/|;
	
	set[loc] expectedPairs = {
	|file:///C:/Users/Nico/workspace/TestProject3/src/Test.java|(273,127,<22,21>,<32,2>),
	|file:///C:/Users/Nico/workspace/TestProject3/src/Test.java|(98,149,<9,21>,<20,2>)
	};
	
	main(3);
	
	int countingPairs = 0;
	set[loc] clonePairsPerClass = {};
	for (currentClass <- cloneClasses) {
		for (currentClone <- cloneClasses[currentClass]) {
			clonePairsPerClass += currentClone[0][1];
			clonePairsPerClass += currentClone[1][1];
			countingPairs += 1;
		}
	}
	
	bool good = true;
	for (uniqueClone <- clonePairsPerClass) {
		if(uniqueClone notin expectedPairs) {
			good = false;
		}
	}
		
	if(countingPairs == 1 && good == true) {
		return true;
	}
	return false;
}