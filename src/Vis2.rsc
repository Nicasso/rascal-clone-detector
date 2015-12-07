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
public list[Figure] fileBoxList = [];
public list[Figure] mapBoxList = [];
public loc currentLocation;
public loc currentProject = |project://smallsql0.21_src/src|;
//public loc currentProject = |project://hsqldb-2.3.1/hsqldb|;

public void begin() {
	clearMemory();
	gotoCurrentLocation();
	createBoxList();
	createTreeMap();
}

public void clearMemory(){
	Vis2::filesInLocation = [];
	Vis2::fileBoxList = [];
	Vis2::mapBoxList = [];
}

public void gotoCurrentLocation() {
	Vis2::currentLocation = Vis2::currentProject;
}

public void createBoxList(){
	Vis2::filesInLocation = Vis2::currentLocation.ls;
							Vis2::mapBoxList += box(
							text("..."),
							fillColor("Yellow"),
							onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
								if(Vis2::currentLocation == Vis2::currentProject + "src"){
									return true;
								} else{
									Vis2::currentLocation = Vis2::currentLocation.parent;
									clearMemory();
									createBoxList();
									createTreeMap();
									return true;
								}
							})
						);
	for(loc location <- Vis2::filesInLocation){
		loc tmploc = location;
		if(location.extension == "java"){
			Vis2::fileBoxList += box(
							area(size(readFileLines(location))),
							//text(replaceFirst(location.path,Vis2::currentLocation.path + "/", ""), fontSize(10)),
							onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
								Vis2::currentLocation = tmploc;
								clearMemory();
								createBoxList();
								createTreeMap();
								return true;
							})
						);
		}else{
			Vis2::mapBoxList += box(
							text(replaceFirst(location.path,Vis2::currentLocation.path,"")),
							fillColor("Yellow"),
							onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
								Vis2::currentLocation = tmploc;
								clearMemory();
								createBoxList();
								createTreeMap();
								return true;
							})
						);
		}
	}
}

public void createTreeMap(){
	t = vcat([
			box(text(toString(Vis2::currentLocation)), vshrink(0.01)),
			box(treemap(Vis2::mapBoxList), vshrink(0.04)),
			box(treemap(Vis2::fileBoxList))
		]);
	render(t);
}
