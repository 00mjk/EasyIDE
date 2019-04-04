(* ::Package:: *)

(* Autogenerated Package *)

DestroyDropDownMenu::usage=
  "Destroys a DropDown menu from its saved state";


AttachDropDownMenu::usage=
  "Attaches a dropdown menu";


Begin["`Private`"];


(* ::Subsection:: *)
(*Attached Cell Menu*)



(* ::Subsubsection::Closed:: *)
(*makeMenuExpr*)



makeMenuExpr[s:Verbatim[Dynamic][state_], menuList_]:=
  Pane[
    Panel[
      Column[
        makeMenuCommand[s, #]&/@menuList,
        GridBoxItemSize->Inherited,
        GridBoxAlignment->Inherited
        ],
      BaseStyle->"CascadingMenuMain"
      ],
    BaseStyle->"CascadingMenuMain",
    ImageSizeAction->"Clip"
    ];


(* ::Subsubsection::Closed:: *)
(*makeMenuCommand*)



makeMenuCommand//Clear


makeMenuCommand[s:Verbatim[Dynamic][state_], label_->list_List]:=
    Button[
      Pane[label, BaseStyle->"CascadingMenuSubmenu"],
      attachMenuExpr[s, EvaluationBox[], makeMenuExpr[s, list]],
      BaseStyle->"CascadingMenuSubmenu",
      Appearance->Inherited
      ]


makeMenuCommand[s:Verbatim[Dynamic][state_], label_:>{command_, ops___}]:=
  EventHandler[
    Button[
      Pane[label, BaseStyle->"CascadingMenuCommand"],
      Internal`WithLocalSettings[
        Null,
        If[Quiet[Lookup[Flatten@{ops}, Method, Automatic]]===Automatic,
          PreemptiveQueued[EvaluationNotebook[], command],
          command
          ],
        If[state["DestroyOnClick"], DestroyDropDownMenu[s]];
        ],
      ButtonData:>s,
      BaseStyle->"CascadingMenuCommand",
      Appearance->Inherited,
      ops
      ],
   {
     "MouseEntered":> pruneMenu[s, EvaluationCell[], False],
     PassEventsDown->True
     }
   ];
makeMenuCommand[s:Verbatim[Dynamic][state_], label_:>command_]:=
  makeMenuCommand[s, label:>{command}]


makeMenuCommand[s:Verbatim[Dynamic][state_], Delimiter]:=
  Framed["", 
    FrameStyle->GrayLevel[.8],
    ImageSize->{Scaled[1], 0},
    FrameMargins->{{0, 0}, {-1, 0}}
    ]


(* ::Subsubsection::Closed:: *)
(*pruneMenu*)



pruneMenu[s:Verbatim[Dynamic][state_], root_, pruneHead:True|False:True]:=
  Module[
    {
      kid
      },
    kid = state[root]["Submenu"];
    WithNotebookPaused[
      ParentNotebook@root,
      If[Head[kid]===CellObject,
        pruneMenu[s, kid]
        ];
      If[pruneHead, 
        NotebookDelete[root];
        If[KeyExistsQ[state, root],
          state[root]=.
          ],
        If[KeyExistsQ[state, root],
          state[root, "Submenu"]=.;
          state[root, "MenuBox"]=.;
          ]
        ]
      ];
    ]


(* ::Subsubsection::Closed:: *)
(*attachMenuExpr*)



attachMenuExpr[s:Verbatim[Dynamic][state_], parentBox_, menuExpr_]:=
  Module[
    {
      parentCell,
      cell,
      currentKids,
      attachPoint,
      subAttach,
      attchPos
      },
    parentCell = ParentCell@parentBox;
    If[!KeyExistsQ[state, parentCell], 
      state[parentCell] = <||>
      ];
    state[parentCell, "MenuBox"];
    If[state[parentCell, "MenuBox"] =!= parentBox || 
        (
          Head[state[parentCell, "Submenu"]] === CellObject&&
            NotebookRead[state[parentCell, "Submenu"]] === $Failed
          ),
      pruneMenu[s, parentCell, False];
      attachPoint = 
        Replace[s["RootPosition"],
          {
            Left->Right,
            n_?Positive->Right,
            _->Left
            }
          ];
      cell=
        FEAttachCell[
          parentBox,
          menuExpr,
          Offset[{0, 0}, 0],
          {attachPoint, Top},
          {Replace[attachPoint, {Left->Right, Right->Left}], Top},
          {"EvaluatorQuit"}
          ];
      state[parentCell, "MenuBox"] = parentBox;
      state[parentCell, "Submenu"] = cell
      ];
    ];


(* ::Subsubsection::Closed:: *)
(*DestroyDropDownMenu*)



DestroyDropDownMenu[s:Verbatim[Dynamic][state_]]:=
  (
    pruneMenu[s, state["RootCell"], True];
    state["RootCell"]=.;
    state["Root"]=.;
    );


(* ::Subsubsection::Closed:: *)
(*AttachDropDownMenu*)



AttachDropDownMenu//Clear
Options[AttachDropDownMenu]=
  {
    "AttachToCell"->True,
    "Position"->Automatic,
    "DestroyOnClick"->True
    }
AttachDropDownMenu[
  stateTracker:(Verbatim[Dynamic][_](*|None*)),
  parentBox:_BoxObject|Automatic:Automatic, 
  menuCommands_List,
  ops:OptionsPattern[]
  ]:=
  With[
    {
      box=Replace[parentBox, Automatic:>EvaluationBox[]],
      position = OptionValue["Position"],
      attachCell = TrueQ@OptionValue["AttachToCell"],
      clickDest = TrueQ@OptionValue["DestroyOnClick"],
      state=
        Replace[stateTracker, 
          None:>Module[{menuState}, Dynamic[menuState]]
          ]
      },
    iMakeMenu[state, box, position, attachCell, clickDest, menuCommands]
    ];


iMakeMenu//Clear
iMakeMenu[
  s:Verbatim[Dynamic][menuState_], 
  box_, 
  position_, 
  attachCell_, 
  clickDest_,
  menuCommands_
  ]:=
  Module[{align, pos},
    align = pos = Replace[position,
        {
          Automatic:>If[attachCell, Right, Left]
          }
         ]; (* this will need an update once I am able to get the box position *)
    menuState["RootPosition"] = align;
    menuState["AttachToCell"] = attachCell;
    menuState["DestroyOnClick"] = clickDest;
    Replace[
      FEAttachCell[
        If[attachCell, ParentCell@box, box],
        If[!AssociationQ[menuState], menuState=<||>];
        menuState["Root"] = box;
        Cell[
          BoxData@ToBoxes@
            makeMenuExpr[
              s, 
              Append[menuCommands, 
              Style["Cancel", Italic]:>
                If[menuState["DestroyOnClick"], None, DestroyDropDownMenu[s]]
              ]
              ]
          ],
        Replace[align, 
          {Left->Automatic, Right->Offset[{-22, -1}, 0]}
          ],
        {align, If[attachCell, Bottom, Top]},
        {If[attachCell, align, Replace[align, {Left->Right, Right->Left}]], Top},
        {(*"OutsideMouseClick", *)"ParentChanged", "EvaluatorQuit"}
        ],
      c_CellObject:>(menuState["RootCell"] = c)
      ]
    ];


End[];



