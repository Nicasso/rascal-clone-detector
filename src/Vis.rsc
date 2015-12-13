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
public Color noCloneColor = color("White");
public Color fullCloneColor = color("Red");
public str defaultDirColor = "LightGrey";
public str highlightDirColor = "DarkGrey";
public loc startLocation = |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src|;
public loc currentLocation = Vis::startLocation;

public void main(int cloneType) {
	CloneDetector::main(cloneType);
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
	if(Vis::currentLocation != Vis::startLocation){
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
			real percentage;
			for(file <- CloneDetector::fileInformation){
				if(file.location == location){
					boxArea = file.LOC;
					if((file.percentage) * 3 > 1.) percentage = 1.; else percentage = (file.percentage) * 3;
					break;
				}
			}
			Vis::fileBoxList += box(
								area(boxArea),
								fillColor(interpolateColor(Vis::noCloneColor, Vis::fullCloneColor, percentage)),
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

public void viewFile(){
	clearMemory();
	createGoUpDirBox();
	bool highlight = false;
	int LOC;
	set[loc] clones;
	for(file <- CloneDetector::fileInformation){
		if(file.location == Vis::currentLocation){
			LOC = file.LOC;
			clones = file.clones;
			break;
		}
	}
	Vis::textField = "<LOC> LOC in file";
	if (isEmpty(clones)){
		Vis::fileBoxList += vcat([
						box(
						text("No clones in this file."),
						onMouseEnter(void () {highlight = true;}), 
						onMouseExit(void () {highlight = false;}),
						onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									//edit(Vis::currentLocation);
									iprintln(clones);
									return true;
									})
						)
						]);
		createTreeMap();
	} //else {
		
	//}
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
