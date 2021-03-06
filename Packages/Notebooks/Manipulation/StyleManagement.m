(* ::Package:: *)

(* Autogenerated Package *)

GetMainStylesheet::usage="Gets a NotebookObject's stylesheet name";
SetMainStylesheet::usage="Sets a NotebookObject's stylesheet";
GetMainStylesheetName::usage="Gets just the name";
GetCleanStylePath::usage="";


AddNotebookStyles::usage="";
RemoveNotebookStyles::usage="";
AddNotebookStylesheet::usage="";
RemoveNotebookStylesheet::usage="";


SetNotebookStyleTheme::usage="";
GetThemedStylesheet::usage="";
SetThemedStylesheet::usage="";


IDEAddStyles::usage="Adds styles to the IDE notebook";
IDERemoveStyles::usage="Removes styles from the IDE notebook";


IDEGetStylesheet::usage="Gets the IDE notebook stylesheet";
IDESetStylesheet::usage="Sets the IDE notebook stylesheet";


Begin["`Private`"];


(* ::Subsection:: *)
(*Styles*)



(* ::Subsubsection::Closed:: *)
(*getThemeName*)



getThemeName[nb_]:=
  Replace[IDEData[nb, {"Styles", "Theme"}], 
    Inherited:>
      IDEData[nb, "MainStyleName"]
    ];


(* ::Subsubsection::Closed:: *)
(*GetMainStylesheet*)



GetMainStylesheet[nb_]:=
  Module[
    {
      s=GetCurrentValue[nb, StyleDefinitions]
      },
    If[Head[s]===Notebook,
      FirstCase[s, Cell[StyleData[StyleDefinitions->f_, ___], ___]:>f, None, \[Infinity]],
      s
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*SetMainStylesheet*)



SetMainStylesheet//Clear
SetMainStylesheet[nb_, f_]:=
  Module[
    {
      s = GetCurrentValue[nb, StyleDefinitions],
      scell,
      nbo,
      sPath = GetCleanStylePath[nb, f]
      },
    If[Head[s]===Notebook,
      nbo = StyleSheetNotebookObject[nb];
      scell = 
        SelectFirst[Cells[nbo], 
          MatchQ[NotebookRead[#], Cell[StyleData[StyleDefinitions->_, ___], ___]]&,
          None
          ];
      If[scell === None,
        MathLink`CallFrontEnd@{
          FrontEnd`SelectionMove[nbo, Before, Notebook],
          FrontEnd`NotebookWrite[nbo,
            Cell[StyleData[StyleDefinitions->sPath]]
            ]
          },
        NotebookWrite[
          scell,
          Cell[StyleData[StyleDefinitions->sPath]]
          ]
        ],
      SetNotebookOptions[nb, StyleDefinitions->sPath]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*GetCleanStylePath*)



GetCleanStylePath[nb_, f_]:=
  cleanStylesheetName[
    GetMainStylesheetName[nb],
    Replace[f,
      {
        s_String?(!StringEndsQ[#, ".nb"]&):>
          "-"<>StringTrim[s, "-"]<>".nb",
        FrontEnd`FileName[p_, s_String?(Not@*StringEndsQ[".nb"]), ___]:>
          FrontEnd`FileName[p, Evaluate["-"<>StringTrim[s, "-"]<>".nb"]]
        }
      ]
   ]


(* ::Subsubsection::Closed:: *)
(*GetMainStylesheetName*)



(* ::Text:: *)
(*
	This is currently a slow point in my code... 
	Can I get it from the theme if the theme is set...?
*)



GetMainStylesheetName//Clear
GetMainStylesheetName[main:_String|_FrontEnd`FileName, fallback_:"LightMode"]:=
  (* this will definitely need to be robustified... *)
  StringSplit[Replace[#, FrontEnd`FileName[_, s_, ___]:>s], "."|"-"][[1]]&@
    Replace[main, 
      {
        FrontEnd`FileName[{path___}, fn_, ___]:>
          With[
            {
              bn=StringSplit[fn, "."|"-"][[1]], 
              f2=StringTrim[fn, ".nb"]
              },
            SelectFirst[
              {
              FrontEnd`FileName[{path}, bn],
              FrontEnd`FileName[{path}, f2],
              FrontEnd`FileName[{path, "Extensions"}, bn],
              FrontEnd`FileName[{path, "Extensions"}, f2],
                If[Length[Hold[path]]>0&&
                  Hold[path]=!=Hold["EasyIDE", "Extensions"]
                  (* this is a clear dud path *),
                  Replace[Hold[path],
                    {
                      Hold[p1__, p2_]:>FrontEnd`FileName[{p1}, p2],
                      _->Nothing
                      }
                    ],
                  Nothing
                  ]
                },
              sheetExistsQ,
              fallback
              ]
            ],
        s_String:>
          GetMainStylesheetName[
            FrontEnd`FileName[{}, s],
            fallback
            ]
        }
      ];
GetMainStylesheetName[nb_NotebookObject, fallback_:Automatic]:=
  Replace[
    getThemeName[nb],
    Except[_String]:>
      Set[
        IDEData[nb, {"Styles", "Theme"}],
        GetMainStylesheetName[
          GetMainStylesheet[nb],
          Replace[fallback, Except[_String]:>"LightMode"]
          ]
        ]
    ]


(* ::Subsubsection::Closed:: *)
(*SetNotebookStyleTheme*)



SetNotebookStyleTheme[nb_NotebookObject, themeName_String]:=
  With[{gs=GetMainStylesheet[nb]},
    With[{tname=GetMainStylesheetName[gs]},
      If[tname=!=themeName,
        IDEData[nb, {"Styles", "Theme"}] = themeName;
        SetOptions[nb, StyleDefinitions->gs/.tname->themeName]
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*GetThemedStylesheet*)



loadSheetStyles[]:=
  Append[
    Normal@
      Merge[
        Get/@
          FileNames[
            "StylesheetStylesMap.wl",
            FileNames["Mappings", $IDESettingsPath]
            ],
        First
        ],
    _->None
      (*GetStylesheetName[
		    $CurrentIDENotebook,
  		  FrontEnd`FileName[{"EasyIDE"}, "LightMode.nb"]
       ]*)
    ];


GetThemedStylesheet[sheet_]:=
  sheet/.loadSheetStyles[]


(* ::Subsubsection::Closed:: *)
(*SetThemedStylesheet*)



SetThemedStylesheet[nb_, targ_]:=
  Module[
    {
      currentStyles = 
        Replace[IDEData[nb, {"Styles", "StyleSheet"}], Inherited:>IDEData["Stylesheet"]],
      mainName
      },
    IDEData[nb, {"Styles", "StyleSheet"}] = targ;
    If[targ =!= None,
      SetMainStylesheet[nb, targ];
      IDEData[nb, {"Styles", "Theme"}] = GetMainStylesheetName[nb];
      ];
    ]


(* ::Subsubsection::Closed:: *)
(*sheetExistsQ*)



(* ::Text:: *)
(*
	I might want to reimp something like this for myself to speed this up...?
*)



sheetExistsQ[s_String]:=
  MathLink`CallFrontEnd@FrontEnd`FindFileOnPath[s, "StyleSheetPath"]=!=$Failed;
sheetExistsQ[f_FrontEnd`FileName]:=
  MathLink`CallFrontEnd@FrontEnd`FindFileOnPath[ToFileName[f], "StyleSheetPath"]=!=$Failed;


(* ::Subsubsection::Closed:: *)
(*cleanStylesheetName*)



(* ::Subsubsubsection::Closed:: *)
(*getExtStyleSubpathAndName*)



getExtStyleSubpathAndName[s_]:=
  Module[{base=StringTrim[StringTrim[s, "-"], ".nb"]<>".nb"},
    {Most[#], Last[#]}&@StringSplit[base, "/"]
    ]


(* ::Subsubsubsection::Closed:: *)
(*cleanStylesheetName*)



cleanStylesheetName[mainName_String, sheet_]:=
  Replace[sheet,
    {
      FrontEnd`FileName[{path___}, s_String?(StringStartsQ["-"]), r___]:>
        Replace[getExtStyleSubpathAndName[s],
          {{subpath___}, tt_}:>
            SelectFirst[
              {
              FrontEnd`FileName[{path, mainName, subpath}, tt],
              FrontEnd`FileName[{path, subpath}, Evaluate[mainName<>"-"<>tt]],
              FrontEnd`FileName[{path, subpath}, tt],
              FrontEnd`FileName[{path}, s]
               },
              sheetExistsQ,
              FrontEnd`FileName[{path}, s]
              ]
          ],
      s_String?(StringStartsQ["-"]):>
        cleanStylesheetName[mainName, FrontEnd`FileName[{"EasyIDE", "Extensions"}, s]],
      sht_String:>
        With[{s=StringTrim[sht, ".nb"]<>".nb"},
          SelectFirst[
            {
            FrontEnd`FileName[{"EasyIDE", "Extensions", mainName}, s],
            FrontEnd`FileName[{"EasyIDE", "Extensions"}, s],
            FrontEnd`FileName[{"EasyIDE"}, s],
            FrontEnd`FileName[{"EasyIDE", "Extensions"}, Evaluate[mainName<>"-"<>s]],
             s
             },
            sheetExistsQ,
            s
            ]
         ],
      None:>
        With[{mn=mainName<>".nb"},
          SelectFirst[
            {
            FrontEnd`FileName[{"EasyIDE"}, mn],
            mn,
            FrontEnd`FileName[{"EasyIDE", "Extensions"}, mn]
             },
            sheetExistsQ,
            FrontEnd`FileName[{"EasyIDE"}, mn]
            ]
          ]
      }
    ]


(* ::Subsubsection::Closed:: *)
(*getStylesheetDefsSection*)



getStylesheetDefsSection[data:{__Cell}, tag_String]:=
  Module[
    {sec},
    sec = 
      Cell[
        tag, 
        "Subsubsubsubsection",
        CellGroupingRules->{"SectionGrouping",200},
        CellTags->{tag}
        ];
    Cell[
      CellGroupData[
        Flatten@{
          sec,
          data
          },
        Closed
        ]
      ]
    ];
getStylesheetDefsSection[
  file:_String|_FrontEnd`FileName, 
  tag:_String|Automatic:Automatic
  ]:=
  Module[
    {
      fileName,
      data,
      sec
      },
    fileName=
      FrontEndExecute@
        FrontEnd`FindFileOnPath[file, "StyleSheetPath"];
    If[StringQ@fileName, 
      data = Cases[Get[fileName][[1]], Cell[_StyleData, ___], \[Infinity]];
      getStylesheetDefsSection[data, 
      Replace[tag, Automatic:>ToString@file]
      ],
      $Failed
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*AddNotebookStyles*)



AddNotebookStyles[nb_, styleData:_Cell, tag_]:=
  Module[
    {
      nbo,
      currDefs,
      defCells
      },
    currDefs = GetCurrentValue[nb, StyleDefinitions];
    If[Head[currDefs] =!= Notebook,
      SetCurrentValue[nb, 
        StyleDefinitions,
        Notebook[
          {
            Cell[StyleData[StyleDefinitions->currDefs]],
            styleData
            },
          StyleDefinitions->"PrivateStylesheetFormatting.nb"
          ]
        ],
      nbo = StyleSheetNotebookObject[nb];
      defCells = Cells[nbo, CellTags->tag];
      If[Length@defCells === 0,
        SelectionMove[nbo, After, Notebook];
        NotebookWrite[nbo, styleData],
        SelectionMove[defCells[[-1]], After, Cell];
        NotebookWrite[nbo, styleData]
        ]
      ]
    ]
AddNotebookStyles[nb_, styleData:{__Cell}, tag_]:=
  AddNotebookStyles[nb, getStylesheetDefsSection[styleData, tag], tag];


(* ::Subsubsection::Closed:: *)
(*AddNotebookStylesheet*)



AddNotebookStylesheet//Clear
AddNotebookStylesheet[nb_, fileName_, tag:_String|Automatic:Automatic]:=
  Module[
    {
      file = If[!StringQ[fileName], ToFileName[fileName], fileName],
      styles
      },
    styles = getStylesheetDefsSection[file, tag];
    If[styles=!=$Failed,
      AddNotebookStyles[nb, styles, 
        Replace[tag, Automatic:>ToString@file]
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*RemoveNotebookStyles*)



RemoveNotebookStyles[nb_, tag_]:=
  Module[
    {
      nbo,
      defCells
      },
    nbo = StyleSheetNotebookObject[nb];
    defCells = Cells[nbo, CellTags->tag];
    FrontEndExecute@
      Flatten@Map[
        Function[
          {
            FrontEnd`SelectionMove[#, All, CellGroup],
            FrontEnd`SetOptions[
              NotebookSelection[nbo], 
              {
                Deletable->True,
                Editable->True
                }
              ],
            FrontEnd`NotebookDelete[
              nbo
              ]
          }
          ],
        defCells
        ]
    ]


(* ::Subsubsection::Closed:: *)
(*RemoveNotebookStylesheet*)



RemoveNotebookStylesheet//Clear
RemoveNotebookStylesheet[nb_, fileName_, tag:_String|Automatic:Automatic]:=
  RemoveNotebookStyles[
    nb,
    Replace[tag,
      Automatic:>If[!StringQ[fileName], ToFileName[fileName], fileName]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*prepStyleDefs*)



prepStyleDefs[rules:{(_String->_)..}]:=
  KeyValueMap[
    Cell[
      StyleData[#],
      Sequence@@Flatten@{#2}
      ]&,
    Association@rules
    ]


(* ::Subsection:: *)
(*IDE Stuff*)



(* ::Subsubsection::Closed:: *)
(*IDEAddStyles*)



IDEAddStyles//Clear


IDEAddStyles[nb_NotebookObject, styles:{__Cell}, tag_String]:=
  AddNotebookStyles[nb, styles, tag];
IDEAddStyles[ide_IDENotebookObject, styles:{__Cell}, tag_String]:=
  IDEAddStyles[ide["Notebook"], styles, tag];


IDEAddStyles[nb_NotebookObject, styles:_String|_FrontEnd`FileName]:=
  AddNotebookStylesheet[nb, styles];
IDEAddStyles[ide_IDENotebookObject, styles:_String|_FrontEnd`FileName]:=
  AddNotebookStylesheet[ide["Notebook"], styles];


IDEAddStyles[
  nb_NotebookObject, 
  rules:({(_String->_)..})|(_String->_)|(_Association), 
  tag_String
  ]:=
  AddNotebookStyles[nb, prepStyleDefs[Normal@Association[rules]], tag];
IDEAddStyles[
  ide_IDENotebookObject, 
  rules:{(_String->_)..}|(_String->_)|_Association, 
  tag_String
  ]:=IDEAddStyles[ide["Notebook"], rules, tag]


(* ::Subsubsection::Closed:: *)
(*IDERemoveStyles*)



IDERemoveStyles//Clear


IDERemoveStyles[nb_NotebookObject, tag_String]:=
  If[StringEndsQ[tag, ".nb"],
    RemoveNotebookStylesheet[nb, tag];,
    RemoveNotebookStyles[nb, tag];
    ];
IDERemoveStyles[nb_NotebookObject, tag_FrontEnd`FileName]:=
  RemoveNotebookStylesheet[nb, tag];
IDERemoveStyles[ide_IDENotebookObject, tag:_FrontEnd`FileName|_String]:=
  IDERemoveStyles[ide["Notebook"], tag]


(* ::Subsubsection::Closed:: *)
(*IDEGetStylesheet*)



IDEGetStylesheet[nb_NotebookObject]:=
  GetMainStylesheet[nb];
IDEGetStylesheet[ide_IDENotebookObject]:=
  IDEGetStylesheet[ide["Notebook"]];


(* ::Subsubsection::Closed:: *)
(*IDESetStylesheet*)



IDESetStylesheet[nb_NotebookObject, file:_String|_FrontEnd`FileName]:=
  SetMainStylesheet[nb, file];
IDESetStylesheet[ide_IDENotebookObject, file:_String|_FrontEnd`FileName]:=
  IDESetStylesheet[ide["Notebook"], file];


End[];



