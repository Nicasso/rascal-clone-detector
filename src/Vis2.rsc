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
	Vis2::filesInLocation = [];
	//Vis2::infoList = [];
	Vis2::boxList = [];
}

public void gotoCurrentLocation() {
	Vis2::currentLocation = Vis2::currentProject + "src";
	while(size(Vis2::currentLocation.ls) == 1){
		Vis2::currentLocation = Vis2::currentLocation.ls[0];
	}
}

public void createBoxList(){
	Vis2::filesInLocation = Vis2::currentLocation.ls;
	for(loc location <- Vis2::filesInLocation){
		Vis2::boxList += box(
							text(replaceFirst(location.path,Vis2::currentLocation.path + "/",""))
						);
	}
}

public void createTreeMap(){
	t = treemap([
			box(
				vcat([
					text(toString(Vis2::currentLocation)),
					treemap(Vis2::boxList,shrink(0.95))
				])
			)
		]);
	render(t);
}




/*

public void createBoxInformation() {
	tuple[loc,int] boxInfo;
	for(loc location <- Vis2::allJavaLoc){
		loc name = location;
		int LOC = size(readFileLines(location));
		boxInfo = <name,LOC>;
		Vis2::infoList += [boxInfo];
	}
}

public void createBoxList() {
	//iprint(Vis2::infoList);
	for(tuple[loc,int] n <- Vis2::infoList){
		Vis2::boxList += box(area(n[1]));	
	}
}

public void createTreeMap() {
	t = treemap(Vis2::boxList);
	render(t);
}

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
*/