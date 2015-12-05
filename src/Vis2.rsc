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

public list[loc] filesInLocation = [];
//public lrel[loc,int] infoList = [];
public list[Figure] boxList = [];
public loc currentLocation;
public loc currentProject = |project://smallsql0.21_src|;

public void begin() {
	clearMemory();
	gotoCurrentLocation();
	createBoxList();
	createTreeMap();
}

public void clearMemory(){
	Vis::filesInLocation = [];
	//Vis::infoList = [];
	Vis::boxList = [];
}

public void gotoCurrentLocation() {
	Vis::currentLocation = Vis::currentProject + "src";
	while(size(Vis::currentLocation.ls) == 1){
		Vis::currentLocation = Vis::currentLocation.ls[0];
	}
}

public void createBoxList(){
	Vis::filesInLocation = Vis::currentLocation.ls;
	for(loc location <- Vis::filesInLocation){
		Vis::boxList += box(
							text(replaceFirst(location.path,Vis::currentLocation.path + "/",""))
						);
	}
}

public void createTreeMap(){
	t = treemap([
			box(
				vcat([
					text(toString(Vis::currentLocation)),
					treemap(Vis::boxList,shrink(0.95))
				])
			)
		]);
	render(t);
}




/*

public void createBoxInformation() {
	tuple[loc,int] boxInfo;
	for(loc location <- Vis::allJavaLoc){
		loc name = location;
		int LOC = size(readFileLines(location));
		boxInfo = <name,LOC>;
		Vis::infoList += [boxInfo];
	}
}

public void createBoxList() {
	//iprint(Vis::infoList);
	for(tuple[loc,int] n <- Vis::infoList){
		Vis::boxList += box(area(n[1]));	
	}
}

public void createTreeMap() {
	t = treemap(Vis::boxList);
	render(t);
}

from = color("White");
to = color("Red");
int maxLOC = 0;
for(tuple[str,int] n <- Vis::boxInformation){
	if(n[1] > maxLOC){
		maxLOC = n[1];
	}
}
for(tuple[str,int] n <- Vis::boxInformation){
	Vis::boxList += box(area(n[1]), fillColor(interpolateColor(from, to, (toReal(n[1]) / maxLOC))));	
}
*/