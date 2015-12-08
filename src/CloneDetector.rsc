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
//public loc currentProject = |project://smallsql0.21_src|;
//public loc currentProject = |project://hsqldb-2.3.1|;

map[node, lrel[node, loc]] buckets = ();

map[node, lrel[tuple[node, loc], tuple[node, loc]]] cloneClasses = ();
map[list[node], lrel[list[tuple[node, loc]], list[tuple[node, loc]]]] cloneSequences = ();

list[node] subCloneClasses = [];

//map[list[Statement],list[Statement]] allSequences = ();
list[lrel[node,loc]] allSequences = [];

lrel[tuple[node,loc],tuple[node,loc]] clonesToGeneralize = [];
set[Declaration] ast;

int massThreshold;

public void main() {
	iprintln("Attack of the clones!");
	println(printTime(now(), "HH:mm:ss"));
	
	buckets = ();
	cloneClasses = ();
	subCloneClasses = [];
	allSequences = [];
	clonesToGeneralize = [];

	currentSoftware = createM3FromEclipseProject(currentProject);
	
	ast = createAstsFromEclipseProject(currentProject, true);
		
	massThreshold = 5;
	real similarityThreshold = 0.75;
	
	// Step 1. Finding Sub-tree Clones
	
	// Add all the subtrees with a decent mass to a bucket.
	visit (ast) {
		case node x: {
			if (calculateMass(x) >= massThreshold) {
				node normalizedNode = normalizeNodeDec(x);
				addSubTreeToMap(normalizedNode, x);
			}
		}
	}
	
	println("Done with indexing the subtrees into buckets.");
	println(printTime(now(), "HH:mm:ss"));
	
	for (bucket <- buckets) {
		if (size(buckets[bucket]) >= 2) {
			lrel[tuple[node,loc] L, tuple[node,loc] R] complementBucket = [];
			complementBucket += buckets[bucket] * buckets[bucket];
			// Removing reflective pairs
			complementBucket = [p | p <- complementBucket, p.L != p.R];
			// Cleanup symmetric clones, they are useless.
			complementBucket = removeSymmetricPairs(complementBucket);
				
			for (treeRelation <- complementBucket) {
				num similarity = calculateSimilarity(treeRelation[0][0], treeRelation[1][0])*1.0;
				println("similarityThreshold: <similarity>");
				if (similarity > similarityThreshold) {
					
					if (cloneClasses[treeRelation[0][0]]?) {
						cloneClasses[treeRelation[0][0]] += treeRelation;
					} else {
						cloneClasses[treeRelation[0][0]] = [treeRelation];
					}
				}
			}
		}
	}
	
	println("Done with finding clones from buckets and created cloneClasses.");
	println(printTime(now(), "HH:mm:ss"));
	
	// Loop through all the clone classes and remove all smaller subclones.
	for (currentClass <- cloneClasses) {
		for (currentClone <- cloneClasses[currentClass]) {
			checkForInnerClones(currentClone[0]);
			checkForInnerClones(currentClone[1]);
		}
	}
	
	println("Indexed all thesmaller subclones");
	println(printTime(now(), "HH:mm:ss"));
	
	// Remove the subclones one by one from the cloneClasses.
	for (subCloneClas <- subCloneClasses) {
		cloneClasses = delete(cloneClasses, subCloneClas);
	}
	
	println("Removed all subclones from the cloneClasses");
	println(printTime(now(), "HH:mm:ss"));
		
	set[loc] clonePairsPerClass = {};
	iprintln("Here come the clones!");
	for (currentClass <- cloneClasses) {
		iprintln("Total clone pairs in this class: <size(cloneClasses[currentClass])>");
		clonePairsPerClass = {};
		for (currentClone <- cloneClasses[currentClass]) {
			clonePairsPerClass += currentClone[0][1];
			clonePairsPerClass += currentClone[1][1];
		}
		for (uniqueClone <- clonePairsPerClass) {
			iprintln(uniqueClone);
		}
		iprintln("--------------------------------------------------");
	}
	
	//printCloneResults();
	
	// Step 2. Finding Clone Sequences
	// THIS IS WORK IN PROGRESS!!!
	findSequences(ast);
	
	//for (currentClass <- cloneClasses) {
	//	for (currentClone <- cloneClasses[currentClass]) {
	//		int a;
	//	}
	//}
	
	
	

	// Step 3. Generalizing clones
	/*
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
	*/
	//printCloneResults();
	
}

// Normalize all variable types of the leaves in a tree.
public node normalizeNodeDec(node ast) {
	return visit (ast) {
		case \Type(_) => \Type(char())
		case \Modifier(_) => \Type(\private())
		case \simpleName(_) => \simpleName("a")
		case \number(_) => \number("1")
		case \booleanLiteral(_) => \booleanLiteral(true)
		case \stringLiteral(_) => \stringLiteral("b")
		case \characterLiteral(_) => \characterLiteral("c")
	}
}

// Work in progess
public void findSequences(set[Declaration] ast) {
	blocks = [[<n, n@src> | n <- stmts] | /block(list[Statement] stmts) <- ast, size(stmts) >= 6];
	
	//iprintln("Total amount of sequences found: <size(blocks)>");
	for (block <- blocks) {
		// if the current block does not contain any clones then we remove it.
		if (!containsClone(block)) {
			//delete(blocks, indexOf(blocks,block));
			blocks = blocks - [block];
		}
	}
	//iprintln("Total amount of sequences left: <size(blocks)>");
}

public bool containsClone(list[tuple[node,loc]] block) {
	list[list[node]] sequences = [];
	list[node] tmpSequence = [];
	
	bool added = false;
		
	for (stmt <- block) {
		added = false;
		for (currentClass <- cloneClasses) {
			for (currentClone <- cloneClasses[currentClass]) {
				if (stmt[0] == currentClone[0][0] || stmt[0] == currentClone[1][0]) {
					//iprintln("Found a clone");
					//iprintln(currentClone[0][1]);
					added = true;
					tmpSequence += stmt[0];
					continue;
				}
			}
			if (added == true) {
				continue;
			}
		}
		
		if (added == false && size(tmpSequence) > 1) {
			//iprintln("Saving the current tmpSequence");
			sequences += [tmpSequence];
			tmpSequence = [];
		} else if (added == false && size(tmpSequence) == 1) {
			//iprintln("Resetting the current tmpSequence");
			tmpSequence = [];
		}
	}
	
	if (size(tmpSequence) > 0) {
		sequences += [tmpSequence];
	}
	
	/*
	for(seq <- sequences) {
		for(lol <- seq) {
			loc lal = getLocationOfNode(lol);
			iprintln(lal);
		}
	}
	*/
	
	iprintln("Size sequences: <size(sequences)>");
	
	if (size(sequences) > 1) {
		return true;
	} else {
		return false;
	}
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

// @TODO The performance of this method is super crap! Takes ages too finish!
public void checkForInnerClones(tuple[node,loc] tree) {
	visit (tree[0]) {
		case node x: {
			// Only if the tree is not equal to itself, and has a certain mass.
			if (x != tree[0] && calculateMass(x) >= massThreshold) {
				loc location = getLocationOfNode(x);
				if (location == currentProject) {
					continue;
				}
				tuple[node,loc] current = <x, location>;
				bool member = isMemberOfClones(current);
				if (member) {
					//cloneClasses = delete(cloneClasses, current[0]);
					subCloneClasses += x;
				}
			}
		}
	}
}

public bool isMemberOfClones(tuple[node,loc] current) {	

	for (currentcloneClass <- cloneClasses) {
		for (currentPair <- cloneClasses[currentcloneClass]) {
			if ((current[1] < currentPair[0][1] && currentPair[0][1] > current[1]) || (current[1] < currentPair[1][1] && currentPair[1][1] > current[1])) {
				if (size(cloneClasses[current[0]]) == size(cloneClasses[currentcloneClass])) {
					return true;
				}
			}	
		}
	}
	
	return false;
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
	loc location = currentProject;
	
	if (Declaration d := subTree) { 
		if (d@src?) {
			location = d@src;
		}
	} else if (Expression e := subTree) {
		if (e@src?) {
			location = e@src;
		}
	} else if (Statement s := subTree) {
		if (s@src?) {
			location = s@src;
		}
	} else if (Type t := subTree) {
		iprintln("WTF THIS IS A TYPE!");
	} else if (Modifier m := subTree) {
		iprintln("WTF THIS IS A MODIFIER!");
	} else {
		iprintln("WTF IS THIS?!");
	}
	
	return location;
}

public void addSubTreeToMap(node normalizedSubTree, node subTree) {

	loc location = getLocationOfNode(subTree);
	
	if (location == currentProject) {
		return;
	}
	
	if (buckets[normalizedSubTree]?) {
		buckets[normalizedSubTree] += <subTree,location>;
	} else {
		buckets[normalizedSubTree] = [<subTree,location>];
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