; SPDX-License-Identifier: GPL-3.0-or-later
; Installatore Windows di DECODIUM SDR, con Inno Setup.
;
; Lo stesso strumento con cui si confeziona DECODIUM: chi installa i due
; programmi sulla stessa macchina incontra la stessa procedura, e chi li
; assiste non deve imparare due installatori. CPack sa già produrre un
; pacchetto NSIS, e resta al suo posto per la release automatica su tag; questo
; è per il pacchetto che si pubblica sul sito, dove conta che l'esperienza sia
; quella dell'ecosistema.
;
; Si compila da una cartella di staging già pronta, quella che esce da
; `cmake --install`: l'installatore non sa costruire nulla e non deve saperlo.
;
;   cmake --install build --prefix staging
;   ISCC /DStagingDir=<percorso assoluto> /DAppVersion=1.2.5 ^
;        /DAppVersionName=Goldsmith decodium-sdr.iss

#ifndef StagingDir
  #error Manca StagingDir: indicare la cartella prodotta da cmake --install
#endif

#ifndef AppVersion
  #error Manca AppVersion: indicare la versione del progetto
#endif

; Il nome della versione. Non obbligatorio: un pacchetto tecnico costruito a
; mano puo' farne a meno, e allora il titolo resta il solo numero.
#ifndef AppVersionName
  #define AppVersionName ""
#endif

#define MyAppName "DECODIUM SDR"
#define MyAppPublisher "IU8LMC"
#define MyAppExeName "decodium-sdr.exe"
#define MyAppUrl "https://decodium.it"

[Setup]
; L'AppId non cambia mai fra una versione e l'altra: è la chiave con cui
; Windows riconosce l'installazione precedente e la sostituisce invece di
; affiancarla. Cambiarlo lascerebbe due DECODIUM SDR nell'elenco dei programmi.
AppId={{4D9C1E27-8F3A-4B65-9E10-2A7C6B5D3F84}
AppName={#MyAppName}
AppVersion={#AppVersion}
; Nel pannello «App installate» si legge questo, ed e' li' che il nome serve:
; chi assiste chiede «che versione hai?» e si sente rispondere un nome.
#if AppVersionName != ""
  #define VerLabel AppVersion + " «" + AppVersionName + "»"
#else
  #define VerLabel AppVersion
#endif
AppVerName={#MyAppName} {#VerLabel}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppUrl}
AppSupportURL={#MyAppUrl}
AppUpdatesURL={#MyAppUrl}
DefaultDirName={autopf}\DECODIUM SDR
DefaultGroupName=DECODIUM SDR
DisableProgramGroupPage=yes
OutputDir=.
; Il nome della versione entra nel nome del file, e non e' decorazione: un
; installatore scaricato finisce in una cartella insieme ad altri dieci, e fra
; sei mesi «DECODIUM_SDR_1.2.1_x64_Setup.exe» non dice a nessuno che cosa
; contiene. «Braun» si'.
; Lo spazio sparisce dal nome del file e resta nel titolo. «De Forest» e' come
; si chiamava; «DECODIUM_SDR_1.2.5_Armstrong_x64_Setup.exe» e' un nome di file
; che si spezza in due alla prima riga di comando che lo tocca.
#if AppVersionName != ""
  #define FileVer AppVersion + "_" + StringChange(AppVersionName, " ", "")
#else
  #define FileVer AppVersion
#endif
OutputBaseFilename=DECODIUM_SDR_{#FileVer}_x64_Setup
SetupIconFile=decodium-sdr.ico
UninstallDisplayIcon={app}\bin\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Senza privilegi di amministratore, come DECODIUM: chi vuole provare un
; programma per radioamatori non deve chiedere il permesso alla propria
; azienda. Con `lowest` l'installazione finisce sotto il profilo dell'utente.
PrivilegesRequired=lowest

; Un programma in esecuzione tiene aperto il proprio eseguibile, e
; l'aggiornamento fallirebbe a metà: si chiude prima, dicendolo.
CloseApplications=force
CloseApplicationsFilter={#MyAppExeName}

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Tutto l'albero dello staging, così com'è: eseguibile e librerie in bin\,
; plugin Qt e moduli QML in share\. Elencare i file uno per uno — come fa lo
; script di DECODIUM, che ne ha una ventina — qui vorrebbe dire riscrivere
; l'elenco a ogni libreria che entra o esce, e dimenticarne una produce un
; pacchetto che parte sulla macchina di chi lo costruisce e su nessun'altra.
Source: "{#StagingDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\DECODIUM SDR"; Filename: "{app}\bin\{#MyAppExeName}"; IconFilename: "{app}\bin\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,DECODIUM SDR}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\DECODIUM SDR"; Filename: "{app}\bin\{#MyAppExeName}"; IconFilename: "{app}\bin\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\{#MyAppExeName}"; Description: "{cm:LaunchProgram,DECODIUM SDR}"; Flags: nowait postinstall skipifsilent

[Messages]
italian.WelcomeLabel2=Verrà installato [name/ver] sul computer.%n%nDECODIUM SDR è un client SDR universale: RTL-SDR, SpyServer, SoapySDR, ColibriNANO, Hermes e radio tradizionali via audio e CAT.
english.WelcomeLabel2=This will install [name/ver] on your computer.%n%nDECODIUM SDR is a universal SDR client: RTL-SDR, SpyServer, SoapySDR, ColibriNANO, Hermes, and traditional radios over audio and CAT.

[Code]
{ L'avviso che vale la radio di qualcuno. Chi installa accanto a un
  ricetrasmettitore deve saperlo prima, non dopo aver visto il PTT scattare da
  solo: su una Yaesu con «CAT RTS» attivo quella linea è il PTT, e qualunque
  programma che apra la porta seriale può mandare in aria una portante per un
  istante. Si mostra alla fine, quando è il momento di collegare la radio, e
  non all'inizio insieme alla licenza — dove non lo legge nessuno. }
procedure CurStepChanged(CurStep: TSetupStep);
begin
  { Non in installazione silenziosa: là non c'è nessuno a premere «OK», e una
    finestra che aspetta blocca l'installazione fino al termine del mondo. Chi
    installa senza interfaccia lo fa da uno script, e gli avvisi li ha già
    letti — o li legge nella pagina della release. }
  if (CurStep = ssPostInstall) and not WizardSilent then
  begin
    if ActiveLanguage() = 'italian' then
      MsgBox('Se colleghi un ricetrasmettitore via CAT: spegni «CAT RTS» nei menù della radio.' + #13#10#13#10 +
             'DECODIUM SDR comanda il PTT con un comando CAT e non usa quella linea; lasciandola attiva, qualunque programma che apra la porta seriale può mandare la radio in trasmissione per un istante.' + #13#10#13#10 +
             'Sul FTDX3000 e su altre radio «CAT RTS» è abilitato di fabbrica: il programma se ne accorge e riapre la porta con l''handshake, ma spegnerlo resta la via più sicura.',
             mbInformation, MB_OK)
    else
      MsgBox('If you connect a transceiver over CAT: turn off "CAT RTS" in the radio menus.' + #13#10#13#10 +
             'DECODIUM SDR keys the PTT with a CAT command and does not use that line; leaving it enabled means any program opening the serial port can key the radio for an instant.',
             mbInformation, MB_OK);
  end;
end;

{ Un'installazione sopra una copia in esecuzione lascia file mezzi sostituiti,
  e il programma riparte con metà delle librerie della versione vecchia. }
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/F /IM {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(400);
  Result := True;
end;
