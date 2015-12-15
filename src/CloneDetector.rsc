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
import UnitTests;
import Config;
import Vis;

public map[node, lrel[node, loc]] buckets = ();
public map[node, lrel[tuple[node, loc], tuple[node, loc]]] cloneClasses = ();
public list[node] subCloneClasses = [];

public list[loc] allFiles = [];
public lrel[loc location,int LOC, real percentage, set[loc] clones] fileInformation = [];

public set[Declaration] ast;

public int massThreshold;
public real similarityThreshold;
public int cloneType;

public void main(int cloneT) {
	cloneType = cloneT;
	
	massThreshold = 25;
	
	iprintln("Attack of the clones!");
	println(printTime(now(), "HH:mm:ss"));
	
	buckets = ();
	cloneClasses = ();
	subCloneClasses = [];
	fileInformation = [];
	allFiles = [];
	
	currentSoftware = createM3FromEclipseProject(currentProject);
	
	ast = createAstsFromEclipseProject(currentProject, true);

	if (cloneType == 1) {
		similarityThreshold = 1.0;
	} else if(cloneType == 2) {
		similarityThreshold = 1.0;
	} else if(cloneType == 3) {
		similarityThreshold = 0.80;
	}
	
	// Add all the subtrees with a mass higher than the massThreshold into a bucket.
	// Depening on the clone type we want to find, we normalize the subtrees.
	visit (ast) {
		case node x: {
			int currentMass = calculateMass(x);
			if (currentMass >= massThreshold) {
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
				if (cloneType == 3) {
					if (cloneClasses[treeRelation[0][0]]?) {
						cloneClasses[treeRelation[0][0]] += treeRelation;
					} else {
						cloneClasses[treeRelation[0][0]] = [treeRelation];
					}
				} else {
					num similarity = calculateSimilarity(treeRelation[0][0], treeRelation[1][0])*1.0;
					//println("Similarity: <similarity> \>= <similarityThreshold>");
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
	
	printCloneResults();
	
	allFiles = getAllJavaFiles();

	fileInformation = transfer(cloneClasses, allFiles);
}

// Normalize all variable types of the leaves in a tree.
public node normalizeNodeDec(node ast) {
	return visit (ast) {
		case \method(x, _, y, z, q) => \method(lang::java::jdt::m3::AST::short(), "methodName", y, z, q)
		case \method(x, _, y, z) => \method(lang::java::jdt::m3::AST::short(), "methodName", y, z)
		case \parameter(x, _, z) => \parameter(x, "paramName", z)
		case \vararg(x, _) => \vararg(x, "varArgName") 
		case \annotationTypeMember(x, _) => \annotationTypeMember(x, "annonName")
		case \annotationTypeMember(x, _, y) => \annotationTypeMember(x, "annonName", y)
		case \typeParameter(_, x) => \typeParameter("typeParaName", x)
		case \constructor(_, x, y, z) => \constructor("constructorName", x, y, z)
		case \interface(_, x, y, z) => \interface("interfaceName", x, y, z)
		case \class(_, x, y, z) => \class("className", x, y, z)
		case \enumConstant(_, y) => \enumConstant("enumName", y) 
		case \enumConstant(_, y, z) => \enumConstant("enumName", y, z)
		case \methodCall(x, _, z) => \methodCall(x, "methodCall", z)
		case \methodCall(x, y, _, z) => \methodCall(x, y, "methodCall", z) 
		case Type _ => lang::java::jdt::m3::AST::short()
		case Modifier _ => lang::java::jdt::m3::AST::\private()
		case \simpleName(_) => \simpleName("simpleName")
		case \number(_) => \number("1337")
		case \variable(x,y) => \variable("variableName",y) 
		case \variable(x,y,z) => \variable("variableName",y,z) 
		case \booleanLiteral(_) => \booleanLiteral(true)
		case \stringLiteral(_) => \stringLiteral("StringLiteralThingy")
		case \characterLiteral(_) => \characterLiteral("q")
	}
}

public void printCloneResults() {
	println();
	
	int counting = 0;
	
	set[loc] clonePairsPerClass = {};
	iprintln("Here come the clones!");
	for (currentClass <- cloneClasses) {
		iprintln("Total clone pairs in this class: <size(cloneClasses[currentClass])>");
		clonePairsPerClass = {};
		for (currentClone <- cloneClasses[currentClass]) {
			clonePairsPerClass += currentClone[0][1];
			clonePairsPerClass += currentClone[1][1];
			counting += 1;
		}
		for (uniqueClone <- clonePairsPerClass) {
			iprintln(uniqueClone);
		}
		iprintln("--------------------------------------------------");
	}
	
	iprintln("Total amount of clone pairs: <counting>");
}

public void checkForInnerClones(tuple[node,loc] tree) {
	visit (tree[0]) {
		case node x: {
			// Only if the tree is not equal to itself, and has a certain mass.
			if (x != tree[0]) {
				if (calculateMass(x) >= massThreshold) {
					loc location = getLocationOfNode(x);
					bool doIt = true;
					if (location == currentProject) {
						doIt = false;
					}
					if (doIt) {
						tuple[node,loc] current = <x, location>;
						bool member = isMemberOfClones(current);
						
						if (member) {
							if(cloneType == 1) {
								subCloneClasses += x;
							} else {
								subCloneClasses += normalizeNodeDec(x);
							}
						}
					}
				}
			}
		}
	}
}

public bool isMemberOfClones(tuple[node,loc] current) {

	for (currentcloneClass <- cloneClasses) {
		for (currentPair <- cloneClasses[currentcloneClass]) {
			if ((current[1] <= currentPair[0][1] && currentPair[0][0] == current[0]) || (current[1] <= currentPair[1][1] && currentPair[1][0] == current[0])) {
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
	}
	
	return location;
}

public bool minimumCloneSizeCheck(loc key) {
	if (key.end.line - key.begin.line >= 6) {
		return true;
	}
	return false;
}

public void addSubTreeToMap(node key, node subTree) {

	loc location = getLocationOfNode(subTree);
	
	if (location == currentProject) {
		return;
	}
	
	if (minimumCloneSizeCheck(location) == false) {
		return;
	}
	
	if (cloneType == 3) {
		int totalB = size(buckets);
		int i = 0;
		
		node bestKeyMatch;
		num highestSimilarity = 0;
		for (buck <- buckets) {
			i += 1;
			num currentSimilarity = calculateSimilarity(buck, key);
			if (currentSimilarity >= similarityThreshold && currentSimilarity > highestSimilarity) {
				highestSimilarity = currentSimilarity;
				bestKeyMatch = buck; 
			}
		}
		
		if (highestSimilarity > 0) {
			key = bestKeyMatch;
		}
	}
	
	if (buckets[key]?) {
		if(cloneType == 3) {
			bool doIt = true;
			for (clonePair <- buckets[key]) {
				if (location < clonePair[1]) {
					doIt = false;
					break;
				} else if (clonePair[1] < location) {
					buckets[key] = buckets[key] - clonePair; 
				}
			}
		
			if (doIt == true) {
				buckets[key] += <subTree,location>;
			}
		} else {
			buckets[key] += <subTree,location>;
		}
	} else {
		buckets[key] = [<subTree,location>];
	}
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

public set[loc] getCloneClass(loc clone){
	set[set[loc]] allClonePairs = {
		{
			*{clonePair[0][1], clonePair[1][1]}
		|
			clonePair <- cloneClasses[cloneClass]
		}
	|
		cloneClass <- cloneClasses
	};
	for(set[loc] A <- allClonePairs){
		if(clone in A){
			return A;
		}
	}
	return {};
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
		int linesOfFile = computeLOC(file);
		int linesOfClones = 0;
		real percentage = 0.0;
		set[loc] clones = {};
		for(clone <- allClones){
			if(file == toLocation(clone.uri)){
				linesOfClones += computeLOC(clone);
				clones += clone;
			}
		}
		percentage = toReal(linesOfClones) / toReal(linesOfFile);
		result += <file, linesOfFile, percentage, clones>; 
	}
	return result;
}

public list[loc] getAllJavaFiles() {
	return crawl(currentProject2, ".java");
} 