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

public list[loc] filesInLocation = [];
public list[Figure] fileBoxList = [];
public list[Figure] dirBoxList = [];
public loc currentProject = |home:///Documents/Eclipse%20Workspace/smallsql0.21_src|;
public loc currentLocation = Vis::currentProject;

public void begin() {
	clearMemory();
	createGoUpDirBox();
	createFileAndDirBoxes();
	createTreeMap();
}

public void clearMemory(){
	Vis::filesInLocation = [];
	Vis::fileBoxList = [];
	Vis::dirBoxList = [];
}

public void createGoUpDirBox(){
	Vis::dirBoxList += box(
						text("..."),
						fillColor("Yellow"),
						onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
							if(Vis::currentLocation == Vis::currentProject){
								return true;
							} else{
								Vis::currentLocation = Vis::currentLocation.parent;
								begin();
								return true;
								}
							})
						);
}

public void createFileAndDirBoxes(){			
	Vis::filesInLocation = Vis::currentLocation.ls;	
	for(loc location <- Vis::filesInLocation){
		loc tmploc = location;
		if(location.extension == "java"){
			Vis::fileBoxList += box(
							//text(replaceFirst(location.path,Vis::currentLocation.path + "/", ""), fontSize(5)),
							area(size(readFileLines(location)))
							,onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
								iprintln(tmploc);
								return true;
							})
						);
		}else if(contains(location.extension, "/") || location.extension == ""){
			Vis::dirBoxList += box(
							text(replaceFirst(location.path, Vis::currentLocation.path, "")),
							fillColor("Yellow"),
							onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
								Vis::currentLocation = tmploc;
								begin();
								return true;
								})
							);
		}
	}
	if(isEmpty(Vis::fileBoxList)){
		Vis::fileBoxList += box(
							text("No .java files in directory")
							);
	}
}

public void createTreeMap(){
	t = vcat([
			box(text(toString(Vis::currentLocation)), vshrink(0.04)),
			box(treemap(Vis::dirBoxList), vshrink(0.04)),
			box(treemap(Vis::fileBoxList), vshrink(0.92))
		]);
	render(t);
}
