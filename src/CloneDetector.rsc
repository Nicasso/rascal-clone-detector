module CloneDetector

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import demo::common::Crawl;
import IO;
import List;
import Map;
import Tuple;
import Type;
import String;
import Relation;
import ListRelation;
import util::Math;
import DateTime;
import Traversal;

public loc currentProject = |project://TestProject|;

map[node,lrel[node,loc]] buckets = ();

map[node, lrel[tuple[node,loc],tuple[node,loc]]] cloneClasses = ();

lrel[tuple[node,loc],tuple[node,loc]] clonePairs = [];
lrel[tuple[node,loc],tuple[node,loc]] clonesToGeneralize = [];
set[Declaration] ast;

public void main() {
	iprintln("Attack of the clones!");
	
	buckets = ();
	clonePairs = [];
	cloneClasses = ();

	currentSoftware = createM3FromEclipseProject(currentProject);
	
	ast = createAstsFromEclipseProject(currentProject, true);
		
	int massThreshold = 8;
	real similarityThreshold = 0.75;
	
	// Step 1. Finding Sub-tree Clones
	
	visit (ast) {
		case node x: {
			if (calculateMass(x) >= massThreshold) {
				addSubTreeToMap(x);
			}
		}
	}
	
	for (bucket <- buckets) {
		if (size(buckets[bucket]) >= 2) {
			lrel[tuple[node,loc] L, tuple[node,loc] R] complementBucket = [];
			complementBucket += buckets[bucket] * buckets[bucket];
			// Removing reflective pairs
			complementBucket = [p | p <- complementBucket, p.L != p.R];
			// Cleanup symmetric clones, they are useless.
			complementBucket = removeSymmetricPairs(complementBucket);
				
			for (treeRelation <- complementBucket) {
				num similarity = calculateSimilarity(treeRelation[0][0], treeRelation[1][0]);
				if (similarity > similarityThreshold) {
					
					// Look for smaller clones within the trees and remove them.
					// @TODO This is broken, it messes up the results.
					// It will remove almosts ALL results...
					checkForInnerClones(treeRelation[0]);
					checkForInnerClones(treeRelation[1]);
					
					clonePairs += treeRelation;
					
					if (cloneClasses[treeRelation[0][0]]?) {
						cloneClasses[treeRelation[0][0]] += treeRelation;
					} else {
						cloneClasses[treeRelation[0][0]] = [treeRelation];
					}
				}
			}
		}
	}
	
	iprintln("Amount of clonepairs after step 1: <size(clonePairs)>");
	
	iprintln("Class sizes");
	for (currentClass <- cloneClasses) {
		iprintln(size(cloneClasses[currentClass]));
		iprintln("--------------------------------------------------");
	}
	
	printCloneResults();
	
	// Step 2. Finding Clone Sequences

	// Step 3. Generalizing clones
	
	clonesToGeneralize = clonePairs;
	
	while (currentClonePair <- clonesToGeneralize) {
		clonesToGeneralize = clonesToGeneralize - currentClonePair;
		
		//iprintln("Child");
		//iprintln(currentClonePair[0][1]);
		
		list[node] parents = getParentsOfClone(currentClonePair[0][0]);		
		// Dunno if this is required, but lets keep it for now just to be sure.
		parents += getParentsOfClone(currentClonePair[1][0]);
		parents = dup(parents);
		
		lrel[node,loc] parentsPairs = [];
		for (parent <- parents) {
			loc parentLocation = getLocationOfNode(parent);
			parentsPairs += <parent, parentLocation>;
		}
		
		//iprintln(size(parentsPairs));
				
		lrel[tuple[node,loc] L, tuple[node,loc] R] complementParents = [];
		complementParents += parentsPairs * parentsPairs;
		complementParents = [p | p <- complementParents, p.L != p.R];
		complementParents = removeSymmetricPairs(complementParents);
		
		//iprintln("Amount of parent pairs: <size(complementParents)>");
		
		if (size(complementParents) == 0) {
			//iprintln(parents);
			int a;
		}
		
		for (parentRelation <- complementParents) {
			num similarity = calculateSimilarity(parentRelation[0][0],parentRelation[1][0]);
			//iprintln("Parent simi <similarity>");
			//iprintln(parentRelation[0][1]);
			//iprintln(parentRelation[1][1]);
			
			if (similarity > similarityThreshold) {
				//iprintln("So we found a parent which matches");
				clonePairs = clonePairs - currentClonePair;
				
				clonePairs += parentRelation; 
				clonesToGeneralize += parentRelation;
			} else {
				//iprintln("So we did not find a parent which matches");
				int a;
			}
		}
		//iprintln("End loop iteration");
		//iprintln("----------------------------------");
	}
	
	/*
	for (clone <- clonePairs) {
		checkForInnerClones(clone[0][0]);
		checkForInnerClones(clone[1][0]);
	}
	*/
	
	printCloneResults();
}

public void printCloneResults() {
	println();
	iprintln("Final clone pairs");
	for (pair <- clonePairs) {
		iprintln(pair[0][1]);
		iprintln(pair[1][1]);
		iprintln("----------------------------------------------------------------------------------------");
	}
}

public void checkForInnerClones(tuple[node,loc] tree) {
	visit (tree[0]) {
		case node x: {
			if (x != tree[0]) {
				//iprintln("WTF?!?!?!?!?!?!??!");
				loc location = getLocationOfNode(x);
				isMemberOfClones(x, location);
			} else {
				//iprintln("SAME");
				int a;
			}
		}
	}
}

public lrel[tuple[node,loc],tuple[node,loc]] removeSymmetricPairs(lrel[tuple[node,loc],tuple[node,loc]] clonePairs) {
	// Remove one of the symmetric pairs (a,b) & (b,a) should result in only one of the two.
	lrel[tuple[node,loc],tuple[node,loc]] newClonePairs = [];
	for (pair <- clonePairs) {
		tuple[tuple[node,loc],tuple[node,loc]] reversePair = <<pair[1][0],pair[1][1]>,<pair[0][0],pair[0][1]>>;
		if (reversePair notin newClonePairs) {		
			newClonePairs += pair;
		}
	}
	return newClonePairs;
}

public list[node] getParentsOfClone(node current) {
	
	list[node] parents = [];
	
	//iprintln("Potential parents");
	top-down visit (ast) {
		case current: {
			list[value] context = getTraversalContext();
			
			int i = 1;
			bool added = false;
			while (i <= size(context) && added == false) {
				value potentialParent = context[i];
				
				if (node x := potentialParent) {
					//iprintln("FOUND PARENT");
					//iprintln(getLocationOfNode(potentialParent));
					parents += x;
					added = true;
				} 
				i += 1;
			}
			//iprintln("NEXT");
			//iprintln("--------------------------------------------------------------------------------------");
		}
	}
	
	return parents;
}

public void isMemberOfClones(node target, loc location) {
	tuple[node,loc] current = <target,location>;
	
	for (relation <- clonePairs) {
		if (current == relation[0] || current == relation[1]) {
			if(size(cloneClasses[target]) == 1) {
				clonePairs = clonePairs - relation;
				cloneClasses = delete(cloneClasses, target);   
			}
			
		}
	}
}

public num calculateSimilarity(node t1, node t2) {
	//Similarity = 2 x S / (2 x S + L + R)
	
	list[node] tree1 = [];
	list[node] tree2 = [];
	
	visit (t1) {
		case node x: {
			tree1 += x;
		}
	}
	
	visit (t2) {
		case node x: {
			tree2 += x;
		}
	}
	
	num s = size(tree1 & tree2);
	num l = size(tree1 - tree2);
	num r = size(tree2 - tree1); 
		
	num similarity = (2 * s) / (2 * s + l + r); 
	
	return similarity;
}

public loc getLocationOfNode(node subTree) {
	loc location;
	
	if (Declaration d := subTree) { 
		location = d@src;
	} else if (Expression e := subTree) {
		location = e@src;
	} else if (Statement s := subTree) {
		location = s@src;
	} else {
		iprintln("WTF NO LOCATION?!");
	}
	
	return location;
}

public void addSubTreeToMap(node subTree) {

	loc location = getLocationOfNode(subTree);

	if (buckets[subTree]?) {
		buckets[subTree] += <subTree,location>;
	} else {
		buckets[subTree] = [<subTree,location>];
	}
}

public int findSubTrees(set[Declaration] ast, node dec) {
	int occurrences = 0;
	top-down visit (ast) {
		case node x: {
			if (x == dec) {
				occurrences += 1;
			}
		}
	}
	return occurrences;
}

public int calculateMass(node currentNode) {
	int mass = 0;
	visit (currentNode) {
		case node x: {
			mass += 1;
		}
	}
	return mass;
}