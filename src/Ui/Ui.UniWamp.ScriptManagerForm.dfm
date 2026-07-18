object ScriptManagerForm: TScriptManagerForm
  Left = 0
  Top = 0
  Caption = 'UniWamp script manager'
  ClientHeight = 780
  ClientWidth = 1043
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
    Width = 1043
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
    ExplicitWidth = 1048
    object FMainPanel: TPanel
      Left = 12
      Top = 12
      Width = 1019
      Height = 714
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      ExplicitWidth = 1024
      object FColumnSplitter: TSplitter
        Left = 592
        Top = 0
        Width = 6
        Height = 714
        Align = alRight
        AutoSnap = False
        Color = clBtnFace
        MinSize = 410
        ParentColor = False
        ResizeStyle = rsUpdate
        ExplicitLeft = 720
      end
      object FGridHostPanel: TPanel
        Left = 0
        Top = 0
        Width = 592
        Height = 714
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        Padding.Right = 12
        ParentBackground = False
        TabOrder = 0
        ExplicitWidth = 688
        object FHeaderPanel: TPanel
          Left = 0
          Top = 0
          Width = 580
          Height = 109
          Align = alTop
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 1
          ExplicitWidth = 676
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
            Left = 174
            Top = 6
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
            Top = 38
            Width = 35
            Height = 15
            Caption = 'Search'
          end
          object FCategoryLabel: TLabel
            Left = 4
            Top = 73
            Width = 48
            Height = 15
            Caption = 'Category'
          end
          object FHeaderDivider: TBevel
            Left = 0
            Top = 107
            Width = 580
            Height = 2
            Align = alBottom
            Shape = bsTopLine
            ExplicitTop = 134
            ExplicitWidth = 672
          end
          object FSearchEdit: TEdit
            Left = 60
            Top = 36
            Width = 240
            Height = 23
            TabOrder = 0
          end
          object FCategoryCombo: TComboBox
            Left = 60
            Top = 71
            Width = 240
            Height = 23
            Style = csDropDownList
            TabOrder = 1
          end
          object FCmsOnlyCheck: TCheckBox
            Left = 326
            Top = 38
            Width = 49
            Height = 19
            Caption = 'CMS'
            TabOrder = 2
          end
          object FEcommerceOnlyCheck: TCheckBox
            Left = 325
            Top = 73
            Width = 96
            Height = 19
            Caption = 'E-commerce'
            TabOrder = 3
          end
          object FShowInstallTerminalCheck: TCheckBox
            Left = 427
            Top = 36
            Width = 144
            Height = 19
            Caption = 'Show install terminal'
            TabOrder = 4
          end
          object FClearFilterButton: TButton
            Left = 428
            Top = 68
            Width = 110
            Height = 26
            Caption = 'Clear filters'
            TabOrder = 5
          end
        end
        object FGrid: TStringGrid
          Left = 0
          Top = 109
          Width = 580
          Height = 605
          Align = alClient
          ColCount = 4
          DefaultDrawing = False
          FixedCols = 0
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goRowSelect, goThumbTracking]
          TabOrder = 0
          ExplicitWidth = 676
          ColWidths = (
            250
            126
            418
            118)
        end
      end
      object FDetailsPanel: TPanel
        Left = 598
        Top = 0
        Width = 421
        Height = 714
        Align = alRight
        BevelOuter = bvNone
        Color = clWhite
        Padding.Left = 4
        ParentBackground = False
        TabOrder = 1
        ExplicitLeft = 603
        object FDetailsCardPanel: TPanel
          Left = 4
          Top = 0
          Width = 417
          Height = 0
          Align = alTop
          BevelOuter = bvNone
          Color = clWhite
          Padding.Bottom = 8
          ParentBackground = False
          TabOrder = 0
          Visible = False
          ExplicitWidth = 326
          object FDetailTitleLabel: TLabel
            Left = 146
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
            Width = 320
            Height = 104
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
            Left = 284
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
          object FDetailLogoPanel: TPanel
            Left = 24
            Top = 20
            Width = 118
            Height = 118
            BevelOuter = bvNone
            Color = clWhite
            ParentBackground = False
            TabOrder = 2
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
            Left = 146
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
            Left = 214
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
        end
        object FOutputPanel: TPanel
          Left = 4
          Top = 0
          Width = 417
          Height = 714
          Align = alClient
          BevelOuter = bvNone
          Color = 1579032
          Padding.Left = 10
          Padding.Top = 10
          Padding.Right = 10
          Padding.Bottom = 10
          ParentBackground = False
          TabOrder = 1
          ExplicitWidth = 326
          object FOutputHeaderPanel: TPanel
            Left = 10
            Top = 10
            Width = 397
            Height = 76
            Align = alTop
            BevelOuter = bvNone
            Color = 1579032
            ParentBackground = False
            TabOrder = 0
            ExplicitWidth = 306
            DesignSize = (
              397
              76)
            object FOutputTitleLabel: TLabel
              Left = 10
              Top = 8
              Width = 133
              Height = 14
              Caption = 'Installation output'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 8454143
              Font.Height = -12
              Font.Name = 'Consolas'
              Font.Style = [fsBold]
              ParentFont = False
            end
            object FDetailInstallButton: TButton
              Left = 10
              Top = 28
              Width = 375
              Height = 40
              Anchors = [akLeft, akTop, akRight, akBottom]
              Caption = 'Install selected'
              Default = True
              TabOrder = 0
            end
          end
          object FOutputMemo: TMemo
            Left = 10
            Top = 86
            Width = 397
            Height = 618
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 0
            Align = alClient
            BorderStyle = bsNone
            Color = 1579032
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 12615680
            Font.Height = -13
            Font.Name = 'Cascadia Mono'
            Font.Style = []
            Lines.Strings = (
              'PS D:\uniwamp> waiting for install output...')
            ParentFont = False
            ReadOnly = True
            ScrollBars = ssHorizontal
            TabOrder = 1
            ExplicitWidth = 306
          end
        end
      end
    end
    object FFooterPanel: TPanel
      Left = 12
      Top = 726
      Width = 1019
      Height = 42
      Align = alBottom
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      ExplicitWidth = 1024
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
