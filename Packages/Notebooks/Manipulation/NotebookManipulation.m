(* ::Package:: *)

(* Autogenerated Package *)

(* ::Text:: *)
(*Lower-level functions directly used to manipulate the IDE interface*)



NotebookSaveContents::usage="Saves the contents of a NotebookObject to a file";
NotebookPutFile::usage="Puts a File expression into a NotebookObject";
NotebookPutContents::usage="Puts a Notebook into a NotebookObject";
NotebookPutScratch::usage="Puts a notebook into a scratch file";


GetNotebookExpression::usage="Extracts the Notebook expression";
GetFileTabName::usage="Gets a unique name for a tab";


(* ::Text:: *)
(*The functions provided to an IDENotebookObject as methods*)



IDEOpen::usage="Open a file in the IDE notebook";
IDESave::usage="Save the active IDE notebook file";
IDEClose::usage="Close the IDE notebook";


Begin["`Private`"];


(* ::Subsection:: *)
(*Notebook Manipulation*)



(* ::Subsubsection::Closed:: *)
(*NotebookPutNotebook*)



(* ::Text:: *)
(*
	Put a new notebook in the pane
*)



nbPut1[nbObj_NotebookObject, nb_Notebook]:=
    Module[
      {
        baseExpr
        },
      FrontEndExecute@{
        FrontEnd`NotebookPut[
          Notebook[nb[[1]], Options[nbObj]],
          nbObj
          ],
        FrontEnd`SelectionMove[
          nbObj,
          Before,
          Notebook
          ]
      }
      ];


nbPut2[enb_NotebookObject, nb_Notebook]:=
  With[
    {
     mcells=
      Sequence@@Flatten@
       Map[
        {
         FrontEnd`SetOptions[#, Deletable->True],
         FrontEnd`NotebookDelete[#]
         }&,
        Cells[enb]
        ],
     ops=Options[enb]
    },
    MathLink`CallFrontEnd@{
     FrontEnd`SetOptions[enb, ops],
     mcells,
     FrontEnd`SelectionMove[enb, Before, Notebook],
     FrontEnd`NotebookWrite[enb, nb[[1]], None,
      AutoScroll->False
      ]
     }
   ]


NotebookPutContents[ideNb_NotebookObject, nb_Notebook]:=
  Module[
    {
      ops=Options[nb],
      c=Cells[ideNb]
      },
    WithNotebookPaused[
      ideNb,
     If[Length@c>0, (* Cell open/close state was getting messed up *)
       nbPut1[ideNb, nb],
       nbPut2[ideNb, nb]
       ];
     IDEData[ideNb, "Options"] = ops;
     ];
   ]


(* ::Subsubsection::Closed:: *)
(*setNbFileStyle*)



(* ::Subsubsubsection::Closed:: *)
(*getFExtStylesheet*)



loadExtStyles[]:=
  Append[
    Normal@
      Merge[
        Get/@
          FileNames[
            "ExtensionStylesMap.wl",
            FileNames["Mappings", $IDESettingsPath]
            ],
        First
        ],
    _->None
    ]


getFExtStylesheet[fExt_]:=
  fExt/.loadExtStyles[]


(* ::Subsubsubsection::Closed:: *)
(*getNbFileSSheet*)



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
    _->FrontEnd`FileName[{"EasyIDE"}, "LightMode.nb"]
    ];


getNbFileSSheet[nbFile_]:=
  If[FileByteCount[nbFile]<1000000,
    Module[{g=Get[nbFile], sd, sdFile},
      sd=FirstCase[Flatten@Apply[List, Rest[g]], (StyleDefinitions->s_):>s, "Default.nb"];
      sdFile=
        Replace[sd, 
          Except[_String|_FrontEnd`FileName]:>
            FirstCase[sd, 
              StyleData[StyleDefinitions->s_:>s, ___], 
              "Default.nb",
              \[Infinity]
              ]
          ];
      If[StringQ@sdFile&&FileNameDepth[sdFile]>1,
        sdFile = FrontEnd`FileName[#[[;;-2]], #[[-1]]]&@FileNameSplit[sdFile]
        ];
      (*Replace[sdFile,
				f_FrontEnd`FileName\[RuleDelayed]ToFileName[f]
				]*)
      sdFile
      ],
    $Failed
    ];
getStylesheetStylesheet[nbFile_]:=
  getNbFileSSheet[nbFile]/.
    loadSheetStyles[]


(* ::Subsubsubsection::Closed:: *)
(*getFileStylesheet*)



getFileStylesheet[nb_, file_]:=
  Module[
    {
      fExt = FileExtension[file]
      },
    getCleanStylePath[
      nb,
      Replace[getFExtStylesheet[fExt],
        None:>If[fExt==="nb", getStylesheetStylesheet[file], None]
        ]
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*setNbFileStyle*)



setNbFileStyle[nb_, file_]:=
  Module[
    {
      currentStyles = IDEData[nb, "StyleSheet", None],
      mainName,
      targ
      },
    targ = getFileStylesheet[nb, file];
    IDEData[nb, "StyleSheet"] = targ;
    If[targ =!= None,
      SetMainStylesheet[nb, targ]
      ];
    ]


(* ::Subsubsection::Closed:: *)
(*setNbFileToolbar*)



(* ::Subsubsubsection::Closed:: *)
(*getFExtToolbar*)



loadExtToolbars[]:=
  Append[
    Normal@
      Merge[
        Get/@
          FileNames[
            "ExtensionToolbarsMap.wl",
            FileNames["Mappings", $IDESettingsPath]
            ],
        First
        ],
    _->None
    ]


getFExtToolbar[fExt_]:=
  fExt/.loadExtToolbars[]


(* ::Subsubsubsection::Closed:: *)
(*getStylesheetToolbar*)



loadSheetToolbars[]:=
  Append[
    Normal@
      Merge[
        Get/@
          FileNames[
            "StylesheetToolbarsMap.wl",
            FileNames["Mappings", $IDESettingsPath]
            ],
        First
        ],
    _->None
    ];


getStylesheetToolbar[nbFile_]:=
  getNbFileSSheet[nbFile]/.
    loadSheetToolbars[]


(* ::Subsubsubsection::Closed:: *)
(*getFileToolbar*)



(* ::Text:: *)
(*
	Toolbars are just treated as another case of a Plugin, but not always attached to the menu or put into a ActionMenu
*)



getFileToolbar[nb_, file_]:=
  Module[
    {
      fExt = FileExtension[file],
      tbName
      },
    tbName=
      Replace[getFExtToolbar[fExt],
        None:>If[fExt==="nb", getStylesheetToolbar[file], None]
        ];
    tbName
    ]


(* ::Subsubsubsection::Closed:: *)
(*setNbFileToolbar*)



setNbFileToolbar[nb_, file_]:=
  Module[
    {
      currentTb = IDEData[nb, "FileToolbar", None],
      name
      },
    name = getFileToolbar[nb, file];
    If[currentTb =!= name,
      IDEData[nb, "FileToolbar"] =  name;
      If[currentTb =!= None,
        RemoveNotebookToolbar[nb, currentTb]
        ];
      UpdateNotebookToolbars[nb]
      ];
    ]


(* ::Subsubsection::Closed:: *)
(*setAutoSave*)



setAutoSave[nb_]:=
  Module[{aug = CurrentValue[nb, AutoGeneratedPackage]},
    If[aug === Automatic,
      IDEData[nb, "AutoGeneratePackage"] = True,
      CurrentValue[nb, AutoGeneratedPackage] = Inherited;
      IDEData[nb, "AutoGeneratePackage"] = False
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*setNbActions*)



setNbActions[nb_]:=
  Module[{nbActs},
    CurrentValue[nb, NotebookEventActions] = Inherited;
    nbActs = CurrentValue[nb, NotebookEventActions];
    If[MemberQ[nbActs, {"MenuCommand", "Save"}],
      CurrentValue[nb, "SavingAction"]
      ];
    CurrentValue[nb, NotebookEventActions]=
      DeleteDuplicatesBy[First]@
        Join[
          {
            {"MenuCommand", "Save"}:>
              IDESave[EvaluationNotebook[]]
           },
          Replace[nbActs,
            Except[_List]:>{}
            ],
          {
            PassEventsDown->True,
            EvaluationOrder->After
            }
         ]
    ]


(* ::Subsubsection::Closed:: *)
(*GetNotebookExpression*)



GetNotebookExpression[nb_]:=
  Module[
    {
      opts = IDEData[nb, "Options", {}]
      },
    Notebook[
      NotebookGet[nb][[1]],
      Flatten[List@@opts]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*NotebookPutFile*)



NotebookPutFile[nb_NotebookObject, f_String]:=
  Module[
    {
      nbObj,
      nbExpr,
      aug
      },
    (* since we need to handle autogeneration stuff too... *)
    CurrentValue[nb, AutoGeneratedPackage] = Inherited;
    Switch[FileExtension[f],
      "nb",
        nbExpr = Get[f],
      _,
        nbObj = NotebookOpen[f, Visible->False];
        nbExpr = NotebookGet[nbObj];
        NotebookClose[nbObj];
      ];
    WithNotebookPaused[
      nb,
      setNbFileStyle[nb, f];
      setNbFileToolbar[nb, f];
      NotebookPutContents[nb, nbExpr];
      setAutoSave[nb];
      setNbActions[nb];
      ];
    ];


(* ::Subsubsection::Closed:: *)
(*NotebookSaveContents*)



NotebookSaveContents//Clear
Options[NotebookSaveContents]=
  {
    "AutoGenerateSave"->True
    };
Module[{recurseProtect},
  NotebookSaveContents[nb_NotebookObject, 
    file:_String|Automatic:Automatic,
    preemptive:True|False:False,
    ops:OptionsPattern[]
    ]:=
    Block[
      {
        recurseProtect = !preemptive&&TrueQ[recurseProtect]
        },
      If[!recurseProtect,
        recurseProtect=True;
        (*While[TrueQ[inSave], Pause[.1]];*) 
          (* 
				  An attempt to protect against crashes by introducing a forced wait...not sure if this is the issue at all
				  *)
        Internal`WithLocalSettings[
          inSave = True,
          Module[
            {
              f = file,
              dir,
              nbExpr,
              nbObj,
              nbFName,
              nbPkgName,
              ags = OptionValue["AutoGenerateSave"]
              },
            If[f === Automatic,
              f = IDEPath[nb, Key["ActiveFile"]]
              ];
            If[f=!=None,
              f = IDEPath[nb, f];
              Switch[FileExtension[f],
                "nb",
                  nbExpr = GetNotebookExpression[nb];
                  If[preemptive,
                    PreemptiveQueued[nb, Export[f, nbExpr]],
                    Export[f, nbExpr]; (* would Put be better ? *)
                    ];
                  If[preemptive,
                    Function[Null, PreemptiveQueued[nb, #], HoldAllComplete],
                    #&
                    ]@
                    If[ags && IDEData[nb, "AutoGeneratePackage"],
                      nbFName = NotebookFileName[nb];
                      If[StringQ[nbFName],
                        nbPkgName = StringReplace[nbFName, ".nb"->".m"];
                        If[FileExistsQ[nbPkgName],
                          RenameFile[
                            nbPkgName,
                            StringReplace[f, ".nb"->".m"],
                            OverwriteTarget->True
                            ]
                          ]
                        ]
                      ],
                "m"|"wl",
                  If[preemptive,
                    nbExpr =GetNotebookExpression[nb];
                    PreemptiveQueued[nb,
                      Internal`WithLocalSettings[
                        nbObj = CreateDocument[nbExpr, Visible->False],
                        FrontEndExecute@
                          FrontEndToken[
                            nbObj,
                            "Save",
                            {f, "Package"}
                            ],
                        NotebookClose[nbObj]
                        ]
                      ],
                    nbObj = nb;
                    FrontEndExecute@
                      FrontEndToken[
                        nbObj,
                        "Save",
                        {f, "Package"}
                        ]
                    ],
                _,
                  If[preemptive,
                    nbExpr =GetNotebookExpression[nb];
                    PreemptiveQueued[nb,
                      Internal`WithLocalSettings[
                        nbObj = CreateDocument[nbExpr, Visible->False],
                        FrontEndExecute@
                          FrontEndToken[
                            nbObj,
                            "Save",
                            {f, "Text"}
                            ],
                        NotebookClose[nbObj]
                        ]
                      ],
                    nbObj = nb;
                    FrontEndExecute@
                      FrontEndToken[
                        nbObj,
                        "Save",
                        {f, "Text"}
                        ]
                    ]
                ]
              ]
            ],
          inSave = False
          ];
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*NotebookPutScratch*)



NotebookPutScratch[nb_, expr_Notebook]:=
  NotebookPutFile[nb, CreateProjectScratchFile[nb, expr]]


(* ::Subsection:: *)
(*File Operations*)



(* ::Subsubsection::Closed:: *)
(*GetFileTabName*)



GetFileTabName[nb_, f_]:=
  Module[
    {
      tabs = IDEData[nb, "Tabs"],
      tns,
      tabName
      },
    tabName =
      Do[If[Lookup[t[[2]], "File"]==f, Return[t[[1]], Do]], {t, tabs}];
    If[tabName===Null,
      tabName = FileBaseName[f];
      tns = tabs[[All, 1]];
      If[MemberQ[tns, tabName],
        tabName = tabName <> "." <> FileExtension[f]
        ];
      tabName=
        NestWhile[
          # <> "/" <> FileNameTake[f, -Length[URLParse[#, "Path"]]]&,
          tabName,
          MemberQ[tns, #]&,
          1,
          FileNameDepth[f]-1
          ]
      ];
    tabName
    ]


(* ::Subsubsection::Closed:: *)
(*IDEOpen*)



IDEOpen[nb_NotebookObject, f_String?FileExistsQ]:=
  Module[
    {
      nbObj,
      nbExpr,
      tabName
      },
    tabName = GetFileTabName[nb, f];
    If[!TrueQ@IDETabExists[nb, tabName],
      NotebookCreateTab[nb, tabName, 
        {
          "File"->f  
          }
        ]
      ];
    NotebookSwitchTab[nb, tabName]
    ];
IDEOpen[nb_IDENotebookObject, f_String?FileExistsQ]:=
  IDEOpen[nb["Notebook"], f];
IDEOpen[nb_NotebookObject, expr_Notebook]:=
  IDEOpen[nb, CreateProjectScratchFile[nb, expr]];
IDEOpen[nb_IDENotebookObject, expr_Notebook]:=
  IDEOpen[nb["Notebook"], expr];


(* ::Subsubsection::Closed:: *)
(*IDESave*)



IDESave//Clear
IDESave[nb_NotebookObject, ops:OptionsPattern[]]:=
  NotebookSaveContents[nb, ops];
IDESave[nb_IDENotebookObject, ops:OptionsPattern[]]:=
  IDESave[nb["Notebook"], ops]


(* ::Subsubsection::Closed:: *)
(*IDEClose*)



IDEClose[nb_NotebookObject, tabName_]:=
  If[IDETabExists[tabName],
    NotebookCloseTab[nb, tabName]
    ];
IDEClose[nb_IDENotebookObject, tabName_]:=
  IDEClose[nb["Notebook"], tabName]


End[];



