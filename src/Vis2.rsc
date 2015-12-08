module Vis2

import vis::Figure;
import vis::Render; 
import vis::KeySym;
import Prelude;
import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import IO;
import List;
import ListRelation;
import Tuple;
import String;
import Relation;
import util::Math;
import demo::common::Crawl;
import DateTime;

public int projectNamelength;
public list[loc] allJavaLoc;
public lrel[str,int] boxInformation = [];
public list[Figure] boxList = [];

public loc currentProject = |project://smallsql0.21_src/|;
//public loc currentProject = |project://hsqldb-2.3.1|;

/**
 *	Counts a treemap for the currentProject.
 */
public void begin() {
	calculateNamelength();
	getAllJavaFiles();
	createBoxInformation();
	createBoxList();
	createTreeMap();
}

/**
 *	Calculate the length of the currentProject, keep "/" at last position in mind. 
 */
public void calculateNamelength() {
	str projectName = toString(Vis2::currentProject);
	Vis2::projectNamelength = size(projectName);
	if(projectName[(Vis2::projectNamelength - 2)] == "/"){
		Vis2::projectNamelength -= 1;
	}
}

/**
 *	Create list of all .java files in currentProject
 */
public void getAllJavaFiles() {
	Vis2::allJavaLoc = crawl(Vis2::currentProject, ".java");
}

/**
 *	Create list with name and LOC for every file.
 */
public void createBoxInformation() {
	for(loc n <- Vis2::allJavaLoc){
		str name = toString(n)[(Vis2::projectNamelength)..-1];
		int LOC = size(readFileLines(n));
		tuple[str,int] boxInfo = <name,LOC>;
		Vis2::boxInformation += [boxInfo];
	}
}

/**
 *	Create list with boxes for every file.
 */
public void createBoxList() {
	from = color("White");
	to = color("Red");
	int maxLOC = 0;
	for(tuple[str,int] n <- Vis2::boxInformation){
		if(n[1] > maxLOC){
			maxLOC = n[1];
		}
	}
	for(tuple[str,int] n <- Vis2::boxInformation){
		Vis2::boxList += box(area(n[1]), fillColor(interpolateColor(from, to, (toReal(n[1]) / maxLOC))));	
	}
}

/**
 *	Create treemap with list of boxes for every file.
 */
public void createTreeMap() {
	t = treemap(Vis2::boxList);
	render(t);
}
