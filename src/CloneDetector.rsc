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
import util::Math;
import DateTime;

public loc currentProject = |project://TestProject|;

map[node,list[node]] buckets = ();

public void main() {
	iprintln("Lets Begin!");
	
	currentSoftware = createM3FromEclipseProject(currentProject);
	
	set[Declaration] ast = createAstsFromEclipseProject(currentProject, true);
		
	int massThreshold = 5;
	
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
	
	for (buck <- buckets) {
		if (size(buckets[buck]) >= 2) {
			iprintln(buckets[buck]);
			calculateSimilarity(buck, buck);
		}
	}
}

public int calculateSimilarity(node t1, node t2) {
	//Similarity = 2 x S / (2 x S + L + R)
	
	map[node,int] tree1 = ();
	map[node,int] tree2 = ();
	
	visit (t1) {
		case node x: {
			tree1[x] = 1;
		}
	}
	
	visit (t2) {
		case node x: {
			tree2[x] = 1;
		}
	}
	
	iprintln(tree1+tree2 == tree1);
	
	return 1;
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