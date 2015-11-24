module CloneDetector

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import demo::common::Crawl;
import IO;
import List;
import Tuple;
import Type;
import String;
import Relation;
import util::Math;
import DateTime;

public loc currentProject = |project://TestProject|;

public void main() {
	iprintln("Lets Begin!");
	
	currentSoftware = createM3FromEclipseProject(currentProject);
	
	set[Declaration] ast = createAstsFromEclipseProject(currentProject, true);
		
	int massThreshold = 3;
	
	visit (ast) {
		case node x: {
			iprintln("Mass: <calculateMass(x)>");
			if (calculateMass(x) >= massThreshold) {
				int occurrences = findSubTrees(ast, x);
				iprintln("Occurrences: <occurrences>");
			}
		}
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