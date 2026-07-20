object ScriptManagerForm: TScriptManagerForm
  Left = 0
  Top = 0
  Caption = 'UniWamp script manager'
  ClientHeight = 792
  ClientWidth = 1105
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object FRootPanel: TPanel
    Left = 0
    Top = 0
    Width = 1105
    Height = 792
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    Padding.Left = 12
    Padding.Top = 12
    Padding.Right = 12
    Padding.Bottom = 12
    ParentBackground = False
    TabOrder = 0
    object FBottomSplitter: TSplitter
      Left = 12
      Top = 515
      Width = 1081
      Height = 5
      Cursor = crVSplit
      Align = alBottom
      MinSize = 180
      ResizeStyle = rsUpdate
      ExplicitTop = 568
      ExplicitWidth = 1056
    end
    object FHeaderPanel: TPanel
      Left = 12
      Top = 12
      Width = 1081
      Height = 83
      Align = alTop
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object FTitleLabel: TLabel
        Left = 6
        Top = -5
        Width = 153
        Height = 32
        Caption = 'Script Catalog'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object FSearchLabel: TLabel
        Left = 4
        Top = 47
        Width = 35
        Height = 15
        Caption = 'Search'
      end
      object FCategoryLabel: TLabel
        Left = 249
        Top = 47
        Width = 48
        Height = 15
        Caption = 'Category'
      end
      object FSearchEdit: TEdit
        Left = 48
        Top = 43
        Width = 185
        Height = 23
        TabOrder = 0
      end
      object FCategoryCombo: TComboBox
        Left = 311
        Top = 43
        Width = 230
        Height = 23
        Style = csDropDownList
        TabOrder = 1
      end
      object FCmsOnlyCheck: TCheckBox
        Left = 561
        Top = 45
        Width = 49
        Height = 19
        Caption = 'CMS'
        TabOrder = 2
      end
      object FEcommerceOnlyCheck: TCheckBox
        Left = 634
        Top = 45
        Width = 96
        Height = 19
        Caption = 'E-commerce'
        TabOrder = 3
      end
      object FClearFilterButton: TButton
        Left = 921
        Top = 40
        Width = 110
        Height = 26
        Caption = 'Clear filters'
        TabOrder = 4
      end
      object FCreateDatabaseCheck: TCheckBox
        Left = 748
        Top = 43
        Width = 117
        Height = 19
        Caption = 'Create Database'
        Checked = True
        State = cbChecked
        TabOrder = 5
      end
    end
    object FMainPanel: TPanel
      Left = 12
      Top = 95
      Width = 1081
      Height = 420
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      ExplicitHeight = 467
      object FGridHostPanel: TPanel
        Left = 0
        Top = 0
        Width = 1081
        Height = 420
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        ExplicitWidth = 1056
        ExplicitHeight = 401
        object FStatusLabel: TLabel
          Left = 0
          Top = 389
          Width = 1081
          Height = 31
          Align = alBottom
          Caption = 'Ready'
          Layout = tlCenter
          ExplicitTop = 388
        end
        object FGrid: TStringGrid
          Left = 0
          Top = 0
          Width = 1081
          Height = 389
          Align = alClient
          ColCount = 6
          DefaultDrawing = False
          FixedCols = 0
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goRowSelect, goThumbTracking]
          TabOrder = 0
          ExplicitWidth = 1056
          ExplicitHeight = 401
          ColWidths = (
            220
            150
            360
            110
            110
            90)
        end
      end
    end
    object pnlfooter: TPanel
      Left = 12
      Top = 520
      Width = 1081
      Height = 260
      Align = alBottom
      TabOrder = 2
      object FOutputPanel: TPanel
        Left = 1
        Top = 1
        Width = 1079
        Height = 216
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        Padding.Top = 8
        ParentBackground = False
        TabOrder = 0
        ExplicitTop = 21
        ExplicitHeight = 148
        object FOutputHeaderPanel: TPanel
          Left = 0
          Top = 8
          Width = 1079
          Height = 25
          Align = alTop
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          object FOutputTitleLabel: TLabel
            Left = 0
            Top = 0
            Width = 1079
            Height = 15
            Align = alTop
            Caption = 'Details and installation output'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            ExplicitWidth = 102
          end
        end
        object FOutputMemo: TMemo
          Left = 0
          Top = 33
          Width = 1079
          Height = 183
          Align = alClient
          Lines.Strings = (
            'Select a script to view its minimum requirements and installation details.')
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 1
          WordWrap = False
          ExplicitHeight = 115
        end
      end
      object FFooterPanel: TPanel
        Left = 1
        Top = 217
        Width = 1079
        Height = 42
        Align = alBottom
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        ExplicitTop = 169
        DesignSize = (
          1079
          42)
        object FInstallButton: TButton
          Left = 733
          Top = 4
          Width = 212
          Height = 34
          Anchors = [akTop, akRight]
          Caption = 'Install selected'
          Default = True
          TabOrder = 0
        end
        object FCloseButton: TButton
          Left = 959
          Top = 4
          Width = 110
          Height = 34
          Anchors = [akTop, akRight]
          Caption = 'Close'
          TabOrder = 1
        end
      end
    end
  end
end
