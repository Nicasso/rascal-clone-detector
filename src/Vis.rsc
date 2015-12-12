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
import util::Editors;
import demo::common::Crawl;
import DateTime;

import CloneDetector;
import Helper;

public list[loc] filesInLocation = [];
public list[Figure] dirBoxList = [];
public list[Figure] fileBoxList = [];
public str textField = "";
public lrel[loc location, int LOC] fileInformation = [];
public str defaultDirColor = "LightGrey";
public str highlightDirColor = "DarkGrey";
public str defaultFileColor = "LightCyan";
public str highlightFileColor = "PaleTurquoise";
public loc currentProject = |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src|;
public loc currentLocation = Vis::currentProject;

public void main(){
	buildFileInformation();
	startVisualization();
}

public void startVisualization() {
	clearMemory();
	createGoUpDirBox();
	createFileAndDirBoxes();
	createTreeMap();
}

public void clearMemory(){
	Vis::textField = "";
	Vis::filesInLocation = [];
	Vis::dirBoxList = [];
	Vis::fileBoxList = [];
}

public void createGoUpDirBox(){
	if(Vis::currentLocation != Vis::currentProject){
		bool highlight = false;
		Vis::dirBoxList += box(
						text("..."),
						fillColor(Color () { return highlight ? color(Vis::highlightDirColor) : color(Vis::defaultDirColor); }),
						onMouseEnter(void () { highlight = true;}), 
						onMouseExit(void () { highlight = false;}),
						onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
							Vis::currentLocation = Vis::currentLocation.parent;
							startVisualization();
							return true;
							})
						);
	}
}

public void createFileAndDirBoxes(){			
	Vis::filesInLocation = Vis::currentLocation.ls;	
	for(loc location <- Vis::filesInLocation){
		loc tmploc = location;
		if(contains(location.extension, "/") || location.extension == ""){
			bool highlight = false;
			Vis::dirBoxList += box(
								text(replaceFirst(location.path, Vis::currentLocation.path, "")),
								fillColor(Color () {return highlight ? color(Vis::highlightDirColor) : color(Vis::defaultDirColor);}),
								onMouseEnter(void () {highlight = true;}), 
								onMouseExit(void () {highlight = false;}),
								onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									Vis::currentLocation = tmploc;
									startVisualization();
									return true;
									})
								);
		} else if(location.extension == "java"){
			bool highlight = false;
			int boxArea;
			for(file <- Vis::fileInformation){
				if(file.location == location){
					boxArea = file.LOC;
					break;
				}
			}
			Vis::fileBoxList += box(
								area(boxArea),
								fillColor(Color () { return highlight ? color(Vis::highlightFileColor) : color(Vis::defaultFileColor);}),
								onMouseEnter(void () {highlight = true; Vis::textField = tmploc.file + " (<boxArea> LOC)";}), 
								onMouseExit(void () {highlight = false; Vis::textField = "";}),
								onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									Vis::currentLocation = tmploc;
									viewFile();
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

public void buildFileInformation(){
	for(location <- crawl(Vis::currentProject, ".java")){
		Vis::fileInformation += <location, Helper::computeLOC(location)>;
	}
}

public void viewFile(){
	clearMemory();
	createGoUpDirBox();
	Vis::textField = "Click on file to edit";
	bool highlight = false;
	int boxArea;
	for(file <- Vis::fileInformation){
		if(file.location == Vis::currentLocation){
			boxArea = file.LOC;
			break;
		}
	}
	Vis::fileBoxList += vcat([
						box(
						text("<boxArea> LOC in file"),
						fillColor(Color () {return highlight ? color(Vis::highlightFileColor) : color(Vis::defaultFileColor);}),
						onMouseEnter(void () {highlight = true;}), 
						onMouseExit(void () {highlight = false;}),
						onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									edit(Vis::currentLocation);
									return true;
									})
						)
						]);
	createTreeMap();
}

public void createTreeMap(){
	t = vcat([
			box(
				text(toString(Vis::currentLocation)),
				fillColor(Vis::defaultDirColor), 
				vshrink(0.04)),
			box(
				treemap(Vis::dirBoxList), 
				vshrink(0.04)),
			box(
				treemap(Vis::fileBoxList), 
				vshrink(0.88)),
			box(
				text(str(){return "<Vis::textField>";}), 
				fillColor(Vis::defaultDirColor),
				vshrink(0.04))
		]);
	render(t);
}
