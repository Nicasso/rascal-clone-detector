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
lrel[tuple[node,loc],tuple[node,loc]] clonePairs = [];
lrel[tuple[node,loc],tuple[node,loc]] clonesToGeneralize = [];
set[Declaration] ast;

public void main() {
	iprintln("Lets Begin!");
	
	buckets = ();
	clonePairs = [];
	
	currentSoftware = createM3FromEclipseProject(currentProject);
	
	ast = createAstsFromEclipseProject(currentProject, true);
		
	int massThreshold = 8;
	real similarityThreshold = 0.75;
		
	visit (ast) {
		case node x: {
			//iprintln("Mass: <calculateMass(x)>");
			if (calculateMass(x) >= massThreshold) {
				//int occurrences = findSubTrees(ast, x);
				//iprintln("Occurrences: <occurrences>");
				addSubTreeToMap(x);
			}
		}
	}
	
	for (bucket <- buckets) {
		if (size(buckets[bucket]) >= 2) {
			lrel[tuple[node,loc] L, tuple[node,loc] R] complementBucket = [];
			complementBucket += buckets[bucket] * buckets[bucket];
			
			complementBucket = [p | p <- complementBucket, p.L != p.R];
									
			for (treeRelation <- complementBucket) {
				//iprintln(treeRelation);
				num similarity = calculateSimilarity(treeRelation[0][0], treeRelation[1][0]);
				//iprintln(similarity);
				if (similarity > similarityThreshold) {
					
					visit (treeRelation[0]) {
						case node x: {
							isMemberOfClones(x);
						}
					}
					
					visit (treeRelation[1]) {
						case node x: {
							isMemberOfClones(x);
						}
					}
					
					clonePairs += treeRelation;
				}
			}
		}
	}
	
	clonePairs = removeSymmetricPairs(clonePairs);

	// Generalizing clones
	
	clonesToGeneralize = clonePairs;
	
	for (currentClonePair <- clonesToGeneralize) {
		clonesToGeneralize = clonesToGeneralize - currentClonePair;
		
		list[node] parents = getParentsOfClone(currentClonePair[0][0]);
		
		// Dunno if this is required, but lets keep it for now just to be sure.
		parents += getParentsOfClone(currentClonePair[1][0]);
		parents = dup(parents);
		
		lrel[node,loc] parentsPairs = [];
		for (parent <- parents) {
			loc parentLocation = getLocationOfNode(parent);
			parentsPairs += <parent, parentLocation>;
		}
				
		lrel[tuple[node,loc] L, tuple[node,loc] R] complementParents = [];
		complementParents += parentsPairs * parentsPairs;
		
		complementParents = [p | p <- complementParents, p.L != p.R];
		complementParents = removeSymmetricPairs(complementParents);
		
		for (parentRelation <- complementParents) {
			num similarity = calculateSimilarity(parentRelation[0][0],parentRelation[1][0]);
			if (similarity > similarityThreshold) {
				clonePairs = clonePairs - currentClonePair;
				
				clonePairs += parentRelation; 
				clonesToGeneralize += parentRelation;
			}
		}
	}
		
	iprintln("CLONES");
	for (pair <- clonePairs) {
		iprintln(pair[0][1]);
		iprintln(pair[1][1]);
		iprintln("NEXT!");
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
	
	top-down visit (ast) {
		case current: {
			list[value] context = getTraversalContext();
			
			if (node x := context[2]) {
				//iprintln("FOUND PARENT");
				parents += x;
			} 
			//iprintln(getLocationOfValue(context[2]));
			//iprintln("NEXT");
			//iprintln("--------------------------------------------------------------------------------------");
		}
	}
	
	return parents;
}

public void isMemberOfClones(node target) {
	for (relation <- clonePairs) {
		if (target == relation[0] || target == relation[1]) {
			clonePairs = clonePairs - relation;
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
		iprintln("WTF GEEN LOCATION?!");
	}
	
	return location;
}

public void addSubTreeToMap(node subTree) {

	loc location = getLocationOfNode(subTree);
	
	//iprintln(location);

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