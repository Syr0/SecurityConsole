Structure CHARFORMAT2_ 
  cbSize.l 
  dwMask.l  
  dwEffects.l  
  yHeight.l  
  yOffset.l  
  crTextColor.l  
  bCharSet.b  
  bPitchAndFamily.b  
  szFaceName.b[#LF_FACESIZE]  
  _wPad2.w  
  wWeight.w  
  sSpacing.w  
  crBackColor.l  
  lcid.l  
  dwReserved.l  
  sStyle.w  
  wKerning.w  
  bUnderlineType.b  
  bAnimation.b  
  bRevAuthor.b  
  bReserved1.b 
EndStructure

Structure ConsoleType
  Timestamp.i
  Description.s
EndStructure

Global ArialFontNormal = LoadFont(#PB_Any, "Consolas", 8,#PB_Font_HighQuality)

#Boring_Backcolor =$323232
#Alert_Frontcolor =$0000CC

Procedure.s IO_Get_CurrentSecurityEvents(lastminutes=1)
  skip = 3
  Compiler = RunProgram("powershell", "Get-WinEvent -FilterHashtable @{LogName = 'Security';StartTime=(Get-Date) - (New-TimeSpan -minute "+Str(lastminutes)+")} | Select-Object TimeCreated,@{name='NewProcessName';expression={ $_.Properties[5].Value }}, @{name='CommandLine';expression={ $_.Properties[8].Value }}", "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  Output$ = ""
  If Compiler
    While ProgramRunning(Compiler)
      If AvailableProgramOutput(Compiler)
        If skip > 0
          skip -1
          ReadProgramString(Compiler)
          Continue
        EndIf
        
        Output$ + ReadProgramString(Compiler) + Chr(13)
      EndIf
    Wend
    CloseProgram(Compiler) ; Schließt die Verbindung zum Programm
  EndIf
  ProcedureReturn  Output$
EndProcedure
Procedure IO_Set_TransparentWindow(PurebasicWindowHandle, alpha.i);for best results, make it borderless!
  
  If IsWindow(PurebasicWindowHandle)
    Protected WindowID = WindowID(PurebasicWindowHandle)
    SetWindowLongPtr_(WindowID,#GWL_EXSTYLE,#WS_EX_LAYERED)
    SetLayeredWindowAttributes_(WindowID,0,alpha,#LWA_ALPHA)
  EndIf
EndProcedure
Procedure IO_Set_HideFromTaskBar(hWnd.i, Flag.l)
  Protected TBL.ITaskbarList
  CoInitialize_(0)
  If CoCreateInstance_(?CLSID_TaskBarList, 0, 1, ?IID_ITaskBarList, @TBL) = #S_OK
    TBL\HrInit()
    If Flag
      TBL\DeleteTab(hWnd)
    Else
      TBL\AddTab(hWnd)
    EndIf
    TBL\Release()
  EndIf
  CoUninitialize_()
 
  DataSection
    CLSID_TaskBarList:
    Data.l $56FDF344
    Data.w $FD6D, $11D0
    Data.b $95, $8A, $00, $60, $97, $C9, $A0, $90
    IID_ITaskBarList:
    Data.l $56FDF342
    Data.w $FD6D, $11D0
    Data.b $95, $8A, $00, $60, $97, $C9, $A0, $90
  EndDataSection
EndProcedure

ExamineDesktops()
Global Width = 500
Global Height = 400
Global hwnd = OpenWindow(#PB_Any,DesktopUnscaledX(DesktopWidth(0))-Width,DesktopUnscaledY(DesktopHeight(0))-Height-40,Width,Height,"",#PB_Window_BorderLess)
; SetWindowColor(hwnd,RGB(28,28,28))
IO_Set_TransparentWindow(hwnd,220)
StickyWindow(hwnd,1)
IO_Set_HideFromTaskBar(WindowID(hwnd),1)

Global canvas = CanvasGadget(#PB_Any,0,0,DesktopScaledX(Width),DesktopScaledY(Height))
StartDrawing(CanvasOutput(canvas))
Box(0, 0, DesktopScaledX(Width),DesktopScaledY(Height), #Boring_Backcolor)
StopDrawing()

Global NewMap KnownGoods.s()

NewList ConsoleEntry.ConsoleType()

If FileSize(GetCurrentDirectory()+"config.json") <= 0
  MessageRequester("Installation","This seems to be your first running."+#CRLF$+"Please open your local security policies, "+#CRLF$+" adv. surveillence -> System surv ->"+#CRLF$+"Detailed Surv. and check[]"+#CRLF$+Chr(34)+"Monitor process creation"+Chr(34)+#CRLF$+"You can also check everything else.")
EndIf
Procedure RefreshSecurityEvents(trash)
  RefreshMs = 400
  MaxDiffSec = 15
  NewList MyOwnPowershells()
  Repeat
    json = LoadJSON(#PB_Any,GetCurrentDirectory()+"config.json")
    If IsJSON(json)
      ExtractJSONMap(JSONValue(json),KnownGoods())
    EndIf
    AddElement(MyOwnPowershells()) : MyOwnPowershells() = Date()
    Last10.s = IO_Get_CurrentSecurityEvents(1)
    
    FilteredLastMinute.s = ""
    For x = 0 To CountString(Last10,#CR$)
      line$ = StringField(Last10,x+1,#CR$)
     
      If Right(Trim(line$),57) = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" Or Right(Trim(line$),31) = "C:\Windows\System32\conhost.exe"
        date$ = StringField(line$,1," ")
        time$ = StringField(line$,2," ")
        Time = Date(Val(StringField(date$,3,".")),Val(StringField(date$,2,".")),Val(StringField(date$,1,".")),Val(StringField(time$,1,":")),Val(StringField(time$,2,":")),Val(StringField(time$,3,":")))
        ForEach MyOwnPowershells()
          If Abs(MyOwnPowershells() - Time) <= MaxDiffSec
            skip = 1
            Break
          EndIf
        Next
        If skip
          skip = 0
          Continue
        EndIf
      EndIf
      FilteredLastMinute + line$ +#CR$
    Next
    For x = 1 To 20
      FilteredLastMinute +Space(200) + #CR$
    Next
    
    
    StartDrawing(CanvasOutput(canvas))
    DrawingFont(FontID(ArialFontNormal))
    ;Background
    Box(0, 0, DesktopUnscaledX(Width),DesktopUnscaledY(Height), #Boring_Backcolor)
    
    
    For x = 0 To CountString(FilteredLastMinute,#CR$)
      line$ = StringField(FilteredLastMinute,x+1,#CR$)
      Description$ = Trim(Mid(line$,20))
      PrintText$ = Trim(Mid(line$,12))+Space(100)
      If KnownGoods(Description$)
        DrawText(5,x*17,"("+KnownGoods(Description$)+")"+PrintText$,$00FF00,#Boring_Backcolor)
      Else
        DrawText(5,x*17,PrintText$,$2222FFF,#Boring_Backcolor)
        KnownGoods(Description$) = ""
      EndIf
    Next
    
    ;Close Button
    Box(DesktopScaledX(Width)-20,0,20,20,$00020FF)
    DrawText(DesktopScaledX(Width)-20+6,2,"X",$FFFFFF,$00020FF)
    
    ;Question Button
    Box(DesktopScaledX(Width)-40,0,20,20,$FF7777)
    DrawText(DesktopScaledX(Width)-40+6,2,"?",$FFFFFF,$FF7777)
    
    StopDrawing()
    json = CreateJSON(#PB_Any)
    InsertJSONMap(JSONValue(json),KnownGoods())
    SaveJSON(json,GetCurrentDirectory()+"config.json")
        
    Delay(RefreshMs)
  ForEver
EndProcedure
CreateThread(@RefreshSecurityEvents(),0)

Repeat
  WaitWindowEvent(1)
  
  If EventType() = #PB_EventType_LeftButtonDown
    
    GetCursorPos_(@pt.POINT)
    ;Close
    If pt\x >= DesktopScaledX(WindowX(hwnd)+Width)-20 And pt\x <= DesktopScaledX(WindowX(hwnd)+Width)
      If pt\y >= DesktopScaledY(WindowY(hwnd)) And pt\y <= DesktopScaledY(WindowY(hwnd)+20)
        End
      EndIf
    EndIf
    ;Quesiton Mark
    If pt\x >= DesktopScaledX(WindowX(hwnd)+Width)-40 And pt\x <= DesktopScaledX(WindowX(hwnd)+Width-20)
      If pt\y >= DesktopScaledY(WindowY(hwnd)) And pt\y <= DesktopScaledY(WindowY(hwnd)+20)
        MessageRequester("HELP","To white and blacklist, open the file config.json at"+#CRLF$+GetCurrentDirectory()+#CRLF$+"and add names between empty free quotes"+#CRLF$+"If you need more visibility, open your local security policies, "+#CRLF$+" adv. surveillence -> System surv ->"+#CRLF$+"Detailed Surv. and check[]"+#CRLF$+Chr(34)+"Monitor process creation"+Chr(34)+#CRLF$+"You can also check everything else.")
      EndIf
    EndIf
    
  EndIf 
ForEver
; IDE Options = PureBasic 6.00 LTS (Windows - x64)
; CursorPosition = 181
; FirstLine = 115
; Folding = 5
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = searching.ico
; Executable = SecurityConsole.exe