(* ::Package:: *)

Paclet[
  Name -> "EasyIDE",
  Version -> "1.0.1",
  Extensions -> {
    	{
     		"Kernel",
     		"Root" -> ".",
     		"Context" -> "EasyIDE`"
     	},
    	{
     		"FrontEnd",
     		"Prepend" -> True,
     		Prepend -> True
     	},
    	{
     		"Resource",
     		"Root" -> "Resources",
     		"Resources" -> {
       			"Settings",
       			"StyleSheets",
       			{
        				"ExtensionStylesMap",
        				"Settings/Mappings/ExtensionStylesMap.wl"
        			},
       			{
        				"ExtensionToolbarsMap",
        				"Settings/Mappings/ExtensionToolbarsMap.wl"
        			},
       			{
        				"StylesheetStylesMap copy",
        				"Settings/Mappings/StylesheetStylesMap copy.wl"
        			},
       			{
        				"StylesheetStylesMap",
        				"Settings/Mappings/StylesheetStylesMap.wl"
        			},
       			{
        				"StylesheetToolbarsMap",
        				"Settings/Mappings/StylesheetToolbarsMap.wl"
        			},
       			{
        				"FileMenu",
        				"Settings/Plugins/FileMenu.wl"
        			},
       			{
        				"Git",
        				"Settings/Plugins/Git.wl"
        			},
       			{
        				"Paclets",
        				"Settings/Plugins/Paclets.wl"
        			},
       			{
        				"ProjectMenu",
        				"Settings/Plugins/ProjectMenu.wl"
        			},
       			{
        				"CodePackage",
        				"Settings/Toolbars/CodePackage.wl"
        			},
       			{
        				"Package",
        				"Settings/Toolbars/Package.wl"
        			},
       			{
        				"Custom",
        				"StyleSheets/Custom.nb"
        			},
       			{
        				"Mappings",
        				"Settings/Mappings"
        			},
       			{
        				"Plugins",
        				"Settings/Plugins"
        			},
       			{
        				"Toolbars",
        				"Settings/Toolbars"
        			}
       		}
     	}
    }
 ]