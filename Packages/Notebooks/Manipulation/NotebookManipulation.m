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


$SaveNotebookMethod::usage="The method to use when saving notebooks";


EnsureNotebookUpdated::usage=
  "Checks to make sure the notebook file and the current notebook state aren't out-of-sync";


Begin["`Private`"];


(* ::Subsection:: *)
(*Notebook Manipulation*)



(* ::Subsubsection::Closed:: *)
(*NotebookPutContents*)



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
       Sequence@@{
         FrontEnd`SelectionMove[enb, All, Notebook],
         FrontEnd`SetOptions[NotebookSelection[enb], Deletable->True],
         FrontEnd`NotebookDelete[enb]
         }
    },
    MathLink`CallFrontEnd@{
     mcells,
     (*FrontEnd`SelectionMove[enb, Before, Notebook],*)
     FrontEnd`NotebookWrite[enb, nb[[1]], None, AutoScroll->False],
     FrontEnd`SelectionMove[enb, Before, Notebook]
     };
   ]


nbPut3[enb_NotebookObject, nb_Notebook]:=
  MathLink`CallFrontEnd@{
   (*FrontEnd`SelectionMove[enb, Before, Notebook],*)
   FrontEnd`NotebookWrite[enb, nb[[1]], None, AutoScroll->False],
   FrontEnd`SelectionMove[enb, Before, Notebook]
   }


NotebookPutContents//Clear
NotebookPutContents[
  ideNb_NotebookObject, 
  notebook:_Notebook|_Hold (* for some reason pass-by-value helps a lot here... *),
  mode:(NotebookWrite|NotebookPut|Automatic):Automatic
  ]:=
  Module[
    {
      ops,
      c,
      m,
      nb = ReleaseHold[notebook]
      },
    ops=Flatten@{List@@Rest[nb]};
    m = 
      Replace[mode, 
        Automatic:>(
          c=Cells[ideNb];
          If[Length@c>100000, NotebookPut, NotebookWrite]
          )
        ];
    WithNotebookPaused[
      ideNb,
      If[m===NotebookWrite,
        If[!ListQ[c], c=Cells[ideNb]];
        If[Length@c===0,
          nbPut3[ideNb, nb],
          nbPut2[ideNb, nb]
          ],
        nbPut1[ideNb, nb]
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



getNbFileSSheet[nbFile_]:=
  If[FileByteCount[nbFile]<1000000000,
    Module[{g=Get[nbFile], sd, sdFile},
      sd=FirstCase[Flatten@Apply[List, Rest[g]], (StyleDefinitions->s_):>s, "Default.nb"];
      sdFile=
        Replace[sd, 
          Except[_String|_FrontEnd`FileName]:>
            FirstCase[sd, 
              StyleData[StyleDefinitions->s_, ___]:>s, 
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
  GetThemedStylesheet@getNbFileSSheet[nbFile]


(* ::Subsubsubsection::Closed:: *)
(*getFileStylesheet*)



getFileStylesheet[nb_, file_]:=
  Module[
    {
      fExt = FileExtension[file]
      },
      Replace[getFExtStylesheet[fExt],
        None:>If[fExt==="nb", getStylesheetStylesheet[file], None]
        ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*setNbFileStyle*)



(* ::Text:: *)
(*
	This is a little too slow in general... like .3s? We can probably do better by only updating when the 
	actual base stylesheet changes?
*)



setNbFileStyle[nb_, file_]:=
  With[{f=getFileStylesheet[nb, file]},
    If[f=!=IDEData[nb, {"Styles", "UnthemedStylesheet"}],
      IDEData[nb, {"Styles", "UnthemedStylesheet"}] = f;
      SetThemedStylesheet[nb, GetCleanStylePath[nb, f]];
      True,
      False
      ]
    ];


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



(* ::Text:: *)
(*
	This is like .2s in general...
*)



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
      UpdateNotebookToolbars[nb]; (* seems to be necessary...? *)
      True,
      False
      ];
    ]


(* ::Subsubsection::Closed:: *)
(*setAutoSave*)



setAutoSave[nb_]:=
  Module[{aug = GetCurrentValue[nb, AutoGeneratedPackage]},
    If[aug === Automatic,
      IDEData[nb, "AutoGeneratePackage"] = True,
      SetCurrentValue[nb, AutoGeneratedPackage, Inherited];
      IDEData[nb, "AutoGeneratePackage"] = False
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*setNbActions*)



setNbActions[nb_]:=
  Module[{nbActs, saveAction},
    (* reset the actions to start *)
    SetCurrentValue[nb, NotebookEventActions, Inherited];
    (* pull the events from the stylesheet *)
    nbActs = GetCurrentValue[nb, NotebookEventActions];
    If[MemberQ[Keys@nbActs, {"MenuCommand", "Save"}],
      saveAction = 
        Extract[Association[nbActs],
          Key[{"MenuCommand", "Save"}],
          Hold
          ],
      saveAction = None
      ];
    If[MatchQ[saveAction, 
        Hold[IDESave[EvaluationNotebook[]]]|
          Hold[CompoundExpression[_Needs, IDESave[EvaluationNotebook[]]]]
        ],
      saveAction = None
      ];
    IDEData[nb, "SavingAction"] = saveAction;
    SetCurrentValue[nb, 
      NotebookEventActions,
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
      Sequence@@Flatten[List@@opts]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*NotebookPutFile*)



(* ::Text:: *)
(*
	Should make use of the tab cache to find some way to check if I need to reload from disk...
*)



NotebookPutFile//Clear
NotebookPutFile[nb_NotebookObject, f_String, data:_Notebook|None:None]:=
  Module[
    {
      nbObj,
      nbExpr = data,
      stylesChanged,
      tbChanged
      },
    (* since we need to handle autogeneration stuff too... *)
    SetCurrentValue[nb, AutoGeneratedPackage, Inherited];
    If[nbExpr===None,
      Switch[FileExtension[f],
        "nb",
          nbExpr = Get[f],
        _,
          nbObj = NotebookOpen[f, Visible->False];
          nbExpr = NotebookGet[nbObj];
          NotebookClose[nbObj];
        ]
      ];
    WithNotebookPaused[
      nb,
      stylesChanged = setNbFileStyle[nb, f];
      tbChanged = setNbFileToolbar[nb, f];
      NotebookPutContents[nb, Hold[nbExpr]];
      (* can't see why not to put it here... ? *)
      If[stylesChanged,
        setAutoSave[nb];
        setNbActions[nb];
        ];
      ];
    ];


(* ::Subsubsection::Closed:: *)
(*notebookSaveNotebook*)



If[!ValueQ[$SaveNotebookMethod], $SaveNotebookMethod = notebookSaveNotebook];


$poisonBoxes = _GraphicsBox|_Graphics3DBox|_Raster3DBox|_RasterBox;


notebookSaveNotebook[f_, nb_]:=
  With[{expr=GetNotebookExpression[nb]},
    If[!FreeQ[expr[[1]], $poisonBoxes],
      Export[f, expr, "Notebook"],
      Put[expr, f]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*notebookHandleAutoSave*)



notebookHandleAutoSave[f_, nb_]:=
  Module[{nbFName, nbPkgName},
    If[IDEData[nb, "AutoGeneratePackage"],
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
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*NotebookSaveContents*)



NotebookSaveContents//Clear
Options[NotebookSaveContents]=
  {
    "AutoGenerateSave"->True,
    "HandleSavingAction"->True,
    "ClearCache"->True,
    "Preemptive"->False
    };
Module[{recurseProtect},
  NotebookSaveContents[nb_NotebookObject, 
    file:_String|Automatic:Automatic,
    ops:OptionsPattern[]
    ]:=
    Block[
      {
        preemptive = False,
        recurseProtect = !preempt&&TrueQ[recurseProtect]
        },
      If[!recurseProtect,
        recurseProtect=True;
        Module[
          {
            f = file,
            dir,
            nbExpr,
            nbObj,
            ags = TrueQ@OptionValue["AutoGenerateSave"],
            sa = TrueQ@OptionValue["HandleSavingAction"]
            },
          If[f === Automatic,
            f = IDEPath[nb, Key["ActiveFile"]]
            ];
          If[f=!=None,
            f = IDEPath[nb, f];
            Switch[FileExtension[f],
              "nb",
                If[preemptive,
                  PreemptiveQueued[nb, notebookSaveNotebook[f, nb]],
                   $SaveNotebookMethod[f, nb];
                  ];
                If[ags,
                  If[preemptive,
                    Function[Null, PreemptiveQueued[nb, #], HoldAllComplete],
                    #&
                    ]@notebookHandleAutoSave[f, nb]
                  ];
               If[sa,
                 ReleaseHold@IDEData[nb, "SavingAction"]
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
          ];
        If[OptionValue["ClearCache"],
          ClearCachedTabData[nb]
          ]
        ]
      ];
    ];
NotebookSaveContents[nb_NotebookObject, 
    file:_String|Automatic:Automatic,
    preempt:True|False,
    ops:OptionsPattern[]
    ]:=
    NotebookSaveContents[nb, file, "Preemptive"->preempt, ops]


(* ::Subsubsection::Closed:: *)
(*NotebookPutScratch*)
 


NotebookPutScratch[nb_, expr_Notebook]:=
  NotebookPutFile[nb, CreateProjectScratchFile[nb, expr]]


(* ::Subsection:: *)
(*File Operations*)



(* ::Subsubsection::Closed:: *)
(*EnsureNotebookUpdated*)



EnsureNotebookUpdated[nb_NotebookObject, openDialog:True|False:True]:=
  Module[
    {
      nbDate = 
        FromAbsoluteTime[Lookup[NotebookInformation[nb], "MemoryModificationTime"], TimeZone->0],
      buffer = Quantity[3, "Seconds"],
      active = IDEPath[nb, Key["ActiveFile"]],
      needsUpdate,
      hasDeclined
      },
    needsUpdate = Quiet[TrueQ[FileDate[active]>nbDate+buffer]];
    If[needsUpdate&&openDialog,
      hasDeclined = IDEData[nb, PrivateKey["CheckUpdateData"]];
      If[!AssociationQ@hasDeclined,
        hasDeclined = <|"Tab"->active, "InUpdate"->False, "HasDeclined"->False|>
        ];
      If[(!TrueQ[hasDeclined["InUpdate"]]&&!TrueQ[hasDeclined["HasDeclined"]])||
          hasDeclined["Tab"]=!=active,
        With[{active=active, hasDeclined=hasDeclined},
          IDEData[nb, PrivateKey["CheckUpdateData"]] = 
            <|"Tab"->active, "InUpdate"->True, "HasDeclined"->hasDeclined["HasDeclined"]|>;
          CreateAttachedDialog[
            nb,
            <|
              "Header"->"Update from Disk?",
              "Body"->"File changed on disk. Would you like to reload?",
              "SubmitButton"->
                {
                  "Reload",
                  Function[
                    NotebookDelete[EvaluationCell[]];
                    NotebookPutFile[nb, active];
                    IDEData[nb, PrivateKey["CheckUpdateData"]] = 
                      Append[hasDeclined, "HasDeclined"->False];
                    needsUpdate = False
                    ]
                  },
              "CancelButton"->
                {
                  "Cancel",
                  Function[
                    NotebookDelete[EvaluationCell[]];
                    IDEData[nb, PrivateKey["CheckUpdateData"]] = 
                      Append[hasDeclined, "HasDeclined"->True];
                    ]
                  }
              |>
            ]
          ]
        ]
      ];
    !needsUpdate
    ]


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
IDEOpen[e:_String?FileExistsQ|_Notebook]:=
  IDEOpen[$CurrentIDENotebook, e];


(* ::Subsubsection::Closed:: *)
(*IDESave*)



IDESave//Clear
IDESave[nb_NotebookObject, ops:OptionsPattern[]]:=
  NotebookSaveContents[nb, ops];
IDESave[nb_IDENotebookObject, ops:OptionsPattern[]]:=
  IDESave[nb["Notebook"], ops];
IDESave[ops:OptionsPattern[]]:=
  IDESave[$CurrentIDENotebook, ops];


(* ::Subsubsection::Closed:: *)
(*IDEClose*)



IDEClose[nb_NotebookObject, tabName_]:=
  If[IDETabExists[tabName],
    NotebookCloseTab[nb, tabName]
    ];
IDEClose[nb_IDENotebookObject, tabName_]:=
  IDEClose[nb["Notebook"], tabName];
IDEClose[tabName_]:=
  IDEClose[$CurrentIDENotebook, tabName];


End[];



