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

public loc currentProject = |project://TestProject|;

map[node,list[node]] buckets = ();
lrel[node,node] clonePairs = [];

public void main() {
	iprintln("Lets Begin!");
	
	currentSoftware = createM3FromEclipseProject(currentProject);
	
	set[Declaration] ast = createAstsFromEclipseProject(currentProject, true);
		
	int massThreshold = 5;
	real similarityThreshold = 0.5;
	
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
			lrel[node,node] complementBucket = [];
			complementBucket += buckets[bucket] * buckets[bucket];
			
			//iprintln([ <x,y> | <x,y> <- complementBucket, x != y]);
			
			for (treeRelation <- complementBucket) {
				//iprintln(treeRelation);
				int similarity = calculateSimilarity(treeRelation[0], treeRelation[1]);
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
}

public void isMemberOfClones(node target) {
	for (relation <- clonePairs) {
		if (target == relation[0] || target == relation[1]) {
			clonePairs - relation;
		} 
	}
}

public int calculateSimilarity(node t1, node t2) {
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
	
	int s = size(tree1 & tree2);
	int l = size(tree1 - tree2);
	int r = size(tree2 - tree1); 
		
	int similarity = (2 * s) / (2 * s + l + r); 
	
	return similarity;
}

public void addSubTreeToMap(node subTree) {
	if (buckets[subTree]?) {
		buckets[subTree] += subTree;
	} else {
		buckets[subTree] = [subTree];
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