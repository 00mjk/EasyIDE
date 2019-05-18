(* ::Package:: *)

(* Autogenerated Package *)

(* ::Text:: *)
(*Functions for getting IDE data*)



IDEData::usage="";
IDEPath::usage="";


Begin["`Private`"];


(* ::Subsection:: *)
(*IDE Data*)



(* ::Subsubsection::Closed:: *)
(*ideNbData*)



ideNbData[nb_, {opts___}, default_]:=
  GetCurrentValue[nb, {TaggingRules, $PackageName, opts}, default];
ideNbData[nb_, {opts___}]:=
  GetCurrentValue[nb, {TaggingRules, $PackageName, opts}];
ideNbData[nb_, opt_String, default_]:=
  ideNbData[nb, {opt}, default];
ideNbData[nb_, opt_String]:=
  ideNbData[nb, {opt}];
ideNbData[nb_]:=
  ideNbData[nb, {}];


(* ::Subsubsection::Closed:: *)
(*ideSetNbData*)



iSCV//Clear;
iSCVD//Clear;


iSCV[nb_, {opts___}, value_]:=
  SetCurrentValue[nb, {TaggingRules, $PackageName, opts}, value];
iSCVD[nb_, {opts___}, value_]:=
  SetCurrentValueDelayed[nb, {TaggingRules, $PackageName, opts}, value];


ideSetNbData[nb_, {opts___}, value_]:=
  iSCV[nb, {opts}, value];
ideSetNbData[nb_, opts_, value_]:=
  ideSetNbData[nb, {opts}, value];
ideSetNbDataDelayed[nb_, opts_, value_]:=
  iSCVD[nb, Flatten[{opts}, 1], Hold[value]];
ideSetNbDataDelayed~SetAttributes~HoldRest;


(* ::Subsubsection::Closed:: *)
(*ideTmpData*)



If[!ValueQ[$ideDataCache],
  $ideDataCacheTag = $FrontEndSession;
  (* for some reason the $FrontEnd object went out of scope...? *)
  $ideDataCache=Language`NewExpressionStore["IDEState"]
  ];


ideTmpData[nb_, key_]:=
  With[{base=$ideDataCache@"get"[$FrontEndSession, nb[[2]]]},
    If[!AssociationQ@base,
      $ideDataCache@"put"[$FrontEndSession, nb[[2]], <||>];
      Missing["KeyAbset", key],
      base[key]
      ]
    ];
ideSetTmpData[nb_, key_, val_]:=
  Module[{base=$ideDataCache@"get"[$FrontEndSession, nb[[2]]]},
    If[!AssociationQ@base,
      $ideDataCache@"put"[$FrontEndSession, nb[[2]], <|key->val|>],
      base[key]=val;
      $ideDataCache@"put"[$FrontEndSession, nb[[2]], base]
      ]
    ];
ideTmpData[nb_, key_, val_]:=
  Replace[
    ideTmpData[nb, key],
    _Missing:>(ideSetTmpData[nb, key, val];val)
    ]


ideTmpDataClean[]:=
  (
    If[NotebookInformation[NotebookObject[$FrontEnd, #[[2]]]]===$Failed,
      $ideDataCache
      ]&/@Flatten[test@"listTable"[], 1]
    );


(* ::Subsubsection::Closed:: *)
(*ideActiveTab*)



ideActiveTab[nb_]:=
  ideNbData[nb, "ActiveTab", None];


(* ::Subsubsection::Closed:: *)
(*ideActiveFile*)



ideActiveFile[nb_]:=
  With[{t=ideActiveTab[nb]},
    If[t=!=None,
      ideNbData[nb, {"Tabs", t, "File"}, None],
      t
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*ideAbsPath*)



ideAbsPath[nb_NotebookObject, ""]:=
  ideProjectDir[nb];
ideAbsPath[nb_NotebookObject, file_]:=
  Module[
    {
      absFile = file,
      expF,
      dir
      },
   expF = ExpandFileName[absFile];
    If[expF =!= absFile,
      dir = ideProjectDir[nb];
      Which[
        FileExistsQ@FileNameJoin@{dir, absFile}, (* I want this to be the first tested branch *)
          absFile = FileNameJoin@{dir, absFile},
        FileExistsQ@expF,
          absFile = expF,
        True,
          absFile = FileNameJoin@{dir, absFile}
        ]
      ];
    absFile
    ]


(* ::Subsubsection::Closed:: *)
(*IDEData*)



IDEData//Unprotect
IDEData//Clear


(* ::Subsubsubsection::Closed:: *)
(*notebookObjectQ*)



notebookObjectQ[nb_]:=
  MatchQ[nb, _NotebookObject]||
    MatchQ[FE`Evaluate@nb, _NotebookObject]


(* ::Subsubsubsection::Closed:: *)
(*getNbObj*)



getNbObj[nb_]:=
  Replace[nb,
    e:Except[_NotebookObject]:>FE`Evaluate[e]
    ]


(* ::Subsubsubsection::Closed:: *)
(*Normal*)



IDEData[
  nb:_NotebookObject|_FrontEnd`EvaluationNotebook|_FrontEnd`InputNotebook, 
  key:_String|_Symbol|{(_String|_Symbol)..}, 
  default_
  ]:=
  ideNbData[nb, key, default];
IDEData[
  nb:_NotebookObject|_FrontEnd`EvaluationNotebook|_FrontEnd`InputNotebook, 
  key:(_String|_Symbol|{(_String|_Symbol)..})
  ]:=
  ideNbData[nb, key];


IDEData/:
  HoldPattern[ 
    IDEData[
      nb:_NotebookObject|_?notebookObjectQ, 
      key:(_String|_Symbol|{(_String|_Symbol)..})
      ]~Set~val_
    ]:=
    ideSetNbData[getNbObj@nb, key, val];
IDEData/:
  HoldPattern[ 
    IDEData[
      nb:_NotebookObject|_?notebookObjectQ, 
      key:(_String|_Symbol|{(_String|_Symbol)..})
      ]~SetDelayed~val_
    ]:=
    ideSetNbDataDelayed[getNbObj@nb, key, Hold[val]];


(* ::Subsubsubsection::Closed:: *)
(*Temporary*)



IDEData[nb_NotebookObject, PrivateKey[key_]]:=
  ideTmpData[nb, key];
IDEData[nb_NotebookObject, PrivateKey[key_], default_]:=
  ideTmpData[nb, key, default];
IDEData/:
  HoldPattern[
    IDEData[nb:_NotebookObject|_?notebookObjectQ, PrivateKey[key_]]~Set~val_
    ]:=
    ideSetTmpData[getNbObj@nb, key, val];


(* ::Subsubsubsection::Closed:: *)
(*IDENotebookObject*)



IDEData[ide_IDENotebookObject, key_, default___]:=
  Module[{nb=ide["Notebook"], res},
    res = IDEData[nb, key, default];
    res/;Head[res]=!=IDEData
    ];
IDEData/:
  HoldPattern[
    IDEData[ide_?(MatchQ[#, _IDENotebookObject]&), 
      key:(_String|_Symbol|{(_String|_Symbol)..}|_PrivateKey)
      ]~Set~val_
    ]:=
    Module[{nb=ide["Notebook"], res},
      IDEData[nb, key]=val
      ];
IDEData/:
  HoldPattern[
    IDEData[ide_?(MatchQ[#, _IDENotebookObject]&), 
      key:(_String|_Symbol|{(_String|_Symbol)..}|_PrivateKey)
      ]~SetDelayed~val_
    ]:=
    Module[{nb=ide["Notebook"], res},
      IDEData[nb, key]:=val
      ];


(* ::Subsubsubsection::Closed:: *)
(*No Object*)



IDEData[key:(_String|_Symbol|{(_String|_Symbol)..}|_PrivateKey)]:=
  IDEData[$CurrentIDENotebook, key];
IDEData/:
  HoldPattern[ 
    IDEData[
      key:(_String|_Symbol|{(_String|_Symbol)..}|_PrivateKey)
      ]~Set~val_
    ]:=
    IDEData[$CurrentIDENotebook, key]~Set~val;
IDEData/:
  HoldPattern[ 
    IDEData[
      key:(_String|_Symbol|{(_String|_Symbol)..}|_PrivateKey)
      ]~SetDelayed~val_
    ]:=
    IDEData[$CurrentIDENotebook, key]~Set~val;


(* ::Subsubsubsection::Closed:: *)
(*Protect*)



IDEData//Protect


(* ::Subsubsection::Closed:: *)
(*ideProjectDir*)



ideProjectDir[nb_]:=
  ideNbData[nb, {"Project", "Directory"}];


(* ::Subsubsection::Closed:: *)
(*IDEPath*)



IDEPath//Clear


IDEPath[nb_NotebookObject, fileName_String]:=
  ideAbsPath[nb, fileName];
IDEPath[ide_IDENotebookObject, fileName_String]:=
  ideAbsPath[ide["Notebook"], fileName];


IDEPath[nb_NotebookObject, Key["ActiveFile"]]:=
  ideActiveFile[nb];
IDEPath[ide_IDENotebookObject, k_Key]:=
  IDEPath[ide["Notebook"], k];


IDEPath[nb_NotebookObject]:=
  ideProjectDir[nb];
IDEPath[ide_IDENotebookObject]:=
  ideProjectDir[ide["Notebook"]];


IDEPath[k_]:=
  IDEPath[$CurrentIDENotebook, k];
IDEPath[]:=
  IDEPath[$CurrentIDENotebook]


End[];



