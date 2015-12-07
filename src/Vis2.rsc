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
public loc currentProject = |home:///Documents/Eclipse%20Workspace/smallsql0.21_src|;
//public loc currentProject = |home:///Documents/Eclipse%20Workspace/hsqldb-2.3.1|;
//public loc currentProject = |home:///Documents/Eclipse%20Workspace/Project%20Application%20Development|;

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
								if(Vis2::currentLocation == Vis2::currentProject){
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
							//text(replaceFirst(location.path,Vis2::currentLocation.path + "/", ""), fontSize(2)),
							area(size(readFileLines(location)))
							,onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
								iprintln(tmploc);
								return true;
							})
						);
		}else if(contains(location.extension, "/") || location.extension == ""){
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
			box(text(toString(Vis2::currentLocation)), vshrink(0.04)),
			box(treemap(Vis2::mapBoxList), vshrink(0.04)),
			box(treemap(Vis2::fileBoxList),vshrink(0.92))
		]);
	render(t);
}
