(* ::Package:: *)

(* Autogenerated Package *)

WithNotebookPaused::usage="Pauses the notebook temporarily to execute code";
PreemptiveQueued::usage="Evaluates preemptive code in a queued fashion";


WithFrontEndTracking::usage=
  "Executes with FrontEnd tracking enabled";
WithoutCurrentValueUpdating::usage=
  "Executes with FrontEnd tracking disabled";
WithCurrentValueUpdating::usage=
  "Alias for WithFrontEndTracking";
WithoutCurrentValueUpdating::usage=
  "Alias for WithoutFrontEndTracking";


WithoutDynamics::usage=
  "Executes with DynamicUpdating paused";
WithoutScreenUpdates::usage=
  "Executes with DynamicUpdating paused";
WithoutScreenUpdatesOrDynamics::usage=
  "Turns of both screen updates and DynamicUpdating in a clean fashion";


WithActiveNotebookPath::usage=
  "Temporarily sets NotebookFileName and NotebookDirectory to the ActiveFile path";


(* ::Text:: *)
(*Consistent references to the current IDE notebook*)



$CurrentIDENotebook::usage="";
$CurrentIDE::usage="";


GetCurrentValue::usage="Just reimplements CurrentValue for when it's needed";
SetNotebookOptions::usage="Reimplements SetOptions for when that is needed";
SetCurrentValue::usage="";
SetCurrentValueDelayed::usage="";
SetCurrentValues::usage="Batch form of SetCurrentValue";
SetCurrentValuesDelayed::usage="Batch form of SetCurrentValueDelayed";
WithIDEData::usage="Reroutes CurrentValue to the EasyIDE path";


Begin["`Private`"];


(* ::Subsection:: *)
(*CurrentValues*)



(* ::Text:: *)
(*
	I do a lot of hoop jumping to avoid having to call into the front end multiple times but I think it\[CloseCurlyQuote]s worth it...
*)



(* ::Subsubsection::Closed:: *)
(*iCurrentValue*)



GetCurrentValue[a___]:=
  iCurrentValue[a]


iCurrentValue[a___]/;!TrueQ[$inCVHeld]:=
  Block[{FrontEnd`CurrentValue},
    With[{c=FrontEnd`CurrentValue[a]},
      Replace[
        MathLink`CallFrontEnd[
          FrontEnd`Value[c, FrontEnd`$TrackingEnabled]],
        c->$Failed
        ]
      ]
    ];
 iCurrentValue[nb_, k_]/;TrueQ[$inCVHeld]:=
   If[KeyExistsQ[$setCurrentValueStack, {nb, k}],
     $setCurrentValueStack[{nb, k}],
     Inherited
     ];
  iCurrentValue[nb_, k_, default_]/;TrueQ[$inCVHeld]:=
   If[KeyExistsQ[$setCurrentValueStack, {nb, k}],
     $setCurrentValueStack[{nb, k}],
     $setCurrentValueStack[{nb, k}] = default
     ]


(* ::Subsubsection::Closed:: *)
(*iSetOptions*)



SetNotebookOptions[o_, a___]:=
  Block[{FrontEnd`SetOptions},
    MathLink`CallFrontEnd@
      FrontEnd`SetOptions[o, a]
    ]


(* ::Subsubsection::Closed:: *)
(*SetCurrentValue*)



SetCurrentValue//Clear
SetCurrentValue[nb_, k_, value_]:=
  iSetCurrentValue[nb, k, value];
iSetCurrentValue[nb_, k_, value_]/;!TrueQ[$inCVHeld]:=
  With[{h=FrontEnd`$TrackingEnabled},
      MathLink`CallFrontEndHeld[
        FrontEnd`SetValue[
            FEPrivate`Set[
              FrontEnd`CurrentValue[nb, k], 
            value
              ],
            h
            ]
        ]
      ];
iSetCurrentValue[nb_, k_, value_]/;TrueQ[$inCVHeld]:=
  $setCurrentValueStack[{nb, k}] = value;


SetCurrentValues[triples_]:=
  MathLink`CallFrontEnd@FrontEnd`SetValue@
    Map[
      FEPrivate`Set[
        FrontEnd`CurrentValue[#[[1, 1]], #[[1, 2]]], 
        #[[2]]
          ]&,
        triples
        ];
SetCurrentValuesDelayed[triples_]:=
  With[
    {
      r=FrontEnd`SetValue@
        Map[
          FEPrivate`SetDelayed[
            FrontEnd`CurrentValue[#[[1, 1]], #[[1, 2]]], 
            Extract[#[[2]], 1, Unevaluated]
              ]&,
            triples
            ]
        },
    MathLink`CallFrontEndHeld[r]
    ]


(* ::Subsubsection::Closed:: *)
(*SetCurrentValueDelayed*)



SetCurrentValueDelayed//Clear
SetCurrentValueDelayed[nb_, k_, Hold[value_]]:=
  With[{h=FrontEnd`$TrackingEnabled},
    MathLink`CallFrontEndHeld[
      FrontEnd`SetValue[
        FEPrivate`SetDelayed[
          FrontEnd`CurrentValue[nb, k], 
          value
          ],
        h
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*WithIDEData*)



WithIDEData[nb_, expr_]:=
  Block[
    {
      CurrentValue,
      FrontEnd`Options
      },
    CurrentValue[a_, b_, c___]:=
      Block[{CurrentValue=iCurrentValue, k=Flatten@{"Options", b}},
        IDEData[a, k, c]
        ];
    CurrentValue/:
      (CurrentValue[a_, b_, c___] = v_):=
        Block[{CurrentValue=iCurrentValue},
          With[{k=Flatten@{"Options", b}},
            IDEData[a, k] = v
            ]
          ];
    CurrentValue/:
      (CurrentValue[a_, b_, c___] := v_):=
        Block[{CurrentValue=iCurrentValue},
          With[{k=Flatten@{"Options", b}},
            IDEData[a, k] := v
            ]
          ];
    FrontEnd`Options[n_]:=
      Block[
        {
          iCurrentValue=
            FrontEnd`Value[
              FrontEnd`CurrentValue[##], 
              FrontEnd`$TrackingEnabled
              ]&
          },
        IDEData[n, "Options"]
        ];
    Internal`InheritedBlock[{NotebookGet},
      Unprotect[NotebookGet];
      NotebookGet[nb]:=
        Block[
          {
            NotebookGet=MathLink`CallFrontEnd[FrontEnd`NotebookGet[nb]]&,
            CurrentValue=iCurrentValue
            },
          GetNotebookExpression[nb]
          ];
      expr
      ]
    ];
WithIDEData~SetAttributes~HoldRest;


(* ::Subsection:: *)
(*IDE Refs*)



$CurrentIDENotebook := EvaluationNotebook[];
$CurrentIDE := IDENotebookObject[$CurrentIDENotebook];


(* ::Subsection:: *)
(*Pausing*)



(* ::Subsubsection::Closed:: *)
(*WithoutDynamics*)



WithoutDynamics//Clear;
WithoutDynamics[nb_NotebookObject, expr_]:=
  Block[
    {
      dynamicsOff = If[TrueQ@dynamicsOff, True, False]
      },
      If[dynamicsOff,
        expr,
        Internal`WithLocalSettings[
          SetOptions[nb, DynamicUpdating->False],
          dynamicsOff = True;
          expr,
          SetOptions[nb, DynamicUpdating->Automatic]
          ]
        ]
      ];
WithoutDynamics[e:Except[_NotebookObject], expr_]:=
  With[
    {
      nb=
        Replace[e, 
          n:_FrontEnd`InputNotebook|_FrontEnd`EvaluationNotebook:>FE`Evaluate[n]
          ]
      },
    WithoutDynamics[nb, expr]/;MatchQ[nb, NotebookObject]
    ];
WithoutDynamics[expr_]:=
  WithoutDynamics[$CurrentIDENotebook, expr];
WithoutDynamics~SetAttributes~HoldAll;


(* ::Subsubsection::Closed:: *)
(*WithoutScreenUpdates*)



WithoutScreenUpdates//Clear;
WithoutScreenUpdates[nb_NotebookObject, expr_]:=
  Block[
    {
      noScreen = If[TrueQ@noScreen, True, False]
      },
      If[noScreen,
        expr,
        Internal`WithLocalSettings[
          FrontEndExecute@
            FrontEnd`NotebookSuspendScreenUpdates[nb],
          noScreen = True;
          expr,
          FrontEndExecute@
            FrontEnd`NotebookResumeScreenUpdates[nb]
          ]
        ]
      ];
WithoutScreenUpdates[e:Except[_NotebookObject], expr_]:=
  With[
    {
      nb=
        Replace[e, 
          n:_FrontEnd`InputNotebook|_FrontEnd`EvaluationNotebook:>FE`Evaluate[n]
          ]
      },
    WithoutScreenUpdates[nb, expr]/;MatchQ[nb, NotebookObject]
    ];
WithoutScreenUpdates[expr_]:=
  WithoutScreenUpdates[$CurrentIDENotebook, expr];
WithoutScreenUpdates~SetAttributes~HoldAll;


(* ::Subsubsection::Closed:: *)
(*WithoutScreenUpdatesOrDynamics*)



WithoutScreenUpdatesOrDynamics//Clear;
WithoutScreenUpdatesOrDynamics[nb_NotebookObject, expr_]:=
  Block[
    {
      noScreen = If[TrueQ@noScreen, True, False],
      dynamicsOff = If[TrueQ@dynamicsOff, True, False]
      },
      Which[
        noScreen && dynamicsOff,
          expr,
        noScreen,
          WithoutDynamics[nb, expr],
        dynamicsOff,
          WithoutScreenUpdates[nb, expr],
        True,
          Internal`WithLocalSettings[
            FrontEndExecute@{
              FrontEnd`NotebookSuspendScreenUpdates[nb],
              FrontEnd`SetOptions[nb, DynamicUpdating->False]
              },
            noScreen = True;
            expr,
            FrontEndExecute@{
              FrontEnd`NotebookResumeScreenUpdates[nb],
              FrontEnd`SetOptions[nb, DynamicUpdating->Automatic]
              }
            ]
          ]
      ];
WithoutScreenUpdatesOrDynamics[e:Except[_NotebookObject], expr_]:=
  With[
    {
      nb=
        Replace[e, 
          n:_FrontEnd`InputNotebook|_FrontEnd`EvaluationNotebook:>FE`Evaluate[n]
          ]
      },
    WithoutScreenUpdatesOrDynamics[nb, expr]/;MatchQ[nb, NotebookObject]
    ];
WithoutScreenUpdatesOrDynamics[expr_]:=
  WithoutScreenUpdatesOrDynamics[$CurrentIDENotebook, expr];
WithoutScreenUpdatesOrDynamics~SetAttributes~HoldAll;


(* ::Subsubsection::Closed:: *)
(*WithFrontEndTracking*)



WithFrontEndTracking[expr_]:=
  Block[
    {
      FrontEnd`$TrackingEnabled = True,
      $inCVHeld = False,
      $setCurrentValueStack = 
        If[!AssociationQ[$setCurrentValueStack], <||>, $setCurrentValueStack]
      },
   SetCurrentValues[KeyValueMap[List, $setCurrentValueStack]];
   $setCurrentValueStack = <||>;
    expr
    ];
WithFrontEndTracking~SetAttributes~HoldRest


(* ::Subsubsection::Closed:: *)
(*WithoutFrontEndTracking*)



WithoutFrontEndTracking//Clear
WithoutFrontEndTracking[expr_]:=
  Block[
    {
      FrontEnd`$TrackingEnabled = False,
      $headCall = If[TrueQ[$headCall], False, True],
      $inCVHeld = True,
      $setCurrentValueStack = 
        If[!AssociationQ[$setCurrentValueStack], <||>, $setCurrentValueStack]
      },
    Internal`WithLocalSettings[
      (* don't need to process $setCurrentValueStack before hand *)
      None,
      expr,
      If[$headCall, (* if we've bottomed out we call into the FE *)
        SetCurrentValues[KeyValueMap[List, $setCurrentValueStack]]
        ]
      ]
    ];
WithoutFrontEndTracking~SetAttributes~HoldRest


(* ::Subsubsection::Closed:: *)
(*WithCurrentValueUpdating*)



WithCurrentValueUpdating = WithFrontEndTracking;


(* ::Subsubsection::Closed:: *)
(*WithoutCurrentValueUpdating*)



WithoutCurrentValueUpdating = WithoutFrontEndTracking;


(* ::Subsubsection::Closed:: *)
(*WithNotebookPaused*)



(* ::Text:: *)
(*
	Helper function to suspend the screen while updating the nb
*)



WithNotebookPaused//Clear;
WithNotebookPaused[nb_NotebookObject, expr_]:=
  WithoutFrontEndTracking@
    WithoutScreenUpdatesOrDynamics[nb, expr];
WithNotebookPaused[e:Except[_NotebookObject], expr_]:=
  With[
    {
      nb=
        Replace[e, 
          {
            n:_FrontEnd`InputNotebook|_FrontEnd`EvaluationNotebook:>FE`Evaluate[n]
            }
          ]
      },
    WithNotebookPaused[nb, expr]/;MatchQ[nb, NotebookObject]
    ];
WithNotebookPaused[expr_]:=
  WithNotebookPaused[$CurrentIDENotebook, expr];
WithNotebookPaused~SetAttributes~HoldAll;


(* ::Subsection:: *)
(*Preemptive*)



(* ::Subsubsection::Closed:: *)
(*PreemptiveQueued*)



PreemptiveQueued[nb_, expr_]:=
  With[{nnbb=nb},
    MessageDialog[
      DynamicModule[
        {},
        Null,
        Initialization:>{
          Internal`WithLocalSettings[
            Null,
            Block[
              {
                $CurrentIDENotebook=nnbb
                },
              expr
              ],
            NotebookClose[EvaluationNotebook[]]
            ]
          },
        SynchronousInitialization -> False
        ],
      Visible->False,
      Evaluator->CurrentValue[nb, Evaluator]
      ]
    ];
PreemptiveQueued[expr_]:=
  With[{nb=$CurrentIDENotebook},
    PreemptiveQueued[nb, expr]
    ];
PreemptiveQueued~SetAttributes~HoldAll


(* ::Subsection:: *)
(*Paths*)



(* ::Subsubsection::Closed:: *)
(*WithActiveNotebookPath*)



WithActiveNotebookPath[nb_, expr_]:=
  With[{p=IDEPath[nb, Key["ActiveFile"]]},
    If[StringQ[p],
      Internal`InheritedBlock[
        {
          NotebookFileName,
          NotebookDirectory
          },
        Unprotect[NotebookFileName];
        Unprotect[NotebookDirectory];
        NotebookFileName[nb]=p;
        NotebookDirectory[nb]=DirectoryName[p];
        DownValues[NotebookFileName];
        expr
        ],
      expr
      ]
    ];
WithActiveNotebookPath[expr_]:=
  With[{nb=$CurrentIDENotebook},
    WithActiveNotebookPath[nb, expr]
    ];
WithActiveNotebookPath~SetAttributes~HoldAll


End[];



