object ScriptManagerForm: TScriptManagerForm
  Left = 0
  Top = 0
  Caption = 'UniWamp script manager'
  ClientHeight = 780
  ClientWidth = 1080
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
    Width = 1080
    Height = 780
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    Padding.Left = 12
    Padding.Top = 12
    Padding.Right = 12
    Padding.Bottom = 12
    ParentBackground = False
    TabOrder = 0
    object FHeaderPanel: TPanel
      Left = 12
      Top = 12
      Width = 1056
      Height = 108
      Align = alTop
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object FTitleLabel: TLabel
        Left = 6
        Top = -4
        Width = 149
        Height = 32
        Caption = 'Script catalog'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object FHintLabel: TLabel
        Left = 6
        Top = 34
        Width = 227
        Height = 15
        Caption = 'Install and manage web application scripts.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object FSearchLabel: TLabel
        Left = 4
        Top = 67
        Width = 35
        Height = 15
        Caption = 'Search'
      end
      object FCategoryLabel: TLabel
        Left = 354
        Top = 71
        Width = 48
        Height = 15
        Caption = 'Category'
      end
      object FSearchEdit: TEdit
        Left = 48
        Top = 65
        Width = 280
        Height = 23
        TabOrder = 0
      end
      object FCategoryCombo: TComboBox
        Left = 424
        Top = 65
        Width = 230
        Height = 23
        Style = csDropDownList
        TabOrder = 1
      end
      object FCmsOnlyCheck: TCheckBox
        Left = 678
        Top = 68
        Width = 49
        Height = 19
        Caption = 'CMS'
        TabOrder = 2
      end
      object FEcommerceOnlyCheck: TCheckBox
        Left = 748
        Top = 68
        Width = 96
        Height = 19
        Caption = 'E-commerce'
        TabOrder = 3
      end
      object FClearFilterButton: TButton
        Left = 870
        Top = 63
        Width = 110
        Height = 26
        Caption = 'Clear filters'
        TabOrder = 4
      end
      object FShowInstallTerminalCheck: TCheckBox
        Left = 678
        Top = 88
        Width = 180
        Height = 19
        Caption = 'Show install terminal'
        TabOrder = 5
      end
      object FCreateDatabaseCheck: TCheckBox
        Left = 678
        Top = 112
        Width = 180
        Height = 19
        Caption = 'Create database'
        Checked = True
        State = cbChecked
        TabOrder = 6
      end
    end
    object FMainPanel: TPanel
      Left = 12
      Top = 120
      Width = 1056
      Height = 458
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object FGridHostPanel: TPanel
        Left = 0
        Top = 0
        Width = 682
        Height = 458
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        Padding.Right = 10
        ParentBackground = False
        TabOrder = 0
        object FGrid: TStringGrid
          Left = 0
          Top = 0
          Width = 672
          Height = 458
          Align = alClient
          ColCount = 4
          DefaultDrawing = False
          FixedCols = 0
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goRowSelect, goThumbTracking]
          TabOrder = 0
          ColWidths = (
            250
            126
            418
            118)
        end
      end
      object FDetailsPanel: TPanel
        Left = 682
        Top = 0
        Width = 374
        Height = 458
        Align = alRight
        BevelOuter = bvNone
        Color = clWhite
        Padding.Left = 4
        ParentBackground = False
        TabOrder = 1
        object FDetailsCardPanel: TPanel
          Left = 4
          Top = 0
          Width = 370
          Height = 458
          Align = alClient
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          ExplicitLeft = 6
          ExplicitTop = 2
          object FDetailTitleLabel: TLabel
            Left = 154
            Top = 13
            Width = 115
            Height = 32
            Caption = 'WordPress'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -24
            Font.Name = 'Segoe UI Semibold'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object FDetailSummaryLabel: TLabel
            Left = 24
            Top = 148
            Width = 332
            Height = 112
            AutoSize = False
            Caption = 
              'Download the latest WordPress core into a project folder with WP' +
              '-CLI.'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            WordWrap = True
          end
          object FDetailVersionCaption: TLabel
            Left = 18
            Top = 275
            Width = 38
            Height = 15
            Caption = 'Version'
          end
          object FDetailMethodCaption: TLabel
            Left = 12
            Top = 328
            Width = 76
            Height = 15
            Caption = 'Install method'
          end
          object FDetailMethodValue: TLabel
            Left = 296
            Top = 328
            Width = 38
            Height = 13
            Alignment = taRightJustify
            Caption = 'WP-CLI'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object FDetailDatabaseCaption: TLabel
            Left = 12
            Top = 346
            Width = 76
            Height = 15
            Caption = 'Database'
          end
          object FDetailDatabaseValue: TLabel
            Left = 296
            Top = 346
            Width = 38
            Height = 13
            Alignment = taRightJustify
            Caption = '-'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object FDetailHomepageCaption: TLabel
            Left = 12
            Top = 364
            Width = 76
            Height = 15
            Caption = 'Homepage'
          end
          object FDetailHomepageValue: TLabel
            Left = 154
            Top = 364
            Width = 180
            Height = 13
            Alignment = taRightJustify
            Caption = '-'
            Cursor = crHandPoint
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clHighlight
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsUnderline]
            ParentFont = False
          end
          object FDetailLogoPanel: TPanel
            Left = 24
            Top = 20
            Width = 118
            Height = 118
            BevelOuter = bvNone
            Color = clWhite
            ParentBackground = False
            TabOrder = 3
            object FDetailLogoImage: TImage
              Left = 0
              Top = 0
              Width = 118
              Height = 118
              Align = alClient
              Center = True
              Proportional = True
              Stretch = True
            end
          end
          object FDetailCategoryBadge: TPanel
            Left = 154
            Top = 54
            Width = 76
            Height = 24
            BevelOuter = bvNone
            Color = clMoneyGreen
            ParentBackground = False
            TabOrder = 0
            object FDetailCategoryLabel: TLabel
              Left = 0
              Top = 0
              Width = 24
              Height = 13
              Alignment = taCenter
              Caption = 'CMS'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              Transparent = True
              Layout = tlCenter
            end
          end
          object FDetailVersionBadge: TPanel
            Left = 225
            Top = 271
            Width = 118
            Height = 24
            BevelOuter = bvNone
            ParentBackground = False
            TabOrder = 1
            object FDetailVersionValue: TLabel
              Left = 0
              Top = 0
              Width = 31
              Height = 13
              Alignment = taCenter
              Caption = 'Latest'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              Transparent = True
              Layout = tlCenter
            end
          end
          object FDetailInstallButton: TButton
            Left = 14
            Top = 388
            Width = 314
            Height = 40
            Caption = 'Install selected'
            Default = True
            TabOrder = 2
          end
        end
      end
    end
    object FOutputPanel: TPanel
      Left = 12
      Top = 578
      Width = 1056
      Height = 148
      Align = alBottom
      BevelOuter = bvNone
      Color = clWhite
      Padding.Top = 8
      ParentBackground = False
      TabOrder = 2
      object FOutputHeaderPanel: TPanel
        Left = 0
        Top = 8
        Width = 1056
        Height = 34
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object FOutputTitleLabel: TLabel
          Left = 10
          Top = 8
          Width = 102
          Height = 15
          Caption = 'Installation output'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object FOutputMemo: TMemo
        Left = 0
        Top = 42
        Width = 1056
        Height = 106
        Align = alClient
        Lines.Strings = (
          'Installation logs will appear here.')
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
        WordWrap = False
      end
    end
    object FFooterPanel: TPanel
      Left = 12
      Top = 726
      Width = 1056
      Height = 42
      Align = alBottom
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 3
      object FStatusLabel: TLabel
        Left = 0
        Top = 8
        Width = 32
        Height = 15
        Caption = 'Ready'
        Layout = tlCenter
      end
      object FCloseButton: TButton
        Left = 946
        Top = 4
        Width = 110
        Height = 34
        Caption = 'Close'
        TabOrder = 0
      end
    end
  end
end
