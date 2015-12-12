module CloneDetector

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import demo::common::Crawl;
import util::Math;
import IO;
import List;
import Map;
import Tuple;
import Type;
import Set;
import Prelude;
import String;
import Relation;
import ListRelation;
import util::Math;
import DateTime;
import Traversal;
import Helper;

public loc currentProject = |project://TestProject|;
//public loc currentProject = |project://smallsql0.21_src|;
//public loc currentProject2 = |file:///C:/Users/Ardavan/RCPworkspace/smallsql0.21_src|;
public loc currentProject2 = |project://TestProject|;
//public loc currentProject = |project://hsqldb-2.3.1|;

map[node, lrel[node, loc]] buckets = ();
map[node, lrel[tuple[node, loc], tuple[node, loc]]] cloneClasses = ();
map[node, lrel[tuple[node, loc], tuple[node, loc]]] toBeRemoved = ();
map[list[node], list[lrel[tuple[node, loc], tuple[node, loc]]]] cloneSequences = ();
list[node] subCloneClasses = [];
//map[list[Statement],list[Statement]] allSequences = ();
list[lrel[node,loc]] allSequences = [];

list[loc] allFiles = [];
public lrel[loc location,int LOC, real percentage, set[loc] clones] fileInformation = [];

lrel[tuple[node,loc],tuple[node,loc]] clonesToGeneralize = [];
set[Declaration] ast;

int massThreshold;
real similarityThreshold;
int cloneType;

public void main(int cloneT) {
	cloneType = cloneT;
	
	iprintln("Attack of the clones!");
	println(printTime(now(), "HH:mm:ss"));
	
	buckets = ();
	cloneClasses = ();
	subCloneClasses = [];
	allSequences = [];
	clonesToGeneralize = [];
	
	toBeRemoved = ();

	currentSoftware = createM3FromEclipseProject(currentProject);
	
	ast = createAstsFromEclipseProject(currentProject, true);
		

	massThreshold = 5;
	if (cloneType == 1) {
	    similarityThreshold = 1.0;
  	} else if(cloneType == 2) {
	    similarityThreshold = 1.0;
  	} else if(cloneType == 3) {
		similarityThreshold = 0.75;
  	}
	
	// Step 1. Finding Sub-tree Clones
	
	// Add all the subtrees with a decent mass to a bucket.
	visit (ast) {
		case node x: {
			if (calculateMass(x) >= massThreshold) {
				if (cloneType == 1) {
					addSubTreeToMap(x, x);
				} else if (cloneType == 2) {
					node normalizedNode = normalizeNodeDec(x);
					addSubTreeToMap(normalizedNode, normalizedNode);
				} else if (cloneType == 3) {
					node normalizedNode = normalizeNodeDec(x);
					addSubTreeToMap(normalizedNode, normalizedNode);
				}
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
				//println("similarityThreshold: <similarity>");
				if (similarity >= similarityThreshold) {
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
	
	// Removing all clones pairs with only one file
	// @TODO Good or bad?
	set[loc] amountOfClonePairsPerClass = {};
	for (currentClass <- cloneClasses) {
		amountOfClonePairsPerClass = {};
		for (currentClone <- cloneClasses[currentClass]) {
			amountOfClonePairsPerClass += currentClone[0][1];
			amountOfClonePairsPerClass += currentClone[1][1];
		}
		if (size(amountOfClonePairsPerClass) == 1) {
			cloneClasses = delete(cloneClasses, currentClass);
		}
	}
		
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
	/*
	iprintln("SEQUENCES!");
	for (key <- cloneSequences) {
		iprintln("Sequence Class");
		for (seq <- cloneSequences[key]) {
			iprintln("Single sequence");
			for (lol <- seq) {
				iprintln(lol[0][1]);
				iprintln(lol[1][1]);
				iprintln("-------------------------------------------------------------------------");
			}
		}
	}
	*/
	
	allFiles = getAllJavaFiles();
	
	fileInformation = transfer(cloneClasses, allFiles);
	
	iprintln(fileInformation);
	
}

// Normalize all variable types of the leaves in a tree.
public node normalizeNodeDec(node ast) {
	return visit (ast) {
		case \Type(_) => \Type(char())
		case \Modifier(_) => \Type(\private())
		case \simpleName(_) => \simpleName("simpleName")
		case \number(_) => \number("1337")
		case \variable(x,y) => \variable("variableName",y) 
		case \variable(x,y,z) => \variable("variableName",y,z) 
		case \booleanLiteral(_) => \booleanLiteral(true)
		case \stringLiteral(_) => \stringLiteral("StringLiteralThingy")
		case \characterLiteral(_) => \characterLiteral("q")
	}
}

// Work in progess
public void findSequences(set[Declaration] ast) {
	list[lrel[node,loc]] blocks = [];
	
	if (cloneType == 1) {
		blocks = [[<n, n@src> | n <- stmts] | /block(list[Statement] stmts) <- ast, size(stmts) >= 6];
	} else if (cloneType == 2 || cloneType == 3) {
		blocks = [[<normalizeNodeDec(n), n@src> | n <- stmts] | /block(list[Statement] stmts) <- ast, size(stmts) >= 6];
	}
		
	for (block <- blocks) {
		// if the current block does not contain any clones then we remove it.
		if (!containsClone(block)) {
			blocks = blocks - [block];
		}
	}
}

public void addCloneSequence(list[node] key, lrel[tuple[node, loc], tuple[node, loc]] sequence) {
	if (cloneSequences[key]?) {
		if (!checkExistanceCloneSequence(sequence)) {
			//iprintln("APPEND NEW SEQUENCE");
			cloneSequences[key] += [sequence];
		}
	} else {
		//iprintln("CREATE FIRST SEQUENCE");
		cloneSequences[key] = [sequence];
	}
}

public bool checkExistanceCloneSequence(lrel[tuple[node, loc], tuple[node, loc]] target) {
	for (sequenceClass <- cloneSequences) {
		for (sequence <- cloneSequences[sequenceClass]) {
			if (target == sequence) {
				return true;
			}
		}
	}
	return false;
}

public bool containsClone(list[tuple[node,loc]] block) {
	lrel[tuple[node, loc], tuple[node, loc]] tmpSequence = [];
	
	list[node] currentKey = [];
	
	bool added = false;
	bool containsClones = false;
	
	//iprintln("CONTAINSCLONES");		
	
	for (stmt <- block) {
		added = false;
		//iprintln(stmt[1]);
		for (currentClass <- cloneClasses) {
			for (currentClone <- cloneClasses[currentClass]) {
				if (stmt[0] == currentClone[0][0] || stmt[0] == currentClone[1][0]) {
					added = true;
					tmpSequence += currentClone;
					//iprintln("Found a clone!");
					currentKey += stmt[0];
					// REALLY? DOES THIS MAKE UNIQUE SEQUENCES?
					cloneClasses[currentClass] = cloneClasses[currentClass] - currentClone;

					if (size(cloneClasses[currentClass]) == 0) {
						cloneClasses = delete(cloneClasses, currentClass);
					}
					break;
				}
			}
			
			if (added == true) {
				break;
			}
		}
		
		if (added == false && size(tmpSequence) > 1) {
			//iprintln("Saving the current tmpSequence");
			addCloneSequence(currentKey, tmpSequence);
			containsClones = true;
			
			tmpSequence = [];
			currentKey = [];
		} else if (added == false && size(tmpSequence) == 1) {
			//iprintln("Resetting the current tmpSequence");
			tmpSequence = [];
			currentKey = [];
		}
	}
	
	if (size(tmpSequence) > 0) {
		addCloneSequence(currentKey, tmpSequence);
		containsClones = true;
	}
		
	return containsClones;
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
				if (cloneClasses[current[0]]?) {
					if (size(cloneClasses[current[0]]) == size(cloneClasses[currentcloneClass])) {
						return true;
					}
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

public void addSubTreeToMap(node key, node subTree) {

	//if (cloneType == 3) {
	//	key = checkForSimilarBucket(key);
	//}

	loc location = getLocationOfNode(subTree);
	
	if (location == currentProject) {
		return;
	}
	
	if (buckets[key]?) {
		buckets[key] += <subTree,location>;
	} else {
		buckets[key] = [<subTree,location>];
	}
}

public node checkForSimilarBucket(node normalizedSubTreeKey) {
	lrel[node, loc] highestSimilarityBucket;
	real highestSimilarity = 0.00;
	
	for (bucket <- buckets) {
		real similarity = calculateSimilarity(bucket, normalizedSubTreeKey)*1.0;
		if (similarity >= similarityThreshold && similarity > highestSimilarity) {
			highestSimilarity = similarity;
			highestSimilarityBucket = bucket;
		}
	}
		
	if (highestSimilarity > 0) {
		return highestSimilarityBucket;
	} else {
		return normalizedSubTreeKey;
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

public lrel[loc,int, real,set[loc]] transfer(map[node, lrel[tuple[node,loc],tuple[node,loc]]] cloneClasses, list[loc] allFiles){
	lrel[loc,int, real,set[loc]] result = [];
	set[loc] allClones = {};
	for(cloneClass <- cloneClasses){
		for(clonePair <- cloneClasses[cloneClass]){
			allClones += clonePair[0][1];
			allClones += clonePair[1][1];
		}
	}
	for(file <- allFiles){
		real linesOfFile = computeLOC(file);
		real linesOfClones = 0.0;
		real percentage = 0.0;
		set[loc] clones = {};
		for(clone <- allClones){
			iprintln(file);
			iprintln(toLocation(clone.uri));
			println();
			if(file == toLocation(clone.uri)){
				linesOfClones += computeLOC(clone);
				clones += clone;
			}
		}
		percentage = linesOfClones/linesOfFile;
		result += <file, linesOfFile, percentage, clones>; 
	}
	return result;
	//set[set[loc]] allClones = {
	//	{
	//		*{clonePair[0][1], clonePair[1][1]}
	//	|
	//		clonePair <- cloneClasses[cloneClass]
	//	}
	//|
	//	cloneClass <- cloneClasses
	//};
	//for(cloneClass <- allClones){
	//	lrel[loc,int,loc,int] temp = [];
	//		for(location <- cloneClass){
	//			 //<location of clone,
	//			 // number of lines for the clone,
	//			 // location of it's parent,
	//			 // number of lines for the parent>
	//			loc parent = toLocation(location.uri); 
	//			temp += <location, computeLOC(location), parent, computeLOC(parent)>;   
	//		}
	//	result += [temp];
	//}
}

public list[loc] getAllJavaFiles() {
	return crawl(currentProject2, ".java");
} 