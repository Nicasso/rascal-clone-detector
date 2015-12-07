module Temp

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

map[node,lrel[node,loc]] buckets = ();
lrel[tuple[node,loc],tuple[node,loc]] clonePairs = [];
lrel[tuple[node,loc],tuple[node,loc]] newClonePairs = [];
public list[list[Statement]] blocks = [];

public void main() {
	iprintln("Let us Begin!");
	
	buckets = ();
	clonePairs = [];
	
	currentSoftware = createM3FromEclipseProject(currentProject);
	
	set[Declaration] ast = createAstsFromEclipseProject(currentProject, true);
		
	sequenceDetection(ast);
		
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
	//iprintln(size(blocks));
	//for (block <- blocks){
	//	for(stmt <- block){
	//		iprintln(stmt);
	//	}
	//}
	
	for (bucket <- buckets) {
		if (size(buckets[bucket]) >= 2) {
			lrel[tuple[node,loc] L, tuple[node,loc] R] complementBucket = [];
			complementBucket += buckets[bucket] * buckets[bucket];
			
			//iprintln(size(complementBucket));
			
			complementBucket = [p | p <- complementBucket, p.L != p.R];
						
			//iprintln(size(complementBucket));
									
			for (treeRelation <- complementBucket) {
				//iprintln(treeRelation);
				int similarity = calculateSimilarity(treeRelation[0][0], treeRelation[1][0]);
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
	
	
	// Remove one of the symmetric pairs (a,b) & (b,a) should result in only one of the two.
	//lrel[tuple[node,loc],tuple[node,loc]] newClonePairs = [];
	for (pair <- clonePairs) {
		tuple[tuple[node,loc],tuple[node,loc]] reversePair = <<pair[1][0],pair[1][1]>,<pair[0][0],pair[0][1]>>;
		if (reversePair notin newClonePairs) {		
			newClonePairs += pair;
		}

	}
	//for(pair <- newClonePairs){
	//	iprintln(pair[0][1]);
	//	iprintln(pair[1][1]);
	//}
	iprintln(size(newClonePairs));
}

public void isMemberOfClones(node target) {
	for (relation <- clonePairs) {
		if (target == relation[0] || target == relation[1]) {
			clonePairs = clonePairs - relation;
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

public void sequenceDetection(set[Declaration] decls){
	blocks = [stmts | /block(list[Statement] stmts) <- decls, size(stmts) >= 6];
	iprintln(size(blocks));
	for(block <- blocks){
	//if the current block does not contain any clones then we remove it.
		if(!containsClone(block)){
			//delete(blocks, indexOf(blocks,block));
			blocks = blocks - [block];
			}
	}
	iprintln(size(blocks));
}

public bool containsClone(list[Statement] block){
	for(stmt <- block){
		for(pair <- newClonePairs){
			if(stmt == pair[0][0] || stmt == pair[1][0])
				return true;
		}
	}
	return false;
}