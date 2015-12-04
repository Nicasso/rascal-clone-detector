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
public lrel[str,int] boxInformation = [];
public list[Figure] boxList;

public loc currentProject = |project://smallsql0.21_src/|;

public void begin() {
	calculateNamelength();
	getAllJavaFiles();
	createBoxInformation();
	createBoxList();
	createTreeMap();
}

public void calculateNamelength() {
	str projectName = toString(Vis::currentProject);
	Vis::projectNamelength = size(projectName);
	if(projectName[(Vis::projectNamelength - 2)] == "/"){
		Vis::projectNamelength -= 1;
	}
}

public void getAllJavaFiles() {
	Vis::allJavaLoc = crawl(Vis::currentProject, ".java");
}

public void createBoxInformation() {
	for(loc n <- allJavaLoc){
		str name = toString(n)[(Vis::projectNamelength)..-1];
		int LOC = 10;
		tuple[str,int] boxInfo = <name,LOC>;
		Vis::boxInformation += [boxInfo];
	}
	iprint(Vis::boxInformation[0]);
}

public void createBoxList() {
	Vis::boxList = for(tuple[str,int] n <- Vis::boxInformation) append box();
}

public void createTreeMap() {
	t = treemap(Vis::boxList);
	render(t);
}