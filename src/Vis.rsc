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
import Config;

public list[loc] filesInLocation = [];
public list[Figure] dirBoxList = [];
public list[Figure] fileBoxList = [];
public str textField = "";
public Color noCloneColor = color("White");
public Color fullCloneColor = color("Red");
public str defaultDirColor = "LightGrey";
public str highlightDirColor = "DarkGrey";
public loc currentLocation = Config::startLocation;

public void mainVis(int cloneType) {
	CloneDetector::main(cloneType);
	startVisualization();
}

public void startVisualization() {
	clearMemory();
	createGoUpDirBox();
	createFileAndDirBoxes();
	createFileAndDirView();
}

public void clearMemory(){
	Vis::textField = "";
	Vis::filesInLocation = [];
	Vis::dirBoxList = [];
	Vis::fileBoxList = [];
}

public void createGoUpDirBox(){
	if(Vis::currentLocation != Config::startLocation){
		bool highlight = false;
		Vis::dirBoxList += box(
						text("..."),
						fillColor(Color () { return highlight ? color(Vis::highlightDirColor) : color(Vis::defaultDirColor); }),
						onMouseEnter(void () { highlight = true; Vis::textField = "Click to open parent folder";}), 
						onMouseExit(void () { highlight = false; Vis::textField = "";}),
						onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
							Vis::currentLocation = Vis::currentLocation.parent;
							startVisualization();
							return true;
							})
						);
	}
}

public void createGoBackToFileBox(){
	bool highlight = false;
	Vis::dirBoxList += box(
					text("..."),
					fillColor(Color () { return highlight ? color(Vis::highlightDirColor) : color(Vis::defaultDirColor); }),
					onMouseEnter(void () { highlight = true; Vis::textField = "Click to go back to file";}), 
					onMouseExit(void () { highlight = false; Vis::textField = "";}),
					onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
						createSingleFileBox();
						return true;
						})
					);
}

public void createFileAndDirBoxes(){			
	Vis::filesInLocation = Vis::currentLocation.ls;	
	for(loc location <- Vis::filesInLocation){
		loc tmploc = location;
		if(contains(location.extension, "/") || location.extension == ""){
			bool highlight = false;
			str showText = replaceFirst(location.path, Vis::currentLocation.path, "");
			Vis::dirBoxList += box(
								text(showText),
								fillColor(Color () {return highlight ? color(Vis::highlightDirColor) : color(Vis::defaultDirColor);}),
								onMouseEnter(void () {highlight = true; Vis::textField = "Click to open " + showText;}), 
								onMouseExit(void () {highlight = false; Vis::textField = "";}),
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
					percentage = file.percentage * 3 > 1. ? 1. : file.percentage * 3;
					break;
				}
			}
			Vis::fileBoxList += box(
								area(boxArea),
								fillColor(interpolateColor(Vis::noCloneColor, Vis::fullCloneColor, percentage)),
								onMouseEnter(void () {highlight = true; Vis::textField = "Click to open " + tmploc.file + " (<boxArea> LOC)";}), 
								onMouseExit(void () {highlight = false; Vis::textField = "";}),
								onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									Vis::currentLocation = tmploc;
									createSingleFileBox();
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

public void createSingleFileBox(){
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
	int numberOfClones = size(clones);
	if (isEmpty(clones)){
		Vis::fileBoxList += vcat([
						box(
						text("0 clones in this file"),
						onMouseEnter(void () {highlight = true;}), 
						onMouseExit(void () {highlight = false;}),
						onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									return true;
									})
						)
						]);
		createFileAndDirView();
	} else {
		int endLine = size(readFileLines(Vis::currentLocation));
		list[loc] sortedClones = sortClones(clones);
		for(clone <- sortedClones){
			bool highlight = false;
			loc cloneLocation = clone;
			str text = "Click to see where this clone (line <clone.begin.line> - <clone.end.line>) occurs";
			Vis::fileBoxList += box(
									vcat([
										box(
											vshrink(toReal(clone.begin.line - 1) / toReal(endLine)),
											fillColor(Color () {return highlight ? color(Vis::defaultDirColor) : color("White");})
										),
										box(
											fillColor("Red")
										),
										box(
											vshrink(toReal(endLine - clone.end.line) / toReal(endLine)),
											fillColor(Color () {return highlight ? color(Vis::defaultDirColor) : color("White");})
										)
									]),
									onMouseEnter(void () {highlight = true; Vis::textField = text;}), 
									onMouseExit(void () {highlight = false; Vis::textField = "";}),
									onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
										createCloneBox(CloneDetector::getCloneClass(cloneLocation));
										return true;
									})
								);
		}
		createSingleFileView();
	}
}

public void createCloneBox(set[loc] cloneLocations){
	clearMemory();
	createGoBackToFileBox();
	for(clone <- cloneLocations){
		bool highlight = false;
		loc cloneLocation = clone;
		Vis::fileBoxList += box(
								text("<cloneLocation.uri>\nline <cloneLocation.begin.line> - <cloneLocation.end.line>", left()),
								onMouseEnter(void () {highlight = true; Vis::textField = "Click to open clone";}), 
								onMouseExit(void () {highlight = false; Vis::textField = "";}),
								onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									edit(cloneLocation);
									return true;
								}),
								fillColor(Color () {return highlight ? color(Vis::defaultDirColor) : color("White");})
							);
	}
	createCloneView();
}

public list[loc] sortClones(set[loc] clones){
	list[loc] unsorted = toList(clones);
	list[loc] sorted = [];
	sorted = insertAt(sorted, 0, head(unsorted));
	unsorted = delete(unsorted, 0);
	for(loc clone1 <- unsorted){
		int i = 0;
		for(loc clone2 <- sorted){
			if(clone1.begin.line > clone2.begin.line){
				i += 1;
			}
		}
		sorted = insertAt(sorted, i, head(unsorted));
		unsorted = delete(unsorted, 0);
	}
	return sorted;
}

public void createFileAndDirView(){
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

public void createSingleFileView(){
	t = vcat([
			box(
				text(toString(Vis::currentLocation)),
				fillColor(Vis::defaultDirColor), 
				vshrink(0.04)),
			box(
				treemap(Vis::dirBoxList), 
				vshrink(0.04)),
			box(
				hcat(Vis::fileBoxList), 
				vshrink(0.88)),
			box(
				text(str(){return "<Vis::textField>";}), 
				fillColor(Vis::defaultDirColor),
				vshrink(0.04))
		]);
	render(t);
}

public void createCloneView(){
	t = vcat([
			box(
				text(toString(Vis::currentLocation)),
				fillColor(Vis::defaultDirColor), 
				vshrink(0.04)),
			box(
				treemap(Vis::dirBoxList), 
				vshrink(0.04)),
			box(
				vcat(Vis::fileBoxList), 
				vshrink(0.88)),
			box(
				text(str(){return "<Vis::textField>";}), 
				fillColor(Vis::defaultDirColor),
				vshrink(0.04))
		]);
	render(t);
}
