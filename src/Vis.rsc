module Vis

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
public lrel[str,int] boxInformation;
public list[Figure] boxList;

public loc currentProject = |project://smallsql0.21_src/|;

public void begin() {
	calculateNamelength(Vis::currentProject);
	getAllJavaFiles();
	createBoxInformation();
	Vis::boxList = createBoxList(boxInformation);
	treeMap();
}

public void calculateNamelength(loc project) {
	str projectName = toString(project);
	Vis::projectNamelength = size(projectName);
	if(projectName[(Vis::projectNamelength - 2)] == "/"){
		Vis::projectNamelength -= 1;
	}
}

public void getAllJavaFiles() {
	allJavaLoc = crawl(Vis::currentProject, ".java");
}

public void createBoxInformation() {
	boxInformation = [];
	for(loc n <- allJavaLoc){
		str name = toString(n)[(Vis::projectNamelength)..-1];
		int LOC = 10;
		rel[str,int] boxInfo = <name,LOC>;
		boxInformation += boxInfo;
	}
}

public list[Figure] createBoxList(lrel[str,int] boxInformation) {
	return for(str n <- boxInformation[0]) append box();
}

public void treeMap() {
	t = treemap(Vis::boxList);
	render(t);
}