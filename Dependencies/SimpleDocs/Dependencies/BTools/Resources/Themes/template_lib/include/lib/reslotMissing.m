With[{
  tempArgs=
    (Join@@
      Flatten@{
        #,
        Replace[Templating`$TemplateArgumentStack,{
            {___,a_}:>a,
            _-><||>
          }]
        }),
  expr=
    #2,
  tag=
    #3
  },
  ReplaceAll[expr,
    {
      Missing[_, tag]:>
        tempArgs[tag]
      }
    ]
  ]&